@echo off
setlocal
cd /d "%~dp0"

echo flex-workstation / Sync Windows (hosts, Firewall, .wslconfig)
echo Dong bo domain vao file hosts, mo quy tac Windows Firewall cho microservices va kiem tra .wslconfig.
echo Them tham so -Check de chi kiem tra, khong thay doi gi.
echo.


powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\sync-windows.ps1" %*

if errorlevel 1 (
    echo.
    echo [ERROR] Loi trong qua trinh dong bo file hosts.
    pause
    exit /b 1
)

echo.
pause
