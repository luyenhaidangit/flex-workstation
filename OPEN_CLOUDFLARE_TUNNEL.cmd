@echo off
setlocal

set "LOCAL_URL=http://localhost:4200"

where cloudflared >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Khong tim thay cloudflared trong PATH.
    echo Cai dat bang: winget install --id Cloudflare.cloudflared
    pause
    exit /b 1
)

echo.
echo Mo Cloudflare Quick Tunnel den %LOCAL_URL%
echo Giu cua so nay mo. Nhan Ctrl+C de dung tunnel.
echo.

cloudflared tunnel --url "%LOCAL_URL%"

set "EXIT_CODE=%ERRORLEVEL%"
echo.
echo Cloudflare Tunnel da dung voi ma %EXIT_CODE%.
pause
exit /b %EXIT_CODE%
