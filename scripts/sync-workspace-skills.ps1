param([switch]$PullVendors)

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
    $lines = Get-Content -Encoding UTF8 (Join-Path $SkillPath "SKILL.md")
    foreach ($line in $lines) {
        if ($line -match "^name:\s*(.+?)\s*$") {
            return $Matches[1].Trim().Trim('"').Trim("'")
        }
    }
    return $null
}

function Resolve-ConfigPath {
    param([string]$RawPath, [string]$Base)
    if ([System.IO.Path]::IsPathRooted($RawPath)) { return $RawPath }
    return Join-Path $Base $RawPath
}

$workstationRoot = Resolve-Path "$PSScriptRoot\.."
$projectRoot     = Resolve-Path "$PSScriptRoot\..\.."
$configPath      = Join-Path $workstationRoot "config\workspace-assistants.json"

Write-Step "Syncing workspace"

if (-not (Test-Path $configPath)) {
    Write-Warn "Config not found: $configPath"
    return
}

$config         = Get-Content -Raw -Encoding UTF8 $configPath | ConvertFrom-Json
$localSkills    = @($config.localSkills)
$externalSources = if ($config.externalSources) { @($config.externalSources) } else { @() }

# --- Build resourceTargets: type -> [absolute target paths] ---
# Supports new "targets" map and legacy "skillTarget"
$resourceTargets = @{}

foreach ($prop in ($config.assistants.PSObject.Properties | Where-Object { $_.Value.enabled })) {
    $asst = $prop.Value

    $typeMap = if ($asst.targets) {
        $asst.targets.PSObject.Properties | ForEach-Object { [pscustomobject]@{ Type = $_.Name; Path = $_.Value } }
    } elseif ($asst.skillTarget) {
        @([pscustomobject]@{ Type = "skills"; Path = $asst.skillTarget })
    } else { @() }

    foreach ($entry in $typeMap) {
        $abs = Resolve-ConfigPath $entry.Path $projectRoot
        New-Item -ItemType Directory -Force -Path $abs | Out-Null
        if (-not $resourceTargets.ContainsKey($entry.Type)) { $resourceTargets[$entry.Type] = @() }
        $resourceTargets[$entry.Type] += $abs
    }
}

if ($resourceTargets.Count -eq 0) {
    Write-Warn "No enabled targets declared in workspace-assistants.json."
    return
}

# --- Discover items from external sources ---
# $discovered: type -> ordered{ name -> { path, source, isFile, fileName? } }
$discovered = @{}

foreach ($source in $externalSources) {
    # Resolve cloneTo and clone/pull as needed
    $cloneTo = $null
    if ($source.cloneTo) {
        $cloneTo = Resolve-ConfigPath $source.cloneTo $workstationRoot

        if (-not (Test-Path $cloneTo)) {
            if ($source.url) {
                Write-Step "Cloning: $($source.name)"
                git clone --depth 1 $source.url $cloneTo
                Write-Ok "Cloned: $($source.name)"
            } else {
                Write-Warn "Source '$($source.name)' not cloned and no 'url' declared."
                continue
            }
        } elseif ($PullVendors) {
            Write-Step "Pulling: $($source.name)"
            Push-Location $cloneTo
            try { git pull; Write-Ok "Pulled: $($source.name)" }
            finally { Pop-Location }
        }
    }

    # Build sync map: type -> absolute source path
    $syncMap = @{}
    if ($source.sync -and $cloneTo) {
        foreach ($sp in $source.sync.PSObject.Properties) {
            $syncMap[$sp.Name] = Join-Path $cloneTo $sp.Value
        }
    } elseif ($source.path) {
        # Legacy: path field = skills directory
        $syncMap["skills"] = Resolve-ConfigPath $source.path $workstationRoot
    }

    foreach ($sm in $syncMap.GetEnumerator()) {
        $type    = $sm.Key
        $srcPath = $sm.Value

        if (-not (Test-Path $srcPath)) {
            Write-Warn "Not found '$($source.name)/$type': $srcPath"
            continue
        }

        if (-not $discovered.ContainsKey($type)) { $discovered[$type] = [ordered]@{} }
        $before = $discovered[$type].Count

        if ($type -eq "skills") {
            foreach ($dir in (Get-ChildItem -Path $srcPath -Directory)) {
                if (-not (Test-Path (Join-Path $dir.FullName "SKILL.md"))) { continue }
                if ($discovered[$type].Contains($dir.Name)) {
                    Write-Warn "Skill '$($dir.Name)' from '$($source.name)' skipped - name collision."
                    continue
                }
                $discovered[$type][$dir.Name] = @{ path = $dir.FullName; source = $source.name; isFile = $false }
            }
        } else {
            foreach ($file in (Get-ChildItem -Path $srcPath -Filter "*.md" -File)) {
                if ($file.Name -eq "README.md") { continue }
                if ($discovered[$type].Contains($file.BaseName)) {
                    Write-Warn "$type '$($file.BaseName)' from '$($source.name)' skipped - name collision."
                    continue
                }
                $discovered[$type][$file.BaseName] = @{ path = $file.FullName; source = $source.name; isFile = $true; fileName = $file.Name }
            }
        }

        $added = $discovered[$type].Count - $before
        if ($added -gt 0) { Write-Ok "Discovered $added $type from: $($source.name)" }
    }
}

# --- Apply localSkills (override external skills by name) ---
if ($localSkills.Count -gt 0) {
    if (-not $discovered.ContainsKey("skills")) { $discovered["skills"] = [ordered]@{} }

    foreach ($skill in $localSkills) {
        if (-not $skill.path) { Write-Warn "Skipped skill entry: missing 'path'."; continue }

        $srcPath = Resolve-ConfigPath $skill.path $workstationRoot
        if (-not (Test-Path $srcPath))                      { Write-Warn "Skipped missing skill: $srcPath"; continue }
        if (-not (Test-Path (Join-Path $srcPath "SKILL.md"))) { Write-Warn "No SKILL.md in: $srcPath"; continue }

        $name = $skill.name
        if (-not $name) { $name = Get-SkillNameFromManifest -SkillPath $srcPath }
        if (-not $name) { $name = Split-Path -Leaf $srcPath }

        $isOverride = $discovered["skills"].Contains($name)
        $discovered["skills"][$name] = @{ path = $srcPath; source = "local"; isFile = $false; isOverride = $isOverride }
    }
}

# --- Clean stale resources in targets ---
foreach ($type in $resourceTargets.Keys) {
    $targets = $resourceTargets[$type]
    if (-not $targets -or $targets.Count -eq 0) { continue }

    $known = if ($discovered.ContainsKey($type)) { $discovered[$type] } else { [ordered]@{} }

    foreach ($targetRoot in $targets) {
        if (-not (Test-Path $targetRoot)) { continue }

        if ($type -eq "skills") {
            foreach ($existing in (Get-ChildItem -Path $targetRoot -Directory)) {
                if (-not $known.Contains($existing.Name)) {
                    Remove-Item -LiteralPath $existing.FullName -Recurse -Force
                    Write-Warn "Removed stale ${type}: $($existing.Name)"
                }
            }
        } else {
            foreach ($existing in (Get-ChildItem -Path $targetRoot -Filter "*.md" -File)) {
                if (-not $known.Contains($existing.BaseName)) {
                    Remove-Item -LiteralPath $existing.FullName -Force
                    Write-Warn "Removed stale ${type}: $($existing.Name)"
                }
            }
        }
    }
}

if ($discovered.Count -eq 0) {
    Write-Ok "Nothing to sync."
    return
}

# --- Sync all resources to their targets ---
foreach ($type in $discovered.Keys) {
    $targets = $resourceTargets[$type]
    if (-not $targets -or $targets.Count -eq 0) {
        Write-Warn "No target configured for '$type' - skipping."
        continue
    }

    foreach ($entry in $discovered[$type].GetEnumerator()) {
        $name = $entry.Key
        $info = $entry.Value
        $src  = (Resolve-Path $info.path).Path

        if ($info.source -eq "local" -and $info.isOverride) {
            $label = "[local override]"
        } elseif ($info.source -eq "local") {
            $label = "[local]"
        } else {
            $label = "[$($info.source)]"
        }

        foreach ($targetRoot in $targets) {
            if ($info.isFile) {
                $dst = Join-Path $targetRoot $info.fileName
                Copy-Item -LiteralPath $src -Destination $dst -Force
            } else {
                $dst = Join-Path $targetRoot $name
                if (Test-Path $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
                Copy-Item -LiteralPath $src -Destination $dst -Recurse
            }
            Write-Ok "Synced $label [$type] $name -> $(Split-Path -Leaf $targetRoot)"
        }
    }
}
