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
echo WARNING:
echo   This starts Codex with full filesystem/network access and
echo   disables approval prompts.
echo   Use this only inside a trusted workspace.
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
cmd /k codex --sandbox danger-full-access --ask-for-approval never
