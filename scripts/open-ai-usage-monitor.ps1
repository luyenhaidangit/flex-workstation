param(
    [ValidateSet("daily", "weekly", "monthly", "session", "claude-blocks")]
    [string]$View = "daily",
    [string]$Since = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd"),
    [int]$RefreshSeconds = 30
)

$ErrorActionPreference = "Stop"

& "$PSScriptRoot\ensure-ccusage.ps1"

$workspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
Set-Location $workspaceRoot

function Format-UsageNumber {
    param([Nullable[double]]$Value)

    if ($null -eq $Value) {
        return "0"
    }

    return "{0:N0}" -f $Value
}

function Format-UsageCost {
    param([Nullable[double]]$Value)

    if ($null -eq $Value) {
        return "$0.00"
    }

    return ("$" + ("{0:N2}" -f $Value))
}

function Join-UsageList {
    param($Items)

    if ($null -eq $Items) {
        return ""
    }

    return (($Items | ForEach-Object { [string]$_ }) -join ", ")
}

function Show-DailyUsageReport {
    param([string]$FromDate)

    $jsonText = (& ccusage daily --all --since $FromDate --json) -join "`n"
    $report = $jsonText | ConvertFrom-Json
    $rows = @()

    $rows += [pscustomobject]@{
        Date          = "TOTAL"
        Agents        = ""
        Models        = ""
        Input         = Format-UsageNumber $report.totals.inputTokens
        Output        = Format-UsageNumber $report.totals.outputTokens
        CacheCreate   = Format-UsageNumber $report.totals.cacheCreationTokens
        CacheRead     = Format-UsageNumber $report.totals.cacheReadTokens
        TotalTokens   = Format-UsageNumber $report.totals.totalTokens
        CostUSD       = Format-UsageCost $report.totals.totalCost
    }

    $report.daily |
        Sort-Object period -Descending |
        ForEach-Object {
            $rows += [pscustomobject]@{
                Date          = $_.period
                Agents        = Join-UsageList $_.metadata.agents
                Models        = Join-UsageList $_.modelsUsed
                Input         = Format-UsageNumber $_.inputTokens
                Output        = Format-UsageNumber $_.outputTokens
                CacheCreate   = Format-UsageNumber $_.cacheCreationTokens
                CacheRead     = Format-UsageNumber $_.cacheReadTokens
                TotalTokens   = Format-UsageNumber $_.totalTokens
                CostUSD       = Format-UsageCost $_.totalCost
            }
        }

    $rows | Format-Table -AutoSize
}

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
            Show-DailyUsageReport -FromDate $Since
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
