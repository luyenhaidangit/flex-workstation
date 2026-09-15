# Bootstrap Plan

Use this instead of the Change Plan when creating genuinely new ground: a new
project, a new module/bounded context, or a client for an external API or SDK.
Fill it in **before** writing implementation code — that is the whole point.

---

## Bootstrap Plan

- **Goal:** <one sentence — what this module is responsible for>

- **Boundaries:** one line each, name + single responsibility. If you can't say
  a boundary's job in one phrase, it isn't a boundary yet.
  - `<name>` — <responsibility>
  - `<name>` — <responsibility>

- **Layer map:** which package/namespace holds contracts, which holds
  implementations, which holds wiring. State the dependency direction and the
  rule that enforces it.
  - contracts: `<path>` — interfaces + data shapes, no framework/vendor types
  - implementation: `<path>` — the only place that knows the wire format
  - wiring: `<path>` — DI/registration, options binding

- **Conventions fixed:** decide once, apply everywhere. Inconsistency introduced
  now is permanent.
  - naming: <method naming, async suffix, file-per-type vs grouped>
  - cancellation/context: <convention and position in the signature>
  - tests: <location, naming, what gets a test>
  - errors: <type name crossing the boundary>

- **Seams:** anything non-deterministic or externally owned gets an interface
  now, because retrofitting after N call sites always gets deferred.
  - `<clock / network / DB / SDK / credentials>` — <interface> because <reason>

- **Error model:** the type crossing the boundary, what it carries, and how a
  caller distinguishes retryable from fatal from needs-reauth. Must be decided
  before the first call site, not after.

- **Inherited from repo:** which outer conventions this module obeys — naming,
  error handling, test layout, DI style. Write "greenfield" only if the repo is
  genuinely empty. A new module inside a mature repo does not get its own
  dialect for things already decided.

- **Deliberately not built:** named gaps. Anything you chose not to implement
  belongs here rather than as an unused stub in the code.

---

## Changes

<the actual new files>

## Decision Log

- <boundary decision + why>
- <seam decision + why>
- <error model decision + why>
- <anything deviating from repo convention + why>

## Debt & Follow-ups

- <deferred item> — revisit when <trigger>
- (Write "None." if there genuinely is none.)

---

**Before declaring done**, run the skill's completion gate plus the Bootstrap
additions (signature consistency across the whole surface, classified errors, no
sensitive data reachable by logs, conventions recorded where the next person
will find them). For external API/SDK work, use the completion gate in
`references/integration-clients.md`.
