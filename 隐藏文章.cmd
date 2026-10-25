@echo off
chcp 65001 >nul
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0隐藏文章.ps1" %*
set code=%errorlevel%
if not "%code%"=="0" (
  echo.
  echo 脚本出错，错误码 %code%。
  pause
)
endlocal
