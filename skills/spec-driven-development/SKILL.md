---
name: spec-driven-development
description: >
  Creates specs before coding. Use when starting a new project, feature, or significant change and no specification exists yet.
  Use when requirements are unclear, ambiguous, or only exist as a vague idea.
  Do NOT use for single-line fixes, typo corrections, or changes where requirements are fully clear and self-contained.
  Done when spec file is saved to docs/specs/, implementation plan and task breakdown are approved or explicitly handed off.
---

# Spec-Driven Development

## Overview

Write a structured specification before writing any code. The spec is the shared source of truth between you and the human engineer — it defines what we're building, why, and how we'll know it's done. Code without a spec is guessing.

## When to Use

- Starting a new project or feature
- Requirements are ambiguous or incomplete
- The change touches multiple files or modules
- You're about to make an architectural decision
- The task would take more than 30 minutes to implement

**When NOT to use:** Single-line fixes, typo corrections, or changes where requirements are unambiguous and self-contained.

## The Gated Workflow

Spec-driven development has four phases. For substantial work, seek human validation before moving to the next phase. For small changes, produce a concise spec, clearly mark assumptions, and continue when the requirements are unambiguous.

```
SPECIFY ──→ PLAN ──→ TASKS ──→ IMPLEMENT
   │          │        │          │
   ▼          ▼        ▼          ▼
 Human      Human    Human      Human
 reviews    reviews  reviews    reviews
```

## Input Contract

**Required:** A project, feature, or change request to specify.

**Optional:** Repository path, tech stack, constraints, existing requirements, target spec file, acceptance criteria, deadlines, or known risks.

### Phase 1: Specify

**Save location:** Save the spec to `docs/specs/YYYY-MM-DD-<feature-name>.md` in the working project (kebab-case, today's date, e.g. `2026-06-14-auth-refresh-token.md`, `2026-06-14-user-dashboard-redesign.md`). Create the `docs/specs/` directory if it doesn't exist. Do not save to the project root — multiple specs will accumulate and clutter it.

Start with a high-level vision. Ask the human clarifying questions until requirements are concrete.

**Surface assumptions immediately.** Before writing any spec content, list what you're assuming:

```
ASSUMPTIONS I'M MAKING:
1. This is a web application (not native mobile)
2. Authentication uses session-based cookies (not JWT)
3. The database is PostgreSQL (based on existing Prisma schema)
4. We're targeting modern browsers only (no IE11)
→ Correct me now or I'll proceed with these.
```

Don't silently fill in ambiguous requirements. The spec's entire purpose is to surface misunderstandings *before* code gets written — assumptions are the most dangerous form of misunderstanding.

**Write a spec document covering these six core areas:**

1. **Objective** — What are we building and why? Who is the user? What does success look like?

2. **Commands** — Full executable commands with flags, not just tool names.
   ```
   Build: npm run build
   Test: npm test -- --coverage
   Lint: npm run lint --fix
   Dev: npm run dev
   ```

3. **Project Structure** — Where source code lives, where tests go, where docs belong.
   ```
   src/           → Application source code
   src/components → React components
   src/lib        → Shared utilities
   tests/         → Unit and integration tests
   e2e/           → End-to-end tests
   docs/          → Documentation
   ```

4. **Code Style** — One real code snippet showing your style beats three paragraphs describing it. Include naming conventions, formatting rules, and examples of good output.

5. **Testing Strategy** — What framework, where tests live, coverage expectations, which test levels for which concerns.

6. **Boundaries** — Three-tier system:
   - **Always do:** Run tests before commits, follow naming conventions, validate inputs
   - **Ask first:** Database schema changes, adding dependencies, changing CI config
   - **Never do:** Commit secrets, edit vendor directories, remove failing tests without approval

For substantial changes, add optional operational sections where relevant: Risks, Rollout, Migration, Security, Performance, and Compatibility.

**Spec template:**

```markdown
# Spec: [Project/Feature Name]

**Date:** YYYY-MM-DD
**Feature:** [feature-name-kebab-case]
**Status:** Draft
**Author:** [author]

## Objective
[What we're building and why. User stories or acceptance criteria.]

## Tech Stack
[Framework, language, key dependencies with versions]

## Commands
[Build, test, lint, dev — full commands]

## Project Structure
[Directory layout with descriptions]

## Code Style
[Example snippet + key conventions]

## Testing Strategy
[Framework, test locations, coverage requirements, test levels]

## Boundaries
- Always: [...]
- Ask first: [...]
- Never: [...]

## Risks
[Optional: key technical, product, delivery, or operational risks.]

## Rollout / Migration
[Optional: rollout plan, migration steps, rollback approach, compatibility notes.]

## Security / Performance
[Optional: security, privacy, performance, and reliability considerations.]

## Success Criteria
[How we'll know this is done — specific, testable conditions]

## Open Questions
[Anything unresolved that needs human input]
```

**Reframe instructions as success criteria.** When receiving vague requirements, translate them into concrete conditions:

```
REQUIREMENT: "Make the dashboard faster"

REFRAMED SUCCESS CRITERIA:
- Dashboard LCP < 2.5s on 4G connection
- Initial data load completes in < 500ms
- No layout shift during load (CLS < 0.1)
→ Are these the right targets?
```

This lets you loop, retry, and problem-solve toward a clear goal rather than guessing what "faster" means.

### Phase 2: Plan

With the validated spec, generate a technical implementation plan. The plan should be reviewable: the human should be able to read it and say "yes, that's the right approach" or "no, change X."

**Plan template:**

```markdown
## Plan: [Feature Name]

### Components
- [Component 1]: [short description, e.g. "RefreshToken entity + Oracle table"]
- [Component 2]: [short description]

### Implementation Order
1. [First step] — reason: [why this must come first, e.g. "other steps depend on this schema"]
2. [Next step] — can run in parallel with [X] if [condition]

### Risks
- [Risk]: [Mitigation strategy]

### Checkpoints
- [ ] [What to verify at checkpoint 1]
- [ ] [What to verify at checkpoint 2]
```

### Phase 3: Tasks

Break the plan into discrete, implementable tasks:

- Each task should be completable in a single focused session
- Each task has explicit acceptance criteria
- Each task includes a verification step (test, build, manual check)
- Tasks are ordered by dependency, not by perceived importance
- Prefer tasks that touch no more than ~5 files. If a task must touch more, split it when practical or explain why it should remain a single task.

**Task template:**
```markdown
- [ ] Task: [Description]
  - Acceptance: [What must be true when done]
  - Verify: [How to confirm — test command, build, manual check]
  - Files: [Which files will be touched]
```

### Phase 4: Implement

Execute tasks one at a time. If the workspace has skills `incremental-implementation`, `test-driven-development`, or `context-engineering` available, load them at the start — they guide incremental execution, test-first habits, and focused context loading respectively. If they're not available, proceed without them.

## Keeping the Spec Alive

The spec is a living document, not a one-time artifact:

- **Update when decisions change** — If you discover the data model needs to change, update the spec first, then implement.
- **Update when scope changes** — Features added or cut should be reflected in the spec.
- **Commit the spec** — The spec belongs in version control alongside the code.
- **Reference the spec in PRs** — Link back to the spec section that each PR implements.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "This is simple, I don't need a spec" | Simple tasks don't need *long* specs, but they still need acceptance criteria. A two-line spec is fine. |
| "I'll write the spec after I code it" | That's documentation, not specification. The spec's value is in forcing clarity *before* code. |
| "The spec will slow us down" | A 15-minute spec prevents hours of rework. Waterfall in 15 minutes beats debugging in 15 hours. |
| "Requirements will change anyway" | That's why the spec is a living document. An outdated spec is still better than no spec. |
| "The user knows what they want" | Even clear requests have implicit assumptions. The spec surfaces those assumptions. |

## Red Flags

- Starting to write code without any written requirements
- Asking "should I just start building?" before clarifying what "done" means
- Implementing features not mentioned in any spec or task list
- Making architectural decisions without documenting them
- Skipping the spec because "it's obvious what to build"

## Boundaries

- Do not overwrite an existing spec file without confirming with the human first.
- Do not write any implementation code until the human has approved Phase 1 (Spec).
- Do not advance to the next phase when the human hasn't responded yet — wait for an explicit signal ("ok", "looks good", "proceed", or equivalent).
- Do not embed secrets, credentials, connection strings, or tokens in spec files.

## Verification

Before proceeding to implementation, confirm:

- [ ] The spec covers all six core areas
- [ ] The human has reviewed and approved the spec
- [ ] Success criteria are specific and testable
- [ ] Boundaries (Always/Ask First/Never) are defined
- [ ] The spec is saved to `docs/specs/YYYY-MM-DD-<feature-name>.md`
