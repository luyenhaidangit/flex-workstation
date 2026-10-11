---
name: flex-prod-troubleshooting
description: Diagnoses production incidents on Flex servers by SSH-ing through WSL with read-only commands first, then reporting evidence and proposing a fix. Use when the user reports a production error, outage, 5xx, slow response, unhealthy container, failed deployment, or asks to check logs or state on a prod server.
---

# Flex Production Troubleshooting

## Overview

Investigate a live production issue from the Windows workstation by running
diagnostic commands on the server through WSL (`wsl -d <distro> -- ssh ...`).
Evidence comes first, mutation comes last, and every mutation needs explicit user
confirmation.

Target setup: Windows host + WSL distro with an SSH key and `~/.ssh/config` aliases
named `flex-prod-<role>`. Real hosts, IPs, users and keys live only in WSL
`~/.ssh/config`, never in the repo, docs or command output. See
`references/ssh-config.example`.

This skill owns the incident diagnosis procedure. Infrastructure changes that follow
from the diagnosis (Compose, HAProxy, Jenkins, rollout) belong to
`flex-devops-engineering`; code or schema fixes belong to the relevant engineering skill.

## When to Use

- A user reports a production error, outage, 5xx, timeout, slow flow, or crashed or
  unhealthy container.
- A deployment just finished and behaves differently from staging.
- The user asks to check logs, disk, memory, service state, or container state on prod.

Do not use for local or development environments; use the local tooling directly.

## Core Process

### 1. Establish scope before touching the server

1. Identify symptom, first-seen time, affected service and user impact.
2. Pick the alias from `wsl -d <distro> -- bash -c "grep '^Host ' ~/.ssh/config"`.
   If no `flex-prod-*` alias exists, stop and point the user to
   `references/ssh-config.example`; never ask for or write credentials.
3. Check whether the cause is visible without the server first: recent commits,
   deployment history, repo logs, and the MCP database tools when connected.

### 2. Gather read-only evidence

Use the exact form below so the `prod-ssh-guard.js` hook can classify it:

```bash
wsl -d Ubuntu -- ssh -o BatchMode=yes flex-prod-<role> '<one command>'
```

- One simple command per call: no `;`, `&&`, pipes, redirects or `$(...)`. Bound
  output (`--tail 200`, `--since 30m`, `-n 200`).
- Preferred order: `docker ps` → `docker logs --tail 200 <name>` → `systemctl status
  <svc> --no-pager` → `journalctl -u <svc> -n 200 --no-pager` → `df -h`, `free -m`,
  `uptime` → `tail -n 200 /var/log/<file>`.
- Never stream (`-f`, `--follow`). Never read `.env`, key files or secret stores; do
  not `docker inspect` without need, because it prints environment variables.
- On Git Bash, set `MSYS_NO_PATHCONV=1` when the remote command contains `/var/log/...`.
- If a secret appears in output, do not repeat it in the report; mask it.

### 3. Form a hypothesis from evidence

State the timeline, the failing component, the evidence line that supports it, and what
would disprove it. Test a competing hypothesis with one more read-only command before
proposing a fix. Do not guess from a single log line.

### 4. Propose, then act only with confirmation

- Restart (`docker restart`, `systemctl restart`) is allowed only after the user
  confirms the exact service. The hook will prompt; still explain impact and
  rollback first.
- Anything beyond restart (deploy, config edit, delete, DB write, rollback) is out of
  scope: present the plan and hand it to the user or to `flex-devops-engineering`.
- After any mutation, re-check health and logs, then report observed results.

### 5. Report

Separate: symptom, evidence (commands and key lines, secrets masked), root cause
(confirmed or suspected), actions taken on prod (state "none" if none), recommended
follow-up and remaining risk.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "Restarting will probably fix it." | It destroys in-memory evidence and may hide the cause. Collect logs first. |
| "I'll chain commands to save calls." | Chained commands bypass the read-only classification and escalate to a prompt. Run them one by one. |
| "`cat .env` shows the config quickly." | It exposes secrets into the transcript. Ask the user for the specific non-secret value. |
| "`docker logs -f` will show the next error." | It never returns and blocks the session. Use `--since` and re-run. |
| "The hook allowed it, so it is safe." | The hook is a guardrail, not the boundary. The server user must be least-privilege. |

## Red Flags

- Running a mutating command on prod without explicit user confirmation.
- Real hostname, IP, user or key path written to a repo file or printed in the report.
- Streaming or unbounded log output.
- Root cause stated as fact with a single log line as evidence.
- Report claiming "fixed" without post-action health and log verification.

## Verification

- [ ] Symptom, time window and target service were stated before the first ssh call.
- [ ] Every ssh call used the standard `wsl ... -- ssh flex-prod-<role> '<cmd>'` form.
- [ ] Only read-only commands ran, apart from confirmed restarts.
- [ ] No secret was read, repeated or written to a file.
- [ ] Root cause is backed by evidence and a competing hypothesis was considered.
- [ ] Any prod mutation is listed in the report with before and after health.
