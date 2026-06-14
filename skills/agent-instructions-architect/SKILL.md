---
name: agent-instructions-architect
description: >
  Dùng khi người dùng muốn viết, audit, tách, gộp, chuyển tầng hoặc dọn
  instruction files của Claude Code: CLAUDE.md (project / subdir / user-global),
  MEMORY.md, memory files, rules files, subagent prompts, SKILL.md, slash commands,
  output styles. Trigger khi user nói "viết CLAUDE.md cho repo này",
  "memory lộn xộn dọn giúp", "rule này nên đặt ở đâu", "CLAUDE.md dài quá tách giúp",
  "tạo subagent X viết prompt cho nó", "review instructions có mâu thuẫn không",
  "cách viết description SKILL.md để trigger đúng", "output style cho session debug",
  "where should this rule live", "is my CLAUDE.md too long",
  "how do I write a good subagent prompt".
  Không dùng khi yêu cầu về hooks, MCP servers, permissions, statusLine
  hoặc settings.json non-prompt — đó không thuộc tầng instruction.
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

**Input yêu cầu:** mô tả loại file cần tạo và mục đích.
**Input tùy chọn:** target path, constraints, ví dụ mẫu. Nếu thiếu → hỏi tối đa 3 câu.

### Quy trình

1. **Làm rõ tối đa 3 câu** (bỏ qua câu nào đã rõ từ yêu cầu):
   - **Ai/khi nào áp dụng?** Mọi session trong project / chỉ subdir / chỉ user này / chỉ subagent / chỉ khi user gõ slash command / khi cần đổi format output
   - **Stable hay học dần?** Stable, đã chốt → CLAUDE.md hoặc rules. Còn học, tích lũy theo conversation → memory.
   - **Khuôn hành vi hay khuôn trình bày?** Hành vi (làm gì, tránh gì) → CLAUDE.md / rules / memory. Trình bày (tone, format, length) → output style.

2. **Chọn tầng** theo `references/decision-tree.md`.

3. **Viết file** theo template tương ứng trong `references/templates.md`.

4. **Verify** bằng Principles (`references/principles.md`): cụ thể chưa? có Why chưa? đúng tầng chưa? cold-read được không?

5. Nếu là memory mới → thêm 1 dòng vào `MEMORY.md`. Nếu là subagent/skill/command mới và project có registry → cập nhật.

### Ví dụ

User: "Tạo subagent `db-migrator` chuyên viết và review migration Postgres"

- Làm rõ: tools cần (Read, Edit, Bash), model tier (Sonnet đủ), có cần worktree không
- Chọn tầng: subagent (`.claude/agents/db-migrator.md`)
- Viết theo template subagent: description cụ thể đủ để main agent biết khi nào delegate (vd "khi user tạo/sửa migration Postgres, đặc biệt khi có ALTER TABLE trên bảng lớn"), system prompt có ràng buộc nghiệp vụ (luôn dùng transaction reversible, không drop column trực tiếp...)
- Verify: description không chung chung, prompt có Why cho ràng buộc

**Xong khi:** file đã được tạo, verify pass, và registry (nếu có) đã cập nhật.

---

## Chế độ 2 — Review

Audit tầng instructions, ra punch list. Không sửa luôn — đợi user duyệt mới chuyển Improve.

**Input yêu cầu:** scope review (một file cụ thể, toàn bộ project, hoặc global).
**Input tùy chọn:** focus area (vd "chỉ check memory", "chỉ check CLAUDE.md root"). Nếu scope không rõ → hỏi 1 câu.

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

2. **Đọc và check** theo các nhóm vấn đề trong `references/anti-patterns.md`:
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

**Xong khi:** punch list đã trả trong chat và user chưa yêu cầu Improve.

---

## Chế độ 3 — Improve

Refactor instruction files theo punch list (từ Review hoặc user nêu trực tiếp).

**Input yêu cầu:** punch list hoặc mô tả vấn đề cần sửa.
**Input tùy chọn:** thứ tự ưu tiên. Nếu chưa có punch list → chạy Review trước.

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

**Xong khi:** user confirm và commit message đã được đề xuất.

---

## Tài liệu tham khảo

- `references/decision-tree.md` — chọn tầng instruction nào cho từng loại nội dung
- `references/principles.md` — 10 nguyên tắc viết instructions tốt (với Why)
- `references/templates.md` — template cho mỗi loại file (CLAUDE.md, memory, subagent, skill, command, output style, rules)
- `references/anti-patterns.md` — danh sách lỗi thường gặp và cách nhận biết

## Project-specific notes (flex-workstation)

Áp dụng convention ngôn ngữ, bảo mật và docs update theo `CLAUDE.md` root.

Skill dùng chung của tổ chức ở `skills/` (top-level repo); skill scope project ở `.claude/skills/`. Skill này nằm `.claude/skills/` vì là cấu hình Claude Code, không phải khuôn workflow chung của team.
