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
        Write-Ok "Added rtk install directory to user PATH: $PathToAdd"
    }

    $processParts = @()
    if ($env:Path) {
        $processParts = $env:Path -split ";" | Where-Object { $_ }
    }

    if ($processParts -notcontains $PathToAdd) {
        $env:Path = (($processParts + $PathToAdd) -join ";")
    }
}

function Install-RtkWindows {
    $installDir = Join-Path $env:USERPROFILE ".local\bin"
    $zipPath = Join-Path $env:TEMP "rtk-windows.zip"
    $extractDir = Join-Path $env:TEMP ("rtk-" + [Guid]::NewGuid().ToString("N"))
    $downloadUrl = "https://github.com/rtk-ai/rtk/releases/latest/download/rtk-x86_64-pc-windows-msvc.zip"

    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null

    Write-Host "Downloading rtk Windows binary..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

    $rtkExe = Get-ChildItem -LiteralPath $extractDir -Recurse -Filter "rtk.exe" | Select-Object -First 1
    if (-not $rtkExe) {
        throw "rtk.exe was not found in downloaded archive."
    }

    Copy-Item -LiteralPath $rtkExe.FullName -Destination (Join-Path $installDir "rtk.exe") -Force
    Add-UserPath $installDir

    Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $extractDir -Recurse -Force -ErrorAction SilentlyContinue
}

function Install-RtkFallback {
    if (Test-Command "cargo") {
        Write-Host "Installing rtk with cargo from GitHub..."
        cargo install --git https://github.com/rtk-ai/rtk
        return
    }

    if (Test-Command "bash") {
        Write-Host "Installing rtk with upstream shell installer..."
        bash -lc "curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
        return
    }

    Write-Warn "rtk is missing and no supported installer path is available. Install from https://github.com/rtk-ai/rtk/releases."
}

function Ensure-ClaudeRtkHook {
    $claudeDir = Join-Path $env:USERPROFILE ".claude"
    $settingsPath = Join-Path $claudeDir "settings.json"

    New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

    if (Test-Path $settingsPath) {
        try {
            $settings = Get-Content -Raw -Encoding UTF8 $settingsPath | ConvertFrom-Json
        }
        catch {
            Write-Warn "Cannot patch Claude global settings because JSON is invalid: $settingsPath"
            return
        }
    }
    else {
        $settings = [pscustomobject]@{}
    }

    if (-not ($settings.PSObject.Properties.Name -contains "hooks") -or $null -eq $settings.hooks) {
        $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([pscustomobject]@{})
    }

    if (-not ($settings.hooks.PSObject.Properties.Name -contains "PreToolUse") -or $null -eq $settings.hooks.PreToolUse) {
        $settings.hooks | Add-Member -NotePropertyName "PreToolUse" -NotePropertyValue @()
    }

    $targetMatcher = "Bash|PowerShell"
    $preToolUse = @($settings.hooks.PreToolUse)
    $alreadyConfigured = $false
    $migrated = $false

    foreach ($entry in $preToolUse) {
        $hasRtkHook = $false
        foreach ($hook in @($entry.hooks)) {
            if ($hook.type -eq "command" -and $hook.command -eq "rtk hook claude") {
                $hasRtkHook = $true
            }
        }

        if (-not $hasRtkHook) {
            continue
        }

        if ($entry.matcher -eq $targetMatcher) {
            $alreadyConfigured = $true
        }
        elseif ($entry.matcher -eq "Bash") {
            $entry.matcher = $targetMatcher
            $migrated = $true
        }
    }

    if ($alreadyConfigured) {
        Write-Ok "Claude global rtk hook already configured: $settingsPath"
        return
    }

    if (-not $migrated) {
        $rtkHook = [pscustomobject]@{
            matcher = $targetMatcher
            hooks = @(
                [pscustomobject]@{
                    type = "command"
                    command = "rtk hook claude"
                }
            )
        }

        $preToolUse = @($preToolUse + $rtkHook)
    }

    $settings.hooks.PreToolUse = @($preToolUse)
    [System.IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 20), (New-Object System.Text.UTF8Encoding $false))
    Write-Ok "Patched Claude global rtk hook: $settingsPath"
}

function Ensure-CodexRtkTemplate {
    $templatePath = Join-Path $PSScriptRoot "templates\rtk-codex.md"
    if (-not (Test-Path $templatePath)) {
        Write-Warn "Codex RTK template not found: $templatePath"
        return
    }

    $codexDir = Join-Path $env:USERPROFILE ".codex"
    New-Item -ItemType Directory -Force -Path $codexDir | Out-Null

    $targetPath = Join-Path $codexDir "RTK.md"
    $templateContent = Get-Content -Raw -Encoding UTF8 $templatePath

    if ((Test-Path $targetPath) -and ((Get-Content -Raw -Encoding UTF8 $targetPath) -eq $templateContent)) {
        Write-Ok "Codex RTK.md already matches workstation template: $targetPath"
        return
    }

    [System.IO.File]::WriteAllText($targetPath, $templateContent, (New-Object System.Text.UTF8Encoding $false))
    Write-Ok "Applied workstation Codex RTK template: $targetPath"
}

Write-Step "Checking rtk"

$defaultInstallDir = Join-Path $env:USERPROFILE ".local\bin"
if (Test-Path (Join-Path $defaultInstallDir "rtk.exe")) {
    Add-UserPath $defaultInstallDir
}

if (Test-Command "rtk") {
    Write-Ok "rtk found: $(Get-CommandVersion rtk)"
}
elseif ($SkipInstall) {
    Write-Warn "rtk is not installed and installation was skipped."
    return
}
elseif ($env:OS -eq "Windows_NT") {
    Install-RtkWindows
}
else {
    Install-RtkFallback
}

if (Test-Command "rtk") {
    Write-Ok "rtk ready: $(Get-CommandVersion rtk)"
}
else {
    Write-Warn "rtk install finished, but 'rtk' is not available in this terminal yet. Open a new terminal and run 'rtk --version'."
    return
}

if ($SkipInit) {
    Write-Warn "rtk init was skipped."
    return
}

try {
    Write-Host "Initializing rtk hooks for Claude Code/Copilot..."
    rtk init -g
    Ensure-ClaudeRtkHook
    Write-Ok "rtk initialized for Claude Code/Copilot."
}
catch {
    Write-Warn "rtk init -g failed: $($_.Exception.Message)"
    Ensure-ClaudeRtkHook
}

try {
    Write-Host "Initializing rtk hooks for Codex..."
    rtk init -g --codex
    Write-Ok "rtk initialized for Codex."
}
catch {
    Write-Warn "rtk init -g --codex failed: $($_.Exception.Message)"
}

# Apply after rtk init so the workstation template wins over rtk's embedded template.
Ensure-CodexRtkTemplate
