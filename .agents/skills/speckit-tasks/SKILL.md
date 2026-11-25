---
name: "speckit-tasks"
description: "Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts."
argument-hint: "Optional task generation constraints"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/tasks.md"
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

`scripts/speckit-cli.js setup-tasks --json` reads `.specify/extensions.yml` and returns `HOOKS: { before: [...], after: [...] }`.
- If a hook list is empty, skip silently without reading `.specify/extensions.yml` again.
- For each entry in `HOOKS.before` (after Step 1 setup) or `HOOKS.after` (before the Completion Report): if `optional: true`, display `Command: \`{slashCommand}\``, `Description`, and `Prompt`; if `optional: false`, emit `EXECUTE_COMMAND: {command}`, invoke it, and wait for completion.

## Outline

1. **Setup**: Run `node scripts/speckit-cli.js setup-tasks --json` (adding `--feature "<feature-ref>"` if the user named a feature ID/directory in `$ARGUMENTS`) from repo root and parse `FEATURE_DIR`, `TASKS_TEMPLATE`, `AVAILABLE_DOCS`, and `PLAN_READINESS`.

2. **Load design documents & rules**:
   - Read `.agents/skills/speckit-tasks/references/task-generation-rules.md` for atomic task sizing, Foundational scope boundaries, `[P]` file-conflict handling, Data/Migration safety, Contract rules, and multi-clause requirement coverage.
   - Read from `FEATURE_DIR`:
     - **Required**: `plan.md` (tech stack, libraries, structure, inline design if `Compact` mode), `spec.md` (user stories with priorities)
     - **Optional** (present in `AVAILABLE_DOCS`): `data-model.md`, `contracts/`, `research.md`, `quickstart.md`, `repos.md`
     - **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints
     - Read `plan.md` section `Tác động tài liệu nghiệp vụ` and `spec.md` §20. Do not infer a documentation task from the feature name or an example task.

3. **Check plan readiness checklist** (using `PLAN_READINESS` returned by `setup-tasks`):
   - **If `PLAN_READINESS.incomplete > 0`**:
     - List `PLAN_READINESS.incompleteItems`
     - **STOP** and ask: "Plan chưa đủ sẵn sàng cho `/speckit-tasks` (còn N item chưa tick). Bạn muốn tiếp tục sinh tasks hay quay lại `/speckit-plan`? (tiếp tục/quay lại)"
     - Wait for user response before continuing; halt if user chooses to go back.
   - **If `PLAN_READINESS.incomplete == 0`**: proceed to step 4 automatically.

4. **Execute task generation workflow**:
   - Load plan.md and extract tech stack, libraries, project structure
   - Load spec.md and extract user stories with their priorities (P1, P2, P3, etc.)
   - If data-model.md exists: Extract entities and map to user stories
   - If contracts/ exists: Map interface contracts to user stories
   - If research.md exists: Extract decisions for setup tasks
   - Generate tasks organized by user story (see Task Generation Rules below)
   - Generate dependency graph showing user story completion order
   - Create parallel execution examples per user story
   - Validate task completeness (each user story has all needed tasks, independently testable)

5. **Generate tasks.md**: Read the tasks template from TASKS_TEMPLATE (from the JSON output above) and use it as structure. If TASKS_TEMPLATE is empty, fall back to `.specify/templates/tasks-template.md`. Fill with:
   - Correct feature name from plan.md
   - Phase 1: Setup tasks (project initialization)
   - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
   - Phase 3+: One phase per user story (in priority order from spec.md)
   - Each phase includes: story goal, independent test criteria, test tasks required by risks and test strategy in `plan.md`, implementation tasks
   - Add a documentation task only when `Tác động tài liệu nghiệp vụ` names an outstanding update after implementation; use its exact existing document path and section. Otherwise omit that task.
   - Final Phase: Polish & cross-cutting concerns
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing story completion order and parallel opportunities
   - Run `node scripts/speckit-cli.js validate --feature "<FEATURE_DIR>" --stage tasks` to verify zero leftover template tokens, unique sequential `T###` IDs, and zero `[P]` same-file conflicts before reporting completion.

## Mandatory Post-Execution Hooks

Dispatch `HOOKS.after` if non-empty per the Extension Hooks Protocol above; otherwise skip silently.

## Completion Report

Output path to generated tasks.md and summary:
- Total task count
- Task count per user story
- Parallel opportunities identified
- Independent test criteria for each story
- Suggested MVP scope (typically just User Story 1)
- Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)
- Suggested next step: `/speckit-implement` to begin executing tasks. If GitHub Issues are used, run `/speckit-taskstoissues` first. If a cross-artifact quality gate is needed, run `/speckit-analyze` first.

**HARD STOP**: This command is complete. Do NOT auto-invoke `/speckit-analyze`, `/speckit-implement`, or any other command. Report completion and wait for the user to explicitly invoke the next step.

## Checklist Format Quick Reference

Every task MUST strictly follow: `- [ ] T### [P?] [US#?] Description with backticked \`file/path\`` (sequential `T001+`; `[P]` only when touching distinct files with no dependency on incomplete tasks in the same phase; `[US#]` required only in User Story phases).
All detailed sizing, Foundational boundary, `[P]` conflict, Test Gate, migration, contract, and multi-clause FR rules live in `.agents/skills/speckit-tasks/references/task-generation-rules.md` — follow that file as the single source of truth.

## Done When

- [ ] tasks.md generated with all phases, task IDs, and file paths
- [ ] Test tasks or documented manual/command validation cover every risk identified in `plan.md`
- [ ] Extension hooks dispatched or skipped per Extension Hooks Protocol
- [ ] Completion reported to user with task count, story breakdown, and MVP scope
