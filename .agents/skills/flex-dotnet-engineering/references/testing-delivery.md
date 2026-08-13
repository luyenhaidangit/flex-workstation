# Testing, quality gates, and delivery

## Contents

- [Build a risk-based test strategy](#build-a-risk-based-test-strategy)
- [Write maintainable tests](#write-maintainable-tests)
- [Choose doubles and real dependencies](#choose-doubles-and-real-dependencies)
- [Test APIs data and distributed behavior](#test-apis-data-and-distributed-behavior)
- [Enforce architecture and code quality](#enforce-architecture-and-code-quality)
- [Design CI gates](#design-ci-gates)
- [Manage dependencies and supply chain](#manage-dependencies-and-supply-chain)
- [Deploy schema and code safely](#deploy-schema-and-code-safely)
- [Verify production readiness](#verify-production-readiness)

## Build a risk-based test strategy

Map tests to failure impact and uncertainty. Use the cheapest test that can reliably catch the defect, then add broader tests for boundaries that unit tests cannot prove.

Use:

- unit tests for pure domain rules, calculations, parsers, and state transitions;
- component/application tests for orchestration with controlled ports;
- integration tests for database provider, ASP.NET pipeline, serialization, auth, queues, files, and external protocols;
- contract tests for public HTTP/message compatibility;
- end-to-end tests for a small set of critical journeys;
- architecture tests for important dependency rules;
- performance, load, resilience, and security tests for material risks.

Do not target a coverage percentage as the goal. Use coverage to find untested critical branches, not to reward tests that execute lines without asserting behavior.

## Write maintainable tests

Name tests by behavior and condition, following repository style. Keep arrange/act/assert visible. Assert observable outcomes rather than implementation sequence unless the sequence is the contract.

Make tests deterministic:

- inject `TimeProvider`, IDs, randomness, and external ports when behavior depends on them;
- avoid real sleeps and polling without a bounded eventual assertion;
- isolate test data and tenant identity;
- avoid order dependence and shared mutable fixtures;
- control culture and timezone when parsing or formatting matters.

Prefer builders/factories with meaningful defaults for complex domain setup. Avoid a giant “test base” that hides dependencies and state. Keep failure messages informative and snapshots reviewed rather than blindly updated.

## Choose doubles and real dependencies

Use a stub/fake for a stable port when it makes business behavior faster and clearer. Mock interactions only when the interaction itself is the contract, such as a required publish or forbidden remote call.

Do not mock EF Core query internals, `DbSet`, HTTP internals, or a broker so deeply that the test reproduces framework implementation. Use the real relational provider/containerized dependency for translation, constraints, transactions, locking, serialization, and acknowledgment behavior.

Use an HTTP fake handler or local test server for outbound client behavior and verify URL, headers, body, timeout, retry, and response handling. Never call a live production service from automated tests.

## Test APIs data and distributed behavior

For ASP.NET Core, exercise the real host pipeline for routing, binding, validation, middleware, authn/authz, status codes, Problem Details, content type, and serialization. Test unauthorized, forbidden, not found, conflict, limit, cancellation, and unexpected-failure paths.

For EF Core, test against the actual provider for generated queries, collation, precision, unique/foreign/check constraints, transactions, optimistic concurrency, migrations, and tenant filtering. Apply migrations to an empty database and upgrade from a representative prior schema.

For messaging/jobs, test duplicate/out-of-order delivery, crash around commit/ack, retry classification, dead-letter behavior, outbox/inbox, lease expiry, idempotency, and graceful shutdown.

For multi-tenancy, use at least two tenants in the same test and assert negative isolation on read, write, cache, message, file, admin, and background paths.

## Enforce architecture and code quality

Use `.editorconfig`, nullable reference analysis, SDK analyzers, package analyzers, and build properties to automate stable rules. Ratchet legacy solutions: enforce new/changed code or a growing subset rather than suppressing the entire backlog.

Add architecture tests only for boundaries the compiler/project graph cannot already enforce, such as module internals, forbidden infrastructure references, or naming/annotation contracts. Keep rules few, valuable, and understandable.

Treat warnings and analyzer suppressions as reviewable code. Scope a suppression to the narrowest location, include a reason when it is not obvious, and avoid disabling security/correctness rules merely to pass CI.

Use formatting automation to remove style debate, but do not mix repository-wide reformatting into a functional change unless requested.

## Design CI gates

Use repository commands and pinned SDK/tool versions. A typical pipeline may include:

1. restore with locked/reproducible dependency behavior where supported;
2. build the same configuration that will ship;
3. formatter/analyzer/nullability verification;
4. unit and integration tests with useful logs/results;
5. contract and migration validation;
6. dependency vulnerability/license/policy checks;
7. packaging/container build and a startup smoke test;
8. selected performance/security gates for high-risk changes.

Fail fast on deterministic cheap checks, but preserve enough diagnostics to understand failure. Cache dependencies safely without masking lock-file changes. Never print secrets. Run untrusted pull-request code without privileged production credentials.

Keep CI and local commands aligned. Do not claim a green build based only on IDE compilation when the deployment uses different properties, runtime identifiers, trimming, AOT, or container settings.

## Manage dependencies and supply chain

Prefer supported framework features and well-maintained packages. Add a package only when its value exceeds lifecycle, vulnerability, license, transitive, binary-size, startup, and upgrade cost.

Centralize versions in multi-project solutions where practical. Pin SDK and build tools for reproducibility. Review transitive changes and release notes for significant upgrades. Keep runtime and package versions inside official support and apply security patches promptly through a tested process.

Produce an inventory/SBOM when policy or operational response requires it. Sign artifacts and verify source/provenance according to the delivery platform. Protect package feeds and CI tokens with least privilege.

## Deploy schema and code safely

Build immutable artifacts once and promote the same artifact through environments. Externalize environment configuration and secrets. Run the application as a non-root/non-admin identity where supported and keep the runtime image patched and minimal enough to reduce attack surface.

Use expand-and-contract schema changes across rolling deployments. Review migrations, estimate locks/time, back up, test on production-like volume, and use a controlled migrator rather than uncoordinated replica startup.

Make startup and shutdown observable. Stop accepting traffic before terminating critical work, honor cancellation, drain within a budget, and ensure jobs/messages can resume safely after interruption.

Use rolling, canary, blue/green, or feature-flag rollout according to risk. Define success guardrails and an actual rollback/roll-forward path. Avoid a flag whose old code cannot operate after an irreversible schema change.

## Verify production readiness

Before handoff or release, verify:

- supported runtime and patched dependencies;
- reproducible build and deployable artifact;
- passing targeted unit/integration/contract tests;
- reviewed schema changes and recovery path;
- configuration validation and secret provisioning;
- authorization and cross-tenant negative tests;
- capacity, timeout, retry, queue, cache, and payload limits;
- liveness/readiness and graceful shutdown;
- dashboards, safe telemetry, alerts, and ownership;
- backup/restore or reconciliation for critical data;
- rollout criteria and rollback/roll-forward procedure.

Report exactly which gates ran and which remain. Never weaken a gate silently to complete a delivery.

## Official anchors

Use the current [.NET testing guidance](https://learn.microsoft.com/dotnet/core/testing/) and official [.NET support policy](https://dotnet.microsoft.com/platform/support/policy/dotnet-core) for version-sensitive decisions. Verify platform-specific CI and deployment controls from their primary documentation.
