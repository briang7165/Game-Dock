@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -File "%~dp0scripts\Check-WindowsPrerequisites.ps1"
echo.
pause
