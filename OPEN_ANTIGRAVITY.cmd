@echo off
setlocal

for %%I in ("%~dp0.") do set "PROJECT_ROOT=%%~fI"

echo ============================================================
echo  flex-workstation - open Antigravity
echo ============================================================
echo.
echo Workstation project root:
echo   %PROJECT_ROOT%
echo.
echo Antigravity keeps its normal permission prompts enabled.
echo.

where agy >nul 2>nul
if errorlevel 1 (
    echo Antigravity CLI 'agy' was not found in PATH.
    echo Run SYNC_WORKSPACE.cmd first, then open a new terminal and try again.
    echo.
    pause
    exit /b 1
)

call agy --version >nul 2>nul
if errorlevel 1 (
    echo Antigravity CLI was found but could not start correctly.
    echo Reinstall it with the official installer, then open a new terminal and try again.
    echo.
    pause
    exit /b 1
)

cd /d "%PROJECT_ROOT%"
cmd /k agy
