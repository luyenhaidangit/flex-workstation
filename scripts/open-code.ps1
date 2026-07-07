$ErrorActionPreference = "Stop"

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

$workspaceRoot = Split-Path $PSScriptRoot -Parent
$configPath = Join-Path $workspaceRoot "workstation.json"

if (-not (Test-Path $configPath)) {
    Write-Fail "workstation.json not found at: $configPath"
    Write-Fail "Run SYNC_WORKSPACE.cmd first to set up the workspace."
    exit 1
}

if (-not (Get-Command "code" -ErrorAction SilentlyContinue)) {
    Write-Fail "VS Code CLI 'code' was not found in PATH."
    Write-Fail "Install VS Code and ensure 'code' is added to PATH, then try again."
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$repos = $config.repositories.items

if (-not $repos -or $repos.Count -eq 0) {
    Write-Warn "No repositories configured in workstation.json."
    exit 0
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " flex-workstation - Open Code" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$opened = 0
$skipped = 0

foreach ($repo in $repos) {
    $repoPath = Join-Path $workspaceRoot $repo.name
    if (Test-Path $repoPath) {
        code $repoPath
        Write-Ok "$($repo.name)"
        $opened++
    } else {
        Write-Warn "[SKIP] $($repo.name): directory not found (run SYNC_WORKSPACE.cmd to clone)"
        $skipped++
    }
}

Write-Host ""
Write-Host "Opened: $opened project(s)" -ForegroundColor Cyan
if ($skipped -gt 0) {
    Write-Host "Skipped: $skipped project(s) - directories not found" -ForegroundColor Yellow
}
Write-Host ""
