---
name: architecture-documenter
description: >
  Creates, reviews, and improves evidence-based system architecture documentation
  from codebase structure, requirements, APIs, database schema, deployment config,
  runtime flows, security constraints, and operations signals. Use when writing or
  updating architecture.md, system-map.md, architecture folders, technical design
  docs, onboarding architecture docs, Mermaid diagrams, risk reviews, or ADR
  suggestions for a service, module, repo, or multi-repo workspace. Do not use for
  general prose editing or prompt/instruction files; use documentation-and-adrs
  for decision records only and agent-instructions-architect for CLAUDE/AGENTS/
  SKILL instruction files.
---

# Architecture Documenter

## Mission

Produce architecture documentation that is useful for engineers, tech leads, testers, DevOps, security reviewers, maintainers, and AI agents. The document must explain the system's purpose, structure, runtime behavior, data, security, deployment, observability, risks, and open questions.

Do not invent architecture. Separate confirmed facts from inference.

## Input

Required:

- Target repo/workspace path, or use current working directory.
- Documentation target: create new doc, update existing doc, review existing doc, or propose structure.

Optional:

- Scope: whole workspace, one repo, one service, one module, one API, one workflow, deployment, data, security, observability.
- Audience: developer, tech lead, BA/tester, DevOps, security, manager, AI agent.
- Output language: default to Vietnamese with technical terms in English unless the user requests English.
- Desired destination path, for example `docs/architecture.md` or `docs/architecture/system-overview.md`.

If scope or destination is ambiguous, ask at most two short questions. If the user asks to implement directly and a reasonable default exists, proceed.

## Workflow

### 1. Discover evidence

Inspect only relevant files for the requested scope:

- `README*`, `SPEC.md`, `docs/**`
- solution/project/package files: `*.sln`, `*.csproj`, `package.json`, `pom.xml`, `go.mod`, etc.
- entrypoints, API controllers/routes, middleware, background jobs
- domain/entity/model files and database migrations/schema
- config examples: `appsettings*.json`, `.env.example`, Docker, Compose, Kubernetes, nginx/gateway, CI/CD
- logging, metrics, tracing, health check, and security config

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

Include only views relevant to the scope:

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
- ADR suggestions

Use Mermaid diagrams when they clarify relationships or runtime flow. Keep diagrams source-controlled as Markdown/Mermaid, not screenshots.

### 4. Write evidence-based documentation

Use these labels consistently:

- `Confirmed`: directly supported by code/config/docs.
- `Inferred`: likely based on structure, naming, or repeated patterns.
- `Assumption`: reasonable but not verified.
- `Unknown`: not enough information found.

Every major claim should be tied to evidence or explicitly labeled. Missing information is not a failure; hiding it is.

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

Before editing files, preserve existing useful content and avoid rewriting unrelated docs. When creating a new architecture doc, use `references/system-architecture-template.md`. When suggesting or creating ADRs, use `references/adr-template.md`.

Read `references/quality-checklist.md` before finalizing non-trivial docs or reviews.

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
