@echo off
setlocal

cd /d "%~dp0"

echo ============================================================
echo  flex-workstation - sync workspace skills
echo ============================================================
echo.
echo This syncs local skills declared in:
echo   config\workspace-skills.json
echo.
echo Target:
echo   C:\Workspace\Project\.claude\skills
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\sync-workspace-skills.ps1" -Force

if errorlevel 1 (
    echo.
    echo ============================================================
    echo  Skill sync failed. Review the messages above.
    echo ============================================================
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Skill sync finished.
echo ============================================================
pause
