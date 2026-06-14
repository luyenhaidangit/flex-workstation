---
name: agent-instructions-architect
description: Generate, review, or refactor files in Claude Code's instruction layer — CLAUDE.md (project / subdirectory / user-global), MEMORY.md, memory files, rules files, output styles, subagent prompts, SKILL.md, slash commands. Use this skill whenever the user wants to write, audit, split, consolidate, move, or fix instructions; asks "where should this rule live", "is my CLAUDE.md too long", "how do I write a good subagent prompt"; or wants to clean up bloated, contradictory, or stale instruction files. Also teaches which instruction tier to use for what, and how to write instructions that survive across fresh sessions.
---

# Agent Instructions Architect

Kiến trúc tầng *instructions* của Claude Code — phần chỉ dẫn mà model nhìn thấy. Mục tiêu: chọn đúng tầng, viết đúng cách, dọn sạch khi phình.

## Tầng instructions là gì

Skill này CHỈ đụng tới những file/cơ chế quyết định *Claude nhìn thấy chỉ dẫn gì*:

- **CLAUDE.md** — ba tầng:
  - Project root: `CLAUDE.md` (mọi session trong repo, mọi người)
  - Subdirectory: vd `src/api/CLAUDE.md` (chỉ khi làm việc trong thư mục con)
  - User-global: `~/.claude/CLAUDE.md` (cá nhân, mọi project)
- **Memory system** — `MEMORY.md` (index) + các file memory phân loại `user / feedback / project / reference`
- **Rules files** — file ngắn path-scoped (vd `.claude/rules/<topic>.md`), mỗi file một hành vi
- **Subagent prompts** — `.claude/agents/<name>.md`, phần body là system prompt
- **SKILL.md** — `.claude/skills/<name>/SKILL.md`, phần hướng dẫn cho Claude khi skill trigger
- **Slash commands** — `.claude/commands/<name>.md`
- **Output styles** — `.claude/output-styles/<name>.md`
- **Plugin-bundled instructions** — instruction text nằm trong plugin bundle (nếu dùng)

KHÔNG thuộc phạm vi skill: hooks, MCP servers, permissions, statusLine, settings.json non-prompt. Nếu user hỏi về các tầng đó, chỉ ra rằng đây không phải tầng instructions và đề nghị tách yêu cầu.

## Khi nào skill này trigger

User nói/hỏi đại loại:

- "Viết hộ CLAUDE.md cho repo này / cho `src/api/`"
- "Memory của tôi đang lộn xộn, dọn giúp"
- "Rule này nên đặt ở CLAUDE.md hay memory?"
- "CLAUDE.md đang dài quá, tách giúp"
- "Tạo subagent `foo`, viết prompt cho nó"
- "Review toàn bộ instructions, có gì mâu thuẫn không"
- "Cách viết description SKILL.md để trigger đúng"
- "Output style cho session debug"

## Phát hiện chế độ

Đọc yêu cầu → chọn 1 trong 3 chế độ. Nếu không rõ, hỏi ngắn 1 câu.

| Tín hiệu từ user | Chế độ |
|---|---|
| "viết", "tạo mới", "soạn", "có file X nào chưa" | **Generate** |
| "review", "audit", "có vấn đề gì", "đọc giúp", "kiểm tra" | **Review** |
| "dọn", "tách", "gộp", "refactor", "cleanup", "phình quá" | **Improve** |

Một yêu cầu có thể chuyển chế độ giữa chừng (vd Review xong user bảo "sửa giúp luôn" → Improve).

---

## Chế độ 1 — Generate

Viết mới một instruction file.

### Quy trình

1. **Làm rõ tối đa 3 câu** (bỏ qua câu nào đã rõ từ yêu cầu):
   - **Ai/khi nào áp dụng?** Mọi session trong project / chỉ subdir / chỉ user này / chỉ subagent / chỉ khi user gõ slash command / khi cần đổi format output
   - **Stable hay học dần?** Stable, đã chốt → CLAUDE.md hoặc rules. Còn học, tích lũy theo conversation → memory.
   - **Khuôn hành vi hay khuôn trình bày?** Hành vi (làm gì, tránh gì) → CLAUDE.md / rules / memory. Trình bày (tone, format, length) → output style.

2. **Chọn tầng** theo Decision Tree (mục Reference).

3. **Viết file** theo Template tương ứng (mục Reference).

4. **Verify** bằng Principles: cụ thể chưa? có Why chưa? đúng tầng chưa? cold-read được không?

5. **Nếu là memory mới** → thêm 1 dòng vào `MEMORY.md`. Nếu là subagent/skill/command mới và project có registry/docs liệt kê (vd `docs/tasks.md`) → cập nhật.

### Ví dụ

User: "Tạo subagent `db-migrator` chuyên viết và review migration Postgres"

- Làm rõ: tools cần (Read, Edit, Bash), model tier (Sonnet đủ), có cần worktree không
- Chọn tầng: subagent (`.claude/agents/db-migrator.md`)
- Viết theo template subagent: description cụ thể đủ để main agent biết khi nào delegate (vd "khi user tạo/sửa migration Postgres, đặc biệt khi có ALTER TABLE trên bảng lớn"), system prompt có ràng buộc nghiệp vụ (luôn dùng transaction reversible, không drop column trực tiếp...)
- Verify: description không chung chung, prompt có Why cho ràng buộc

---

## Chế độ 2 — Review

Audit tầng instructions, ra punch list. Không sửa luôn — đợi user duyệt mới chuyển Improve.

### Quy trình

1. **Liệt kê file** bằng Glob:
   - `CLAUDE.md`, `**/CLAUDE.md`
   - `~/.claude/CLAUDE.md` nếu user yêu cầu review cả global
   - `MEMORY.md`, `**/memory/**/*.md`
   - `.claude/rules/**/*.md`
   - `.claude/agents/**/*.md`
   - `.claude/skills/**/SKILL.md`
   - `.claude/commands/**/*.md`
   - `.claude/output-styles/**/*.md`

2. **Đọc và check theo các nhóm vấn đề** (xem Anti-patterns ở Reference):
   - Trùng lặp cross-tier (cùng 1 rule ở 2+ file)
   - Mâu thuẫn (rule A nói "luôn X", rule B nói "không X")
   - Sai tầng (project convention nằm trong memory; user preference nằm trong project CLAUDE.md)
   - Phình (CLAUDE.md root > ~500 tokens; memory file > 1 màn hình)
   - Mơ hồ (rule không kiểm chứng được)
   - Chết (nhắc file/function/flag không còn tồn tại — grep verify)
   - Memory thiếu `**Why:**` / `**How to apply:**` (với type feedback/project)
   - Subagent/skill description mơ hồ → trigger không đúng
   - `MEMORY.md` viết nội dung memory trực tiếp thay vì link sang file con

3. **Báo cáo dạng punch list**, mỗi item: `<file>:<line> — <vấn đề> — <đề xuất sửa>`.

### Ví dụ output

```
CLAUDE.md:12 — "viết test đầy đủ" mơ hồ — đề xuất: "thêm test cho mọi handler mới trong src/api/, dùng pytest fixture có sẵn"
.claude/memory/feedback_review.md — thiếu **Why:** — đề xuất: thêm lý do (incident? preference cá nhân?)
CLAUDE.md:34 và memory/project_naming.md — cùng rule naming convention ở 2 nơi — đề xuất: giữ ở CLAUDE.md (stable), xóa khỏi memory
.claude/agents/researcher.md — description chỉ "nghiên cứu code" → quá chung — đề xuất: "Dùng khi cần tìm definition/usage của symbol trong codebase đa repo, đặc biệt khi grep nhiều vòng"
```

---

## Chế độ 3 — Improve

Refactor instruction files theo punch list (từ Review hoặc user nêu trực tiếp).

### Quy trình

1. Nếu chưa có punch list → chạy Review trước.
2. **Xác nhận thứ tự ưu tiên với user** trước khi sửa hàng loạt. Không tự ý sửa nhiều file cùng lúc khi chưa duyệt.
3. **Áp các phép biến đổi an toàn**:
   - **Split**: CLAUDE.md phình → tách phần path-specific sang `<dir>/CLAUDE.md` hoặc `.claude/rules/<topic>.md`
   - **Merge**: 2+ memory cùng chủ đề → gộp 1 file, giữ Why của bản gốc rõ nhất
   - **Move**: instruction sai tầng → chuyển đúng tầng, xóa chỗ cũ, cập nhật `MEMORY.md` nếu liên quan
   - **Rewrite**: mơ hồ → cụ thể, thêm ví dụ đúng/sai
   - **Delete**: chết → xóa, ghi rõ "tại sao xóa" trong commit message
4. Sau mỗi thay đổi, **verify**:
   - Frontmatter còn parse được (`name`, `description`, `type` cho memory)
   - Link trong `MEMORY.md` còn đúng tên file
   - Không tạo mâu thuẫn mới (thêm rule → grep xem có ngược ở đâu)
5. Khi xong: đề xuất commit message gọn, mô tả "tại sao" thay vì "đã đổi gì".

### Ví dụ

User: "CLAUDE.md root dài 800 tokens, tách giúp"

- Đọc CLAUDE.md → nhận diện block path-specific (vd phần React, phần backend API, phần CI)
- Đề xuất plan trước khi sửa:
  - Root giữ: vai trò repo, conventions universal, commands chính
  - Tách `src/frontend/CLAUDE.md`: rule React
  - Tách `src/backend/CLAUDE.md`: rule API
  - Tách `.claude/rules/ci.md`: rule CI scripts
- Chờ user duyệt → apply
- Verify root giờ dưới ~500 tokens, không mất rule nào

---

## Reference — Decision Tree (chọn tầng nào)

```
Áp dụng cho ai/khi nào?
│
├─ Mọi session trong project, mọi người
│  ├─ Stable, project-wide, ngắn → CLAUDE.md (root)
│  ├─ Chỉ áp dụng trong subdir → CLAUDE.md (subdir) hoặc rules file path-scoped
│  └─ Một rule ngắn, path-scoped, độc lập → .claude/rules/<topic>.md
│
├─ Chỉ user này, mọi project
│  └─ ~/.claude/CLAUDE.md
│
├─ Học/tích lũy theo conversation (xuất hiện dần qua tương tác)
│  ├─ Về user (role, preference, expertise) → memory type=user
│  ├─ User correct hoặc confirm cách làm → memory type=feedback (kèm Why + How to apply)
│  ├─ Context project (deadline, decision, motivation) → memory type=project (kèm Why + How to apply)
│  └─ Pointer ra hệ thống ngoài (Linear, Grafana, Slack...) → memory type=reference
│
├─ Khi Claude làm task cụ thể cần context riêng / tool allow-list riêng
│  └─ Subagent (.claude/agents/)
│
├─ Khi user gõ /xxx
│  └─ Slash command (.claude/commands/)
│
├─ Khi user invoke skill, hoặc skill auto-trigger theo description
│  └─ SKILL.md (.claude/skills/)
│
└─ Đổi tone / format / cách trình bày output (không đổi hành vi)
   └─ Output style (.claude/output-styles/)
```

## Reference — Principles (nguyên tắc viết instructions tốt)

Dạy lại các nguyên tắc này khi giải thích quyết định cho user.

### 1. Cụ thể hơn trừu tượng

Bad: "viết code chất lượng cao"
Good: "không thêm try/catch quanh internal code; chỉ validate ở boundary (user input, external API)"

Trừu tượng → model phải đoán → kết quả không nhất quán.

### 2. Why bên cạnh What

Bad: "không mock database trong integration test"
Good: "không mock database trong integration test — Q3/2024 mock pass nhưng prod migration fail, tạo incident"

Why giúp model judge edge case thay vì follow mù.

### 3. Ví dụ thắng rule trừu tượng

Một cặp ví dụ "đúng vs sai" rõ hơn 3 dòng rule. Đặc biệt cần với format/style.

### 4. Đặt đúng tầng

Đặt sai tầng = thông tin rò rỉ vào context không cần (preference cá nhân vào project CLAUDE.md → cả team thấy), hoặc không reach session cần (project convention nằm trong memory → session mới không nhận).

### 5. Lean main file

CLAUDE.md root nên dưới ~500 tokens. Phần dài tách sang rules / sub-CLAUDE.md / memory. `MEMORY.md` là index, không phải nội dung — mỗi entry 1 dòng `- [Title](file.md) — hook`.

### 6. Không mâu thuẫn cross-tier

Trước khi thêm rule mới, grep xem có rule ngược đâu đó không. Khi review, mâu thuẫn ngầm là loại bug khó thấy nhất.

### 7. Test cold-read

Tự hỏi: "fresh Claude session không có lịch sử conversation, đọc file này có hiểu và làm đúng không?" Nếu phải có context conversation mới hiểu → viết lại.

### 8. Description là cơ chế trigger

SKILL.md và subagent dùng `description` để Claude quyết định có invoke không. Description chung chung → undertrigger. Description cụ thể + hơi pushy về trigger context → đúng tần suất.

### 9. Memory cần đúng type và format

File memory cần frontmatter `name`, `description` (cụ thể, dùng để future-Claude judge relevance), `type` (`user | feedback | project | reference`). Feedback và project memory cần `**Why:**` và `**How to apply:**` trong body.

### 10. Không lưu cái derive được

Code patterns, file paths, git history, debugging recipes → KHÔNG vào memory. Đọc code và `git log` là đủ.

## Reference — Templates

### CLAUDE.md (project root)

```markdown
# <Project name>

<1-2 dòng repo là gì, vai trò trong nhóm>

## Conventions
- <convention 1, cụ thể>
- <convention 2>

## Commands
- Build: `<cmd>`
- Test: `<cmd>`
- Lint: `<cmd>`

## Gotchas
- <thứ dễ sai mà đọc code không tự nói ra>

## Tài liệu cần đọc theo task
- Tổng quan: `README.md`
- <khác>
```

Giữ dưới ~500 tokens. Phần dài → tách.

### Memory file

```markdown
---
name: <slug ngắn>
description: <1 dòng cụ thể, future-Claude dùng để judge relevance>
type: <user | feedback | project | reference>
---

<nội dung chính>

**Why:** <lý do — bắt buộc với feedback/project>
**How to apply:** <khi nào áp dụng — bắt buộc với feedback/project>
```

### Subagent

```markdown
---
name: <slug>
description: <khi nào main agent nên delegate — pushy, cụ thể context trigger>
tools: <allow-list, hoặc bỏ trống = inherit>
model: <opus | sonnet | haiku tùy task complexity>
---

<system prompt: vai trò, mục tiêu, ràng buộc, output format, ví dụ nếu cần>
```

### Skill

```markdown
---
name: <slug>
description: <pushy, kê rõ trigger context, không chung chung>
---

# <Tên>

<1-2 dòng skill làm gì>

## Khi nào dùng
<triggers cụ thể>

## Quy trình
<steps>
```

### Slash command

```markdown
---
description: <hiển thị trong /help, ngắn>
---

<prompt template, có thể dùng $ARGUMENTS>
```

### Output style

```markdown
---
name: <slug>
description: <khi nào dùng>
---

<instructions về tone, format, length, không đụng hành vi>
```

### Rules file

```markdown
---
description: <khi nào rule áp dụng, path scope nếu có>
---

<một hành vi ngắn, kèm Why nếu non-obvious>
```

## Reference — Anti-patterns thường gặp

- **CLAUDE.md kể chuyện**: viết như tài liệu kiến trúc dài → chuyển sang `docs/architecture.md`, CLAUDE.md chỉ giữ rules ngắn.
- **Memory không có Why**: "user thích X" mà không nói tại sao → khó judge edge case.
- **`MEMORY.md` phình**: viết nội dung memory thẳng vào index → tách ra file con, index chỉ giữ 1 dòng pointer.
- **Rule chung chung**: "viết code sạch", "test đầy đủ" → không kiểm chứng được, không hữu ích.
- **Trùng giữa CLAUDE.md và memory**: cùng preference ở 2 nơi → khi đổi sẽ lệch, model confused.
- **Subagent description mơ hồ**: "researcher" → main agent không biết khi nào delegate → subagent ít được dùng.
- **Instruction nhắc file/symbol không tồn tại**: code đã rename/xóa → grep verify trước khi tin.
- **User-specific lọt vào project CLAUDE.md**: "tôi thích dùng vim" trong CLAUDE.md root → phải chuyển `~/.claude/CLAUDE.md`.
- **Skill description không pushy đủ**: "skill làm X" → Claude undertrigger → bổ sung trigger context cụ thể.
- **Mix tầng trong 1 file**: file vừa chứa project convention vừa chứa user preference vừa chứa memory → tách rõ.

---

## Project-specific notes (flex-workstation)

- Tài liệu, ghi chú, mô tả task viết tiếng Việt có dấu (theo `CLAUDE.md` root).
- Giữ nguyên tên file, command, package, framework, thuật ngữ kỹ thuật bằng tiếng Anh.
- Khi thêm/sửa skill, subagent, slash command — cập nhật `docs/tasks.md` theo quy ước repo.
- Không đưa secrets/token/connection string vào bất kỳ instruction file nào.
- Skill dùng chung của tổ chức ở `skills/` (top-level repo); skill scope project ở `.claude/skills/`. Skill này nằm `.claude/skills/` vì là cấu hình Claude Code, không phải khuôn workflow chung của team.
