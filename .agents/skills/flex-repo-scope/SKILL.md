---
name: flex-repo-scope
description: Decides which Flex child repos a request actually needs to read or change, using the `scope` field of each entry in workstation.json, so agents do not scan every repo. In a cloud session it also attaches and clones the chosen repos; locally it only prints the plan. Use when a task would read or change code in a child repo listed in workstation.json, or when a task turns out to need an additional child repo mid-way.
---

# Flex Repo Scope

## Overview

`flex-workstation` is a coordination repo. Real code lives in independent child repos declared in `workstation.json`. Scanning all of them wastes time and context. In a cloud session, which starts with only the workstation cloned, each child repo must also be attached (`add_repo`) and cloned on demand: cloning all of them is slow and costs a permission prompt per repo, while cloning too few makes the agent edit blind. This skill chooses the smallest correct set and states it before acting.

| Mode | Detect | Steps |
| --- | --- | --- |
| Local | `CLAUDE_CODE_REMOTE` is not `true` | 1-3 only: choose repos and print the plan, then read or search only those folders. No `add_repo`, no clone, no wait for confirmation. |
| Cloud | `CLAUDE_CODE_REMOTE=true` | All steps, including attach and clone. |

The `scope` field in each `workstation.json` entry is the single source for what a repo owns. This skill reads it; it does not duplicate it.

## When to Use

- A task names or implies code in a child repo (UI, auth, gateway, migration, k8s, ...), whether or not it is on disk yet.
- A task already in progress turns out to need another child repo (re-run the gate for the added repo only).
- The user asks which repos a request touches.
- A question, review or design discussion depends on how Flex currently runs (Nginx, Docker Compose, TLS, WAF, ingress, deploy, gateway), even with no change requested. Read the owning repo first; never infer current state from a skill description or general knowledge.

Do not use it for work entirely inside the workstation (docs, skills, `.claude/`) or to add or change manifest entries (use `flex-repo-onboarding`).

## Core Process

### 1. Read the scope map

Read `repositories.items` in `workstation.json`: `name`, `url`, `scope`. List the folders already present under the workstation root; in cloud mode skip repos already cloned, in local mode a missing folder is reported as "not cloned, run `SYNC_WORKSPACE.cmd`" instead of being cloned. If an entry has no `scope`, fall back to the Projects table in `docs/architecture/system-map.md` and say the entry lacks one. In cloud mode, an entry with `"cloudEnabled": false` is off for cloud sessions: put it in Skip with the reason "cloudEnabled=false", do not attach or clone it, and if the request truly needs it, tell the user instead of enabling it yourself. A missing `cloudEnabled` means `true`; local mode ignores the field.

### 2. Classify each repo for this request

| Group | Meaning | Action |
| --- | --- | --- |
| Edit | Code will be changed here | Attach and clone |
| Read | Only a contract, config or example is needed | Attach with read access, then read single files via the GitHub MCP file tool; clone only if many files are needed |
| Skip | Not related | Do nothing |

A request that only asks for analysis, explanation or review (no change to make) puts every relevant repo in Read by default. The GitHub MCP file tool is denied for a repo that is not attached to the session, so Read still needs `add_repo` (read access), but it skips the clone. Promote a repo to Edit only when a change is actually going to be made. In Read mode do not `git clone`: read the needed files with the GitHub MCP file tool (`get_file_contents`), and clone only if many files must be read.

Match on what the change touches, not on the words used. A UI task that adds a field usually needs the frontend (Edit) and the backend service that serves it (Read or Edit); a schema change adds `flex-database` and the service that consumes it. When the request is ambiguous, ask instead of widening the set.

### 3. Report the plan before cloning

```text
Repo plan
- Edit: <repos or none>
- Read: <repos or none>
- Skip: <repos, one clause why>
- Assumptions: <inferences the user should correct>
```

Print the plan before the first `add_repo`, even when every repo is Read-only, and attach only repos listed as Edit or Read. Keep it short. In local mode, stop here and use the plan to read only the listed repos. In cloud mode, wait for correction only when an assumption is uncertain or the set is larger than two repos; otherwise proceed.

When a Speckit feature is active (a `specs/<feature>/` directory exists for the task), also write the plan to `specs/<feature>/repos.md` using the same Edit/Read/Skip table, and update it whenever the gate re-runs. `speckit-plan` and `speckit-implement` read this file as the repo scope of the feature. Do not put it in `spec.md`, which stays business-only.

### 4. Attach and clone, one repo at a time (cloud mode only)

For each Edit repo: `add_repo` (with `access: push` only when the session must push), clone from the manifest `url` into `<workstation root>/<name>` so it stays ignored by the workstation's git, then `register_repo_root` so its own `CLAUDE.md` and skills load. If `add_repo` is denied, relay the reason and continue with what is available; do not work around the denial.

### 5. Keep changes in the right repo

Edits and commits for a child repo belong to that repo's own branch and pull request. Ask for the branch name before pushing a child repo; the session branch designated for the workstation does not apply to it. Do not touch the workstation for a request that belongs to a child repo.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Clone everything so nothing is missing." | Slow, one prompt per repo, and most tasks touch one or two. Re-run the gate when a new need appears. |
| "The folder name tells me what the repo does." | `scope` was written to disambiguate; read it, especially for `flex-environment` vs `flex-k8s`. |
| "I can read the whole repo through the file API instead of cloning." | Fine for a few files; for edits or wide search it is slower and cannot run tests. Clone it. |
| "It is only a design question, general knowledge is enough." | A design is only valid against the real topology. Attach the owning repo as Read, open the 1-3 relevant files, and state what was verified. Example: a WAF question needs `flex-environment` (`docker-compose.infra.yml`, `mounts/nginx/conf.d/`), not a guess. |
| "The user said 'the frontend', so skip the plan." | The plan is how a wrong inference gets caught before a clone. One line is enough. |

## Red Flags

- Cloning a repo that is not in `workstation.json`.
- Editing a child repo's files through the workstation branch or PR.
- Attaching repos before the plan was stated.
- Ignoring a missing `scope` instead of reporting it.
- Working around a denied `add_repo`.

## Verification

- [ ] Plan listed Edit, Read and Skip with assumptions before any `add_repo`.
- [ ] For an analysis-only request, no repo was cloned unless the user asked for changes.
- [ ] With an active Speckit feature, `specs/<feature>/repos.md` matches the final plan.
- [ ] Only repos declared in `workstation.json` were attached.
- [ ] Each cloned repo sits at `<workstation root>/<name>` and was registered with `register_repo_root`.
- [ ] Child-repo changes went to that repo's own branch, with the branch name confirmed.
- [ ] A mid-task need for another repo re-ran this gate for that repo only.
