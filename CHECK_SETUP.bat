@echo off
setlocal
cd /d "%~dp0"
REM This setting applies only to this PowerShell process, not to Windows globally.
REM RemoteSigned permits our local Git-tracked script without disabling permanent security controls.
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0scripts\Check-WindowsPrerequisites.ps1"
set "CHECK_EXIT=%ERRORLEVEL%"
if not "%CHECK_EXIT%"=="0" (
  echo.
  echo The setup audit could not complete. Share this window's error message.
)
echo.
pause
exit /b %CHECK_EXIT%
