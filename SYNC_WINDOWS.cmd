@echo off
setlocal
cd /d "%~dp0"

echo flex-workstation / Sync Hosts & Firewall
echo Dong bo cau hinh domain vao file hosts va mo quy tac Windows Firewall cho microservices.
echo.


powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\sync-hosts.ps1"

if errorlevel 1 (
    echo.
    echo [ERROR] Loi trong qua trinh dong bo file hosts.
    pause
    exit /b 1
)

echo.
pause
