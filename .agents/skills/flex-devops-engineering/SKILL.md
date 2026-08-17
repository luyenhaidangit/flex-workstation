---
name: flex-devops-engineering
description: Designs, implements, reviews, diagnoses, and safely operates Flex infrastructure and delivery workflows. Use when working with Dockerfiles, Docker Compose, HAProxy, Jenkins, CI/CD, deployment scripts, environment configuration, secrets, container networking, health checks, observability, rollout, rollback, or infrastructure production-readiness.
---

# Flex DevOps Engineering

## Overview

Apply safe, evidence-driven DevOps practices to the Flex workspace. Preserve the
existing deployment topology, minimize blast radius, keep state recoverable, and
distinguish configuration validation from an actual successful deployment.

This skill specializes generic delivery practices for Flex repositories, especially
`flex-environment`: split Docker Compose files, the shared `flex_net` network,
HAProxy ingress, Jenkins/JCasC, stateful infrastructure, monitoring, and operational
scripts. Existing repository instructions and nearby patterns govern exact names,
paths, and commands.

This skill does not own application business logic, Angular UI, or database schema.
When infrastructure work also changes those artifacts, apply the relevant
engineering skill as an additional owner rather than duplicating its rules here.

## When to Use

- Adding, changing, reviewing, or diagnosing a Dockerfile or Docker Compose service.
- Changing HAProxy routes, exposed ports, container networks, service discovery, or
  TLS/proxy configuration.
- Creating or modifying Jenkins pipelines, JCasC, GitHub Actions, deployment scripts,
  quality gates, artifact publishing, or image promotion.
- Introducing stateful infrastructure such as PostgreSQL, RabbitMQ, Redis, MinIO,
  Elasticsearch, or monitoring services.
- Managing environment variables, runtime configuration, credentials, volumes,
  health checks, logs, metrics, dashboards, alerts, rollout, or rollback.
- Investigating failed builds, unhealthy containers, deployment regressions,
  networking failures, port conflicts, or infrastructure drift.
- Reviewing infrastructure for production readiness, recoverability, least
  privilege, observability, or operational safety.

Do not use this skill for a purely application-level change with no infrastructure
or delivery artifact. Do not introduce Kubernetes, Terraform, Helm, or a new
platform merely because it is common elsewhere; use the technology already present
unless the user explicitly requests and justifies a platform change.

## Core Process

### 1. Establish target, authority, and blast radius

Before changing files or runtime state:

1. Identify the target repository, service, environment (`local`, `development`,
   `staging`, or `production`), host or cluster, and affected stateful resources.
2. Read the nearest `AGENTS.md`, Compose entry point, deployment documentation,
   adjacent service definitions, scripts, proxy configuration, and monitoring setup.
3. Classify the request as design, review, diagnosis, configuration change, local
   deployment, production deployment, migration, or incident response.
4. State success criteria, expected downtime, data risk, rollback path, and what
   runtime actions the request authorizes.

Read-only inspection and narrow local verification are safe defaults. Do not infer
permission to deploy to production, rotate credentials, delete data, recreate
stateful services, or change external DNS/firewalls.

### 2. Map the existing topology

Build a small evidence-backed map before proposing a change:

- Compose entry point and included role files.
- Service dependencies and readiness conditions.
- Internal networks, DNS names, host ports, and ingress routes.
- Images, version tags, build contexts, and registries.
- Named volumes, bind mounts, databases, queues, buckets, and backup ownership.
- Configuration sources and secret providers by environment.
- Health checks, logs, metrics, dashboards, and alert paths.
- Deployment scripts, CI triggers, promotion flow, and rollback mechanism.

Reuse the existing service pattern that performs the same operational role. Do not
copy an example from the internet before checking the repository's topology and
constraints.

### 3. Design the smallest operable change

For each proposed change:

1. Put it in the file responsible for that role. In `flex-environment`, keep the
   Compose entry point limited to includes and place services in the applicable
   infra, app, tools, or monitoring file.
2. Follow local naming, network, volume, comment, environment-variable, and image
   conventions. Pin a concrete image version or immutable digest; never use
   `latest` or an omitted tag.
3. Prefer internal service discovery on `flex_net`. Route user-facing HTTP/Web UIs
   through HAProxy when repository policy requires it; expose host ports only for an
   explicit local-debug or integration requirement.
4. Give every stateful service persistent storage, ownership boundaries, and a
   recovery strategy. Treat bucket/database/queue initialization as idempotent.
5. Separate liveness from readiness. Startup order alone is not readiness; use a
   real health check or an init job that retries the actual dependency operation.
6. Keep environment-specific addresses, credentials, and tunables in approved
   configuration. Never introduce real secrets into source, examples, logs, command
   output, or documentation.
7. Add only the observability needed to operate the service: health state, useful
   logs, key metrics, and a clear failure signal.

If repository instructions conflict about credentials, follow higher-priority
instructions and never commit a real credential. A local placeholder/default may be
used only when explicitly allowed and unmistakably non-production; report the
policy conflict instead of silently choosing an unsafe interpretation.

### 4. Plan deployment and rollback before mutation

Define these before starting or restarting services:

- Exact services and configuration files in scope.
- Preconditions: credentials, images, disk, ports, network, certificates, backups.
- Deployment order and readiness gates.
- Smoke tests and observable success thresholds.
- Rollback trigger and exact rollback action.
- Data compatibility across old and new versions.

For stateful changes, rollback must not assume that deleting a volume or restoring an
old image restores compatible data. Prefer forward-compatible configuration and
application changes; require an explicit backup/restore plan for destructive or
irreversible changes.

### 5. Implement surgically

- Preserve unrelated working-tree changes.
- Change only the responsible Compose, proxy, pipeline, script, config, and docs.
- Reuse existing anchors, scripts, health-check styles, and environment conventions.
- Keep scripts non-interactive, fail-fast, and explicit about target services.
- Quote variables and paths; avoid string-built destructive commands.
- Make init/provisioning operations safe to rerun.
- Update operational documentation when commands, ports, routes, required variables,
  topology, onboarding, or recovery procedures change.

Do not refactor the entire stack, rename established services, or normalize unrelated
files while adding one service.

### 6. Validate configuration before runtime actions

Run the narrowest relevant static checks using repository scripts first. Typical
evidence includes:

```text
docker compose config --quiet
docker compose -f <compose-file> config --quiet
docker build --check <context>
haproxy -c -f <haproxy.cfg>
shellcheck <changed-script>
```

Also inspect the rendered configuration for:

- unresolved or accidentally defaulted variables;
- secrets or sensitive values;
- `latest`/unpinned images;
- port collisions and unintended host exposure;
- missing networks, volumes, dependencies, or health checks;
- invalid startup assumptions;
- architecture/platform mismatch;
- destructive commands or broad cleanup targets.

A static check proves syntax and interpolation, not service readiness or deployment
success.

### 7. Verify runtime state proportionally

Only perform runtime mutation authorized by the request. For an authorized local or
identified target deployment:

1. Pull/build the exact images required.
2. Start or update only the affected services when possible.
3. Observe container state and health, not merely command exit status.
4. Inspect bounded recent logs for startup errors and leaked secrets.
5. Verify service discovery and connectivity from the correct network boundary.
6. Run a real smoke operation: HTTP health request, bucket operation, queue publish,
   database readiness query, or equivalent.
7. Restart a stateful service when persistence is part of acceptance criteria, then
   confirm required data remains.
8. Check dependent services and ingress after the change.

Do not use `docker compose down -v`, broad prune commands, or volume deletion as a
routine troubleshooting step. Resolve exact targets and obtain explicit authorization
before destructive cleanup.

### 8. Report observed evidence

The final handoff must distinguish:

- files/configuration changed;
- static validation completed;
- images built or pulled;
- services actually started or updated;
- observed health/smoke-test results;
- production state, if any, actually changed;
- rollback readiness and remaining risk;
- blocked steps caused by missing target, credentials, access, or external state.

Never say "deployed" when only configuration was written or rendered.

## Artifact-Specific Rules

### Docker and Compose

- Use a specific version tag or digest and confirm target architecture support.
- Use named volumes for persistent service data unless the repository intentionally
  requires a reviewed bind mount.
- Keep one clear service owner for each host port and named volume.
- Add resource limits only with evidence and platform support; do not invent limits
  that cause silent throttling or OOM restarts.
- Use `depends_on` for ordering only; pair it with health/readiness behavior where
  dependency availability matters.
- Avoid fixed `container_name` unless repository integration requires it; Compose DNS
  should normally use the service name.

### HAProxy and network exposure

- Prefer one controlled ingress path for HTTP/Web UIs.
- Preserve forwarded headers, WebSocket/streaming behavior, timeouts, and TLS
  expectations required by the upstream service.
- Validate configuration before reload and verify both direct upstream health and the
  public route after reload.
- Do not expose admin consoles publicly without explicit authentication and network
  restrictions.

### CI/CD and Jenkins

- Keep local and CI verification commands aligned.
- Build once and promote the same immutable artifact between environments.
- Keep credentials in the approved CI secret store and scope them to the minimum job.
- Make quality gates fail visibly; do not convert real failures into warnings merely
  to make a pipeline green.
- Serialize deployments or migrations that cannot run concurrently.
- Record deployed version/digest and retain a known-good rollback artifact.

### Observability and operations

- A health endpoint should report actionable readiness without exposing secrets or
  internal diagnostics publicly.
- Logs must identify service, environment, timestamp, severity, and correlation data
  where applicable.
- Alerts need an owner, threshold, evaluation window, and actionable runbook; an alert
  that nobody can act on is noise.
- Verify disk/volume growth, retention, and backup for stateful infrastructure.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Compose config passed, so it is deployed." | Rendering proves syntax only. Observe health and run a smoke operation before claiming deployment. |
| "Using `latest` keeps us current." | It makes builds and rollbacks non-reproducible. Pin a version or digest and upgrade deliberately. |
| "Opening the admin port is faster." | It creates an unmanaged ingress path. Use the established proxy or explicitly scope local debug exposure. |
| "The init container runs after the service, so it is safe." | Started is not ready. Retry a real dependency operation or wait for a meaningful health check. |
| "Deleting the volume will fix the container." | It may irreversibly destroy state and hide the actual cause. Diagnose first and require authorization. |
| "These are only local credentials." | Defaults get copied into shared environments. Never commit real secrets and label permitted placeholders clearly. |
| "Rollback means redeploying the old image." | Stateful or contract changes may make the old version incompatible. Plan data and config compatibility explicitly. |

## Red Flags

- `latest`, an omitted image tag, or an unreviewed mutable tag.
- A new host port or public admin console that bypasses the established ingress.
- Real passwords, tokens, private keys, certificates, or production endpoints in
  source, rendered output, logs, or documentation.
- `service_started` treated as readiness without a retry or health mechanism.
- Stateful service without persistent storage, backup ownership, or recovery notes.
- Init script that fails on its second execution or creates duplicate resources.
- `docker compose down -v`, `docker system prune`, wildcard deletion, or broad cleanup
  proposed without resolved targets and explicit authorization.
- Production deployment without an exact environment, version/digest, health gate,
  monitoring window, and rollback plan.
- CI pipeline that rebuilds different artifacts per environment or suppresses failed
  quality gates.
- A completion report claiming runtime success without observed runtime evidence.
- Infrastructure changes mixed with unrelated application refactoring.

## Verification

- [ ] Target repository, service, environment, authority, blast radius, and success
      criteria were identified before mutation.
- [ ] Nearest repository instructions and existing topology/patterns were inspected.
- [ ] Image versions are pinned and target architecture is supported.
- [ ] Networks, ingress, ports, dependencies, health checks, and service discovery are
      deliberate and follow local convention.
- [ ] Stateful services have persistent storage, idempotent initialization, and a
      credible recovery path.
- [ ] No real secret or sensitive deployment value was added to files or exposed in
      output.
- [ ] Static validation ran successfully for every changed artifact, or the exact
      unavailable check is reported.
- [ ] Runtime deployment occurred only with authority and an identified target.
- [ ] Runtime health and a real smoke operation were observed before deployment was
      reported successful.
- [ ] Rollback triggers and actions are known for risky or production changes.
- [ ] Operational documentation reflects changed variables, routes, ports, commands,
      topology, or recovery steps.
- [ ] Final reporting separates configuration, validation, deployment, health, and
      residual risk with command evidence.

## Example Prompts

- "Thêm MinIO vào `flex-environment` để lưu avatar Agent và triển khai local."
- "RabbitMQ đang unhealthy; tìm nguyên nhân, sửa cấu hình và xác minh không mất dữ liệu."
- "Deploy phiên bản mới của `flex-agent-service` lên production và chuẩn bị rollback."
