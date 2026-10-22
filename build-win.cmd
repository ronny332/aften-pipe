@echo off
rem Double-click build for Windows: Microsoft Visual C++, x64 and Win32.
rem Needs Visual Studio 2017+ or Build Tools with the "Desktop development
rem with C++" workload; CMake finds the toolset, no Developer Prompt needed.
rem Assets land in bin\aften-<ver>-msvc-x64.exe and ...-msvc-i386.exe.
rem Anything you type here goes to the script, e.g.
rem   build-win.cmd -CMake C:\Users\you\scoop\apps\cmake\4.4.4\bin\cmake.exe
rem   build-win.cmd -Version 0.09pipe2
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ci\build-win-msvc.ps1" %*
if errorlevel 1 (echo. & echo BUILD FAILED & pause & exit /b 1)
echo.
echo Assets:
dir /b "%~dp0bin\aften-*-msvc-*.exe"
pause
