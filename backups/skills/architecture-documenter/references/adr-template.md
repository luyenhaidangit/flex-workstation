# ADR Template

Use this when an architecture document reveals an important decision that should be recorded separately.

```markdown
# ADR-XXX: <Decision Title>

## Status

Proposed | Accepted | Deprecated | Superseded by ADR-XXX

## Date

YYYY-MM-DD

## Context

Describe the context that led to this decision:

- What problem are we solving?
- What business or technical constraints matter?
- Which services/modules/teams are affected?
- What legacy constraints or operational risks exist?

## Decision

We decided to <clear decision>.

## Options Considered

### Option 1: <name>

Pros:

- <pro>

Cons:

- <con>

### Option 2: <name>

Pros:

- <pro>

Cons:

- <con>

## Consequences

Positive:

- <benefit>

Negative:

- <trade-off>

Operational:

- <deployment/testing/monitoring impact>

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| <risk> | <impact> | <mitigation> |

## Validation Plan

This decision is considered valid if:

- <test/metric/review criterion>

## Related Documents

- <architecture doc>
- <ticket/PR/spec>
```
