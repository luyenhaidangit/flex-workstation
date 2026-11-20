# Server Setup (guide-only runbook)

## Overview

Walks a person through standing up a Flex server in a fixed order, one stage at a time. The source of truth for what the stack needs is `flex-environment` (`SETUP_SERVER.md`, `setup/0*-init-*.sh`, `docker-compose*.yml`, `AGENTS.md`) and `flex-k8s`. This reference carries the commands and the safety gates so the person can follow without opening every file, but the repo wins whenever the two disagree (see Step 1).

**Mode: guide-only.** The agent does not SSH into any server and does not run mutating commands on one. It reads the repos, explains, and hands over commands for the person to run, then interprets the output the person pastes back. Reason: a fresh server receives private keys, secrets, certificates and an admin signup page; a wrong or unreviewed command there is hard to undo and may leak a credential into a transcript.

Loaded from `flex-devops-engineering` when the task is to provision a new server. It does not diagnose incidents on a running production server (use `flex-prod-troubleshooting`); Compose, Nginx, Jenkins and secret rules stay in `flex-devops-engineering`'s main file.

## When to Use

- "Setup server mới", "dựng lại server", "cài Docker/Nginx/TLS/k3s trên máy trắng", "chuyển sang server khác".
- A checklist or review of whether a server is ready for the Flex stack (stage 10 works on its own for an existing server).
- A person is mid-setup and pastes an error or output from one of the stages below.

Do not use it to change an existing production service, deploy a new app version, or rotate secrets; those follow the main `flex-devops-engineering` process with its own authority checks.

## Core Process

### 1. Verify against the repo before giving any command

Read the current files first; do not rely on this reference's text for current state. Use `flex-repo-scope` (Read mode) to get `flex-environment` and `flex-k8s`, then open:

- `flex-environment/SETUP_SERVER.md` and `AGENTS.md` (section "Runtime Targets" says which compose files are populated and which are empty placeholders; `temp/` holds old configs awaiting migration).
- `flex-environment/setup/01..04-init-*.sh` header comments (flags such as `--check`, `--env`, `--staging`).
- `flex-k8s/README.md` when k3s/Argo CD is in scope.

If a command or step below differs from the repo, give the repo's version and say which one you used. If a file cannot be read, say "chưa xác minh" and do not guess.

### 2. Establish the target before stage 1

Ask only what is unknown (one batch): server role (new dev/staging/prod), provider and OS, CPU architecture, RAM/disk, public IP, domain(s), whether k3s (`flex.`/`api.` routes, `/fss/`) is needed, and whether the person logs in as `root` or a sudo user. Never ask for or accept a password, private key, token or real IP in chat; hosts live in the person's `~/.ssh/config`.

### 3. Run the stages in order, one at a time

Present one stage, its commands, the expected result and the gate. Wait for the person's output before the next stage. Each command goes in its own fenced `bash` block. Stages 0-3 are the base; 4-9 depend on what the target needs; 10 is the review checklist.

#### Stage 0: Machine facts and sizing

```bash
uname -m && lsb_release -a && free -h && df -h /
```

- Ubuntu only (the setup scripts refuse other distros). Record the architecture; every pinned image must support it. The repo's Jenkins label says `aarch64` while a measured server was `x86_64`, so never assume.
- Known measured sizing for a build-out server: 3.8 GiB RAM, no swap, 38 GB disk. Infisical alone is about 1.2 GiB; Elasticsearch (1 GB heap) plus Logstash, Jenkins, databases and Ollama may not fit. Recommend swap before adding services; whether the full stack fits is "chưa đo".

#### Stage 1: Deploy user, base packages, GitHub access

Work as `ubuntu` (not root) so the repo lives at `~/flex-environment`, the path CI and `JENKINS_HOST_HOME` expect. If only root exists:

```bash
adduser ubuntu && usermod -aG sudo ubuntu
```

```bash
install -d -m 700 -o ubuntu -g ubuntu /home/ubuntu/.ssh
```

```bash
install -m 600 -o ubuntu -g ubuntu ~/.ssh/authorized_keys /home/ubuntu/.ssh/
```

Copy only `authorized_keys`, never a private key. Then, as `ubuntu`:

```bash
sudo apt-get update && sudo apt-get install -y git curl openssh-client ca-certificates
```

`flex-environment` is private, so GitHub access must exist before cloning (HTTPS password prompts fail; GitHub rejects passwords for Git). Use a per-machine key:

```bash
ssh-keygen -t ed25519 -C "flex-server" -f ~/.ssh/id_ed25519 -N ""
```

If it asks `Overwrite (y/n)?` answer `n`. Then print only the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Register it on GitHub, either as an account SSH key (read+write to every repo, including private) or, safer, a read-only deploy key on `flex-environment` (one key per repo). Prefer the deploy key. Test and clone:

```bash
ssh -T git@github.com
```

On first connect compare the ED25519 fingerprint with GitHub's official "SSH key fingerprints" page and type the full word `yes`. `Permission denied (publickey)` means GitHub did not accept the key. Then:

```bash
cd ~ && git clone git@github.com:luyenhaidangit/flex-environment.git
```

Gate: `ssh -T` greets the account and `~/flex-environment` exists. Never paste `id_ed25519` (no `.pub`) anywhere.

#### Stage 2: Docker Engine and Compose

```bash
cd ~/flex-environment && bash setup/01-init-setup.sh --check
```

```bash
bash setup/01-init-setup.sh
```

`--check` changes nothing. The script is idempotent and installs Docker Engine, Compose v2, Buildx and adds the user to group `docker`. Then log out and back in (or `newgrp docker`) and verify:

```bash
docker --version && docker compose version
```

#### Stage 3: Secrets and host configuration (names only, never values)

Compose reads these from the host; a missing file means the container will not start, and a missing bind path becomes an empty directory:

| File | Used by | Note |
| --- | --- | --- |
| `~/.ssh/id_ed25519` | Jenkins checkout | `chmod 600`; an account-level key gives Jenkins write access to every repo |
| `~/.secrets/dockerhub_username`, `~/.secrets/dockerhub_password` | Jenkins image push | `chmod 600` |
| `./.secrets/jenkins_admin_password`, `hnx_db_password`, `aspnetidentity_db_password` | Jenkins JCasC, `postgres-bootstrap` | inside the repo dir; confirm `.gitignore` covers it |
| `./.env` | `JENKINS_HOST_HOME` and options | repo value is the dev machine's home; must be set to the deploy user's home |
| `mounts/flex-api-gateway/.env`, `mounts/flex-auth-service/.env` | app `env_file` | create from `.env.example`; `JwtSettings__SecretKey` must be identical in both |

```bash
mkdir -p ~/.secrets && chmod 700 ~/.secrets
```

The person creates the Docker Hub files themselves with `printf '%s'` redirected into `~/.secrets/`, then:

```bash
chmod 600 ~/.secrets/dockerhub_username ~/.secrets/dockerhub_password ~/.ssh/id_ed25519
```

```bash
sed -i 's|^JENKINS_HOST_HOME=.*|JENKINS_HOST_HOME=/home/ubuntu|' .env
```

Infrastructure variables have inline defaults (`POSTGRES_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `RABBITMQ_DEFAULT_PASS`, `ELASTIC_PASSWORD`, `MINIO_ROOT_PASSWORD`, ...). On production they must be overridden in `.env`; defaults are not acceptable. Gate: the person confirms each file exists with mode 600 (`ls -l`, never `cat`).

#### Stage 4: Host kernel setting for Elasticsearch (only if Elasticsearch will run)

```bash
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-flex-elasticsearch.conf && sudo sysctl --system
```

Verify `sysctl vm.max_map_count` prints `262144`. Marked "chưa xác minh trên server" in the repo.

#### Stage 5: Nginx and TLS (Let's Encrypt)

Preconditions: DNS A records for `luyenhaidangit.pro` and `www.luyenhaidangit.pro` (plus each subdomain used: `portainer.`, `infisical.`, `flex.`, `api.`) point to the server, ports 80 and 443 are open. No AAAA record unless IPv6 is served (Let's Encrypt prefers IPv6 and a wrong AAAA breaks issuance and renewal). DNS is created by hand in the registrar's UI (Mắt Bão), then confirmed:

```bash
nslookup luyenhaidangit.pro
```

```bash
bash setup/02-init-nginx.sh --check
```

```bash
sudo bash setup/02-init-nginx.sh --env prod
```

Try `--staging` first to save rate-limit quota (staging certs are not browser-trusted; delete with `certbot delete --cert-name luyenhaidangit.pro` and remove `.env.nginx` before the real issue). The script issues via webroot, writes `NGINX_ENV` into the git-ignored `.env.nginx` and recreates nginx. Every manual compose command afterwards needs `--env-file .env --env-file .env.nginx` (`restart.sh` adds it). Verify:

```bash
curl -I https://luyenhaidangit.pro/healthz
```

```bash
sudo certbot renew --dry-run
```

Expect HTTP 200 and a passing dry run. Do not commit any private key.

#### Stage 6: Infisical (only if the secret manager is wanted)

Order matters: the main stack (nginx) must be up first, because Infisical joins the external network `flex-platform_flex_net`.

```bash
sudo bash setup/03-init-infisical.sh
```

Immediately back up `ENCRYPTION_KEY` outside the server (`sudo grep '^ENCRYPTION_KEY=' /etc/flex/infisical.env`); losing it loses every secret. Start it with an explicit file flag (a bare `docker compose up -d` does not start it):

```bash
sudo docker compose -f docker-compose.secrets.yml up -d
```

**Before exposing it to the Internet**, the UI listens on `127.0.0.1:8080` only. From the person's own machine, tunnel and create the admin account at once, because the first signup becomes admin:

```bash
ssh -L 8080:127.0.0.1:8080 ubuntu@<IP-server>
```

Open `http://localhost:8080/admin/signup`, enable 2FA, keep invite-only signup. Only then publish via Nginx: DNS A for `infisical.`, `bash pull.sh`, `sudo bash setup/02-init-nginx.sh --env prod`, set `SITE_URL` in `/etc/flex/infisical.env`, recreate the container, and check `curl -I https://infisical.luyenhaidangit.pro/api/status`. Remaining before calling it done: a `pg_dump` backup with one tested restore, and an IP restriction decision for the route. Marked "chưa chạy thử trên server thật".

#### Stage 7: Kubernetes on the same host (only if `flex.`/`api.`/`/fss/` routes are needed)

```bash
bash setup/04-init-k3s.sh --check
```

```bash
bash setup/04-init-k3s.sh
```

Single-node k3s with Traefik and servicelb disabled (Docker Nginx owns 80/443 and reaches the cluster through NodePort `30080`). Skip entirely for Compose-only services. Manifests, Argo CD and gateway secrets belong to `flex-k8s` (`restart.sh`, `set-secret.sh`, `install-argocd.sh`); follow its README, and create the gateway Secret before applying the gateway manifest.

#### Stage 8: Firewall and network exposure

Only 80/443 (and the SSH port) should be reachable from the Internet. The repo publishes many ports on all interfaces (PostgreSQL 5432, MySQL 3306, RabbitMQ 5672/15672, Elasticsearch 9200, Logstash 5044/5000/9600, MinIO 9001/9002, gateway 7000, Ollama 11434, Jenkins agent 50000, k3s 6443/10250, NodePorts 30000-32767), so the provider firewall or security list is the only barrier. Do not open 6443, 10250 or NodePorts. Manage the cluster over SSH or a tunnel. Verify from a machine outside the network:

```bash
nc -zv -w 5 <IP-server> <port>
```

Expect `timed out` for every closed port. A claim that the provider firewall is closed is not a verification until this scan has been run.

#### Stage 9: Start the stack and verify

```bash
cd ~/flex-environment && docker compose config --quiet
```

```bash
docker compose up -d
```

Use plain `docker compose up -d` for a new server, not `restart.sh` (which runs `git pull` then `docker compose down` and stops every container). Add `--env-file .env --env-file .env.nginx` if the nginx environment was selected. Monitoring is separate (`docker compose -f docker-compose.monitoring.yml up -d`). Check `AGENTS.md` first: `infra`, `app` and `monitoring` may still be empty placeholders. Jenkins first start uses `bash publish-jenkins.sh` (needs `docker login` and Docker installed; never on production without a `jenkins_data` backup). Verify with evidence:

```bash
docker compose ps
```

```bash
docker compose exec nginx nginx -t
```

Expect long-running services `Up` and `healthy`, init containers (`postgres-bootstrap`, `minio-init`, `elasticsearch-init`, `kibana-init`, `ollama-init`) `Exited (0)`, and `/healthz` returning 200. A passing `docker compose config` proves syntax only.

CI/CD (optional): GitHub secrets `SERVER_HOST`, `SERVER_USER`, `SERVER_SSH_KEY` on `flex-environment`, set with `gh secret set <name>`. The workflow triggers on `push` and `pull_request` to `main` and runs `restart.sh` on the server, so ask whether pull requests should be able to deploy.

#### Stage 10: Readiness check (review checklist)

Self-contained and read-only: use it right after stage 9, or alone when someone asks "server ổn chưa / sẵn sàng chưa" about a server that already exists. Skip groups that do not apply (no k3s, no Infisical). The person runs each command (one per `bash` block, as in Step 3) and pastes the output; the agent marks the row. Commands marked † are standard Linux/OpenSSL/curl commands, not taken from the repo and not yet run on this server; say so when handing them over. Never `cat` a secret: names, modes and counts only.

**A. Machine**

| # | Check | Command | Expected |
| --- | --- | --- | --- |
| A1 | OS and architecture | `lsb_release -rs && uname -m` | Ubuntu; architecture matches every pinned image |
| A2 | Memory, swap, disk | `free -h && df -h /` | Recorded; swap present on a small-RAM host; disk not near full |
| A3 | Elasticsearch kernel setting (if used) | `sysctl vm.max_map_count` | `262144` |
| A4 | Clock in sync † | `timedatectl show -p NTPSynchronized` | `NTPSynchronized=yes` (TLS and JWT depend on time) |

**B. Access**

| # | Check | Command | Expected |
| --- | --- | --- | --- |
| B1 | Deploy user, not root | `id` | User `ubuntu`, in groups `sudo` and `docker` |
| B2 | GitHub access | `ssh -T git@github.com` | Greets the account, no `Permission denied` |
| B3 | Repo location | `ls -d ~/flex-environment` | Exists (CI runs `cd ~/flex-environment`) |
| B4 | SSH hardening † (recommended, not in repo) | `sudo sshd -T \| grep -E 'permitrootlogin\|passwordauthentication'` | Password login off; root login off or key-only |

**C. Docker and stack**

| # | Check | Command | Expected |
| --- | --- | --- | --- |
| C1 | Docker and Compose | `docker --version && docker compose version` | Both print versions |
| C2 | Compose renders | `docker compose config --quiet` | Exit 0 (syntax only) |
| C3 | Images pinned † | `docker compose config \| grep -E 'image:.*(:latest\|[^:]$)'` | No output |
| C4 | Containers healthy | `docker compose ps` | Long-running `Up`/`healthy`; init containers `Exited (0)` |
| C5 | Data persists | `docker volume ls` | Named volumes exist for every stateful service |

**D. Secrets and configuration (names, modes and counts only)**

| # | Check | Command | Expected |
| --- | --- | --- | --- |
| D1 | Secret file modes | `ls -l ~/.ssh/id_ed25519 ~/.secrets ./.secrets` | `-rw-------`; all files from stage 3 present |
| D2 | `JENKINS_HOST_HOME` | `grep '^JENKINS_HOST_HOME=' .env` | The deploy user's home, not the dev machine's |
| D3 | App env files exist | `ls -l mounts/flex-api-gateway/.env mounts/flex-auth-service/.env` | Both exist, mode 600 |
| D4 | JWT key identical in both | `grep -h '^JwtSettings__SecretKey=' mounts/flex-api-gateway/.env mounts/flex-auth-service/.env \| uniq \| wc -l` | `1` (prints no value) |
| D5 | Production passwords overridden | `grep -E '^(POSTGRES_PASSWORD\|MYSQL_ROOT_PASSWORD\|RABBITMQ_DEFAULT_PASS\|ELASTIC_PASSWORD\|MINIO_ROOT_PASSWORD)=' .env \| cut -d= -f1` | Every name used by the running stack is listed (defaults are not acceptable) |
| D6 | No secrets or private keys tracked by Git † | `git ls-files \| grep -E '(^\|/)\.secrets/\|\.key$\|(^\|/)\.env$\|wallet'` | No output on a production checkout |

**E. DNS and TLS (repeat per served domain: `luyenhaidangit.pro`, `www.`, and each of `portainer.`, `infisical.`, `flex.`, `api.` in use)**

| # | Check | Command | Expected |
| --- | --- | --- | --- |
| E1 | A record points here | `nslookup <domain>` | `Address:` equals the server IP |
| E2 | No stray IPv6 | `nslookup -type=AAAA <domain>` | No AAAA unless IPv6 is served |
| E3 | Cert issued | `sudo certbot certificates` | Cert listed, every served name in its domains |
| E4 | Cert actually served, SAN and expiry † | `echo \| openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null \| openssl x509 -noout -dates -subject -ext subjectAltName` | Not expired, `notAfter` more than 30 days away (certbot renews inside 30 days), SAN covers the name |
| E5 | Auto-renewal | `systemctl list-timers \| grep certbot` | A timer is scheduled |
| E6 | Renewal works | `sudo certbot renew --dry-run` | Succeeds |
| E7 | HTTP redirects to HTTPS † | `curl -sI http://<domain>` | `301` to `https://` (ACME path stays HTTP) |
| E8 | `www` redirects to root † | `curl -sI https://www.luyenhaidangit.pro` | `301` to the root domain |
| E9 | Health route | `curl -I https://<domain>/healthz` | `200` |
| E10 | Nginx config and environment | `docker compose exec nginx nginx -t` | `syntax is ok`; `.env.nginx` selects `NGINX_ENV=prod` |
| E11 | Not the self-signed or dev cert † | `curl -sS -o /dev/null -w '%{ssl_verify_result}\n' https://<domain>/healthz` | `0` (a mkcert or self-signed cert fails here) |

**F. Network exposure**

| # | Check | Command | Expected |
| --- | --- | --- | --- |
| F1 | What listens locally | `ss -tlnp` | Only intended services; compare with the port table in stage 8 |
| F2 | Closed from outside (run from another machine) | `nc -zv -w 5 <IP-server> <port>` for 5432, 3306, 6379, 5672, 15672, 9200, 6443, 10250, 30080 | `timed out` for each; only 80, 443 and SSH answer |
| F3 | Provider firewall | Ask the person; it cannot be read from the host | Recorded as "xác nhận bởi chủ server", never as verified without F2 |

**G. Kubernetes (only if stage 7 was done)**

| # | Check | Command | Expected |
| --- | --- | --- | --- |
| G1 | Node and pods | `kubectl get nodes` then `kubectl get pods -A` | Node `Ready`; pods `Running` |
| G2 | Reachable on the NodePort | `curl -i http://localhost:30080/` | Responds (nginx page) |
| G3 | Gateway secret exists | `kubectl get secret flex-api-gateway-secret -o jsonpath='{.data}' \| jq 'keys'` | Lists key names only, never values |

**H. Recovery and operations**

| # | Check | How | Expected |
| --- | --- | --- | --- |
| H1 | Infisical `ENCRYPTION_KEY` backed up off the server | Ask the person (do not read the file) | Confirmed; otherwise a blocker |
| H2 | Database backup and a tested restore | Ask for the last `pg_dump` and restore date | Both exist; otherwise "chưa xác minh" |
| H3 | `jenkins_data` backup before any Jenkins change | Ask | Exists before `publish-jenkins.sh` runs |
| H4 | CI secrets set (run on the person's machine) | `gh secret list -R luyenhaidangit/flex-environment` | `SERVER_HOST`, `SERVER_USER`, `SERVER_SSH_KEY` |
| H5 | No secret leaked into logs | `docker compose logs --tail 100 <service>` and skim | No credentials in output |

Blockers (any one makes the verdict "chưa sẵn sàng"): expired cert or a served name missing from the SAN, a database/broker/Elasticsearch port reachable from outside, default production passwords, unhealthy long-running containers, JWT keys that differ, or no off-server `ENCRYPTION_KEY` backup. Everything else is reported as a finding with its severity, not hidden.

Report with the block defined under "Output Format".

## Output Format

For each stage, reply in Vietnamese with this block, then the commands (each in its own `bash` block):

```text
Giai đoạn <n>: <tên>
- Mục đích: <một câu>
- Điều kiện cần: <danh sách hoặc không>
- Kỳ vọng sau khi chạy: <kết quả quan sát được>
- Chốt an toàn: <điều phải xác nhận trước khi sang giai đoạn sau>
```

End the whole run, and answer any "is this server ready" review, with the stage 10 checklist and this report. Mark a row passed only for output the person actually pasted back; otherwise it is `chưa xác minh` or `chưa chạy` with the reason.

```text
Báo cáo sẵn sàng server
- Mục tiêu: <server, vai trò, domain>
- Kết quả: <đạt>/<tổng> mục đạt, <n> không đạt, <m> chưa xác minh
- Không đạt: <mã mục — bằng chứng — cách khắc phục>
- Chưa xác minh: <mã mục — lý do>
- Kết luận: Sẵn sàng | Chưa sẵn sàng (blocker: <mã mục>)
```

Example: `- Không đạt: E4 — notAfter còn 12 ngày, www.luyenhaidangit.pro không có trong SAN — chạy lại setup/02-init-nginx.sh --env prod sau khi có DNS www`.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| "I can just SSH in and run it for them." | Guide-only is a deliberate boundary: a fresh server holds keys and an admin signup page. Hand over commands; the person runs them. |
| "This reference lists the commands, no need to open the repo." | The reference can drift from `SETUP_SERVER.md` and the scripts. Step 1 comes first, and the repo wins. |
| "Run `restart.sh` to start everything." | It runs `git pull` and `docker compose down`, stopping every container. Use `docker compose up -d` on a new server. |
| "Infisical can be opened to the Internet, we'll sign up later." | Whoever reaches `/admin/signup` first becomes admin. Create the admin through the SSH tunnel before publishing the route. |
| "Config renders, so the server is ready." | `compose config` and `--check` prove syntax and prerequisites, not readiness. Collect health output and the external port scan. |
| "Paste the secret file so I can check it." | Never. Check existence and mode with `ls -l`; values do not enter the chat. |

## Red Flags

- Running or offering to run a command on the server through SSH.
- Asking for, accepting or echoing a password, token, private key, `ENCRYPTION_KEY`, certificate key or a real server IP.
- Any `docker compose down -v`, `docker system prune`, or volume deletion suggested as troubleshooting.
- Skipping `--check` or the DNS precondition before requesting a certificate.
- Reporting "server ready" without pasted health and port-scan evidence.
- Opening 6443, 10250 or NodePorts to the Internet.
- Copying repo state from this reference's text without having read the repo in Step 1.

## Verification

- [ ] Step 1 ran: `flex-environment` and `flex-k8s` were read and every difference from this reference was reported.
- [ ] Target facts (OS, architecture, RAM/disk, domains, k3s needed) were stated before stage 0 ended.
- [ ] Every stage used the stage block and one command per `bash` block.
- [ ] No command was run on a server by the agent, and no secret value appeared in the chat.
- [ ] Each stage gate was confirmed by output the person pasted, not assumed.
- [ ] Final checklist marks only evidenced items; unverified items carry a reason.
- [ ] Items the repo marks "chưa xác minh" were passed on as unverified, not promoted to fact.
