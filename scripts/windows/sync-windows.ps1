# Dong bo cau hinh Windows tu template canh script (scripts\windows): hosts, firewall; kiem tra .wslconfig.
# Requires Administrator privileges to update C:\Windows\System32\drivers\etc\hosts
# -Check: chi kiem tra, khong thay doi gi (khong can Administrator), exit 1 neu con thieu.
param([switch]$Check)

$ErrorActionPreference = 'Stop'
$missing = $false

# Auto-elevate to Administrator if not already elevated
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $Check -and -not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yeu cau quyen Administrator de cap nhat file hosts hệ thong." -ForegroundColor Yellow
    Write-Host "Dang yeu cau quyen Administrator (UAC)..." -ForegroundColor Cyan
    
    $scriptPath = $MyInvocation.MyCommand.Path
    $powershell = (Get-Command powershell.exe).Source
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    
    $process = Start-Process -FilePath $powershell -ArgumentList $argList -Verb RunAs -PassThru -Wait
    exit $process.ExitCode
}

$templatePath = Join-Path $PSScriptRoot "hosts"
$targetHostsPath = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"

if (-not (Test-Path $templatePath)) {
    Write-Error "Khong tim thay tệp template: $templatePath"
    exit 1
}

Write-Host "========== DONG BO FILE HOSTS ==========" -ForegroundColor Green
Write-Host "Tệp nguon (Template) : $templatePath"
Write-Host "Tệp dich (System)   : $targetHostsPath"
Write-Host "========================================="

$templateLines = Get-Content $templatePath -Encoding UTF8
$existingContent = Get-Content $targetHostsPath -Raw -Encoding UTF8

$addedCount = 0

foreach ($line in $templateLines) {
    $trimmed = $line.Trim()
    
    # Bo qua dong trong hoac dong comment
    if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
        continue
    }

    # Tach IP va Hostname
    $parts = $trimmed -split '\s+'
    if ($parts.Count -ge 2) {
        $ip = $parts[0]
        $hostname = $parts[1]

        # Kiem tra neu hostname chua co trong file hosts hien tai
        $pattern = "\b" + [regex]::Escape($hostname) + "\b"
        if ($existingContent -notmatch $pattern) {
            if ($Check) {
                Write-Host "[THIEU] Domain chua co trong hosts: $trimmed" -ForegroundColor Yellow
                $missing = $true
                continue
            }
            Add-Content -Path $targetHostsPath -Value "`n$trimmed" -Encoding UTF8 -Force
            Write-Host "[+] Da pride domain moi: $trimmed" -ForegroundColor Cyan
            $addedCount++
        } else {
            Write-Host "[=] Domain da ton tai: $hostname" -ForegroundColor Gray
        }
    }
}

Write-Host "========================================="
if ($addedCount -gt 0) {
    Write-Host "[OK] Da dong bo thanh cong $addedCount domain vao file hosts!" -ForegroundColor Green
} else {
    Write-Host "[OK] Tat ca domain trong template da co san trong file hosts." -ForegroundColor Yellow
}

# ========== DONG BO QUY TAC FIREWALL ==========
Write-Host "`n========== DONG BO QUY TAC FIREWALL ==========" -ForegroundColor Green
$rules = @(
    @{ Name = "Allow Flex Auth Service 5050"; Port = 5050 },
    @{ Name = "Allow Flex Branch Service 5001"; Port = 5001 },
    @{ Name = "Allow Flex Agent Service 7001"; Port = 7001 }
)

foreach ($r in $rules) {
    $existing = Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue
    if (-not $existing -and $Check) {
        Write-Host "[THIEU] Quy tac Firewall chua co: $($r.Name)" -ForegroundColor Yellow
        $missing = $true
    } elseif (-not $existing) {
        New-NetFirewallRule -DisplayName $r.Name -Direction Inbound -Protocol TCP -LocalPort $r.Port -Action Allow | Out-Null
        Write-Host "[+] Da tao quy tac Firewall: $($r.Name) (Port $($r.Port))" -ForegroundColor Cyan
    } else {
        Write-Host "[=] Quy tac Firewall da ton tai: $($r.Name)" -ForegroundColor Gray
    }
}
Write-Host "==============================================="

# ========== KIEM TRA .WSLCONFIG (chi doc; ap dung boi scripts\bootstrap.ps1) ==========
Write-Host "`n========== KIEM TRA .WSLCONFIG ==========" -ForegroundColor Green
$wslTemplatePath = Join-Path $PSScriptRoot ".wslconfig"
$wslConfigPath = Join-Path $env:USERPROFILE ".wslconfig"
$wslConfigContent = if (Test-Path $wslConfigPath) { Get-Content $wslConfigPath -Raw -Encoding UTF8 } else { '' }

foreach ($line in (Get-Content $wslTemplatePath -Encoding UTF8)) {
    if ($line -notmatch '^\s*([^\[#=\s][^=]*?)\s*=\s*(.*?)\s*$') { continue }
    $pattern = "(?m)^\s*" + [regex]::Escape($matches[1]) + "\s*=\s*" + [regex]::Escape($matches[2]) + "\s*$"
    if ($wslConfigContent -match $pattern) {
        Write-Host "[=] $line" -ForegroundColor Gray
    } else {
        Write-Host "[THIEU] $line chua co trong $wslConfigPath (chay scripts\bootstrap.ps1 de ap dung, roi 'wsl --shutdown')" -ForegroundColor Yellow
        $missing = $true
    }
}
Write-Host "================================================="

if ($Check -and $missing) { exit 1 }
