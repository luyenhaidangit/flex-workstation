<#
.SYNOPSIS
  Keeps one or more "mirror" skill directories in sync with a single tracked
  source-of-truth skills directory, via one OS-level link per skill folder
  (Windows junction, or a symlink on non-Windows). Creates missing links and
  removes links whose source skill no longer exists.

  This is the portable implementation of the pattern documented in
  ../references/skill-sync-pattern.md. flex-workstation's own
  scripts/sync-skills.ps1 (repo root) is a thin wrapper around this file
  with this repo's own paths filled in — copy this file into another repo's
  scripts/ and pass -SourceDir/-MirrorDir for its own layout instead of
  duplicating the logic.

.PARAMETER SourceDir
  The tracked skills directory that is the source of truth (each immediate
  subfolder is one skill).

.PARAMETER MirrorDir
  One or more directories that should mirror SourceDir. Add one entry per
  agent tool that hardcodes its own skills path (e.g. Claude Code always
  reads "<repo>/.claude/skills"). Repeatable.

.EXAMPLE
  ./sync-skills.ps1 -SourceDir ".agents/skills" -MirrorDir ".claude/skills"

.EXAMPLE
  ./sync-skills.ps1 -SourceDir "skills" -MirrorDir ".claude/skills", ".other-tool/skills"
#>
param(
    [Parameter(Mandatory)]
    [string]$SourceDir,

    [Parameter(Mandatory)]
    [string[]]$MirrorDir
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

function Sync-SkillMirror {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Mirror
    )

    if (-not (Test-Path $Source)) {
        Write-Warn "No skills found at $Source - skipping sync into $Mirror"
        return
    }

    New-Item -ItemType Directory -Force -Path $Mirror | Out-Null
    $isWindows = $env:OS -eq "Windows_NT"

    $sourceNames = @{}
    $synced = 0
    foreach ($skill in Get-ChildItem $Source -Directory) {
        $sourceNames[$skill.Name] = $true
        $linkPath = Join-Path $Mirror $skill.Name
        if (Test-Path $linkPath) {
            $existing = Get-Item -LiteralPath $linkPath -Force
            $isLink = $existing.Attributes -band [System.IO.FileAttributes]::ReparsePoint
            if ($isLink) {
                # Link already points at the source skill; nothing to do
                $synced++
                continue
            }
            # Stale real copy from an older checkout; replace with a link
            Remove-Item -LiteralPath $linkPath -Recurse -Force
        }
        if ($isWindows) {
            New-Item -ItemType Junction -Path $linkPath -Target $skill.FullName | Out-Null
        }
        else {
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $skill.FullName | Out-Null
        }
        $synced++
    }

    $removed = 0
    foreach ($link in Get-ChildItem $Mirror -Directory -Force) {
        if ($sourceNames.ContainsKey($link.Name)) {
            continue
        }
        $isLink = $link.Attributes -band [System.IO.FileAttributes]::ReparsePoint
        if (-not $isLink) {
            continue
        }
        # Source skill was deleted/retired; clear the dangling link
        Remove-Item -LiteralPath $link.FullName -Force
        Write-Ok "Removed stale link for retired skill: $($link.Name)"
        $removed++
    }

    Write-Ok "$Mirror synced: $synced skill(s) linked from $Source, $removed stale link(s) removed"
}

Write-Step "Syncing skill mirrors"
foreach ($mirror in $MirrorDir) {
    Sync-SkillMirror -Source $SourceDir -Mirror $mirror
}
