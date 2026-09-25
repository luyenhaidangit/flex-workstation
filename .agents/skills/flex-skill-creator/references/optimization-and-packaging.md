# Optimization & Packaging — making the skill trigger reliably and shipping it

Read this at Steps 10–11, and whenever you're updating an existing installed skill. Two jobs: tune the `description` so the skill fires when it should, and bundle the skill so the user can install it.

## How skill triggering works

The `description` field is the *only* thing Claude sees when deciding whether to consult a skill — it's the always-loaded metadata tier (see `skill-anatomy.md`). So the description carries the entire triggering burden, and getting it right is high-leverage.

Two facts shape good triggering:

- **Claude under-triggers by default** — it tends to *not* reach for a skill even when one would help. Counter this by making descriptions slightly *pushy*: name concrete phrasings and contexts, and explicitly say "use this even if the user doesn't say 'X'." Compare the weak "How to build a dashboard for internal data" with the stronger "...use this whenever the user mentions dashboards, data visualization, internal metrics, or wants to display company data, even if they don't explicitly ask for a 'dashboard.'"
- **Claude only consults skills for tasks it can't trivially handle.** A one-step request ("read this PDF") may not trigger any skill no matter how well the description matches, because Claude just does it directly. Substantive, multi-step, or specialized requests trigger reliably when the description matches. Keep this in mind when judging whether a "miss" is a description problem or just an easy task.

## Optimizing the description

The goal is a description that fires on the should-trigger cases and stays quiet on the near-misses.

**Step 1 — Build a trigger-eval set.** Write ~20 realistic queries split between should-trigger and should-not-trigger. For a skill targeting `.agents/skills/` (this repo), commit the set to `.agents/skills/<skill-name>/evals/trigger-eval.json` per `evaluation-and-iteration.md` so it's a reusable baseline for the next optimization pass rather than a one-off scratch file:

```json
[
  { "query": "the user prompt", "should_trigger": true },
  { "query": "another prompt",  "should_trigger": false }
]
```

Make them concrete and specific — file paths, real context about the user's job, column names, company names, casual phrasing, the odd typo. Focus on edge cases, not clear-cut ones.
- **Should-trigger (8–10):** vary the phrasing (formal and casual), include cases where the user never names the skill or file type but clearly needs it, and cases where this skill competes with another but should win.
- **Should-not-trigger (8–10):** the valuable ones are *near-misses* — queries that share keywords or concepts but actually need something else. Avoid obviously-irrelevant negatives ("write a fibonacci function" tests nothing for a PDF skill); the negatives should be genuinely tricky.

**Step 2 — Review the set with the user.** Bad eval queries produce a bad description, so let the user sign off, edit, toggle, add, or remove entries before optimizing.

**Step 3 — Optimize by hand.** This workspace has not ported the automated loop script (`scripts.run_loop`, from Anthropic's public skill-creator) — `flex-skill-creator`'s `scripts/` holds `sync-skills.ps1` (workspace wiring only), not this one. Don't spend a step checking for it; go straight to the manual pass: walk the eval set, predict for each whether the current description would trigger, find the misses, and rewrite the description to catch the should-triggers and exclude the near-misses — applying the pushiness and "Claude under-triggers" lessons above. Then re-walk the set to confirm.

**Step 4 — Apply.** Put the chosen description in the SKILL.md frontmatter and show the user a before/after (and the scores, if you have them).

## Packaging

**Note:** this is for producing an installable `.skill` bundle for a skill living outside this repo (e.g. the user's personal `~/.claude/skills/`). A skill targeting `.agents/skills/` in this repo lives and is distributed as tracked source (git + the `.claude/skills/` junction) — it is not packaged this way.

This workspace has not ported `scripts.package_skill` either — same story as Step 3 above, `flex-skill-creator`'s `scripts/` doesn't hold it — skip checking for it. Zip the skill folder directly (`zip -r <skill-name>.skill <path/to/skill-folder>` or equivalent) and point the user to the resulting file's path so they can install it. If you have a `present_files`-style tool, present the `.skill` file directly.

## Updating an existing installed skill

When the user wants to update a skill that's already installed (rather than create a new one):

- **Preserve the original name.** Use the existing directory name and `name:` frontmatter field unchanged. If the installed skill is `research-helper`, the output is `research-helper.skill`, never `research-helper-v2`.
- **Copy to a writeable location before editing.** The installed path may be read-only. Copy to e.g. `/tmp/<skill-name>/`, edit there, and package from the copy.
- **Stage in `/tmp/` when packaging manually**, then move to the output directory — direct writes to protected paths may fail on permissions.
