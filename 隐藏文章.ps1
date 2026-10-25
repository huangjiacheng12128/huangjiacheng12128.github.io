#Requires -Version 5.1
<#
  隐藏文章.ps1 — 把暂时不想展示的文章设为 published: false，或恢复显示
  用法：
    .\隐藏文章.ps1                      交互式选择（可多选）
    .\隐藏文章.ps1 -Title "文章标题"    直接切换指定文章
    .\隐藏文章.ps1 -DryRun              只列出/演示，不改动
    .\隐藏文章.ps1 -NoPush              构建并提交，不推送
    .\隐藏文章.ps1 -NoCommit -NoPush    只改文件并构建（测试用）
#>
param(
    [string]$Title = "",
    [switch]$DryRun,
    [switch]$NoPush,
    [switch]$NoCommit,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Repo
$BaseUrl = 'https://huangjiacheng12128.github.io'
$ActionsUrl = 'https://github.com/huangjiacheng12128/huangjiacheng12128.github.io/actions'

function Write-Step([string]$Text) { Write-Host "`n>> $Text" -ForegroundColor Cyan }
function Write-Ok([string]$Text)   { Write-Host "   $Text" -ForegroundColor Green }
function Write-Warn2([string]$Text){ Write-Host "   $Text" -ForegroundColor Yellow }

function Get-PostInfo {
    $dir = Join-Path $Repo 'source\_posts'
    if (-not (Test-Path $dir)) { return @() }

    Get-ChildItem $dir -Filter *.md -File | Sort-Object LastWriteTime -Descending | ForEach-Object {
        $lines = @(Get-Content -LiteralPath $_.FullName -Encoding UTF8)
        $title = $_.BaseName
        $published = $true

        if ($lines.Count -gt 0 -and $lines[0].Trim() -eq '---') {
            for ($i = 1; $i -lt $lines.Count; $i++) {
                if ($lines[$i].Trim() -eq '---') { break }
                if ($lines[$i] -match '^title:\s*(.+)$') {
                    $title = $Matches[1].Trim().Trim('"').Trim("'")
                }
                if ($lines[$i] -match '^published:\s*(.*)$') {
                    $value = $Matches[1].Trim().Trim('"').Trim("'").ToLowerInvariant()
                    if ($value -in @('false', '0', 'no', 'off')) { $published = $false }
                }
            }
        }

        [pscustomobject]@{
            Path      = $_.FullName
            Title     = $title
            Base      = $_.BaseName
            Published = $published
            Hidden    = -not $published
            Updated   = $_.LastWriteTime
        }
    }
}

function Set-PostPublished {
    param(
        [string]$Path,
        [bool]$Published
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($hasBom -and $text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) {
        $text = $text.Substring(1)
    }

    $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($text -split "`r?`n")) {
        [void]$lines.Add($line)
    }

    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') {
        throw "无法识别 front-matter（文件第一行不是 ---）：$Path"
    }

    $close = -1
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { $close = $i; break }
    }
    if ($close -lt 0) { throw "front-matter 没有结束的 ---：$Path" }

    $publishedIndex = -1
    for ($i = 1; $i -lt $close; $i++) {
        if ($lines[$i] -match '^\s*published\s*:') { $publishedIndex = $i; break }
    }

    $changed = $false

    if ($Published) {
        if ($publishedIndex -ge 0) {
            $lines.RemoveAt($publishedIndex)
            $changed = $true
        }
    } else {
        if ($publishedIndex -ge 0) {
            if ($lines[$publishedIndex] -ne 'published: false') {
                $lines[$publishedIndex] = 'published: false'
                $changed = $true
            }
        } else {
            $insertAt = $close
            for ($i = 1; $i -lt $close; $i++) {
                if ($lines[$i] -match '^title\s*:') { $insertAt = $i + 1; break }
            }
            $lines.Insert($insertAt, 'published: false')
            $changed = $true
        }
    }

    if (-not $changed) { return $false }

    $encoding = New-Object System.Text.UTF8Encoding($hasBom)
    [System.IO.File]::WriteAllText($Path, ($lines -join $newline), $encoding)
    return $true
}

function Invoke-Build {
    Write-Step '正在重新构建网站（约 10 秒）'
    & npx hexo clean 2>&1 | Out-Null

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $log = @(& npm run build 2>&1)
    $code = $LASTEXITCODE
    $ErrorActionPreference = $previous

    if ($code -ne 0 -or -not (Test-Path (Join-Path $Repo 'public\index.html'))) {
        $dir = Join-Path $Repo '.preview'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $logFile = Join-Path $dir 'build-error.log'
        $log | Out-File -LiteralPath $logFile -Encoding UTF8
        $tail = ($log | Select-Object -Last 12) -join "`n"
        throw "构建失败。最后几行：`n`n$tail`n`n完整日志：$logFile"
    }

    $count = (Get-ChildItem (Join-Path $Repo 'public') -Recurse -File).Count
    Write-Ok "构建完成，共 $count 个文件。"
}

# ---------- 1. 选择文章 ----------
$posts = @(Get-PostInfo)
if ($posts.Count -eq 0) {
    Write-Warn2 'source\_posts 里没有找到 .md 文章。'
    if (-not $NoPause) { Write-Host "`n按 Enter 关闭窗口。"; $null = Read-Host }
    exit 1
}

if ($Title) {
    $targets = @($posts | Where-Object {
        $_.Title -eq $Title -or
        $_.Base -eq $Title -or
        $_.Base -eq ($Title -replace '\s+', '-')
    })
    if ($targets.Count -eq 0) {
        Write-Warn2 "没有找到标题为「$Title」的文章。现有文章："
        $posts | ForEach-Object { Write-Host "   - $($_.Title)" -ForegroundColor Gray }
        if (-not $NoPause) { Write-Host "`n按 Enter 关闭窗口。"; $null = Read-Host }
        exit 1
    }
} else {
    Write-Host "`n===== 隐藏 / 恢复文章 =====" -ForegroundColor Magenta
    Write-Host "选中后会自动切换状态：显示中的 → 隐藏，隐藏的 → 恢复" -ForegroundColor Gray
    Write-Host ''
    for ($i = 0; $i -lt $posts.Count; $i++) {
        $state = if ($posts[$i].Hidden) { '已隐藏' } else { '显示中' }
        $color = if ($posts[$i].Hidden) { 'DarkGray' } else { 'White' }
        Write-Host ("[{0}] {1}  {2}" -f ($i + 1), $state, $posts[$i].Title) -ForegroundColor $color
    }
    Write-Host "`n输入序号（可多选，如 2,4），a=全部，q=退出：" -ForegroundColor Yellow
    $choice = Read-Host '>'
    if ([string]::IsNullOrWhiteSpace($choice) -or $choice -match '^(q|quit|退出)$') { exit 0 }

    if ($choice -match '^(a|all|全部)$') {
        $targets = @($posts)
    } else {
        $indexes = @()
        foreach ($part in ($choice -split '[,，\s]+')) {
            if ($part -match '^\d+$') {
                $number = [int]$part
                if ($number -lt 1 -or $number -gt $posts.Count) {
                    Write-Warn2 "序号 $number 不存在。"
                    exit 1
                }
                $indexes += ($number - 1)
            }
        }
        if ($indexes.Count -eq 0) {
            Write-Warn2 '没有选中任何文章。'
            exit 1
        }
        $targets = @($indexes | ForEach-Object { $posts[$_] } | Sort-Object Path -Unique)
    }
}

$toHide = @($targets | Where-Object { -not $_.Hidden })
$toShow = @($targets | Where-Object { $_.Hidden })

if ($toHide.Count -eq 0 -and $toShow.Count -eq 0) {
    Write-Warn2 '选中的文章状态没有变化。'
    if (-not $NoPause) { Write-Host "`n按 Enter 关闭窗口。"; $null = Read-Host }
    exit 0
}

# ---------- 2. 预览 ----------
Write-Host ''
foreach ($post in $toHide) { Write-Host "将隐藏：$($post.Title)" -ForegroundColor Yellow }
foreach ($post in $toShow) { Write-Host "将恢复：$($post.Title)" -ForegroundColor Green }

$visibleAfter = ($posts | Where-Object { $_.Published }).Count - $toHide.Count + $toShow.Count
if ($visibleAfter -lt 1) {
    Write-Warn2 '这样会把所有文章都隐藏，首页会变空。已停止，没有改动。'
    if (-not $NoPause) { Write-Host "`n按 Enter 关闭窗口。"; $null = Read-Host }
    exit 1
}

if ($DryRun) {
    Write-Ok '（演练模式：到这里会修改 front-matter、构建、提交并推送，本次未执行）'
    if (-not $NoPause) { Write-Host "`n按 Enter 关闭窗口。"; $null = Read-Host }
    exit 0
}

# ---------- 3. 改 front-matter ----------
Write-Step '更新文章状态'
$changed = 0

foreach ($post in $toHide) {
    if (Set-PostPublished -Path $post.Path -Published $false) {
        $changed++
        Write-Ok "已隐藏：$($post.Title)"
    }
}
foreach ($post in $toShow) {
    if (Set-PostPublished -Path $post.Path -Published $true) {
        $changed++
        Write-Ok "已恢复：$($post.Title)"
    }
}

if ($changed -eq 0) {
    Write-Warn2 '文件内容没有变化，已停止。'
    if (-not $NoPause) { Write-Host "`n按 Enter 关闭窗口。"; $null = Read-Host }
    exit 0
}

# ---------- 4. 构建 ----------
Invoke-Build

# ---------- 5. 提交 ----------
if (-not $NoCommit) {
    Write-Step '提交到本地仓库'
    & git add -A
    $staged = (& git status --porcelain)
    if (-not $staged) {
        Write-Warn2 '没有需要提交的改动。'
        if (-not $NoPause) { Write-Host "`n按 Enter 关闭窗口。"; $null = Read-Host }
        exit 0
    }

    $parts = @()
    if ($toHide.Count -gt 0) { $parts += "隐藏 $($toHide.Count) 篇" }
    if ($toShow.Count -gt 0) { $parts += "恢复 $($toShow.Count) 篇" }
    $message = 'posts: ' + ($parts -join '，')

    & git commit -q -m $message
    $hash = (& git rev-parse --short HEAD).Trim()
    Write-Ok "已提交：$hash  $message"
}

# ---------- 6. 推送 ----------
$pushed = $false
if (-not $NoPush) {
    Write-Step '推送到 GitHub'
    $env:GIT_TERMINAL_PROMPT = '0'
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $pushOut = & cmd /c "git push origin main 2>&1"
    $pushed = ($LASTEXITCODE -eq 0)
    $ErrorActionPreference = $previous

    if ($pushed) {
        Write-Ok '推送成功。'
    } else {
        $pushOut | Select-Object -Last 3 | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
        Write-Warn2 '自动推送没成功，已帮你打开 GitHub Desktop。'
        $desktop = "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe"
        if (Test-Path $desktop) {
            Start-Process $desktop
            Write-Host '在 GitHub Desktop 里点右上角「Push origin」即可。' -ForegroundColor Yellow
        } else {
            Write-Warn2 '没找到 GitHub Desktop，请手动推送。'
        }
    }
}

Write-Host ''
if ($NoPush) {
    Write-Host '已改好并构建（未推送）。' -ForegroundColor White
} elseif ($pushed) {
    Write-Host "已发布：$BaseUrl" -ForegroundColor White
    Write-Host "部署进度（约 1~2 分钟）：$ActionsUrl" -ForegroundColor Gray
} else {
    Write-Host '本地已保存并提交；在 GitHub Desktop 点 Push origin 后，网站才会更新。' -ForegroundColor White
}

if (-not $NoPause) {
    Write-Host "`n按 Enter 关闭窗口。"
    $null = Read-Host
}
