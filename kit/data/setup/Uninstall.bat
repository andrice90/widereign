@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
pause
cd /d "%TEMP%"
if not exist "%~dp0uninstall.ps1" (goto) 2>nul & del "%~f0" & rd "%~dp0" 2>nul
