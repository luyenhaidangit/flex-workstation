param(
    [switch]$SkipClaudeInstall,
    [switch]$SkipCcusageInstall,
    [switch]$SkipRtkInstall,
    [switch]$SkipRtkInit,
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

function Copy-TemplateDirectory {
    param(
        [string]$TemplatePath,
        [string]$TargetPath,
        [string]$Label,
        [string[]]$PreserveExistingRelativePaths = @()
    )

    if (-not (Test-Path $TemplatePath)) {
        Write-Warn "$Label template not found: $TemplatePath"
        return
    }

    $resolvedTemplatePath = (Resolve-Path $TemplatePath).Path
    New-Item -ItemType Directory -Force -Path $TargetPath | Out-Null

    Get-ChildItem -LiteralPath $resolvedTemplatePath -Directory -Recurse -Force | ForEach-Object {
        $relativePath = $_.FullName.Substring($resolvedTemplatePath.Length).TrimStart('\')
        New-Item -ItemType Directory -Force -Path (Join-Path $TargetPath $relativePath) | Out-Null
    }

    Get-ChildItem -LiteralPath $resolvedTemplatePath -File -Recurse -Force | ForEach-Object {
        if ($_.Name -eq ".gitkeep") {
            return
        }

        $relativePath = $_.FullName.Substring($resolvedTemplatePath.Length).TrimStart('\')
        $targetFilePath = Join-Path $TargetPath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $targetFilePath) | Out-Null

        if ((Test-Path $targetFilePath) -and ($PreserveExistingRelativePaths -contains $relativePath)) {
            Write-Ok "$Label local config preserved: $targetFilePath"
        }
        elseif (Test-Path $targetFilePath) {
            Copy-Item -LiteralPath $_.FullName -Destination $targetFilePath -Force
            Write-Ok "Synced $Label config template: $targetFilePath"
        }
        else {
            Copy-Item -LiteralPath $_.FullName -Destination $targetFilePath
            Write-Ok "Copied $Label config template: $targetFilePath"
        }
    }

    Write-Ok "$Label config folders ready: $TargetPath"
}

function Copy-TemplateFile {
    param(
        [string]$TemplatePath,
        [string]$TargetPath,
        [string]$Label
    )

    if (-not (Test-Path $TemplatePath)) {
        Write-Warn "$Label template not found: $TemplatePath"
        return
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $TargetPath) | Out-Null

    if (Test-Path $TargetPath) {
        Copy-Item -LiteralPath $TemplatePath -Destination $TargetPath -Force
        Write-Ok "Synced $Label template: $TargetPath"
    }
    else {
        Copy-Item -LiteralPath $TemplatePath -Destination $TargetPath
        Write-Ok "Copied $Label template: $TargetPath"
    }
}

function Initialize-WorkspaceProjectConfig {
    $projectRoot = Resolve-Path "$PSScriptRoot\.."
    $templatesRoot = (Resolve-Path "$PSScriptRoot\..\workspaces\templates").Path
    $projectRootClaudeTemplate = Join-Path $templatesRoot "CLAUDE.md"
    $projectRootAgentsTemplate = Join-Path $templatesRoot "AGENTS.md"
    $projectRootClaudePath = Join-Path $projectRoot "CLAUDE.md"
    $projectRootAgentsPath = Join-Path $projectRoot "AGENTS.md"
    $claudeRoot = Join-Path $projectRoot ".claude"
    $agentsRoot = Join-Path $projectRoot ".agents"
    $codexRoot = Join-Path $projectRoot ".codex"
    $settingsSharedPath = Join-Path $claudeRoot "settings.json"
    $settingsPath = Join-Path $claudeRoot "settings.local.json"

    Write-Step "Preparing AI assistant project configuration"

    Copy-TemplateFile -TemplatePath $projectRootClaudeTemplate -TargetPath $projectRootClaudePath -Label "project root CLAUDE.md"
    Copy-TemplateFile -TemplatePath $projectRootAgentsTemplate -TargetPath $projectRootAgentsPath -Label "project root AGENTS.md"

    Copy-TemplateDirectory -TemplatePath (Join-Path $templatesRoot ".claude") -TargetPath $claudeRoot -Label "Claude" -PreserveExistingRelativePaths @("settings.local.json")
    Copy-TemplateDirectory -TemplatePath (Join-Path $templatesRoot ".agents") -TargetPath $agentsRoot -Label "Codex agent"
    Copy-TemplateDirectory -TemplatePath (Join-Path $templatesRoot ".codex") -TargetPath $codexRoot -Label "Codex CLI"

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
Write-Host "  flex-workstation - prepare workspace templates" -ForegroundColor Cyan
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

Initialize-WorkspaceProjectConfig

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

Write-Step "Syncing flex-agents marketplace"

if (Test-Command "claude") {
    claude plugin marketplace add luyenhaidangit/flex-agents 2>$null
    claude plugin marketplace update flex-agents 2>$null
    claude plugin install flex-agents@flex-agents 2>$null
    claude plugin update flex-agents@flex-agents 2>$null
    Write-Ok "flex-agents marketplace and plugin synced"
}
else {
    Write-Warn "Claude Code not found - skipping flex-agents sync"
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
Write-Host "   .\OPEN_WORKSPACE.cmd"

if ($OpenWorkspace) {
    if (Test-Command "code") {
        code (Resolve-Path "$PSScriptRoot\..")
    }
    else {
        Write-Warn "Cannot open workspace because the VS Code CLI is missing."
    }
}
