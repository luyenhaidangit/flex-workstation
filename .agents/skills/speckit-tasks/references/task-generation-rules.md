# Task Generation Rules for `speckit-tasks`

Reference rules applied by `speckit-tasks` when generating `tasks.md` from `.specify/templates/tasks-template.md`. Kept out of the runtime template so every `tasks.md` stays lean and free of instructional boilerplate.

## 1. Atomic Task & Size Rules

- Every task MUST have a unique sequential ID (`T001`, `T002`, ...), a concrete file path (or an explicit validation command), and a verifiable output (diff, test, command exit, log, UI check, or artifact).
- One primary responsibility per task: creating one file, a focused change in an existing file (naming the class, method, endpoint group, section, or config key), or one validation command.
- Split any task touching >3 files or spanning multiple layers (DB + service + endpoint + UI).
- Never output placeholder tokens (`[FeatureName]`, `[Entity]`, `[UseCaseName]`, `[endpoint]`, `[file]`, `TXXX`, `Phase N`) or example phases.
- Only generate phases for user stories that actually exist in `spec.md` (do not invent `US2`/`US3` if `spec.md` only has `US1`).

## 2. Parallelism (`[P]`) & File Conflict Rules

- `[P]` means **parallelizable** (touches distinct files and has no dependency on an incomplete task in the same phase). It is unrelated to story priority (`P1`/`P2`/`P3`).
- Never mark two tasks `[P]` in the same phase if they modify the same file.
- When multiple user stories touch a shared aggregation file (`DependencyInjection.cs`, `routes.ts`, `index.ts`, module registration):
  - Either split files per use case/endpoint, OR
  - Record explicit dependency task IDs `(phụ thuộc T012)` and treat those tasks as sequential integration steps.

## 3. Foundational Phase Scope Rules

Place a task in `Phase 2: Foundational` **only** when it:
- Is shared by at least 2 user stories, OR
- Is a blocking prerequisite before any story can run (schema/migration, base infrastructure, shared auth/contract foundation).

Story-specific DTOs, validators, handlers, UI components, and story tests belong inside their own User Story phase (`[US1]`, `[US2]`, ...), never in Foundational.

## 4. Test Gate, Data/Migration & Contract Rules

- **Test Gate (Constitution)**: Every risk in `plan.md` requiring verification MUST have an automated test task (written to fail before implementation) OR a concrete manual/command validation task stating why automated testing does not apply. If a user story has no automated test task, include a concrete manual/command validation task for it.
- **Data & Migration Safety**: Never combine schema migration with business handler code in one task. Include tasks for migration creation, backward-compatibility check (if rolling deploy), seed/backfill (if needed), and rollback/recovery verification when `plan.md` flags data risk.
- **Contracts**: Every endpoint/event in `contracts/` (or inline contract table in Compact mode) gets an implementation task, DTO/validator task when schemas change, and contract test task when required by `plan.md`.
- **Business Docs**: Never generate a default documentation task. Only generate one when `plan.md` (`Tác động tài liệu nghiệp vụ`) explicitly lists an outstanding post-implementation update with an exact existing document path and section.

## 5. Coverage & Multi-Clause Requirement Rules

- Cover every `MVP-###`, `US`, key `AC`, `FR` (`P1`/`P2` or code/data/API/permission-impacting), `BR`, `SEC`, `NFR`, entity, contract, rollout/rollback, feature flag, and observability item marked in `spec.md` / `plan.md`.
- When an `FR` or `BR` has multiple clauses (e.g., "reject X; after Y do Z"), each clause must appear explicitly in at least one task description — listing the ID in `Traceability Matrix` alone is insufficient.
- `Traceability Matrix` must list exact generated task IDs (e.g. `T012, T014`), never ranges (`T010-T018`) that span unrelated tasks.

## 6. Invalid Task Anti-Examples

- `- [ ] T001 Implement chức năng đặt lịch` → invalid: too broad, no file path.
- `- [ ] T002 Cập nhật backend và frontend` → invalid: multi-layer bundle, no path.
- `- [ ] T003 [P] Sửa BookingService.cs` + `- [ ] T004 [P] Thêm log vào BookingService.cs` → invalid: `[P]` collision on the same file.
- `- [ ] T006 [US2] Cập nhật BookingService.cs` → invalid: edits existing file without naming method/class/behavior.
