[CmdletBinding()]
param(
  [string[]]$Path,
  [string]$Caption = '',
  [switch]$DryRun,
  [switch]$SkipGit,
  [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Root = $PSScriptRoot
$PhotoDir = Join-Path $Root 'source\img\photos'
$DataFile = Join-Path $Root 'source\_data\photos.yml'
$SiteUrl = 'https://huangjiacheng12128.github.io/photos/'
$Allowed = @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp')

function Stop-WithMessage([string]$Message) {
  Write-Host ''
  Write-Host "[出错] $Message" -ForegroundColor Red
  if (-not $NoPause) { [void](Read-Host '按回车关闭') }
  exit 1
}

function Write-Step([string]$Message) {
  Write-Host ''
  Write-Host "==> $Message" -ForegroundColor Cyan
}

if (-not (Test-Path (Join-Path $Root 'package.json'))) {
  Stop-WithMessage "没有找到博客项目：$Root"
}

# 1. 选照片
if (-not $Path -or $Path.Count -eq 0) {
  Add-Type -AssemblyName System.Windows.Forms
  $dialog = New-Object System.Windows.Forms.OpenFileDialog
  $dialog.Title = '选择要放进相册的照片（可多选）'
  $dialog.Filter = '图片文件|*.jpg;*.jpeg;*.png;*.webp;*.gif;*.bmp|所有文件|*.*'
  $dialog.Multiselect = $true
  if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host '已取消。'
    exit 0
  }
  $Path = $dialog.FileNames
}

$files = @()
foreach ($item in $Path) {
  if (-not (Test-Path -LiteralPath $item -PathType Leaf)) {
    Stop-WithMessage "找不到文件：$item"
  }
  $full = (Resolve-Path -LiteralPath $item).ProviderPath
  $ext = [IO.Path]::GetExtension($full).ToLowerInvariant()
  if ($Allowed -notcontains $ext) {
    Stop-WithMessage "不支持的图片格式：$ext（支持 jpg / png / webp / gif / bmp）"
  }
  $files += [pscustomobject]@{ Source = $full; Extension = $ext }
}

# 2. 说明
if (-not $Caption -and -not $DryRun) {
  Write-Host ''
  $Caption = Read-Host '给这组照片写一句说明（可留空，直接回车）'
}
$Caption = $Caption.Trim()

function ConvertTo-SafeBaseName([string]$Name) {
  $base = [IO.Path]::GetFileNameWithoutExtension($Name)
  $base = $base -replace '[^\w\u4e00-\u9fa5\-]', '-'
  $base = $base -replace '-{2,}', '-'
  $base = $base.Trim('-')
  if ([string]::IsNullOrWhiteSpace($base)) { $base = 'photo' }
  if ($base.Length -gt 40) { $base = $base.Substring(0, 40) }
  return $base
}

# 3. 重命名、复制
$today = (Get-Date).ToString('yyyy-MM-dd')
$entries = @()
New-Item -ItemType Directory -Force -Path $PhotoDir | Out-Null

foreach ($file in $files) {
  $base = ConvertTo-SafeBaseName ([IO.Path]::GetFileName($file.Source))
  $name = $base + $file.Extension
  $dest = Join-Path $PhotoDir $name
  $index = 2
  while (Test-Path -LiteralPath $dest) {
    $name = "$base-$index" + $file.Extension
    $dest = Join-Path $PhotoDir $name
    $index++
  }
  $webPath = '/img/photos/' + $name
  $entries += [pscustomobject]@{
    Source = $file.Source
    Dest = $dest
    Web = $webPath
    Caption = $Caption
    Date = $today
  }
}

Write-Step "准备加入 $($entries.Count) 张照片"
foreach ($entry in $entries) {
  Write-Host ("  {0}  ->  {1}" -f [IO.Path]::GetFileName($entry.Source), $entry.Web)
  if (-not $DryRun) {
    Copy-Item -LiteralPath $entry.Source -Destination $entry.Dest -Force
  }
}

if ($DryRun) {
  Write-Step '预览模式（-DryRun）：没有复制文件、没有改相册数据、没有构建和提交'
  foreach ($entry in $entries) {
    Write-Host "- src: $($entry.Web)"
    Write-Host "  caption: '$($entry.Caption -replace "'", "''")'"
    Write-Host "  date: '$($entry.Date)'"
  }
  if (-not $NoPause) { [void](Read-Host '按回车关闭') }
  exit 0
}

# 4. 写相册数据
if (-not (Test-Path -LiteralPath $DataFile)) {
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $DataFile) | Out-Null
  [IO.File]::WriteAllText($DataFile, "# 相册数据（由桌面上的「上传照片」自动维护）`r`n", [System.Text.UTF8Encoding]::new($false))
}
$existing = [IO.File]::ReadAllText($DataFile)
$yamlBlock = ''
$added = 0
foreach ($entry in $entries) {
  if ($existing -match [regex]::Escape("src: $($entry.Web)")) {
    Write-Host ("  跳过（相册里已有）：{0}" -f $entry.Web) -ForegroundColor Yellow
    continue
  }
  $escaped = $entry.Caption -replace "'", "''"
  $yamlBlock += "- src: $($entry.Web)`r`n  caption: '$escaped'`r`n  date: '$($entry.Date)'`r`n"
  $added++
}
if ($added -gt 0) {
  if (-not $existing.EndsWith("`n")) { $yamlBlock = "`r`n" + $yamlBlock }
  [IO.File]::AppendAllText($DataFile, $yamlBlock, [System.Text.UTF8Encoding]::new($false))
}

# 5. 构建
Write-Step '正在构建网站'
Push-Location $Root
try {
  & npx hexo clean | Out-Null
  & npm run build | Out-Null
  if (-not (Test-Path (Join-Path $Root 'public\photos\index.html'))) {
    Stop-WithMessage '构建后没有生成相册页（public\photos\index.html）'
  }
}
finally {
  Pop-Location
}

# 6. 提交并推送
if (-not $SkipGit) {
  Write-Step '正在提交并推送到 GitHub'
  git add -A
  $changes = git status --porcelain
  if ($changes) {
    git commit -m "photos: 新增 $added 张照片" | Out-Null
    $env:GIT_TERMINAL_PROMPT = '0'
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $push = & cmd /c "git push origin main 2>&1"
    $pushCode = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ($pushCode -ne 0) {
      Write-Host ''
      Write-Host '推送没有成功，最近几行输出：' -ForegroundColor Yellow
      $push | Select-Object -Last 4 | ForEach-Object { Write-Host "  $_" }
      $desktop = Join-Path $env:LOCALAPPDATA 'GitHubDesktop\GitHubDesktop.exe'
      if (Test-Path $desktop) {
        Start-Process $desktop
        Write-Host '已打开 GitHub Desktop：点右上角 Push origin 就能上线。' -ForegroundColor Yellow
      }
    }
    else {
      Write-Host '已推送。' -ForegroundColor Green
    }
  }
  else {
    Write-Host '没有文件变化，跳过提交。'
  }
}

Write-Step '完成'
Write-Host "相册：$SiteUrl"
Write-Host 'GitHub Actions 大约 1-3 分钟后更新线上页面（Ctrl+F5 强刷）。'
if (-not $NoPause) { [void](Read-Host '按回车关闭') }
