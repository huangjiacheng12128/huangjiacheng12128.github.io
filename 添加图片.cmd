@echo off
chcp 65001 >nul
cd /d "%~dp0"
title 添加图片
powershell -STA -NoProfile -ExecutionPolicy Bypass -File "%~dp0添加图片.ps1" %*
if errorlevel 1 pause
