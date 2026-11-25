---
name: "speckit-clarify"
description: "Identify underspecified areas in the current feature spec by asking up to 5 highly targeted clarification questions and encoding answers back into the spec."
argument-hint: "Optional areas to clarify in the spec"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/clarify.md"
user-invocable: true
disable-model-invocation: true
---


## User Input

```text
$ARGUMENTS
```

## Active Feature Reporting

In the Completion Report, print `ACTIVE_FEATURE_DIRECTORY: <resolved FEATURE_DIR>` as the first line before any other result.

You **MUST** consider the user input before proceeding (if not empty).

## Extension Hooks Protocol

`scripts/speckit-cli.js check-prereqs --paths-only --stage clarify --json` reads `.specify/extensions.yml` and returns `HOOKS: { before: [...], after: [...] }`.
- If a hook list is empty, skip silently without reading `.specify/extensions.yml` again.
- For each entry in `HOOKS.before` (before Step 2) or `HOOKS.after` (before the Completion Report): if `optional: true`, display `Command: \`{slashCommand}\``, `Description`, and `Prompt`; if `optional: false`, emit `EXECUTE_COMMAND: {command}`, invoke it, and wait for completion.

## Outline

Goal: Detect and reduce ambiguity or missing decision points in the active feature specification and record the clarifications directly in the spec file.

Note: This clarification workflow is expected to run (and be completed) BEFORE invoking `/speckit-plan`. If the user explicitly states they are skipping clarification (e.g., exploratory spike), you may proceed, but must warn that downstream rework risk increases.

Execution steps:

1. Run `node scripts/speckit-cli.js check-prereqs --paths-only --stage clarify --json` (adding `--feature "<feature-ref>"` if the user named a feature ID/directory in `$ARGUMENTS`) from repo root **once**. Parse JSON payload fields:
   - `FEATURE_DIR`, `FEATURE_SPEC`, `HOOKS` (and optionally `IMPL_PLAN`, `TASKS`).
   - Dispatch `HOOKS.before` if non-empty.
   - If resolution fails, abort and instruct user to re-run `/speckit-specify` or pass the feature ID explicitly.

2. **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints.

3. Load the current spec file. Perform a structured ambiguity & coverage scan using this taxonomy. For each category, mark status: Clear / Partial / Missing. Produce an internal coverage map used for prioritization (do not output raw map unless no questions will be asked).

   Functional Scope & Behavior:
   - Core user goals & success criteria
   - Explicit out-of-scope declarations
   - User roles / personas differentiation

   Domain & Data Model:
   - Entities, attributes, relationships
   - Identity & uniqueness rules
   - Lifecycle/state transitions
   - Data volume / scale assumptions

   Interaction & UX Flow:
   - Critical user journeys / sequences
   - Error/empty/loading states
   - Accessibility or localization notes

   Non-Functional Quality Attributes:
   - Performance (latency, throughput targets)
   - Scalability (horizontal/vertical, limits)
   - Reliability & availability (uptime, recovery expectations)
   - Observability (logging, metrics, tracing signals)
   - Security & privacy (authN/Z, data protection, threat assumptions)
   - Compliance / regulatory constraints (if any)

   Integration & External Dependencies:
   - External services/APIs and failure modes
   - Data import/export formats
   - Protocol/versioning assumptions

   Edge Cases & Failure Handling:
   - Negative scenarios
   - Rate limiting / throttling
   - Conflict resolution (e.g., concurrent edits)

   Constraints & Tradeoffs:
   - Technical constraints (language, storage, hosting)
   - Explicit tradeoffs or rejected alternatives

   Terminology & Consistency:
   - Canonical glossary terms
   - Avoided synonyms / deprecated terms

   Completion Signals:
   - Acceptance criteria testability
   - Measurable Definition of Done style indicators

   Misc / Placeholders:
   - TODO markers / unresolved decisions
   - Ambiguous adjectives ("robust", "intuitive") lacking quantification

   For each category with Partial or Missing status, add a candidate question opportunity unless:
   - Clarification would not materially change implementation or validation strategy
   - Information is better deferred to planning phase (note internally)

4. Generate (internally) a prioritized queue of candidate clarification questions (maximum 5). Do NOT output them all at once. Apply these constraints:
    - Maximum of 5 total questions across the whole session.
    - Each question must be answerable with EITHER:
       - A short multiple‑choice selection (2–5 distinct, mutually exclusive options), OR
       - A one-word / short‑phrase answer (explicitly constrain: "Answer in <=5 words").
    - Only include questions whose answers materially impact architecture, data modeling, task decomposition, test design, UX behavior, operational readiness, or compliance validation.
    - Ensure category coverage balance: attempt to cover the highest impact unresolved categories first; avoid asking two low-impact questions when a single high-impact area (e.g., security posture) is unresolved.
    - Exclude questions already answered, trivial stylistic preferences, or plan-level execution details (unless blocking correctness).
    - Favor clarifications that reduce downstream rework risk or prevent misaligned acceptance tests.
    - If more than 5 categories remain unresolved, select the top 5 by (Impact * Uncertainty) heuristic.

5. Questioning loop (batch interactive picker preferred, sequential fallback):
    - **Batch mode with interactive picker (preferred when `ask_question` / `AskUserQuestion` is available and queued questions are independent)**:
       - Group all independent high-impact questions (up to 5 total across the session) into a single picker call so the user can answer in one turn.
       - For each question, put the best option first prefixed with `(Recommended)` and include a brief rationale in the option text or lead-in.
       - If a follow-up question depends on an earlier answer, ask it in a second turn only if total asked questions remain ≤ 5.
    - **Sequential text mode (fallback when no interactive picker exists, or when each question depends on the previous answer)**:
       - Present ONE question at a time.
       - For multiple-choice: state `**Recommended:** Option [X] - <reasoning>`, render a Markdown table (`Option | Description` for A–E + optional `Short <=5 words`), and let the user reply with the letter, `"yes"`/`"recommended"`, or a short answer.
       - For short-answer: state `**Suggested:** <answer> - <reasoning>` (`<=5 words`) and accept `"yes"`/`"suggested"` or custom text.
    - Stop asking further questions when all critical ambiguities are resolved, the user signals completion (`"done"`, `"good"`, `"no more"`), or 5 questions have been asked.
    - If no valid questions exist at start, immediately report no critical ambiguities.

6. Integration after each answered batch (or single answer in sequential mode):
    - Maintain in-memory representation of the spec plus the raw file contents.
    - Ensure a `## Clarifications` section exists immediately after `## 18. Câu hỏi mở` and before `## 19. Điều kiện sẵn sàng để lập plan kỹ thuật`; create it at that exact position if missing, with a `### Session YYYY-MM-DD` subheading for today.
    - For every accepted answer in the batch:
       - Append `- Q: <question> → A: <final answer>` under `### Session YYYY-MM-DD`.
       - Apply the clarification to the target section(s) (Functional Requirements, User Stories/Actors, Data Model, Success Criteria, Edge Cases, or Terminology), replacing invalidated ambiguous text instead of duplicating.
       - If an answer resolves an item in `## 18. Câu hỏi mở`, remove its `[CẦN LÀM RÕ]` marker or replace it with `[ĐÃ LÀM RÕ → Clarifications / Session YYYY-MM-DD]`.
    - **Conditional Documentation Impact Gate reset**: If any accepted answer materially changes core business sections (`§3 Phạm vi MVP`, `§5 Kịch bản người dùng`, `§7 Yêu cầu chức năng`, `§8 Quy tắc nghiệp vụ`, `§9 Thực thể dữ liệu`, or `§15 Ngoài phạm vi`) and `§20 **Trạng thái**` currently reads `CÓ CẬP NHẬT` or `KHÔNG CẦN CẬP NHẬT`, update `§20 **Trạng thái**` to `CẦN ĐÁNH GIÁ LẠI` so `/speckit-docbiz` re-evaluates before `/speckit-plan`.
    - Save `FEATURE_SPEC` once per batch (atomic overwrite), preserving heading hierarchy and unrelated formatting.

7. Validation (performed after EACH write plus final pass):
   - Clarifications session contains exactly one bullet per accepted answer (no duplicates).
   - Total asked (accepted) questions ≤ 5.
   - Updated sections contain no lingering vague placeholders the new answer was meant to resolve.
    - No contradictory earlier statement remains (scan for now-invalid alternative choices removed).
    - Every question resolved from `## 18. Câu hỏi mở` is removed or explicitly marked `[ĐÃ LÀM RÕ → Clarifications / Session YYYY-MM-DD]`; no resolved item retains `[CẦN LÀM RÕ]`.
   - Markdown structure valid; only allowed new headings: `## Clarifications`, `### Session YYYY-MM-DD`.
   - Terminology consistency: same canonical term used across all updated sections.

8. Write the updated spec back to `FEATURE_SPEC`.

9. **Re-validate Spec Quality Checklist** (if it exists):
   - Check if `FEATURE_DIR/checklists/requirements.md` exists.
   - If it does NOT exist, skip this step silently.
   - If it exists:
     1. Read the checklist file.
     2. Identify all GitHub task-list checkbox lines — lines matching `- [ ]`, `- [x]`, or `- [X]` (case-insensitive, tolerant of leading whitespace for nested items) outside of code fences. Ignore all other content (headings, notes, non-checkbox bullets, metadata).
      3. For each checkbox line, record its current marker state (checked or unchecked), inline `Status:`, and item text into a before-snapshot list.
     4. Re-evaluate each checkbox item against the **updated** spec (the version just saved in step 7).
      5. For each checkbox item, read and update its inline `Status:` together with its checkbox when the evaluation changes:
         - `Status: Pass` uses `[x]`; if an item now passes, set both status and marker accordingly.
         - An unapproved `Status: Fail` uses `[ ]`; if an item now fails without an approved exception, set both status and marker accordingly.
         - `Status: Không áp dụng` remains `[x]` and must not be unchecked merely because it is not a pass. Change it only when the clarification makes the criterion applicable; then re-evaluate it as Pass or Fail.
         - `Status: Fail (ngoại lệ đã phê duyệt)` remains `[x]` while its approved exception remains valid. If clarification resolves the condition, change it to `Status: Pass`; if approval is withdrawn, change it to unapproved `Status: Fail` and `[ ]`.
         - If status and marker are already correct, leave them as-is (preserve marker case to avoid cosmetic diffs).
      6. Save the updated checklist file. Change only the status text and `[ ]`/`[x]` marker portions needed by re-validation; preserve all other content — headings, metadata, fail evidence, approved exceptions, line ordering, and whitespace — to avoid losing review history or creating noisy diffs.
      7. Compare the before-snapshot with the current state to compute three lists for the Completion Report:
         - **Newly gate-complete**: items that changed from unchecked to checked.
         - **Regressions**: items that changed from checked to unchecked.
         - **Status changes**: items whose inline `Status:` changed even if their checkbox did not.
         - **Still unchecked**: items that remain unchecked.
      8. Record the before/after gate-complete counts as checked/total checkbox items (e.g., "12/16 → 15/16 items complete").

Behavior rules:

- If no meaningful ambiguities found (or all potential questions would be low-impact), respond: "No critical ambiguities detected worth formal clarification." and suggest proceeding.
- If spec file missing, instruct user to run `/speckit-specify` first (do not create a new spec here).
- Never exceed 5 total asked questions (clarification retries for a single question do not count as new questions).
- Avoid speculative tech stack questions unless the absence blocks functional clarity.
- Respect user early termination signals ("stop", "done", "proceed").
- If no questions asked due to full coverage, output a compact coverage summary (all categories Clear) then suggest advancing.
- If quota reached with unresolved high-impact categories remaining, explicitly flag them under Deferred with rationale.

Context for prioritization: $ARGUMENTS

## Mandatory Post-Execution Hooks

Dispatch `HOOKS.after` if non-empty per the Extension Hooks Protocol above; otherwise skip silently.

## Completion Report

Report completion (after questioning loop ends or early termination):
- Number of questions asked & answered.
- Path to updated spec.
- Sections touched (list names).
- Spec quality checklist status (if `FEATURE_DIR/checklists/requirements.md` was re-validated): show before/after gate-complete counts (e.g., "Spec Quality Checklist: 12/16 → 15/16 items complete") and list any checkbox or `Status:` changes, including newly checked, regressions, and approved exceptions. If any items remain unchecked, list them as areas needing attention.
- Coverage summary table listing each taxonomy category with Status: Resolved (was Partial/Missing and addressed), Deferred (exceeds question quota or better suited for planning), Clear (already sufficient), Outstanding (still Partial/Missing but low impact).
- If any Outstanding or Deferred remain, recommend whether to run `/speckit-clarify` again or proceed to `/speckit-docbiz` (mandatory Documentation Impact Gate whenever `spec.md §20` is `CHƯA ĐÁNH GIÁ` or the business scope changed) before `/speckit-plan`.
- Suggested next command (`/speckit-docbiz` if `spec.md §20` needs initial/updated evaluation, otherwise `/speckit-plan`).

**HARD STOP**: This command is complete. Do NOT auto-invoke `/speckit-docbiz`, `/speckit-plan`, or any other command. Report completion and wait for the user to explicitly invoke the next step.

## Done When

- [ ] Spec ambiguities identified and clarifications integrated into spec file
- [ ] Spec quality checklist re-validated against updated spec (if `FEATURE_DIR/checklists/requirements.md` exists)
- [ ] Extension hooks dispatched or skipped according to the rules in Mandatory Post-Execution Hooks above
- [ ] Completion reported to user with questions answered, sections touched, checklist status, and coverage summary
