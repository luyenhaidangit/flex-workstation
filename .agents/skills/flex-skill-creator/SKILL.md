---
name: flex-skill-creator
description: Creates, hardens, tests, evaluates, optimizes, audits, merges, retires, or packages a Claude skill (in .agents/skills/ or a personal skills folder), especially for software development, code review, and technical documentation. Use when the user wants a new skill designed, an existing skill improved, audited, merged or removed, or a repetitive workflow captured. Trigger on "make me a skill for X", "turn this workflow into a skill", "improve/test/optimize my skill", "tạo/review/sửa/gộp/xóa skill", on bare invocation (no argument) or a request to review which skill misread intent in this session (session retrospective), and on "audit/health-check all skills" for a catalog sweep. Do not use for editing AGENTS.md/CLAUDE.md rules (use flex-context-engineering) or for performing the task itself instead of capturing it as a skill.
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
- The user asks you to **review, audit, or "check for improvements" on a specific existing skill** by name or path, standalone — not from a session mistake and not a fresh idea. See "Auditing an existing skill" below.
- The user asks to **audit, health-check, or "review all" skills** in the catalog at once. See "Catalog-wide health check" below.

## When NOT to use

- The user wants you to *perform* the task right now (review this code, debug this error), not to build a reusable skill for it. Just do the task.
- The user wants a one-off prompt they will use once and throw away. A skill is overhead that only pays off across many uses.
- The request is about where an instruction belongs (rules file vs. skill vs. hook) or about editing `AGENTS.md`/`CLAUDE.md`/`.claude/rules/`. That is `flex-context-engineering`'s job; come back here only once it decides the instruction should be a skill.

## Communicating with the user

Skill creation gets used by people across a wide range of technical familiarity — from seasoned engineers to people who recently learned what a terminal is. Read the context cues and match your language. Terms like "evaluation" and "benchmark" are usually fine; for things like "JSON," "assertion," or "subagent," wait for signs the user knows them, or add a one-line explanation. When in doubt, briefly define the term. Language rules (Vietnamese for everything the user reads, English for the skill body) are in "Language handling."

**House-style deviation:** this meta-skill intentionally does not follow the `flex-workspace-spec.md` section set (no `Overview`/`Common Rationalizations`/`Red Flags`/`Verification`). Its sections map to a procedure with several entry modes, which that set does not fit; the Quality bar and Decision framework play the Verification and Red Flags roles.

## Core principles

1. **Clarify before you generate.** The cost of 3–7 good questions is one message. The cost of generating the wrong skill is a useless artifact the user has to debug or discard. Front-load the cheap step. (See "The clarification gate" for when you may skip it.)

2. **Specific beats generic, always.** "Write clean, maintainable code" is noise — the model already knows that and it changes no behavior. A skill earns its place by encoding *non-obvious, opinionated decisions*: which file a thing goes in, which check runs first, what the default is when the user is silent. If a line would be equally true of every skill, cut it.

3. **Opinionated, but not over-engineered.** Pick sensible defaults and state them plainly so the user doesn't have to decide every time. But resist inventing ceremony — config files, abstraction layers, and ten-step procedures that the task doesn't need. The test: would a sharp senior engineer find this rule earns its complexity, or roll their eyes?

4. **Explain the "why," not just the "what."** Models follow reasoning better than they follow bare commands, and a rule with its rationale survives editing because the next maintainer understands its purpose. Prefer "do X because Y" over "ALWAYS do X." Reserve hard MUSTs for genuine safety/correctness invariants. If you catch yourself writing ALWAYS or NEVER in caps, that's a yellow flag — reframe and explain the reasoning instead.

5. **Design for maintenance.** The skill will be edited months from now by someone (maybe the user, maybe you) who has forgotten the context. Keep it scannable, keep sections single-purpose, and make it obvious where a new rule would go.

6. **Production-readiness for code skills.** If the generated skill touches code, it must account for the realities of a living codebase — existing conventions, file placement, dependency direction, no hardcoding, no duplicate logic, no god services, no premature abstraction. See `references/codebase-conventions.md` and fold the relevant items in.

7. **No surprises, no harm.** A skill must never contain malware, exploit code, or anything that could compromise security, and its actual behavior must match what its description promises — a user reading the description should not be surprised by what it does. Decline requests to build misleading skills or skills designed to facilitate unauthorized access, data exfiltration, or other malicious activity. (Benign roleplay or persona skills are fine.)

8. **Iterate on the real target, not the examples.** A skill is meant to be used across thousands of prompts; you test it on a handful only because that's fast. Full rationale lives in `references/evaluation-and-iteration.md` ("Generalize from the feedback") — that's the canonical copy; don't restate it elsewhere.

9. **Portable by default.** Domain logic (the actual how-to-do-the-work content) should read the same if someone copies the skill folder into an unrelated repo — don't bake in the current project's specific paths, service names, or tool choices just because they were on screen while writing it. The one declared exception is a skill whose whole point is this specific repo (Step 0 and Step 4 decide the target); even there, keep the repo-specific wiring (paths, routing-table rows, install steps) isolated in its own `references/` file rather than mixed through the domain logic, so a reader can tell at a glance which parts travel and which don't. This skill follows that rule itself: the wiring checklist lives only in `references/flex-workspace-spec.md`.

## Operating procedure

Follow these steps in order. Steps 1–7 (plus 0 and 7.5 where they apply) are the design front-end (always apply the care). Steps 8–11 are the lifecycle back half — apply them when the user wants validation and rigor, and skip or compress them when the user just wants the artifact.

**Step 0 — Check the catalog (skills targeting `.agents/skills/` only).** Before designing anything, check for overlap. Start with the routing table in `.agents/skills/flex-using-agent-skills/SKILL.md` (`## Routing table`) — it's already a maintained intent→skill index, so scanning it is far cheaper than reading every `SKILL.md` in the catalog. Only open the full `SKILL.md` of a candidate overlap when the table suggests one. Prefer extending an existing skill (a new section, a new reference file) over adding a near-duplicate. When extending a skill's scope, grep its "When NOT to use" and "Do not..." clauses for exclusions the new scope contradicts (e.g. a DevOps skill that forbids introducing Kubernetes) and fix them in the same change, or the skill will argue with itself. Be able to state the specific gap the new skill fills that no existing skill covers. If the overlap is strong enough that the right move is merging into or retiring an existing skill rather than adding a new one, say so and follow "Consolidating or retiring a skill" below instead of proceeding to Step 1. Skip this step for a skill targeting somewhere outside this repo (e.g. the user's personal `~/.claude/skills/`) — there is no shared catalog to check.

**Step 1 — Restate the intended purpose.** In one or two sentences, reflect back what you understand the skill is for, who uses it, and when. This catches misunderstandings before any work is wasted and gives the user a cheap correction point.

**Step 2 — Run the clarification gate.** Decide whether you have enough to design a *specific* skill. If not, ask 3–7 high-value questions (see "The clarification gate" below). If yes, say so briefly and proceed — don't ask questions for their own sake.

**Step 3 — Analyze the workflow.** Before proposing structure, work through the workflow analysis checklist (below). This is where a good skill is actually designed: the procedure and anti-patterns fall out of understanding the pain points and failure modes, not out of a template.

**Step 4 — Propose the skill name.** Short, lowercase, hyphenated, verb-or-domain-led, and specific enough that its purpose is obvious from the name alone (`pr-review-guard`, not `code-helper`). Offer one strong recommendation, not a menu. Targeting `.agents/skills/` (this repo): prefix with `flex-` unless it's a ported lifecycle tool with its own prefix convention (see `references/flex-workspace-spec.md`), and the name must exactly match the directory you create.

**Step 5 — Propose the structure.** A short outline of the sections and any reference files, so the user can redirect before you write the full thing. For a simple skill this is a few lines; for a complex one, note which parts will live in `references/` and whether any `scripts/` or `assets/` are warranted. Apply progressive disclosure — see `references/skill-anatomy.md`. **If the skill will live under `.agents/skills/` (this repo), this repo's house style overrides that generic guidance — read `references/flex-workspace-spec.md` first and structure the outline to match its observed section set instead.**

**Step 6 — Generate the full, production-ready skill.** Write the complete skill using the output contract in `references/output-template.md`, scaled to the skill's size (see "Skill size" in the Decision framework). A non-trivial skill includes the decision framework, mandatory checks, anti-patterns, and output format; a single-workflow skill keeps only the sections that carry real rules. **Exception: a skill targeting `.agents/skills/` (this repo) uses the section set and frontmatter rules in `references/flex-workspace-spec.md` instead of this generic contract.**

**Step 7 — Provide 3 example prompts.** Show realistic, concrete things a user would type to invoke the new skill — the kind with file paths, real-sounding context, and casual phrasing — so the user can confirm it triggers on the right things. Show them in the chat reply only; do not write them into the skill file (they cost tier-2 tokens on every activation and add no instruction).

**Step 7.5 — Wire it into the workspace (skills targeting `.agents/skills/` only).** Generating the file is not the finish line: a skill missing from the router's table is never selected. Follow "Wiring a new or changed skill into the workspace" in `references/flex-workspace-spec.md` (directory, routing-table row, `scripts/sync-skills.ps1`, docs flag) — that file is the single copy of the checklist. For a skill targeting another repo that serves several agent tools with hardcoded skill paths, use `references/skill-sync-pattern.md` instead.

**Step 8 — Offer to test it.** Propose 2–3 realistic test prompts and, with the user's OK, run the skill on them to see real output. Include one value-add run: the same prompt without the skill, to confirm the skill beats zero-shot. On Claude.ai this is done inline (no subagents). Full procedure and platform differences are in `references/evaluation-and-iteration.md`.

**Step 9 — Review and iterate.** Show the user the outputs, gather feedback, and rewrite the skill to fix what's weak — generalizing rather than overfitting. Rerun the new cases and every case that passed before the edit (regression), and repeat until the user is satisfied. Before delivery, run the independent adversarial review described in "Quality bar." See `references/evaluation-and-iteration.md`.

**Step 10 — Optimize the description (optional).** Once the body is solid, offer to tune the `description:` for reliable triggering. See `references/optimization-and-packaging.md`.

**Step 11 — Package and deliver (optional).** Bundle the skill into an installable `.skill` file and hand it back. See `references/optimization-and-packaging.md`.

You may compress steps when the request is already detailed (e.g., the user pasted a precise workflow): restate, confirm you have enough, and move to generation. Don't pad a clear request with ceremony.

## No-argument mode: Session retrospective

When invoked with no argument and no described skill idea, do **not** ask "what skill do you want to create?" — instead run a session retrospective on the current conversation.

**Goal**: find exchanges where the AI or a skill misread intent, did the wrong thing, or required correction, then translate each finding into a concrete improvement proposal for the responsible skill (or memory/CLAUDE.md).

### R1 — Scan for misalignment signals

Read the full conversation and collect every exchange that shows one of these signals:

- **Explicit correction** — user said "không phải", "làm lại", "sai rồi", "that's not what I meant", "no don't", "undo that", or similar.
- **Unsolicited action** — AI did something the user did not ask for: added abstraction, refactored surrounding code, added comments, created extra files, pushed without being asked.
- **Wrong skill fired** — a skill triggered on a prompt it shouldn't have, or failed to trigger on one it should.
- **Silent assumption** — AI guessed instead of asking, and the guess was wrong (evidenced by a follow-up correction).
- **Repeated pattern** — the same type of correction or push-back appeared more than once in the session.

Only flag exchanges where the user *actually reacted* (corrected, objected, had to redo). Do not flag cases where the AI deviated but the user accepted the result.

### R2 — Categorize each finding

For each flagged exchange, output (labels in Vietnamese; the `Loại` values stay as identifiers):

```
Sự việc: [trích ngắn hoặc mô tả điều đã xảy ra]
Nguyên nhân: [tên skill, hoặc "hành vi mặc định của AI", hoặc "quy tắc CLAUDE.md"]
Loại: wrong-scope | over-engineering | misread-intent | wrong-skill-fired | silent-assumption | other
Tác động: [một câu — người dùng phải làm gì để khắc phục]
```

### R3 — Propose a targeted fix

For each finding, propose the minimal change that would prevent recurrence:

- **Which file** to edit (SKILL.md path, or memory file, or CLAUDE.md)
- **What to add/change/remove** — be specific: a new anti-pattern bullet, a tightened "When NOT to use" clause, an added clarification-gate question, a reworded rule
- **Why** this change prevents the specific misalignment (one sentence)

Resist proposing sweeping rewrites. A single well-placed anti-pattern bullet often fixes a repeating failure mode.

### R4 — Confirm and implement

Present all findings and proposals in one pass. Ask the user which ones to implement. Then execute the chosen changes using the normal skill-editing flow (respecting the git-source rule: edit `.agents/skills/` not `~/.claude/skills/`).

**Scope guard**: if the session shows no clear misalignment signals, say so briefly and offer to switch to normal skill-creation mode instead.

## Auditing an existing skill

Triggered by a request to review, audit, or find improvements in one named skill — distinct from the no-argument session retrospective (which looks at *this conversation*, not a skill's own file) and from ordinary "harden my draft" requests (which assume the user is mid-design). Here the skill already exists and is presumably working; the job is a cold, standalone quality pass.

1. Read the skill's `SKILL.md` and every file it references — don't review from memory or a partial read.
2. If it targets `.agents/skills/`, run `node scripts/validate-skills.js <skill-name>` for the mechanical checks.
3. Judge the skill against the five criteria in `references/audit-rubric.md` (trigger precision, context efficiency, instruction clarity, tool and script safety, output determinism), plus `references/flex-workspace-spec.md`'s Verification checklist if it targets this repo. Take the adversarial stance described there: assume defects exist and look for them.
4. Report findings only, in Vietnamese, each with severity (Blocker / Major / Minor), file and section, what is wrong, why it matters, and replacement text or a diff. Skip praise for things that are merely fine; a finding-free section needs no line.
5. Ask which findings to implement before touching any files. A full audit often surfaces more than the user wants fixed today.

This mode skips Steps 1–5 of the operating procedure entirely (there's no new name or structure to propose).

## Catalog-wide health check

Triggered by an explicit request to audit, health-check, or "review all" skills in `.agents/skills/` — the same idea as "Auditing an existing skill" above, but run over every skill instead of one.

1. Run `node scripts/validate-skills.js` with no argument (validates the whole catalog) for the mechanical checks.
2. For each skill, check the same drift patterns this skill's own house style calls out: missing `evals/` despite the skill's domain recommending them, description length outside the range `validate-skills.js` accepts (the validator is the only place the limit lives), a missing routing-table row in `flex-using-agent-skills`, a description missing a literal "Use when" clause, and reference material duplicated instead of pointed-to.
3. Group findings by skill, most actionable first, with the severity scale from `references/audit-rubric.md`. Skip a skill entirely if it has no findings — don't manufacture filler to look thorough.
4. Present all findings in one pass using the finding format in `references/audit-rubric.md` (each with replacement text or a diff), and ask which to implement before editing anything — a catalog-wide audit touches many files, so confirm scope first.

Keep this to the mechanical/structural checks above, not a content rewrite of each skill's domain logic — a finding that needs deeper rework is a separate, per-skill conversation (use "Auditing an existing skill" for that one skill) once this pass surfaces it as a candidate.

## Consolidating or retiring a skill

Skill creation isn't the only outcome of a catalog check. Reach for this instead of a new skill when:

- **Step 0 finds real overlap** — two skills would fire on largely the same tasks. Merge the weaker one into the stronger: fold its distinctive rules in as a section or `references/` file, update its description if the merge widens scope, then delete the absorbed skill's directory and remove its routing-table row.
- **A skill has gone stale** — its conventions no longer match the codebase, or a session retrospective (no-argument mode) repeatedly points at the same skill for wrong-scope or misread-intent findings that a targeted fix hasn't resolved after a couple of iterations.
- **The user asks to retire a skill outright.**

Retiring a skill means: delete `.agents/skills/<skill-name>/`, remove its row from `flex-using-agent-skills`'s routing table, and confirm `.claude/skills/` still links to `.agents/skills/` (see `references/flex-workspace-spec.md`; the whole-directory link needs no re-sync).

Deleting a directory and editing the shared router affect every task in the workspace, so get explicit approval first: ask with `AskUserQuestion` (or directly in chat if that tool is unavailable), listing the skill to be absorbed or removed, the reason, and the routing row that will go. Perform the deletion only after the user chooses to proceed; if they decline, leave everything as it is.

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
- **Skill size:** A skill with one workflow and no scripts keeps only Overview/When to Use/Core Process/Verification (or the generic equivalents). Add a decision framework, rationalizations/red flags, or an output format only when a real failure mode or a report/file output needs it, because every extra section is loaded on each activation. A skill that produces a report or file always gets an output format with a literal example.
- **Value-add:** If a test shows the skill's output is not clearly better than the same prompt without it, tell the user the skill is redundant and recommend not shipping it.
- **Scope:** When a request is broad ("a skill for backend development"), narrow it to a sharp, useful slice rather than building a sprawling skill that does everything weakly. Recommend the slice and say why.

## Quality bar (self-check before delivering)

Before handing over a generated skill, verify each:

- Specific, not generic — every rule changes behavior; cut anything universally true.
- Actionable, not theoretical — the model can follow it without guessing.
- Structured — the sections its size calls for are present (see "Skill size"), and any skill producing a report or file has an output format with an example.
- Reusable — works across many prompts, not overfit to one example.
- Maintainable — scannable, single-purpose sections, obvious where new rules go.
- Paste-ready — clean, self-contained, written as direct instructions to Claude.
- Reasoned — important rules explain their "why."
- Portable — no current-project path, service name, or tool assumption leaked into the domain logic unless the skill explicitly targets this repo; any such glue that does belong is isolated in its own section or `references/` file, not scattered through the core instructions.
- Safe and honest — no malicious behavior; what it does matches what its description says.
- Targeting `.agents/skills/` (this repo): run `node scripts/validate-skills.js <skill-name>` and the checklist in `references/flex-workspace-spec.md` (name matches directory, description has a literal "Use when" clause, no duplicated reference material, routing-table row added per Step 7.5).

If any fail, revise before delivering.

**Independent adversarial review.** The author reviewing its own draft tends to approve it. After the self-check, review the skill once more as a hostile reviewer who assumes defects exist and scores it with `references/audit-rubric.md`. Where subagents exist (Claude Code), spawn a fresh `Agent` with no design context, only the skill path and the rubric path, and have it report findings. Where they don't, run the rubric as a separate pass and label the result "self-review, not independent" in the delivery message. Fix every Blocker and Major finding, or tell the user why one stays.

## Tracking changes

Don't add a `CHANGELOG.md` or a version field to a skill — git history over `.agents/skills/<skill-name>/` is the changelog. When you edit a skill for a specific reason (a no-argument-mode fix, an audit finding, a triggering tweak), say so in the commit message so `git log --follow SKILL.md` stays a readable record of why the skill looks the way it does.

## Language handling

Two languages, split by audience:

- **Skill file (SKILL.md, references, evals):** English by default, the convention the catalog and these tools expect, unless the user explicitly asks for the skill itself in Vietnamese.
- **Everything the user reads** (design summary, questions, audit and retrospective reports, finding labels, delivery message): Vietnamese with diacritics, as `AGENTS.md` requires. Keep skill names, file names, commands and other technical identifiers in English.

## Reference files

- `references/flex-workspace-spec.md` — this repo's own house style for skills (where they live, the observed section set, frontmatter rules, reference-material placement, the routing/wiring checklist), which overrides `references/output-template.md` and `references/skill-anatomy.md` whenever the generated skill will live under `.agents/skills/` (this repo, `flex-workstation`). Read this first, before Step 5, for any skill targeting this repo.
- `references/audit-rubric.md` — the five-criterion rubric, severity scale (Blocker/Major/Minor), adversarial stance, and finding format. Read when auditing a skill (named or catalog-wide) and for the pre-delivery review in the Quality bar.
- `references/skill-sync-pattern.md` — the generalized, repo-agnostic version of `flex-workstation`'s own source-of-truth + per-tool-mirror + sync-script pattern. Read this at Step 7.5 when the skill targets a different repo that also serves multiple agent tools with hardcoded skill paths.
- `references/output-template.md` — the exact structure and required sections every generated skill must follow **for skills outside this repo** (e.g. the user's personal `~/.claude/skills/`). Read this before writing any skill (Step 6) that isn't targeting `.agents/skills/`.
- `references/codebase-conventions.md` — engineering rules to fold into any code-related skill (file placement, dependency direction, no hardcoding, avoiding god services and premature abstraction, extensibility, production-readiness). Read this when the skill being created touches code.
- `references/skill-anatomy.md` — how skills are physically built: progressive disclosure / three-level loading, the SKILL.md + scripts/ + references/ + assets/ layout, domain organization, writing patterns, and the no-surprises principle. Read when proposing structure (Step 5) or when you need the underlying mechanics.
- `references/evaluation-and-iteration.md` — the test → review → iterate loop: writing test cases, running the skill on them (Claude.ai-first, with subagent/Cowork/Claude Code variants), reviewing outputs with the user, and improving the skill without overfitting. Read at Steps 8–9.
- `references/optimization-and-packaging.md` — tuning the `description` for reliable triggering (how triggering works, building trigger evals, the optimization loop) and packaging/updating a skill for installation. Read at Steps 10–11, and when updating an existing installed skill.
