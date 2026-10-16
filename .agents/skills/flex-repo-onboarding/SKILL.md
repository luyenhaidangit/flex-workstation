---
name: flex-repo-onboarding
description: Registers a new or existing Git repo so flex-workstation manages it — declares it in workstation.json, keeps it out of the workstation's own git tracking while leaving it searchable by AI tools, and verifies the manifest URL matches the repo's origin. Use when the user asks to add a repo/project to the workstation, create a new project folder that the workstation should manage, or fix a repo that SYNC_WORKSPACE does not clone, does not pull, or that shows up as untracked.
---

# Flex Repo Onboarding

## Overview

`flex-workstation` coordinates independent Git repos cloned into its root. A repo is "managed" only when the manifest declares it, the workstation's git ignores it, AI-tool search un-hides it, and the manifest URL matches the repo's `origin`. Missing one produces a quiet failure: not cloned, not pulled, shown as untracked, or invisible to search.

This skill is specific to this workspace. It does not scaffold the repo's contents (use `flex-codebase-architect` or the repo's domain skill) and does not create the remote.

## When to Use

- "Thêm repo X vào workstation", "workstation cũng cần quản lý repo này".
- A new project folder was just created under the workstation root and must be managed.
- A repo is in `workstation.json` but untracked in `git status`, hidden from search, or skipped by `SYNC_WORKSPACE.cmd`.

Do not use it to remove a repo, change an existing entry's `url`/`branch`, or sync/pull repos — those need their own confirmation.

## Core Process

### 1. Collect and confirm the entry

`AGENTS.md` requires asking before changing `workstation.json`, because it changes what every machine clones. Establish:

- `name` — equals the folder name and is valid as a Windows file name.
- `url` — if the folder already exists, take it from `git -C <name> remote get-url origin`. Only when there is no repo yet, infer it from existing entries (same owner and style) and say it is an inference.
- `branch` — omit unless the user wants a non-default branch.

### 2. Register the required touchpoints

Run `scripts/add-repo.ps1 -Name <name> -Url <url>`. It rejects a duplicate name, embedded credentials, and a URL that differs from the local `origin`; it appends to `workstation.json`, `.gitignore` and `.ignore` as raw text so line endings and other entries stay untouched, and it checks the JSON before writing. Hand-edit only if the script cannot run, following `references/touchpoints.md`.

### 3. Update the documentation touchpoints

The script cannot edit prose. Update `docs/architecture/system-map.md` in all three places (tree, manifest table, projects table) as listed in `references/touchpoints.md`; fill the role and technology from the repo's own README, not from guesses.

### 4. Validate

- `workstation.json` parses and existing entries are unchanged in `git diff`.
- `git status` does not list the new repo folder as untracked.
- The manifest URL equals `origin` character for character.
- Do not run `SYNC_WORKSPACE.cmd` or `scripts/sync-repositories.ps1` unasked: they clone and pull over the network across every repo.

### 5. Report

List the files changed. Say whether the remote exists (`git ls-remote <url>` is a safe read-only check) and the manual steps left, typically creating the remote, adding `origin`, and pushing. Do not commit unless asked.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Adding it to `workstation.json` is enough." | Without `.gitignore` the folder shows as untracked; without `.ignore` AI tools skip it; without `system-map.md` the docs drift. |
| "The URL without `.git` is the same repo." | The sync script compares strings. A mismatch with `origin` skips the pull with only a warning. |
| "I'll guess the URL from the pattern." | Guessing produced the wrong `.git` form before. Read `origin` when the folder exists. |
| "Run the sync script to prove it works." | It clones and pulls across every repo over the network. Static validation is enough. |
| "Folder name and repo name can differ." | The sync script clones into `<root>/<name>`; a mismatch creates a second folder. |

## Red Flags

- Editing an existing entry's `url` or `branch` while "just adding" a repo.
- Rewriting a whole file and producing a noisy diff or mixed line endings.
- Adding a submodule or subtree instead of a manifest entry.
- Calling the repo "managed" without checking `.ignore`, `git status` and the `origin` match.
- Committing or pushing the workstation change without being asked.

## Verification

- [ ] Name, URL and branch were confirmed with the user, or the inferred URL was flagged.
- [ ] `scripts/add-repo.ps1` succeeded (or the manual edit followed `references/touchpoints.md`).
- [ ] `system-map.md` lists the repo in the tree, manifest table and projects table.
- [ ] Manifest URL equals `origin`; `git status` shows no untracked repo folder.
- [ ] No sync/clone/pull command ran without being requested.
- [ ] Remaining manual steps were reported.
