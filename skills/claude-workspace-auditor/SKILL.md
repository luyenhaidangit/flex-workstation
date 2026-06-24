---
name: claude-workspace-auditor
description: >
  Audits whether a Claude Code workspace is architected well for coding:
  canonical project structure, config integrity, permissions, template integrity,
  hooks, lifecycle coverage, and context hygiene. Use when setting up a new
  workspace, after changing settings.json or workspace templates, when a
  skill fails to trigger, when hooks seem inactive, when CLAUDE.md has grown
  large, or before onboarding a new developer. Do not use for reviewing one
  skill file; use skill-reviewer instead.
---

# Claude Workspace Auditor

## Tổng quan

Chạy chẩn đoán có cấu trúc qua **7 chiều** của workspace Claude Code và xuất ra báo cáo findings có ưu tiên. Skill chỉ **đọc và báo cáo** — không tự sửa. Với mỗi issue tìm được, skill chỉ rõ skill hoặc command nào nên dùng để xử lý.

Tư duy nền: mọi best practice của Claude Code đều xoay quanh một ràng buộc duy nhất — **cửa sổ context đầy lên rất nhanh và hiệu năng giảm khi đầy**. Workspace tốt cần làm hai việc song song: đưa kiến thức bền vững vào đúng tầng (CLAUDE.md / skills / subagents) và cho Claude cách tự kiểm chứng (test, lint, hook) thay vì bạn phải soát lỗi.

## Khi nào dùng

**Dùng khi:**
- Thiết lập workspace mới lần đầu
- Sau khi chỉnh `settings.json`, workspace template, hoặc bất kỳ hook script nào
- Một skill không trigger dù gõ đúng keyword
- Hook có vẻ không chạy (không thấy output, không có phản hồi)
- CLAUDE.md đã phình to và nghi ngờ Claude đang bỏ qua chỉ dẫn quan trọng
- Trước khi onboard developer mới để đảm bảo baseline sạch
- Định kỳ health check sau refactor lớn

**Không dùng khi:**
- Muốn viết hoặc cải thiện skill → dùng `agent-instructions-architect` hoặc `skill-creator`
- Muốn review chất lượng một skill cụ thể → dùng `skill-reviewer`
- Đã biết rõ vấn đề cụ thể → xử lý thẳng, không cần audit toàn bộ

---

## Input

**Bắt buộc:** workspace root hoặc path repo cần audit. Nếu user không đưa path, dùng current working directory.

**Tùy chọn:**
- Focus area: một chiều cụ thể như `hooks`, `skills`, `context hygiene`, `canonical structure`
- Assistant target: `claude`, `codex`, hoặc `both`; mặc định là `both` nếu workspace có cả `.claude/` và `.agents/`
- Mode: `quick` cho health check nhanh, `full` cho audit đủ 7 chiều; mặc định là `full`

Nếu path không tồn tại hoặc không đọc được, dừng và hỏi lại path đúng. Nếu thiếu focus area, tự chạy full audit thay vì hỏi.

---

## Quy trình Audit

Kiểm tra từng chiều độc lập. Gán trạng thái: ✅ tốt / ⚠️ cảnh báo (chạy được nhưng có rủi ro) / ❌ lỗi (hỏng hoặc cấu hình sai).

### Chiều 0 — Canonical Workspace Structure (Kiến trúc thư mục chuẩn)

Đọc `references/audit-checklist.md`, phần "Canonical Workspace Structure". Kiểm tra workspace có tách đúng các tầng Claude Code theo vai trò không. Dùng cấu trúc chuẩn làm baseline, nhưng phân biệt rõ `not applicable` với issue thật; repo nhỏ không bắt buộc có mọi file ngay từ ngày đầu.

**Tiêu chí:**
- ✅ Các tầng chính có mặt và đúng vai trò: root context ngắn, runtime `.claude/`, verify script, guard script, tests/docs/module context phù hợp quy mô repo
- ⚠️ Thiếu tầng hữu ích nhưng chưa phá workflow, ví dụ thiếu `SPEC.md`, thiếu module-level CLAUDE trong repo nhỏ, thiếu commands dù không dùng slash commands
- ❌ `CLAUDE.local.md` có nguy cơ bị commit, không có root `CLAUDE.md`, hoặc không có verification path nào để Claude tự kiểm chứng

---

### Chiều 1 — Config Integrity (Tính toàn vẹn cấu hình)

Kiểm tra tất cả file config có cấu trúc hợp lệ:

1. Đọc `settings.json` và `settings.local.json` — xác nhận JSON hợp lệ (không trailing comma, ngoặc cân bằng)
2. Kiểm tra tên model trong `settings.json` theo allowlist/local docs nếu repo có khai báo. Nếu không có nguồn xác thực hiện tại, flag là "cần verify" thay vì kết luận model sai.
3. Với mỗi hook entry trong `settings.json`: kiểm tra script path trong `args` có trỏ đến file tồn tại không
4. So sánh `settings.json` với `flex-workstation/workspaces/templates/.claude/settings.json` — báo drift nếu có field lệch
5. Nếu workspace có template scaffold (`workspaces/templates/`), kiểm tra root `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`, `.agents/` và `.codex/config.toml` có được mirror từ template theo policy của repo không

**Tiêu chí:**
- ✅ JSON hợp lệ, model name đúng, tất cả script path tồn tại, không có drift
- ⚠️ Drift ở field không quan trọng
- ❌ JSON lỗi, model name không nhận ra, hoặc script path bị thiếu

---

### Chiều 2 — Template và skill source health

Xác minh template và skill source tồn tại đúng vị trí:

1. Xác nhận `workspaces/templates/` có `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/` và `.codex/`
2. Với mỗi skill dưới `skills/`: xác nhận có `SKILL.md` và frontmatter hợp lệ
3. Với skill có side-effect (deploy, tạo PR, gửi message): kiểm tra có `disable-model-invocation: true` trong frontmatter không — skill loại này chỉ nên chạy khi người dùng gõ tay, không tự trigger
4. Không suy diễn `.claude/skills/` hoặc `.agents/skills/` là output được sync nếu bootstrap không có cơ chế sync

**Tiêu chí:**
- ✅ Template đầy đủ và mọi skill source có `SKILL.md` hợp lệ
- ⚠️ Skill có side-effect nhưng thiếu `disable-model-invocation`
- ❌ Thiếu file template bắt buộc hoặc `SKILL.md` không hợp lệ

---

### Chiều 3 — Permissions Fitness (Mức độ phù hợp permissions)

Đánh giá danh sách `allow` trong `settings.json` có được hiệu chỉnh hợp lý chưa:

1. Đọc mảng `permissions.allow`
2. Đánh dấu **quá restrictive** nếu chỉ có `Bash(claude --version)` hoặc tương tự — làm việc thực tế sẽ liên tục bị nhắc approve
3. Đánh dấu **quá permissive** nếu có wildcard như `Bash(*)`
4. Kiểm tra các lệnh hay dùng mà chưa có trong allow list: `git`, `npm`, `node`, `powershell`
5. Ghi nhận các entry trong `settings.local.json` override hoặc mở rộng permissions
6. Kiểm tra **CLI tools vs MCP gap**: nếu `enabledPlugins` rỗng mà không có CLI tool nào pre-approve (`gh`, `aws`, `gcloud`), đây là gap kết nối external system — không phải lỗi config nhưng hạn chế năng lực Claude trong workflow thực tế. Docs Anthropic khuyến nghị ưu tiên CLI tool trước MCP vì tiết kiệm context hơn.

**Hành động nếu quá restrictive:** nếu workspace có command/skill `fewer-permission-prompts`, dùng nó để phân tích transcript và sinh allowlist phù hợp. Nếu không có, đề xuất phân tích transcript thủ công và thêm allowlist tối thiểu cho các lệnh đã dùng lặp lại.

**Tiêu chí:**
- ✅ Allow list phủ đủ lệnh thường dùng, không có wildcard
- ⚠️ Chỉ có entry tối thiểu — sẽ bị hỏi liên tục khi làm việc thực; hoặc không có CLI tool nào cho external system
- ❌ Có wildcard permission (`Bash(*)`)

---

### Chiều 4 — Hooks Validation (Kiểm tra hooks)

Xác minh hooks được cấu hình đúng, script có thể reach được, **và bộ hook tối thiểu đã có mặt**:

1. Đọc phần `hooks` trong `settings.json`
2. Với mỗi hook event:
   - Xác nhận field `matcher` là regex pattern hợp lệ
   - Xác nhận script trong `command`/`args` tồn tại ở path đó
   - Ghi chú nếu dùng absolute path (dễ hỏng khi đổi máy) thay vì relative path
3. Kiểm tra **bộ hook tối thiểu** theo khuyến nghị Anthropic:

   | Hook | Mục đích | Cần thiết |
   |------|----------|-----------|
   | `PreToolUse` | Guard — chặn ghi vào thư mục nhạy cảm, kiểm tra trước khi sửa | Nên có |
   | `PostToolUse` | Auto-format sau khi sửa file | Nên có với dự án có formatter |
   | `Stop` | Chạy verify script trước khi Claude kết thúc lượt — guardrail mạnh nhất | **Quan trọng nhất** |

4. Nếu không có `Stop` hook: đây là gap lớn nhất. Stop hook chạy `verify.sh` (test + lint + typecheck) đảm bảo Claude không kết thúc lượt khi có lỗi — thay thế việc bạn phải soát thủ công.
5. Kiểm tra thư mục `.claude/hooks/` — nếu tồn tại và không rỗng, xác nhận các file ở đó là có chủ đích
6. Kiểm tra PreToolUse guard có thật sự chặn ghi vào runtime/generated hoặc sensitive paths (`.claude/skills`, `.agents/skills`, secrets, env files) khi project có các path này

**Tiêu chí:**
- ✅ Tất cả hook có matcher hợp lệ, script tồn tại, dùng relative path; có ít nhất `PreToolUse` và `Stop`
- ⚠️ Dùng absolute path; hoặc thiếu `Stop` hook; hoặc có `PreToolUse` nhưng không có verify gate
- ❌ Script path của hook không tồn tại

---

### Chiều 5 — Lifecycle Skill Coverage (Phủ sóng lifecycle)

Đánh giá các skill hiện có có phủ đủ vòng đời phát triển chưa:

Map từng skill trong `.claude/skills/` vào phase tương ứng:

| Phase | Cần phủ | Tìm kiếm skill nào |
|-------|---------|---------------------|
| Define | Làm rõ yêu cầu | `interview-me`, `idea-refine`, `spec-driven-development` |
| Plan | Chia nhỏ công việc | `planning-and-task-breakdown` |
| Build | Implement đúng | `incremental-implementation`, `test-driven-development`, `source-driven-development`, `frontend-ui-engineering`, `api-and-interface-design` |
| Verify | Bắt lỗi trước review | `debugging-and-error-recovery`, `browser-testing-with-devtools` |
| Review | Quality gate | `code-review-and-quality`, `code-simplification`, `security-and-hardening` |
| Ship | Deploy an toàn | `git-workflow-and-versioning`, `ci-cd-and-automation`, `shipping-and-launch` |

Báo gap nếu có phase nào không có skill nào.

Ngoài skills, kiểm tra `.claude/commands/` hoặc `.agents/commands/` có entrypoints lifecycle nếu workspace dùng slash commands:

| Command | Vai trò |
|---------|---------|
| `spec` | tạo/cập nhật `SPEC.md` trước khi code |
| `plan` | chia task từ spec |
| `build` | implement incremental |
| `test` | chạy verification |
| `review` | quality gate |
| `ship` | pre-launch / release checklist |

**Tiêu chí:**
- ✅ Cả 6 phase đều có ít nhất một skill
- ⚠️ Một phase chỉ có đúng một skill (không có phương án dự phòng)
- ❌ Một hoặc nhiều phase không có skill nào

---

### Chiều 6 — Context Hygiene (Vệ sinh ngữ cảnh)

Đây là chiều quan trọng nhất theo docs Anthropic nhưng thường bị bỏ qua nhất. Mục tiêu: đảm bảo context không bị lãng phí vào những thứ không cần thiết ở đầu mỗi session.

1. **CLAUDE.md bloat check**: Đọc `CLAUDE.md` ở project root. Với mỗi dòng/đoạn, áp dụng bộ lọc của Anthropic:
   - *"Bỏ dòng này đi thì Claude có mắc lỗi không?"* — nếu không, đó là ứng viên cắt bỏ
   - Flag nếu file > 100 dòng
   - Flag nếu có nội dung thuộc về skills (workflow đôi lúc mới dùng), hooks (rule tất định), hoặc docs riêng — những thứ này không nên ở CLAUDE.md

2. **Verification script**: Kiểm tra có file `scripts/verify.sh` (hoặc `scripts/verify.ps1`, `Makefile` với target `verify`) chạy test + lint + typecheck bằng 1 lệnh không. Đây là điều kiện tiên quyết để Stop hook hoạt động có ý nghĩa.

3. **CLAUDE.local.md**: Kiểm tra có file `CLAUDE.local.md` và file này có trong `.gitignore` không. Ghi chú cá nhân (path cục bộ, token tạm, reminder cho bản thân) nên ở đây, không nên commit lên repo.

4. **Module-level CLAUDE.md**: Với repo có nhiều module/subdir lớn, kiểm tra các thư mục quan trọng có `CLAUDE.md` riêng không. Claude nạp on-demand khi đọc file trong thư mục đó — giúp CLAUDE.md root không phải chứa context của từng module.

5. **Subagent definitions**: Kiểm tra `.claude/agents/` có file `.md` nào không. Subagent chạy trong context riêng — tác vụ đọc nhiều file (explore codebase, review, security scan) nên được đẩy sang subagent để giữ session chính sạch.

6. **Docs import hygiene**: Kiểm tra root `CLAUDE.md` có dùng pointer/import cho tài liệu dài (`@docs/...`, `@flex-workstation/README.md`) thay vì copy nguyên nội dung docs. Nếu docs có `git-instructions.md`, architecture, onboarding, hoặc runbook dài mà nội dung bị nhét vào CLAUDE.md, báo ⚠️.

**Tiêu chí:**
- ✅ CLAUDE.md ngắn gọn (< 100 dòng), có verify script, có CLAUDE.local.md trong .gitignore, có subagent definitions
- ⚠️ CLAUDE.md > 100 dòng hoặc chứa nội dung nên ở skill/hook; thiếu verify script; thiếu subagent
- ❌ CLAUDE.local.md tồn tại nhưng không có trong `.gitignore` (rủi ro commit thông tin cá nhân/nhạy cảm)

---

## Định dạng output

Xuất báo cáo theo cấu trúc sau:

```
## Báo cáo Audit Workspace — [ngày]

| Chiều | Trạng thái | Tóm tắt |
|-------|------------|---------|
| Canonical structure   | ✅/⚠️/❌ | Một dòng mô tả kết quả |
| Config integrity       | ✅/⚠️/❌ | Một dòng mô tả kết quả |
| Skill sync health      | ✅/⚠️/❌ | Một dòng mô tả kết quả |
| Permissions fitness    | ✅/⚠️/❌ | Một dòng mô tả kết quả |
| Hooks validation       | ✅/⚠️/❌ | Một dòng mô tả kết quả |
| Lifecycle coverage     | ✅/⚠️/❌ | Một dòng mô tả kết quả |
| Context hygiene        | ✅/⚠️/❌ | Một dòng mô tả kết quả |

## Findings (theo độ ưu tiên)

### ❌ Lỗi cần xử lý
- [finding]: [hành động cụ thể + skill/command nên dùng]

### ⚠️ Cảnh báo
- [finding]: [hành động gợi ý]

### ✅ Ổn
- [xác nhận ngắn gọn chiều này đã pass]
```

---

## Lý do hay bỏ qua (và phản biện)

| Lý do bỏ qua | Phản biện |
|--------------|-----------|
| "Config trông ổn mà" | Drift vô hình — template vs thực tế có thể lệch ở field chỉ quan trọng lúc bootstrap |
| "Skills đang chạy được rồi" | Chạy được ≠ đang load đúng phiên bản; source có thể đã cập nhật nhưng sync chưa chạy |
| "Hỏi permissions thì approve thôi" | Bị hỏi liên tục làm gián đoạn flow và dễ dẫn đến over-approve |
| "Hook chạy tuần trước, vẫn ổn thôi" | Một thay đổi path hoặc script có thể làm hook hỏng im lặng, không có error message |
| "Tôi biết mình có những skill nào" | Phát hiện gap lifecycle cần map skill vào phase, không chỉ đếm tổng số |
| "CLAUDE.md tôi viết cẩn thận lắm" | CLAUDE.md phình to khiến Claude phớt lờ chính những chỉ dẫn quan trọng — độ dài là kẻ thù |
| "Không có Stop hook cũng được, tôi tự check" | Bạn là bottleneck — Stop hook tự động, không bao giờ quên, không mệt mỏi |
| "Repo nhỏ nên không cần verify script" | Càng nhỏ càng dễ có một command verify đơn giản; thiếu verify làm Claude không có bằng chứng kết thúc |

---

## Dấu hiệu đỏ (cần audit ngay)

- Gõ keyword của skill nhưng skill không engage — khả năng cao là vấn đề sync hoặc name mismatch
- Hook event kích hoạt nhưng không có gì xảy ra — script path hỏng hoặc matcher quá hẹp
- `.claude/skills/` và `.agents/skills/` có số lượng thư mục khác nhau sau khi sync
- Có `CLAUDE.local.md` nhưng `.gitignore` không ignore
- Không có `scripts/verify.*`, `Makefile verify`, hoặc test command thay thế
- Root `CLAUDE.md` chứa nội dung docs dài thay vì `@docs/...`
- Danh sách `permissions.allow` rỗng hoặc chỉ có `Bash(claude --version)` sau khi workspace đã dùng thực tế
- Claude hay "quên" chỉ dẫn trong CLAUDE.md — dấu hiệu file quá dài, context bị đầy sớm
- Claude kết thúc lượt mà không báo lỗi nhưng test thực ra đang fail — thiếu Stop hook

---

## Xác minh hoàn thành

Một lần audit được coi là xong khi:

- [ ] Cả 7 chiều đã được kiểm tra và có trạng thái rõ ràng
- [ ] Mỗi ❌ có hành động cụ thể đi kèm (không chỉ "cần sửa")
- [ ] Mỗi ⚠️ đã được xác nhận là rủi ro chấp nhận được hoặc nâng lên ❌
- [ ] Mỗi mục không kiểm được được ghi rõ là `not checked`, và mỗi mục không áp dụng được ghi rõ là `not applicable`
- [ ] Findings được sắp xếp theo độ ưu tiên (❌ trước)
- [ ] Có ít nhất một follow-up action hoặc skill được gợi ý nếu tìm thấy issue
