@echo off
rem Native Windows build with Microsoft Visual C++, plain cmd.exe, no PowerShell.
rem Needs Visual Studio 2017+ or Build Tools with the "Desktop development with
rem C++" workload.  CMake finds the toolset through the registry, so no
rem Developer Prompt / vcvars64.bat is needed, and it works over ssh.
rem
rem   build_windows.cmd          x64 and 32-bit  (default)
rem   build_windows.cmd -64      x64 only
rem   build_windows.cmd -32      32-bit only
rem   build_windows.cmd -clean   remove the build directories first
rem   build_windows.cmd -h       this help
rem
rem Result: bin\aften-<ver>-msvc-x64.exe and bin\aften-<ver>-msvc-i386.exe
rem (CRT linked in, /MT), with the raw builds in build-msvc-x64\ and
rem build-msvc-Win32\.  For MinGW or Ninja, use the commands in README.md
rem instead: this script passes -A, which only the Visual Studio generator
rem understands.

setlocal
cd /d "%~dp0"

set "ONLY="
set "CLEAN="
:args
if "%~1"=="" goto :argsdone
if /i "%~1"=="-64" set "ONLY=x64"
if /i "%~1"=="-32" set "ONLY=x86"
if /i "%~1"=="-clean" set "CLEAN=1"
if /i "%~1"=="-h" (set "HELP=1" & goto :argsdone)
if /i "%~1"=="--help" (set "HELP=1" & goto :argsdone)
shift
goto :args
:argsdone
if defined HELP (call :usage & goto :good)

rem Package managers install a launcher shim (scoop) that cannot spawn
rem processes in a non-interactive session: ssh, services, CI agents.  Prefer
rem the real binary when we can see it.
set "CMAKE=cmake"
for /d %%D in ("%USERPROFILE%\scoop\apps\cmake\*") do if exist "%%D\bin\cmake.exe" set "CMAKE=%%D\bin\cmake.exe"
for /d %%D in ("%LOCALAPPDATA%\Programs\CMake\*") do if exist "%%D\bin\cmake.exe" set "CMAKE=%%D\bin\cmake.exe"
if exist "%ProgramFiles%\CMake\bin\cmake.exe" set "CMAKE=%ProgramFiles%\CMake\bin\cmake.exe"

set "VER="
for /f "tokens=3" %%V in ('findstr /c:"define AFTEN_VERSION" libaften\a52.h') do set "VER=%%~V"
if not defined VER (echo could not read AFTEN_VERSION from libaften\a52.h 1>&2 & goto :fail)
echo CMake: %CMAKE%
echo aften: %VER%

if defined CLEAN (
    if exist build-msvc-x64 rmdir /s /q build-msvc-x64
    if exist build-msvc-Win32 rmdir /s /q build-msvc-Win32
)

if defined ONLY (
    if "%ONLY%"=="x86" call :build Win32 i386
    if "%ONLY%"=="x64" call :build x64 x64
    if errorlevel 1 goto :fail
    goto :report
)

call :build x64 x64
if errorlevel 1 goto :fail
call :build Win32 i386
if errorlevel 1 goto :fail

:report
echo.
echo Assets:
for %%F in ("%~dp0bin\aften-*-msvc-*.exe") do echo   %%~nxF  (%%~zF bytes)
goto :good

:build
setlocal
set "ARCH=%~1"
set "DIR=build-msvc-%~1"
echo.
echo ==== %ARCH% ============================================
"%CMAKE%" -S . -B "%DIR%" -A %ARCH% -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 "-DCMAKE_C_FLAGS_RELEASE=/MT /DNDEBUG"
if errorlevel 1 (endlocal & exit /b 1)
"%CMAKE%" --build "%DIR%" --config Release -j
if errorlevel 1 (endlocal & exit /b 1)
if not exist "%DIR%\Release\aften.exe" (echo no aften.exe in %DIR%\Release 1>&2 & endlocal & exit /b 1)
if not exist bin mkdir bin
copy /y "%DIR%\Release\aften.exe" "bin\aften-%VER%-msvc-%~2.exe" >nul
for %%F in ("bin\aften-%VER%-msvc-%~2.exe") do echo   %~2:  %%~nxF  (%%~zF bytes)
endlocal
exit /b 0

:usage
echo.
echo   build_windows.cmd          x64 and 32-bit  (default)
echo   build_windows.cmd -64      x64 only
echo   build_windows.cmd -32      32-bit only
echo   build_windows.cmd -clean   remove the build directories first
echo.
echo   Needs Visual Studio 2017+ / Build Tools with the "Desktop development
echo   with C++" workload.  Assets land in bin\; details in README.md.
echo.
exit /b 0

:good
if not defined CI pause
endlocal
exit /b 0

:fail
echo.
echo BUILD FAILED
if not defined CI pause
endlocal
exit /b 1
