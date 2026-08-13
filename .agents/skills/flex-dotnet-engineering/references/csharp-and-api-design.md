# C# and in-process API design

## Contents

- [Optimize for readable contracts](#optimize-for-readable-contracts)
- [Use precise names and types](#use-precise-names-and-types)
- [Model nullability and state](#model-nullability-and-state)
- [Design methods and public APIs](#design-methods-and-public-apis)
- [Handle errors consistently](#handle-errors-consistently)
- [Use async and cancellation correctly](#use-async-and-cancellation-correctly)
- [Manage resources and concurrency](#manage-resources-and-concurrency)
- [Keep mapping and serialization explicit](#keep-mapping-and-serialization-explicit)
- [Automate style and analysis](#automate-style-and-analysis)
- [Review common hazards](#review-common-hazards)

## Optimize for readable contracts

Write code for the next maintainer. Prefer a direct implementation with explicit behavior over clever generic machinery. Keep methods cohesive and extract code when the extracted concept has a meaningful name, independent rule, or reusable policy—not only because a line-count threshold was reached.

Make invalid and expensive operations visible in APIs. Keep side effects out of getters, mapping, constructors, and implicit conversions.

## Use precise names and types

Follow the repository's style and standard .NET naming:

- Use PascalCase for types and public members, camelCase for parameters and locals, and the established private-field convention.
- Prefix interfaces with `I` where that matches .NET conventions.
- Suffix asynchronous methods with `Async` unless an established framework contract dictates otherwise.
- Name methods with verbs and values/properties with nouns or affirmative predicates such as `IsActive`, `CanPublish`, or `HasAccess`.
- Replace ambiguous names such as `data`, `item`, `process`, `manager`, and `helper` with domain intent.

Use a type that carries meaning:

- Use enums or dedicated option types instead of several Boolean parameters.
- Use immutable value objects for important validated concepts such as money, tenant identity, or date range when primitive confusion is credible.
- Prefer `IReadOnlyCollection<T>` or `IEnumerable<T>` for read-only consumption; do not expose a mutable collection accidentally.
- Return a concrete collection when materialization and ownership are part of the contract.
- Use records for value-like data and messages; do not assume a mutable entity is a value merely because records are concise.

## Model nullability and state

Enable nullable reference analysis for new code and treat annotations as contract. Use `?` only when absence is meaningful. Validate external input before applying the null-forgiving operator; do not scatter `!` to silence uncertainty.

Initialize objects into valid states. Prefer constructors or named factories for required invariants. Use `required` members only when the target framework, serializers, ORMs, and callers handle them correctly.

Distinguish:

- not found;
- unavailable or unauthorized;
- invalid input;
- a value that is legitimately absent.

Do not encode all four as `null` when callers need different behavior.

## Design methods and public APIs

Keep parameters cohesive. Introduce a request/options type when parameters form a concept or evolve together. Avoid long parameter lists, optional Boolean switches, and methods whose name hides several unrelated operations.

Prefer command/query clarity: make a method either change state or return data unless an atomic operation naturally needs both. Document important side effects, idempotency, ordering, thread safety, and ownership.

For reusable libraries:

- Keep the public API minimal and stable.
- Accept the least-derived useful input type.
- Avoid returning internal mutable state.
- Preserve source and binary compatibility where required.
- Use XML documentation on public contracts when the repository publishes API docs or consumers need semantics not expressed by types.

Do not introduce `dynamic`, reflection, expression compilation, unsafe code, or source-generation complexity without a concrete interoperability or performance need.

## Handle errors consistently

Use exceptions for unexpected or exceptional failures. Use explicit result/union-style outcomes for expected business alternatives when callers must branch on them. Avoid both exception-driven normal flow and a universal `Result<T>` wrapper that obscures programming or infrastructure failures.

Throw the most specific standard exception for programmer contract violations. Preserve the original exception as `InnerException` when translating infrastructure errors. Never catch `Exception` only to log and rethrow; centralized boundary logging should normally record an unhandled failure once.

Do not expose stack traces or internal exception messages across process boundaries. Keep cancellation distinct from failure, and do not convert `OperationCanceledException` caused by the requested cancellation into a server error.

## Use async and cancellation correctly

Keep asynchronous I/O async through the call chain:

```csharp
public async Task<Order?> GetOrderAsync(
    OrderId orderId,
    CancellationToken cancellationToken)
{
    return await dbContext.Orders
        .AsNoTracking()
        .SingleOrDefaultAsync(x => x.Id == orderId, cancellationToken);
}
```

- Pass the token to every cancellable downstream operation.
- Put `CancellationToken` last and default it only on an appropriate public boundary.
- Avoid `.Result`, `.Wait()`, sync-over-async, and blocking I/O on request or worker threads.
- Use `async void` only for required event-handler signatures.
- Await owned tasks; route durable background work to a managed queue or hosted service.
- Use `Task.WhenAll` only when operations are independent and concurrency is bounded by downstream capacity.
- Use `IAsyncEnumerable<T>` for true asynchronous streaming and pass cancellation explicitly.

Return `Task` by default. Use `ValueTask` only after measurement shows a high-rate synchronous-completion path and the additional consumption rules are acceptable. Apply `ConfigureAwait(false)` consistently in reusable libraries if library policy requires it; do not sprinkle it through ASP.NET Core code without purpose.

## Manage resources and concurrency

Dispose resources according to ownership. Use `await using` for asynchronous disposal. Do not dispose DI-owned services, shared `HttpClient` instances, or objects whose lifecycle belongs to another component.

Prefer immutable or request-local state. Make singleton state thread-safe. Use `lock` for short synchronous critical sections and `SemaphoreSlim` or an appropriate async primitive for asynchronous coordination; never `await` while holding a monitor lock.

Bound channels, queues, parallel loops, and fan-out. Define overload behavior: wait, reject, shed, or persist. Use concurrent collections only when their atomic operations match the complete invariant; compound check-then-act logic may still need coordination.

Use `TimeProvider` for behavior affected by current time. Store instants in UTC or as `DateTimeOffset`; define timezone conversion at system boundaries. Use cryptographically secure randomness for secrets and tokens.

## Keep mapping and serialization explicit

Separate public transport contracts from persistence entities and internal domain types. Map at the boundary that owns the contract. Use manual mapping when it is short or behavior-sensitive; use a mapping tool only when its configuration is validated and discoverable.

Treat serialized names, enum values, required fields, precision, and date formats as compatibility contracts. Add contract tests before changing them. Do not accept polymorphic or type-name-based deserialization from untrusted input without a strict allowlist.

## Automate style and analysis

Use `.editorconfig`, SDK analyzers, nullable analysis, and repository build properties as executable conventions. Add analyzers incrementally and configure severity intentionally. Prefer fixing a warning or scoping a documented suppression over disabling a rule globally.

Use centralized build/package files when a solution has several projects, but avoid changing unrelated project behavior during a focused feature. Pin SDK selection when reproducibility requires it and keep dependencies within supported, patched versions.

## Review common hazards

Check for:

- hidden multiple enumeration or deferred execution after a resource is disposed;
- culture-sensitive parsing/comparison where protocols require invariant behavior;
- case conversion used as a substitute for an explicit string comparison;
- incorrect equality or hash-code semantics on value-like types;
- mutable data used as dictionary keys;
- closure capture in loops or high-allocation hot paths;
- fire-and-forget tasks and swallowed exceptions;
- unbounded recursion, queues, caches, or parallelism;
- static mutable state that leaks across tests, requests, users, or tenants;
- `DateTime.Now`, random GUID ordering, or local timezone assumptions in distributed logic;
- public API changes hidden inside a refactor.

## Official anchors

Use Microsoft's [Framework Design Guidelines](https://learn.microsoft.com/dotnet/standard/design-guidelines/) for public API consistency and the current [C# documentation](https://learn.microsoft.com/dotnet/csharp/) for language behavior. Verify guidance that depends on the repository's language and runtime version.
