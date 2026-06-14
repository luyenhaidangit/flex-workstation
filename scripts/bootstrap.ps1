param(
    [switch]$SkipClaudeInstall,
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

function Initialize-ClaudeProjectConfig {
    $projectRoot = Resolve-Path "$PSScriptRoot\..\.."
    $templateRoot = (Resolve-Path "$PSScriptRoot\..\templates\project-root\.claude").Path
    $projectRootClaudeTemplate = Join-Path $PSScriptRoot "..\templates\project-root\CLAUDE.md"
    $projectRootAgentsTemplate = Join-Path $PSScriptRoot "..\templates\project-root\AGENTS.md"
    $projectRootClaudePath = Join-Path $projectRoot "CLAUDE.md"
    $projectRootAgentsPath = Join-Path $projectRoot "AGENTS.md"
    $claudeRoot = Join-Path $projectRoot ".claude"
    $agentsTemplateRoot = Join-Path $PSScriptRoot "..\templates\project-root\.agents"
    $agentsRoot = Join-Path $projectRoot ".agents"
    $settingsSharedPath = Join-Path $claudeRoot "settings.json"
    $settingsPath = Join-Path $claudeRoot "settings.local.json"

    Write-Step "Preparing AI assistant project configuration"

    if (Test-Path $projectRootClaudeTemplate) {
        if (Test-Path $projectRootClaudePath) {
            Write-Ok "Workspace root CLAUDE.md already exists: $projectRootClaudePath"
        }
        else {
            Copy-Item -LiteralPath $projectRootClaudeTemplate -Destination $projectRootClaudePath
            Write-Ok "Copied workspace root CLAUDE.md: $projectRootClaudePath"
        }
    }

    if (Test-Path $projectRootAgentsTemplate) {
        if (Test-Path $projectRootAgentsPath) {
            Write-Ok "Workspace root AGENTS.md already exists: $projectRootAgentsPath"
        }
        else {
            Copy-Item -LiteralPath $projectRootAgentsTemplate -Destination $projectRootAgentsPath
            Write-Ok "Copied workspace root AGENTS.md: $projectRootAgentsPath"
        }
    }

    New-Item -ItemType Directory -Force -Path $claudeRoot | Out-Null

    Get-ChildItem -LiteralPath $templateRoot -Directory -Recurse -Force | ForEach-Object {
        $relativePath = $_.FullName.Substring($templateRoot.Length).TrimStart("\")
        New-Item -ItemType Directory -Force -Path (Join-Path $claudeRoot $relativePath) | Out-Null
    }

    Get-ChildItem -LiteralPath $templateRoot -File -Recurse -Force | ForEach-Object {
        if ($_.Name -eq ".gitkeep") {
            return
        }

        $relativePath = $_.FullName.Substring($templateRoot.Length).TrimStart("\")
        $targetPath = Join-Path $claudeRoot $relativePath
        $targetDirectory = Split-Path -Parent $targetPath

        New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null

        if (Test-Path $targetPath) {
            Write-Ok "Claude config already exists: $targetPath"
        }
        else {
            Copy-Item -LiteralPath $_.FullName -Destination $targetPath
            Write-Ok "Copied Claude config template: $targetPath"
        }
    }

    if (Test-Path $agentsTemplateRoot) {
        $resolvedAgentsTemplateRoot = (Resolve-Path $agentsTemplateRoot).Path

        New-Item -ItemType Directory -Force -Path $agentsRoot | Out-Null

        Get-ChildItem -LiteralPath $resolvedAgentsTemplateRoot -Directory -Recurse -Force | ForEach-Object {
            $relativePath = $_.FullName.Substring($resolvedAgentsTemplateRoot.Length).TrimStart("\")
            New-Item -ItemType Directory -Force -Path (Join-Path $agentsRoot $relativePath) | Out-Null
        }

        Get-ChildItem -LiteralPath $resolvedAgentsTemplateRoot -File -Recurse -Force | ForEach-Object {
            if ($_.Name -eq ".gitkeep") {
                return
            }

            $relativePath = $_.FullName.Substring($resolvedAgentsTemplateRoot.Length).TrimStart("\")
            $targetPath = Join-Path $agentsRoot $relativePath
            $targetDirectory = Split-Path -Parent $targetPath

            New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null

            if (Test-Path $targetPath) {
                Write-Ok "Codex config already exists: $targetPath"
            }
            else {
                Copy-Item -LiteralPath $_.FullName -Destination $targetPath
                Write-Ok "Copied Codex config template: $targetPath"
            }
        }

        Write-Ok "Codex config folders ready: $agentsRoot"
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
    Write-Ok "Claude config folders ready: $claudeRoot"
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  flex-workstation - sync workspace" -ForegroundColor Cyan
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

Initialize-ClaudeProjectConfig

& "$PSScriptRoot\sync-workspace-skills.ps1"

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

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Workspace sync finished." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Step "Next steps"
Write-Host "1. Run 'claude' in this repository and complete browser login."
Write-Host "2. Run 'claude doctor' if login or shell integration fails."
Write-Host "3. Open the shared workspace with:"
Write-Host "   .\OPEN_WORKSPACE.cmd"

if ($OpenWorkspace) {
    if (Test-Command "code") {
        code (Resolve-Path "$PSScriptRoot\..\..")
    }
    else {
        Write-Warn "Cannot open workspace because the VS Code CLI is missing."
    }
}
