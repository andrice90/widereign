@echo off
title WideReign setup
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0data\setup\install.ps1" %*
if errorlevel 1 pause
