---
name: claude-workspace-auditor
description: Audits the Claude Code workspace setup across config integrity, permissions, skill sync, hooks, and lifecycle coverage. Use when setting up a new workspace, after changing settings.json or workspace-assistants.json, when a skill fails to trigger, when hooks seem inactive, or before onboarding a new developer.
---

# Claude Workspace Auditor

## Overview

Runs a structured diagnostic across 5 dimensions of a Claude Code workspace and produces a prioritized findings report. Output is read-only: the skill identifies issues and recommends which tool, skill, or command to use to fix each one — it does not make changes.

## When to Use

**Use when:**
- Setting up a new workspace for the first time
- After editing `settings.json`, `workspace-assistants.json`, or any hook script
- A skill stops triggering despite the correct keyword being used
- A hook appears to be silently doing nothing
- Before onboarding a new developer so they start with a healthy baseline
- Periodically as a health check (after major refactors or dependency updates)

**Do not use when:**
- You want to write or improve a skill → use `agent-instructions-architect` or `skill-creator`
- You want to review a single skill's quality → use `skill-reviewer`
- You want to fix a specific known issue → go directly to the relevant fix

---

## Audit Process

Work through each dimension independently. Mark status as ✅ healthy, ⚠️ warning (works but has risk), or ❌ issue (broken or misconfigured).

### Dimension 1 — Config Integrity

Check every config file for structural validity:

1. Read `settings.json` and `settings.local.json` — confirm valid JSON (no trailing commas, balanced braces)
2. Read `workspace-assistants.json` — confirm valid JSON and all required fields present (`assistants`, `localSkills`)
3. Verify model name in `settings.json` matches a known model ID (e.g., `claude-sonnet-4-6`, `claude-opus-4-8`)
4. For each hook entry in `settings.json`, check that the script path in `args` resolves to an existing file
5. Confirm `settings.json` vs `flex-workstation/templates/project-root/.claude/settings.json` — flag any structural drift (model mismatch, missing fields)

**Status criteria:**
- ✅ All JSON valid, model name recognized, all hook script paths exist, no template drift
- ⚠️ Template drift detected (non-critical fields differ)
- ❌ Invalid JSON, unrecognized model name, or missing hook script

---

### Dimension 2 — Skill Sync Health

Verify that declared skills actually exist and are synced correctly:

1. For each entry in `localSkills` array of `workspace-assistants.json`:
   - Confirm `path` directory exists under `flex-workstation/`
   - Confirm `SKILL.md` exists in that directory
   - Confirm `name:` field in frontmatter matches the declared `name` in config
2. For each `externalSources` entry: confirm `cloneTo` path exists (non-empty, not just `.gitkeep`)
3. Compare skill directories in `.claude/skills/` and `.agents/skills/` — they must match each other
4. Count: `localSkills` count + external skills count = expected total in `.claude/skills/`
5. Check for stale skills in `.claude/skills/` or `.agents/skills/` that are no longer declared in config

**Status criteria:**
- ✅ All declared skills exist with valid SKILL.md, targets match each other, no stale entries
- ⚠️ External source path exists but appears shallow-cloned/empty
- ❌ Missing SKILL.md, name mismatch, or targets out of sync

---

### Dimension 3 — Permissions Fitness

Assess whether the `allow` list in `settings.json` is appropriately calibrated:

1. Read the `permissions.allow` array
2. Flag as **too restrictive** if only `Bash(claude --version)` or similar minimal entries — real work will trigger constant prompts
3. Flag as **too permissive** if wildcard patterns like `Bash(*)` are present
4. Check for commonly needed commands that are missing from the allow list: `git`, `npm`, `node`, `powershell`
5. Note any entries in `settings.local.json` that override or extend `settings.json` permissions

**Recommended action if too restrictive:** run `/fewer-permission-prompts` skill to analyze transcripts and generate a calibrated allowlist.

**Status criteria:**
- ✅ Allow list covers common tools without wildcards
- ⚠️ Only minimal entries — will cause frequent prompts during normal work
- ❌ Wildcard permission (`Bash(*)`) present

---

### Dimension 4 — Hooks Validation

Verify hooks are correctly configured and their scripts are reachable:

1. Read the `hooks` section of `settings.json`
2. For each hook event (e.g., `PreToolUse`, `PostToolUse`, `SessionStart`):
   - Confirm the `matcher` field is a valid regex pattern (test mentally or note for verification)
   - Confirm the script referenced in `command`/`args` exists at the declared path
   - Note any hooks that use absolute paths (fragile across machines) vs relative paths
3. Check that no hook uses a path that only exists on one machine (should use `flex-workstation/scripts/` relative paths)
4. Verify `hooks/` directory in `.claude/` — if present and non-empty, confirm those files are intentionally there

**Status criteria:**
- ✅ All hooks have valid matchers and existing script paths, paths are relative
- ⚠️ Absolute paths used in hook args (works locally, breaks on other machines)
- ❌ Hook script path does not exist

---

### Dimension 5 — Lifecycle Skill Coverage

Assess whether the available skills cover the full development lifecycle:

Map each available skill in `.claude/skills/` to its phase:

| Phase | Expected coverage | Skills to look for |
|-------|-------------------|--------------------|
| Define | Clarify requirements | `interview-me`, `idea-refine`, `spec-driven-development` |
| Plan | Break work into tasks | `planning-and-task-breakdown` |
| Build | Implement correctly | `incremental-implementation`, `test-driven-development`, `source-driven-development`, `frontend-ui-engineering`, `api-and-interface-design` |
| Verify | Catch issues before review | `debugging-and-error-recovery`, `browser-testing-with-devtools` |
| Review | Quality gate | `code-review-and-quality`, `code-simplification`, `security-and-hardening` |
| Ship | Safe deployment | `git-workflow-and-versioning`, `ci-cd-and-automation`, `shipping-and-launch` |

Flag any phase with zero skills as a gap.

**Status criteria:**
- ✅ All 6 phases have at least one skill
- ⚠️ One phase has coverage but only one skill (single point of failure)
- ❌ One or more phases have zero skills

---

## Output Format

Produce a report in this structure:

```
## Workspace Audit Report — [date]

| Dimension | Status | Summary |
|-----------|--------|---------|
| Config integrity | ✅/⚠️/❌ | One-line finding |
| Skill sync health | ✅/⚠️/❌ | One-line finding |
| Permissions fitness | ✅/⚠️/❌ | One-line finding |
| Hooks validation | ✅/⚠️/❌ | One-line finding |
| Lifecycle coverage | ✅/⚠️/❌ | One-line finding |

## Findings (prioritized)

### ❌ Critical
- [finding]: [recommended action + skill/command to use]

### ⚠️ Warnings
- [finding]: [recommended action]

### ✅ Healthy
- [brief confirmation that this dimension passed]
```

---

## Common Rationalizations

| Rationalization | Counter |
|-----------------|---------|
| "Config looks fine visually" | Drift is invisible — template vs actual may differ in a field that only matters at bootstrap time |
| "Skills are working so sync must be correct" | A skill may load a stale copy from a previous sync; the source has moved on |
| "Permissions are fine, I just approve when asked" | Constant approval prompts break flow and create fatigue that leads to over-approving |
| "Hooks ran last week, they're probably still fine" | A path change or script edit can silently break a hook with no error message |
| "I know which skills we have" | Lifecycle gap detection requires mapping skills to phases, not just counting them |

---

## Red Flags

- A skill keyword is typed in a prompt but the skill does not engage — likely a sync issue or name mismatch
- A hook event fires but nothing happens — script path broken or matcher too narrow
- `.claude/skills/` and `.agents/skills/` have different directory counts after a sync
- `workspace-assistants.json` references a `localSkills` path that returns a 404 on Read
- Permissions `allow` list is empty or only `Bash(claude --version)` after the workspace has been used for real work

---

## Verification

A complete audit is done when:

- [ ] All 5 dimensions have been assessed and assigned a status
- [ ] Every ❌ finding has a specific recommended action (not just "fix it")
- [ ] Every ⚠️ warning has been acknowledged as accepted risk or escalated to ❌
- [ ] The findings table is ordered by severity (❌ first)
- [ ] At least one follow-up action or skill invocation is recommended if any issue was found
