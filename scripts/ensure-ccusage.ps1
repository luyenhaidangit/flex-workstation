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

Write-Step "Checking ccusage"

if (Test-Command "ccusage") {
    Write-Ok "ccusage found: $(Get-CommandVersion ccusage)"
    return
}

if ($SkipInstall) {
    Write-Warn "ccusage is not installed and installation was skipped."
    return
}

if (Test-Command "npm") {
    Write-Host "Installing ccusage globally with npm..."
    npm install -g ccusage@latest
}
elseif (Test-Command "bun") {
    Write-Host "Installing ccusage globally with bun..."
    bun install -g ccusage
}
elseif (Test-Command "pnpm") {
    Write-Host "Installing ccusage globally with pnpm..."
    pnpm add -g ccusage
}
else {
    Write-Warn "ccusage is missing, and no supported package manager was found. Install Node.js/npm or Bun, then re-run SYNC_WORKSPACE.cmd."
    return
}

if (Test-Command "ccusage") {
    Write-Ok "ccusage installed: $(Get-CommandVersion ccusage)"
}
else {
    Write-Warn "ccusage install finished, but 'ccusage' is not available in this terminal yet. Open a new terminal and run 'ccusage --version'."
}
