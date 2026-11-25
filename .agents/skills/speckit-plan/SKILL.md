---
name: "speckit-plan"
description: "Execute the implementation planning workflow using the plan template to generate design artifacts."
argument-hint: "Optional guidance for the planning phase"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/plan.md"
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

`scripts/speckit-cli.js setup-plan --json` reads `.specify/extensions.yml` and returns `HOOKS: { before: [...], after: [...] }`.
- If a hook list is empty, skip silently without reading `.specify/extensions.yml` again.
- For each entry in `HOOKS.before` (after Step 1 setup) or `HOOKS.after` (before the Completion Report): if `optional: true`, display `Command: \`{slashCommand}\``, `Description`, and `Prompt`; if `optional: false`, emit `EXECUTE_COMMAND: {command}`, invoke it, and wait for completion.

## Outline

1. **Setup**: Run `node scripts/speckit-cli.js setup-plan --json` (adding `--feature "<feature-ref>"` if the user named a feature ID/directory in `$ARGUMENTS`) from repo root and parse JSON for `FEATURE_SPEC`, `IMPL_PLAN`, `SPECS_DIR`, `REPOS_FILE`, `REPOS_EXISTS`, `SPEC_MODE`, and `BRANCH`. Notice that `setup-plan` deterministically verifies `spec.md` exists and `spec.md §20` (`Documentation Impact Gate`) is no longer `CHƯA ĐÁNH GIÁ` — if it exits non-zero, stop immediately and instruct the user to run `/speckit-specify` or `/speckit-docbiz` as indicated.

2. **Load context & Repo Scope**: Read `FEATURE_SPEC` and `.specify/memory/constitution.md`, plus the `IMPL_PLAN` template (already copied if new).
   - **Repo Scope Gate**: If `REPOS_EXISTS` is `true`, read `REPOS_FILE` (`specs/<id>/repos.md`) as the repo scope (`Edit`/`Read`/`Skip`). If `REPOS_EXISTS` is `false` and the feature touches any child repo in `workstation.json` (or if the plan needs an unlisted child repo), **run `flex-repo-scope` now and write/update `FEATURE_DIR/repos.md`** before filling `plan.md`.
   - If the feature touches database/schema/migration, also read `docs/architecture/system-map.md` (Projects, Data Architecture sections) before filling "Dữ liệu & Migration" — per Constitution VI, the target database and the repo that owns its migration script must be analyzed and cited, never assumed by habit.

3. **Route specialist skills**: Use `flex-using-agent-skills` once with the technical
   context and planned artifacts. Keep `speckit-plan` as the active lifecycle skill;
   select only additional specialist skills, read them, and apply their planning
   guidance before making architecture, data, API, security, or test decisions. Do
   not route `speckit-plan` again.

4. **Execute plan workflow** (respecting `SPEC_MODE` from `spec.md` — `Compact` vs `Full`):
   - Fill Technical Context, `Chế độ Spec`, and copy the completed Documentation Impact Gate result from `spec.md` §20 into `Tác động tài liệu nghiệp vụ` (naming any existing document + section that still needs post-implementation updates).
   - Fill Constitution Check section from constitution and evaluate gates (ERROR if violations unjustified).
   - **If `SPEC_MODE == Compact`** (single child repo, no shared DB schema migration, no breaking public contract): record research decisions, entity changes, contracts, and quickstart validation commands **inline inside `plan.md`** without creating separate `research.md`, `data-model.md`, or `quickstart.md` files unless complexity genuinely requires splitting.
   - **If `SPEC_MODE == Full`**:
     - Phase 0: Generate `research.md` (resolve all `NEEDS CLARIFICATION` / `TQ-###`).
     - Phase 1: Generate `data-model.md`, `contracts/`, and `quickstart.md`.
   - Re-evaluate Constitution Check post-design and tick completed items in `Checklist sẵn sàng cho /speckit-tasks`.
   - Run `node scripts/speckit-cli.js validate --feature "<SPECS_DIR>" --stage plan` to confirm zero leftover sample trees (`# [XÓA NẾU KHÔNG DÙNG]`), zero unfilled tokens, and valid `repos.md` coverage.

## Mandatory Post-Execution Hooks

Dispatch `HOOKS.after` if non-empty per the Extension Hooks Protocol above; otherwise skip silently.

## Completion Report

Command ends after Phase 2 planning. Report branch, IMPL_PLAN path, and generated artifacts.

Suggested next step: `/speckit-tasks` to generate the implementation task list from the design artifacts.

**HARD STOP**: This command is complete. Do NOT auto-invoke `/speckit-tasks` or any other command. Report completion and wait for the user to explicitly invoke the next step.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Define interface contracts** (if project has external interfaces) → `/contracts/`:
   - Identify what interfaces the project exposes to users or other systems
   - Document the contract format appropriate for the project type
   - Examples: public APIs for libraries, command schemas for CLI tools, endpoints for web services, grammars for parsers, UI contracts for applications
   - Skip if project is purely internal (build scripts, one-off tools, etc.)

3. **Create quickstart validation guide** → `quickstart.md`:
   - Document runnable validation scenarios that prove the feature works end-to-end
   - Include prerequisites, setup commands, test/run commands, and expected outcomes
   - Use links or references to contracts and data model details instead of duplicating them
   - Do not include full implementation code, model/service/controller bodies, migrations, or complete test suites
   - Keep this artifact as a validation/run guide; implementation details belong in `tasks.md` and the implementation phase

**Output**: data-model.md, /contracts/*, quickstart.md

## Key rules

- If spec file (`FEATURE_SPEC`) is missing, instruct user to run `/speckit-specify` first (do not create or plan without a spec)
- Use absolute paths for filesystem operations; use project-relative paths for references in documentation
- ERROR on gate failures or unresolved clarifications
- Do not make a technical decision governed by an applicable specialist skill before
  routing to and applying that skill.
- If the target database/repo for a migration is ambiguous or `system-map.md` conflicts with actual precedent in other specs, record it as `NEEDS CLARIFICATION` in Phase 0 research (with evidence from the conflicting sources) instead of picking a location without analysis

## Done When

- [ ] Plan workflow executed and design artifacts generated
- [ ] Extension hooks dispatched or skipped according to the rules in Mandatory Post-Execution Hooks above
- [ ] Completion reported to user with branch, plan path, and generated artifacts
