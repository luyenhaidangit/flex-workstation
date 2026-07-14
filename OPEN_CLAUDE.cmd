@echo off
setlocal

for %%I in ("%~dp0.") do set "PROJECT_ROOT=%%~fI"

echo ============================================================
echo  flex-workstation - open Claude
echo ============================================================
echo.
echo Workstation project root:
echo   %PROJECT_ROOT%
echo.
echo WARNING:
echo   This starts Claude Code with --dangerously-skip-permissions.
echo   Claude will not ask before running tools or editing files.
echo   Use this only inside a trusted workstation.
echo.

where claude >nul 2>nul
if errorlevel 1 (
    echo Claude Code CLI 'claude' was not found in PATH.
    echo Run SYNC_WORKSPACE.cmd first, then open a new terminal and try again.
    echo.
    pause
    exit /b 1
)

call claude --version >nul 2>nul
if errorlevel 1 (
    echo Claude Code CLI was found but could not start correctly.
    echo Reinstall it with: npm install -g @anthropic-ai/claude-code --include=optional
    echo Then open a new terminal and try again.
    echo.
    pause
    exit /b 1
)

cd /d "%PROJECT_ROOT%"
cmd /k claude --dangerously-skip-permissions
