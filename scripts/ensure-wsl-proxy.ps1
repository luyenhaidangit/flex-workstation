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
    # Kiem tra xem socat da co trong WSL2 chua
    $hasSocat = wsl -e which socat 2>$null
    if ([string]::IsNullOrWhiteSpace($hasSocat)) {
        Write-Host "Installing 'socat' in WSL2 Ubuntu..."
        wsl -u root -e bash -c "apt-get update -qq && apt-get install -y socat"
    }

    # Tao/Cap nhat service systemd flex-socat-proxy trong WSL2
    $serviceDef = @'
[Unit]
Description=Flex Socat Proxy (59339 -> 59338)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/socat TCP-LISTEN:59339,fork,reuseaddr TCP:127.0.0.1:59338
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
'@

    $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($serviceDef))
    wsl -u root -e bash -c "echo '$b64' | base64 -d > /etc/systemd/system/flex-socat-proxy.service"

    # Reload & enable service
    wsl -u root -e bash -c "systemctl daemon-reload && systemctl enable --now flex-socat-proxy" 2>&1 | Out-Null

    Write-Ok "WSL2 socat proxy service configured and active (59339 -> 59338)"
}
catch {
    Write-Warn "Could not auto-configure WSL2 socat proxy service: $_"
}
