#Requires -Version 5.1
<#
  添加图片.ps1 — 把图片放进博客、并生成可直接粘贴的 Markdown
  用法：
    双击 添加图片.cmd          优先取剪贴板里的截图，否则弹出选图对话框
    .\添加图片.ps1 -Path a.png -Caption "图注"
#>
param(
    [string[]]$Path,
    [string]$Caption = '',
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$ImgDir = Join-Path $Repo 'source\img'
if (-not (Test-Path $ImgDir)) { New-Item -ItemType Directory -Path $ImgDir | Out-Null }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$files = @()
if ($Path) {
    $files = @($Path | ForEach-Object { (Resolve-Path $_ -ErrorAction Stop).Path })
} else {
    $clip = [System.Windows.Forms.Clipboard]::GetImage()
    if ($clip) {
        $name = 'pasted-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.png'
        $dest = Join-Path $ImgDir $name
        $clip.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
        $files = @($dest)
        Write-Host '已读取剪贴板里的截图。' -ForegroundColor Green
    } else {
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title = '选择要放进文章的图片（可多选）'
        $dlg.Filter = '图片文件|*.png;*.jpg;*.jpeg;*.gif;*.webp;*.bmp'
        $dlg.Multiselect = $true
        if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit }
        $files = @($dlg.FileNames)
    }
}

if (-not $Caption) {
    Write-Host ''
    $Caption = Read-Host '图注（会显示在图片下方，可留空直接回车）'
    $Caption = $Caption.Trim()
}

$saved = @()
$i = 0
foreach ($f in $files) {
    $i++
    $ext = [System.IO.Path]::GetExtension($f).ToLower()
    $base = [System.IO.Path]::GetFileNameWithoutExtension($f) -replace '[^\w\u4e00-\u9fa5\-]', '-'
    if (-not $base) { $base = 'img' }
    $name = "$base$ext"

    $alreadyHere = ([System.IO.Path]::GetFullPath([System.IO.Path]::GetDirectoryName($f))) -eq ([System.IO.Path]::GetFullPath($ImgDir))
    if ($alreadyHere) {
        $name = [System.IO.Path]::GetFileName($f)
        $dest = $f
    } else {
        $n = 2
        while (Test-Path (Join-Path $ImgDir $name)) {
            $name = "$base-$n$ext"
            $n++
        }
        $dest = Join-Path $ImgDir $name
        Copy-Item -LiteralPath $f -Destination $dest
    }
    $saved += [pscustomobject]@{ Name = $name; Path = $dest }
}

$md = ($saved | ForEach-Object {
    if ($Caption) { "![$Caption](/img/$($_.Name))" } else { "![](/img/$($_.Name))" }
}) -join "`r`n`r`n"

Set-Clipboard -Value $md

Write-Host ''
Write-Host "已保存 $($saved.Count) 张图片到 source\img：" -ForegroundColor Green
foreach ($s in $saved) { Write-Host "  $($s.Name)" -ForegroundColor DarkGray }
Write-Host ''
Write-Host 'Markdown 已复制到剪贴板，回到 Typora 按 Ctrl+V 粘贴：' -ForegroundColor Yellow
Write-Host $md -ForegroundColor Cyan

if (-not $NoPause) {
    Write-Host "`n按 Enter 关闭窗口。"
    $null = Read-Host
}
