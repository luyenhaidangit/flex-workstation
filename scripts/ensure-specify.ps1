param(
    [switch]$SkipInstall,
    [switch]$SkipInit
)

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

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-CommandVersion {
    param(
        [string]$Name,
        [string[]]$Arguments = @("--version")
    )

    try {
        return (& $Name @Arguments 2>$null | Select-Object -First 1)
    }
    catch {
        return $null
    }
}

function Add-UserPath {
    param([string]$PathToAdd)

    $currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @()
    if ($currentUserPath) {
        $parts = $currentUserPath -split ";" | Where-Object { $_ }
    }

    if ($parts -notcontains $PathToAdd) {
        $newUserPath = (($parts + $PathToAdd) -join ";")
        [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
        Write-Ok "Added to user PATH: $PathToAdd"
    }

    $processParts = @()
    if ($env:Path) {
        $processParts = $env:Path -split ";" | Where-Object { $_ }
    }

    if ($processParts -notcontains $PathToAdd) {
        $env:Path = (($processParts + $PathToAdd) -join ";")
    }
}

function Install-Uv {
    Write-Host "Installing uv (Python package manager)..."
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

    $uvDir = Join-Path $env:USERPROFILE ".local\bin"
    if (Test-Path (Join-Path $uvDir "uv.exe")) {
        Add-UserPath $uvDir
    }

    $cargoUvDir = Join-Path $env:USERPROFILE ".cargo\bin"
    if (Test-Path (Join-Path $cargoUvDir "uv.exe")) {
        Add-UserPath $cargoUvDir
    }
}

function Install-SpecifyCli {
    $specKitVersion = "v1.0.1"
    Write-Host "Installing specify-cli $specKitVersion via uv..."
    uv tool install specify-cli --force --from "git+https://github.com/github/spec-kit.git@$specKitVersion"

    $uvToolBinDir = Join-Path $env:USERPROFILE ".local\bin"
    if (Test-Path (Join-Path $uvToolBinDir "specify.exe")) {
        Add-UserPath $uvToolBinDir
    }
}

function Get-SpecifyVersion {
    if (-not (Test-Command "specify")) {
        return $null
    }

    $versionLine = Get-CommandVersion specify
    if ($versionLine -match "([0-9]+\.[0-9]+\.[0-9]+)") {
        return $Matches[1]
    }

    return $null
}

# --- uv ---

Write-Step "Checking uv"

if (Test-Command "uv") {
    Write-Ok "uv found: $(Get-CommandVersion uv)"
}
elseif ($SkipInstall) {
    Write-Warn "uv is not installed and installation was skipped. specify-cli requires uv."
    return
}
else {
    Install-Uv

    if (Test-Command "uv") {
        Write-Ok "uv installed: $(Get-CommandVersion uv)"
    }
    else {
        Write-Warn "uv install finished, but 'uv' is not available in this terminal yet. Open a new terminal and re-run bootstrap."
        return
    }
}

# --- specify-cli ---

Write-Step "Checking specify-cli"

$requiredSpecKitVersion = "1.0.1"
$installedSpecKitVersion = Get-SpecifyVersion

if ($installedSpecKitVersion -eq $requiredSpecKitVersion) {
    Write-Ok "specify-cli found: $(Get-CommandVersion specify)"
}
elseif ($SkipInstall) {
    if ($installedSpecKitVersion) {
        Write-Warn "specify-cli $installedSpecKitVersion is installed, but $requiredSpecKitVersion is required and upgrade was skipped."
    }
    else {
        Write-Warn "specify-cli is not installed and installation was skipped."
    }
    return
}
else {
    if ($installedSpecKitVersion) {
        Write-Host "Upgrading specify-cli from $installedSpecKitVersion to $requiredSpecKitVersion..."
    }
    else {
        Write-Host "specify-cli is missing. Installing $requiredSpecKitVersion..."
    }

    Install-SpecifyCli
    $installedSpecKitVersion = Get-SpecifyVersion
    if ($installedSpecKitVersion -eq $requiredSpecKitVersion) {
        Write-Ok "specify-cli ready: $(Get-CommandVersion specify)"
    }
    else {
        Write-Warn "specify-cli install finished, but version $requiredSpecKitVersion is not available in this terminal yet. Open a new terminal and re-run bootstrap."
        return
    }
}

# --- specify init ---

if ($SkipInit) {
    Write-Warn "specify init was skipped."
    return
}

if (-not (Test-Command "agy")) {
    Write-Warn "Antigravity CLI 'agy' is required before initializing Spec Kit. Run scripts\ensure-antigravity.ps1, then re-run bootstrap."
    return
}

Write-Step "Initializing spec-kit project"

$projectRoot = Resolve-Path "$PSScriptRoot\.."
$specifyTemplatesPath = Join-Path $projectRoot ".specify\templates"

if (Test-Path $specifyTemplatesPath) {
    Write-Ok "spec-kit already initialized: $specifyTemplatesPath"
    Write-Host "Run scripts\migrate-speckit-antigravity.ps1 once to switch an existing workspace to Antigravity."
    return
}

# Backup custom .specify files before specify init overwrites them
$customFiles = @("extensions.yml", "memory\constitution.md")
$backups = @{}
foreach ($file in $customFiles) {
    $fullPath = Join-Path $projectRoot ".specify\$file"
    if (Test-Path $fullPath) {
        $backups[$file] = Get-Content -Raw -Encoding UTF8 $fullPath
        Write-Host "Backed up .specify\$file"
    }
}

try {
    Write-Host "Running: specify init . --integration agy --script ps --force"
    Push-Location $projectRoot
    specify init . --integration agy --script ps --force
    Pop-Location
    Write-Ok "spec-kit initialized with Antigravity integration."
}
catch {
    Pop-Location -ErrorAction SilentlyContinue
    Write-Warn "specify init failed: $($_.Exception.Message)"
    if (Test-Path (Join-Path $projectRoot ".specify")) {
        Write-Warn ".specify directory exists but may be incomplete. Run 'specify init . --integration agy --script ps --force' manually."
    }
}

# Restore custom files after init
foreach ($file in $backups.Keys) {
    $fullPath = Join-Path $projectRoot ".specify\$file"
    $dir = Split-Path $fullPath -Parent
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Set-Content -Encoding UTF8 -Path $fullPath -Value $backups[$file]
    Write-Ok "Restored .specify\$file"
}
