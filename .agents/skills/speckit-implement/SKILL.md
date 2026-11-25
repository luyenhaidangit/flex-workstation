---
name: "speckit-implement"
description: "Execute the implementation plan by processing and executing all tasks defined in tasks.md"
argument-hint: "Optional implementation guidance or task filter"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/implement.md"
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

`scripts/speckit-cli.js check-prereqs --stage implement ... --json` reads `.specify/extensions.yml` and returns `HOOKS: { before: [...], after: [...] }`.
- If a hook list is empty, skip silently without reading `.specify/extensions.yml` again.
- For each entry in `HOOKS.before` (after Step 1) or `HOOKS.after` (before the Completion Report): if `optional: true`, display `Command: \`{slashCommand}\``, `Description`, and `Prompt`; if `optional: false`, emit `EXECUTE_COMMAND: {command}`, invoke it, and wait for completion.

## Outline

1. Run `node scripts/speckit-cli.js check-prereqs --stage implement --require-tasks --include-tasks --json` (adding `--feature "<feature-ref>"` if the user named a feature ID/directory in `$ARGUMENTS`) from repo root and parse `FEATURE_DIR`, `AVAILABLE_DOCS`, `CHECKLISTS`, and `HOOKS`. Dispatch `HOOKS.before` if non-empty. All paths must be absolute.

2. **Check checklists status** (using `CHECKLISTS` returned by `speckit-cli.js`, or scanning `FEATURE_DIR/checklists/` if present):
   - For each checklist, inspect `total`, `completed`, `incomplete`, `uninspectedCount` (`[Status: Chưa kiểm]`), and `status`:
   - A checked item with `Status: Không áp dụng` is complete and MUST NOT block this gate. A checked `Status: Fail (ngoại lệ đã phê duyệt)` is also complete: the status keeps the risk visible, while its approved exception records the authorization. Unchecked `- [ ]` items or items left at `[Status: Chưa kiểm]` are incomplete.
   - Render the status table (`Checklist | Total | Completed | Incomplete | Status`).
   - **If any checklist has `status == FAIL` (`incomplete > 0` or `uninspectedCount > 0`)**:
     - Display the table with incomplete item counts
     - **STOP** and ask in Vietnamese: `"Một số checklist chưa hoàn tất (còn mục chưa tick hoặc Chưa kiểm). Bạn có muốn tiếp tục triển khai không? (có/không)"`
     - Wait for user response before continuing; halt if user replies `"không"` / `"no"` / `"stop"`, proceed to step 3 only if user explicitly confirms `"có"` / `"yes"` / `"tiếp tục"`.
   - **If all checklists pass**: display the table and proceed to step 3 automatically.

3. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read .specify/memory/constitution.md for governance constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios
   - **IF EXISTS**: Read repos.md for the repos in scope; edit code only in `Edit` repos, and re-run `flex-repo-scope` (updating repos.md) if a task needs a repo not listed

3a. **Route specialist skills**: Use `flex-using-agent-skills` once with the concrete
    file paths and artifact types in the loaded plan and tasks. Keep
    `speckit-implement` as the active lifecycle skill; select only additional
    specialist skills, read them, and apply their instructions before editing source.
    Do not route `speckit-implement` again. Re-route only when a later task introduces
    an artifact domain not covered by the selected skills; record when no specialist
    skill applies.

3b. **Sync spec status**: Read the `**Trạng thái**` field in `FEATURE_DIR/spec.md`'s
    header. If it reads `Bản nháp` or `Hoàn thành` while `tasks.md` still has at least
    one unchecked `- [ ]` task, update it to `Đang triển khai`. Change only that field's
    value; do not touch any other header line or section.

4. **Project Setup Verification**:
   - Run this step only when tasks.md contains an explicit Setup task that requires creating or verifying ignore files or tool ignore configuration.
   - Limit verification and changes to the files and technologies named in that task.
   - If no matching Setup task exists, skip this step without probing, creating, or modifying ignore files.

5. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements

6. Execute implementation following the task plan:
   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together  
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **Validation checkpoints**: Verify each phase completion before proceeding

7. Implementation execution rules:
   - **Setup first**: Initialize project structure, dependencies, configuration
   - **Tests before code**: If you need to write tests for contracts, entities, and integration scenarios
   - **Core development**: Implement models, services, CLI commands, endpoints
   - **Integration work**: Database connections, middleware, logging, external services
   - **Polish and validation**: Unit tests, performance optimization, documentation

8. Progress tracking and error handling:
   - Report progress after each completed task
   - Halt execution if any non-parallel task fails
   - For parallel tasks [P], continue with successful tasks, report failed ones
   - Provide clear error messages with context for debugging
   - Suggest next steps if implementation cannot proceed
   - **IMPORTANT** For completed tasks, make sure to mark the task off as [X] in the tasks file.

9. Completion validation:
   - Verify all required tasks are completed
   - Check that implemented features match the original specification
   - Validate that tests pass and coverage meets requirements
   - Confirm the implementation follows the technical plan
   - Confirm all selected specialist-skill checks were completed or any approved
     exception is recorded in the relevant artifact
   - Keep `**Trạng thái**` in `FEATURE_DIR/spec.md`'s header as `Đang triển khai`
     (final transition to `Hoàn thành` and `Ngày reconcile cuối` happens in
     `/speckit-converge` once 0 gaps, Spec Reconciliation, and Final Specialist
     Review closeout all pass per Constitution §8).

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/speckit-tasks` first to regenerate the task list.

## Mandatory Post-Execution Hooks

Dispatch `HOOKS.after` if non-empty per the Extension Hooks Protocol above; otherwise skip silently.

## Completion Report

Report final status with summary of completed work, tasks completed vs remaining, and any blockers encountered.

Suggested next step: `/speckit-converge` to check for remaining gaps between the implementation and the spec/plan.

**HARD STOP**: This command is complete. Do NOT auto-invoke `/speckit-converge` or any other command. Report completion and wait for the user to explicitly invoke the next step.

## Done When

- [ ] All tasks in tasks.md completed and marked `[X]`
- [ ] Implementation validated against specification, plan, and test coverage
- [ ] Extension hooks dispatched or skipped according to the rules in Mandatory Post-Execution Hooks above
- [ ] Completion reported to user with summary of completed work
