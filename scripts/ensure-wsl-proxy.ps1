$ErrorActionPreference = "Stop"

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

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

if ($env:OS -ne "Windows_NT") {
    Write-Ok "Non-Windows host detected - skipping WSL socat proxy setup"
    exit 0
}

if (-not (Test-Command "wsl")) {
    Write-Warn "WSL CLI is missing - skipping WSL socat proxy setup"
    exit 0
}

Write-Step "Checking WSL2 socat proxy service (flex-socat-proxy)"

try {
    $hasSocat = wsl -e which socat 2>$null
    if ([string]::IsNullOrWhiteSpace($hasSocat)) {
        Write-Host "Installing 'socat' in WSL2 Ubuntu..."
        wsl -u root -e bash -c "apt-get update -qq && apt-get install -y socat"
    }

    $serviceDef = @'
[Unit]
Description=Flex Socat Proxy (7002 -> 7001)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/socat TCP-LISTEN:7002,fork,reuseaddr TCP:127.0.0.1:7001
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
'@

    $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($serviceDef))
    wsl -u root -e bash -c "echo '$b64' | base64 -d > /etc/systemd/system/flex-socat-proxy.service"
    wsl -u root -e bash -c "systemctl daemon-reload && systemctl enable --now flex-socat-proxy" 2>&1 | Out-Null

    Write-Ok "WSL2 socat proxy service configured and active (7002 -> 7001)"
}
catch {
    Write-Warn "Could not auto-configure WSL2 socat proxy service: $_"
}
