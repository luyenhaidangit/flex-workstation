@echo off
setlocal

for %%I in ("%~dp0..") do set "PROJECT_ROOT=%%~fI"

echo ============================================================
echo  flex-workstation - open Codex
echo ============================================================
echo.
echo Workspace:
echo   %PROJECT_ROOT%
echo.
echo This starts Codex at the shared workspace root and keeps
echo the default sandbox and permission behavior.
echo.

where codex >nul 2>nul
if errorlevel 1 (
    echo Codex CLI 'codex' was not found in PATH.
    echo Install Codex, open a new terminal, then run this file again.
    echo.
    pause
    exit /b 1
)

cd /d "%PROJECT_ROOT%"
cmd /k codex
