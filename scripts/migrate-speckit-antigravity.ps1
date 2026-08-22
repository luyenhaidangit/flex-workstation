param()

$ErrorActionPreference = "Stop"

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Restore-BackupPath {
    param(
        [string]$BackupRoot,
        [string]$ProjectRoot,
        [string]$RelativePath
    )

    $backupPath = Join-Path $BackupRoot $RelativePath
    if (-not (Test-Path $backupPath)) {
        return
    }

    $targetPath = Join-Path $ProjectRoot $RelativePath
    if (Test-Path $targetPath) {
        Remove-Item -LiteralPath $targetPath -Recurse -Force
    }

    $targetParent = Split-Path $targetPath -Parent
    New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
    Copy-Item -LiteralPath $backupPath -Destination $targetPath -Recurse -Force
}

$projectRoot = (Resolve-Path "$PSScriptRoot\..").Path

if (-not (Test-Command "git")) {
    throw "Git is required to verify the worktree before migration."
}

if (-not (Test-Command "specify")) {
    throw "specify-cli is required. Run scripts\ensure-specify.ps1 first."
}

if (-not (Test-Command "agy")) {
    throw "Antigravity CLI 'agy' is required. Run scripts\ensure-antigravity.ps1 first."
}

$worktreeChanges = & git -C $projectRoot status --porcelain
if ($LASTEXITCODE -ne 0) {
    throw "Unable to determine Git worktree status."
}

if ($worktreeChanges) {
    throw "Migration requires a clean Git worktree. Commit, stash, or discard existing changes first."
}

$protectedPaths = @(
    ".agents\skills",
    ".specify\templates",
    ".specify\scripts",
    ".specify\extensions.yml",
    ".specify\memory\constitution.md",
    ".specify\feature.json",
    ".specify\workflows",
    ".specify\integrations\claude.manifest.json",
    ".specify\integrations\speckit.manifest.json"
)

$backupRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("flex-speckit-agy-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

foreach ($relativePath in $protectedPaths) {
    $sourcePath = Join-Path $projectRoot $relativePath
    if (-not (Test-Path $sourcePath)) {
        continue
    }

    $backupPath = Join-Path $backupRoot $relativePath
    $backupParent = Split-Path $backupPath -Parent
    New-Item -ItemType Directory -Force -Path $backupParent | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $backupPath -Recurse -Force
}

$migrationSucceeded = $false
$migrationError = $null
try {
    Push-Location $projectRoot
    & specify init . --integration agy --script ps --force
    if ($LASTEXITCODE -ne 0) {
        throw "specify init failed with exit code $LASTEXITCODE."
    }

    $integrationPath = Join-Path $projectRoot ".specify\integration.json"
    $integration = Get-Content -Raw -Encoding UTF8 $integrationPath | ConvertFrom-Json
    if ($integration.integration -ne "agy" -or $integration.default_integration -ne "agy") {
        throw "Spec Kit did not select Antigravity as the default integration."
    }

    $migrationSucceeded = $true
}
catch {
    $migrationError = $_
}
finally {
    Pop-Location -ErrorAction SilentlyContinue
    foreach ($relativePath in $protectedPaths) {
        Restore-BackupPath -BackupRoot $backupRoot -ProjectRoot $projectRoot -RelativePath $relativePath
    }
}

if (-not $migrationSucceeded) {
    throw "Migration failed: $($migrationError.Exception.Message) Protected files were restored from $backupRoot."
}

Remove-Item -LiteralPath $backupRoot -Recurse -Force
Write-Host "[OK] Spec Kit now uses Antigravity as its default integration. Shared skills and customized Speckit artifacts were preserved."
