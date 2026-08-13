# Codebase Conventions — for any code-related generated skill

Read this when the skill being created touches code (development, codebase analysis, debugging, architecture review, code review, refactoring). Fold the relevant items into the generated skill's principles, mandatory checks, and anti-patterns — not as a copy-paste block, but selected and adapted to the specific skill. A migration-reviewer skill cares about different items than a dependency-audit skill.

The unifying idea: code lives in an existing, evolving codebase. A change is good not only if it works, but if it leaves the codebase **easier to extend than before** and surprises no one who reads it later.

## Respect what's already there

- **Existing conventions win.** Match the codebase's naming, structure, formatting, and idioms even when they differ from your personal preference. Consistency is worth more than your favorite style. Detect the convention from nearby code before introducing anything.
- **File placement.** New code goes where a reader would expect to find it, following the project's existing layering (e.g., handlers vs. services vs. repositories). Don't drop a new module at the root because it's convenient.
- **Naming conventions.** Follow the project's casing and naming patterns for files, types, functions, and constants. A name should describe intent, not implementation.

## Structural discipline

- **Dependency direction.** Dependencies point inward/downward consistently (e.g., UI → service → data, never the reverse). Flag and avoid cycles and back-references that violate the project's layering.
- **Interface / service separation.** Keep the contract (interface) separate from the implementation so callers depend on the abstraction, not the concretion. Don't leak implementation details across the boundary.
- **No god services.** Watch for a class/module that keeps accreting unrelated responsibilities. If a unit does five unrelated things, that's a smell — split by responsibility. Prefer adding to a focused unit over bloating a central one.
- **Constants and configuration.** Magic numbers and strings become named constants or config. Environment- or deployment-specific values go in configuration, not source. A literal that appears twice, or that someone might want to change, is a constant.

## Avoid the classic traps

- **No hardcoding.** Don't bake in values that vary by environment, user, or deployment (URLs, paths, credentials, limits). Pull them from config/constants. Hardcoded secrets are a hard stop.
- **No duplicate logic.** Before writing a function, check whether the behavior already exists. Duplicated logic drifts out of sync and multiplies bugs. Reuse or extract a shared helper — but see the next point.
- **No premature/unnecessary abstraction.** Don't build a framework for a single use. Three concrete usages is a reasonable bar before extracting an abstraction; one is usually too early. An abstraction that wraps one caller adds indirection without payoff. Inline-and-obvious beats clever-and-indirect.
- **No unnecessary coupling.** A change in one module shouldn't force changes in unrelated ones. Keep modules talking through narrow, stable interfaces.

## Forward-looking

- **Future extensibility.** Leave a clear seam where the next likely change will go, without building it speculatively. The goal is "easy to extend when needed," not "pre-built for every imagined future."
- **Production-readiness.** Account for error handling, edge cases, observability (logging where it matters), and failure modes appropriate to the project's maturity. Don't gold-plate a prototype, but don't ship code that ignores the unhappy path in production code.

## How to use these in a generated skill

- Turn the relevant items into **mandatory checks** ("verify no hardcoded config values were introduced") and **anti-patterns** ("god service: piling unrelated methods onto a central class — split by responsibility instead").
- For a **review/analysis** skill, these are the lens it applies.
- For a **generation/implementation** skill, these are the constraints it codes within.
- Always tie the check back to *why* it matters in that skill's context, so the rule is followed with understanding rather than rote.
