@echo off
setlocal
cd /d "%~dp0"

set "EXTRA_ARGS="
choice /C YN /M "Pull vendor skill updates" /T 10 /D N
if not errorlevel 2 set "EXTRA_ARGS=-PullVendors"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\bootstrap.ps1" %EXTRA_ARGS%

@echo off
if errorlevel 1 (
    pause
    exit /b 1
)

pause
