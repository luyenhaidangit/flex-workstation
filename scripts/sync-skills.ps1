$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path "$PSScriptRoot\.."
$genericSync = Join-Path $projectRoot ".agents\skills\flex-skill-creator\scripts\sync-skills.ps1"

# flex-workstation's own paths for the portable sync pattern documented in
# .agents/skills/flex-skill-creator/references/skill-sync-pattern.md.
# Codex and Antigravity read .agents/skills directly and need no mirror;
# only Claude Code hardcodes its own .claude/skills.
& $genericSync `
    -SourceDir (Join-Path $projectRoot ".agents\skills") `
    -MirrorDir (Join-Path $projectRoot ".claude\skills")
