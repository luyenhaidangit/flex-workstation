# Requires Administrator privileges to update C:\Windows\System32\drivers\etc\hosts

$ErrorActionPreference = 'Stop'

# Auto-elevate to Administrator if not already elevated
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yeu cau quyen Administrator de cap nhat file hosts hệ thong." -ForegroundColor Yellow
    Write-Host "Dang yeu cau quyen Administrator (UAC)..." -ForegroundColor Cyan
    
    $scriptPath = $MyInvocation.MyCommand.Path
    $powershell = (Get-Command powershell.exe).Source
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    
    $process = Start-Process -FilePath $powershell -ArgumentList $argList -Verb RunAs -PassThru -Wait
    exit $process.ExitCode
}

$templatePath = Join-Path $PSScriptRoot "templates\host"
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
