---
name: architecture-documenter
description: >
  Creates, reviews, and improves evidence-based system architecture documentation
  from codebase structure, requirements, APIs, database schema, deployment config,
  runtime flows, security constraints, and operations signals. Use when writing or
  updating architecture.md, system-map.md, architecture folders, technical design
  docs, onboarding architecture docs, Mermaid diagrams, risk reviews, or ADR
  suggestions for a service, module, repo, or multi-repo workspace. Also triggers
  on requests like "tài liệu kiến trúc", "document the system", "architecture
  overview", "vẽ diagram hệ thống", "system map", "mô tả kiến trúc hệ thống".
  Do not use for general prose editing or prompt/instruction files; use
  documentation-and-adrs
  for decision records only and agent-instructions-architect for CLAUDE/AGENTS/
  SKILL instruction files. Do not use to write standalone ADR files (use
  documentation-and-adrs); do not use to update non-architecture prose docs.
---

# Architecture Documenter

## Mission

Produce architecture documentation that is useful for engineers, tech leads, testers, DevOps, security reviewers, maintainers, and AI agents. The document must explain the system's purpose, structure, runtime behavior, data, security, deployment, observability, risks, and open questions — at the appropriate level of abstraction for the requested scope.

Do not invent architecture. Separate confirmed facts from inference.

## Input

Required:

- Target repo/workspace path, or use current working directory.
- Documentation target: create new doc, update existing doc, review existing doc, or propose structure.

Optional:

- Scope: whole workspace, one repo, one service, one module, one API, one workflow, deployment, data, security, observability.
- Audience: developer, tech lead, BA/tester, DevOps, security, manager, AI agent.
- Output language: default to Vietnamese with technical terms in English unless the user requests English.
- Desired destination path (default: `docs/architecture.md` for single-repo, `docs/architecture/overview.md` for workspace). Examples: `docs/architecture.md`, `docs/architecture/system-overview.md`.

If scope or destination is ambiguous, ask at most two short questions before proceeding. Examples: "Scope là toàn workspace hay một repo cụ thể?" / "Đường dẫn output mong muốn, hay dùng default?" If the user asks to implement directly and a reasonable default exists, proceed without asking.

## Workflow

### 1. Discover evidence

Inspect only relevant files for the requested scope:

- `README*`, `SPEC.md`, `docs/**`
- solution/project/package files: `*.sln`, `*.csproj`, `package.json`, `pom.xml`, `go.mod`, etc.
- entrypoints, API controllers/routes, middleware, background jobs
- domain/entity/model files and database migrations/schema
- config examples: `appsettings*.json`, `.env.example`, Docker, Compose, Kubernetes, nginx/gateway, CI/CD
- logging, metrics, tracing, health check, and security config

Calibrate evidence depth by scope:

| Scope | Read |
| --- | --- |
| Workspace / multi-repo | README, package/solution files, entrypoints, docker-compose, CI/CD — enough for container-level context |
| Single repo | + entrypoints, API routes, middleware, background jobs, config examples |
| Module / service detail | + domain/entity/model files, migrations/schema, security config, logging config |

Prefer structural evidence from code/config over guesses. Use file references in notes and final findings when useful.

### 2. Classify architecture

Identify the likely architecture style when evidence supports it:

- layered architecture
- clean/hexagonal architecture
- modular monolith
- microservice architecture
- microfrontend
- event-driven architecture
- CQRS
- gateway/BFF pattern

State why the classification is `Confirmed`, `Inferred`, or `Unknown`.

### 3. Build architecture views

Include only views relevant to the scope. Use the table below to decide which views to include — do not add lower-level views unless the user explicitly requests them:

| Scope | Include | Skip (delegate to per-service docs) |
| --- | --- | --- |
| Workspace / multi-repo | system context, container/application view, deployment, risks and trade-offs | component/module view, runtime/sequence flow, data architecture, API/integration detail, observability internals |
| Single repo | + component/module view, runtime/sequence flow, security, observability | data schema detail (unless core to the doc) |
| Module / service detail | all views as relevant | — |

Available views:

- system context
- container/application view
- component/module view
- runtime/sequence flow
- data architecture
- API/integration
- security
- deployment
- observability
- risks and trade-offs

Also include ADR suggestions when new decisions or reversals are detected in the evidence.

Use Mermaid diagrams when they clarify relationships or runtime flow. Keep diagrams source-controlled as Markdown/Mermaid, not screenshots — Mermaid is diffable, searchable, and AI-readable; screenshots are not.

### 4. Write evidence-based documentation

Use these labels consistently to prevent AI agents and reviewers from treating inferred claims as ground truth:

- `Confirmed`: directly supported by code/config/docs.
- `Inferred`: likely based on structure, naming, or repeated patterns.
- `Assumption`: reasonable but not verified.
- `Unknown`: not enough information found.

Every major claim should be tied to evidence or explicitly labeled. Missing information is not a failure; hiding it is.

**Good:** `"Service A calls Service B (Confirmed — see HttpClient registration in ServiceCollectionExtensions.cs:42)"`
**Bad:** `"Service A calls Service B (Confirmed)"` — label without evidence pointer is not Confirmed, it is Inferred.

### 5. Review risks

Assess practical risks in scope:

- tight coupling and unclear ownership
- security/auth/tenant isolation gaps
- deployment/config drift
- missing retries, timeouts, idempotency, or error handling
- data consistency and migration risks
- missing tests around critical flows
- weak logging/tracing/metrics/health checks
- performance bottlenecks and scaling constraints
- stale or missing ADRs

Prioritize recommendations as High/Medium/Low.

### 6. Finalize

**Determine destination path before writing any file:**

| Scope | Default destination |
| --- | --- |
| Workspace (multiple repos) | `<workspace-docs-dir>/architecture/overview.md` — e.g. `flex-workstation/docs/architecture/overview.md` |
| Single repo | `docs/architecture.md` in that repo's root |
| User specified explicitly | Use the user-specified path verbatim |

Do not invent a custom filename when a default applies. If the resolved path is non-obvious, state it explicitly before writing and let the user correct it.

**Good:** User asks "tài liệu cho flex-auth-service" → state path: `flex-auth-service/docs/architecture.md` before writing.
**Bad:** Silently creating `architecture.md` at workspace root without stating the resolved path first.

If a file already exists at the destination, read it first to preserve useful content before overwriting.

Before editing files, preserve existing useful content and avoid rewriting unrelated docs. When creating a new architecture doc, use `references/system-architecture-template.md` — but select only the sections appropriate for the scope:

- **Workspace scope:** use Executive Summary, System Context, Container/Application View, Deployment, Risks, Open Questions, Suggested ADRs. Link to per-service docs for component detail, data schema, and API listings.
- **Single-repo scope:** use all sections; omit those that are genuinely not applicable.

When listing ADR suggestions within the architecture doc, use `references/adr-template.md` as the format reference for each entry.

Read `references/quality-checklist.md` before finalizing non-trivial docs or reviews.

Do not edit source code, tests, migrations, or CI/CD files — this skill has read-only access to all non-documentation files.

Task is complete when: (1) the resolved destination path has been confirmed or stated to the user, (2) the target doc has been written or updated at that path, and (3) `references/quality-checklist.md` has been reviewed.

## Output Rules

- Prefer concise, scannable Markdown.
- Use tables for component inventories, risks, open questions, and decisions.
- Keep executive summaries short; put detail in sections.
- Do not duplicate long content already maintained elsewhere; link to source docs.
- Mark stale or missing information as `Unknown` or `Needs verification`.
- For Vietnamese output, write Vietnamese with diacritics and keep filenames, commands, APIs, package names, and architecture terms in English.

## Reference Files

- `references/system-architecture-template.md`: use when creating a full architecture document.
- `references/adr-template.md`: use when creating or suggesting Architecture Decision Records.
- `references/quality-checklist.md`: use before finalizing a generated/reviewed architecture doc.
