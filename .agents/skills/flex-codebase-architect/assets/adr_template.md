# ADR <NNNN>: <short decision title>

> An Architecture Decision Record. Use this — not just the inline Decision Log —
> when a change introduces a genuinely new boundary, layer, dependency, or
> pattern that future maintainers will need the *reasoning* for, not just the
> *result*. Save as `docs/adr/NNNN-<kebab-title>.md` (or wherever the repo keeps
> ADRs; check first). Most changes do NOT need an ADR — reserve it for decisions
> that are expensive to reverse.

- **Status:** Proposed | Accepted | Superseded by ADR-<n>
- **Date:** <YYYY-MM-DD>
- **Deciders:** <who>

## Context
<The forces at play: the requirement, the constraints, what in the existing
codebase made this decision necessary. State the problem, not the solution.>

## Decision
<The change being made, stated plainly. "We will …">

## Alternatives considered
- **<Option A>** — <why rejected; e.g. "added a generic plugin layer for one
  caller — premature abstraction">
- **<Option B>** — <why rejected>

## Consequences
- **Positive:** <what gets easier; which future changes this enables>
- **Negative / trade-offs:** <new indirection, learning cost, debt accepted>
- **Revisit when:** <the condition that would make us reconsider this>
