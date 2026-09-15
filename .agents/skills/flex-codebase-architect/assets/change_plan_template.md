# Change Plan — <one-line title of the change>

> Fill this in BEFORE writing code. Placement, reuse, and abstraction decisions
> are cheapest to change while they're still words. Delete the guidance lines
> (the `>` quotes) in the final output. For a trivial change, collapse to a
> single Plan line plus the change.

## Change Plan
- **Goal:** <what this change accomplishes, one sentence>
- **Placement:** <file path(s)> — beside <existing sibling file/dir>, because <reason>
- **Reusing:** <existing functions/modules/interfaces being leveraged> (or "none found after searching")
- **Not abstracting yet:** <thing left inline> — would extract when <concrete trigger, e.g. "a 2nd real format appears">
- **Seams/boundaries touched:** <layer(s)>; dependency direction <inward/downward — confirmed>

## Changes
<the actual edits / diffs / new files>

## Decision Log
- **Placement:** <why here and not elsewhere>
- **Reuse vs. new:** <what was reused/extended, or why new code was justified>
- **Coupling/seam:** <interface introduced or avoided, and why>
- **Literals externalized:** <any magic value moved to config/constant, and where it now lives>

## Debt & Follow-ups
- <anything deliberately deferred> — revisit when <trigger>
- (Write "None." if there genuinely is none.)
