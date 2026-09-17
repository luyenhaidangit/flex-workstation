# Flex Workspace Spec — when the target skill lives in this repo

Read this whenever the skill being designed will live under `.agents/skills/` (this repo, `flex-workstation`) rather than being a standalone personal skill for the user's own `~/.claude/skills/`. This repo has its own house conventions that **override** `references/output-template.md` and `references/skill-anatomy.md` on the points below — those two files describe the generic Anthropic skill format; this repo follows a narrower, observed house style instead.

There is currently **no automated validator** for this house style — treat every check below as a manual self-check.

## Where skills actually live

- **Source of truth:** `.agents/skills/<skill-name>/` — tracked by git, shared across Codex, Antigravity, and Claude Code.
- `.claude/skills/` is a **junction** to `.agents/skills/`, created by `SYNC_WORKSPACE.cmd`. It is gitignored — never edit through it, and never create a skill directly there.
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

- `name:` — plain (unquoted) YAML, lowercase-hyphenated, **must exactly match the directory name**. This is checkable by eye today (no automated check yet) — always diff the two before delivering.
- `description:` — plain YAML, one paragraph, must contain a literal **"Use when …"** (or "Use during…", "Use before/after…") clause naming concrete triggers, not just a summary of what the skill does.
- Naming prefix: a skill customized for or specific to this Flex workspace/codebase gets the `flex-` prefix (e.g. `flex-dotnet-engineering`). A skill that is a ported lifecycle tool with its own external convention (Speckit) keeps that tool's prefix (`speckit-*`) instead — don't force `flex-` onto it.
- Length: observed `flex-*` descriptions run 175–960 characters. `flex-codebase-architect` currently sits at 1352 characters using folded (`>`) frontmatter and a `name:` that doesn't match its directory (`codebase-architect` vs. the `flex-codebase-architect/` folder) — that's a known existing defect in this repo, not a pattern to copy.

## Reference material placement

- A supporting file specific to **one** skill's own content goes in that skill's own `references/` (e.g. `flex-skill-creator/references/*.md`).
- There is no shared, cross-skill `references/` directory at the workspace root today. If several skills would genuinely need the same shared material, raise that with the user rather than inventing a new shared location unasked.

## Verification

- [ ] `name:` frontmatter matches the directory name exactly
- [ ] `description:` contains a literal "Use when …" clause
- [ ] Section set follows the house pattern above, or a deviation is explicitly called out and justified
- [ ] No shared reference material was silently duplicated into a new cross-skill location
