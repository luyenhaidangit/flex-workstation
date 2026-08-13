# Security and observability

## Contents

- [Start with trust boundaries](#start-with-trust-boundaries)
- [Authenticate and authorize explicitly](#authenticate-and-authorize-explicitly)
- [Protect secrets and sensitive data](#protect-secrets-and-sensitive-data)
- [Validate inputs and outputs](#validate-inputs-and-outputs)
- [Harden common integration paths](#harden-common-integration-paths)
- [Emit useful safe telemetry](#emit-useful-safe-telemetry)
- [Use logs metrics and traces together](#use-logs-metrics-and-traces-together)
- [Design health checks and alerts](#design-health-checks-and-alerts)
- [Preserve audit evidence](#preserve-audit-evidence)
- [Verify production readiness](#verify-production-readiness)

## Start with trust boundaries

Identify assets, actors, entry points, data flows, trust boundaries, privileged operations, and plausible abuse before adding controls. Include HTTP, queues, scheduled jobs, admin tools, callbacks/webhooks, storage, caches, logs, CI, and deployment credentials.

Assume all external input is untrusted, including headers, tokens before validation, filenames, URLs, serialized messages, broker metadata, database values written by other systems, and configuration from a less-trusted control plane.

Apply least privilege to identities, database users, storage, queues, network access, and deployment roles. Separate read/write/admin capabilities where the risk justifies it.

## Authenticate and authorize explicitly

Use framework-supported authentication handlers and well-maintained identity libraries. Validate cryptographic signatures and expected issuer, audience, lifetime, algorithm, nonce/state, and key rotation as applicable. Do not implement custom password hashing, token signing, or cryptographic protocols.

Authorize every entry point that reaches protected behavior, including background jobs and internal/admin endpoints. Prefer policy- and resource-based checks. Treat role or permission claims as inputs to authorization, not as a substitute for tenant, ownership, state, and object checks.

Deny by default. Avoid client-controlled bypass flags. Re-check authorization for state-changing actions and sensitive reads; do not assume that hiding a UI action protects its API.

For multi-tenant systems, resolve one trusted tenant context, reject conflicts, enforce it at query/write boundaries, and test cross-tenant access attempts. Keep tenant context out of mutable global state.

## Protect secrets and sensitive data

Never commit credentials, tokens, private keys, production connection strings, or real customer data. Use development secret storage only for development and an approved secret manager/workload identity for deployed environments.

Rotate secrets and signing keys without requiring an unsafe big-bang deployment. Limit secret lifetime and scope. Avoid copying secrets into command lines, exception text, metrics, traces, support bundles, or build output.

Classify sensitive data and minimize collection. Encrypt transport with modern TLS. Use platform data-protection APIs for application-protected payloads and persist/protect key rings correctly across replicas where cookies or protected data must survive restarts.

Do not invent field-level encryption casually. Define key ownership, rotation, search/index implications, backup/restore, deletion, and incident response first.

## Validate inputs and outputs

Apply allowlists and bounds to length, count, depth, numeric range, regex complexity, payload size, decompression ratio, file type, and processing time. Use parameterized database access. Encode output for its destination context and let safe serializers produce JSON rather than concatenating it.

Treat mass assignment as a boundary risk: map only permitted client fields into commands or domain operations. Never bind a persistence entity directly to an untrusted request.

For error responses, return a stable safe code and correlation identifier. Keep internal details in protected telemetry. Avoid distinguishing sensitive resource existence unless the product requires it.

Use rate limits, quotas, concurrency limits, and request limits for resource-exhaustion paths. Partition limits by trusted identity or tenant when a shared IP would be unfair or easy to evade.

## Harden common integration paths

For outbound HTTP and SSRF risk:

- allowlist schemes and hosts where possible;
- reject loopback, link-local, metadata, and private destinations when not required;
- validate redirects and DNS resolution according to the threat model;
- use fixed base addresses for known services;
- set size and timeout limits on responses.

For files, ignore client path names, generate server-owned names, store outside executable/static roots, validate content and size, scan when required, and authorize every download.

For webhooks, verify the raw-body signature with a secret or public key, validate timestamp/nonce to prevent replay, deduplicate event identity, return promptly, and process durable work asynchronously.

For deserialization, disable unsafe type metadata and limit object depth/size. Treat message contracts as untrusted even on an internal broker.

Keep dependencies patched and within support. Review transitive vulnerabilities in context, but do not suppress a finding without documenting reachability or compensating controls.

## Emit useful safe telemetry

Use structured event templates with stable names. Include service, environment, operation, trace/span identifiers, outcome, duration, and trusted tenant/user identifiers only when policy permits. Prefer immutable identifiers over names or full payloads.

Never log passwords, access/refresh tokens, cookies, API keys, authorization headers, full connection strings, private keys, or raw sensitive bodies. Redact centrally and test redaction. Beware that object destructuring and exception data can leak fields unexpectedly.

Log once at the handling boundary. Use levels consistently:

- Trace/Debug for targeted diagnostics, usually disabled in production.
- Information for meaningful lifecycle and business/operational events, not every method entry.
- Warning for handled abnormal conditions that need attention.
- Error/Critical for failed operations or process-threatening conditions.

Avoid high-cardinality metric labels such as raw URL, user ID, order ID, exception message, or arbitrary tenant ID unless the telemetry backend and privacy policy explicitly support it. Logs and traces can hold scoped identifiers more safely than metrics.

## Use logs metrics and traces together

Instrument critical paths with OpenTelemetry-compatible .NET primitives:

- Use `ILogger` for structured events.
- Use `ActivitySource` for operation/dependency spans.
- Use `Meter` for rates, duration histograms, errors, queue depth, and saturation.

Propagate W3C trace context across HTTP and message boundaries. Preserve the originating correlation while creating a new processing span for asynchronous work. Add baggage sparingly; it propagates and may leak sensitive data.

Use semantic conventions and route/operation templates. Configure sampling so errors and important low-volume flows remain diagnosable while high-volume cost stays bounded. Understand that head sampling cannot decide based on a future error without collector/tail-sampling support.

Record business signals that reveal correctness, such as publish success, payment state transition, outbox lag, duplicate suppression, and cross-system reconciliation—not only CPU and HTTP status.

## Design health checks and alerts

Keep liveness cheap and process-local. Use readiness for dependencies or initialization required to serve traffic. Apply timeouts to checks and avoid creating a traffic storm against dependencies.

Secure detailed health output. Return only the minimum status needed by orchestrators on public surfaces.

Alert on user-visible symptoms and saturation using an agreed objective: error rate, high latency, availability, queue age, failed business outcomes, exhausted pools, or migration/backfill failure. Avoid alerts that fire on every handled exception without operational action.

Attach runbook context, ownership, dashboard links, and a safe diagnostic path. Test that an alert is actionable before relying on it.

## Preserve audit evidence

Separate audit events from diagnostic logs when compliance or sensitive actions require it. Record actor, trusted tenant, action, target, timestamp, outcome, source, and reason where appropriate. Make the record append-oriented and protect access and retention.

Do not store secrets or unnecessary before/after payloads in an audit trail. Define correction, deletion, retention, and legal requirements explicitly. Make administrator impersonation and permission changes auditable.

## Verify production readiness

Verify:

- threat boundaries and privileged paths have been reviewed;
- authentication validation and authorization policies cover every entry point;
- tenant isolation is enforced and negatively tested;
- secrets and key rings are deployed, scoped, rotated, and redacted safely;
- request/file/queue limits and failure behavior are bounded;
- dependency vulnerabilities and support status are known;
- logs, metrics, and traces correlate without leaking sensitive data;
- critical business and dependency failures have actionable alerts;
- health checks match the orchestrator's liveness/readiness semantics;
- incident diagnostics and rollback do not require enabling unsafe production logging.

## Official anchors

Use current Microsoft [ASP.NET Core security guidance](https://learn.microsoft.com/aspnet/core/security/), [safe secret storage guidance](https://learn.microsoft.com/aspnet/core/security/app-secrets), and [.NET OpenTelemetry guidance](https://learn.microsoft.com/dotnet/core/diagnostics/observability-with-otel). Validate specific controls against the deployment platform and target framework.
