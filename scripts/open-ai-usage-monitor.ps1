param(
    [int]$RefreshSeconds = 30
)

$ErrorActionPreference = "Stop"

& "$PSScriptRoot\ensure-ccusage.ps1"

$workspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
Set-Location $workspaceRoot

$blocksHelp = (& ccusage blocks --help 2>$null) -join "`n"

if ($blocksHelp -match "(^|\s)--live(\s|,|$)") {
    ccusage blocks --live
    return
}

while ($true) {
    Clear-Host
    Write-Host "ccusage monitor - active Claude Code billing block" -ForegroundColor Cyan
    Write-Host "Workspace: $workspaceRoot"
    Write-Host "Refresh: every $RefreshSeconds seconds. Press Ctrl+C to stop."
    Write-Host ""

    ccusage blocks --active

    Start-Sleep -Seconds $RefreshSeconds
}
