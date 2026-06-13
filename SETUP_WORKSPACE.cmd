@echo off
setlocal

cd /d "%~dp0"

echo ============================================================
echo  flex-workstation - setup workspace
echo ============================================================
echo.
echo This setup will:
echo   - Check Git, VS Code CLI, WinGet, and Claude Code
echo   - Prepare C:\Workspace\Project\.claude from templates
echo   - Install Claude Code if it is missing
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\bootstrap.ps1"

if errorlevel 1 (
    echo.
    echo ============================================================
    echo  Setup failed. Review the messages above.
    echo ============================================================
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Setup finished.
echo ============================================================
echo.
echo Next step:
echo   Double-click OPEN_WORKSPACE.cmd to open C:\Workspace\Project in VS Code.
echo.
pause
