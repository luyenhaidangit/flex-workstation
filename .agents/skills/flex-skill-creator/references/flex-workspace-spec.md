# Flex Workspace Spec — when the target skill lives in this repo

Read this whenever the skill being designed will live under `.agents/skills/` (this repo, `flex-workstation`) rather than being a standalone personal skill for the user's own `~/.claude/skills/`. This repo has its own house conventions that **override** `references/output-template.md` and `references/skill-anatomy.md` on the points below — those two files describe the generic Anthropic skill format; this repo follows a narrower, observed house style instead.

A real, mechanical check exists for the points below: `node scripts/validate-skills.js` (run from the workspace root, `flex-workstation/`), or `node scripts/validate-skills.js <skill-name>` for just one skill. It also runs automatically as a `PreToolUse` hook on `Write`/`Edit` to any `.agents/skills/**/SKILL.md` (`.claude/hooks/skill-format-guard.js`) — a `name:`/directory mismatch blocks the write; everything else below is advisory (printed as a warning, doesn't block). Run it yourself before delivering a new or edited skill rather than relying solely on the hook.

## Where skills actually live

- **Source of truth:** `.agents/skills/<skill-name>/` — tracked by git, shared across Codex, Antigravity, and Claude Code.
- `.claude/skills/` is a **junction** to `.agents/skills/`, created directly by `scripts/sync-skills.ps1` (repo root) — `SYNC_WORKSPACE.cmd` also produces this as part of its full bootstrap, but `scripts/sync-skills.ps1` is the fast, side-effect-free way to trigger it after creating or retiring a single skill (see "Wiring a new or changed skill" below). It is gitignored — never edit through it, and never create a skill directly there.
- There is **no `flex-agents/` repository** in this workspace's manifest (`workstation.json`). It may still exist as a stray local directory on some machines, but it is not bootstrap-managed and is not the skill source — do not read or write to it.

## House section set (observed, not enforced)

Every `flex-*` engineering skill in this repo (`flex-context-engineering`, `flex-database-engineering`, `flex-naming-convention`, `flex-devops-engineering`, `flex-dotnet-engineering`, `flex-frontend-engineering`) follows the same section shape:

```markdown
---
name: <skill-name>
description: <what it does>. Use when <concrete trigger clause>.
---

# <Skill Title>

## Overview
## When to Use
## Core Process        (or "Workflow" / "Steps" when that reads better)
## <Domain-Specific Section(s)>   (optional — e.g. "Realtime Naming", "Templates", "Artifact-Specific Rules")
## Common Rationalizations
## Red Flags
## Verification
```

Use this shape by default for a skill targeting `.agents/skills/`, in place of the 13-section contract in `references/output-template.md`. A meta/routing skill whose real shape doesn't fit (like `flex-skill-creator` or `flex-using-agent-skills` themselves) may deviate — that's a documented exception, not a silent one: say so explicitly to the user and explain why.

`## Common Rationalizations` and `## Red Flags` do the job that the generic template's "Anti-Patterns to Prevent" does — pair each with why it's wrong and the correct move, same as the generic guidance. `## Verification` is a checklist (`- [ ]` items), same intent as the generic "Mandatory Checks."

## Frontmatter rules

- `name:` — plain (unquoted) YAML, lowercase-hyphenated, **must exactly match the directory name**. The validator (and the `PreToolUse` hook) blocks on a mismatch — but still double-check by eye before delivering.
- `description:` — plain YAML, one paragraph, must contain a literal **"Use when …"** (or "Use during…", "Use before/after…") clause naming concrete triggers, not just a summary of what the skill does.
- Naming prefix: a skill customized for or specific to this Flex workspace/codebase gets the `flex-` prefix (e.g. `flex-dotnet-engineering`). A skill that is a ported lifecycle tool with its own external convention (Speckit) keeps that tool's prefix (`speckit-*`) instead — don't force `flex-` onto it.
- Length: observed `flex-*` descriptions run 175–960 characters.

## Reference material placement

- A supporting file specific to **one** skill's own content goes in that skill's own `references/` (e.g. `flex-skill-creator/references/*.md`).
- There is no shared, cross-skill `references/` directory at the workspace root today. If several skills would genuinely need the same shared material, raise that with the user rather than inventing a new shared location unasked.

## Before creating a new skill directory

1. **Search the existing catalog** (`.agents/skills/`, currently ~20 skills) for overlap. Prefer extending an existing skill (a new section, a new reference file) over adding a near-duplicate. Name the specific gap the new skill fills that no existing skill covers.
2. **Check `flex-using-agent-skills`'s routing table.** A skill that isn't listed there is invisible under this workspace's mandatory routing rule (`AGENTS.md` → "Skill routing bắt buộc"): agents will never select it. Confirm the new skill will get a row before treating the work as done (see "Wiring a new or changed skill" below).

## Wiring a new or changed skill into the workspace

Generating `SKILL.md` is not the last step for a skill targeting this repo. Before calling the work done:

1. **Create it at `.agents/skills/<skill-name>/`** — never under `.claude/skills/` or a standalone `flex-agents/` path.
2. **Add a row to the routing table** in `.agents/skills/flex-using-agent-skills/SKILL.md` (`## Routing table`), naming the task/artifact this skill governs. Without this row the skill is dead weight — nothing will ever select it.
3. **Run `scripts/sync-skills.ps1` yourself** (repo root — a thin wrapper around the portable implementation in `flex-skill-creator/scripts/sync-skills.ps1`, with this workspace's paths filled in) so `.claude/skills/` picks up the new directory for Claude Code immediately — it's local-only and idempotent, no need to hand this back to the user. It also clears any stale junction left over from a retired skill. A plain content edit to an existing skill needs no re-sync: `.claude/skills/<name>` is a junction (a live link into `.agents/skills/<name>`, not a copy), so the edit is visible immediately everywhere.
4. **Codex and Antigravity need no mirror** — both read `.agents/skills/` directly (see `docs/architecture/system-map.md`); only Claude Code hardcodes its own `.claude/skills/` directory, which is why it's the one tool that needs a junction. If a future tool is added that also hardcodes its own skills path, add one more `-MirrorDir` value to the root wrapper's call into `flex-skill-creator/scripts/sync-skills.ps1` and add the folder to the root `.gitignore` next to the existing `.claude/skills/` entry — the generic script already supports multiple mirrors, don't invent a second sync mechanism or fork the script.
5. **If the change alters workspace structure or onboarding** (new category of skill, new convention), flag that `docs/architecture/system-map.md` or `docs/setup/onboarding.md` may need a matching update, per `AGENTS.md`'s documentation rule — don't silently update those docs yourself unless the user's request already covers it.

## Verification

- [ ] `node scripts/validate-skills.js <skill-name>` passes with no errors (warnings are advisory — read them, but they don't block)
- [ ] `name:` frontmatter matches the directory name exactly
- [ ] `description:` contains a literal "Use when …" clause
- [ ] Section set follows the house pattern above, or a deviation is explicitly called out and justified
- [ ] No shared reference material was silently duplicated into a new cross-skill location
- [ ] A row was added to `flex-using-agent-skills`'s routing table (or the skill was flagged to the user as missing one)
- [ ] `scripts/sync-skills.ps1` was run (or the `.claude/skills/` junction was confirmed to already cover it) — not just left as a task for the user
