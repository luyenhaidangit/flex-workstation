# Integration Clients — Bootstrapping Against an API You Don't Control

Read this when building a client, wrapper, or SDK layer for something external:
a REST/GraphQL API, a vendor SDK, a payment or messaging provider, or an LLM/AI
provider. This is Bootstrap mode applied to the most common greenfield shape
there is.

The reason this shape deserves its own reference: the provider is outside your
control and **will** break you — versions get deprecated, error formats are
undocumented, rate limits appear under load, credentials expire on their own
schedule. Structure written assuming a well-behaved provider gets rewritten, not
patched. The decisions below are the ones that are expensive to retrofit.

## The layer map

```
contracts/          interfaces + data shapes. No HTTP, no SDK types.
  ├── I<Provider>Client          façade — composition only, no logic
  ├── I<Provider><Domain>Client  one per provider domain
  ├── I<Provider>Gateway         the transport seam
  ├── I<Provider>CredentialStore the credential seam
  └── models/                    request/response shapes, typed error

implementation/     the only code that knows the wire format
  ├── <Provider>Gateway          HTTP, serialization, error parsing, retry
  ├── <Provider><Domain>Client   composes the gateway; domain semantics only
  └── wiring/                    DI registration, options binding

inbound/            webhooks/callbacks — separate from everything above
```

Your domain code depends on `contracts/` only. If a domain service imports an
SDK type or an HTTP type, the split has already failed.

## The decisions, in the order they get expensive

### 1. Split contracts from implementation on day one
**Default:** separate package/namespace/assembly.
**Why:** it is the only mechanical guarantee that domain code stays free of
vendor types. A comment saying "don't import the SDK here" does not survive
contact with a deadline.

### 2. One interface per provider domain, plus a thin façade
**Default:** `IProviderClient` exposes `.Messaging`, `.Media`, `.Analytics`;
each is its own interface; the façade holds no logic.
**Why:** provider domains have independent release cycles and independent
breaking changes. A single `ProviderClient` class becomes a multi-thousand-line
god object where every vendor change touches the same file. The façade keeps the
call site ergonomic without paying that cost.
**Failure mode it prevents:** "just add the method to the client" — forever.

### 3. Extract the transport gateway when the second domain arrives
**Default:** the second domain client triggers extraction of shared transport,
auth injection, error parsing, retry, and pagination.
**Why:** this is the standing exception to abstract-on-third-use. The repetition
is already visible with two, and the retrofit cost grows with every copy — by
the time there are three or four, fixing the error handling means editing all of
them and missing one.
**Test that it worked:** you can unit-test a domain client by faking the
gateway, without constructing a fake HTTP handler.

### 4. Design the error model before the first call site
This is the single most commonly skipped decision and the most expensive to
retrofit.

**Default:** parse the provider's error body into a typed error that carries the
provider's own code/subcode plus a trace identifier, and exposes classification:

```
IsTransient      → safe to retry as-is
IsRateLimited    → back off; do not retry immediately
IsAuthError      → refresh/invalidate the credential, then retry once
(otherwise)      → fatal; surface to the caller
```

**Why:** every retry policy, circuit breaker, dead-letter rule and alert
upstream is a function of this classification. If the client throws one generic
exception with the raw body stuffed in the message, callers have two options:
retry everything (hammering a provider that's telling you to stop) or retry
nothing (failing on transient blips). Both are wrong, and the fix is not a
patch — it's rewriting every call site.

**Concretely:** a failed response usually has a structured body. Parse it. Do
not log the raw body and throw away the structure.

```csharp
if (!response.IsSuccessStatusCode)
{
    var error = TryParseProviderError(body)
                ?? new ProviderErrorPayload { Message = body, Code = -1 };
    logger.LogWarning("provider.error {Op} {Status} {Code} {TraceId}",
        operation, (int)response.StatusCode, error.Code, error.TraceId);
    throw new ProviderApiException(error, (int)response.StatusCode);
}
```

Note what is logged: the classified fields, not the whole body. See #9.

### 5. Credentials get their own seam, separate from configuration
**Default:** an interface that resolves a credential for a given scope and can
invalidate it.
**Why:** configuration is static; credentials are not. Tokens expire, refresh on
their own schedule, differ per tenant, and come in kinds with different
lifetimes (app-level vs resource-level vs delegated). Putting a token in an
options object is hardcoding with extra steps, and it blocks multi-tenancy
permanently.
**Also:** whatever resolves credentials must never be the same object that binds
`appsettings`/`.env`. Secrets belong in a secret store; the options object holds
non-secret settings and, at most, a reference.

### 6. Pin the API version explicitly
**Default:** an explicit, non-empty version in config, with a validation rule
that fails startup if it's missing.
**Why:** most providers interpret "no version" as their oldest supported
version, which is precisely the one about to be deprecated. Pinning turns a
surprise outage into a scheduled migration.

### 7. Buffer vs stream — decide by bound, not by habit
**Default:** if the result set has a natural small bound (accounts a user owns,
configured endpoints, templates), return a materialized list. If it is unbounded
(feed items, transactions, search results, log entries), return a lazy sequence
(`IAsyncEnumerable`, generator, cursor iterator).
**Why:** materializing an unbounded edge is an out-of-memory incident waiting for
a large customer. Streaming a five-element list is ceremony that makes every
caller write a loop.
**Either way:** the pagination loop lives in the gateway, once. Never make
callers follow cursor links.

### 8. Wrap what has a caller; list the rest
**Default:** implement the endpoints in use; record the unimplemented surface in
the module README's "deliberately not built" section.
**Why:** an unused wrapper method is not free — it still has to be reviewed,
tested, and migrated through every provider breaking change, and it lies about
what's been validated. Coverage of an API is not a goal; coverage of your use
cases is.

### 9. Check what the logger actually serializes
**Default:** log identifiers and classified fields; never log whole request or
response objects from a provider.
**Why:** provider responses routinely carry credentials inline (per-resource
access tokens are a common example), plus PII and payment details. A single
`LogDebug("{@Response}", response)` ships those to whatever aggregates your
logs, usually with a much longer retention than you'd choose.
**Check it explicitly at the completion gate** — the intent of a log line and
what it emits are different things.

### 10. Keep inbound separate from outbound
**Default:** webhook/callback handling is its own interface and its own file; it
does not live on the client that makes outbound calls.
**Why:** they are opposite directions with nothing in common. The inbound path
needs signature verification over the **raw body** — which means the handler
must buffer the request before any model binding — and needs replay/idempotency
handling. Mixing it into the outbound client forces every consumer that only
sends to also depend on the receiving machinery.

### 11. Keep signatures uniform across the whole surface
**Default:** identical parameter order, naming, and cancellation convention in
every method of every domain interface.
**Why:** with several same-typed string parameters (ids, tokens, names), one
method that orders them differently is a bug that compiles cleanly and fails at
runtime, at exactly one call site, in production. Review the full surface in one
pass rather than method by method — the inconsistency is only visible in
aggregate.

## LLM / AI provider specifics

Everything above applies. These are the additional decisions:

- **Streaming is the default path, not a variant.** Design the interface for
  incremental output first and derive the non-streaming call from it. Retrofitting
  streaming onto a request/response interface means changing every signature.
- **Classify context-length and content-filter errors separately** from generic
  fatal errors. They need different upstream handling — truncate and retry vs
  surface to the user — and both are common enough that "fatal" loses information.
- **Usage accounting belongs in the gateway**, emitted per call: input tokens,
  output tokens, model, latency. If each caller computes cost, you get N
  inconsistent answers and no way to attribute spend.
- **Model identifiers are configuration, never literals.** They change on the
  provider's schedule, differ per environment, and get overridden per tenant.
- **Tool/function schemas belong with the domain that owns the tool**, not in the
  client. The client transports them; it does not define them.
- **Prompts are versioned assets, not string literals in logic.** Treat a prompt
  change like a code change — it needs review and a rollback path.

## Completion gate for an integration client

Run alongside the skill's standard completion gate.

- [ ] Domain code has zero imports of vendor/HTTP types.
- [ ] Errors crossing the boundary are classified, not just wrapped.
- [ ] Credential resolution sits behind a seam and can be invalidated.
- [ ] No secret in source, config-under-version-control, or logs.
- [ ] API version is explicit and validated at startup.
- [ ] Pagination/streaming loop exists once, in the gateway.
- [ ] Parameter order and naming are uniform across the whole surface.
- [ ] Inbound handling is separate, verifies signatures over the raw body, and
      is idempotent.
- [ ] Unimplemented surface is listed as named gaps, not silently absent.
- [ ] A domain client can be unit-tested by faking the gateway alone.
