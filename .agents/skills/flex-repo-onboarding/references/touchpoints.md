# Touchpoints when registering a repo

Source of truth for the steps is `docs/checklists/new-service-checklist.md` (sections 1 and 4). This file only adds what that checklist does not say. It can lag behind reality, so confirm by searching the workstation root (excluding nested repos, `.git`, `specs`, `.tmp`) for the names of at least two existing manifest repos and taking the union of files found.

## Required — machine behavior (a miss is a silent failure)

| File | Entry | Automated by `scripts/add-repo.ps1` |
| --- | --- | --- |
| `workstation.json` | `{ "name", "url" }` (plus optional `"branch"`) appended to `repositories.items` | yes |
| `.gitignore` | `/<name>/` appended at the end of the file | yes |
| `.ignore` | `!/<name>/` appended at the end, so AI search still reaches the repo | yes |

## Documentation — drift, not breakage (manual)

The files and sections to update are listed in `docs/checklists/new-service-checklist.md` section 4; follow that. What it does not say:

- `system-map.md` section 4 ("Projects") ends each row with an evidence tag in the status column: `Confirmed` (cite the file that proves it, e.g. ``Confirmed — xem `<repo>/README.md` ``) or `Inferred`. Copy the style of a neighboring row and take role and technology from the new repo's own README; use `Inferred` when only guessing.
- `docs/setup/onboarding.md` needs no row per repo — its tree ends with `+-- ...` by design.

## Not touchpoints

- `.vscode/tasks.json` has git-status tasks for a few repos only; add one only if asked.
- `.claude/settings.json` has no per-repo entries.
- Any other file the search finds that lists repos counts as a touchpoint.

## Why the URL must equal `origin`

`scripts/sync-repositories.ps1` compares the manifest `url` to `git remote get-url origin` as plain strings. A difference such as a trailing `.git` makes it warn "origin differs" and skip the repo, including its pull. Use the exact form `origin` reports.
