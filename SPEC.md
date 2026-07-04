# SPEC — Chuẩn hóa quy ước đặt tên (flex-workstation)

## Mục tiêu

Thống nhất quy ước đặt tên cho thư mục, file, module và namespace trong
flex-workstation. Giúp contributor — kể cả AI — tạo artifact đúng ngay
từ lần đầu, không cần đoán mò.

**Phạm vi:** Chỉ repo flex-workstation và các thư mục thuộc workstation.
Convention của repo con thuộc trách nhiệm từng repo.

---

## Hiện trạng — Điểm chưa nhất quán

| Khu vực | Vấn đề |
|---|---|
| Doc files trong repo con | UPPER-KEBAB, PascalCase-kebab, PascalCase thuần — không có rule duy nhất |
| SPEC files | `SPEC.md` + `SPEC-realtime-force-logout.md` — prefix UPPER, body lowercase |
| `requirements/` internals | Chưa có convention rõ cho file bên trong |
| Skill namespace (workstation) | Skills trong `skills/` chưa có prefix đăng ký |

---

## Quy ước

### 1. Thư mục

| Loại | Convention | Ví dụ |
|---|---|---|
| Workstation modules | `kebab-case` | `docs/`, `skills/`, `scripts/` |
| Repo con | `kebab-case` với prefix `flex-` | `flex-agents`, `flex-auth-service` |
| Skill / agent / command | `kebab-case` | `code-reviewer/`, `agent-instructions-architect/` |
| Thư mục con trong `docs/` | `kebab-case` | `docs/architecture/`, `docs/adr/` |

Không dùng `UPPER_CASE`, `PascalCase`, hay `snake_case` cho tên thư mục.

### 2. File — theo loại

#### Config root-level

| File | Convention |
|---|---|
| AI tooling, workspace config | `UPPER_CASE.md` — `CLAUDE.md`, `AGENTS.md`, `TASKS.md`, `README.md` |
| Data / manifest | `lowercase.json` — `workstation.json` |
| Windows entrypoint | `UPPER_SNAKE_CASE.cmd` — `OPEN_CLAUDE.cmd`, `SYNC_WORKSPACE.cmd` |

#### Tài liệu trong `docs/`

Tất cả dùng `kebab-case.md`:

```
docs/
  onboarding.md          ✓
  system-map.md          ✓
  architecture/
    overview.md          ✓
    adr-logging.md       ✓   (không phải ADR-Global-Logging.md)
```

#### SPEC file

- Spec chính: `SPEC.md` (UPPER, ở root repo hoặc root workstation)
- Spec feature: `SPEC-<feature>.md` — feature dùng `kebab-case`

```
SPEC.md                           ← spec tổng quan
SPEC-realtime-force-logout.md     ✓
```

Không dùng `SPEC_feature.md` hay `spec-feature.md`.

#### Script

`kebab-case.ps1` / `.sh` trong `scripts/`:

```
scripts/
  bootstrap.ps1           ✓
  sync-repositories.ps1   ✓
```

#### Skill / Agent / Command

| Loại | Folder | File chính |
|---|---|---|
| Skill | `kebab-case/` | `SKILL.md` |
| Agent | flat trong `agents/` | `kebab-case.md` |
| Command | flat trong `commands/` | `kebab-case.toml` |

#### Requirements

Folder `000001/` (ID 6 chữ số, zero-padded). File bên trong dùng `kebab-case.md`:

```
requirements/
  000001/
    spec.md
    intent.md
    plan.md
    tasks.md
    artifacts/
    contracts/
```

### 3. Namespace / Prefix

| Nguồn gốc | Pattern | Ví dụ |
|---|---|---|
| Skill từ `flex-agents/skills/` | `flex-agents:<skill-name>` | `flex-agents:code-review-and-quality` |
| Skill từ `skills/` (workstation) | `flex:<skill-name>` | `flex:architecture-documenter` |
| Agent từ `flex-agents/agents/` | `flex-agents:<agent-name>` | `flex-agents:code-reviewer` |
| Command từ `flex-agents/commands/` | `flex-agents:<command-name>` | `flex-agents:build` |

Dùng `:` làm separator. Không dùng `/`, `.`, hay `__`.

---

## Ranh giới

**Luôn làm:**
- Đặt tên file/thư mục mới theo bảng convention ngay từ đầu
- Cập nhật spec này khi thêm loại artifact mới

**Hỏi trước khi làm:**
- Rename file/thư mục đã tồn tại (ảnh hưởng references)
- Đổi namespace prefix (ảnh hưởng người đang dùng)

**Không làm:**
- Áp dụng convention này vào code bên trong repo con
- Rename toàn bộ docs cũ trong một lần — làm theo từng PR nhỏ
- Định nghĩa C# namespace, Angular module naming tại đây

---

## Checklist tạo file mới

```
[ ] Thư mục: kebab-case
[ ] Doc file: kebab-case.md (trong docs/) hoặc UPPER_CASE.md (config root)
[ ] SPEC file: SPEC.md hoặc SPEC-<kebab>.md
[ ] Script: kebab-case.ps1/.sh
[ ] Skill: kebab-case/ + SKILL.md
[ ] Namespace: flex-agents: (từ flex-agents) hoặc flex: (từ workstation skills)
[ ] Windows cmd: UPPER_SNAKE_CASE.cmd
```
