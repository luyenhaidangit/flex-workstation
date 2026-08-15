# Architecture and boundaries

## Contents

- [Start from system forces](#start-from-system-forces)
- [Choose a deployment shape](#choose-a-deployment-shape)
- [Organize by business capability](#organize-by-business-capability)
- [Isolate module data ownership](#isolate-module-data-ownership)
- [Design in-process module contracts](#design-in-process-module-contracts)
- [Define dependency boundaries](#define-dependency-boundaries)
- [Apply Clean Architecture proportionately](#apply-clean-architecture-proportionately)
- [Assign layer ownership](#assign-layer-ownership)
- [Build a vertical slice](#build-a-vertical-slice)
- [Design state changes and external effects](#design-state-changes-and-external-effects)
- [Choose domain-model depth](#choose-domain-model-depth)
- [Design projects and assemblies](#design-projects-and-assemblies)
- [Use dependency injection deliberately](#use-dependency-injection-deliberately)
- [Handle configuration and startup](#handle-configuration-and-startup)
- [Evolve architecture safely](#evolve-architecture-safely)
- [Use this decision checklist](#use-this-decision-checklist)

## Start from system forces

Document the forces that affect the design before choosing a named architecture:

- business capabilities and invariants;
- team ownership and release cadence;
- expected traffic, latency, data volume, and growth;
- availability, recovery, compliance, and isolation requirements;
- external integrations and failure modes;
- current operational maturity and cost constraints.

Prefer a design that makes the common change easy and the dangerous change explicit. Optimize for cohesive ownership and low coupling, not for the largest possible number of layers.

## Choose a deployment shape

Use this default order:

1. Use a single deployable for a small application with limited domain complexity.
2. Use a modular monolith when several business capabilities need strong internal boundaries but can share a release and runtime.
3. Extract a service only when a boundary needs independent ownership, deployment, scaling, technology, isolation, or availability.

Require concrete evidence before choosing microservices. Account for network failure, contract evolution, duplicated operational tooling, distributed transactions, eventual consistency, observability, and on-call ownership.

Keep a modular monolith extraction-ready by enforcing module APIs and data ownership; do not simulate a distributed system inside one process with unnecessary serialization or brokers.

## Organize by business capability

Prefer feature or module cohesion over one global folder per technical type.

**Single service (small or medium domain area).** Place feature folders inside the Api project; do not add an Application project until orchestration justifies it:

```text
src/
  Product.Api/
    Features/
      Orders/
        CreateOrder/
          CreateOrderRequest.cs
          CreateOrderValidator.cs
          CreateOrderHandler.cs
        GetOrder/
        CancelOrder/
      Invoices/
    Middleware/
    Program.cs
  Product.Domain/
  Product.Infrastructure/
tests/
  Product.UnitTests/
  Product.IntegrationTests/
```

**Modular monolith (several distinct business capabilities in one deployment).** Use a per-module layout:

```text
src/
  Product.Api/
  Product.Modules.Orders/
    CreateOrder/
    GetOrder/
    Domain/
    Infrastructure/
  Product.Modules.Billing/
  Product.SharedKernel/       # only proven, stable shared concepts
tests/
  Product.Modules.Orders.Tests/
  Product.IntegrationTests/
```

Co-locate an operation's request, validation, handler/use case, mapping, and tests when doing so improves discoverability. Keep module internals inaccessible to other modules where practical.

Avoid a large `Shared`, `Common`, or `Core` assembly that becomes an unowned dependency hub. Share only stable primitives or contracts with clear ownership.

## Organize the Domain by aggregate

When a Domain project contains more than a few related types, organize it by
aggregate or business module rather than by technical type alone. Keep an
aggregate root, its statuses, value objects, domain events, policies, and
aggregate-local classifications together.

```text
Domain/
  Agents/
    Agent.cs
    AgentStatus.cs
    AgentPublishLocation.cs
  Conversations/
    Conversation.cs
    ConversationStatus.cs
    Message.cs
    MessageClassification.cs
  Shared/
    # Only concepts with the same meaning across two or more modules
```

Do not create global `Entities/`, `Enums/`, or `ValueObjects/` folders that
become long flat catalogs when the system has multiple aggregates. A type belongs
in `Shared/` only when it has one stable business meaning across modules; do not
move a type there merely to avoid duplication.

For a small domain with only a few types, a flat layout is acceptable. Introduce
module folders when the aggregate has supporting types or when navigation across
type-based folders slows down feature work.

Keep namespaces aligned with the module by default, for example
`Flex.Agent.Domain.Agents` and `Flex.Agent.Domain.Conversations`. Preserve an
existing public namespace only when changing it would create unnecessary
compatibility impact.

Migrate an existing flat Domain incrementally: move one aggregate in a focused
change, update references and tests, verify the build, and avoid a broad
folder-only reorganization during parallel feature work.

## Isolate module data ownership

Give each module in a modular monolith its own schema (or database) and forbid another module from joining, querying, or holding a foreign key across that boundary. Access another module's data only through its published contract, never through a direct table or `DbContext` reference.

This keeps the schema boundary honest while the system is still one deployment, and turns a later split into a per-service database into a schema move, not a data-model redesign.

## Design in-process module contracts

When modules communicate inside a modular monolith, prefer an in-process contract over a message broker or HTTP call:

- Define the contract as interfaces and DTOs in a dedicated contracts project (for example `Product.Modules.Orders.Contracts`) referenced by every module that calls it; never let a module reference another module's internal namespaces directly.
- Implement the interface inside the owning module and register it in the composition root; the caller resolves it through DI like any other service.
- Keep contract DTOs independent of persistence and domain types so the owning module can change its internal model without breaking callers.
- Extracting a module into its own service later becomes swapping the DI registration for an HTTP/gRPC client behind the same interface, not a rewrite of calling code.
- Reserve a broker or queue for genuinely asynchronous, at-least-once cross-boundary effects (see `distributed-systems.md`); do not add one merely to decouple two modules that only need a synchronous call.

## Define dependency boundaries

Make dependency direction reflect policy ownership:

- Keep domain rules independent of HTTP, EF Core, queues, and vendor SDKs when the domain has meaningful behavior.
- Keep application operations responsible for orchestration, authorization decisions, transactions, and ports to infrastructure.
- Keep infrastructure responsible for database, messaging, files, clocks, and remote providers.
- Keep the composition root responsible for selecting implementations and lifetimes.

Let an outer layer depend on an inner policy layer; do not let inner policy import transport or persistence details. Define an interface at the boundary owned by the caller when that interface protects a volatile or external dependency.

Do not add an interface to every class. Keep pure, stable collaborators concrete when substitution has no value.

**When to add an Application project.** The default starting point is `Api + Domain + Infrastructure`. Introduce `Product.Application` as a separate project when two or more of these appear:

- Use cases involve multi-step workflows or non-trivial orchestration.
- Business authorization rules need enforcement across multiple transports (Api + Worker).
- Domain or integration event handling requires coordination outside a single handler.
- The same use case is consumed from both an API endpoint and a background worker.
- Business logic is accumulating inside controllers or large service classes.

**Controller → Service → Repository is not automatically Clean Architecture.** That stack is Layered Architecture. It aligns with Clean Architecture principles only when business rules do not import ASP.NET Core or EF Core types, interfaces are owned by the caller rather than the implementer, controllers handle only HTTP concerns, and service classes are not growing into a single class per entity. In a Vertical Slice layout, many requests can flow `Endpoint → Handler → Domain + DbContext` without a dedicated service or repository layer when those layers provide no real boundary.

## Apply Clean Architecture proportionately

Treat Clean Architecture as a dependency and responsibility discipline, not a mandatory project template. Start with the smallest shape that protects the important business policy:

- Use feature folders and a thin API layer for straightforward CRUD with few invariants.
- Add an application boundary when use-case orchestration, authorization, transactions, or infrastructure ports need a stable home.
- Add a domain boundary when rules, value concepts, state transitions, or aggregate invariants would otherwise be duplicated across handlers.
- Add separate assemblies only when compile-time dependency rules, reuse, deployment, or ownership justify them.

For a system where all boundaries are useful, use this reference graph:

```text
Domain          → no production-project references
Application     → Domain
Infrastructure  → Application and Domain as needed to implement ports
Api / Worker    → Application and Infrastructure; composition root
```

The runtime call may travel from an application use case to an infrastructure adapter through an application-owned interface. That does not reverse the source dependency: the adapter references the port, while the policy remains independent of its implementation.

Do not infer that CQRS, MediatR, generic repositories, domain events, Outbox, or microservices are required by this graph. Introduce each only when it resolves an identified change, consistency, reliability, or ownership problem.

## Assign layer ownership

Make layer ownership explicit before implementation:

| Layer | Own | Must not own |
| --- | --- | --- |
| Domain | Entities, value objects, invariants, state transitions, pure domain services, domain errors/events | HTTP, ORM mapping, SQL, queues, email, vendor SDKs, configuration |
| Application | Commands/queries or use cases, orchestration, resource authorization, transaction boundary, ports, expected business outcomes | Controller logic, HTTP status codes, provider-specific persistence or transport types |
| Infrastructure | EF Core/database, migrations, repositories/adapters, HTTP clients, broker/cache/file/email providers, delivery mechanisms | Business policy that belongs to the domain or a use case |
| Presentation | Routing, binding, public DTOs, authentication context, endpoint authorization, protocol response mapping | SQL, aggregate mutation through public setters, provider-specific workflow logic |
| Host | DI registration, middleware, configuration, logging/telemetry setup, process lifecycle | Business decisions or service-locator access |

Keep public transport contracts, persistence entities, and domain types separate. Map at the boundary that owns each contract. Do not let a client supply trusted fields such as actor, tenant, price, ownership, or privilege; derive them from validated server-side context and authoritative data.

Use explicit outcomes for expected business alternatives such as invalid state, conflict, or not found. Map those outcomes at the presentation boundary. Use exceptions for unexpected infrastructure failures, programmer errors, and failures that cannot be handled as ordinary business flow. Keep requested cancellation separate from server failure.

## Build a vertical slice

Implement a complete thin use case before generalizing an architecture. For a state-changing HTTP API operation, use this sequence:

1. Define the actor, trusted tenant context, input, expected outcomes, authorization rule, state change, transaction scope, and side effects.
2. Define a public request/response DTO and validate untrusted shape, ranges, formats, and cross-field constraints at the boundary.
3. Map the request and trusted context to an application command or use-case input.
4. Load only the state needed by the use case; authorize resource/tenant access before returning or changing protected data.
5. Invoke aggregate behavior or a pure domain service to enforce invariants and transition state.
6. Persist all local changes in a visible unit of work. Enforce race-sensitive invariants with database constraints, optimistic concurrency, or atomic conditional updates.
7. Return an application outcome and map it consistently to the protocol, usually a success response or Problem Details.
8. Test the domain rule, the use-case orchestration, and the real boundary that mocks cannot prove.

Keep endpoint code limited to transport concerns: bind, authenticate/authorize, map, invoke, and translate. Keep the application operation focused on one use case. Do not move a coherent rule into a generic helper simply because it is shared twice; first establish its owner.

Use commands and queries when the distinction makes intent, validation, optimization, or ownership clearer. A query may project directly to a response shape; it does not need to hydrate an aggregate. A mediator is optional: use it only if its pipeline policies or module boundary provide value beyond a direct service call.

## Design state changes and external effects

Make the complete write path explicit:

```text
trusted request context
  → application authorization and orchestration
  → domain invariant and state transition
  → local transaction and durable state
  → application outcome
  → asynchronous external effect when required
```

Keep database transactions short and never hold one open across a slow remote call. Treat a check-then-insert sequence as unsafe under concurrent writers unless the database also enforces the invariant.

Use a transactional Outbox when a local database change and an integration message must not diverge. Write the business change and outbox record atomically, then dispatch asynchronously. Assume at-least-once delivery: give messages stable identities, make consumers idempotent, classify retries, retain failure evidence, and monitor dispatch age and failures. Use an inbox or a uniqueness-backed idempotency strategy when a consumer's durable effect must not repeat.

Distinguish a domain event from an integration event. A domain event records a business fact inside a model; an integration event is a deliberately versioned contract for another module or service. Do not publish EF entities or internal object graphs as external contracts. Use a saga/process manager only for long-running cross-transaction workflows that require remembered state, timeout, or business compensation.

For durable background work, persist or enqueue work before acknowledging success. Create a DI scope per job/message or bounded batch, honor cancellation, bound concurrency and prefetch, and make shutdown/retry/dead-letter behavior visible. Do not use fire-and-forget work from an HTTP request or an in-memory timer for business-critical once-only execution.

## Choose domain-model depth

Use transaction-script or feature-handler code for straightforward CRUD and orchestration. Use richer entities, value objects, aggregates, domain services, or domain events only where they encode real invariants and reduce duplicated business logic.

For a rich model:

- Prevent invalid state through constructors/factories and behavior methods.
- Keep aggregate boundaries small and aligned with transaction boundaries.
- Reference other aggregates by identity instead of loading a giant object graph.
- Distinguish a domain event that records a business fact from an integration event sent to another boundary.
- Dispatch external effects only after durable state and delivery semantics are designed.

Avoid an anemic model only when business behavior truly belongs in the model; do not force domain objects around simple data maintenance.

## Design projects and assemblies

Create a project boundary when it enforces a dependency rule, has distinct deployment/runtime needs, or is independently reusable. Use namespaces and folders when compile-time isolation adds little value.

For solution-wide settings, centralize compatible defaults in `Directory.Build.props`, package versions in `Directory.Packages.props`, and repository style in `.editorconfig`. Preserve deliberate per-project exceptions.

Keep public surface area small. Mark implementation types `internal` when consumers do not need them. Treat public libraries as compatibility contracts: review binary/source compatibility, nullable annotations, serialization, and behavioral changes before release.

Avoid project cycles, feature-to-feature database shortcuts, and references that bypass a module's owned API.

## Use dependency injection deliberately

Register services near their owning module through explicit extension methods. Keep the composition root readable and avoid service-locator access.

Match lifetime to state and dependencies:

- Use singleton only for thread-safe, process-wide state with no scoped dependency.
- Use scoped for request/unit-of-work state such as an EF Core `DbContext`.
- Use transient for lightweight stateless services where creation cost is acceptable.

Never capture a scoped service in a singleton. Create an explicit scope inside a background worker for each independent unit of work. Avoid building a second service provider during registration.

Keep constructors small enough to reveal cohesion problems. Do not hide a large dependency set behind an aggregate service merely to reduce parameter count.

## Handle configuration and startup

Bind cohesive settings to options types. Validate required configuration at startup and fail fast for invalid settings that make the process unsafe or unusable. Avoid injecting raw `IConfiguration` throughout business code.

Separate:

- non-secret deploy-time configuration;
- secrets obtained from an approved secret provider;
- dynamic business settings that need ownership, validation, audit, and caching.

Keep startup deterministic and bounded. Avoid network calls or data migrations that can block every replica indefinitely. Make initialization idempotent and observable if it must happen at startup.

## Evolve architecture safely

Use characterization tests around behavior before a large refactor. Move one feature or boundary at a time, preserve contracts, and keep deployable checkpoints. Use an anti-corruption layer when replacing a legacy or vendor model incrementally.

Record a meaningful architecture decision when it changes system-wide constraints, especially deployment shape, data ownership, integration style, tenancy, or security. Capture context, decision, alternatives, consequences, and revisit conditions; do not create an ADR for routine coding choices.

## Use this decision checklist

Before accepting the design, verify:

- Does each boundary have a named owner and purpose?
- Can the common feature change stay mostly inside one module?
- Are business rules testable without transport and vendor infrastructure?
- Are transaction and consistency boundaries explicit?
- Are cross-boundary contracts smaller and more stable than internal models?
- Does every abstraction remove a real dependency or variation?
- Can the system be deployed, observed, and recovered with current team capability?
- Is the design simpler than the problem, rather than more impressive than it?

## Official anchors

Use Microsoft's [.NET architectural principles](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/architectural-principles) and [common web application architectures](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures) as conceptual anchors, then adapt them to the repository and system forces.
