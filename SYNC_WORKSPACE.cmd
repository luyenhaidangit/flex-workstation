@echo off
setlocal

cd /d "%~dp0"

echo ============================================================
echo  flex-workstation - sync workspace
echo ============================================================
echo.
echo This sync will:
echo   - Check Git, VS Code CLI, WinGet, and Claude Code
echo   - Prepare C:\Workspace\Project\CLAUDE.md and AGENTS.md
echo   - Prepare C:\Workspace\Project\.claude and .agents from templates
echo   - Sync workspace skills from config\workspace-assistants.json
echo   - Install Claude Code if it is missing
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\bootstrap.ps1"

if errorlevel 1 (
    echo.
    echo ============================================================
    echo  Workspace sync failed. Review the messages above.
    echo ============================================================
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Workspace sync finished.
echo ============================================================
echo.
echo Next step:
echo   Double-click OPEN_WORKSPACE.cmd to open C:\Workspace\Project in VS Code.
echo.
pause
