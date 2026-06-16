param(
    [ValidateSet("daily", "weekly", "monthly", "session", "claude-blocks")]
    [string]$View = "daily",
    [string]$Since = (Get-Date -Format "yyyy-MM-dd"),
    [int]$RefreshSeconds = 30
)

$ErrorActionPreference = "Stop"

& "$PSScriptRoot\ensure-ccusage.ps1"

$workspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
Set-Location $workspaceRoot

if ($View -eq "claude-blocks") {
    $blocksHelp = (& ccusage blocks --help 2>$null) -join "`n"

    if ($blocksHelp -match "(^|\s)--live(\s|,|$)") {
        ccusage blocks --live
        return
    }
}

while ($true) {
    Clear-Host
    Write-Host "ccusage monitor - $View" -ForegroundColor Cyan
    Write-Host "Workspace: $workspaceRoot"
    if ($View -ne "claude-blocks") {
        Write-Host "Since: $Since"
    }
    Write-Host "Refresh: every $RefreshSeconds seconds. Press Ctrl+C to stop."
    Write-Host ""

    switch ($View) {
        "daily" {
            ccusage daily --all --since $Since
        }
        "weekly" {
            ccusage weekly --all --since $Since
        }
        "monthly" {
            ccusage monthly --all --since $Since
        }
        "session" {
            ccusage session --all --since $Since
        }
        "claude-blocks" {
            ccusage blocks --active
        }
    }

    Start-Sleep -Seconds $RefreshSeconds
}
