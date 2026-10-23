#Requires -Version 5.1
<#
  发布文章.ps1 — 一条命令完成「新建/编辑 → 本地构建 → 提交 → 推送」
  用法：
    .\发布文章.ps1                        交互式选择文章
    .\发布文章.ps1 -Title "文章标题"       直接新建/编辑该标题
    .\发布文章.ps1 -DryRun                只演示，不改动仓库
#>
param(
    [string]$Title = "",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Repo
$BaseUrl = 'https://huangjiacheng12128.github.io'
$ActionsUrl = 'https://github.com/huangjiacheng12128/huangjiacheng12128.github.io/actions'

function Write-Step([string]$Text) { Write-Host "`n>> $Text" -ForegroundColor Cyan }
function Write-Ok([string]$Text)   { Write-Host "   $Text" -ForegroundColor Green }
function Write-Warn2([string]$Text){ Write-Host "   $Text" -ForegroundColor Yellow }

function Get-Posts {
    $dir = Join-Path $Repo 'source\_posts'
    if (-not (Test-Path $dir)) { return @() }
    Get-ChildItem $dir -Filter *.md -File | Sort-Object LastWriteTime -Descending | ForEach-Object {
        $raw = Get-Content $_.FullName -TotalCount 20 -Encoding UTF8
        $t = ($raw | Where-Object { $_ -match '^title:\s*(.+)$' } | Select-Object -First 1)
        $name = if ($t) { ($t -replace '^title:\s*', '').Trim().Trim('"').Trim("'") } else { $_.BaseName }
        [pscustomobject]@{ File = $_.FullName; Name = $name; Base = $_.BaseName; Updated = $_.LastWriteTime }
    }
}

function Open-InEditor([string]$Path) {
    try {
        Start-Process $Path
        Write-Ok "已用默认编辑器打开：$Path"
    } catch {
        Write-Warn2 "打不开默认编辑器，改用记事本。"
        Start-Process notepad.exe $Path
    }
}

function Invoke-Build {
    Write-Step '正在构建网站（约 10 秒）'
    & npx hexo clean 2>&1 | Out-Null
    & npm run build 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $Repo 'public\index.html'))) {
        throw '构建失败，请把窗口里的报错发给助手。'
    }
    $count = (Get-ChildItem (Join-Path $Repo 'public') -Recurse -File).Count
    Write-Ok "构建完成，共 $count 个文件。"
}

# ---------- 1. 选文章 ----------
if (-not $Title) {
    $posts = @(Get-Posts)
    Write-Host "`n===== 发布文章 =====" -ForegroundColor Magenta
    Write-Host "[0] 新建文章" -ForegroundColor White
    for ($i = 0; $i -lt $posts.Count; $i++) {
        $p = $posts[$i]
        Write-Host ("[{0}] {1}  ({2:MM-dd HH:mm})" -f ($i + 1), $p.Name, $p.Updated)
    }
    Write-Host "`n输入序号编辑已有文章，或直接输入新标题：" -ForegroundColor Gray
    $choice = Read-Host '>'
    if ([string]::IsNullOrWhiteSpace($choice)) { exit }
    if ($choice -match '^\d+$') {
        $idx = [int]$choice
        if ($idx -eq 0) { $Title = (Read-Host '新文章标题') }
        elseif ($idx -le $posts.Count) { $Title = $posts[$idx - 1].Name }
        else { Write-Warn2 '序号不对。'; exit 1 }
    } else { $Title = $choice }
}

$Title = $Title.Trim()
if (-not $Title) { Write-Warn2 '标题不能为空。'; exit 1 }
if ($Title -match '[\\/:*?"<>|]') {
    Write-Warn2 '标题里不要用 \ / : * ? " < > | 这些符号（Windows 文件名不允许）。'
    exit 1
}

# ---------- 2. 定位或新建文件 ----------
$hyphen = $Title -replace '\s+', '-'
$post = Get-Posts | Where-Object { $_.Name -eq $Title -or $_.Base -eq $Title -or $_.Base -eq $hyphen } | Select-Object -First 1
$isNew = -not $post
if ($isNew) {
    Write-Step "新建文章：$Title"
    if ($DryRun) { Write-Ok '（演练模式：到这里会新建并打开编辑器，本次未执行）'; exit 0 }
    $out = & npm run new -- $Title 2>&1
    $line = $out | Where-Object { $_ -match 'Created:' } | Select-Object -First 1
    if ($line) {
        $path = ($line -replace '\x1b\[[0-9;]*m', '') -replace '^.*Created:\s*', ''
        $path = $path.Trim()
    }
    if (-not $path -or -not (Test-Path $path)) {
        $path = (Get-ChildItem (Join-Path $Repo 'source\_posts') -Filter *.md -File |
                 Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
    }
    if (-not $path) { throw "新建失败，请检查上方输出。" }
} else {
    $path = $post.File
    Write-Step "编辑已有文章：$($post.Name)"
}

# ---------- 3. 写文章 ----------
if ($DryRun) { Write-Ok "（演练模式：将打开 $path，本次未打开）"; exit 0 }
Open-InEditor $path
Write-Host "`n在编辑器里写完、保存后，回到这个窗口按 Enter 发布（直接关闭窗口 = 放弃）：" -ForegroundColor Yellow
$null = Read-Host

# ---------- 4. 构建 + 提交 ----------
Invoke-Build

Write-Step '提交到本地仓库'
& git add -A
$staged = (& git status --porcelain)
if (-not $staged) {
    Write-Warn2 '没有任何改动（是不是没保存？），已停止，网站没有变化。'
    Write-Host "`n按 Enter 关闭窗口。"
    $null = Read-Host
    exit 0
}
$msg = if ($isNew) { "post: $Title" } else { "edit: $Title" }
& git commit -q -m $msg
$hash = (& git rev-parse --short HEAD).Trim()
Write-Ok "已提交：$hash  $msg"

# ---------- 5. 推送 ----------
Write-Step '推送到 GitHub'
Write-Host '   第一次推送可能会弹出 GitHub 登录窗口，按提示登录一次，以后就不用再登了。' -ForegroundColor Yellow
$env:GIT_TERMINAL_PROMPT = '0'
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$pushOut = & cmd /c "git push origin main 2>&1"
$pushed = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $prevEap
if ($pushed) {
    Write-Ok '推送成功。'
} else {
    $pushOut | Select-Object -Last 3 | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
    Write-Warn2 '自动推送没成功，已帮你打开 GitHub Desktop。'
    $desktop = "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe"
    if (Test-Path $desktop) {
        Start-Process $desktop
        Write-Host "在 GitHub Desktop 里点右上角「Push origin」即可（只需要点一下）。" -ForegroundColor Yellow
    } else {
        Write-Warn2 '没找到 GitHub Desktop，请手动推送。'
    }
}

if ($pushed) {
    Write-Host "`n文章已发布：$BaseUrl" -ForegroundColor White
    Write-Host "部署进度（约 1~2 分钟）：$ActionsUrl" -ForegroundColor Gray
} else {
    Write-Host "`n本地已保存并提交；在 GitHub Desktop 点 Push origin 后，网站才会更新。" -ForegroundColor White
}
Write-Host "`n按 Enter 关闭窗口。"
$null = Read-Host
