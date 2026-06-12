@echo off
setlocal

cd /d "%~dp0"

echo ============================================================
echo  flex-workstation setup
echo ============================================================
echo.
echo This window will run bootstrap.ps1 with PowerShell.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bootstrap.ps1"

echo.
echo ============================================================
echo  Setup finished. You can close this window.
echo ============================================================
echo.
echo To open the whole Flex project folder, double-click OPEN_PROJECT.cmd.
pause
