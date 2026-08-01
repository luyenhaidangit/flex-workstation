@echo off
setlocal
cd /d "%~dp0"

echo flex-workstation / Sync Hosts
echo Dong bo cau hinh domain tu scripts\templates\host vao C:\Windows\System32\drivers\etc\hosts.
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
