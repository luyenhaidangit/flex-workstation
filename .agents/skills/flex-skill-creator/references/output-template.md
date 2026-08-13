# Output Template — what every generated skill must contain

When you generate a skill (Step 6 of the operating procedure), produce **two things**: a short design summary for the user to read in chat, and the actual `SKILL.md` artifact. Both follow the structure below. Do not skip any required section — a missing decision framework, mandatory-checks section, anti-patterns section, or output format is a defect, not a stylistic choice.

The generated `SKILL.md` itself uses YAML frontmatter (`name`, `description`) followed by a Markdown body. The sections below map onto that body.

---

## Required sections

**1. Skill Name** — lowercase, hyphenated, specific (`db-migration-reviewer`, not `db-helper`). Goes in the `name:` frontmatter field and the H1 title.

**2. Short Description** — one or two sentences, pushy about *when to trigger*, naming concrete user phrasings and contexts. This is the primary triggering mechanism, so it lives in the `description:` frontmatter field and must include both what the skill does and when to use it. Make it slightly insistent (skills tend to under-trigger), e.g. "...use this whenever the user mentions migrations, schema changes, or `ALTER TABLE`, even if they don't say 'review'."

**3. Purpose** — 2–4 sentences on the problem solved, the target user, and the value. Concrete, not aspirational.

**4. When to Use** — the specific situations and request phrasings that should invoke this skill.

**5. When Not to Use** — the near-misses and adjacent cases where the skill should stand down. This is what keeps a skill from over-triggering and annoying the user.

**6. Core Principles** — the 3–6 opinionated beliefs that drive the skill's behavior, each with a one-line rationale. These are the skill's point of view; without them it's just a checklist.

**7. Operating Procedure** — the ordered steps the skill follows. Numbered. Order should matter (if it doesn't, it's a checklist, put it under Mandatory Checks instead). Imperative voice.

**8. Decision Framework** — the rules the skill uses to make judgment calls *automatically* so the user isn't asked the same thing repeatedly. Frame as "when X, do Y because Z." This is the highest-value section and the one most often skipped — never skip it.

**9. Mandatory Checks** — the unordered verifications that must pass before work is considered done. Each check should be objectively determinable (the model can tell whether it passed).

**10. Anti-Patterns to Prevent** — the tempting-but-wrong moves the skill must actively guard against, each with why it's wrong and what to do instead. Derived from the workflow's real failure modes.

**11. Output Format** — the exact shape of what the skill produces (template, schema, file type, section headers). Show the literal structure. A skill without a defined output produces inconsistent freeform results.

**12. Example User Prompts** — exactly 3 realistic prompts a user would type to invoke the skill, with concrete detail (file names, error text, real-sounding context, casual phrasing). These double as triggering documentation.

**13. Full Skill Prompt** — the complete, paste-ready `SKILL.md` content, assembled from the sections above, ready to drop into a skill folder or skill-creation flow with no further editing.

---

## Skeleton to fill in

Use this as the literal structure of the generated `SKILL.md` body:

```markdown
---
name: <skill-name>
description: <pushy when-to-trigger + what-it-does, naming concrete phrasings>
---

# <Skill Name>

<Purpose: 2–4 sentences.>

## When to use
- <situation / phrasing>

## When NOT to use
- <near-miss / adjacent case>

## Core principles
1. **<principle>.** <one-line why.>

## Operating procedure
1. <imperative step>

## Decision framework
- **When <condition>:** <decision> because <reason>.

## Mandatory checks
- <objectively verifiable check>

## Anti-patterns to prevent
- **<anti-pattern>.** Why it's wrong: <reason>. Instead: <correct move>.

## Output format
<literal template / schema / file shape>

## Example prompts
1. "<concrete, casual, detailed user prompt>"
2. "<different phrasing / context>"
3. "<edge or uncommon case>"
```

---

## Style rules for generated skills

- **Imperative voice** for instructions ("Read the file before editing," not "The file should be read").
- **Explain the why** for non-trivial rules; reserve all-caps MUST/NEVER for real safety or correctness invariants.
- **No filler.** If a sentence would be true of every skill, delete it.
- **Scannable.** Short sections, single purpose each, so a future editor can find and change one rule without rereading everything.
- **Length.** Keep the body under ~400 lines; push long per-variant material into `references/` and point to it.
- **Self-contained Full Skill Prompt.** The user must be able to paste it and have a working skill with zero edits.
