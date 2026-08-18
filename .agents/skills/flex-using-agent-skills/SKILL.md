---
name: flex-using-agent-skills
description: Routes a task to the smallest applicable set of installed workspace skills. Use when starting any task that reads, analyzes, reviews, or changes workspace or repository files.
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

## Speckit integration

Speckit owns the feature lifecycle; it does not replace the engineering skill that
governs a planned or changed artifact. Apply routing in two stages when a Speckit
workflow makes the technical scope concrete:

1. The initial route selects the invoked `speckit-*` lifecycle skill.
2. After `plan.md` or `tasks.md` identifies the affected artifacts, route once more
   to select **additional** specialist skills before planning or editing source.

For this nested route, retain the active Speckit skill as the lifecycle owner and
return only additional specialist skills. Do not route the same `speckit-*` skill
again and do not recursively invoke this router.

| Speckit lifecycle | Required routing behavior |
| --- | --- |
| `speckit-plan` | Use the technical context and planned artifacts to select applicable specialist skills before making architecture, data, API, or test decisions. |
| `speckit-implement` | After loading plan and tasks, select and apply applicable specialist skills before editing source; re-route only if a later task introduces a new artifact domain. |
| `speckit-converge` | Assess spec/plan/task coverage only. A converged result still requires a separate final review task routed to the applicable specialist skills before the feature is considered complete. |

Examples: C# changes add `flex-dotnet-engineering`; database migrations add
`flex-database-engineering`; Angular UI adds `flex-frontend-engineering`; backend
or public-contract naming changes add `flex-naming-convention`.

## Routing table

Select only skills that directly govern the task.

| Task or primary artifact | Primary skill |
| --- | --- |
| PostgreSQL schema, Liquibase changelog, migration, seed, index, constraint, database function, view, or trigger | `flex-database-engineering` |
| C#/.NET, ASP.NET Core, EF Core, dependency injection, tests, architecture, or service implementation | `flex-dotnet-engineering` |
| Angular UI in `flex-microfrontend`, including components, templates, forms, modals, and tables | `flex-frontend-engineering` |
| Dockerfile, Docker Compose, HAProxy, Jenkins, CI/CD, deployment scripts, environment configuration, container networking, health checks, observability, rollout, or rollback | `flex-devops-engineering` |
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
| Assess a feature's business-documentation impact and update the relevant documentation | `speckit-docbiz` |
| Create or update the project constitution | `speckit-constitution` |
| Convert approved tasks into GitHub issues | `speckit-taskstoissues` |

If no installed skill directly applies, record that outcome and continue under the
workspace instructions. Do not invent a skill name or force an unrelated skill.

## Combination rules

- A database migration that also changes C# persistence uses
  `flex-database-engineering` and `flex-dotnet-engineering`.
- Infrastructure work that also changes application code or database schema uses
  `flex-devops-engineering` plus the applicable frontend, .NET, database, or naming
  skill. Keep artifact ownership distinct rather than duplicating domain rules.
- A task that creates, renames, or exposes a backend/domain/public-contract symbol
  adds `flex-naming-convention` to its primary engineering skill.
- A feature request starts with the applicable Speckit skill. A high-level request to
  “implement” a new feature starts at `speckit-specify`; do not skip the workspace's
  explicit Speckit gates.
- An active Speckit workflow is not an exclusive route. Use the Speckit integration
  rules to add only the specialist skills that govern its concrete artifacts.
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
