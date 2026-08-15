---
name: flex-using-agent-skills
description: Routes a task to the smallest applicable set of installed workspace skills. Use at the start of every task that reads, analyzes, reviews, or changes workspace or repository files.
---

# Using Agent Skills

## Purpose

Route each task to the smallest applicable set of installed workspace skills before
working on files. This skill selects the workflow; it does not replace the selected
skill's instructions or duplicate general behavior already defined in `AGENTS.md` or
`CLAUDE.md`.

## Mandatory routing rule

Before reading, analyzing, reviewing, or changing workspace or repository files:

1. Identify the task's intent and primary artifact.
2. Select the applicable skill or skills from the table below.
3. Read and apply every selected skill before continuing.
4. Announce the routing result concisely.

Do not invoke this skill recursively when the task is solely to review or update
`flex-using-agent-skills`. Use the applicable skill-creation workflow instead.

Reuse the selected skills while the task scope remains unchanged. Route again only
when the repository, primary artifact, or lifecycle changes; for example, from a C#
review to a Liquibase migration, or from planning to implementation.

## Routing table

Select only skills that directly govern the task.

| Task or primary artifact | Primary skill |
| --- | --- |
| PostgreSQL schema, Liquibase changelog, migration, seed, index, constraint, database function, view, or trigger | `flex-database-engineering` |
| C#/.NET, ASP.NET Core, EF Core, dependency injection, tests, architecture, or service implementation | `flex-dotnet-engineering` |
| Angular UI in `flex-microfrontend`, including components, templates, forms, modals, and tables | `flex-frontend-engineering` |
| Backend/domain/public-contract naming | `flex-naming-convention` |
| `AGENTS.md`, `CLAUDE.md`, `.claude/rules/`, or decisions about persistent agent context | `flex-context-engineering` |
| Create, review, evaluate, optimize, or package a skill | `flex-skill-creator` |
| New feature without an existing business spec | `speckit-specify` |
| Clarify an existing feature spec | `speckit-clarify` |
| Create a feature plan | `speckit-plan` |
| Create an implementation task list | `speckit-tasks` |
| Analyze consistency of spec, plan, and tasks | `speckit-analyze` |
| Implement approved tasks | `speckit-implement` |
| Assess remaining implementation gaps | `speckit-converge` |
| Create a feature checklist | `speckit-checklist` |
| Produce a business narrative from a feature spec | `speckit-docbiz` |
| Create or update the project constitution | `speckit-constitution` |
| Convert approved tasks into GitHub issues | `speckit-taskstoissues` |

If no installed skill directly applies, record that outcome and continue under the
workspace instructions. Do not invent a skill name or force an unrelated skill.

## Combination rules

- A database migration that also changes C# persistence uses
  `flex-database-engineering` and `flex-dotnet-engineering`.
- A task that creates, renames, or exposes a backend/domain/public-contract symbol
  adds `flex-naming-convention` to its primary engineering skill.
- A feature request starts with the applicable Speckit skill. A high-level request to
  “implement” a new feature starts at `speckit-specify`; do not skip the workspace's
  explicit Speckit gates.
- A task editing rules or skills uses `flex-context-engineering` or
  `flex-skill-creator` respectively; do not add engineering skills unless their
  artifacts are also in scope.
- Select multiple skills only when each governs a distinct artifact or decision.
  Do not add a skill merely because it appears later in a generic delivery lifecycle.

## Routing result

Before performing the task, report:

```text
Routing result
- Primary: <skill or none>
- Additional: <skill list or none>
- Reason: <one sentence>
- Re-route required: <yes only when scope has changed; otherwise no>
```

Keep this report brief. If the user asked only a conversational question and no file
or tool action is needed, answer directly without routing chatter.

## Verification

- [ ] Every selected skill exists in the installed workspace catalog.
- [ ] Selected skills directly govern the task's artifact or decision.
- [ ] The selected skill instructions were read before file or tool work began.
- [ ] No non-existent lifecycle skill or broken reference was used.
- [ ] A re-route happened only after a concrete scope change.
