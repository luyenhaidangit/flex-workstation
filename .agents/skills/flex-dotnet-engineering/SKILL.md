---
name: flex-dotnet-engineering
description: Design, implement, refactor, review, diagnose, and performance-harden production .NET and C# systems using maintainable, secure, observable, and evidence-driven conventions. Use for .sln, .slnx, .csproj, C# source, ASP.NET Core APIs, workers, class libraries, EF Core, dependency injection, async and concurrency, caching, messaging, distributed or multi-tenant systems, testing, CI/CD, architecture decisions, code reviews, clean-code requests, performance work, and production-readiness assessments. Use when a user asks for .NET best practices, conventions, Clean Architecture, maintainability, scalability, reliability, security, or a concrete implementation or review of those concerns.
---

# .NET Engineering

## Overview

Apply production-oriented .NET conventions without imposing architecture, packages, or upgrades that the repository does not need. Optimize for correctness and clarity first; optimize measured bottlenecks second.

## When to Use

- Designing, implementing, or refactoring a .NET/C# system, API, worker, or class library
- Reviewing code or assessing production-readiness of a .NET change
- Diagnosing a correctness, reliability, or performance issue in .NET code
- Touching `.sln`, `.slnx`, `.csproj`, `Directory.Build.*`, `Directory.Packages.props`, or CI/CD configuration for a .NET project
- The user asks for .NET/C# best practices, Clean Architecture, maintainability, scalability, reliability, or security guidance
- Bootstrapping a new ASP.NET Core service from scratch

## Follow the precedence rules

1. Follow the user's explicit requirements.
2. Follow repository instructions, accepted ADRs, public contracts, and established local conventions.
3. Apply this skill where the repository is silent or where the user asks to improve its conventions.
4. Explain a deliberate exception when security, correctness, support status, or measured performance justifies departing from local practice.

Preserve unrelated user changes. Avoid broad rewrites, package churn, framework upgrades, or architectural migrations unless they are required by the request.

## Execute the workflow

### Execution order — mandatory

For every implementation, refactor, diagnosis, review, performance, security, observability, or delivery task, execute the phases in this order and do not skip ahead:

```text
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
```

Each phase must produce its required evidence before the next phase begins:

- Phase 0: scope, authority, acceptance criteria, non-goals, and risk classification.
- Phase 1: repository context, affected call path, existing patterns, and assumptions.
- Phase 2: responsibility, contracts, architecture, execution flow, and edge-case design.
- Phase 3: focused implementation matching the approved scope.
- Phase 4: verification results and remaining unverified behavior.
- Phase 5: review findings and residual risks.
- Phase 6: final report with changed files, validation, and risks.

Do not implement while Phase 0–2 evidence is missing. Do not report completion while Phase 4–5 is missing. If a phase is blocked, state the blocker and stop rather than silently reordering the workflow. A user may explicitly request a single phase; in that case, perform only that phase and report the skipped phases.

For review, diagnosis, explanation, or documentation tasks, do not modify code unless the user explicitly authorizes implementation. For implementation tasks, Phase 0–2 are mandatory gates before editing.

### Phase 0 — Scope and risk

Before designing or editing:

- Classify the task as feature, bug fix, refactor, review, performance, security, observability, or delivery work.
- Identify the affected repository, service, project, public contract, and files. Preserve unrelated worktree changes.
- Assess compatibility, data-loss, authorization, tenant-isolation, concurrency, availability, and latency risks.
- Define acceptance criteria, non-goals, and the smallest change that can satisfy the request.

Stop and ask for direction when the required scope, authority, or public-contract change cannot be inferred safely. Do not expand from one service to another merely because a similar pattern exists.

### Phase 1 — Discover: repository profile and existing patterns

Inspect before designing or editing:

- Read repository instructions and relevant documentation.
- Inspect `global.json`, solution files, project files, `Directory.Build.*`, `Directory.Packages.props`, `.editorconfig`, analyzers, CI, tests, container/deployment files, and representative source.
- Identify target frameworks, application types, dependency versions, nullable/analyzer settings, persistence providers, deployment model, public contracts, and current architectural boundaries.
- Check the worktree and keep the requested scope separate from unrelated changes.
- Run `python3 <skill-dir>/scripts/inspect_dotnet_repo.py <repo-root>` when a quick read-only inventory is useful. Treat its findings as review signals, not proven defects.

Do not assume the newest runtime is compatible. Preserve the repository target unless an upgrade is requested or an unsupported version creates material risk; verify current support status from official sources before making a version recommendation.

Before choosing a project or startup format, locate and read the repository's applicable scaffold/template and its matching examples. Treat explicit template lifecycle rules as a contract: if the template defines a required `Program.cs` flow, logging initialization, exception boundary, shutdown flush, or extension entry point, follow it even when sibling projects are inconsistent. Build the implementation from the template first, then adapt only the registrations and concerns that actually exist in the target project. Do not infer the required format from sibling projects alone.

### Phase 2 — Design: responsibility, contracts, and execution flow

Before implementation, trace the current input-to-output call path, find the closest existing pattern, and record unresolved assumptions and edge cases. Check public DTOs, API routes, events, Hub methods, persistence schemas, and caller compatibility. Make authentication, authorization, tenant scoping, validation, cancellation, timeout, failure, retry, transaction, concurrency, and idempotency behavior explicit when applicable.

Load only the relevant guidance and choose the simplest fitting architecture:

During this phase, invoke `flex-naming-convention` before implementation when the task creates, renames, exposes, or changes the responsibility of a symbol or public contract. If the task has no naming-affecting change, record naming review as not applicable and continue. Resolve `ERROR` findings or explicitly accept documented `WARNING`/`SUGGESTION` findings before Phase 3.

| Concern | Read |
| --- | --- |
| Clean Architecture implementation, layer ownership, vertical slices, or dependency direction | [architecture.md](references/architecture.md) first, then the relevant data, API, security, messaging, and testing references |
| Architecture, boundaries, project layout, DI | [architecture.md](references/architecture.md) |
| C# naming, types, APIs, nullability, async | [csharp-and-api-design.md](references/csharp-and-api-design.md) |
| ASP.NET Core HTTP APIs and workers | [aspnet-core.md](references/aspnet-core.md) |
| EF Core, SQL, transactions, migrations | [ef-core-data.md](references/ef-core-data.md) |
| Profiling, caching, throughput, resilience | [performance-resilience.md](references/performance-resilience.md) |
| Authentication, authorization, secrets, telemetry | [security-observability.md](references/security-observability.md) |
| Messaging, outbox, jobs, multi-tenancy | [distributed-systems.md](references/distributed-systems.md) |
| Test strategy, analyzers, CI/CD, release safety | [testing-delivery.md](references/testing-delivery.md) |
| Structured code or architecture review | [review-checklist.md](references/review-checklist.md) |

### Architecture selection

For a new business system, begin with a modular monolith organized by business capability or vertical feature unless independent deployment, ownership, scaling, isolation, or failure boundaries clearly justify services. Keep domain and application policy independent of infrastructure details where that separation pays for itself.

Do not create interfaces, repositories, mediators, factories, DTO layers, or projects solely to match a diagram. Introduce an abstraction when it protects a real boundary, supports multiple implementations, isolates volatile infrastructure, improves testability of important policy, or removes demonstrated duplication.

For Clean Architecture work, make the responsibility and dependency of every layer explicit before adding code. Implement one thin vertical slice from transport to durable state, then add cross-cutting policies and asynchronous integration only when their failure semantics are designed. Keep the host as the composition root; do not let HTTP, EF Core, vendor SDK, or broker types leak into stable business policy.

### Phase 3 — Implement or diagnose

For implementation or refactor tasks:

- Reuse existing components, services, middleware, persistence, and integration patterns before introducing new code.
- Implement the smallest correct change that satisfies the approved scope.
- Preserve public contract compatibility unless a breaking change is explicitly requested.
- Match existing naming and formatting; keep the diff focused.

For review, diagnosis, explanation, or documentation tasks:

- Do not modify code unless explicitly authorized.
- Produce evidence-based findings, assumptions, impact, and the smallest safe remediation.

### Phase 4 — Verify in proportion to risk

Use repository-provided commands first. Otherwise, select applicable checks such as restore, build with warnings enforced by the project, unit tests, integration tests, formatting/analyzers, package vulnerability checks, migration validation, contract tests, and focused benchmarks or load tests.

Never claim a command passed unless it ran successfully. If the full suite is impractical, run the narrowest meaningful checks and state what remains unverified. Do not weaken analyzers, tests, nullable checks, or security controls merely to make validation pass.

- Run static checks, formatting/analyzers, `git diff --check`, and a search for stale references.
- Build every affected project and run the narrowest relevant tests.
- Verify runtime behavior when the change involves authentication, authorization, HTTP contracts, SignalR/WebSocket, database, messaging, or hosting lifecycle.
- Check relevant edge cases: unauthorized access, invalid input, timeout, cancellation, retry/duplicate delivery, concurrent requests, reconnect, and resource cleanup.

### Phase 5 — Review

Review the completed change for correctness, public-contract compatibility, architecture, naming, dependency direction, security, reliability, performance, and observability. Apply the severity, evidence, and residual-risk rules in “Review with severity and proof”.

### Phase 6 — Report decisions and evidence

Lead with the outcome. Summarize material design decisions and tradeoffs, changed behavior, validation performed, and remaining risks. For a review, list actionable findings before general observations and cite exact code locations.

## Enforce the baseline

Unless the repository has a justified alternative:

- Enable nullable reference analysis and modern .NET analyzers for new code.
- Keep warnings visible and ratchet quality gates instead of hiding legacy warnings globally.
- Use clear domain and feature names; avoid `Manager`, `Helper`, `Common`, and `Utils` when a precise responsibility exists.
- Name projects by responsibility and include the service name: `{Company}.{Service}.Domain`, `{Company}.{Service}.Application` (when orchestration is substantial), `{Company}.{Service}.Infrastructure`, `{Company}.{Service}.Api`, and `{Company}.{Service}.Worker`.
- Keep project, assembly, root namespace, folder, solution entry, project references, and test namespaces aligned when renaming a project.
- For a new service repository, use `src/` for production projects and `tests/` for test projects. Name tests `{Company}.{Service}.{Layer}.Tests` or `{Company}.{Service}.IntegrationTests`.
- Organize the solution with `src` and `tests` solution folders when the repository has multiple projects; do not add an `Application` project solely to satisfy a diagram.
- Keep dependencies directed inward: `Domain` must not depend on HTTP, persistence, messaging, or vendor SDKs; `Infrastructure` implements outer concerns; `Api` or `Worker` is the composition root.
- Let `Application` own use-case orchestration, application authorization decisions, transaction boundaries, and ports to volatile infrastructure. Let `Domain` own invariants and state transitions; keep persistence mapping and side-effect delivery outside it.
- For a new service baseline, inspect or add `global.json`, `Directory.Build.props`, `Directory.Packages.props`, `.editorconfig`, `NuGet.config` when multiple package feeds exist, and a CI workflow that runs restore, build, and test.
- Prefer immutable request/value data and explicit state transitions.
- Use exceptions for exceptional failure, not routine branching; map boundary failures consistently.
- Use explicit outcomes for expected business alternatives, but do not hide programming, infrastructure, timeout, or cancellation failures inside a universal `Result<T>` wrapper.
- Use UTC or `DateTimeOffset` for instants and inject `TimeProvider` when time affects behavior.
- Avoid sync-over-async, unbounded parallelism, unbounded caches, fire-and-forget work, and request-scoped work after the request completes.
- Project only required data, use no-tracking reads where appropriate, and verify generated SQL and indexes for important queries.
- Apply timeouts to remote calls; retry only transient, safe operations with bounded attempts and jitter.
- Require policy/resource-based authorization, explicit tenant isolation, secret-safe configuration, and safe logs.
- Emit correlated logs, traces, and metrics for critical paths; expose meaningful readiness and liveness signals.
- Test behavior at the cheapest reliable level and use real infrastructure semantics where mocks would lie.

## Bootstrap a new service consistently

Use the executable scaffold at [`templates/clean-architecture-service`](templates/clean-architecture-service) as the starting point for a new ASP.NET Core service. The scaffold contains `.template` source files with `{Company}`, `{Service}`, `{company}`, and `{service}` placeholders and a `render.ps1` script for safe copy-and-substitute generation. Keep [`templates/clean-architecture-template.md`](templates/clean-architecture-template.md) as the architecture rationale and review checklist; it is not a substitute for the code scaffold.

When creating a new service or restructuring an existing one, apply this short checklist:

1. Choose the service identity and project names first: `{Company}.{Service}.Domain`, `{Company}.{Service}.Api` or `{Company}.{Service}.Worker`, and add `Infrastructure` or `Application` only when their boundaries are real.
2. Create the solution at the repository root with `src/` and `tests/`; keep project paths and namespaces identical to the chosen names.
3. Centralize SDK defaults, package versions, formatting, and package sources at the repository root. Pin the SDK with `global.json` when reproducible local and CI builds matter.
4. Add focused domain tests and at least one boundary/integration test for an API or worker. For ASP.NET Core integration tests, expose `public partial class Program;` when `WebApplicationFactory<Program>` is used.
5. Add CI before the first feature is merged and verify with `dotnet restore`, `dotnet build --configuration Release`, `dotnet test`, and `git diff --check`.

## Avoid cargo-cult patterns

Do not:

- split a system into microservices only for theoretical scalability;
- wrap EF Core in a generic CRUD repository that removes useful query and transaction semantics;
- add a mediator or event bus for every in-process method call;
- return persistence entities directly from public APIs;
- retry non-idempotent operations without an idempotency design;
- cache without ownership, key scope, TTL, size, invalidation, and failure behavior;
- use `Task.Run` to disguise blocking server I/O;
- optimize allocations, use pooling, compiled queries, `ValueTask`, `Span<T>`, or Native AOT without a measured reason;
- expose exception details, secrets, tokens, connection strings, or sensitive payloads in responses or telemetry;
- treat passing unit tests as proof of database, serialization, authorization, or distributed-system correctness.

## Review with severity and proof

For reviews, prioritize defects and risks over style preferences:

- **Critical**: exploitable security issue, cross-tenant access, likely data loss, or production outage.
- **High**: incorrect behavior, broken contract, serious concurrency/reliability issue, or major scalability risk on a known path.
- **Medium**: maintainability or performance issue with a credible failure mode.
- **Low**: localized clarity or consistency improvement.

For each finding, state location, evidence, impact, triggering scenario, and smallest safe remediation. Do not report a hypothetical anti-pattern as a defect without checking its call path, lifetime, configuration, or generated behavior.

Keep concerns that depend on unseen global configuration, middleware, deployment controls, or caller behavior out of the confirmed finding list. Put them under questions or residual risks, state the potential impact separately, and request the exact evidence needed to confirm or dismiss them.

## Keep external guidance current

Prefer official .NET, ASP.NET Core, EF Core, C#, and OpenTelemetry documentation for version-sensitive claims. Treat package APIs, supported runtimes, hosting behavior, and security recommendations as time-sensitive and verify them when they affect the result.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It's simpler to wrap EF Core in a generic repository now" | That removes the query and transaction semantics EF Core already gives you. Add a repository only when it protects a real boundary or has more than one implementation. |
| "We'll add a mediator/event bus so it's ready to scale" | An in-process method call dressed up as an event adds indirection with no payoff until there is a real reason to decouple caller from handler. |
| "Passing unit tests means it's production-ready" | Unit tests don't prove database, serialization, authorization, or distributed-system correctness — verify those paths with the checks that actually exercise them. |
| "The newest .NET version is always safe to target" | Preserve the repository's current target framework unless an upgrade was requested or the current version is unsupported and creates material, verified risk. |
| "It's just a review comment, I don't need to point at code" | A finding without a location, evidence, and triggering scenario gets argued with instead of fixed. Cite the exact line and the failure path. |
| "Retrying failed calls is always safer" | Retrying a non-idempotent operation without an idempotency design can duplicate side effects. Design the retry, don't default to it. |
| "I ran the tests" (but didn't check the output) | A command that wasn't observed to succeed can't be reported as passing. State what actually ran and what its result was. |

## Red Flags

- A new interface, repository, mediator, or factory with exactly one implementation and no stated reason for the abstraction
- `Domain` project referencing HTTP, EF Core, a vendor SDK, or a message-broker type
- A universal `Result<T>` wrapper swallowing programming, infrastructure, timeout, or cancellation failures alongside expected business outcomes
- Retry logic around an operation with no idempotency key or design behind it
- A cache with no stated owner, TTL, size bound, or invalidation path
- A review finding with no code location, evidence, or triggering scenario attached
- A verification command reported as passing without its actual output having been observed
- A secret, token, connection string, or full request/response payload appearing in logs, telemetry, or an error response

## Verification

- [ ] Repository-provided verification commands ran and their actual output was observed, not assumed
- [ ] When an applicable scaffold/template exists, the touched startup/configuration files were compared against it and all mandatory lifecycle rules were preserved
- [ ] Nullable/analyzer warnings on touched code are not suppressed or weakened merely to pass
- [ ] Dependency direction still points inward: `Domain` has no HTTP, persistence, or vendor SDK reference
- [ ] Every new abstraction (interface, repository, mediator) has a stated reason — protects a real boundary or has 2+ implementations
- [ ] State-changing use cases have an explicit transaction owner, concurrency behavior, and idempotency strategy
- [ ] Authorization and tenant scoping are enforced before data access, not assumed
- [ ] No secret, token, connection string, or unnecessary personal data appears in logs, telemetry, or responses
- [ ] For a review: findings are ranked Critical/High/Medium/Low, each with location, evidence, and remediation
