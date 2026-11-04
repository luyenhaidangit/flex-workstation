---
name: flex-repo-scope
description: Decides which Flex child repos a request actually needs before any is cloned or attached in a cloud session, using the `scope` field of each entry in workstation.json, and reports a clone plan for confirmation. Use when working in a cloud session where child repos listed in workstation.json are not yet on disk and the task would read or change code in one of them, or when a task turns out to need an additional child repo mid-way.
---

# Flex Repo Scope

## Overview

`flex-workstation` is a coordination repo. Real code lives in independent child repos declared in `workstation.json`. A cloud session starts with only the workstation cloned, and each child repo must be attached (`add_repo`) and cloned on demand. Cloning all of them is slow and costs a permission prompt per repo, while cloning too few makes the agent edit blind. This skill chooses the smallest correct set and states it before acting.

The `scope` field in each `workstation.json` entry is the single source for what a repo owns. This skill reads it; it does not duplicate it.

## When to Use

- A cloud session task names or implies code in a child repo (UI, auth, gateway, migration, k8s, ...) that is not on disk yet.
- A task already in progress turns out to need another child repo (re-run the gate for the added repo only).
- The user asks which repos a request touches.

Do not use it for work entirely inside the workstation (docs, skills, `.claude/`), for local sessions where `SYNC_WORKSPACE.cmd` already cloned everything, or to add or change manifest entries (use `flex-repo-onboarding`).

## Core Process

### 1. Read the scope map

Read `repositories.items` in `workstation.json`: `name`, `url`, `scope`. List the folders already present under the workstation root and skip repos already cloned. If an entry has no `scope`, fall back to the Projects table in `docs/architecture/system-map.md` and say the entry lacks one.

### 2. Classify each repo for this request

| Group | Meaning | Action |
| --- | --- | --- |
| Edit | Code will be changed here | Attach and clone |
| Read | Only a contract, config or example is needed | Prefer reading single files via the GitHub MCP file tool; clone only if many files are needed |
| Skip | Not related | Do nothing |

Match on what the change touches, not on the words used. A UI task that adds a field usually needs the frontend (Edit) and the backend service that serves it (Read or Edit); a schema change adds `flex-database` and the service that consumes it. When the request is ambiguous, ask instead of widening the set.

### 3. Report the plan before cloning

```text
Repo plan
- Edit: <repos or none>
- Read: <repos or none>
- Skip: <repos, one clause why>
- Assumptions: <inferences the user should correct>
```

Keep it short. Wait for correction only when an assumption is uncertain or the set is larger than two repos; otherwise proceed.

### 4. Attach and clone, one repo at a time

For each Edit repo: `add_repo` (with `access: push` only when the session must push), clone from the manifest `url` into `<workstation root>/<name>` so it stays ignored by the workstation's git, then `register_repo_root` so its own `CLAUDE.md` and skills load. If `add_repo` is denied, relay the reason and continue with what is available; do not work around the denial.

### 5. Keep changes in the right repo

Edits and commits for a child repo belong to that repo's own branch and pull request. Ask for the branch name before pushing a child repo; the session branch designated for the workstation does not apply to it. Do not touch the workstation for a request that belongs to a child repo.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Clone everything so nothing is missing." | Slow, one prompt per repo, and most tasks touch one or two. Re-run the gate when a new need appears. |
| "The folder name tells me what the repo does." | `scope` was written to disambiguate; read it, especially for `flex-environment` vs `flex-k8s`. |
| "I can read the whole repo through the file API instead of cloning." | Fine for a few files; for edits or wide search it is slower and cannot run tests. Clone it. |
| "The user said 'the frontend', so skip the plan." | The plan is how a wrong inference gets caught before a clone. One line is enough. |

## Red Flags

- Cloning a repo that is not in `workstation.json`.
- Editing a child repo's files through the workstation branch or PR.
- Attaching repos before the plan was stated.
- Ignoring a missing `scope` instead of reporting it.
- Working around a denied `add_repo`.

## Verification

- [ ] Plan listed Edit, Read and Skip with assumptions before any `add_repo`.
- [ ] Only repos declared in `workstation.json` were attached.
- [ ] Each cloned repo sits at `<workstation root>/<name>` and was registered with `register_repo_root`.
- [ ] Child-repo changes went to that repo's own branch, with the branch name confirmed.
- [ ] A mid-task need for another repo re-ran this gate for that repo only.
