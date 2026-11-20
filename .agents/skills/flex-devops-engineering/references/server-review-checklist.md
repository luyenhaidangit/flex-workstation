# Server Review Checklist

Read-only checklist for reviewing a Linux server (VPS or bare metal) that runs
containerized services behind a reverse proxy. Use it for a periodic health check, a
pre-launch review, or after a suspected exposure. It finds what should be done; it does
not change the server.

## How to run it

1. Confirm the target host, environment, and that the request authorizes inspecting it.
   Reach the host the way the workspace's production-access skill describes; do not invent
   a new access path.
2. Run only the read-only commands below. Any fix (open/close a port, edit `sshd_config`,
   renew a certificate, prune images) is a proposal: list it, ask, then act.
3. Never print secret values. Check that a secret exists, its file mode, and where it is
   referenced; do not paste `.env` contents or `docker inspect` environment blocks into
   the report.
4. Mark an item `Đạt` only with command output as evidence. If a command could not run
   (no access, tool missing, not applicable), mark it `Chưa xác minh` and say why. Silence
   is not a pass.
5. Check the public view from outside the server as well as the inside view. An exposure
   that the server's own firewall hides can still be reachable through Docker-published
   ports or a stale DNS record.

## Checklist

Priority: **Cao** = exposes the server or risks data loss now; **TB** = degrades safety or
recoverability over time; **Thấp** = hygiene.

### A. Network exposure and origin

| # | Check | Evidence command | Priority |
| --- | --- | --- | --- |
| A1 | Only intended ports listen on a public interface (typically 80/443 and a restricted SSH). | `ss -tlnp` | Cao |
| A2 | Firewall is active and default-deny inbound. | `ufw status verbose` or `nft list ruleset` | Cao |
| A3 | Docker-published ports are intentional: Docker inserts its own rules and bypasses `ufw`. Databases, brokers, admin UIs, and metrics are not published to `0.0.0.0`. | `docker ps --format '{{.Names}}\t{{.Ports}}'` | Cao |
| A4 | Origin IP is not exposed when a CDN/proxy is in front: no DNS record (A, AAAA, MX, `mail`, `ftp`, old subdomains) resolves straight to the server, and the firewall admits only the CDN's ranges on 80/443. | `dig +short <domain> <sub>.<domain> MX` from outside | TB |
| A5 | Admin consoles (container UIs, monitoring, CI) sit behind the proxy with authentication or an IP allowlist, not on a raw port. | A1 + A3 output, then request the URL from outside | Cao |

### B. Access and accounts

| # | Check | Evidence command | Priority |
| --- | --- | --- | --- |
| B1 | SSH uses keys only; root login with a password is off. | `sshd -T \| grep -Ei 'permitrootlogin\|passwordauthentication\|pubkeyauthentication'` | Cao |
| B2 | SSH access is limited (non-default port is optional; `AllowUsers`/allowlist or brute-force protection is the real control). | `sshd -T \| grep -Ei 'port\|allowusers'`; `fail2ban-client status` | TB |
| B3 | Only expected accounts have sudo; no shared or stale accounts. | `getent group sudo`; `awk -F: '$3>=1000{print $1}' /etc/passwd` | TB |
| B4 | Recent logins and failed attempts look expected. | `last -n 20`; `lastb -n 20` | Thấp |
| B5 | Application containers do not run privileged, as root without need, or with the Docker socket mounted. | `docker ps -q \| xargs docker inspect -f '{{.Name}} priv={{.HostConfig.Privileged}} user={{.Config.User}}'` | TB |

### C. OS and patching

| # | Check | Evidence command | Priority |
| --- | --- | --- | --- |
| C1 | OS release is still supported. | `lsb_release -ds` or `cat /etc/os-release` | TB |
| C2 | Security updates are applied or scheduled; automatic security updates are on. | `apt list --upgradable 2>/dev/null \| head`; `systemctl is-enabled unattended-upgrades` | TB |
| C3 | No pending reboot after a kernel update. | `ls /var/run/reboot-required` | Thấp |
| C4 | Clock is synchronized (TLS, logs, and tokens depend on it). | `timedatectl` | Thấp |

### D. TLS and secrets

| # | Check | Evidence command | Priority |
| --- | --- | --- | --- |
| D1 | Certificate is valid with enough days left, and renewal is automatic. | `openssl s_client -connect <host>:443 -servername <host> </dev/null 2>/dev/null \| openssl x509 -noout -dates`; `systemctl list-timers \| grep -i certbot` | Cao |
| D2 | HTTP redirects to HTTPS; weak protocols are off. | `curl -sI http://<host>` | TB |
| D3 | Secret files are not world-readable and are not tracked in a repository. | `stat -c '%a %U %n' <env-or-secret-file>` | Cao |
| D4 | No default or example credentials remain on services. | Review service config by name; do not print values | Cao |

### E. Containers and services

| # | Check | Evidence command | Priority |
| --- | --- | --- | --- |
| E1 | No container is `unhealthy`, restarting, or exited unexpectedly. | `docker ps -a --format '{{.Names}}\t{{.Status}}'` | Cao |
| E2 | Long-running services have a restart policy. | `docker ps -q \| xargs docker inspect -f '{{.Name}} {{.HostConfig.RestartPolicy.Name}}'` | TB |
| E3 | Images use pinned tags, not `latest` or no tag. | `docker ps --format '{{.Names}}\t{{.Image}}'` | TB |
| E4 | Stateful services mount named volumes or reviewed bind mounts, so data survives container recreation. | `docker inspect -f '{{.Name}} {{range .Mounts}}{{.Type}}:{{.Name}}{{.Destination}} {{end}}' <name>` | Cao |
| E5 | Reverse proxy config is valid and matches the running upstreams. | `nginx -t` (inside the proxy container or host) | TB |

### F. Resources and capacity

| # | Check | Evidence command | Priority |
| --- | --- | --- | --- |
| F1 | Disk and inode usage leave headroom (alert threshold well below 100%). | `df -h`; `df -i` | Cao |
| F2 | Memory and swap are not under sustained pressure; no recent OOM kills. | `free -m`; `uptime`; `dmesg -T \| grep -i 'out of memory' \| tail` | TB |
| F3 | Container logs are rotated, so a chatty service cannot fill the disk. | `docker info --format '{{.LoggingDriver}}'`; check `max-size`/`max-file` in the daemon or Compose config | Cao |
| F4 | Docker's own footprint (images, build cache, volumes) is known and bounded. | `docker system df` | Thấp |

### G. Backup and recovery

| # | Check | Evidence command | Priority |
| --- | --- | --- | --- |
| G1 | Every stateful service (database, queue, object store, CI home) has a backup job. | `crontab -l`; `systemctl list-timers` | Cao |
| G2 | The latest backup is recent and non-empty. | `ls -lh --time-style=long-iso <backup-dir>` | Cao |
| G3 | A copy exists off the server, so losing the host does not lose the backup. | Backup job config | Cao |
| G4 | A restore has been tried and the steps are written down. | Runbook or last restore record; otherwise `Chưa xác minh` | Cao |
| G5 | A provider snapshot or equivalent exists before risky changes. | Provider console or records | TB |

### H. Monitoring and operations

| # | Check | Evidence | Priority |
| --- | --- | --- | --- |
| H1 | An external uptime check hits the public URL, not only an internal health check. | Monitoring config or service | TB |
| H2 | Alerts exist for disk, memory, certificate expiry, and container health, each with an owner. | Alert rules | TB |
| H3 | Logs are reachable without SSH-ing into the host for each investigation. | Log/monitoring setup | Thấp |
| H4 | A rollback path and a short runbook exist for each service. | Runbook | TB |

## Output format

Report in Vietnamese. One row per checked item, grouped by section, then a short ranked
action list. Example:

```text
Review server: <host> (<môi trường>) — <ngày>

| # | Kết quả | Bằng chứng | Đề xuất |
| --- | --- | --- | --- |
| A1 | Chưa đạt | `ss -tlnp` thấy 5432 nghe trên 0.0.0.0 | Bind về 127.0.0.1 hoặc mạng nội bộ Docker |
| B1 | Đạt | PermitRootLogin no, PasswordAuthentication no | — |
| G4 | Chưa xác minh | Không có bản ghi restore | Thử restore vào môi trường tạm |

Việc nên làm (theo ưu tiên)
1. [Cao] A1 — đóng cổng 5432 ra ngoài.
2. [Cao] G4 — thử restore một bản backup.

Chưa xác minh: <mục và lý do>
Bạn muốn áp dụng những điểm nào?
```

Close with the question so the user chooses which fixes to apply. Do not apply any of
them as part of the review.
