# Architecture Documentation Quality Checklist

Read this before finalizing non-trivial architecture documentation.

## Completeness

- [ ] Business/system purpose is clear.
- [ ] Scope and audience are explicit.
- [ ] Architecture style is identified or marked `Unknown`.
- [ ] Main components and responsibilities are listed.
- [ ] Runtime/request/event flow is explained.
- [ ] Data stores, ownership, consistency, and migration concerns are covered.
- [ ] APIs/integrations and boundaries are covered.
- [ ] Authentication, authorization, secrets, and sensitive data are covered.
- [ ] Deployment environments and config source are covered.
- [ ] Logging, metrics, tracing, health checks, and alerts are covered.
- [ ] NFRs are listed with targets or marked `Unknown`.
- [ ] Risks, technical debt, and recommendations are prioritized.
- [ ] Open questions identify owner or impact when possible.
- [ ] Suggested ADRs are listed for important decisions.

## Evidence and Accuracy

- [ ] Major claims cite code/config/docs or are labeled `Inferred`, `Assumption`, or `Unknown`.
- [ ] No generated section pretends missing information was found.
- [ ] Diagrams match the text and do not introduce unsupported components.
- [ ] File paths and commands are exact.
- [ ] Existing docs are linked instead of duplicated when they are source-of-truth.

## Markdown Quality

- [ ] Headings are hierarchical and easy to scan.
- [ ] Tables are used for inventories and risks.
- [ ] Mermaid diagrams are valid enough to render.
- [ ] Long sections are split or linked.
- [ ] The document can be understood by a new developer without chat history.

## Practical Value

- [ ] A maintainer can use the doc to locate key code paths.
- [ ] A tester can identify major flows and risk areas.
- [ ] DevOps/security can see deployment, config, and access-control concerns.
- [ ] An AI agent can use the doc as a navigation map without overloading root instructions.
