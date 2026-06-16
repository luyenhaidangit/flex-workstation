@echo off
setlocal
cd /d "%~dp0"

echo flex-workstation / AI Usage Monitor
echo Opens ccusage monitor for all detected coding AI CLIs.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0scripts\open-ai-usage-monitor.ps1"
