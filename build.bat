@echo off
setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
cd /d "%~dp0"
if not exist bin mkdir bin
if not exist obj mkdir obj
cl /nologo /O2 /MT /EHsc /W3 /std:c++17 /DUNICODE /D_UNICODE /D_CRT_SECURE_NO_WARNINGS /Foobj\ src\nrwide.cpp /LD /Fe:bin\nrwide.dll /link user32.lib || exit /b 1
cl /nologo /O2 /MT /EHsc /W3 /std:c++17 /DUNICODE /D_UNICODE /Foobj\ src\launcher.cpp /Fe:bin\nrwide_launcher.exe /link /SUBSYSTEM:WINDOWS user32.lib shell32.lib || exit /b 1
copy /y nrwide.ini bin\nrwide.ini >nul
echo BUILD OK
