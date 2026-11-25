param(
    [switch]$RequireCli
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path "$PSScriptRoot\..").Path
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $script:failures.Add($Message)
}

if ($RequireCli) {
    $agy = Get-Command agy -ErrorAction SilentlyContinue
    if ($null -eq $agy) {
        Add-Failure "Antigravity CLI 'agy' is not available in PATH."
    }
    elseif (-not (& agy --version 2>$null)) {
        Add-Failure "Antigravity CLI 'agy' could not return a version."
    }
}

$specify = Get-Command specify -ErrorAction SilentlyContinue
if ($null -eq $specify) {
    Add-Failure "specify-cli is not available in PATH."
}
else {
    $specifyVersion = & specify --version 2>$null | Select-Object -First 1
    if (-not $specifyVersion) {
        Add-Failure "specify-cli could not return a version."
    }
    elseif ($specifyVersion -notmatch "1\.0\.1") {
        Add-Failure "specify-cli version 1.0.1 is required; found '$specifyVersion'."
    }
}

$integrationPath = Join-Path $projectRoot ".specify\integration.json"
if (-not (Test-Path $integrationPath)) {
    Add-Failure "Missing .specify\\integration.json."
}
else {
    $integration = Get-Content -Raw -Encoding UTF8 $integrationPath | ConvertFrom-Json
    $allowedIntegrations = @("claude", "agy")
    $activeKey = [string]$integration.default_integration
    if (-not $activeKey) { $activeKey = [string]$integration.integration }
    if ($allowedIntegrations -notcontains [string]$integration.integration -or $allowedIntegrations -notcontains $activeKey) {
        Add-Failure "Spec Kit integration/default_integration must be 'claude' or 'agy' (shared .agents/skills runtime); found '$($integration.integration)' / '$activeKey'."
    }
    elseif ($integration.integration_settings -and $integration.integration_settings.PSObject.Properties[$activeKey]) {
        $sep = $integration.integration_settings.PSObject.Properties[$activeKey].Value.invoke_separator
        if ($sep -and $sep -ne "-") {
            Add-Failure "Spec Kit invoke_separator for '$activeKey' must be '-' so /speckit-* commands match .agents/skills/."
        }
    }
}

$expectedSkills = @(
    "speckit-analyze",
    "speckit-checklist",
    "speckit-clarify",
    "speckit-constitution",
    "speckit-converge",
    "speckit-docbiz",
    "speckit-implement",
    "speckit-plan",
    "speckit-specify",
    "speckit-tasks",
    "speckit-taskstoissues"
)

foreach ($skillName in $expectedSkills) {
    $skillPath = Join-Path $projectRoot ".agents\skills\$skillName\SKILL.md"
    if (-not (Test-Path $skillPath)) {
        Add-Failure "Missing Speckit skill: $skillName."
        continue
    }

    $content = Get-Content -Raw -Encoding UTF8 $skillPath
    $namePattern = '(?m)^name:\s*["'']?' + [regex]::Escape($skillName) + '["'']?\s*$'
    if ($content -notmatch $namePattern -or $content -notmatch '(?m)^description:\s*\S') {
        Add-Failure "Skill $skillName must provide frontmatter name and description."
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "[OK] Antigravity runtime configuration and $($expectedSkills.Count) Speckit skills are ready."
