# Production .NET review checklist

## Contents

- [Review procedure](#review-procedure)
- [Finding format](#finding-format)
- [Architecture and maintainability](#architecture-and-maintainability)
- [C# correctness](#c-correctness)
- [ASP.NET Core and API contracts](#aspnet-core-and-api-contracts)
- [EF Core and data](#ef-core-and-data)
- [Distributed systems and reliability](#distributed-systems-and-reliability)
- [Performance](#performance)
- [Security and privacy](#security-and-privacy)
- [Observability and operations](#observability-and-operations)
- [Tests and delivery](#tests-and-delivery)
- [False-positive safeguards](#false-positive-safeguards)

## Review procedure

1. Read the request, repository instructions, relevant contracts, and changed code.
2. Trace each changed entry point through authorization, business rules, data access, side effects, and failure handling.
3. Inspect configuration, DI lifetimes, migrations, tests, and deployment assumptions that affect runtime behavior.
4. Run focused build/tests/analyzers or a reproduction when feasible.
5. Report only evidence-backed findings. Separate pre-existing issues from introduced or in-scope risk.
6. Order findings by impact and give the smallest safe remediation.

## Finding format

Use:

```text
[Severity] Short defect title
Location: path:line
Evidence: What the code/configuration actually does.
Impact: The incorrect, unsafe, slow, or hard-to-operate outcome.
Trigger: The input, state, concurrency, deployment, or failure condition required.
Remediation: The smallest safe fix and any compatibility consideration.
Verification: Test or observation that would prove the fix.
```

Use Critical for exploitable security, cross-tenant access, likely data loss, or outage; High for incorrect behavior or serious reliability/concurrency risk; Medium for a credible maintainability/performance failure; Low for localized clarity. Omit severity inflation.

## Architecture and maintainability

- [ ] The change belongs to the module/feature that owns the behavior.
- [ ] Dependency direction does not leak HTTP, EF, queue, or vendor details into stable policy.
- [ ] New projects/interfaces/patterns protect a real boundary rather than add ceremony.
- [ ] Public contracts and serialization changes are intentional and compatible.
- [ ] Business invariants live in one authoritative place.
- [ ] Names express domain intent and responsibilities stay cohesive.
- [ ] The diff avoids unrelated formatting, upgrades, or broad refactoring.
- [ ] Configuration is typed, validated, and owned by the correct component.

## C# correctness

- [ ] Nullable annotations match real absence and no unjustified `!` hides risk.
- [ ] Expected outcomes and exceptions are distinguished consistently.
- [ ] Async I/O remains async; no `.Result`, `.Wait()`, or disguised blocking appears.
- [ ] Cancellation reaches database, HTTP, stream, queue, and delay operations.
- [ ] All owned tasks are awaited or durably queued.
- [ ] Resources are disposed by the owner; DI-owned objects are not disposed manually.
- [ ] Singleton/static state is thread-safe and cannot leak request/tenant data.
- [ ] Parallelism, queues, recursion, payloads, and collections are bounded.
- [ ] Time, timezone, culture, equality, and precision semantics are explicit.

## ASP.NET Core and API contracts

- [ ] Input DTOs expose only client-writable fields and validation is bounded.
- [ ] Status codes, Problem Details, headers, and idempotency match the contract.
- [ ] Authentication is validated and authorization covers resource/tenant ownership.
- [ ] Error responses do not reveal internals or sensitive existence.
- [ ] Middleware order, CORS, proxy headers, HTTPS, cookies, and rate limits fit deployment.
- [ ] Request/response/file limits prevent unbounded buffering or decompression.
- [ ] Remote clients use managed lifetimes, deadlines, safe retries, and SSRF controls.
- [ ] Background work does not outlive a request scope accidentally.

## EF Core and data

- [ ] `DbContext` lifetime and transaction owner are correct and not concurrent.
- [ ] Reads project required columns, bound result size, and use tracking intentionally.
- [ ] Generated SQL avoids N+1, client-side work, cartesian growth, and needless round trips.
- [ ] Important filters/orderings have plausible indexes and deterministic pagination.
- [ ] Raw SQL and dynamic sort/filter identifiers are parameterized or allowlisted.
- [ ] Concurrency constraints prevent lost updates and check-then-insert races.
- [ ] Remote calls do not occur inside long database transactions.
- [ ] Migrations are safe for existing rows, rolling versions, data volume, and rollback/roll-forward.
- [ ] Tenant scope appears in reads, writes, uniqueness, caches, and background paths.

## Distributed systems and reliability

- [ ] Cross-service calls have a deadline, retry classification, and bounded attempts.
- [ ] Retried commands are idempotent or durably deduplicated.
- [ ] Database change plus message publication uses an explicit consistency design.
- [ ] Consumers tolerate duplicate, delayed, and out-of-order delivery where applicable.
- [ ] Message contracts are versioned compatibly and exclude unnecessary sensitive data.
- [ ] Queue concurrency/prefetch is bounded and poison messages are visible.
- [ ] Jobs survive restart when required and coordinate multi-replica execution safely.
- [ ] Partial failure, replay, reconciliation, and compensation behavior is defined.
- [ ] No “exactly once” or global ordering assumption crosses independent resources without proof.

## Performance

- [ ] A baseline or production evidence identifies a meaningful bottleneck.
- [ ] The change reduces actual I/O, work, allocation, contention, or queueing.
- [ ] Database/HTTP connection pools and concurrency cannot starve each other.
- [ ] Caches define keys, tenant/auth variation, TTL, size, invalidation, stampede, and outage behavior.
- [ ] Hot-path optimizations preserve clarity and are supported by measurement.
- [ ] Telemetry can compare latency percentiles, errors, saturation, and downstream load before/after.
- [ ] Load behavior includes bursts, cold cache, slow dependencies, and rolling deployment when material.

## Security and privacy

- [ ] Secrets and production credentials are absent from code, config, logs, tests, and examples.
- [ ] Authorization denies by default and privileged/admin paths are explicit and auditable.
- [ ] Cross-tenant access is negatively tested.
- [ ] SQL, SSRF, path traversal, unsafe deserialization, mass assignment, and file-upload risks are controlled.
- [ ] Tokens, cookies, keys, TLS, data-protection key persistence, and rotation fit deployment.
- [ ] Logs/traces/errors redact tokens, credentials, PII, and raw sensitive payloads.
- [ ] Dependencies are supported and material vulnerabilities are addressed.
- [ ] Rate, size, depth, time, and concurrency limits constrain abuse.

## Observability and operations

- [ ] Logs use stable structured properties and record a failure once.
- [ ] Traces propagate across HTTP/messages and metrics avoid high-cardinality labels.
- [ ] Critical rates, errors, duration, saturation, queue age, and business outcomes are measured.
- [ ] Liveness is process-focused; readiness reflects ability to serve safely.
- [ ] Alerts are actionable and tied to user impact or saturation.
- [ ] Startup, shutdown, retries, migrations, and backfills are observable.
- [ ] Audit events capture protected state changes without storing secrets.

## Tests and delivery

- [ ] Tests cover changed behavior, failure paths, authorization, and tenant isolation.
- [ ] Relational, HTTP, serialization, and broker semantics use realistic integration tests where needed.
- [ ] Tests are deterministic and do not rely on real sleeps, order, timezone, or shared mutable state.
- [ ] Build, analyzers, nullable checks, and formatting use repository settings.
- [ ] The shipped configuration/artifact—not only Debug/IDE output—has been validated.
- [ ] Schema and code can coexist during rollout.
- [ ] Deployment has health checks, graceful shutdown, guardrails, and a rollback/roll-forward path.

## False-positive safeguards

Before reporting a finding:

- Trace the real call path and DI lifetime.
- Check whether framework or repository configuration already provides the control.
- Check generated SQL, serialization, or middleware behavior when the conclusion depends on it.
- Distinguish a theoretical possibility from a reachable production scenario.
- Confirm the issue is introduced by or relevant to the requested scope.
- Avoid presenting a personal style preference as correctness or performance risk.
- If evidence remains incomplete, exclude the item from severity-ranked defects and label it as a question or residual risk. State its potential severity only conditionally and identify the configuration, call path, test, or runtime evidence needed to resolve it.
