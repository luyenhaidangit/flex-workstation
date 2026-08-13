# ASP.NET Core APIs and workers

## Contents

- [Treat HTTP as a boundary](#treat-http-as-a-boundary)
- [Design stable contracts](#design-stable-contracts)
- [Validate and map failures](#validate-and-map-failures)
- [Authenticate and authorize](#authenticate-and-authorize)
- [Compose middleware and dependencies](#compose-middleware-and-dependencies)
- [Call remote services safely](#call-remote-services-safely)
- [Run background work safely](#run-background-work-safely)
- [Handle payloads and streaming](#handle-payloads-and-streaming)
- [Expose operational endpoints](#expose-operational-endpoints)
- [Evolve and test contracts](#evolve-and-test-contracts)

## Treat HTTP as a boundary

Keep endpoints thin but meaningful. Let them own HTTP concerns—routing, authentication context, binding, status codes, headers, and contract mapping—while an application operation owns business orchestration and invariants.

Use Minimal APIs, controllers, Razor Pages, gRPC, or another supported host based on repository conventions and contract needs. Do not migrate styles solely for fashion. Group registration and endpoints by feature or module so startup remains discoverable.

Never trust identity, tenant, price, role, ownership, or other protected state solely because the client supplied it. Derive trusted context from authenticated server-side claims and authoritative data.

## Design stable contracts

Use dedicated request and response contracts. Keep persistence entities and internal domain objects private. Define JSON names, nullability, enum representation, number precision, timestamps, and pagination semantics intentionally.

Use HTTP semantics consistently:

- Return `200` for a successful representation, `201` plus a location for creation when addressable, and `204` only when no response body is useful.
- Distinguish malformed/invalid input, unauthenticated, forbidden, not found, conflict, precondition failure, rate limit, and unexpected failure.
- Avoid returning `200` with an error envelope for every outcome unless an existing external contract requires it.
- Make `PUT`, `DELETE`, and retryable commands idempotent by contract; add an idempotency key and durable deduplication for important retried `POST` operations.

For collections, define stable ordering before pagination. Prefer cursor/keyset pagination for large or frequently changing datasets; use offset pagination only when its cost and consistency are acceptable. Bound page size and filtering complexity.

Document behavior in OpenAPI or the repository's contract mechanism. Keep examples free of real credentials and personal data.

## Validate and map failures

Validate binding shape, ranges, formats, and cross-field rules at the boundary. Enforce business invariants again in the operation or model that owns them. Do not treat client-side validation as protection.

Use a consistent Problem Details representation for HTTP errors where compatible with the existing API. Include a stable machine-readable code, safe human detail, trace/correlation identifier, and field errors when useful. Do not expose stack traces, SQL, internal hostnames, or raw provider messages.

Map known failures centrally or through explicit endpoint results. Log unexpected failures once at the boundary. Treat client-request cancellation and server timeout distinctly when the hosting stack allows it.

## Authenticate and authorize

Authenticate with a supported scheme configured for the token or cookie issuer. Validate issuer, audience, signature, lifetime, and algorithm as applicable. Never decode a token and trust its claims without validation.

Authorize at every protected entry point. Prefer policy- and resource-based authorization over scattered role-string checks. Check object ownership and tenant membership before returning protected data; avoid revealing existence through inconsistent forbidden/not-found behavior when that matters to the threat model.

Resolve tenant context once from a trusted host, route, token claim, or server-side mapping. Reject ambiguous or conflicting tenant inputs. Propagate the verified tenant explicitly into data access, cache keys, messages, jobs, and telemetry.

For cookie-authenticated browser endpoints, configure CSRF protection, secure cookie attributes, HTTPS, CORS, and data-protection key persistence for the deployment topology. CORS is not an authorization mechanism.

## Compose middleware and dependencies

Order middleware deliberately. Place forwarded-header handling only behind trusted proxies; apply exception handling, security headers/HTTPS, routing, CORS, authentication, authorization, rate limiting, and endpoint mapping in an order supported by the framework and repository.

Avoid expensive work before authentication or rejection controls when possible. Do not buffer large request/response bodies globally for logging.

Register dependencies through module-specific extension methods. Validate options at startup. Respect DI lifetimes and avoid resolving services manually from the root provider. Never store `HttpContext`, request services, or request-bound streams for later use.

Keep request code thread-safe. A request may continue on different threads; thread-local state is not request state. Use `HttpContext.Items` sparingly for pipeline-local values and typed scoped services for meaningful context.

## Call remote services safely

Use `IHttpClientFactory` or the repository's managed client abstraction. Configure base address, authentication, serialization, timeout/resilience, and telemetry per logical client. Do not instantiate and dispose `HttpClient` per call or mutate shared default headers per request.

Set a total timeout budget and propagate cancellation. Retry only transient failures and only when the operation is idempotent or protected by an idempotency design. Bound retries, add jitter, honor server retry hints, and avoid multiplying retries across layers.

Validate outbound destinations when any URL component is influenced by a user. Restrict schemes and hosts and defend against redirects/DNS behavior as required by the SSRF threat model.

Use typed contracts and tolerant readers for external APIs, but surface schema drift. Do not silently return empty success when deserialization fails.

## Run background work safely

Do not launch fire-and-forget tasks from an HTTP request for work that must complete. Persist durable work or enqueue it to an owned background system before acknowledging success.

For `BackgroundService` or hosted workers:

- Honor the host cancellation token and stop within the shutdown budget.
- Create a DI scope per message/job or bounded batch.
- Bound concurrency and prefetch according to downstream capacity.
- Make handlers idempotent and define poison-message/dead-letter behavior.
- Record attempts, latency, success/failure, queue delay, and correlation.
- Renew leases or visibility timeouts for long work and avoid duplicate ownership assumptions.

Catch errors at the unit-of-work boundary, classify retryability, and let unrecoverable failures become visible. Never use an empty catch loop that turns a broken worker into a healthy-looking process.

## Handle payloads and streaming

Set explicit request, form, multipart, message, and decompression limits appropriate to the endpoint. Stream large payloads instead of loading them entirely into memory. Validate filename-independent content, type, size, and destination; generate server-controlled storage names and scan uploads when required.

Use asynchronous request/response APIs. Return `IAsyncEnumerable<T>` only when the serializer and client can consume a stream and partial failure semantics are acceptable. Avoid returning a deferred `IEnumerable<T>` backed by a disposed database context.

Apply response compression to suitable content and avoid compressing secrets in a context vulnerable to side-channel attacks. Use output/response caching only for explicitly cacheable responses with correct variation by authorization, tenant, query, encoding, and other relevant dimensions.

## Expose operational endpoints

Separate liveness from readiness:

- Let liveness indicate whether the process should be restarted; avoid making it depend on every downstream service.
- Let readiness indicate whether the instance can safely receive traffic, including critical initialization and dependencies where appropriate.

Keep health responses cheap, bounded, authenticated or minimally detailed as appropriate, and independent from business traffic spikes. Do not expose secrets, connection strings, or detailed topology.

Instrument request rate, errors, duration, active work, dependency latency, saturation, and business-critical outcomes. Use route templates rather than raw high-cardinality paths in metric labels.

## Evolve and test contracts

Prefer additive compatible changes. Version only when a breaking contract cannot be avoided, and define support/deprecation policy. Test serialization and generated OpenAPI for public contracts. Use integration tests through the real ASP.NET Core pipeline for routing, binding, filters/middleware, authentication, authorization, and error mapping.

Before release, verify proxy headers, HTTPS, CORS, cookie/token settings, request limits, timeouts, rate limits, health probes, graceful shutdown, and deployment-specific data-protection behavior.

## Official anchors

Use current Microsoft guidance for [ASP.NET Core best practices](https://learn.microsoft.com/aspnet/core/fundamentals/best-practices), [security](https://learn.microsoft.com/aspnet/core/security/), and [HTTP resilience](https://learn.microsoft.com/dotnet/core/resilience/http-resilience). Verify version-specific middleware and API behavior against the target framework.
