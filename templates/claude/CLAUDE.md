# CLAUDE.md

Project root: `<PROJECT_ROOT>`.

This file is loaded in every Claude Code session. Keep it short and only include rules that are always true for this project.

## Language

- Trả lời và ghi chú bằng tiếng Việt có dấu. Giữ nguyên tên file, command, package, API, framework và thuật ngữ kỹ thuật bằng English.

## Source Of Truth

- Do not edit generated runtime files under `.claude/skills`, `.claude/agents`, or `.claude/commands` directly.
- Shared skills, agents, commands, hooks, and templates must be edited at their declared source path, then synced.
- Personal notes belong in `CLAUDE.local.md`, which must stay ignored by git.

## Workflow

- Write or update `SPEC.md` before non-trivial feature work.
- Use one verify command before finishing a coding task: `powershell -NoProfile -File scripts/verify.ps1`.
- Put module-specific rules in `src/<module>/CLAUDE.md` instead of growing this root file.

## Task Docs

- Git conventions: `@docs/git-instructions.md`
