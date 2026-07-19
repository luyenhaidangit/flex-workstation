param(
    [switch]$SkipClaudeInstall,
    [switch]$SkipCcusageInstall,
    [switch]$SkipRtkInstall,
    [switch]$SkipRtkInit,
    [switch]$SkipSpecifyInstall,
    [switch]$SkipSpecifyInit,
    [switch]$UseWinget,
    [switch]$OpenWorkspace
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

function Test-Windows {
    return $env:OS -eq "Windows_NT"
}

function Install-ClaudeCodeNative {
    if (Test-Windows) {
        Write-Host "Installing Claude Code with the official native PowerShell installer..."
        Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
        return
    }

    if (-not (Test-Command "bash")) {
        Write-Warn "Bash is missing. Install Bash or use the platform-specific command from Claude Code docs."
        return
    }

    if (-not (Test-Command "curl")) {
        Write-Warn "curl is missing. Install curl or use the platform-specific command from Claude Code docs."
        return
    }

    Write-Host "Installing Claude Code with the official native installer..."
    bash -lc "curl -fsSL https://claude.ai/install.sh | bash"
}

function Sync-AgentSkills {
    $projectRoot = Resolve-Path "$PSScriptRoot\.."
    $claudeSkillsDir = Join-Path $projectRoot ".claude\skills"
    $agentsSkillsDir = Join-Path $projectRoot ".agents\skills"

    if (-not (Test-Path $claudeSkillsDir)) {
        Write-Warn "No skills found at $claudeSkillsDir - skipping agent skill sync"
        return
    }

    New-Item -ItemType Directory -Force -Path $agentsSkillsDir | Out-Null

    $synced = 0
    foreach ($skill in Get-ChildItem $claudeSkillsDir -Directory) {
        $isJunction = $skill.Attributes -band [System.IO.FileAttributes]::ReparsePoint
        if ($isJunction) {
            # Junction already resolves to .agents/skills/<name>; no copy needed
            $synced++
            continue
        }
        $destPath = Join-Path $agentsSkillsDir $skill.Name
        if (-not (Test-Path $destPath)) {
            New-Item -ItemType Directory -Force -Path $destPath | Out-Null
            Copy-Item -Recurse -Force "$($skill.FullName)\*" "$destPath\"
        }
        Remove-Item -LiteralPath $skill.FullName -Recurse -Force
        New-Item -ItemType Junction -Path $skill.FullName -Target $destPath | Out-Null
        $synced++
    }

    Write-Ok "Agent skills synced: $synced skills (.agents/skills source, .claude/skills junctions)"
}

function Initialize-WorkspaceProjectConfig {
    $projectRoot = Resolve-Path "$PSScriptRoot\.."
    $projectRootClaudePath = Join-Path $projectRoot "CLAUDE.md"
    $projectRootAgentsPath = Join-Path $projectRoot "AGENTS.md"
    $claudeRoot = Join-Path $projectRoot ".claude"
    $agentsRoot = Join-Path $projectRoot ".agents"
    $codexRoot = Join-Path $projectRoot ".codex"
    $settingsSharedPath = Join-Path $claudeRoot "settings.json"
    $settingsPath = Join-Path $claudeRoot "settings.local.json"

    Write-Step "Checking AI assistant runtime configuration"

    New-Item -ItemType Directory -Force -Path $claudeRoot, $agentsRoot, $codexRoot | Out-Null

    if (Test-Path $projectRootClaudePath) {
        Write-Ok "Claude project context found: $projectRootClaudePath"
    }
    else {
        Write-Warn "Claude project context is missing: $projectRootClaudePath"
    }

    if (Test-Path $projectRootAgentsPath) {
        Write-Ok "Codex project context found: $projectRootAgentsPath"
    }
    else {
        Write-Warn "Codex project context is missing: $projectRootAgentsPath"
    }

    if (Test-Path $settingsSharedPath) {
        try {
            Get-Content -Raw -Encoding UTF8 $settingsSharedPath | ConvertFrom-Json | Out-Null
            Write-Ok "Claude shared settings found: $settingsSharedPath"
        }
        catch {
            Write-Warn "Claude shared settings exists but is not valid JSON: $settingsSharedPath"
        }
    }

    if (Test-Path $settingsPath) {
        try {
            Get-Content -Raw -Encoding UTF8 $settingsPath | ConvertFrom-Json | Out-Null
            Write-Ok "Claude local settings found: $settingsPath"
        }
        catch {
            Write-Warn "Claude local settings exists but is not valid JSON: $settingsPath"
        }
    }
    if (Test-Path (Join-Path $codexRoot "config.toml")) {
        Write-Ok "Codex CLI config found: $(Join-Path $codexRoot "config.toml")"
    }
    else {
        Write-Warn "Codex CLI config is missing: $(Join-Path $codexRoot "config.toml")"
    }

    Write-Ok "AI runtime config folders ready: $claudeRoot, $agentsRoot, $codexRoot"
}

function Set-PowerShellUtf8Profile {
    $marker = "# flex-workstation: UTF-8 encoding"
    $profilePath = $PROFILE

    if (Test-Path $profilePath) {
        $existing = Get-Content -Raw -Encoding UTF8 $profilePath
        if ($existing -match [regex]::Escape($marker)) {
            Write-Ok "PowerShell UTF-8 encoding already configured: $profilePath"
            return
        }
    }
    else {
        $profileDir = Split-Path $profilePath
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Force $profileDir | Out-Null
        }
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $lines = [string[]]@(
        "",
        $marker,
        "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8",
        "[Console]::InputEncoding  = [System.Text.Encoding]::UTF8",
        "`$OutputEncoding           = [System.Text.Encoding]::UTF8"
    )
    [System.IO.File]::AppendAllLines($profilePath, $lines, $utf8NoBom)
    Write-Ok "PowerShell UTF-8 encoding configured: $profilePath"
    Write-Warn "Open a new terminal for encoding to take effect"
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  flex-workstation - prepare workstation runtime" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Step "Checking workstation prerequisites"

if (Test-Command "git") {
    Write-Ok "Git found: $(Get-CommandVersion git)"
}
else {
    Write-Warn "Git is missing. Install Git for Windows from https://git-scm.com/download/win."
}

if (Test-Command "code") {
    Write-Ok "VS Code CLI found: $(Get-CommandVersion code)"
}
else {
    Write-Warn "VS Code CLI 'code' is missing. Install VS Code or enable 'code' in PATH."
}

if (Test-Command "winget") {
    Write-Ok "WinGet found."
}
else {
    Write-Warn "WinGet is missing. This is fine because the default Claude Code install path is the native installer."
}

Write-Step "Configuring PowerShell UTF-8 encoding"
Set-PowerShellUtf8Profile

Initialize-WorkspaceProjectConfig

Write-Step "Syncing shared agent skills (.agents/skills source, .claude/skills junctions)"
Sync-AgentSkills

& "$PSScriptRoot\sync-repositories.ps1" -PullExisting

& "$PSScriptRoot\ensure-ccusage.ps1" -SkipInstall:$SkipCcusageInstall

& "$PSScriptRoot\ensure-rtk.ps1" -SkipInstall:$SkipRtkInstall -SkipInit:$SkipRtkInit

Write-Step "Checking Claude Code"

if (Test-Command "claude") {
    Write-Ok "Claude Code found: $(Get-CommandVersion claude)"
}
elseif ($SkipClaudeInstall) {
    Write-Warn "Claude Code is not installed and installation was skipped."
}
elseif ($UseWinget) {
    if (-not (Test-Command "winget")) {
        Write-Warn "WinGet is missing. Install WinGet or re-run without -UseWinget to use the native installer."
    }
    elseif (-not (Test-Windows)) {
        Write-Warn "WinGet installation is only supported on Windows. Re-run without -UseWinget to use the native installer."
    }
    else {
        Write-Host "Installing Claude Code with WinGet..."
        winget install --id Anthropic.ClaudeCode --source winget --accept-package-agreements --accept-source-agreements

        if (Test-Command "claude") {
            Write-Ok "Claude Code installed: $(Get-CommandVersion claude)"
        }
        else {
            Write-Warn "Claude Code install finished, but 'claude' is not available in this terminal yet. Open a new terminal and run 'claude --version'."
        }
    }
}
else {
    Install-ClaudeCodeNative

    if (Test-Command "claude") {
        Write-Ok "Claude Code installed: $(Get-CommandVersion claude)"
    }
    else {
        Write-Warn "Claude Code install finished, but 'claude' is not available in this terminal yet. Open a new terminal and run 'claude --version'."
    }
}

& "$PSScriptRoot\ensure-specify.ps1" -SkipInstall:$SkipSpecifyInstall -SkipInit:$SkipSpecifyInit

Write-Step "Installing selected flex skill profile"

$flexProfileInstaller = Join-Path $PSScriptRoot "install-flex-profile.ps1"
if (Test-Path $flexProfileInstaller) {
    if (Test-Command "claude") {
        try { claude plugin uninstall flex-agents@flex-agents 2>$null } catch { }
    }
    & $flexProfileInstaller -Profile flex -Target Both -Clean -Force
    Write-Ok "Selected flex skill profile installed"
}
else {
    Write-Warn "flex-agents profile installer not found - skipping selected skill installation"
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Workspace template setup finished." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Step "Next steps"
Write-Host "1. Run 'claude' in this repository and complete browser login."
Write-Host "2. Run 'claude doctor' if login or shell integration fails."
Write-Host "3. Open the flex-workstation project root with:"
Write-Host "   .\OPEN_VSCODE.cmd"

if ($OpenWorkspace) {
    if (Test-Command "code") {
        code (Resolve-Path "$PSScriptRoot\..")
    }
    else {
        Write-Warn "Cannot open workspace because the VS Code CLI is missing."
    }
}
