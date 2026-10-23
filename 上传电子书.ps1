param(
  [string[]]$Path,
  [string]$Title,
  [string]$Author,
  [string]$Desc,
  [switch]$DryRun,
  [switch]$NoCommit,
  [switch]$NoPush,
  [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$DataFile = Join-Path $Root 'source\_data\books.yml'
$FilesDir = Join-Path $Root 'source\books\files'
$BooksPage = Join-Path $Root 'public\books\index.html'
$Allowed = @('.epub', '.pdf', '.mobi', '.azw3', '.txt', '.md', '.zip')

function Pause-Exit([int]$Code = 0) {
  if (-not $NoPause) {
    Write-Host ''
    Read-Host '按 Enter 退出' | Out-Null
  }
  exit $Code
}

function Format-Size([long]$Bytes) {
  if ($Bytes -ge 1GB) { return ('{0:N1} GB' -f ($Bytes / 1GB)) }
  if ($Bytes -ge 1MB) { return ('{0:N1} MB' -f ($Bytes / 1MB)) }
  return ('{0:N0} KB' -f [Math]::Max(1, [Math]::Round($Bytes / 1KB)))
}

function Escape-Yaml([string]$Value) {
  if ($null -eq $Value) { return '' }
  return $Value.Replace("'", "''")
}

function Invoke-GitPush {
  $saved = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  & cmd /c "git push origin main 2>&1" | Select-Object -Last 6
  $code = $LASTEXITCODE
  $ErrorActionPreference = $saved
  if ($code -ne 0) {
    Write-Host ''
    Write-Host '推送没有成功（可能是网络或第一次需要登录）。' -ForegroundColor Yellow
    Write-Host '正在打开 GitHub Desktop：点右上角「Push origin」即可。' -ForegroundColor Yellow
    $desktop = Join-Path $env:LOCALAPPDATA 'GitHubDesktop\GitHubDesktop.exe'
    if (Test-Path $desktop) { Start-Process $desktop }
    return $false
  }
  return $true
}

Write-Host ''
Write-Host '=== 上传电子书 ===' -ForegroundColor Magenta
Write-Host ''

if (-not $Path -or $Path.Count -eq 0) {
  Add-Type -AssemblyName System.Windows.Forms
  $dialog = New-Object System.Windows.Forms.OpenFileDialog
  $dialog.Title = '选择要上传的电子书'
  $dialog.Multiselect = $true
  $dialog.Filter = '电子书|*.epub;*.pdf;*.mobi;*.azw3;*.txt;*.md;*.zip|所有文件|*.*'
  if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host '没有选择文件。'
    Pause-Exit 0
  }
  $Path = $dialog.FileNames
}

$files = @()
foreach ($item in $Path) {
  if (-not (Test-Path -LiteralPath $item)) {
    Write-Host "找不到文件：$item" -ForegroundColor Red
    Pause-Exit 1
  }
  $ext = [System.IO.Path]::GetExtension($item).ToLower()
  if ($Allowed -notcontains $ext) {
    Write-Host "不支持这个格式：$ext（支持 epub / pdf / mobi / azw3 / txt / md / zip）" -ForegroundColor Red
    Pause-Exit 1
  }
  $files += Get-Item -LiteralPath $item
}

if (-not (Test-Path $FilesDir)) {
  New-Item -ItemType Directory -Path $FilesDir -Force | Out-Null
}

if (-not (Test-Path $DataFile)) {
  New-Item -ItemType File -Path $DataFile -Force | Out-Null
}

$created = @()

foreach ($file in $files) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
  $ext = [System.IO.Path]::GetExtension($file.Name).ToLower()
  $safe = ($base -replace '[^\w\u4e00-\u9fa5\-]', '-').Trim('-')
  if ([string]::IsNullOrWhiteSpace($safe)) { $safe = 'book' }

  $targetName = "$safe$ext"
  $index = 2
  while (Test-Path -LiteralPath (Join-Path $FilesDir $targetName)) {
    $targetName = "$safe-$index$ext"
    $index++
  }
  $targetPath = Join-Path $FilesDir $targetName

  $bookTitle = if ($Title -and $files.Count -eq 1) { $Title } else { $base }
  $bookAuthor = if ($Author) { $Author } else { '' }
  $bookDesc = if ($Desc) { $Desc } else { '' }
  $format = $ext.TrimStart('.').ToUpper()
  $size = Format-Size $file.Length
  $date = Get-Date -Format 'yyyy-MM-dd'

  Write-Host ''
  Write-Host "书名：$bookTitle"
  Write-Host "格式：$format    大小：$size"
  Write-Host "保存为：source\books\files\$targetName"

  if ($DryRun) {
    Write-Host '（DryRun：只演示，不复制、不修改数据）' -ForegroundColor Yellow
    continue
  }

  Copy-Item -LiteralPath $file.FullName -Destination $targetPath -Force

  $entry = @"

- title: '$(Escape-Yaml $bookTitle)'
  author: '$(Escape-Yaml $bookAuthor)'
  file: '/books/files/$targetName'
  format: '$format'
  size: '$size'
  date: '$date'
  desc: '$(Escape-Yaml $bookDesc)'
"@

  [System.IO.File]::AppendAllText($DataFile, $entry, (New-Object System.Text.UTF8Encoding($false)))
  $created += $targetName

  if ($file.Length -gt 50MB) {
    Write-Host '提示：这个文件超过 50MB，GitHub 推送可能会慢，单个文件上限是 100MB。' -ForegroundColor Yellow
  }
}

if ($DryRun) {
  Write-Host ''
  Write-Host 'DryRun 完成，没有改动任何文件。' -ForegroundColor Green
  Pause-Exit 0
}

if (-not $created.Count) {
  Write-Host '没有新增文件。'
  Pause-Exit 0
}

Write-Host ''
Write-Host '正在构建站点……'
& npx hexo clean | Out-Null
& npm run build 2>&1 | Select-Object -Last 4

if (-not (Test-Path $BooksPage)) {
  Write-Host '构建失败：找不到 public\books\index.html' -ForegroundColor Red
  Pause-Exit 1
}

Write-Host ''
Write-Host "已加入书架：$($created.Count) 本。" -ForegroundColor Green

& git add -A
$changes = & git status --porcelain
if (-not $changes) {
  Write-Host '没有检测到需要提交的改动。'
  Pause-Exit 0
}

if ($NoCommit) {
  Write-Host '（NoCommit：跳过 git commit）' -ForegroundColor Yellow
  Pause-Exit 0
}

$message = "books: 新增 $($created.Count) 本电子书"
& git -c user.name="huangjiacheng12128" -c user.email="h19971815036@163.com" commit -m $message | Select-Object -Last 2

if ($NoPush) {
  Write-Host ''
  Write-Host '已提交到本地（NoPush：没有推送）。' -ForegroundColor Yellow
  Pause-Exit 0
}

Write-Host ''
Write-Host '正在推送到 GitHub……'
if (Invoke-GitPush) {
  Write-Host '推送成功，等 GitHub Actions 构建 1–3 分钟后线上生效。' -ForegroundColor Green
}

Pause-Exit 0
