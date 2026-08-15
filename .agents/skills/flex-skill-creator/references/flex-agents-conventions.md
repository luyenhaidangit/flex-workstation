# Flex-Agents Conventions — when the target skill lives in this repo

Read this whenever the skill being designed will live under `flex-agents/skills/` (this repo) rather than being a standalone personal skill for the user's own `~/.claude/skills/`. This repo has its own skill format spec that **overrides** `references/output-template.md` and `references/skill-anatomy.md` — those two files describe the generic Anthropic skill format; this repo enforces a stricter, CI-checked variant of it.

## The repo's spec is the authority, not this skill's generic template

The source of truth is `flex-agents/docs/skill-anatomy.md`, enforced mechanically by `flex-agents/scripts/validate-skills.js`. Read both before generating a skill for this repo — don't rely on memory of the generic template in `references/output-template.md`, the two disagree in specific, checkable ways:

| | Generic (`references/output-template.md`) | This repo (`docs/skill-anatomy.md`) |
|---|---|---|
| Required sections | Purpose, When to Use, When NOT to Use, Core Principles, Operating Procedure, Decision Framework, Mandatory Checks, Anti-Patterns to Prevent, Output Format, Example Prompts, Full Skill Prompt | `## Overview`, `## When to Use`, a process section (`## Core Process` / `## Workflow` / `## Steps`), `## Common Rationalizations`, `## Red Flags`, `## Verification` |
| `name:` frontmatter | lowercase-hyphenated, descriptive | must **match the directory name exactly** — the validator fails otherwise |
| `description:` | pushy, names concrete phrasings | must also contain a literal `Use when …` / `Use before/after/during …` clause (regex-checked) and stay ≤ 1024 characters |
| Reference material | `references/` inside the skill's own folder | shared checklists live in the **project-root** `references/` (`flex-agents/references/`), not inside the skill folder; a skill-owned supporting file inside its own folder is fine only for content specific to that one skill |
| Verification of format | none built in | `node scripts/validate-skills.js` from the `flex-agents/` root — run this before calling the skill done |

## Before creating a new skill directory

Follow the pre-flight in `flex-agents/CONTRIBUTING.md` (see the `#before-proposing-a-new-skill` section) before adding `skills/<name>/`:

1. Search the existing skill catalog (`flex-agents/skills/`) for overlap — prefer extending an existing skill over adding a near-duplicate.
2. Check open PRs/issues on the upstream repo for the same idea already in flight.
3. Be able to state the gap the new skill fills that no existing skill covers.

## Naming

Skills that are specifically customized for Flex (diverge from an upstream/generic version, or are meant to sync via `profiles/flex.json`) are prefixed `flex-` — e.g. `flex-context-engineering`, `flex-dotnet-engineering`, `flex-using-agent-skills`, `flex-skill-creator` itself. A skill ported or adapted from elsewhere for this repo should generally carry the prefix too, unless the user says otherwise.

## When the section headings genuinely don't fit

`docs/skill-anatomy.md` treats its section layout as a recommended pattern, not rigid: "equivalent headings are acceptable when they serve the same purpose clearly." If a skill's real shape doesn't fit the standard flow (a routing/meta-skill, a ported skill with its own established structure), that's a documented exemption in `scripts/validate-skills.js`'s `SECTION_EXEMPT_SKILLS`, not a silent deviation — add an entry there with a one-line reason, the same way `idea-refine` and `flex-skill-creator` itself are exempted.

## Verification step to add for this repo

Before delivering a skill meant for `flex-agents/skills/`, add this to the Quality Bar check (on top of the generic one in SKILL.md):

- [ ] `node scripts/validate-skills.js` (from `flex-agents/`) passes for the new skill, or has a documented exemption with a real reason
- [ ] `name:` frontmatter matches the directory name exactly
- [ ] `description:` contains a literal `Use when …` clause and is under 1024 characters
- [ ] Shared/cross-skill reference material was placed in `flex-agents/references/`, not duplicated inside the skill's own folder
