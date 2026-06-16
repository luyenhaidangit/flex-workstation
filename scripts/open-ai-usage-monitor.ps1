param(
    [ValidateSet("daily", "weekly", "monthly", "session", "claude-blocks")]
    [string]$View = "daily",
    [string]$Since = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd"),
    [int]$RefreshSeconds = 30,
    [switch]$Once
)

$ErrorActionPreference = "Stop"

& "$PSScriptRoot\ensure-ccusage.ps1"

$workspaceRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
Set-Location $workspaceRoot

function Format-UsageNumber {
    param($Value)

    if ($null -eq $Value -or $Value -eq "") {
        return ""
    }

    return "{0:N0}" -f ([double]$Value)
}

function Format-UsageCost {
    param($Value)

    if ($null -eq $Value -or $Value -eq "") {
        return ""
    }

    return ("$" + ("{0:N2}" -f ([double]$Value)))
}

function Limit-UsageText {
    param(
        [string]$Text,
        [int]$Width
    )

    if ($null -eq $Text) {
        return ""
    }

    if ($Text.Length -le $Width) {
        return $Text
    }

    if ($Width -le 1) {
        return $Text.Substring(0, $Width)
    }

    return $Text.Substring(0, $Width - 1) + "~"
}

function Get-AgentFromModel {
    param([string]$ModelName)

    if ($ModelName -match "claude|sonnet|opus|haiku") {
        return "Claude"
    }

    if ($ModelName -match "gpt|o[0-9]|codex") {
        return "Codex"
    }

    return "Other"
}

function Format-ModelName {
    param([string]$ModelName)

    $name = $ModelName
    $name = $name -replace "^claude-", ""
    $name = $name -replace "-202[0-9]{5}$", ""
    return "- " + $name
}

function New-UsageRow {
    param(
        [string]$Date,
        [string]$Agent,
        [string]$Models,
        $InputTokens,
        $OutputTokens,
        $CacheCreationTokens,
        $CacheReadTokens,
        $TotalTokens,
        $Cost
    )

    [pscustomobject]@{
        Date        = $Date
        Agent       = $Agent
        Models      = $Models
        Input       = Format-UsageNumber $InputTokens
        Output      = Format-UsageNumber $OutputTokens
        CacheCreate = Format-UsageNumber $CacheCreationTokens
        CacheRead   = Format-UsageNumber $CacheReadTokens
        TotalTokens = Format-UsageNumber $TotalTokens
        CostUSD     = Format-UsageCost $Cost
    }
}

function New-UsageSpacerRow {
    [pscustomobject]@{
        IsSeparator = $true
        Date        = ""
        Agent       = ""
        Models      = ""
        Input       = ""
        Output      = ""
        CacheCreate = ""
        CacheRead   = ""
        TotalTokens = ""
        CostUSD     = ""
    }
}

function Write-UsageTable {
    param($Rows)

    $columns = @(
        @{ Name = "Date";        Width = 10; Align = "Left"  },
        @{ Name = "Agent";       Width = 11; Align = "Left"  },
        @{ Name = "Models";      Width = 24; Align = "Left"  },
        @{ Name = "Input";       Width = 11; Align = "Right" },
        @{ Name = "Output";      Width = 9;  Align = "Right" },
        @{ Name = "CacheCreate"; Width = 11; Align = "Right" },
        @{ Name = "CacheRead";   Width = 11; Align = "Right" },
        @{ Name = "TotalTokens"; Width = 12; Align = "Right" },
        @{ Name = "CostUSD";     Width = 10; Align = "Right" }
    )

    $horizontal = [char]0x2500
    $vertical = [char]0x2502
    $topLeft = [char]0x250C
    $topJoin = [char]0x252C
    $topRight = [char]0x2510
    $middleLeft = [char]0x251C
    $middleJoin = [char]0x253C
    $middleRight = [char]0x2524
    $bottomLeft = [char]0x2514
    $bottomJoin = [char]0x2534
    $bottomRight = [char]0x2518

    function New-Border {
        param(
            [string]$Left,
            [string]$Middle,
            [string]$Right
        )

        $line = $Left
        for ($i = 0; $i -lt $columns.Count; $i++) {
            $line += ($horizontal.ToString() * ($columns[$i].Width + 2))
            if ($i -lt ($columns.Count - 1)) {
                $line += $Middle
            }
        }
        return $line + $Right
    }

    function Format-Cell {
        param(
            [string]$Text,
            [int]$Width,
            [string]$Align
        )

        $value = Limit-UsageText $Text $Width
        if ($Align -eq "Right") {
            return " " + $value.PadLeft($Width) + " "
        }

        return " " + $value.PadRight($Width) + " "
    }

    function Write-TableRow {
        param($Row)

        $line = $vertical.ToString()
        foreach ($column in $columns) {
            $line += (Format-Cell ([string]$Row.($column.Name)) $column.Width $column.Align) + $vertical
        }
        Write-Host $line
    }

    $topBorder = New-Border $topLeft $topJoin $topRight
    $middleBorder = New-Border $middleLeft $middleJoin $middleRight
    $bottomBorder = New-Border $bottomLeft $bottomJoin $bottomRight

    Write-Host $topBorder
    $header = [ordered]@{}
    foreach ($column in $columns) {
        $header[$column.Name] = $column.Name
    }
    Write-TableRow ([pscustomobject]$header)
    Write-Host $middleBorder

    foreach ($row in $Rows) {
        if ($row.PSObject.Properties.Name -contains "IsSeparator" -and $row.IsSeparator) {
            Write-Host $middleBorder
            continue
        }

        Write-TableRow $row
        if ($row.Date -eq "TOTAL") {
            Write-Host $middleBorder
        }
    }

    Write-Host $bottomBorder
}

function Show-DailyUsageReport {
    param([string]$FromDate)

    $jsonText = (& ccusage daily --all --since $FromDate --json) -join "`n"
    $report = $jsonText | ConvertFrom-Json
    $rows = @()

    $rows += New-UsageRow "TOTAL" "" "" `
        $report.totals.inputTokens `
        $report.totals.outputTokens `
        $report.totals.cacheCreationTokens `
        $report.totals.cacheReadTokens `
        $report.totals.totalTokens `
        $report.totals.totalCost

    $dailyRows = @($report.daily | Sort-Object period -Descending)

    for ($index = 0; $index -lt $dailyRows.Count; $index++) {
        $day = $dailyRows[$index]
        $rows += New-UsageRow $day.period "All" "" `
            $day.inputTokens `
            $day.outputTokens `
            $day.cacheCreationTokens `
            $day.cacheReadTokens `
            $day.totalTokens `
            $day.totalCost

        $day.modelBreakdowns |
            Sort-Object @{ Expression = { Get-AgentFromModel $_.modelName } }, modelName |
            ForEach-Object {
                $rows += New-UsageRow "" ("- " + (Get-AgentFromModel $_.modelName)) (Format-ModelName $_.modelName) `
                    $_.inputTokens `
                    $_.outputTokens `
                    $_.cacheCreationTokens `
                    $_.cacheReadTokens `
                    ($_.inputTokens + $_.outputTokens + $_.cacheCreationTokens + $_.cacheReadTokens) `
                    $_.cost
            }

        if ($index -lt ($dailyRows.Count - 1)) {
            $rows += New-UsageSpacerRow
        }
    }

    Write-UsageTable $rows
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

    if ($Once) {
        break
    }

    Start-Sleep -Seconds $RefreshSeconds
}
