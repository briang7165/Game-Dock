@echo off
setlocal
cd /d "%~dp0launcher"
where npm >nul 2>nul
if errorlevel 1 goto :missing
where cargo >nul 2>nul
if errorlevel 1 goto :missing
call npm install
if errorlevel 1 goto :failed
call npm run tauri build
if errorlevel 1 goto :failed
echo.
echo Installer is in launcher\src-tauri\target\release\bundle\nsis
pause
exit /b 0
:missing
echo Install Node.js, Rust and Visual Studio C++ Build Tools first.
:failed
echo Installer build failed; see docs\WINDOWS_SETUP.md.
pause
exit /b 1
