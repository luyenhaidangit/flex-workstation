# Touchpoints when registering a repo

Source of truth for the steps is `docs/checklists/new-service-checklist.md` (sections 1 and 4). This file only adds what that checklist does not say. It can lag behind reality, so confirm by searching the workstation root (excluding nested repos, `.git`, `specs`, `.tmp`) for the names of at least two existing manifest repos and taking the union of files found.

## Required — machine behavior (a miss is a silent failure)

| File | Entry | Automated by `scripts/add-repo.ps1` |
| --- | --- | --- |
| `workstation.json` | `{ "name", "url" }` appended to `repositories.items` | yes |
| `.gitignore` | `/<name>/` in the "Nested Flex repositories" block | yes |
| `.ignore` | `!/<name>/` so AI search still reaches the repo | yes |

## Documentation — drift, not breakage (manual)

| File | Entry |
| --- | --- |
| `docs/architecture/system-map.md` | Folder tree (section 2), "Manifest repo" table (section 3), "Projects" table (section 4) |
| `docs/setup/onboarding.md` | Nothing: its tree ends with `+-- ...` by design. Touch it only if the bootstrap flow changes |
| `README.md` | A link only if the new repo brings a doc that belongs in the index |

## Not touchpoints

- `.vscode/tasks.json` has git-status tasks for a few repos only; add one only if asked.
- `.claude/settings.json` has no per-repo entries.
- Any other file the search finds that lists repos counts as a touchpoint.

## Why the URL must equal `origin`

`scripts/sync-repositories.ps1` compares the manifest `url` to `git remote get-url origin` as plain strings. A difference such as a trailing `.git` makes it warn "origin differs" and skip the repo, including its pull. Use the exact form `origin` reports.
