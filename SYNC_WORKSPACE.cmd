@echo off
setlocal
cd /d "%~dp0"

set "EXTRA_ARGS="
set /p "dummy=Pull vendor updates: [Y,N]: " <nul
choice /C YN /N /T 10 /D N
if not errorlevel 2 set "EXTRA_ARGS=-PullVendors"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\bootstrap.ps1" %EXTRA_ARGS%

@echo off
if errorlevel 1 (
    pause
    exit /b 1
)

pause
