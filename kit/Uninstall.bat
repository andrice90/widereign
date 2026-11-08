@echo off
title WideReign uninstall
rem Removes WideReign: its install folder, its desktop shortcuts and (if you say yes) the Seamless Co-op files it added.
rem Game files and save files are never touched. Steam's normal Play button keeps working.
if not defined WR_INSTALL set "WR_INSTALL=%LOCALAPPDATA%\nrwide"
if not exist "%WR_INSTALL%\uninstall.ps1" (
    echo.
    echo     WideReign is not installed ^(nothing in %WR_INSTALL%^).
    echo.
    pause
    exit /b 0
)
cmd /c ""%WR_INSTALL%\Uninstall.bat" %*"
