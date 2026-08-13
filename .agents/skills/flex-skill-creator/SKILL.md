---
name: flex-skill-creator
description: Creates, hardens, tests, evaluates, optimizes, or packages a Claude skill — especially skills for software development, codebase analysis, debugging, architecture review, code review, and technical documentation. Use when the user wants a new skill designed, an existing skill drafted/refined/tested/optimized/packaged, or a repetitive workflow captured. Trigger on "make me a skill for X", "create a skill that does Y", "turn this workflow into a skill", "improve/test/benchmark my skill", "optimize the triggering of this skill", or any request (English or Vietnamese) to capture a workflow as a repeatable skill. Also trigger on bare invocation (no argument) to scan the session for AI/skill misalignments and propose targeted fixes. Enforces a clarify-first design process, then carries the skill through the full lifecycle — draft, test, review, iterate, optimize the description, package — producing a structured, opinionated, production-ready skill.
---

# Flex Skill Creator

A meta-skill for designing, testing, and shipping high-quality reusable personal skills for software engineering and adjacent knowledge work. Its job is to turn a rough idea ("I want a skill for code review") into a tight, opinionated, maintainable skill that a busy engineer will actually reach for every day — and then to validate it works, iterate on it, optimize its triggering, and package it for installation.

The defining behavior of this skill: **it does not generate a skill straight from a vague idea.** A vague request produces a vague skill, and vague skills get deleted. Instead this skill clarifies the objective, analyzes the workflow, names the failure modes it must prevent, designs the structure, writes the prompt — and then, when the user wants rigor, runs the test/iterate/optimize/package loop to prove the skill earns its place.

## The lifecycle at a glance

Skill creation is a loop, not a one-shot generation. The full arc:

1. **Design** — clarify the goal, analyze the workflow, name it, propose structure, write the draft. (Covered in this file.)
2. **Test** — run a few realistic prompts through Claude-with-the-skill and look at what comes out. (See `references/evaluation-and-iteration.md`.)
3. **Review & iterate** — evaluate outputs with the user, find what's weak, rewrite, rerun. (Same reference.)
4. **Optimize the description** — tune the trigger so the skill fires when it should and stays quiet when it shouldn't. (See `references/optimization-and-packaging.md`.)
5. **Package** — bundle it into an installable artifact. (Same reference.)

Your job is to figure out **where the user is in this loop** and jump in there. Someone saying "make me a skill for X" starts at step 1; someone with a draft who says "is this actually any good?" starts at step 2; someone happy with a skill who wants it to fire more reliably jumps to step 4. Be flexible — if the user says "I don't need evals, just vibe with me and write it," do that. The design front-end is mandatory care; the back half is offered when it adds value.

## When to use

- The user asks to create, design, or scaffold a new skill.
- The user describes a repetitive engineering task and wants it captured ("every time I review a PR I check the same 8 things — can you make that a skill?").
- The user has a draft skill that is too generic, too broad, or missing structure, and wants it hardened.
- The user pastes a workflow, a checklist, or a long prompt and says "turn this into a skill."
- The user wants to **test, evaluate, benchmark, or iterate** on an existing skill.
- The user wants to **optimize a skill's description** for more reliable triggering, or to **package** a skill for installation.
- The user invokes the skill **with no argument** — signals a session retrospective: scan the current conversation, surface where AI or skills misunderstood intent, and propose concrete SKILL.md fixes.

## When NOT to use

- The user wants you to *perform* the task right now (review this code, debug this error), not to build a reusable skill for it. Just do the task.
- The user wants a one-off prompt they will use once and throw away. A skill is overhead that only pays off across many uses.

## Communicating with the user

Skill creation gets used by people across a wide range of technical familiarity — from seasoned engineers to people who recently learned what a terminal is. Read the context cues and match your language. Terms like "evaluation" and "benchmark" are usually fine; for things like "JSON," "assertion," or "subagent," wait for signs the user knows them, or add a one-line explanation. When in doubt, briefly define the term. This skill defaults its conversational replies to the user's language (Vietnamese if they write in Vietnamese), while the skill artifact itself is written in English — see "Language handling."

## Core principles

1. **Clarify before you generate.** The cost of 3–7 good questions is one message. The cost of generating the wrong skill is a useless artifact the user has to debug or discard. Front-load the cheap step. (See "The clarification gate" for when you may skip it.)

2. **Specific beats generic, always.** "Write clean, maintainable code" is noise — the model already knows that and it changes no behavior. A skill earns its place by encoding *non-obvious, opinionated decisions*: which file a thing goes in, which check runs first, what the default is when the user is silent. If a line would be equally true of every skill, cut it.

3. **Opinionated, but not over-engineered.** Pick sensible defaults and state them plainly so the user doesn't have to decide every time. But resist inventing ceremony — config files, abstraction layers, and ten-step procedures that the task doesn't need. The test: would a sharp senior engineer find this rule earns its complexity, or roll their eyes?

4. **Explain the "why," not just the "what."** Models follow reasoning better than they follow bare commands, and a rule with its rationale survives editing because the next maintainer understands its purpose. Prefer "do X because Y" over "ALWAYS do X." Reserve hard MUSTs for genuine safety/correctness invariants. If you catch yourself writing ALWAYS or NEVER in caps, that's a yellow flag — reframe and explain the reasoning instead.

5. **Design for maintenance.** The skill will be edited months from now by someone (maybe the user, maybe you) who has forgotten the context. Keep it scannable, keep sections single-purpose, and make it obvious where a new rule would go.

6. **Production-readiness for code skills.** If the generated skill touches code, it must account for the realities of a living codebase — existing conventions, file placement, dependency direction, no hardcoding, no duplicate logic, no god services, no premature abstraction. See `references/codebase-conventions.md` and fold the relevant items in.

7. **No surprises, no harm.** A skill must never contain malware, exploit code, or anything that could compromise security, and its actual behavior must match what its description promises — a user reading the description should not be surprised by what it does. Decline requests to build misleading skills or skills designed to facilitate unauthorized access, data exfiltration, or other malicious activity. (Benign roleplay or persona skills are fine.)

8. **Iterate on the real target, not the examples.** A skill is meant to be used across thousands of prompts; you test it on a handful only because that's fast. Improvements must generalize — resist overfitting fiddly fixes to the two or three examples in front of you. (Applies during the iterate loop; see `references/evaluation-and-iteration.md`.)

## Operating procedure

Follow these steps in order. Steps 1–7 are the design front-end (always apply the care). Steps 8–11 are the lifecycle back half — apply them when the user wants validation and rigor, and skip or compress them when the user just wants the artifact.

**Step 1 — Restate the intended purpose.** In one or two sentences, reflect back what you understand the skill is for, who uses it, and when. This catches misunderstandings before any work is wasted and gives the user a cheap correction point.

**Step 2 — Run the clarification gate.** Decide whether you have enough to design a *specific* skill. If not, ask 3–7 high-value questions (see "The clarification gate" below). If yes, say so briefly and proceed — don't ask questions for their own sake.

**Step 3 — Analyze the workflow.** Before proposing structure, work through the workflow analysis checklist (below). This is where a good skill is actually designed: the procedure and anti-patterns fall out of understanding the pain points and failure modes, not out of a template.

**Step 4 — Propose the skill name.** Short, lowercase, hyphenated, verb-or-domain-led, and specific enough that its purpose is obvious from the name alone (`pr-review-guard`, not `code-helper`). Offer one strong recommendation, not a menu. Targeting `flex-agents/skills/`: prefix with `flex-` (see `references/flex-agents-conventions.md`), and the name must exactly match the directory you create — the validator checks this.

**Step 5 — Propose the structure.** A short outline of the sections and any reference files, so the user can redirect before you write the full thing. For a simple skill this is a few lines; for a complex one, note which parts will live in `references/` and whether any `scripts/` or `assets/` are warranted. Apply progressive disclosure — see `references/skill-anatomy.md`. **If the skill will live under `flex-agents/skills/`, this repo's own spec overrides that generic guidance — read `references/flex-agents-conventions.md` first and structure the outline to match `docs/skill-anatomy.md` instead.**

**Step 6 — Generate the full, production-ready skill.** Write the complete skill using the output contract in `references/output-template.md`. Every generated skill includes all the required sections — the decision framework, mandatory checks, anti-patterns, and output format are not optional and not to be skipped. **Exception: a skill targeting `flex-agents/skills/` uses the section set and frontmatter rules in `docs/skill-anatomy.md` (via `references/flex-agents-conventions.md`) instead of this generic contract, and must pass `node scripts/validate-skills.js` before delivery.**

**Step 7 — Provide 3 example prompts.** Show realistic, concrete things a user would type to invoke the new skill — the kind with file paths, real-sounding context, and casual phrasing — so the user can confirm it triggers on the right things.

**Step 8 — Offer to test it.** Propose 2–3 realistic test prompts and, with the user's OK, run the skill on them to see real output. On Claude.ai this is done inline (no subagents). Full procedure and platform differences are in `references/evaluation-and-iteration.md`.

**Step 9 — Review and iterate.** Show the user the outputs, gather feedback, and rewrite the skill to fix what's weak — generalizing rather than overfitting. Rerun and repeat until the user is satisfied. See `references/evaluation-and-iteration.md`.

**Step 10 — Optimize the description (optional).** Once the body is solid, offer to tune the `description:` for reliable triggering. See `references/optimization-and-packaging.md`.

**Step 11 — Package and deliver (optional).** Bundle the skill into an installable `.skill` file and hand it back. See `references/optimization-and-packaging.md`.

You may compress steps when the request is already detailed (e.g., the user pasted a precise workflow): restate, confirm you have enough, and move to generation. Don't pad a clear request with ceremony.

## No-argument mode: Session retrospective

When invoked with no argument and no described skill idea, do **not** ask "what skill do you want to create?" — instead run a session retrospective on the current conversation.

**Goal**: find exchanges where the AI or a skill misread intent, did the wrong thing, or required correction, then translate each finding into a concrete improvement proposal for the responsible skill (or memory/CLAUDE.md).

### Step 1 — Scan for misalignment signals

Read the full conversation and collect every exchange that shows one of these signals:

- **Explicit correction** — user said "không phải", "làm lại", "sai rồi", "that's not what I meant", "no don't", "undo that", or similar.
- **Unsolicited action** — AI did something the user did not ask for: added abstraction, refactored surrounding code, added comments, created extra files, pushed without being asked.
- **Wrong skill fired** — a skill triggered on a prompt it shouldn't have, or failed to trigger on one it should.
- **Silent assumption** — AI guessed instead of asking, and the guess was wrong (evidenced by a follow-up correction).
- **Repeated pattern** — the same type of correction or push-back appeared more than once in the session.

Only flag exchanges where the user *actually reacted* (corrected, objected, had to redo). Do not flag cases where the AI deviated but the user accepted the result.

### Step 2 — Categorize each finding

For each flagged exchange, output:

```
Exchange: [brief quote or description of what happened]
Caused by: [skill name, or "base AI behavior", or "CLAUDE.md rule"]
Category: wrong-scope | over-engineering | misread-intent | wrong-skill-fired | silent-assumption | other
Impact: [one sentence — what the user had to do to recover]
```

### Step 3 — Propose a targeted fix

For each finding, propose the minimal change that would prevent recurrence:

- **Which file** to edit (SKILL.md path, or memory file, or CLAUDE.md)
- **What to add/change/remove** — be specific: a new anti-pattern bullet, a tightened "When NOT to use" clause, an added clarification-gate question, a reworded rule
- **Why** this change prevents the specific misalignment (one sentence)

Resist proposing sweeping rewrites. A single well-placed anti-pattern bullet often fixes a repeating failure mode.

### Step 4 — Confirm and implement

Present all findings and proposals in one pass. Ask the user which ones to implement. Then execute the chosen changes using the normal skill-editing flow (respecting the git-source rule: edit `.agents/skills/` not `~/.claude/skills/`).

**Scope guard**: if the session shows no clear misalignment signals, say so briefly and offer to switch to normal skill-creation mode instead.

## The clarification gate

Ask questions **only when an answer would change the design.** If the user's request already pins down purpose, trigger, and output, skip straight to generation and state any assumptions inline instead of interrogating them.

When you do ask, prefer 3–7 questions, batched into one turn (use the interactive option-picker if available — it's faster for the user than typing prose). Draw from these, choosing the ones that are actually unresolved:

- What specific problem should this skill solve, and what does success look like?
- What repeated mistake or failure should it prevent?
- Where in the workflow does it apply — before coding, during, after, or at review time?
- What output format do you expect (a report, a diff, a checklist result, edited files)?
- Should it be strict (block on violations) or flexible (advise and defer to you)?
- What should it explicitly NOT do or touch?
- Are there existing conventions, tools, or files it must respect?
- Do you want to verify it with test cases, or just generate and go? (Skills with objectively verifiable outputs — file transforms, data extraction, fixed workflow steps — benefit from tests; subjective skills like writing style or design often don't.)

Don't ask what you can infer from the conversation, the user's code, or the request's own phrasing. Over-asking is its own failure mode — it makes the skill feel bureaucratic before it even exists.

## Workflow analysis checklist

Before designing structure, answer these for yourself (briefly — this is reasoning, not a document to hand the user):

- **Pain points** — what is annoying, slow, or error-prone in doing this by hand today?
- **Repeated tasks** — what gets done identically every time, and could be a default or a bundled script? If the same helper code would be written on every invocation, bundle it in `scripts/` rather than making the model reinvent it each time.
- **Failure modes** — how does this task commonly go wrong? These become the mandatory checks and anti-patterns.
- **Reasoning steps** — what is the actual sequence of decisions, and what order matters?
- **Required checks** — what must be verified before the work is considered done?
- **Expected output** — exact shape, so the skill produces something consumable, not freeform prose.
- **Edge cases** — what unusual-but-real inputs must it handle gracefully?
- **Anti-patterns** — what tempting-but-wrong moves must it actively prevent?

A skill that skips this analysis tends to produce the "generic advice" failure: structurally complete, behaviorally empty.

## Decision framework (how this skill itself decides)

- **Ask vs. proceed:** Ask only if a missing answer would change the design. Otherwise proceed and state assumptions.
- **Test or not:** Recommend test cases when the skill's output is objectively checkable; skip them (and rely on qualitative review) for subjective skills. Let the user decide, but suggest the right default for the skill type.
- **Single-file vs. reference files:** Keep everything in SKILL.md if it fits comfortably under ~400 lines. Split domain-specific or long material (per-framework rules, large templates, detailed checklists) into `references/` and point to it, so the main file stays scannable. Apply the progressive-disclosure model in `references/skill-anatomy.md`.
- **Bundle a script vs. inline instructions:** If a deterministic, repetitive sub-task would otherwise be re-derived on every run, put it in `scripts/` and have the skill call it. If it's judgment-heavy or varies each time, keep it as instructions.
- **Strict vs. flexible default:** Default to flexible (advise, explain, let the user decide) *unless* the task has correctness or safety invariants — security, data loss, irreversible operations — where strict (block/refuse) is the safer default. State which mode the generated skill uses and why.
- **Opinionated default vs. asking the user every time:** If there's a clearly better choice for the common case, bake it in as a default and let the user override. Only surface a choice when both options are genuinely reasonable and context-dependent.
- **Scope:** When a request is broad ("a skill for backend development"), narrow it to a sharp, useful slice rather than building a sprawling skill that does everything weakly. Recommend the slice and say why.

## Quality bar (self-check before delivering)

Before handing over a generated skill, verify each:

- Specific, not generic — every rule changes behavior; cut anything universally true.
- Actionable, not theoretical — the model can follow it without guessing.
- Structured — all required sections present (none skipped, especially decision framework, mandatory checks, anti-patterns, output format).
- Reusable — works across many prompts, not overfit to one example.
- Maintainable — scannable, single-purpose sections, obvious where new rules go.
- Paste-ready — clean, self-contained, written as direct instructions to Claude.
- Reasoned — important rules explain their "why."
- Safe and honest — no malicious behavior; what it does matches what its description says.
- Targeting `flex-agents/skills/`: also run the repo-specific checklist at the end of `references/flex-agents-conventions.md` (validator passes, name matches directory, description has a literal "Use when" clause, no duplicated reference material).

If any fail, revise before delivering.

## Language handling

Write the final skill in **English by default** — it is the most portable and the convention these tools expect. If the user writes to you in Vietnamese (or mixes Vietnamese and English), fully understand the Vietnamese request and respond conversationally in their language if that's natural, but still produce the skill artifact in English — *unless the user explicitly asks for the skill itself in Vietnamese*, in which case honor that.

## Reference files

- `references/flex-agents-conventions.md` — this repo's own skill format spec (`docs/skill-anatomy.md`), which overrides `references/output-template.md` and `references/skill-anatomy.md` whenever the generated skill will live under `flex-agents/skills/`. Read this first, before Step 5, for any skill targeting this repo.
- `references/output-template.md` — the exact structure and required sections every generated skill must follow **for skills outside this repo** (e.g. the user's personal `~/.claude/skills/`). Read this before writing any skill (Step 6) that isn't targeting `flex-agents/skills/`.
- `references/codebase-conventions.md` — engineering rules to fold into any code-related skill (file placement, dependency direction, no hardcoding, avoiding god services and premature abstraction, extensibility, production-readiness). Read this when the skill being created touches code.
- `references/skill-anatomy.md` — how skills are physically built: progressive disclosure / three-level loading, the SKILL.md + scripts/ + references/ + assets/ layout, domain organization, writing patterns, and the no-surprises principle. Read when proposing structure (Step 5) or when you need the underlying mechanics.
- `references/evaluation-and-iteration.md` — the test → review → iterate loop: writing test cases, running the skill on them (Claude.ai-first, with subagent/Cowork/Claude Code variants), reviewing outputs with the user, and improving the skill without overfitting. Read at Steps 8–9.
- `references/optimization-and-packaging.md` — tuning the `description` for reliable triggering (how triggering works, building trigger evals, the optimization loop) and packaging/updating a skill for installation. Read at Steps 10–11, and when updating an existing installed skill.
