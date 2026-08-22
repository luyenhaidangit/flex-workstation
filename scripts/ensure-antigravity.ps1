param(
    [switch]$SkipInstall
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
    param([string]$Name)

    try {
        return (& $Name --version 2>$null | Select-Object -First 1)
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
        [Environment]::SetEnvironmentVariable("Path", (($parts + $PathToAdd) -join ";"), "User")
        Write-Ok "Added Antigravity CLI directory to user PATH: $PathToAdd"
    }

    $processParts = @()
    if ($env:Path) {
        $processParts = $env:Path -split ";" | Where-Object { $_ }
    }

    if ($processParts -notcontains $PathToAdd) {
        $env:Path = (($processParts + $PathToAdd) -join ";")
    }
}

function Add-DefaultAntigravityPath {
    $agyBinDir = Join-Path $env:LOCALAPPDATA "agy\bin"
    if (Test-Path (Join-Path $agyBinDir "agy.exe")) {
        Add-UserPath $agyBinDir
    }
}

Write-Step "Checking Antigravity CLI"

Add-DefaultAntigravityPath

if (Test-Command "agy") {
    Write-Ok "Antigravity CLI found: $(Get-CommandVersion agy)"
    return
}

if ($SkipInstall) {
    Write-Warn "Antigravity CLI is not installed and installation was skipped. Install it before running Speckit through Antigravity."
    return
}

Write-Host "Installing Antigravity CLI with the official PowerShell installer..."
Invoke-RestMethod https://antigravity.google/cli/install.ps1 | Invoke-Expression
Add-DefaultAntigravityPath

if (Test-Command "agy") {
    Write-Ok "Antigravity CLI installed: $(Get-CommandVersion agy)"
    Write-Warn "Run 'agy' once in a new terminal to complete Google sign-in if prompted."
}
else {
    Write-Warn "Antigravity CLI installation finished, but 'agy' is not available in this terminal yet. Open a new terminal and run 'agy --version'."
}
