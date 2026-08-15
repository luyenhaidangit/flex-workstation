# EF Core and relational data

## Contents

- [Treat the database as a designed dependency](#treat-the-database-as-a-designed-dependency)
- [Scope DbContext correctly](#scope-dbcontext-correctly)
- [Model storage intentionally](#model-storage-intentionally)
- [Write efficient queries](#write-efficient-queries)
- [Control loading and pagination](#control-loading-and-pagination)
- [Write and update safely](#write-and-update-safely)
- [Handle transactions and concurrency](#handle-transactions-and-concurrency)
- [Manage migrations and deployment](#manage-migrations-and-deployment)
- [Protect tenant and data boundaries](#protect-tenant-and-data-boundaries)
- [Test and diagnose with real semantics](#test-and-diagnose-with-real-semantics)

## Treat the database as a designed dependency

Design schema, constraints, indexes, query shapes, and lifecycle together. Keep invariants in application/domain code and add database constraints where concurrent writers or external access could otherwise violate them.

Use EF Core directly inside a cohesive application operation when it provides the needed unit-of-work and query abstraction. Introduce a focused repository or data port for an aggregate, reusable query policy, alternate storage implementation, or boundary—not a generic CRUD wrapper around every entity.

Verify behavior against the actual provider. SQL Server, PostgreSQL, MySQL, SQLite, and in-memory substitutes differ in collation, null ordering, precision, locking, concurrency, functions, and transactions.

## Scope DbContext correctly

Treat `DbContext` as a short-lived unit of work. Use one scoped context per request/operation by default. Do not share a context concurrently across threads or keep it in singleton state.

For background jobs, messages, parallel work, or explicit units of work, create a scope or use the appropriate context factory. Dispose each context after the unit completes.

Let the composition root configure provider, connection resiliency, command timeout, logging, interceptors, and naming. Avoid `OnConfiguring` secrets and environment-specific connection strings embedded in source.

Do not call `SaveChanges` in arbitrary repositories or entity helpers when an application operation must coordinate several changes atomically. Make the transaction/commit owner visible.

## Model storage intentionally

Configure required fields, maximum lengths, Unicode behavior, decimal precision/scale, timestamps, default values, generated values, relationships, delete behavior, unique constraints, and indexes explicitly where provider conventions are insufficient.

Use database types that preserve domain semantics. Avoid floating-point types for money. Define how enums are stored and evolved. Store instants consistently as UTC or provider-appropriate offset-aware types and convert timezones only at boundaries.

Keep database-generated defaults and non-null additions migration-safe for existing rows. A CLR default, model default, and database default are different mechanisms; verify which one applies to inserts from EF Core, raw SQL, and older application versions.

Choose cascade deletes deliberately. Prevent a relationship change from deleting a large graph unexpectedly. Use soft deletion only with explicit uniqueness, retention, query, authorization, and purge semantics.

## Keep EF Core mapping outside the Domain layer

For a solution with a separate Domain project, do not place EF Core persistence metadata
on Domain entities, including `[Table]`, `[Column]`, `[ForeignKey]`, `[Index]`, or
provider-specific attributes.

Place table, schema, and column mapping; keys; relationships; indexes; conversions;
precision; database defaults; and delete behavior in
`Infrastructure/Persistence/Configurations` using `IEntityTypeConfiguration<T>`.
Apply configurations from the Infrastructure assembly through
`ModelBuilder.ApplyConfigurationsFromAssembly(...)`.

Domain entities own business state, invariants, and transitions. They must not know
table names, column names, schemas, ORM APIs, or provider-specific storage details.

Data Annotations are acceptable only when the repository has no separate Domain /
Infrastructure boundary and the local convention explicitly adopts them.

When Liquibase owns schema changes, treat the approved database migration as the
schema source of truth. EF Core configuration must match that schema; do not create
a competing EF migration chain.

## Write efficient queries

Start from the response or operation's required data. Filter, aggregate, order, and project in SQL:

```csharp
var result = await dbContext.Orders
    .AsNoTracking()
    .Where(x => x.TenantId == tenantId && x.Status == OrderStatus.Open)
    .OrderByDescending(x => x.CreatedAt)
    .Select(x => new OrderSummary(x.Id, x.Code, x.Total, x.CreatedAt))
    .Take(limit)
    .ToListAsync(cancellationToken);
```

- Use no-tracking queries for read-only results unless identity resolution is needed.
- Project only required columns rather than loading entities and mapping in memory.
- Keep filters translatable; detect unintended client evaluation or translation failure.
- Parameterize dynamic values and keep expression-tree shape stable where practical.
- Pass cancellation to async terminal operations.
- Avoid multiple round trips and N+1 access; inspect loops that execute queries.
- Verify important generated SQL, execution plans, row estimates, and indexes with realistic data.

Do not add compiled queries by default. EF already caches query shapes; use explicit compiled queries only after profiling shows query compilation is material on a high-volume stable query.

## Control loading and pagination

Prefer projection over loading a large entity graph. Avoid lazy loading in server applications unless its implicit round trips are understood and tested. Use eager or explicit loading when entities are truly required.

When multiple collection includes create cartesian growth, project a purpose-built shape or evaluate split queries. Understand the consistency and round-trip tradeoff before enabling split behavior globally.

Always define deterministic ordering for pagination. Use a unique tie-breaker. Prefer keyset/seek pagination for deep or changing lists:

```csharp
query = query.Where(x =>
    x.CreatedAt < cursor.CreatedAt ||
    (x.CreatedAt == cursor.CreatedAt && x.Id.CompareTo(cursor.Id) < 0));
```

Adapt the comparison to provider-translatable expressions and matching indexes. Bound page size and prevent callers from requesting arbitrary includes or unbounded sort expressions.

## Write and update safely

Load an entity when domain behavior, concurrency, relationships, or change tracking is needed. For a set-based operation that intentionally bypasses tracked behavior, evaluate `ExecuteUpdate`/`ExecuteDelete` or provider SQL and account for interceptors, audit logic, concurrency, and already-tracked entities.

Avoid calling `SaveChanges` inside a per-row loop. Let EF batch writes or use a verified bulk strategy for genuinely large operations. Bound batch size and measure lock duration, log growth, and memory.

Validate affected-row counts when they carry correctness meaning. Never construct raw SQL by concatenating untrusted values. Use parameterized APIs and allowlist any identifier or sort expression that cannot be parameterized.

Separate application-generated audit fields from database-generated values and define the trusted actor/time source. Do not let a client set ownership, tenant, creation user, or protected status fields directly.

## Handle transactions and concurrency

Use the smallest transaction that protects the invariant. A single `SaveChanges` is transactional for supported relational providers; add an explicit transaction when several saves or compatible operations must be atomic.

Do not keep a database transaction open across slow remote calls. Coordinate database state and external messages with an outbox or another explicit consistency pattern.

Use optimistic concurrency tokens for updates where lost writes matter. On a concurrency conflict, choose deliberately among reject, reload, merge, or retry. Retry the complete transaction only when its operations are safe and bounded.

Understand provider execution strategies before combining automatic retries with explicit transactions. Avoid nested retry layers that can repeat side effects.

Use database uniqueness and atomic conditional updates for race-sensitive invariants; an application check followed by an insert is not sufficient under concurrency.

## Manage migrations and deployment

Review generated migrations as production code. Check destructive operations, defaults, backfills, locks, index build behavior, provider SQL, and downgrade/roll-forward strategy.

Use expand-and-contract for zero/low-downtime changes:

1. Add a compatible schema shape.
2. Deploy code that tolerates old and new shapes or dual-writes when necessary.
3. Backfill in observable bounded batches.
4. Switch reads and validate.
5. Remove old code/schema in a later release.

Do not rely on every application replica racing to run migrations at startup in production. Use a controlled migration job or an explicitly coordinated deployment mechanism. Back up and rehearse high-risk migrations on production-like volume.

## Protect tenant and data boundaries

Make tenant ownership part of the schema and every relevant query for shared-table tenancy. Use composite uniqueness/indexes that include tenant identity. Apply a global query filter only as defense in depth; inspect bypasses, raw SQL, admin queries, background jobs, and writes explicitly.

For schema-per-tenant or database-per-tenant designs, manage connection selection, pooling, migrations, provisioning, deletion, backup/restore, and noisy-neighbor limits centrally. Never accept an arbitrary client connection string or database name.

Test cross-tenant denial, not only happy-path filtering. Include tenant identity in idempotency, cache, and message keys.

## Test and diagnose with real semantics

Use unit tests for pure query-specification or domain logic and integration tests against the actual relational provider for LINQ translation, constraints, transactions, migrations, collation, and concurrency. Do not treat EF's in-memory provider as proof of relational behavior.

During diagnosis:

- correlate slow operations with command duration and request traces;
- inspect generated SQL without logging sensitive parameter values;
- reproduce with realistic cardinality and distribution;
- inspect database execution plans and wait/lock evidence;
- measure before and after the smallest plausible change.

Avoid globally enabling sensitive-data logging in production.

## Official anchors

Use current EF Core guidance for [efficient querying](https://learn.microsoft.com/ef/core/performance/efficient-querying), [performance diagnosis](https://learn.microsoft.com/ef/core/performance/performance-diagnosis), and [efficient updating](https://learn.microsoft.com/ef/core/performance/efficient-updating). Verify provider- and version-specific capabilities before applying them.
