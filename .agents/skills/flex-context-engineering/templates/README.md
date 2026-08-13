# Agent Context Starter Kit

Bộ template cho `AGENTS.md` + `CLAUDE.md` + `.claude/rules/`. Dùng khi thực hiện `flex-context-engineering` cho một repo chưa có rules file, hoặc khi rules file hiện tại đã phình to / lệch thực tế.

## Nguyên tắc nền

Một quy tắc quyết định mọi thứ còn lại: **AGENTS.md là nguồn sự thật duy nhất, CLAUDE.md chỉ import nó và thêm phần đặc thù Claude Code.** Claude Code đọc `CLAUDE.md`, không đọc `AGENTS.md`; import bằng cú pháp `@AGENTS.md` giải quyết việc này mà không phải duy trì hai bản.

Quy tắc thứ hai: **nếu agent tự suy ra được từ repo, đừng viết vào file.** Cây thư mục, danh sách dependency, mô tả kiến trúc chung — agent đọc được từ code. Viết vào chỉ tốn context và làm loãng những chỉ dẫn thật sự quan trọng.

## Cách dùng

```bash
# 1. Copy vào repo
cp AGENTS.md CLAUDE.md /path/to/repo/
cp -r .claude /path/to/repo/
cp CLAUDE.local.md.example /path/to/repo/CLAUDE.local.md

# 2. Gitignore file cá nhân
echo "CLAUDE.local.md" >> /path/to/repo/.gitignore

# 3. Điền TODO_ trong AGENTS.md (bắt buộc), xoá mọi mục không áp dụng
# 4. Xoá các rule không dùng trong .claude/rules/

# 5. Kiểm tra đã nạp đúng
claude
> /context      # xem mục "Memory files"
> /memory       # mở & sửa nhanh
```

Nếu repo chưa có gì: chạy `/init` để Claude sinh bản nháp từ codebase, **rồi cắt mạnh**. File context do LLM sinh ra thường làm giảm tỉ lệ thành công và tăng chi phí, chủ yếu vì lặp lại thông tin đã có sẵn trong repo. Dùng `/init` như điểm khởi đầu, không phải sản phẩm cuối.

Nếu không cần thêm gì riêng cho Claude Code, thay `CLAUDE.md` bằng symlink:

```bash
ln -s AGENTS.md CLAUDE.md   # không dùng được trên Windows nếu thiếu quyền admin
```

## Đặt nội dung ở đâu

| Loại | Nơi đặt | Nạp khi nào |
|---|---|---|
| Quy ước toàn dự án | `AGENTS.md` (qua `@AGENTS.md`) | Mọi session |
| Đặc thù Claude Code | `CLAUDE.md` phần dưới import | Mọi session |
| Quy ước theo nhóm file | `.claude/rules/*.md` + `paths:` | Khi Claude đọc file khớp |
| Quy ước chung nhưng tách file cho gọn | `.claude/rules/*.md` không `paths:` | Mọi session |
| Sở thích cá nhân, 1 dự án | `CLAUDE.local.md` (gitignore) | Mọi session |
| Sở thích cá nhân, mọi dự án | `~/.claude/CLAUDE.md` | Mọi session |
| Chuẩn toàn công ty | Managed policy CLAUDE.md | Mọi session, không tắt được |
| Quy trình nhiều bước, thỉnh thoảng dùng | Skill | Khi được gọi / khi liên quan |
| Ràng buộc phải chặn cứng | Hook `PreToolUse`, `permissions.deny` | Luôn, không phụ thuộc model |

Điểm dễ nhầm nhất: CLAUDE.md **không phải cấu hình bắt buộc**, nó là context. Model đọc và cố tuân theo, nhưng không có bảo đảm tuyệt đối. Thứ nào bắt buộc phải chặn — xoá DB, push lên main, đọc file secret — phải viết thành hook hoặc permission, không phải một dòng "NEVER" trong markdown.

## Thứ tự nạp (nối chuỗi, không ghi đè)

Từ rộng đến hẹp, file nạp sau nằm cuối context nên có trọng số thực tế cao hơn khi mâu thuẫn:

```
managed policy CLAUDE.md
  → ~/.claude/CLAUDE.md         (user)
  → ~/.claude/rules/*.md        (user rules)
  → <root>/CLAUDE.md            (đi từ gốc filesystem xuống cwd)
  → <root>/CLAUDE.local.md
  → <cwd>/CLAUDE.md  hoặc  <cwd>/.claude/CLAUDE.md
  → <cwd>/.claude/rules/*.md
  → <cwd>/CLAUDE.local.md
```

CLAUDE.md ở thư mục con **dưới** cwd không nạp lúc khởi động — chúng nạp khi Claude đọc file trong thư mục đó.

## Monorepo

```
repo/
├── AGENTS.md                 # quy ước chung: pnpm, commit, security
├── CLAUDE.md                 # @AGENTS.md + phần Claude Code
├── .claude/
│   ├── rules/
│   │   ├── security.md       # không paths → luôn nạp
│   │   ├── testing.md        # paths: **/*.test.ts
│   │   └── api.md            # paths: services/*/src/api/**
│   └── settings.local.json   # claudeMdExcludes cho team khác
├── apps/web/
│   ├── AGENTS.md             # đặc thù frontend
│   └── CLAUDE.md             # @AGENTS.md
└── services/billing/
    ├── AGENTS.md
    └── CLAUDE.md             # @AGENTS.md
```

- Mở Claude Code từ **root repo** khi task cắt ngang nhiều package; từ thư mục package khi task nằm gọn trong đó.
- File cấp package chỉ chứa phần **khác** với root. Không lặp lại.
- Bị nhiễm CLAUDE.md của team khác? Dùng `claudeMdExcludes` trong `.claude/settings.local.json`:

```json
{
  "claudeMdExcludes": ["**/other-team/**/CLAUDE.md"]
}
```

## Tham khảo

- Claude Code — memory & CLAUDE.md: https://code.claude.com/docs/en/memory
- Claude Code — hooks: https://code.claude.com/docs/en/hooks-guide
- Claude Code — skills: https://code.claude.com/docs/en/skills
- Đặc tả AGENTS.md: https://agents.md
- GitHub, phân tích 2.500+ agents.md: https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/
