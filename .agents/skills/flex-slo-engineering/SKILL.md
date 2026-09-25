---
name: flex-slo-engineering
description: Audits cross-service system performance against SLI/SLO targets — latency, error rate, availability, error budget — and traces a slow or unreliable user journey end-to-end through frontend, API, database, and infrastructure to find the actual bottleneck stage. Use when the user asks to review, audit, or optimize system performance, define or check SLI/SLO or error budget, investigate why a flow "feels slow" or breaches a latency target, or wants a periodic performance health check across services.
---

# Flex SLO Engineering

## Overview

Give a cross-service, evidence-based read on whether the system meets its
performance and reliability targets, and where in the end-to-end path a
breach actually originates. This skill owns the **system-wide diagnosis**:
which stage of a user journey (client, network, API, database, downstream
service, infrastructure) is responsible for a latency or reliability
problem, and whether that problem is real (measured) or assumed.

It does not own the fix. Once a stage is identified, hand the fix to the
domain skill that governs that artifact — `flex-dotnet-engineering`
(`references/performance-resilience.md`) for API/code-level fixes,
`flex-database-engineering` for query/index/schema fixes,
`flex-frontend-engineering` for Angular rendering/loading fixes, or
`flex-devops-engineering` for infrastructure, scaling, or observability
plumbing. Restate the finding for that skill rather than duplicating its
review checklist here.

## When to Use

- Rà soát/audit hiệu năng hệ thống định kỳ, hoặc "review performance" theo yêu cầu.
- Một flow nghiệp vụ "chậm" hoặc "đôi khi lỗi" nhưng chưa rõ nghẽn ở đâu.
- Định nghĩa hoặc rà soát lại SLI/SLO (latency percentile, availability, error rate) cho một service hoặc user journey.
- Đánh giá error budget: còn bao nhiêu dư địa lỗi/downtime trước khi vi phạm cam kết.
- So sánh hiệu năng thực đo với mục tiêu đã cam kết, trước hoặc sau một thay đổi lớn (release, migration, scale-up).

Do not use this skill to review a single function's algorithmic complexity,
a single SQL query, or a single Angular component in isolation with no
cross-service question attached — that is `flex-dotnet-engineering`,
`flex-database-engineering`, or `flex-frontend-engineering` working alone.
Do not use it to design CI/CD pipelines or container topology with no
performance question attached — that is `flex-devops-engineering`.

## Core Process

### 1. Pin down the SLI before touching data

An audit without a stated target is just an opinion. Before gathering any
evidence:

1. Name the **user journey** in scope (e.g. "đặt lệnh", "tra cứu số dư"), not
   an internal component. A journey usually spans multiple services.
2. Name the **SLI** being judged — latency (state the percentile: p50/p95/p99
   and the window), availability, error rate, or throughput. A vague "phải
   nhanh hơn" is not an SLI; ask for or propose a concrete number.
3. State the **SLO target** and its source: an existing commitment, a
   regression against a prior baseline, or "no target exists yet — this
   audit's job is to propose one from observed behavior."
4. If no historical metric exists at all, say so explicitly and treat
   "establish a baseline" as the deliverable instead of inventing a number.

### 2. Trace the journey stage by stage

Walk the request path end-to-end and collect evidence per stage — don't
jump to the stage that seems likely without checking the others first,
since the perceived bottleneck and the actual one often differ:

- **Client/frontend** — render blocking, redundant calls, missing loading
  state, payload size (Angular: see patterns already flagged in
  `flex-frontend-engineering`, e.g. reload-on-every-change-detection).
- **Network/edge** — HAProxy routing, TLS handshake, connection reuse,
  timeouts configured at the proxy vs. the service.
- **API/application** — request handling time, thread/connection pool
  saturation, N+1 calls to downstream services, synchronous waits on I/O.
- **Database** — query plan, missing index, lock contention, long-running
  transaction holding a connection.
  Cross-reference `flex-database-engineering` for anything migration/schema-shaped.
- **Downstream/integration** — third-party or internal service latency,
  retry storms, circuit breaker state.
- **Infrastructure** — container CPU/memory throttling, autoscaling lag,
  cold start, noisy-neighbor resource contention.

Prefer real signals (metrics, traces, logs — including the ECS-enriched
Serilog fields from `flex-dotnet-engineering`'s logging template) over
guessing from code reading alone. Code reading proposes a *hypothesis*;
a metric or trace confirms it.

### 3. Attribute, don't just describe

For each stage that shows a problem, state:

- **Symptom** — what was observed (e.g. "p95 latency 1.8s, target 500ms").
- **Stage** — which single stage above is the primary contributor. If two
  stages both contribute meaningfully, say so rather than picking one to
  simplify the report.
- **Evidence** — the metric, trace, or log line that supports the
  attribution, or "no direct evidence — inferred from code review" if that's
  all that's available (and flag it as lower confidence).
- **Error budget impact** — if an SLO exists, state whether this finding is
  currently consuming, or already exhausting, the error budget for the
  period.

### 4. Prioritize by user impact, not by ease of fix

Rank findings by how much of the SLO breach or error budget burn each stage
explains — not by which fix is fastest to ship. A quick fix to a stage that
explains 5% of the latency is not the priority when another stage explains
80%.

### 5. Hand off, don't re-litigate

For each finding, name the owning domain skill and restate the finding in
that skill's terms (component, symptom, why it matters) so the handoff is
actionable without re-deriving the diagnosis. Do not write the .NET-level,
SQL-level, or Angular-level fix yourself — that duplicates a skill that
already owns it and drifts out of sync over time.

## SLI/SLO Definition (when no target exists yet)

When the ask is to define SLI/SLO rather than audit against one:

1. Start from the user journey, not the service — an SLO scoped to "API X"
   without reference to what the user experiences is easy to satisfy while
   the user still has a bad time.
2. Pick the smallest set of SLIs that would catch a real user-visible
   regression: usually latency (a percentile, not an average) + availability
   or error rate. Add throughput or saturation only if capacity is the
   actual concern.
3. Set the SLO target from evidence — an existing baseline plus headroom, or
   an explicit business requirement — never a round number picked for looks.
4. State the measurement window and the error budget policy (what happens
   when it's exhausted: freeze non-critical releases, page on-call, etc.) so
   the SLO is enforceable, not decorative.

## Common Rationalizations

- **"The code looks slow, so that's the bottleneck."** — Code reading is a
  hypothesis generator, not evidence. Confirm with a metric or trace before
  attributing the SLO breach to a stage; a stage that looks inefficient may
  be a small fraction of the actual latency.
- **"No baseline exists, so I'll estimate one from the code."** — An
  estimate presented as a measured baseline misleads the next person who
  reads the report. State clearly that no baseline exists and that
  establishing one is the actual next step.
- **"I found the fix, I'll just make the change."** — This skill diagnoses
  across services; the fix belongs to the domain skill that owns the
  artifact. Handing off preserves that skill's own review discipline
  (e.g. `flex-dotnet-engineering`'s resilience patterns) instead of a
  one-off patch that skips it.
- **"One slow request is enough to conclude a systemic problem."** — A
  single sample can be noise (cold cache, one-off GC pause). State the
  sample size and whether the pattern is repeated before calling it a
  trend.

## Red Flags

- A performance audit report with no stated SLI, target, or window — it is
  then just a list of observations with no way to judge severity.
- A finding attributed to a stage with no evidence and no confidence
  caveat.
- A recommendation that duplicates a domain skill's fix in full detail
  instead of naming the finding and the owning skill.
- An SLO number picked because it "sounds reasonable" with no baseline or
  business requirement behind it.
- Treating every finding as equally urgent instead of ranking by user
  impact / error-budget burn.

## Verification

- [ ] The SLI, target, and measurement window are stated before any finding.
- [ ] Every stage of the journey was checked, not only the one suspected upfront.
- [ ] Each finding states its evidence and, if inferred rather than measured, says so.
- [ ] Findings are ranked by user impact / error-budget burn, not by fix effort.
- [ ] Each finding is handed off to the domain skill that owns the fix, not implemented here.
- [ ] If no baseline exists, the report says so explicitly instead of inventing one.
