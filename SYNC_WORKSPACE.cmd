@echo off
setlocal
cd /d "%~dp0"

echo flex-workstation / Sync Workspace
echo Copy workspace templates and prepare local tooling.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\bootstrap.ps1"

@echo off
if errorlevel 1 (
    pause
    exit /b 1
)

pause
