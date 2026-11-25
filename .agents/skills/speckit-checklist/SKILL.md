---
name: "speckit-checklist"
description: "Generate a custom checklist for the current feature based on user requirements."
argument-hint: "Domain or focus area for the checklist"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/checklist.md"
user-invocable: true
disable-model-invocation: true
---


## Checklist Purpose: "Unit Tests for Requirements"

Checklists validate the **quality, clarity, completeness, consistency, and measurability of requirements** in a given domain — NOT whether the code/implementation works.
- Prohibited: items starting with "Verify/Test/Confirm/Check" + runtime behavior ("displays correctly", "click", "returns 200", QA test cases).
- Required: questions about what is written or missing in `spec.md`/`plan.md` (e.g., *"Is 'fast loading' quantified with specific timing thresholds? [Clarity, Spec §NFR-2]"*).
- For domain-specific sample items (`ux`, `api`, `performance`, `security`) and anti-examples, read `.agents/skills/speckit-checklist/references/domain-examples.md`.

## User Input

```text
$ARGUMENTS
```

## Active Feature Reporting

In the Completion Report, print `ACTIVE_FEATURE_DIRECTORY: <resolved FEATURE_DIR>` as the first line before any other result.

You **MUST** consider the user input before proceeding (if not empty).

## Extension Hooks Protocol

`scripts/speckit-cli.js check-prereqs --paths-only --stage checklist --json` reads `.specify/extensions.yml` and returns `HOOKS: { before: [...], after: [...] }`.
- If a hook list is empty, skip silently without reading `.specify/extensions.yml` again.
- For each entry in `HOOKS.before` (after Step 1) or `HOOKS.after` (before finishing): if `optional: true`, display `Command: \`{slashCommand}\``, `Description`, and `Prompt`; if `optional: false`, emit `EXECUTE_COMMAND: {command}`, invoke it, and wait for completion.

## Execution Steps

1. **Setup**: Run `node scripts/speckit-cli.js check-prereqs --paths-only --stage checklist --json` (adding `--feature "<feature-ref>"` if the user named a feature ID/directory in `$ARGUMENTS`) from repo root and parse `FEATURE_DIR`, `FEATURE_SPEC`, `IMPL_PLAN`, `TASKS`, and `HOOKS`. Dispatch `HOOKS.before` if non-empty. All file paths must be absolute.

2. **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints.

3. **Clarify intent (dynamic)**: Derive up to 3 initial contextual clarifying questions from `$ARGUMENTS` and feature signals (domain keywords, risk indicators, audience, missing dimensions). Skip any question already unambiguous in `$ARGUMENTS`.
   - Prefer an interactive question picker (`ask_question` / `AskUserQuestion`) when available; otherwise output Q1–Q3 with compact A–E option tables (`Option | Candidate | Why It Matters`).
   - Defaults when interaction is unnecessary/impossible: Depth = Standard; Audience = Reviewer (PR) if code-related else Author; Focus = Top 2 relevance clusters.
   - After answers, at most 2 follow-ups (Q4–Q5) only if ≥2 scenario classes (Alternate / Exception / Recovery / Non-Functional) remain unclear.

4. **Understand user request**: Combine `$ARGUMENTS` + clarifying answers into a checklist theme (`ux`, `api`, `security`, `performance`, etc.), explicit must-have items, and category scaffolding.

5. **Load feature context (progressive disclosure)**: Read only sections relevant to active focus areas from `spec.md`, `plan.md` (if exists), and `tasks.md` (if exists). Avoid dumping full source text.

6. **Generate checklist (`FEATURE_DIR/checklists/[domain].md`)**:
   - Create `FEATURE_DIR/checklists/` if missing. Use a short descriptive filename (`ux.md`, `api.md`, `security.md`).
   - If the file exists, **append** new items continuing from the last `CHK###` ID; never delete or overwrite existing items.
   - Follow `.specify/templates/checklist-template.md` for title, metadata, summary, category headings, and item format:
     `- [ ] CHK### \`[Blocker|High|Medium|Low]\` \`[Status: Chưa kiểm]\` <requirement-quality question> [Dimension, Spec §X | Gap | Ambiguity | Conflict | Assumption]`
   - Group by quality dimensions: Requirement Completeness, Requirement Clarity, Requirement Consistency, Acceptance Criteria Quality, Scenario Coverage (Primary / Alternate / Exception / Recovery / Non-Functional), Edge Case Coverage, Non-Functional Requirements, Dependencies & Assumptions, Ambiguities & Conflicts.
   - **Traceability**: ≥80% of items MUST include a `[Spec §X]` / `[Plan §Y]` reference or `[Gap]`/`[Ambiguity]`/`[Conflict]`/`[Assumption]` marker.
   - **Consolidation**: Soft cap ~40 items; merge near-duplicates and prioritize by risk/impact.

7. **Post-Execution Hooks**: Dispatch `HOOKS.after` if non-empty per the Extension Hooks Protocol above; otherwise skip silently.

8. **Report**: Print `ACTIVE_FEATURE_DIRECTORY: <FEATURE_DIR>` first, then output the full checklist path, item count, created vs appended mode, focus areas/depth/audience, and suggested next step: if `spec.md §20` is `CHƯA ĐÁNH GIÁ` or `CẦN ĐÁNH GIÁ LẠI`, run `/speckit-docbiz` first; otherwise `/speckit-plan` (or `/speckit-clarify` if open ambiguities remain).

**HARD STOP**: This command is complete. Do NOT auto-invoke any other `/speckit-*` command. Report completion and wait for the user to explicitly invoke the next step.
