@echo off
setlocal

for %%I in ("%~dp0.") do set "PROJECT_ROOT=%%~fI"

echo ============================================================
echo  flex-workstation - open workstation
echo ============================================================
echo.
echo This opens the workstation project root:
echo   %PROJECT_ROOT%
echo.

where code >nul 2>nul
if errorlevel 1 (
    echo VS Code CLI 'code' was not found in PATH.
    echo Install VS Code or enable the 'code' command, then run this file again.
    echo.
    pause
    exit /b 1
)

code "%PROJECT_ROOT%"

if errorlevel 1 (
    echo.
    echo VS Code failed to open the workstation project root.
    echo.
    pause
    exit /b 1
)
