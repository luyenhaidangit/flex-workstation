# Session Retrospective — no-argument mode

Read this when `flex-skill-creator` is invoked with no argument and no described skill idea. Do **not** ask "what skill do you want to create?" — instead run a retrospective on the current conversation.

This mode only applies to a genuine bare invocation (the user typed something like `/flex-skill-creator` or "review this session" with nothing else attached). It does not apply when the router selected `flex-skill-creator` for an unrelated, concrete task (e.g. "create a skill for X") — that's normal design-front-end territory, not this mode.

If the conversation has been compacted/summarized before this point, the summary may be missing exact wording or turn order — scan what's actually available and say so rather than assuming you're seeing the full history.

**Goal**: find exchanges where the AI or a skill misread intent, did the wrong thing, or required correction, then translate each finding into a concrete improvement proposal for the responsible skill (or memory/CLAUDE.md).

## Step 1 — Scan for misalignment signals

Read the conversation and collect every exchange that shows one of these signals:

- **Explicit correction** — user said "không phải", "làm lại", "sai rồi", "that's not what I meant", "no don't", "undo that", or similar.
- **Unsolicited action** — AI did something the user did not ask for: added abstraction, refactored surrounding code, added comments, created extra files, pushed without being asked.
- **Wrong skill fired** — a skill triggered on a prompt it shouldn't have, or failed to trigger on one it should.
- **Silent assumption** — AI guessed instead of asking, and the guess was wrong (evidenced by a follow-up correction).
- **Repeated pattern** — the same type of correction or push-back appeared more than once in the session.

Only flag exchanges where the user *actually reacted* (corrected, objected, had to redo). Do not flag cases where the AI deviated but the user accepted the result.

## Step 2 — Categorize each finding

Focus on the most impactful 3–5 findings rather than enumerating every minor deviation — a wall of 15 nitpicks is as useless to the user as no findings at all. For each flagged exchange, output:

```
Exchange: [brief quote or description of what happened]
Caused by: [skill name, or "base AI behavior", or "CLAUDE.md rule"]
Category: wrong-scope | over-engineering | misread-intent | wrong-skill-fired | silent-assumption | other
Impact: [one sentence — what the user had to do to recover]
```

## Step 3 — Propose a targeted fix

For each finding, propose the minimal change that would prevent recurrence:

- **Which file** to edit (SKILL.md path, or memory file, or CLAUDE.md)
- **What to add/change/remove** — be specific: a new anti-pattern bullet, a tightened "When NOT to use" clause, an added clarification-gate question, a reworded rule
- **Why** this change prevents the specific misalignment (one sentence)

Resist proposing sweeping rewrites. A single well-placed anti-pattern bullet often fixes a repeating failure mode.

## Step 4 — Confirm and implement

Present all findings and proposals in one pass. Ask the user which ones to implement. Then execute the chosen changes using the normal skill-editing flow (respecting the git-source rule: edit `.agents/skills/` not `~/.claude/skills/`).

**Scope guard**: if the session shows no clear misalignment signals, say so briefly and offer to switch to normal skill-creation mode instead.
