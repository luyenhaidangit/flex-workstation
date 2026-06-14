@echo off
setlocal
cd /d "%~dp0"

title flex-workstation - Sync Workspace
cls

powershell -NoProfile -Command "Write-Host ''; Write-Host '  ============================================================' -ForegroundColor Cyan; Write-Host '   flex-workstation  ^|  Sync Workspace' -ForegroundColor Cyan; Write-Host '  ============================================================' -ForegroundColor Cyan; Write-Host '  Dong bo skill, command, agent va cau hinh workspace.' -ForegroundColor DarkGray; Write-Host ''"

set "EXTRA_ARGS="
choice /C YN /M "  Pull vendor skill updates" /T 10 /D N
if not errorlevel 2 set "EXTRA_ARGS=-PullVendors"

echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\bootstrap.ps1" %EXTRA_ARGS%

@echo off
if errorlevel 1 (
    pause
    exit /b 1
)

pause
