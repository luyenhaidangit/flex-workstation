$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Get-SkillNameFromManifest {
    param([string]$SkillPath)

    $skillFile = Join-Path $SkillPath "SKILL.md"
    $lines = Get-Content -Encoding UTF8 $skillFile

    foreach ($line in $lines) {
        if ($line -match "^name:\s*(.+?)\s*$") {
            return $Matches[1].Trim().Trim('"').Trim("'")
        }
    }

    return $null
}

$workstationRoot = Resolve-Path "$PSScriptRoot\.."
$projectRoot = Resolve-Path "$PSScriptRoot\..\.."
$configPath = Join-Path $workstationRoot "config\workspace-assistants.json"

Write-Step "Syncing workspace skills"

if (-not (Test-Path $configPath)) {
    Write-Warn "Workspace assistants config not found: $configPath"
    return
}

$config = Get-Content -Raw -Encoding UTF8 $configPath | ConvertFrom-Json
$localSkills = @($config.localSkills)
$assistantConfigs = $config.assistants.PSObject.Properties | Where-Object {
    $_.Value.enabled -and $_.Value.skillTarget
}
$targetRoots = @()

foreach ($assistantConfig in $assistantConfigs) {
    $targetRoot = $assistantConfig.Value.skillTarget

    if (-not [System.IO.Path]::IsPathRooted($targetRoot)) {
        $targetRoot = Join-Path $projectRoot $targetRoot
    }

    $resolvedTargetRoot = $targetRoot
    New-Item -ItemType Directory -Force -Path $resolvedTargetRoot | Out-Null
    $targetRoots += $resolvedTargetRoot
}

if ($targetRoots.Count -eq 0) {
    Write-Warn "No enabled assistant skill targets declared in config\workspace-assistants.json."
    return
}

if ($localSkills.Count -eq 0) {
    Write-Ok "No workspace skills declared in config\workspace-assistants.json."
    return
}

foreach ($skill in $localSkills) {
    if (-not $skill.path) {
        Write-Warn "Skipped skill entry because 'path' is missing."
        continue
    }

    $sourcePath = $skill.path

    if (-not [System.IO.Path]::IsPathRooted($sourcePath)) {
        $sourcePath = Join-Path $workstationRoot $sourcePath
    }

    if (-not (Test-Path $sourcePath)) {
        Write-Warn "Skipped missing skill path: $sourcePath"
        continue
    }

    $resolvedSource = (Resolve-Path $sourcePath).Path
    $skillFile = Join-Path $resolvedSource "SKILL.md"

    if (-not (Test-Path $skillFile)) {
        Write-Warn "Skipped invalid skill folder without SKILL.md: $resolvedSource"
        continue
    }

    $skillName = $skill.name

    if (-not $skillName) {
        $skillName = Get-SkillNameFromManifest -SkillPath $resolvedSource
    }

    if (-not $skillName) {
        $skillName = Split-Path -Leaf $resolvedSource
    }

    foreach ($targetRoot in $targetRoots) {
        $targetPath = Join-Path $targetRoot $skillName

        if (Test-Path $targetPath) {
            Remove-Item -LiteralPath $targetPath -Recurse -Force
            Copy-Item -LiteralPath $resolvedSource -Destination $targetPath -Recurse
            Write-Ok "Updated workspace skill: $skillName -> $targetRoot"
        }
        else {
            Copy-Item -LiteralPath $resolvedSource -Destination $targetPath -Recurse
            Write-Ok "Installed workspace skill: $skillName -> $targetRoot"
        }
    }
}
