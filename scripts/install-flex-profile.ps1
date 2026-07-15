param(
    [ValidateSet("flex")]
    [string]$Profile = "flex",

    [ValidateSet("Agents", "Claude", "Both")]
    [string]$Target = "Both",

    [switch]$Clean,

    [switch]$Force
)

$ErrorActionPreference = "Stop"

$workspaceRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$flexAgentsRoot = Join-Path $workspaceRoot "flex-agents"
$manifestPath = Join-Path $flexAgentsRoot "profiles\$Profile.json"

if (-not (Test-Path $manifestPath)) {
    throw "Profile manifest not found: $manifestPath"
}

$manifest = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json
$userRoot = [Environment]::GetFolderPath("UserProfile")
$allowedSkills = @($manifest.skills)
$flexSkillCatalog = @(Get-ChildItem -LiteralPath (Join-Path $flexAgentsRoot "skills") -Directory | Select-Object -ExpandProperty Name)
$managedMarker = ".flex-agent-skill"

$targetRoots = switch ($Target) {
    "Agents" { @(Join-Path $userRoot ".agents\skills") }
    "Claude" { @(Join-Path $userRoot ".claude\skills") }
    "Both"   { @(
            (Join-Path $userRoot ".agents\skills"),
            (Join-Path $userRoot ".claude\skills")
        ) }
}

foreach ($targetRoot in $targetRoots) {
    New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null

    if ($Clean) {
        Get-ChildItem -LiteralPath $targetRoot -Directory | Where-Object {
            $_.Name -notin $allowedSkills -and
            (
                (Test-Path (Join-Path $_.FullName $managedMarker)) -or
                $_.Name -in $flexSkillCatalog
            )
        } | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
            Write-Host "Removed obsolete flex skill: $($_.FullName)"
        }
    }
}

foreach ($skillName in $manifest.skills) {
    $sourcePath = Join-Path $flexAgentsRoot "skills\$skillName"

    if (-not (Test-Path (Join-Path $sourcePath "SKILL.md"))) {
        throw "Skill not found or invalid: $skillName"
    }

    foreach ($targetRoot in $targetRoots) {
        $destinationPath = Join-Path $targetRoot $skillName

        if ((Test-Path $destinationPath) -and -not $Force) {
            throw "Skill already exists: $destinationPath. Use -Force to replace it."
        }

        if (Test-Path $destinationPath) {
            Remove-Item -LiteralPath $destinationPath -Recurse -Force
        }

        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Recurse
        New-Item -ItemType File -Force -Path (Join-Path $destinationPath $managedMarker) | Out-Null
        Write-Host "Installed $skillName -> $destinationPath"
    }
}

Write-Host "Profile '$($manifest.name)' installed successfully."
