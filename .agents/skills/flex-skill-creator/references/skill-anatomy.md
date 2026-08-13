# Skill Anatomy — how a skill is physically built

Read this when proposing a skill's structure (Step 5) or whenever you need the underlying mechanics of how skills load and what goes where. The `output-template.md` file covers the *content* of a SKILL.md; this file covers the *packaging and loading model* around it.

## Anatomy of a skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions (the body)
└── Bundled resources (optional)
    ├── scripts/    — executable code for deterministic/repetitive tasks
    ├── references/ — docs loaded into context only when needed
    └── assets/     — files used in the output (templates, icons, fonts)
```

Most skills are just a `SKILL.md`. Add bundled resources only when they earn their place (see below).

## Progressive disclosure — the three-level loading model

Skills load in three tiers, and good design exploits this to keep context lean:

1. **Metadata** (name + description) — *always* in context (~100 words). This is the only thing Claude sees when deciding whether to use the skill, so the description carries the entire triggering burden.
2. **SKILL.md body** — loaded *whenever the skill triggers* (aim for under ~400–500 lines). This is the core instructions.
3. **Bundled resources** — loaded *only when needed*. A reference file is read on demand; a script can be executed without its source ever entering context. This tier is effectively unlimited.

These word/line counts are approximate — go longer when the content genuinely needs it. The point is the *shape*: cheap-and-always-present metadata, focused body, heavy detail deferred.

**Design implications:**
- Keep the body scannable and under ~400–500 lines. If you're pushing that limit, add a layer of hierarchy: move detail into `references/` and leave a clear one-line pointer telling the model when to go read it.
- Reference files should be pointed to explicitly from SKILL.md, each with a note on *when* to read it.
- For a large reference file (>300 lines), put a short table of contents at the top.
- A script the skill always runs the same way belongs in `scripts/` — it executes without loading its code into context, which is both faster and cheaper than re-deriving the logic each time.

## When to bundle scripts vs. inline instructions

Bundle a script when the same deterministic, repetitive work would otherwise be re-written on every invocation. The tell, during the iterate loop: if every test run independently produced a near-identical helper (a `create_docx.py`, a `build_chart.py`), that's a strong signal to write it once, drop it in `scripts/`, and have the skill call it. Keep work as inline instructions when it's judgment-heavy or differs each time — scripting that just adds rigidity.

## Domain organization

When one skill must support several variants (frameworks, clouds, languages), organize by variant so Claude reads only the relevant slice:

```
cloud-deploy/
├── SKILL.md          (shared workflow + a selection step)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

The body explains the common workflow and how to pick the variant; each reference holds one variant's specifics. This keeps any single load small even when the skill covers a lot.

## Writing patterns

**Imperative voice.** Write instructions as commands to Claude: "Read the file before editing," not "The file should be read."

**Defining an output format.** Show the literal shape:

```markdown
## Report structure
Use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Examples pattern.** Concrete input→output examples teach better than description. (If "Input"/"Output" labels don't fit the domain, adapt them.)

```markdown
## Commit message format
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

**Explain the why.** Today's models have good theory of mind; a rule with its rationale is followed more intelligently and survives editing because the next maintainer understands its purpose. Reserve all-caps MUST/NEVER for genuine safety or correctness invariants. Rigid, over-constrained structures are a yellow flag — reframe and explain instead.

**Draft, then re-read with fresh eyes.** Write a first version, then look at it anew and cut filler, tighten, and improve. Keep the skill general rather than overfit to the specific examples that prompted it.

## The no-surprises principle

A skill's contents must not surprise the user relative to what its description says it does. Skills must never contain malware, exploit code, or anything that could compromise system security. Don't build misleading skills or skills designed to facilitate unauthorized access, data exfiltration, or other malicious activity. Benign personas ("roleplay as a grumpy code reviewer") are fine; the line is intent and honesty, not playfulness.
