@echo off
chcp 65001 >nul
cd /d "%~dp0"
title 发布文章
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0发布文章.ps1" %*
if errorlevel 1 (
  echo.
  echo 出错了，请把上面的内容截图发给助手。
  pause
)
