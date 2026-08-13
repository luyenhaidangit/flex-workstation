# Performance and resilience

## Contents

- [Define the target before optimizing](#define-the-target-before-optimizing)
- [Measure the complete path](#measure-the-complete-path)
- [Protect asynchronous throughput](#protect-asynchronous-throughput)
- [Reduce allocation only where it matters](#reduce-allocation-only-where-it-matters)
- [Make data access efficient](#make-data-access-efficient)
- [Design caches as data systems](#design-caches-as-data-systems)
- [Apply resilience by failure mode](#apply-resilience-by-failure-mode)
- [Bound work and apply backpressure](#bound-work-and-apply-backpressure)
- [Validate under realistic load](#validate-under-realistic-load)
- [Use the production checklist](#use-the-production-checklist)

## Define the target before optimizing

Translate “fast” into a workload and objective:

- request or message type;
- throughput and concurrency;
- payload/data size and distribution;
- p50, p95, and p99 latency;
- error and timeout rate;
- CPU, memory, connection, and cost budget;
- cold-start, steady-state, and burst behavior.

Capture a baseline before changing code. Optimize the dominant end-to-end constraint, not the most interesting line of C#. Prefer removing I/O, round trips, or unnecessary work before micro-optimizing instructions.

Preserve correctness. A faster result with stale, cross-tenant, incomplete, reordered, or duplicated data is not an optimization unless those semantics are explicitly accepted.

## Measure the complete path

Use production telemetry and a reproducible test to locate the bottleneck. Correlate request traces with database, cache, HTTP, messaging, GC, CPU, thread-pool, and connection-pool evidence.

Select tools by question:

- Use metrics and distributed traces to find slow stages and saturation.
- Use `dotnet-counters` for live runtime, GC, exception, and thread-pool signals.
- Use `dotnet-trace`, PerfView, or an approved profiler for CPU, allocation, contention, and async stacks.
- Use dumps for leaks, deadlocks, and retained object graphs.
- Use database plans and wait/lock data for query latency.
- Use BenchmarkDotNet for isolated, stable hot-path microbenchmarks—not as a substitute for end-to-end load.

Warm up where steady-state matters, separate cold start, run optimized builds, use representative data, and compare distributions rather than a single average. Record the environment and confidence limits when results drive a significant decision.

## Protect asynchronous throughput

Keep network, disk, database, and stream I/O asynchronous. Avoid `.Result`, `.Wait()`, blocking locks around I/O, and synchronous request-body/response-body access. Do not use `Task.Run` to disguise blocking server work.

Bound concurrency to downstream capacity. More tasks can increase queueing, timeouts, context switching, memory, and connection starvation. Size database and HTTP connection pools together with application concurrency and replica count.

Watch for thread-pool starvation: rising queue length, delayed timers, low CPU with high latency, and bursts of thread injection. Fix blocking or unbounded work before adjusting thread-pool settings.

Use streaming only when it reduces buffering and both producer and consumer support backpressure. Define behavior for partial response or mid-stream failure.

## Reduce allocation only where it matters

First remove needless materialization, duplicate serialization, large intermediate object graphs, and repeated parsing. Keep large payloads off the Large Object Heap when practical by streaming or bounding size.

Use pooling, `ArrayPool<T>`, `Span<T>`, `Memory<T>`, structs, source-generated serializers, or reusable buffers only in measured hot paths with clear ownership. Always return rented buffers and prevent pooled sensitive data from leaking.

Do not cache or pool objects that retain request, tenant, or mutable state accidentally. Avoid mutable structs and large structs. Prefer clarity when the allocation rate is immaterial.

Investigate memory growth as retained ownership, not only allocation rate. Look for unbounded dictionaries/caches, event subscriptions, timers, channels, static references, undisposed resources, and tasks that never complete.

## Make data access efficient

Treat remote and database round trips as the primary budget. Project required fields, batch compatible work, eliminate N+1 access, index actual filters/orderings, and bound result sets. Inspect the generated SQL and plan for high-volume queries.

Avoid parallel database queries on one EF Core context. Do not fan out queries beyond the pool or database's ability to serve them. Prefer one well-shaped query over several small queries when it does not create a cartesian explosion or unacceptable lock/consistency behavior.

Use set-based updates for large data changes when domain and audit semantics permit. Keep transactions short. Monitor lock waits, deadlocks, connection acquisition, command timeouts, rows read versus returned, and replica lag where applicable.

## Design caches as data systems

Before adding a cache, define:

- owner and source of truth;
- key schema including tenant/user/authorization variation;
- value size and serialization format;
- freshness and consistency tolerance;
- TTL, size limit, eviction, and invalidation;
- miss, partial outage, and stale-data behavior;
- stampede protection and observability.

Use in-memory caching for instance-local, bounded data where inconsistency across replicas is acceptable. Use a distributed cache when sharing is required, but account for its own latency and failure modes.

Do not cache authorization decisions or sensitive data without correct identity/tenant scope and revocation semantics. Avoid unbounded user-controlled keys. Add jitter to expirations when synchronized expiry could overload the source. Consider single-flight/coalescing for expensive popular misses.

Measure hit rate, miss latency, eviction, value size, errors, and source load. Remove a cache that adds complexity without improving the objective.

## Apply resilience by failure mode

Start with an end-to-end deadline. Allocate smaller timeouts to dependencies so the caller retains time to handle failure. Propagate cancellation and avoid timeout layers that fight each other.

Apply patterns deliberately:

- **Retry** transient faults only; bound attempts and time, use jitter, and require idempotency or deduplication.
- **Circuit breaker** stop repeated calls during a sustained dependency failure and test recovery behavior.
- **Rate limiter** protect capacity and fairness; define client-facing retry guidance.
- **Bulkhead/concurrency limiter** isolate scarce resources and prevent one workload from exhausting all capacity.
- **Fallback** return only data or behavior that remains semantically safe; never turn corruption or authorization failure into success.
- **Hedging** use only for safe operations after measuring its extra downstream load.

Do not retry validation, authentication, authorization, deterministic not-found, or other permanent failures. Do not multiply retries at HTTP, application, SDK, and proxy layers. Record attempt count and final outcome without logging secrets.

## Bound work and apply backpressure

Bound every queue, batch, parallel loop, cache, payload, and fan-out. Define overload behavior explicitly:

- wait within a deadline;
- reject with a retryable signal;
- shed low-priority work;
- persist durable work for later processing;
- degrade a non-critical feature safely.

Use bounded channels or broker prefetch/concurrency settings for workers. Track queue depth, age of oldest item, processing duration, retries, poison messages, and saturation. Scale on the limiting resource and queue delay, not CPU alone.

Prevent a single tenant, customer, or job type from monopolizing capacity. Apply fair partitioning, quotas, or separate pools when isolation requirements justify them.

## Validate under realistic load

Run focused performance tests in an environment close enough to reveal database, network, GC, container, proxy, and autoscaling behavior. Include steady load, bursts, large payloads, slow dependencies, partial failures, retries, cache cold start, and rolling deployment.

Compare before and after using the same workload. Check latency percentiles, throughput, errors, resource saturation, downstream load, and cost. Verify that gains persist under concurrency and do not move the bottleneck into another service.

For a risky optimization, define a rollback or feature flag and production guardrail before release.

## Use the production checklist

Verify:

- A measurable objective and baseline exist.
- The change targets observed evidence.
- Cancellation, timeouts, and overload behavior are explicit.
- Retries cannot duplicate unsafe side effects.
- Pools, queues, caches, batches, and payloads are bounded.
- Database indexes and query plans match production-like data.
- Telemetry exposes latency, errors, saturation, and dependency behavior.
- Load/failure tests cover the expected operating envelope.
- Correctness, authorization, tenancy, and freshness semantics remain intact.
- Rollback is practical.

## Official anchors

Use Microsoft guidance for [ASP.NET Core performance best practices](https://learn.microsoft.com/aspnet/core/fundamentals/best-practices), [.NET diagnostics](https://learn.microsoft.com/dotnet/core/diagnostics/), and [resilient HTTP applications](https://learn.microsoft.com/dotnet/core/resilience/http-resilience). Verify resilience APIs against the target framework and package version.
