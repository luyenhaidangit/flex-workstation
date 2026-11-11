$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path "$PSScriptRoot\.."
$source = Join-Path $projectRoot ".agents\skills"
$mirror = Join-Path $projectRoot ".claude\skills"

# Codex and Antigravity read .agents/skills directly and need no mirror;
# only Claude Code hardcodes its own .claude/skills. Link the whole directory
# (one junction) so skills added to .agents/skills show up with no re-sync.
# Do NOT call the per-skill generic sync with Source == Mirror: it would
# delete the real skill folders.

function Test-Link([string]$Path) {
    (Get-Item -LiteralPath $Path -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint
}

if (-not (Test-Path $source)) {
    Write-Host "[WARN] No skills found at $source - skipping" -ForegroundColor Yellow
    return
}

New-Item -ItemType Directory -Force -Path (Split-Path $mirror) | Out-Null

if (Test-Path -LiteralPath $mirror) {
    if (Test-Link $mirror) {
        Write-Host "[OK] $mirror already links to $source" -ForegroundColor Green
        return
    }
    # Legacy layout: a real directory holding one link per skill. Remove only
    # the links (Directory.Delete on a link never touches its target); refuse
    # if anything else is inside so no real file is lost.
    $children = Get-ChildItem -LiteralPath $mirror -Force
    $real = $children | Where-Object { -not (Test-Link $_.FullName) }
    if ($real) {
        throw "$mirror has non-link entries ($($real.Name -join ', ')); move them to $source first."
    }
    foreach ($child in $children) { [System.IO.Directory]::Delete($child.FullName) }
    [System.IO.Directory]::Delete($mirror)
}

if ($env:OS -eq "Windows_NT") {
    New-Item -ItemType Junction -Path $mirror -Target $source | Out-Null
}
else {
    New-Item -ItemType SymbolicLink -Path $mirror -Target $source | Out-Null
}
Write-Host "[OK] $mirror -> $source" -ForegroundColor Green
