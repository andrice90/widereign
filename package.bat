@echo off
rem Builds bin\ and makes dist\widereign-mod.zip (staged in dist\stage, so other files in dist\ are left alone).
rem Layout: widereign-mod\Install.bat, Uninstall.bat, data\ (everything else).
rem Seamless Co-op is never bundled: its author forbids re-uploading it. The installer fetches it from Nexus.
setlocal
cd /d "%~dp0"
call "%~dp0build.bat" || exit /b 1
set K=dist\stage\widereign-mod
set D=%K%\data
if exist dist\stage rd /s /q dist\stage
mkdir %D%\files %D%\setup
copy /y bin\nrwide.dll %D%\files\ >nul
copy /y bin\nrwide_launcher.exe %D%\files\ >nul
copy /y nrwide.ini %D%\files\ >nul
copy /y kit\data\setup\*.* %D%\setup\ >nul
copy /y "kit\data\START HERE.txt" %D%\ >nul
copy /y README.md %D%\README.txt >nul
copy /y kit\Install.bat %K%\ >nul
copy /y kit\Uninstall.bat %K%\ >nul
if exist dist\widereign-mod.zip del /q dist\widereign-mod.zip
powershell -NoProfile -Command "Compress-Archive -Path '%K%\*' -DestinationPath 'dist\widereign-mod.zip' -Force" || exit /b 1
rd /s /q dist\stage
if exist dist\nrwide-kit.zip del /q dist\nrwide-kit.zip
echo PACKAGE OK: %CD%\dist\widereign-mod.zip
