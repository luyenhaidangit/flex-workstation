@AGENTS.md

<!--
  Claude Code đọc CLAUDE.md, KHÔNG đọc AGENTS.md.
  Dòng @AGENTS.md ở trên là cú pháp import: nội dung AGENTS.md được nạp
  nguyên văn vào context lúc khởi động session.
  => Không copy-paste lại nội dung AGENTS.md xuống dưới. Chỉ viết phần
     ĐẶC THÙ của Claude Code.
  Nếu không cần thêm gì riêng: dùng symlink thay cho file này
  (`ln -s AGENTS.md CLAUDE.md`) — trừ Windows, hãy giữ import.
-->

## Claude Code

### Workflow

- Task đụng vào TODO_`src/billing/`, TODO_`src/auth/` hoặc schema DB: **dùng plan mode**, trình bày kế hoạch và chờ duyệt trước khi sửa code.
- Task > 3 file: liệt kê file định sửa trước, rồi mới sửa.
- Sau khi sửa xong: chạy `TODO_pnpm lint && pnpm typecheck && pnpm test`, tự sửa lỗi phát sinh, rồi mới báo cáo.
- Ưu tiên `TODO_pnpm test <file>` khi lặp; chỉ chạy full suite ở bước cuối.

### Tool usage

- Đọc file bằng Read/Grep/Glob, **không** dùng `cat`/`grep` qua Bash cho việc tìm kiếm.
- Dùng subagent (Task tool) cho việc dò tìm rộng trong codebase để tiết kiệm context của session chính.
- TODO_MCP server `<tên>` dùng để `<mục đích>`; không gọi cho việc khác.

### Nơi đặt tri thức (đọc mục này trước khi định thêm gì vào CLAUDE.md)

| Loại nội dung | Đặt ở đâu |
|---|---|
| Quy ước áp dụng cho MỌI session | `AGENTS.md` |
| Quy ước chỉ áp dụng cho một nhóm file | `.claude/rules/*.md` + frontmatter `paths:` |
| Quy trình nhiều bước, thỉnh thoảng mới dùng | Skill (`.claude/skills/`) |
| Ràng buộc phải CHẶN bằng mọi giá | Hook `PreToolUse` / `permissions.deny` |
| Sở thích cá nhân, không share team | `CLAUDE.local.md` (gitignore) hoặc `~/.claude/CLAUDE.md` |

<!--
  Nhắc maintainer:
  - Kiểm tra file đã nạp: chạy /context, xem mục "Memory files".
  - Xem & sửa nhanh: /memory
  - Nhờ Claude cắt bớt file phình to: /doctor
-->
