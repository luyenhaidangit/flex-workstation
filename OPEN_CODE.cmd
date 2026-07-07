@echo off
setlocal

for %%I in ("%~dp0.") do set "PROJECT_ROOT=%%~fI"

echo ============================================================
echo  flex-workstation - Open Code
echo ============================================================
echo.
echo Opening all configured project repositories in VS Code...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\open-code.ps1"

if errorlevel 1 (
    echo.
    pause
    exit /b 1
)
