# Evaluation & Iteration — proving the skill works and making it better

Read this at Steps 8–9, when the user wants to validate a skill rather than just generate it. The loop is: write test cases → run the skill on them → review the outputs with the user → improve the skill → rerun → repeat until satisfied.

The mechanics differ by platform. **Claude.ai is the default below** because that's the most common environment; subagent-based platforms (Claude Code, Cowork) get a richer harness, noted in "Platform variations."

## Writing test cases

After the draft exists, come up with 2–3 realistic test prompts — the kind of thing a real user would actually type, with concrete detail (file names, real-sounding context, casual phrasing), not sanitized abstractions. Share them first: "Here are a few test cases I'd like to try — do these look right, or want to add any?" Then run them.

A test prompt must be substantive enough that Claude would genuinely benefit from the skill. Trivial one-step prompts ("read this file") are poor tests — Claude handles them directly and the skill may not even engage.

If you're tracking these in a file, a minimal shape is:

```json
{
  "skill_name": "example-skill",
  "evals": [
    { "id": 1, "prompt": "User's task prompt", "expected_output": "What a good result looks like" }
  ]
}
```

## Running the test cases (Claude.ai)

Claude.ai has no subagents, so run tests **inline, one at a time**:

1. Read the skill's SKILL.md.
2. Follow its instructions to complete the test prompt yourself, producing the real output.
3. If the output is a file the user needs to see (a `.docx`, `.xlsx`, chart, etc.), save it to the filesystem and tell them where, so they can open and inspect it.

This is less rigorous than an independent agent running the skill blind — you wrote it and you're running it, so you have full context — but it's a solid sanity check, and the human review step compensates. Skip baseline ("without skill") runs and skip quantitative benchmarking on Claude.ai; they rely on independent baseline comparisons that aren't meaningful when you're both author and runner.

## Reviewing outputs with the user

Present results directly in the conversation. For each test case, show the prompt and the output. Where the output is a file, point the user to it for download. Then ask for feedback inline: "How does this look? Anything you'd change?"

Empty/positive feedback means it's fine — focus your energy on the cases where the user had specific complaints.

## Improving the skill — the heart of the loop

This is where the real value is created. When rewriting based on feedback:

1. **Generalize from the feedback.** The skill will run across thousands of prompts; you iterate on a handful only because it's fast. If you fix the skill so it only works for these examples, it's useless. Resist fiddly overfit patches and oppressive MUSTs. For a stubborn issue, try a different framing or metaphor, or recommend a different working pattern — it's cheap to try and often lands better than another constraint.

2. **Keep the prompt lean.** Cut anything not pulling its weight. If a part of the skill is making the model waste time on unproductive steps, remove it and see what happens.

3. **Explain the why.** Even when feedback is terse or frustrated, understand the underlying need and encode *that* understanding, with its rationale, into the instructions. Caps-locked ALWAYS/NEVER and rigid structures are a yellow flag — reframe with reasoning instead. It's more humane and more effective.

4. **Look for repeated work across runs.** If every test run independently wrote a similar helper script or took the same multi-step approach, that's a signal to bundle a script (`scripts/`) so future invocations don't reinvent it.

Take your time here — thinking is not the bottleneck. Write a draft revision, then re-read it fresh and improve it. Get into the user's head: what do they actually want and need?

## The iteration loop

After improving the skill:

1. Apply the changes.
2. Rerun the test cases and produce fresh outputs.
3. Show the user the new outputs (and, helpfully, what changed since last time).
4. Read the feedback, improve again.

Keep going until the user says they're happy, the feedback is all positive/empty, or you've stopped making meaningful progress. Then optionally expand the test set and try once more at a larger scale to catch overfitting.

## Platform variations

**Claude Code / Cowork (have subagents):** the richer harness becomes available. For each test case you can spawn two subagents in the same turn — one *with* the skill, one *without* (the baseline) — so the comparison is independent. Organize results under a `<skill-name>-workspace/` sibling directory, by iteration (`iteration-1/`, `eval-0/`, ...). You can then grade objective assertions, aggregate a quantitative benchmark (pass rate, time, tokens), and generate the eval viewer for the human with `eval-viewer/generate_review.py` — always generate the viewer for the human to inspect outputs *before* you start critiquing them yourself, rather than hand-rolling HTML. In Cowork (no display) write the viewer as a standalone file with `--static <path>` and hand the user a link.

  - **When improving an existing skill on these platforms**, snapshot the old version first (`cp -r <skill-path> <workspace>/skill-snapshot/`) and use the snapshot as the baseline, so you can tell whether the new version is actually better.
  - **Blind comparison** (optional, subagents only): for a rigorous "is the new one really better?" check, give two outputs to an independent agent without telling it which is which and let it judge, then analyze why the winner won. Most skills don't need this; the human review loop is usually enough.

If timeouts make parallel subagents painful, fall back to running the test prompts in series.

The judgment, generalize-don't-overfit, and lean-prompt principles above apply identically on every platform — only the running and reviewing machinery changes.
