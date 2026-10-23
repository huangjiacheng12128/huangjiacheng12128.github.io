@echo off
chcp 65001 >nul
powershell -NoProfile -Sta -ExecutionPolicy Bypass -File "%~dp0上传电子书.ps1" %*
if errorlevel 1 pause
