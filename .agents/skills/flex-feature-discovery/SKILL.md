---
name: flex-feature-discovery
description: Analyzes an existing repo's code, specs/, architecture docs, and constitution to propose a short, evidence-backed list of feature and improvement ideas for what to build next — not a spec writer for an idea already decided on. Use when the user asks what to build next, wants to brainstorm features or improvements for a specific repo, or wants a gap analysis of the current system with no feature already described.
---

# Feature Discovery

## Overview

Analyzes an existing repository — its code, `specs/` (if it uses Speckit), README/architecture docs, and `.specify/memory/constitution.md` (if present) — to propose a short, evidence-backed list of feature and improvement ideas for what to build next. This is upstream of `speckit-specify`: it answers "what should we build?", not "how do we spec what we already decided to build?" It never writes a spec, edits files, or invokes another skill's workflow on its own — it produces a list and, if the user picks one, points them at `speckit-specify` to run themselves.

## When to Use

- The user asks what feature to build next, or asks to brainstorm/nghĩ tính năng mới for a specific repo.
- The user wants a gap analysis: what's missing, half-built, or inconsistent compared to what the rest of the system already does.
- The user wants a fresh starting point for a repo they haven't touched in a while.

Do NOT use when:
- The user already has a feature description and wants it turned into a spec — that's `speckit-specify`.
- The user wants review/critique of a change already in progress — that's `flex-codebase-architect` or `code-review`.
- The user wants a security or tech-debt audit for its own sake with no feature angle — name the closer-fit skill instead of forcing this one.

## Core Process

1. **Resolve the target repo.** Default to the repo the user is currently working in (cwd, or the repo named in the request). If the user is at the `flex-workstation` root with no repo-con named, ask which repo-con to target — this skill needs one concrete codebase, not the workspace coordinator itself.
2. **Gather grounding context** before inventing anything:
   - `specs/` (if the repo uses Speckit) — read spec titles/status to know what's already done, in progress, or planned. Never propose something already covered here.
   - `.specify/memory/constitution.md` (if present) — respect its stated principles/constraints; don't propose an idea it would rule out.
   - README / architecture docs — understand the system's actual purpose and boundaries before suggesting scope.
   - The codebase itself — skim for concrete signals of incompleteness (see "Evidence Requirements").
3. **Find gaps grounded in evidence**, not generic best-practice filler. Every idea must trace to something actually found: a `TODO`/`FIXME`, a stubbed or `NotImplementedException` handler, an asymmetric CRUD surface (e.g. create+read but no update/delete), a spec marked incomplete, a user-facing flow that dead-ends, or a capability present in one module but conspicuously absent in a sibling module that shares its domain.
4. **Filter against what already exists or is already planned** — cross-check every candidate idea against `specs/` and the current code before including it.
5. **Group and present** the surviving ideas (aim for roughly 5–10; fewer, higher-confidence ideas beat a padded list) by category: **Feature gap**, **Improvement**, **Tech debt / risk** — use only the categories that actually have entries.
6. **Do not act on the list.** Present it, then stop. If the user picks one, tell them the next step is `speckit-specify <mô tả ý tưởng>` and let them invoke it — do not auto-invoke it yourself (Speckit's gates are user-driven, see `AGENTS.md`).

## Evidence Requirements

Each idea in the output must include:

- **Name** — a short, specific title (not "improve X" — "add refresh-token revocation on logout").
- **Evidence** — the concrete thing found (file path, code pattern, or spec gap) that justifies it. If none can be named, the idea doesn't belong in the list.
- **Why** — one sentence on the concrete consequence of the gap (what breaks, what's inconsistent, what a user can't do today).

Skip an idea entirely rather than including it with a weak or invented evidence line.

## Common Rationalizations

- *"This is a well-known best practice, everyone needs it."* — Not evidence. If it isn't visibly missing or inconsistent in **this** repo, it doesn't belong on this list. Generic advice is what makes ideation lists get ignored.
- *"I'll list everything I can think of, more options are better."* — A 20-item list of shallow ideas gets skimmed and discarded; a 6-item list of specific, evidenced ideas gets acted on. Cut ruthlessly.
- *"This idea is basically decided, I can just write the spec directly."* — Not this skill's job even when the idea is clear-cut; stop at the proposal and name `speckit-specify` as the next step instead of writing one.
- *"The repo doesn't use Speckit, so I can't check for duplicates."* — Check the code and README/docs instead; the absence of `specs/` changes the source of truth, not whether the duplicate-check happens.

## Red Flags

- An idea with no cited file, code pattern, or spec reference behind it.
- Any idea that duplicates something already in `specs/` as done or in progress.
- Any idea that a fetched `constitution.md` would rule out.
- Writing or editing `spec.md`, code, or any other file as part of this skill's own output.
- A list padded past ~10 items to look thorough.

## Verification

- [ ] Target repo was explicitly resolved (cwd, named repo, or asked when ambiguous).
- [ ] `specs/` (if present) and `constitution.md` (if present) were read before proposing anything.
- [ ] Every listed idea cites concrete evidence from the repo, not generic advice.
- [ ] No listed idea duplicates an existing or in-progress spec.
- [ ] The list stopped at proposal — no spec, file, or code was created; `speckit-specify` was named as the next step, not invoked.
