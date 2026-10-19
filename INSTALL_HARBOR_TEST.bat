@echo off
setlocal
cd /d "%~dp0"
where rustc >nul 2>nul
if errorlevel 1 (
    echo Rust is required. See docs\WINDOWS_SETUP.md.
    pause
    exit /b 1
)
set "GAME_DIR=%APPDATA%\com.gamedock.desktop\games\harbor-test"
if not exist "%GAME_DIR%" mkdir "%GAME_DIR%"
echo Building standalone Harbor Test executable...
rustc --edition 2021 -O "samples\harbor-test\main.rs" -o "%GAME_DIR%\HarborTest.exe"
if errorlevel 1 goto :failed
copy /Y "samples\harbor-test\game.json" "%GAME_DIR%\game.json" >nul
if errorlevel 1 goto :failed
echo.
echo Harbor Test installed. Open Game Dock and press Refresh in My Library.
pause
exit /b 0
:failed
echo Harbor Test installation failed. See the error above.
pause
exit /b 1
