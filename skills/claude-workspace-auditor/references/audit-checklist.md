# Audit Checklist

Đọc file này khi chạy `claude-workspace-auditor`. Mục tiêu là giữ `SKILL.md` gọn, còn checklist chi tiết nằm ở đây.

## Canonical Workspace Structure

Kiểm tra workspace có tách đúng các tầng Claude Code theo vai trò không. Dùng cấu trúc chuẩn này làm baseline, nhưng không yêu cầu mọi project phải có mọi file ngay từ ngày đầu:

```text
my-project/
├── CLAUDE.md                      # Context bền vững, nạp mỗi session -> giữ ngắn
├── CLAUDE.local.md                # Ghi chú cá nhân, phải gitignore nếu tồn tại
├── SPEC.md                        # Spec feature hiện tại, sinh ra trước khi code
├── .claude/
│   ├── settings.json              # Permissions + hooks deterministic gates
│   ├── skills/                    # Kiến thức/workflow nạp theo nhu cầu
│   ├── agents/                    # Subagent chạy trong context riêng
│   └── commands/                  # Slash command thuần nếu dùng
├── scripts/
│   ├── verify.sh                  # Test + lint + typecheck bằng 1 lệnh
│   └── block-sensitive-writes.sh  # Guard script gọi từ PreToolUse hook
├── src/<module>/CLAUDE.md         # Context module nạp on-demand
├── tests/                         # Verification là trung tâm của setup
└── docs/git-instructions.md       # Import vào CLAUDE.md bằng @docs/...
```

Checklist:

1. Root có `CLAUDE.md`; nếu có `CLAUDE.local.md` thì `.gitignore` phải ignore file này.
2. Root có `SPEC.md`, `docs/SPEC.md`, hoặc `spec/` khi workspace đang theo spec-first workflow. Nếu không có spec, báo `⚠️` trừ khi project chưa có feature active.
3. `.claude/settings.json` tồn tại và là source cho permissions/hooks; `.claude/skills/`, `.claude/agents/`, `.claude/commands/` tồn tại nếu workspace dùng các tầng tương ứng.
4. `scripts/verify.sh`, `scripts/verify.ps1`, `Makefile` target `verify`, hoặc command tương đương tồn tại. Nếu thiếu, Stop hook không có gate đáng tin.
5. Nếu template có hook hoặc guard script, các path được tham chiếu phải tồn tại và phù hợp với runtime config hiện tại.
6. Có `tests/` hoặc test command rõ ràng trong package/tooling. Nếu không có tests, verification story yếu.
7. Với repo nhiều module, tìm `src/*/CLAUDE.md`, package/module-level `CLAUDE.md`, hoặc rules path-scoped. Nếu root CLAUDE chứa nhiều rule module mà không có module-level context, báo `⚠️`.
8. Nếu `CLAUDE.md` trỏ tới tài liệu dài, ưu tiên import/pointer dạng `@docs/...` thay vì copy nội dung.

Tiêu chí:

- `✅` Các tầng chính có mặt và đúng vai trò: root context ngắn, runtime `.claude/`, verify script, guard script, tests/docs/module context phù hợp quy mô repo.
- `⚠️` Thiếu tầng hữu ích nhưng chưa phá workflow, ví dụ thiếu `SPEC.md`, thiếu module-level CLAUDE trong repo nhỏ, thiếu commands dù không dùng slash commands.
- `❌` `CLAUDE.local.md` có nguy cơ bị commit, không có root `CLAUDE.md`, hoặc không có verification path nào để Claude tự kiểm chứng.

Khi báo cáo, dùng nhãn:

- `not applicable`: tầng không phù hợp với repo này, ví dụ repo rất nhỏ không có module con.
- `not checked`: agent không đủ quyền, file không đọc được, hoặc thiếu dữ liệu để kết luận.
