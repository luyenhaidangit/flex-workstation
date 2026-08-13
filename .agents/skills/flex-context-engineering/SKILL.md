---
name: flex-context-engineering
description: Sets up or repairs an agent's rules files (AGENTS.md, CLAUDE.md, .claude/rules/) so agents get the right context without bloat. Use when a repo has no rules file, when CLAUDE.md/AGENTS.md have drifted apart or grown past ~200 lines, when an agent keeps missing project conventions, or when deciding where a new instruction belongs (rules file vs. skill vs. hook).
---

# Context Engineering

## Overview

A rules file is the highest-leverage, highest-risk context an agent gets: read on every session, but liable to do more harm than good if it repeats what the agent could already infer. This skill sets up `AGENTS.md`/`CLAUDE.md` as one source of truth, keeps them to the content that actually changes agent behavior, and routes everything else (path-scoped conventions, multi-step workflows, hard constraints) to the mechanism built for it.

## When to Use

- Repo has no `AGENTS.md`/`CLAUDE.md` yet
- `AGENTS.md` and `CLAUDE.md` contain duplicated or contradicting content
- The rules file is past ~200 lines or has drifted from what the codebase actually does
- An agent keeps missing a convention that IS written down (loading/placement problem, not a missing-fact problem)
- Deciding where a new instruction should live before adding it anywhere

**Not for:** writing a one-off spec or plan (that's session context, not a persistent rules file), or documenting something an agent can already read from `package.json`, `tsconfig`, linter config, or the directory tree — that content does not belong in a rules file at all, see below.

## Core Process

### 1. One source of truth, not two parallel files

Claude Code reads `CLAUDE.md`; it does not read `AGENTS.md`. If the repo already has (or should have) an `AGENTS.md` for other tools/agents, make `CLAUDE.md` import it and add only the Claude-specific part below the import:

```markdown
@AGENTS.md

## Claude Code
Use plan mode for changes under `src/billing/`.
```

On Linux/macOS a symlink (`ln -s AGENTS.md CLAUDE.md`) works if there's nothing Claude-specific to add. On Windows, symlinks need admin rights or Developer Mode — use the import instead. Maintaining two parallel files is the fastest way to have them drift and contradict each other.

### 2. Write the four high-ROI things, delete the rest

Rules files written by people give a small, real improvement (+4%) only when minimal and accurate; LLM-generated rules files measurably *hurt* completion rate and inflate inference cost by 20%+ on real repos, mostly because the agent follows padding too faithfully and over-explores. (Gloaguen et al., 2026.) The fix is subtractive: if the agent can infer it from the repo — directory tree, dependency list, generic architecture description — delete it. Keep only:

- **Exact, runnable commands, placed early.** Full flags, not just the tool name — the agent re-reads this section constantly during a task.
- **NEVER boundaries.** Files not to touch, commands not to run, branches not to push.
- **One real code example** over three paragraphs of prose describing style.
- **Explicit "ask, don't assume" triggers.** Agents default to non-interactive: they guess silently instead of stopping to ask unless told to. In one benchmark this collapsed resolve rate from 48.8% to 28% (AMBIG-SWE, ICLR 2026). Name the specific situations that should stop the agent (schema/API changes, new dependency, 2+ valid approaches with real tradeoffs).

Phrase everything so it's checkable: "use 2-space indentation" not "format code properly"; "run `npm test` before committing" not "test your changes."

### 3. Size and layering

Target under ~200 lines for the main rules file. Splitting content into `@import`s organizes it but does **not** reduce context — imported files still load in full at session start. Real context reduction requires a path-scoped rule instead:

```markdown
---
paths:
  - "src/api/**/*.ts"
---
# API rules
...
```

A rule with `paths:` only activates when Claude reads a matching file. A rule without `paths:` loads unconditionally, every session — treat it as a fixed context tax and keep it short.

| Content | Goes in |
|---|---|
| Project-wide conventions | `AGENTS.md` |
| Claude Code-specific behavior | `CLAUDE.md`, below the import |
| Conventions for one group of files | `.claude/rules/*.md` + `paths:` |
| Multi-step workflow, used occasionally | Skill |
| Constraint that must be blocked no matter what | `PreToolUse` hook / `permissions.deny` |
| Personal preference, not shared with the team | `CLAUDE.local.md` (gitignored) |

The last row is the most commonly misunderstood: rules files are context the model tries to follow, not enforced configuration. A line reading "NEVER push to main" is not a safety mechanism — anything that must be blocked regardless of what the model decides (deleting data, pushing to a protected branch, reading a secret file) needs a `PreToolUse` hook or `permissions.deny`, not markdown.

### 4. Operate on evidence, not speculation

Treat the rules file as the place you record what you'd otherwise have to re-explain: the second time an agent makes the same mistake, the thing a code review caught that the agent should have known, the correction you typed again from a prior session. Don't pre-write rules for hypothetical problems — add an entry only once there's evidence it's needed.

Three commands to use during setup and review:
- `/context` — confirms which files actually loaded (see "Memory files")
- `/memory` — opens the rules file for a quick edit
- `/doctor` — suggests trims to a committed `CLAUDE.md` (cuts directory trees, dependency lists, generic architecture — keeps gotchas, reasons, and anything that overrides tool defaults)

If two rules conflict — root vs. nested `CLAUDE.md`, a `.claude/rules/` file vs. `AGENTS.md` — the agent may pick either arbitrarily. Periodically re-read the full stack (root, nested, `.claude/rules/`) and remove the stale or contradicting one. In a monorepo, use `claudeMdExcludes` in `.claude/settings.local.json` to keep out another team's `CLAUDE.md`.

## Templates

`templates/` in this skill has a ready-to-fill starter kit: `AGENTS.md`, `CLAUDE.md` (import-only), `CLAUDE.local.md.example`, and four `.claude/rules/*.md` examples (`testing`, `api`, `frontend` — all `paths:`-scoped, and `security` — unscoped, to show the difference). `templates/README.md` has the full usage steps, the load-order chain, and a monorepo layout.

Usage: copy the templates into the target repo, fill in every `TODO_`, then **delete every section that doesn't apply** — deleting is as important as filling in. If the repo has nothing yet, `/init` can generate a first draft from the codebase, but treat it as a starting point to cut down, not a deliverable — see point 2 above on why LLM-generated rules files tend to hurt more than help unedited.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "More context can't hurt, it's all relevant" | Agents follow padding too faithfully; irrelevant detail increases exploration and inference cost without improving output (Gloaguen et al., 2026). |
| "I'll just document the directory structure so it navigates faster" | Agents navigate repos fine without it. A directory tree in the rules file is dead weight, not an aid. |
| "@import keeps things organized *and* saves context" | It organizes; it does not save context. Imported files load in full at session start regardless. |
| "A NEVER line is enough to stop something risky" | Rules files are context, not enforcement. Anything that truly must never happen needs a hook or `permissions.deny`. |
| "The agent should just ask if it's unsure" | It won't by default — ambiguity triggers silent guessing unless the rules file explicitly names when to stop and ask. |
| "I'll write the AGENTS.md and CLAUDE.md separately, they're for different tools" | Two hand-maintained copies drift within a few edits. Import one into the other. |

## Red Flags

- `AGENTS.md` and `CLAUDE.md` contain overlapping prose that isn't identical
- Rules file over ~200 lines, or growing every sprint with sprint-specific detail
- Directory tree, dependency list, or generic architecture description sitting in the rules file
- A `NEVER` line for something that would actually be catastrophic if it happened (should be a hook)
- Agent silently picks one of two valid interpretations instead of asking
- A `.claude/rules/*.md` file with no `paths:` that could obviously be scoped to one area

## Verification

- [ ] Exactly one project-wide rules file is hand-maintained; the other tool's file imports it (or is a symlink)
- [ ] Main rules file is under ~200 lines
- [ ] Every command listed under Commands actually runs when copy-pasted
- [ ] Nothing in the file duplicates what linter/CI/type-checker already enforces
- [ ] No directory tree, dependency list, or generic architecture prose remains
- [ ] `NEVER` items that carry real consequences also exist as a hook or `permissions.deny`, not just prose
- [ ] Ambiguity triggers ("ask before X") are named explicitly, not implied
- [ ] `/context` shows the expected files under "Memory files" and nothing unexpected
