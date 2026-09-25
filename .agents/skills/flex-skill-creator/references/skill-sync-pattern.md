# Skill Sync Pattern — one source, many tool mirrors

Read this when a skill targets a repo **other than `flex-workstation`** (Step 7.5's workstation-specific wiring is skipped there) but that repo still serves more than one agent tool, and at least one of them hardcodes its own skills directory — Claude Code always reads `.claude/skills/` relative to the project root; it cannot be pointed elsewhere. This is the generalized version of the pattern `flex-workstation` itself uses (`.agents/skills/` + `scripts/sync-skills.ps1`, see `flex-workspace-spec.md`'s "Wiring a new or changed skill into the workspace").

The portable implementation already exists at `scripts/sync-skills.ps1` right next to this file (in this skill's own folder) — it's parameterized (`-SourceDir`, `-MirrorDir`, repeatable), so most repos need zero code changes, just the right arguments. `flex-workstation`'s own `scripts/sync-skills.ps1` (repo root) is a two-line wrapper that calls this same file with `.agents/skills` / `.claude/skills` filled in — that wrapper is the reference example for step 5 below.

## The problem

Every tool that hardcodes its own skills path forces a choice: duplicate each skill's files per tool (drifts the moment either copy is edited) or keep one tracked source of truth and mirror it per tool. `flex-workstation` proves out the second approach and found a real failure mode doing it: a skill retired from the source directory left a dangling mirror behind until a cleanup pass caught it — the sync mechanism must handle removal, not just creation.

## The generalized pattern

1. **Pick one source-of-truth directory**, tracked by git, named for whichever tool reads it natively without needing a hardcoded path of its own. In `flex-workstation` that's `.agents/skills/`, since Codex and Antigravity both read it directly. If every tool in the target repo hardcodes its own path, pick the directory of the tool used most, or a neutral `skills/`.
2. **For every other tool that hardcodes its own skills path**, link each skill from that tool's directory into the source directory — a Windows junction (`New-Item -ItemType Junction`, no admin rights needed) or a Unix symlink (`ln -s`) on non-Windows. Never a copy.
3. **Write one small, standalone, idempotent sync script** that creates missing links and removes links whose source skill no longer exists. Keep it separate from any larger bootstrap/setup script so it runs in well under a second right after a skill is created or retired, with no unrelated side effects (package installs, env config, etc.).
4. **Ignore every mirror directory in `.gitignore`**, with a one-line comment naming the source of truth — the mirror is generated, never hand-edited, and must never be committed as real files.
5. **Run the sync script yourself** at the moment a skill is created or retired, rather than only telling the user to run it — it's local-only and reversible. A plain content edit to an existing skill needs no re-sync: a link mirrors live content automatically.

## Applying this to a different repo

1. Decide that repo's own `SourceDir` and `MirrorDir` values (step 1–2 above) — `.agents/skills` / `.claude/skills` are `flex-workstation`'s own naming choice, not a universal convention.
2. Copy `scripts/sync-skills.ps1` (next to this file) into that repo's own scripts location as-is — it takes `-SourceDir` and one or more `-MirrorDir` values, so it needs no code changes for a different layout.
3. Add a small wrapper in that repo (a few lines, same shape as `flex-workstation`'s root `scripts/sync-skills.ps1`) that calls the copied script with that repo's own paths filled in, so the rest of that repo's tooling can invoke it with no arguments.
4. Ignore the mirror directories in that repo's `.gitignore` and run the wrapper once to confirm it creates the expected links.
