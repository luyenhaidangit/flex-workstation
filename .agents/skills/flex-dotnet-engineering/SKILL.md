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

For a new service, a new API/Worker host, or any change to startup/configuration,
inspect the closest healthy service's logging implementation before editing. Compare
the host bootstrap, logging configuration, package references, structured enrichers,
service identity, correlation fields, sinks, buffering, shutdown flush, and deployment
route. Treat an installed logging package as insufficient evidence: the sink must be
configured and its destination must be reachable in the target hosting mode.

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

### Prefer framework capabilities before custom code

Before writing a helper, utility, extension method, serializer, query builder,
validation rule, HTTP abstraction, or infrastructure wrapper, search the current
codebase and verify whether the target framework or an already-approved Microsoft
package provides the behavior. Prefer the existing capability when it matches the
required semantics because it reduces duplicated edge-case handling and keeps the
code aligned with supported .NET behavior.

Use this order of preference:

1. Existing project code with the same responsibility and compatible semantics.
2. .NET BCL APIs such as `UriBuilder`, `HttpClient`, `System.Text.Json`,
   `TimeProvider`, collections, and cancellation primitives.
3. ASP.NET Core, EF Core, and `Microsoft.Extensions` APIs already available to the
   project, such as `QueryHelpers`, model binding, `ProblemDetails`, options,
   logging, caching, and EF query operators.
4. An official, supported Microsoft package when the project does not already
   reference the required API and the dependency is justified by the boundary.
5. A focused custom implementation only when the framework capability is missing,
   has incompatible semantics, or the behavior is domain-specific.

Before adding a package, check target-framework compatibility, package ownership,
version policy, transitive dependency impact, and whether the same capability is
already exposed by a framework reference. Do not add a custom `Helper` or `Utils`
class merely to wrap one framework call. Keep framework-specific utilities in the
outer layer that needs them; do not pull ASP.NET Core dependencies into `Domain`
or stable application policy without a boundary reason.

### Prefer named intermediate results when they improve inspectability

For non-trivial expressions, external-call results, constructed URLs or payloads,
query results, mappings, and values that may need debugging, assign the result to a
clearly named local variable before returning it. This gives the debugger a stable
value to inspect and makes logging, validation, and step-by-step diagnosis easier.
Use direct `return` for genuinely simple expressions where a local name adds no
debugging or readability value; do not create meaningless aliases solely to add a
line of code.

For Clean Architecture work, make the responsibility and dependency of every layer explicit before adding code. Implement one thin vertical slice from transport to durable state, then add cross-cutting policies and asynchronous integration only when their failure semantics are designed. Keep the host as the composition root; do not let HTTP, EF Core, vendor SDK, or broker types leak into stable business policy.

### Adopt an in-process mediator only at a demonstrated operation boundary

MediatR or another in-process mediator is justified when a controller owns several
non-trivial use cases and the same Application operations need a uniform dispatch,
test, or pipeline boundary. Reducing a constructor's parameter count alone is not
sufficient justification; the mediator must also remove application orchestration
from the transport layer.

Before adding a mediator package, inspect its target-framework compatibility,
transitive `Microsoft.Extensions.*` dependencies, license/runtime configuration,
and the repository's package-version convention. Pin an intentional version and
record any compatibility or licensing constraint; do not select an old version
solely to avoid an unreviewed package policy.

When a mediator is justified:

1. Define a focused `IRequest<TResponse>` command or query and an
   `IRequestHandler<TRequest, TResponse>` named after the use case.
2. Inject `ISender` into a controller that only sends requests; do not inject
   `IMediator` when publishing notifications is not part of its responsibility.
3. Move every in-scope action that still owns application orchestration. Do not
   add one concrete handler beside repositories and claim the controller DI problem
   is solved; explicitly label that state as an intermediate migration instead.
4. Keep Application request/result types free of API DTOs, `ActionResult`, status
   codes, and HTTP error envelopes. Map them at the controller boundary.
5. Scan the Application assembly from the composition root rather than registering
   individual handlers as concrete services. Add a pipeline behavior only for a
   defined cross-cutting policy and test its ordering and failure semantics.

Keep a request and its single handler co-located in the feature folder when the
request is only used by that handler and the combined file remains easy to scan.
Name the file after the request type, such as `GetAgentsQuery.cs` or
`CreateAgentCommand.cs`, because the file contains both the request and handler;
do not name it `*Handler.cs` merely because the handler is the executable part.
Split the request and handler when either type has an independent reuse boundary,
the file contains several supporting responsibilities, or the combined file has
become difficult to navigate. File length is a review signal, not a hard threshold.

For a simple one-step CRUD action with no reusable orchestration, keep the direct
flow. Do not introduce a mediator merely because nearby actions use one.

### Keep HTTP controllers at the transport boundary

Keep controllers focused on routing, binding, authentication/authorization context,
calling one use case, and translating that use case's outcome to HTTP. A controller
may perform a short, one-off response projection, but it must not accumulate
application orchestration.

When an endpoint coordinates more than one repository or external port, batches or
joins related data, applies application-level authorization/decision logic, owns a
transaction, or has logic that another transport could reuse, move that work to one
focused Application command/query handler. Name it after the use case, such as
`GetAgentsQueryHandler`, rather than creating a generic `AgentService` or a handler
per entity by default.

- Application owns use-case input and read/write models. A read handler may return a
  purpose-specific application read model and project only the data it needs; it does
  not need to hydrate an aggregate solely for an API response.
- Presentation owns public request/response DTOs, HTTP status codes, and mapping from
  an application result to its HTTP contract. Do not make Application depend on an
  API DTO merely to shorten a controller.
- Infrastructure implements Application-owned ports. Do not introduce a mediator,
  generic query service, generic repository, or interface for a single concrete
  handler unless the repository already uses it or a real substitution/pipeline
  boundary exists.
- Keep the refactor at the operation boundary. Moving `GET /agents` into a query
  handler does not authorize an unrelated rewrite of every action in `AgentsController`.

For simple CRUD that has no meaningful orchestration, keep the direct endpoint flow
and do not add an Application project, handler, or abstraction only to imitate a
diagram.

### Make write ownership and database conflicts explicit

For a command that stages changes through multiple repositories sharing one EF Core
`DbContext`, the handler owns one explicit commit. Repository methods stage changes;
the handler commits once after all domain transitions and local validation succeed.
Do not call `SaveChangesAsync` through each repository, because the first call flushes
the whole tracked unit of work and obscures the real transaction owner.

A preflight uniqueness check improves the ordinary error path but cannot prevent a
concurrent writer from winning the race. Keep the database unique constraint as the
authority. The Infrastructure adapter should translate the known provider-specific
constraint violation into an Application-owned expected alternative; the handler
then returns its focused conflict outcome, and Presentation maps it to the existing
HTTP contract. Do not catch every `DbUpdateException` as a conflict or convert
unexpected database failures into a routine result.

When this behavior is material, add a focused handler test for the translated
alternative and a real-provider integration/concurrency test for the constraint.

### Logging pattern gate

When creating a service or updating a backend service's host, configuration, or
operational behavior, logging review is a required design gate:

1. Select one or more current repository services as canonical examples and read the
   source configuration, not generated `bin/` output. Prefer the closest service with
   the same hosting and deployment model; if examples disagree, record the conflict
   and follow the explicit repository/template rule.
2. Verify the complete path, not just application code:
   `host bootstrap → structured logger → sink/transport → collector or Logstash →
   Elasticsearch/index or other approved backend`.
3. Match the current pattern for `service.name`, environment/host fields, trace/span
   correlation, exception fields, minimum levels, batching/backpressure, local
   fallback, and graceful `Log.CloseAndFlush()`/shutdown behavior.
4. For centralized logging, verify the sink is actually present in `WriteTo`, the
   endpoint is configuration-driven or deliberately fixed by the repository pattern,
   credentials are secret-safe, and the target is reachable from the service's real
   process/container network. A package listed in `csproj` or `Using` alone does not
   count.
5. Check the receiving route and index naming. Confirm the collector can preserve or
   derive the service identity so a new service cannot silently fall into another
   service's default index.
6. Confirm safe telemetry: no tokens, credentials, authorization headers, connection
   strings, raw sensitive bodies, or unbounded high-cardinality payloads. Log once at
   the handling boundary and keep useful error context plus correlation identifiers.

For a service creation or backend update, Phase 4 must include at least a static
configuration check and a runtime smoke check when the logging infrastructure is
available. If the service was not restarted or the backend/index was not queried,
report logging as configured-but-unverified rather than claiming end-to-end delivery.

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
- Prefer supported .NET/BCL, ASP.NET Core, EF Core, and `Microsoft.Extensions`
  capabilities over equivalent handwritten code; verify existing APIs and package
  references before introducing a helper or dependency.
- Prefer a clearly named local result before `return` when the expression is
  non-trivial or likely to be inspected during debugging; keep direct returns for
  simple expressions where the extra variable has no practical value.
- Use exceptions for exceptional failure, not routine branching; map boundary failures consistently.
- Use explicit outcomes for expected business alternatives, but do not hide programming, infrastructure, timeout, or cancellation failures inside a universal `Result<T>` wrapper.
- Use UTC or `DateTimeOffset` for instants and inject `TimeProvider` when time affects behavior.
- Avoid sync-over-async, unbounded parallelism, unbounded caches, fire-and-forget work, and request-scoped work after the request completes.
- Project only required data, use no-tracking reads where appropriate, and verify generated SQL and indexes for important queries.
- Apply timeouts to remote calls; retry only transient, safe operations with bounded attempts and jitter.
- Require policy/resource-based authorization, explicit tenant isolation, secret-safe configuration, and safe logs.
- Emit correlated logs, traces, and metrics for critical paths; expose meaningful readiness and liveness signals.
- Test behavior at the cheapest reliable level and use real infrastructure semantics where mocks would lie.

## Map Models at Their Owning Boundary

Place a mapper in the project that owns the boundary contract it produces. The
mapper may reference the source model and the boundary contract, but must not
reverse an inward dependency just to reuse a DTO.

| Mapping | Owner and location |
| --- | --- |
| Domain entity → HTTP request/response DTO | `Api` / Presentation, for example `Mappers/AgentMapper.cs` or `Features/Agents/Mappers/AgentMapper.cs` |
| Domain entity → application command/query result | `Application`, colocated with the use case that owns that contract |
| Domain entity ↔ EF Core persistence configuration/model | `Infrastructure` |
| Domain value/entity → another domain type | `Domain`, only when the conversion is domain behavior rather than transport glue |

Do not put API DTO mapping in `Domain` or `Application`, and do not put
application contracts in `Api` merely because an endpoint is their first caller.
Keep public HTTP DTOs independent from persistence entities and map them at the
presentation boundary.

### Mapper shape and naming

- A bounded context or aggregate can have one mapper such as `AgentMapper` with
  multiple pure mappings related to that aggregate (`ToResponse`,
  `ToListItemResponse`, and other explicit target names). Prefer this over one
  class per tiny DTO when the source ownership is the same.
- Split a mapper when the mapping belongs to another aggregate or grows into a
  separate coherent concern, for example `AgentPublishLocationMapper`; do not let
  `AgentMapper` map conversations, users, or unrelated contracts.
- For a small, deterministic conversion, use an `internal static` mapper with
  explicit methods. Do not add AutoMapper, `IMapper`, or a generic mapper
  abstraction without demonstrated mapping complexity, configuration, or a real
  substitution boundary.
- A mapper only transforms already-valid values. It must not validate input, check
  authorization or uniqueness, set trusted defaults or timestamps, call a
  repository, mutate an aggregate through business methods, or perform I/O. Those
  responsibilities remain in the presentation/application/domain flow that owns
  them.
- Controllers invoke a mapper instead of constructing reusable response DTOs
  inline. Keep a one-off projection local only when extracting it would add an
  unshared type with no clearer boundary.

When a controller adds a required dependency, update every direct controller
construction in tests to compose the same dependency graph using the test
infrastructure. Do not make a production dependency nullable merely to preserve
outdated tests. Remove null checks once the dependency contract is non-nullable,
then add or update a behavior test that exercises the new collaboration.

## Bootstrap a new service consistently

Use the executable scaffold at [`templates/clean-architecture-service`](templates/clean-architecture-service) as the starting point for a new ASP.NET Core service. The scaffold contains `.template` source files with `{Company}`, `{Service}`, `{company}`, and `{service}` placeholders and a `render.ps1` script for safe copy-and-substitute generation. Keep [`templates/clean-architecture-template.md`](templates/clean-architecture-template.md) as the architecture rationale and review checklist; it is not a substitute for the code scaffold.

The scaffold's `src/{Company}.{Service}.Api/Logging/` directory is the reference code
sample for service logging. Reuse its shape and update only repository-approved
differences: `SeriLogger.cs` owns logger construction, `LogFields.cs` owns stable
field names, `EcsLogEnricher.cs` adds correlation and safe exception fields, and
`serilog.json` owns Console/file/HTTP sink configuration. Do not create a second
logging sample elsewhere in the skill; keep this scaffold and the live repository
pattern aligned when either changes.

When creating a new service or restructuring an existing one, apply this short checklist:

1. Choose the service identity and project names first: `{Company}.{Service}.Domain`, `{Company}.{Service}.Api` or `{Company}.{Service}.Worker`, and add `Infrastructure` or `Application` only when their boundaries are real.
2. Create the solution at the repository root with `src/` and `tests/`; keep project paths and namespaces identical to the chosen names.
3. Centralize SDK defaults, package versions, formatting, and package sources at the repository root. Pin the SDK with `global.json` when reproducible local and CI builds matter.
4. Add focused domain tests and at least one boundary/integration test for an API or worker. For ASP.NET Core integration tests, expose `public partial class Program;` when `WebApplicationFactory<Program>` is used.
5. Add CI before the first feature is merged and verify with `dotnet restore`, `dotnet build --configuration Release`, `dotnet test`, and `git diff --check`.
6. Establish logging before the service is considered operational: reuse the approved
   repository pattern, configure structured service identity and correlation, retain
   a safe local/console fallback, and verify delivery to the configured collector and
   backend when those dependencies are available.

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
| "I moved one action into a handler, so the controller no longer has a DI problem" | A concrete handler injected beside repositories increases constructor coupling. Use `ISender` and migrate the in-scope orchestration, or label the change as an intermediate step. |
| "A `NameExistsAsync` check guarantees the duplicate-name response" | Concurrent writers can both pass the check. Preserve the database constraint and translate only its known violation into the expected conflict outcome. |
| "Calling `SaveChangesAsync` through each repository makes persistence safer" | Repositories sharing one `DbContext` share one tracked unit of work. Commit once from the command handler so transaction ownership is visible. |
| "Passing unit tests means it's production-ready" | Unit tests don't prove database, serialization, authorization, or distributed-system correctness — verify those paths with the checks that actually exercise them. |
| "The newest .NET version is always safe to target" | Preserve the repository's current target framework unless an upgrade was requested or the current version is unsupported and creates material, verified risk. |
| "It's just a review comment, I don't need to point at code" | A finding without a location, evidence, and triggering scenario gets argued with instead of fixed. Cite the exact line and the failure path. |
| "Retrying failed calls is always safer" | Retrying a non-idempotent operation without an idempotency design can duplicate side effects. Design the retry, don't default to it. |
| "I ran the tests" (but didn't check the output) | A command that wasn't observed to succeed can't be reported as passing. State what actually ran and what its result was. |
| "Every DTO needs its own mapper class or generic mapper interface" | Group pure mappings by aggregate ownership (`AgentMapper`) and split only at a real domain or contract boundary; abstractions without variation add indirection, not safety. |
| "Making a new controller dependency nullable is the fastest way to keep old tests compiling" | That weakens the production contract and leaves dead branches. Compose required dependencies in the tests and verify the collaboration instead. |
| "I can put the API response DTO in the query handler to make the controller thinner" | That reverses ownership of the HTTP contract. Let Application return a purpose-specific result and map it in Presentation. |
| "Every endpoint needs a handler, mediator, and repository to be Clean Architecture" | Clean Architecture protects responsibilities and dependency direction; straightforward CRUD can remain direct when no use-case boundary is needed. |
| "A small helper is faster than checking whether .NET already provides this" | Framework APIs carry tested encoding, parsing, cancellation, disposal, and edge-case behavior; search first and add custom code only for a real semantic gap. |
| "Adding a package is harmless because the API is convenient" | A package changes the dependency and support surface; verify target compatibility, ownership, version policy, and whether an existing framework reference already provides the capability. |
| "A direct return is always cleaner" | For non-trivial or externally produced values, a named local improves debugger inspection and makes validation or diagnostics explicit; use direct return only when it remains equally inspectable and clear. |

## Red Flags

- A new interface, repository, mediator, or factory with exactly one implementation and no stated reason for the abstraction
- `Domain` project referencing HTTP, EF Core, a vendor SDK, or a message-broker type
- A universal `Result<T>` wrapper swallowing programming, infrastructure, timeout, or cancellation failures alongside expected business outcomes
- Retry logic around an operation with no idempotency key or design behind it
- A cache with no stated owner, TTL, size bound, or invalidation path
- A review finding with no code location, evidence, or triggering scenario attached
- A verification command reported as passing without its actual output having been observed
- A secret, token, connection string, or full request/response payload appearing in logs, telemetry, or an error response
- A new service has a logging package or `Using` entry but no configured sink, no service identity, or no verified collector/backend route
- A backend change copies a sibling logger without checking whether its endpoint matches the target process/container network
- A mapper in `Domain` or `Application` references an API DTO, or an API mapper references an application/persistence type in a way that reverses project dependencies
- A `Common`, `Shared`, or generic mapper layer owns unrelated aggregate mappings with no stable owner
- A mapper performs validation, authorization, timestamp/default assignment, repository access, I/O, or aggregate mutation
- A controller still builds a reusable DTO inline after an aggregate mapper exists
- A controller batches/join data from multiple repositories, coordinates external ports, or makes application decisions that belong in a focused command/query handler
- An Application handler imports an API request/response DTO or returns HTTP-specific status/result types
- A concrete command/query handler is injected alongside repository dependencies in a controller that is being refactored to reduce DI
- A file containing both a command/query and its single handler is named `*Handler.cs`, obscuring the request that owns the use-case entry point
- A mediator package is added without checking target framework, transitive framework dependencies, or its license/runtime configuration
- A write handler calls `SaveChangesAsync` through multiple repositories backed by the same `DbContext`
- A check-then-insert uniqueness rule has no database constraint or no translation path for its known concurrent constraint violation
- A required controller dependency is changed to nullable to avoid updating direct controller construction in tests
- A handwritten helper duplicates a BCL, ASP.NET Core, EF Core, or `Microsoft.Extensions` capability without a documented semantic difference
- A new package is added for a framework capability without checking target-framework compatibility, existing package/framework references, or version policy
- A complex expression, external-call result, URL, payload, or mapping is returned directly when a named local would materially improve debugging or validation

## Verification

- [ ] Repository-provided verification commands ran and their actual output was observed, not assumed
- [ ] When an applicable scaffold/template exists, the touched startup/configuration files were compared against it and all mandatory lifecycle rules were preserved
- [ ] For a new service or backend startup/configuration change, the closest current service logging pattern was inspected and differences were intentional
- [ ] Structured logging has a stable service identity, environment, correlation fields, safe exception context, and the approved Console/file fallback where applicable
- [ ] Every configured centralized sink has a reachable route from the actual hosting mode, and the collector/index preserves the service identity
- [ ] Runtime logging delivery was smoke-tested when infrastructure was available; otherwise the result explicitly says configured-but-unverified
- [ ] Nullable/analyzer warnings on touched code are not suppressed or weakened merely to pass
- [ ] Before adding a helper or package, the codebase and applicable .NET/ASP.NET Core APIs were checked for an equivalent capability
- [ ] Any selected framework API or package has compatible target framework, ownership, version policy, and layer placement
- [ ] Custom utility code documents the semantic gap that prevents reuse of the existing framework capability
- [ ] Non-trivial results that need inspection, validation, logging, or debugging use clearly named local variables before being returned
- [ ] Dependency direction still points inward: `Domain` has no HTTP, persistence, or vendor SDK reference
- [ ] Every new abstraction (interface, repository, mediator) has a stated reason — protects a real boundary or has 2+ implementations
- [ ] State-changing use cases have an explicit transaction owner, concurrency behavior, and idempotency strategy
- [ ] Authorization and tenant scoping are enforced before data access, not assumed
- [ ] No secret, token, connection string, or unnecessary personal data appears in logs, telemetry, or responses
- [ ] Every mapper sits at the project boundary that owns its destination contract and does not reverse dependency direction
- [ ] Aggregate mappings use a focused `<Aggregate>Mapper` with explicit target methods; unrelated mappings are not mixed into it
- [ ] Mappers contain only pure transformation; validation, business decisions, I/O, and trusted values remain outside
- [ ] Each controller action either remains a simple transport flow or delegates its orchestration to one focused Application use case
- [ ] Application query/command results are free of HTTP DTOs, status codes, and framework response types
- [ ] A mediator was introduced only for a demonstrated operation boundary; the controller injects `ISender` and handler discovery is assembly-scanned from the composition root
- [ ] A co-located request and single handler file is named after the request (`*Query.cs` or `*Command.cs`), and request/handler splitting is justified by reuse or complexity
- [ ] Every state-changing handler has one visible commit owner; database-backed uniqueness rules retain their constraint and map known concurrent violations consistently
- [ ] Tests that exercise a mediator controller compose the actual `ISender`/handler registration, while provider-specific constraints have a real-provider integration test when material
- [ ] Direct controller tests supply every required dependency and cover the newly introduced collaboration
- [ ] For a review: findings are ranked Critical/High/Medium/Low, each with location, evidence, and remediation
