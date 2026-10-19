@echo off
setlocal
cd /d "%~dp0launcher"
where npm >nul 2>nul
if errorlevel 1 goto :missing
where cargo >nul 2>nul
if errorlevel 1 goto :missing
echo [Game Dock] Installing frontend dependencies...
call npm install
if errorlevel 1 goto :failed
echo [Game Dock] Starting desktop launcher...
call npm run tauri dev
if errorlevel 1 goto :failed
exit /b 0
:missing
echo Install Node.js, Rust and the Windows C++ prerequisites first.
goto :failed
:failed
echo Game Dock launch failed; check the error above and docs\WINDOWS_SETUP.md.
pause
exit /b 1
