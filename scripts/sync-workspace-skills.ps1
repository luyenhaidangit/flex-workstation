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
$externalSources = if ($config.externalSources) { @($config.externalSources) } else { @() }

$assistantConfigs = $config.assistants.PSObject.Properties | Where-Object {
    $_.Value.enabled -and $_.Value.skillTarget
}
$targetRoots = @()

foreach ($assistantConfig in $assistantConfigs) {
    $targetRoot = $assistantConfig.Value.skillTarget

    if (-not [System.IO.Path]::IsPathRooted($targetRoot)) {
        $targetRoot = Join-Path $projectRoot $targetRoot
    }

    New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null
    $targetRoots += $targetRoot
}

if ($targetRoots.Count -eq 0) {
    Write-Warn "No enabled assistant skill targets declared in config\workspace-assistants.json."
    return
}

# Build merged skill map — externalSources truoc, localSkills override
$mergedSkills = [ordered]@{}

# Buoc 1: Auto-discover tu external sources (do uu tien thap)
foreach ($source in $externalSources) {
    if (-not $source.path) {
        Write-Warn "External source '$($source.name)' thieu truong 'path'."
        continue
    }

    $sourcePath = $source.path
    if (-not [System.IO.Path]::IsPathRooted($sourcePath)) {
        $sourcePath = Join-Path $workstationRoot $sourcePath
    }

    if (-not (Test-Path $sourcePath)) {
        Write-Warn "External source '$($source.name)' chua duoc clone: $sourcePath"
        continue
    }

    $discovered = 0
    foreach ($dir in (Get-ChildItem -Path $sourcePath -Directory)) {
        $skillMd = Join-Path $dir.FullName "SKILL.md"
        if (-not (Test-Path $skillMd)) { continue }

        $skillName = $dir.Name
        if ($mergedSkills.ContainsKey($skillName)) {
            Write-Warn "Skill '$skillName' tu '$($source.name)' bi bo qua — da duoc dang ky boi nguon truoc."
            continue
        }

        $mergedSkills[$skillName] = @{
            path       = $dir.FullName
            source     = $source.name
            isOverride = $false
        }
        $discovered++
    }

    if ($discovered -gt 0) {
        Write-Ok "Discovered $discovered skills from: $($source.name)"
    }
}

# Buoc 2: Local skills override (do uu tien cao)
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

    $skillFile = Join-Path $sourcePath "SKILL.md"
    if (-not (Test-Path $skillFile)) {
        Write-Warn "Skipped invalid skill folder without SKILL.md: $sourcePath"
        continue
    }

    $skillName = $skill.name
    if (-not $skillName) {
        $skillName = Get-SkillNameFromManifest -SkillPath $sourcePath
    }
    if (-not $skillName) {
        $skillName = Split-Path -Leaf $sourcePath
    }

    $isOverride = $mergedSkills.ContainsKey($skillName)
    $mergedSkills[$skillName] = @{
        path       = $sourcePath
        source     = "local"
        isOverride = $isOverride
    }
}

if ($mergedSkills.Count -eq 0) {
    Write-Ok "No workspace skills to sync."
    return
}

# Buoc 3: Sync merged skills den tat ca targets
foreach ($entry in $mergedSkills.GetEnumerator()) {
    $skillName = $entry.Key
    $info      = $entry.Value
    $resolvedSource = (Resolve-Path $info.path).Path

    $label = if ($info.source -eq "local" -and $info.isOverride) {
        "[local override]"
    } elseif ($info.source -eq "local") {
        "[local]"
    } else {
        "[$($info.source)]"
    }

    foreach ($targetRoot in $targetRoots) {
        $targetPath = Join-Path $targetRoot $skillName

        if (Test-Path $targetPath) {
            Remove-Item -LiteralPath $targetPath -Recurse -Force
        }
        Copy-Item -LiteralPath $resolvedSource -Destination $targetPath -Recurse
        Write-Ok "Synced $label $skillName -> $(Split-Path -Leaf $targetRoot)"
    }
}
