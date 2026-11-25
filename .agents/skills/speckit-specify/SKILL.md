---
name: "speckit-specify"
description: "Create or update the business feature specification from a natural-language feature description. Use when starting a new feature without an existing business spec or when invoking /speckit-specify or $speckit-specify. Do not use for small bug fixes with existing tests or behavior-preserving refactors (Light Track)."
argument-hint: "Describe the feature you want to specify"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/specify.md"
user-invocable: true
---


## User Input

```text
$ARGUMENTS
```

## Active Feature Reporting

In the Completion Report, print `ACTIVE_FEATURE_DIRECTORY: <resolved ACTIVE_FEATURE_DIRECTORY>` as the first line before any other result.

You **MUST** consider the user input before proceeding (if not empty).

## Extension Hooks Protocol

`scripts/speckit-cli.js setup-specify --json` reads `.specify/extensions.yml` and returns `HOOKS: { before: [...], after: [...] }`.
- If a hook list is empty, skip silently without reading `.specify/extensions.yml` again.
- For each entry in `HOOKS.before` (only **after** the duplicate-short-name guard in Step 2 resolves) or `HOOKS.after` (before the Completion Report):
  - If `optional: true`, list `Command: \`{slashCommand}\``, `Description`, and `Prompt` for the user.
  - If `optional: false`, emit `EXECUTE_COMMAND: {command}` and invoke it (e.g. `/{slashCommand}` or `$speckit-...`) and wait for completion before continuing.

## Outline

The text the user typed after `/speckit-specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given that feature description, do this:

1. **Generate a concise short name and classify `Chế độ Spec`**:
   - Extract the most meaningful keywords into a 2–4 word lowercase hyphenated `short-name` in action-noun format (e.g., `user-auth`, `oauth2-api-integration`, `analytics-dashboard`, `fix-payment-timeout`). Preserve technical acronyms (OAuth2, API, JWT).
   - Classify `Chế độ Spec`: choose `Compact` when the feature fits within a single repository, requires no shared database schema migration, and introduces no breaking public contract; otherwise choose `Full` (user-provided mode overrides).

2. **Initialize or select the feature directory via `speckit-cli.js`**:
   - Run `node scripts/speckit-cli.js setup-specify --short-name "<short-name>" --mode "<Compact|Full>" --json` from repo root (if the user explicitly provided an existing directory or `SPECIFY_FEATURE_DIRECTORY`, pass `--feature "<ref>"` instead).
   - Inspect `STATUS` in the JSON output:
     - **`DUPLICATE_FOUND`**: Stop before creating any files or dispatching `HOOKS.before`. Ask the user:
       - If 1 match: **"Đã có spec `<match>` cùng short-name `<short-name>`. Bạn muốn cập nhật spec hiện có hay tạo feature mới?"**
       - If multiple matches: list `MATCHES` and ask the user to choose one directory to update or create a feature mới.
       - After the user answers:
         - **Cập nhật spec hiện có**: run `node scripts/speckit-cli.js setup-specify --feature "<selected>" --json` (preserves existing `spec.md` and `checklists/requirements.md`, and pins both `.specify/feature.local.json` and `.specify/feature.json`).
         - **Tạo feature mới**: run `node scripts/speckit-cli.js setup-specify --short-name "<short-name>" --mode "<Compact|Full>" --allow-duplicate --json`.
     - **`CREATED` / `UPDATED_EXISTING`**: Parse `ACTIVE_FEATURE_DIRECTORY`, `FEATURE_DIR`, `FEATURE_SPEC`, `REQUIREMENTS_CHECKLIST`, `REQUIREMENTS_EXISTS`, `DEPRECATED_WARNING`, and `HOOKS`. If `DEPRECATED_WARNING` is non-null, emit a one-line warning.
   - Now dispatch `HOOKS.before` if non-empty (passing `GIT_BRANCH_NAME` if explicitly provided by the user). The spec directory and file are always created by this command, never by a hook; branch name and spec directory name are independent.

3. **Load context**:
   - Read `FEATURE_SPEC` (already scaffolded with `Branch`, `Ngày tạo`, `Chế độ Spec`, and `{{GIT_USER_NAME}}` for new features, or the existing spec in update mode).
   - **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints.

4. **Draft and write the specification to `FEATURE_SPEC`**:
   - Parse the user description (if empty: ERROR "No feature description provided") and extract actors, actions, data, and constraints.
   - Replace `[Tóm tắt mong muốn người dùng trong 1-2 câu]` with a concise 1–2 sentence summary of the user's intent (core goal and scope only; omit file paths, command syntax, and meta-instructions).
   - Fill all sections in `FEATURE_SPEC` preserving section order and headings `§1–§20` (for non-applicable sections, keep the heading and write `Không áp dụng — <lý do ngắn>`; never delete a section):
     - **User Scenarios & Testing (`§5`)**: if no clear user flow, ERROR "Cannot determine user scenarios".
     - **Functional Requirements (`§7`)**: testable, using `PHẢI` / `KHÔNG ĐƯỢC`, traceable to `US`/`AC`; document defaults in Assumptions (`§14`).
     - **Success Criteria (`§13`)**: measurable, technology-agnostic outcomes (quantitative + qualitative).
     - **Key Entities (`§9`)**: business meaning and relationships only (no DB tables/API payloads).
   - **Clarification markers**: Make informed guesses using context and standards. Use `[NEEDS CLARIFICATION: ...]` or `[CẦN LÀM RÕ: ...]` **only** when a choice significantly impacts scope, security/privacy, or UX with no reasonable default (**max 3 total**; prioritize scope > security/privacy > UX > technical details).
   - **Stale Documentation Impact Gate (update mode only)**: If updating an existing `spec.md` whose `§20 **Trạng thái**` is already `CÓ CẬP NHẬT` or `KHÔNG CẦN CẬP NHẬT`, and this edit materially changes any core business section (`§3`, `§5`, `§7`, `§8`, `§9`, or `§15`), reset `§20 **Trạng thái**` to `CẦN ĐÁNH GIÁ LẠI` so `/speckit-docbiz` re-evaluates before `/speckit-plan`.

5. **Specification Quality Validation (`checklists/requirements.md`)**:
   - For a new feature, `setup-specify` already copied `requirements-template.md` to `REQUIREMENTS_CHECKLIST` with metadata filled; replace `[TÊN TÍNH NĂNG]` with the feature title.
   - For update mode when `REQUIREMENTS_EXISTS` is `true`, do not overwrite it: keep all existing review history, exception decisions, fail evidence, owner/deadline, and metadata. If it lacks a canonical `CHK###` item from `requirements-template.md`, report the gap and ask before adding it.
   - Evaluate `FEATURE_SPEC` against every `CHK###` item:
     - Set each item to `Status: Pass` (`[x]`), `Status: Không áp dụng` (`[x]`), `Status: Fail (ngoại lệ đã phê duyệt)` (`[x]`), or unapproved `Status: Fail` (`[ ]`).
     - For every Fail, add `Phát hiện`, `Ảnh hưởng`, `Đề xuất`, `Tham chiếu`, `Owner`, and `Hạn xử lý` beneath the item.
     - Treat `[NEEDS CLARIFICATION]` / `[CẦN LÀM RÕ]` markers affecting scope, security, data, permission, contract, or UX as Blocker failures (present at most 3 critical questions at once).
     - Update summary counts, review status, conclusion, and next step (`Pass` if 0 Blocker/High fails; `Pass có điều kiện` if High items have approved exceptions; `Fail` if any Blocker fails — update spec and re-validate up to 3 iterations).
   - Run `node scripts/speckit-cli.js validate --feature "<ACTIVE_FEATURE_DIRECTORY>" --stage specify` to confirm zero unfilled tokens and zero uninspected `[Status: Chưa kiểm]` items.

6. **Post-Execution Hooks**: Dispatch `HOOKS.after` if non-empty per the Extension Hooks Protocol above.

7. **Completion Report**:
   - Print `ACTIVE_FEATURE_DIRECTORY: <ACTIVE_FEATURE_DIRECTORY>` as the first line.
   - Report `SPEC_FILE`, chosen `Chế độ Spec` (`Compact` or `Full`), checklist results summary, and readiness for the next phase: `/speckit-clarify` if ambiguities remain, otherwise `/speckit-docbiz` (mandatory Documentation Impact Gate before `/speckit-plan` whenever `§20` is `CHƯA ĐÁNH GIÁ` or `CẦN ĐÁNH GIÁ LẠI`).

**HARD STOP**: This command is complete. Do NOT auto-invoke `/speckit-clarify`, `/speckit-docbiz`, `/speckit-plan`, or any other command. Report completion and wait for the user to explicitly invoke the next step.

## Quick Guidelines

- Focus on **WHAT** users need and **WHY**; avoid **HOW** (no tech stack, APIs, code structure). Written for business stakeholders, not developers.
- Do not embed checklists inside `spec.md`; use `checklists/requirements.md` (mandatory) or `/speckit-checklist` (domain checklists).
- **Reasonable defaults** (don't ask): domain-standard data retention, standard web/mobile performance, user-friendly error messages, standard session/OAuth2 auth, project-appropriate integration patterns.
- **Success Criteria**: measurable, technology-agnostic, user-focused, verifiable (e.g. *"Users can complete checkout in under 3 minutes"*, NOT *"API response time < 200ms"* or *"Redis cache hit rate > 80%"*).

## Done When

- [ ] Feature directory initialized/selected via `speckit-cli.js setup-specify` (max 1 feature per invocation)
- [ ] Specification written to `FEATURE_SPEC` and validated via `checklists/requirements.md` + `speckit-cli.js validate --stage specify`
- [ ] `HOOKS.before` / `HOOKS.after` dispatched or skipped per Extension Hooks Protocol
- [ ] Completion reported with `ACTIVE_FEATURE_DIRECTORY`, `SPEC_FILE`, `Chế độ Spec`, and checklist results
