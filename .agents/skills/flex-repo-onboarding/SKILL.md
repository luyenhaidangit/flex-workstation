---
name: flex-repo-onboarding
description: Registers a new or existing Git repo so flex-workstation manages it — declares it in workstation.json, keeps it out of the workstation's own git tracking while leaving it searchable by AI tools, and verifies the sync script accepts it. Use when the user asks to add a repo/project to the workstation, create a new project folder that the workstation should manage, or fix a repo that SYNC_WORKSPACE does not clone or that shows up as untracked.
---

# Flex Repo Onboarding

## Overview

`flex-workstation` coordinates several independent Git repos cloned into its root. A repo is "managed" only when every touchpoint agrees: the manifest declares it, the workstation's git ignores it, and AI-tool search ignore rules un-hide it. Missing one produces a quiet failure (not cloned on a fresh machine, shown as untracked, or invisible to search).

This skill is specific to this workspace. It does not scaffold the repo's contents (use `flex-codebase-architect` or the repo's own domain skill) and does not create the remote repository.

## When to Use

- "Thêm repo X vào workstation", "workstation cũng cần quản lý repo này".
- A new project folder was just created under the workstation root and must be tracked by the manifest.
- A repo exists in `workstation.json` but is untracked in `git status`, hidden from search, or not cloned by `SYNC_WORKSPACE.cmd`.

Do not use it to remove a repo, change an existing entry's `url`/`branch`, or sync/pull repos — those need their own confirmation.

## Core Process

### 1. Collect and confirm the entry

`AGENTS.md` requires asking before adding to `workstation.json`, because it changes what every machine clones. Establish:

- `name` — must equal the local folder name (it is used as the clone target) and contain no characters invalid in a Windows file name.
- `url` — the remote clone URL. If the user gave none, infer it only from the pattern of existing entries (same owner, same style), state it as an inference, and flag that the remote may not exist yet.
- `branch` — omit unless the user wants a non-default branch; the sync script clones the remote default otherwise.

Reject a duplicate `name` already present in the manifest.

### 2. Find the touchpoints

Read `docs/checklists/new-service-checklist.md` (sections 1 and 4) first: it is the workstation's own list of what to register and which docs to update, so follow it rather than restating it here. It can lag behind reality, so also confirm against the repo itself. Search the workstation root (excluding nested repos, `.git`, `specs`, `.tmp`) for the names of **at least two** existing manifest repos and take the union of files that list them; one name alone misses files that are only documented for some repos.

Required (machine behavior — omitting any one is a silent failure):

| File | Entry to add |
| --- | --- |
| `workstation.json` | `{ "name", "url" }` item appended to `repositories.items` |
| `.gitignore` | `/<name>/` in the "Nested Flex repositories" block |
| `.ignore` | `!/<name>/` so AI search still reaches the repo |

Documentation (drift, not breakage) — update only the parts that list repos:

| File | Entry to add |
| --- | --- |
| `docs/architecture/system-map.md` | Folder-tree snapshot (§2), "Manifest repo" table (§3) and "Projects" table (§4) |
| `docs/setup/onboarding.md` | Nothing — its tree ends with `+-- ...` by design; touch it only if the bootstrap flow changes |
| `README.md` | Link only if the new repo brings a doc that belongs in the index |

Not touchpoints: `.vscode/tasks.json` holds per-repo git-status tasks for a few repos only; add one only if asked. `.claude/settings.json` has no per-repo entries. If the search finds any other file that lists repos, treat it as a touchpoint too.

### 3. Edit surgically

- Append after the last existing entry; keep each file's current indentation and trailing-newline style. Preserve line endings — the repo normalizes to CRLF, so avoid rewriting whole files.
- Touch no other entry, ordering, or formatting.

### 4. Validate without side effects

- `workstation.json` parses as JSON.
- `git status` in the workstation shows only the touchpoint files modified and the new repo folder is not listed as untracked.
- Optionally confirm the sync script would accept the entry: name valid, URL non-empty. Do not run `SYNC_WORKSPACE.cmd` or `scripts/sync-repositories.ps1` unasked — they clone/pull over the network and may touch other repos.

### 5. Report

State which files changed, whether the remote exists (an unreachable URL makes a fresh-machine clone warn and skip, not abort), and the remaining manual steps, typically: create the remote, add `origin`, and push. Do not commit unless asked.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Adding it to `workstation.json` is enough." | Without `.gitignore` the workstation sees an untracked folder; without `.ignore` AI tools skip it; without `system-map.md` the docs silently drift. |
| "The checklist says `.gitignore` already has a general rule." | It does not — every repo is listed individually. Verify with `git status` instead of trusting the checklist. |
| "I'll guess the URL, it's obviously the same owner." | It may be right, but a wrong URL fails silently on other machines. Mark it as inferred and say whether the remote exists. |
| "Run the sync script to prove it works." | It clones and pulls over the network across every repo. Static validation is enough. |
| "Folder name and repo name can differ." | The sync script clones into `<destinationRoot>/<name>`; a mismatch creates a second folder. |

## Red Flags

- Editing an existing entry's `url` or `branch` while "just adding" a repo.
- Reformatting `workstation.json` or rewriting a whole ignore file, producing a noisy diff.
- Adding a submodule or subtree instead of a plain manifest entry.
- Reporting the repo as "managed" without checking `.ignore` and `git status`.
- Committing or pushing the workstation change without being asked.

## Verification

- [ ] Name, URL and branch were confirmed with the user, or the inferred URL was flagged.
- [ ] `name` is unique in the manifest and equals the folder name.
- [ ] Every required touchpoint contains the new entry, and `system-map.md` lists it in all three places.
- [ ] `workstation.json` is valid JSON and existing entries are unchanged.
- [ ] `git status` does not list the new repo folder as untracked.
- [ ] No sync/clone/pull command was run without being requested.
- [ ] Remaining manual steps (remote creation, `origin`, push) were reported.
