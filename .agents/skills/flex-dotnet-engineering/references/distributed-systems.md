# Distributed systems, messaging, jobs, and multi-tenancy

## Contents

- [Make distribution earn its cost](#make-distribution-earn-its-cost)
- [Choose synchronous or asynchronous collaboration](#choose-synchronous-or-asynchronous-collaboration)
- [Design message contracts](#design-message-contracts)
- [Assume at-least-once delivery](#assume-at-least-once-delivery)
- [Coordinate state with outbox and inbox](#coordinate-state-with-outbox-and-inbox)
- [Model long-running workflows](#model-long-running-workflows)
- [Handle ordering locking and time](#handle-ordering-locking-and-time)
- [Run jobs and consumers safely](#run-jobs-and-consumers-safely)
- [Design tenant isolation end to end](#design-tenant-isolation-end-to-end)
- [Secure and observe service communication](#secure-and-observe-service-communication)
- [Test failure behavior](#test-failure-behavior)

## Make distribution earn its cost

Keep a capability in-process unless it needs an independent deployment, owner, scale profile, data boundary, security boundary, availability target, or technology constraint. Treat network calls as slower, fallible, duplicated, reordered, and independently versioned.

Do not preserve a monolith's chatty object graph across services. Move behavior and owned data behind a coarse capability contract. Avoid a shared database that lets services bypass ownership unless the system explicitly accepts that coupling as an interim state.

Define responsibility for availability, schema evolution, on-call, capacity, recovery, and cost before extracting a service.

## Choose synchronous or asynchronous collaboration

Use a synchronous call when the caller needs an immediate answer to complete the user operation and the dependency fits the latency/availability budget. Use asynchronous messaging when the caller can acknowledge durable intent, consumers need independent availability or fan-out, or smoothing bursts matters.

Do not use asynchronous messaging merely to hide a synchronous dependency that the response still waits for. Do not use request/response for side effects that can safely complete later and would make the user request fragile.

For each cross-boundary interaction, define:

- owner and contract;
- deadline and retry behavior;
- idempotency and deduplication;
- ordering and consistency expectations;
- authentication/authorization;
- version compatibility;
- telemetry and support ownership.

## Design message contracts

Publish business facts in past tense, such as `OrderSubmitted`, and commands as explicit requested actions, such as `ReserveInventory`. Keep integration contracts independent from internal EF entities or domain object graphs.

Include a stable message identifier, contract type/version, occurred time, correlation/causation identifiers, trusted tenant context when applicable, and the minimum payload consumers need. Define whether time means event occurrence, persistence, or publication.

Prefer additive evolution. Keep old consumers working during rollout. Never repurpose an existing field with different semantics. Use a new version only when compatibility cannot be preserved, and define the migration/deprecation window.

Keep sensitive data out of events unless every topic/subscriber/retention path is authorized for it. Avoid placing secrets or raw access tokens in messages.

## Assume at-least-once delivery

Assume a consumer can receive the same message more than once, after a delay, and sometimes out of order. Design the handler so repeating it produces the same valid state or is rejected as already applied.

Use one or more of:

- an inbox/deduplication record with a uniqueness constraint;
- a domain operation keyed by a stable business/idempotency key;
- an atomic conditional update;
- naturally idempotent upsert semantics;
- a state-machine transition that rejects repeats.

Do not mark a message complete before its durable effects commit. Do not assume broker “exactly once” settings cover external databases, HTTP calls, emails, or other side effects.

Classify failures. Retry transient dependency failures with bounds; dead-letter or quarantine poison data with enough safe context for remediation. Make replay an owned, auditable operation.

## Coordinate state with outbox and inbox

Use a transactional outbox when a database state change and an integration message must not diverge. Write the business change and outbox record in one local transaction, then publish asynchronously. Record publication attempts and make dispatch idempotent.

Use an inbox or equivalent unique processing record when a consumer's database effect must be deduplicated. Commit the inbox marker and business changes atomically when possible.

Monitor unpublished outbox age/count, dispatch failures, duplicate rate, inbox growth, and cleanup. Retain enough history for retry/reconciliation without allowing tables to grow unbounded.

Avoid wrapping a database and broker in a distributed transaction unless the entire platform explicitly supports and operates it; prefer local atomicity plus idempotent eventual delivery.

## Model long-running workflows

Use a saga/process manager for workflows that span independent transactions and require remembered state, timeouts, retries, or compensation. Make each step and transition explicit and idempotent.

Compensation is a business operation, not a technical rollback. Define what can be reversed, what needs manual repair, and what remains as audit history. Persist workflow state before sending the next durable command.

Expose “pending” or eventual state honestly to callers. Do not claim completion while critical asynchronous steps remain unknown.

Add reconciliation for cross-system facts that matter financially, operationally, or for access control. Alerts should detect stuck workflow age, not only message exceptions.

## Handle ordering locking and time

Require ordering only where a business invariant needs it. Partition ordered streams by the narrowest key, such as aggregate or tenant/entity identity, because global ordering limits throughput and availability.

Use optimistic concurrency and state-version checks before distributed locks. If a distributed lock is unavoidable, define lease expiry, renewal, ownership, failure during pause, and a fencing token so an expired owner cannot continue writing.

Do not use clock time alone to order distributed events. Use sequence/version numbers within an owned stream. Store instants as UTC/offset-aware values and tolerate skew when evaluating expiry. Use monotonic elapsed-time sources for in-process durations.

Choose identifiers that meet uniqueness, ordering, privacy, and database-index needs. Do not expose sequential identifiers when they leak sensitive volume or enable enumeration without authorization.

## Run jobs and consumers safely

Persist jobs that must survive process restart. Define a stable job identity and idempotency key. Use leases/visibility timeouts and renew them for long work. Expect another worker to acquire abandoned work.

Bound batch size, concurrency, prefetch, memory, and downstream calls. Create a DI scope per job/message. Propagate cancellation and stop taking new work during graceful shutdown while finishing or safely abandoning owned work.

For scheduled jobs in a multi-replica service, use one of:

- an external scheduler that emits one durable job;
- a broker/queue with deduplication;
- a database lease with fencing/atomic acquisition;
- an idempotent job that safely tolerates multiple starts.

Do not depend on an in-memory timer for business-critical once-only execution.

## Design tenant isolation end to end

Choose a tenancy model deliberately:

- **Shared tables** reduce operational overhead but require tenant keys, composite constraints/indexes, query/write enforcement, and strong negative tests.
- **Schema per tenant** improves logical isolation but complicates pooling, migrations, tooling, and schema count.
- **Database per tenant** improves isolation, restore, and placement but increases provisioning, connection, migration, and fleet-management cost.
- **Hybrid** tiers tenants by scale/compliance but requires routing and movement mechanisms.

Resolve tenant identity from a trusted source and compare any route/header/body tenant value rather than trusting it independently. Propagate the verified identity to database selection/filtering, cache keys, idempotency keys, object storage paths, message envelopes, jobs, rate limits, and audit events.

Prevent ambient tenant leakage:

- never store tenant context in static mutable state;
- clear pooled/reused context correctly;
- avoid cache keys without tenant scope;
- validate background jobs carry an authorized tenant identity;
- apply admin/cross-tenant access through explicit privileged paths;
- test parallel requests for different tenants.

Plan tenant provisioning, suspension, deletion, export, migration, backup, point-in-time restore, key rotation, noisy-neighbor quotas, and region/data-residency requirements. Make control-plane actions auditable and idempotent.

## Secure and observe service communication

Give each service/workload an identity. Authenticate and authorize service-to-service calls for the specific capability and tenant scope; a private network alone is insufficient authorization.

Propagate trace context, correlation, and safe tenant context across HTTP and messages. Create a new processing span for each consumer attempt while retaining causation. Do not place secrets or high-cardinality identifiers in metrics.

Measure dependency latency/errors, retry attempts, circuit state, queue depth/age, handler duration, duplicates, dead letters, outbox lag, workflow age, and tenant saturation. Use a consistent operation and contract name so a request can be followed across boundaries.

## Test failure behavior

Test more than the happy path:

- duplicate and out-of-order messages;
- crash before and after commit/acknowledgment;
- timeout after a dependency completed but before the response arrived;
- partial dependency outage and retry amplification;
- poison messages and dead-letter replay;
- lease expiry and concurrent workers;
- rolling contract deployment with old/new versions;
- cross-tenant attempts and context leakage;
- broker/cache/database restart and recovery;
- reconciliation of intentionally inconsistent states.

Use real broker/database semantics for critical integration tests where an in-memory fake would hide acknowledgment, transaction, serialization, or concurrency behavior.

## Official anchors

Use Microsoft's [.NET microservices architecture guidance](https://learn.microsoft.com/dotnet/architecture/microservices/) as a pattern catalog, not a mandate to split services. Validate broker, database, and hosting behavior against the actual platform.
