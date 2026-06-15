---
name: claude-workspace-auditor
description: Audits the Claude Code workspace setup across config integrity, permissions, skill sync, hooks, lifecycle coverage, and context hygiene. Use when setting up a new workspace, after changing settings.json or workspace-assistants.json, when a skill fails to trigger, when hooks seem inactive, when CLAUDE.md has grown large, or before onboarding a new developer.
---

# Claude Workspace Auditor

## Tổng quan

Chạy chẩn đoán có cấu trúc qua **6 chiều** của workspace Claude Code và xuất ra báo cáo findings có ưu tiên. Skill chỉ **đọc và báo cáo** — không tự sửa. Với mỗi issue tìm được, skill chỉ rõ skill hoặc command nào nên dùng để xử lý.

Tư duy nền: mọi best practice của Claude Code đều xoay quanh một ràng buộc duy nhất — **cửa sổ context đầy lên rất nhanh và hiệu năng giảm khi đầy**. Workspace tốt cần làm hai việc song song: đưa kiến thức bền vững vào đúng tầng (CLAUDE.md / skills / subagents) và cho Claude cách tự kiểm chứng (test, lint, hook) thay vì bạn phải soát lỗi.

## Khi nào dùng

**Dùng khi:**
- Thiết lập workspace mới lần đầu
- Sau khi chỉnh `settings.json`, `workspace-assistants.json`, hoặc bất kỳ hook script nào
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

## Quy trình Audit

Kiểm tra từng chiều độc lập. Gán trạng thái: ✅ tốt / ⚠️ cảnh báo (chạy được nhưng có rủi ro) / ❌ lỗi (hỏng hoặc cấu hình sai).

### Chiều 1 — Config Integrity (Tính toàn vẹn cấu hình)

Kiểm tra tất cả file config có cấu trúc hợp lệ:

1. Đọc `settings.json` và `settings.local.json` — xác nhận JSON hợp lệ (không trailing comma, ngoặc cân bằng)
2. Đọc `workspace-assistants.json` — xác nhận JSON hợp lệ, có đủ các field bắt buộc (`assistants`, `localSkills`)
3. Kiểm tra tên model trong `settings.json` có nằm trong danh sách hợp lệ không (vd: `claude-sonnet-4-6`, `claude-opus-4-8`)
4. Với mỗi hook entry trong `settings.json`: kiểm tra script path trong `args` có trỏ đến file tồn tại không
5. So sánh `settings.json` với `flex-workstation/templates/project-root/.claude/settings.json` — báo drift nếu có field lệch

**Tiêu chí:**
- ✅ JSON hợp lệ, model name đúng, tất cả script path tồn tại, không có drift
- ⚠️ Drift ở field không quan trọng
- ❌ JSON lỗi, model name không nhận ra, hoặc script path bị thiếu

---

### Chiều 2 — Skill Sync Health (Trạng thái đồng bộ skill)

Xác minh các skill đã khai báo thực sự tồn tại và được sync đúng:

1. Với mỗi entry trong `localSkills` của `workspace-assistants.json`:
   - Xác nhận thư mục `path` tồn tại dưới `flex-workstation/`
   - Xác nhận có file `SKILL.md` trong thư mục đó
   - Xác nhận field `name:` trong frontmatter khớp với tên khai báo trong config
2. Với mỗi `externalSources`: xác nhận path `cloneTo` tồn tại và không rỗng (không chỉ có `.gitkeep`)
3. So sánh danh sách thư mục trong `.claude/skills/` và `.agents/skills/` — phải khớp nhau
4. Kiểm tra skill stale trong `.claude/skills/` hoặc `.agents/skills/` không còn được khai báo trong config
5. Với skill có side-effect (deploy, tạo PR, gửi message): kiểm tra có `disable-model-invocation: true` trong frontmatter không — skill loại này chỉ nên chạy khi người dùng gõ tay, không tự trigger

**Tiêu chí:**
- ✅ Tất cả skill khai báo có `SKILL.md` hợp lệ, hai target khớp nhau, không có stale entry
- ⚠️ External source tồn tại nhưng có vẻ shallow/rỗng; hoặc skill có side-effect nhưng thiếu `disable-model-invocation`
- ❌ Thiếu `SKILL.md`, name không khớp, hoặc hai target lệch nhau

---

### Chiều 3 — Permissions Fitness (Mức độ phù hợp permissions)

Đánh giá danh sách `allow` trong `settings.json` có được hiệu chỉnh hợp lý chưa:

1. Đọc mảng `permissions.allow`
2. Đánh dấu **quá restrictive** nếu chỉ có `Bash(claude --version)` hoặc tương tự — làm việc thực tế sẽ liên tục bị nhắc approve
3. Đánh dấu **quá permissive** nếu có wildcard như `Bash(*)`
4. Kiểm tra các lệnh hay dùng mà chưa có trong allow list: `git`, `npm`, `node`, `powershell`
5. Ghi nhận các entry trong `settings.local.json` override hoặc mở rộng permissions
6. Kiểm tra **CLI tools vs MCP gap**: nếu `enabledPlugins` rỗng mà không có CLI tool nào pre-approve (`gh`, `aws`, `gcloud`), đây là gap kết nối external system — không phải lỗi config nhưng hạn chế năng lực Claude trong workflow thực tế. Docs Anthropic khuyến nghị ưu tiên CLI tool trước MCP vì tiết kiệm context hơn.

**Hành động nếu quá restrictive:** chạy skill `/fewer-permission-prompts` để phân tích transcript và sinh allowlist phù hợp.

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

---

## Dấu hiệu đỏ (cần audit ngay)

- Gõ keyword của skill nhưng skill không engage — khả năng cao là vấn đề sync hoặc name mismatch
- Hook event kích hoạt nhưng không có gì xảy ra — script path hỏng hoặc matcher quá hẹp
- `.claude/skills/` và `.agents/skills/` có số lượng thư mục khác nhau sau khi sync
- `workspace-assistants.json` khai báo `localSkills` path nhưng thư mục không tồn tại
- Danh sách `permissions.allow` rỗng hoặc chỉ có `Bash(claude --version)` sau khi workspace đã dùng thực tế
- Claude hay "quên" chỉ dẫn trong CLAUDE.md — dấu hiệu file quá dài, context bị đầy sớm
- Claude kết thúc lượt mà không báo lỗi nhưng test thực ra đang fail — thiếu Stop hook

---

## Xác minh hoàn thành

Một lần audit được coi là xong khi:

- [ ] Cả 6 chiều đã được kiểm tra và có trạng thái rõ ràng
- [ ] Mỗi ❌ có hành động cụ thể đi kèm (không chỉ "cần sửa")
- [ ] Mỗi ⚠️ đã được xác nhận là rủi ro chấp nhận được hoặc nâng lên ❌
- [ ] Findings được sắp xếp theo độ ưu tiên (❌ trước)
- [ ] Có ít nhất một follow-up action hoặc skill được gợi ý nếu tìm thấy issue
