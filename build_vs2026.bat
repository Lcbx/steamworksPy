@echo off
rem ---------------------------------------------------------------------------
rem  Build SteamworksPy64.dll against the vendored Steamworks SDK (library\sdk)
rem  using whatever Visual Studio (with C++ x64 tools) is installed.
rem
rem  Unlike the upstream build_win_64.bat this does NOT assume the "BuildTools"
rem  edition / old install layout -- it discovers the install via vswhere and
rem  calls vcvars64.bat. No argument required.
rem ---------------------------------------------------------------------------
setlocal enableextensions
cd /d "%~dp0"

echo [*] Locating Visual Studio C++ toolchain
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    echo [!] vswhere.exe not found at "%VSWHERE%"
    exit /b 5
)
set "VSINSTALL="
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSINSTALL=%%i"
if not defined VSINSTALL (
    echo [!] No Visual Studio install with the C++ x64 tools was found.
    exit /b 5
)
echo [*] Using: %VSINSTALL%
call "%VSINSTALL%\VC\Auxiliary\Build\vcvars64.bat" >nul || (echo [!] vcvars64 failed & exit /b 5)

echo [*] Checking SDK prerequisites
if not exist "library\sdk\steam\steam_api.h"   (echo [!] missing library\sdk\steam\*.h   & exit /b 5)
if not exist "library\sdk\redist\steam_api64.dll" (echo [!] missing library\sdk\redist\steam_api64.dll & exit /b 5)
if not exist "library\sdk\redist\steam_api64.lib" (echo [!] missing library\sdk\redist\steam_api64.lib & exit /b 5)

set "DIRNAME=_build_%RANDOM%"
echo [*] Building in %DIRNAME%
mkdir "%DIRNAME%"
copy /y "library\SteamworksPy.cpp" "%DIRNAME%\SteamworksPy.cpp" >nul
copy /y "library\sdk\redist\steam_api64.dll" "%DIRNAME%\" >nul
copy /y "library\sdk\redist\steam_api64.lib" "%DIRNAME%\" >nul
mklink /J "%DIRNAME%\sdk" "%CD%\library\sdk" >nul

pushd "%DIRNAME%"
echo [*] Compiling SteamworksPy64.dll
cl.exe /nologo /O2 /EHsc /D_USRDLL /D_WINDLL SteamworksPy.cpp steam_api64.lib /link /DLL /OUT:SteamworksPy64.dll 2>&1
set "RC=%ERRORLEVEL%"
popd

if "%RC%"=="0" (
    if not exist "redist\windows" mkdir "redist\windows"
    copy /y "%DIRNAME%\SteamworksPy64.dll" "redist\windows\SteamworksPy64.dll" >nul
    echo [*] OK -^> redist\windows\SteamworksPy64.dll
) else (
    echo [!] Build FAILED with code %RC%
)

echo [*] Cleanup
rmdir /s /q "%DIRNAME%"
exit /b %RC%
