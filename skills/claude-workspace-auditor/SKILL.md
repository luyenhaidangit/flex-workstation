---
name: claude-workspace-auditor
description: Audits the Claude Code workspace setup across config integrity, permissions, skill sync, hooks, and lifecycle coverage. Use when setting up a new workspace, after changing settings.json or workspace-assistants.json, when a skill fails to trigger, when hooks seem inactive, or before onboarding a new developer.
---

# Claude Workspace Auditor

## Tổng quan

Chạy chẩn đoán có cấu trúc qua 5 chiều của workspace Claude Code và xuất ra báo cáo findings có ưu tiên. Skill chỉ **đọc và báo cáo** — không tự sửa. Với mỗi issue tìm được, skill chỉ rõ skill hoặc command nào nên dùng để xử lý.

## Khi nào dùng

**Dùng khi:**
- Thiết lập workspace mới lần đầu
- Sau khi chỉnh `settings.json`, `workspace-assistants.json`, hoặc bất kỳ hook script nào
- Một skill không trigger dù gõ đúng keyword
- Hook có vẻ không chạy (không thấy output, không có phản hồi)
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

**Tiêu chí:**
- ✅ Tất cả skill khai báo có `SKILL.md` hợp lệ, hai target khớp nhau, không có stale entry
- ⚠️ External source tồn tại nhưng có vẻ shallow/rỗng
- ❌ Thiếu `SKILL.md`, name không khớp, hoặc hai target lệch nhau

---

### Chiều 3 — Permissions Fitness (Mức độ phù hợp permissions)

Đánh giá danh sách `allow` trong `settings.json` có được hiệu chỉnh hợp lý chưa:

1. Đọc mảng `permissions.allow`
2. Đánh dấu **quá restrictive** nếu chỉ có `Bash(claude --version)` hoặc tương tự — làm việc thực tế sẽ liên tục bị nhắc approve
3. Đánh dấu **quá permissive** nếu có wildcard như `Bash(*)`
4. Kiểm tra các lệnh hay dùng mà chưa có trong allow list: `git`, `npm`, `node`, `powershell`
5. Ghi nhận các entry trong `settings.local.json` override hoặc mở rộng permissions

**Hành động nếu quá restrictive:** chạy skill `/fewer-permission-prompts` để phân tích transcript và sinh allowlist phù hợp.

**Tiêu chí:**
- ✅ Allow list phủ đủ lệnh thường dùng, không có wildcard
- ⚠️ Chỉ có entry tối thiểu — sẽ bị hỏi liên tục khi làm việc thực
- ❌ Có wildcard permission (`Bash(*)`)

---

### Chiều 4 — Hooks Validation (Kiểm tra hooks)

Xác minh hooks được cấu hình đúng và script có thể reach được:

1. Đọc phần `hooks` trong `settings.json`
2. Với mỗi hook event (vd: `PreToolUse`, `PostToolUse`, `SessionStart`):
   - Xác nhận field `matcher` là regex pattern hợp lệ
   - Xác nhận script trong `command`/`args` tồn tại ở path đó
   - Ghi chú nếu dùng absolute path (dễ hỏng khi đổi máy) thay vì relative path
3. Kiểm tra không có hook dùng path chỉ tồn tại trên một máy — nên dùng relative path từ `flex-workstation/scripts/`
4. Kiểm tra thư mục `.claude/hooks/` — nếu tồn tại và không rỗng, xác nhận các file ở đó là có chủ đích

**Tiêu chí:**
- ✅ Tất cả hook có matcher hợp lệ, script path tồn tại, dùng relative path
- ⚠️ Dùng absolute path trong args hook (chạy được trên máy hiện tại, dễ hỏng ở máy khác)
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

---

## Dấu hiệu đỏ (cần audit ngay)

- Gõ keyword của skill nhưng skill không engage — khả năng cao là vấn đề sync hoặc name mismatch
- Hook event kích hoạt nhưng không có gì xảy ra — script path hỏng hoặc matcher quá hẹp
- `.claude/skills/` và `.agents/skills/` có số lượng thư mục khác nhau sau khi sync
- `workspace-assistants.json` khai báo `localSkills` path nhưng thư mục không tồn tại
- Danh sách `permissions.allow` rỗng hoặc chỉ có `Bash(claude --version)` sau khi workspace đã dùng thực tế

---

## Xác minh hoàn thành

Một lần audit được coi là xong khi:

- [ ] Cả 5 chiều đã được kiểm tra và có trạng thái rõ ràng
- [ ] Mỗi ❌ có hành động cụ thể đi kèm (không chỉ "cần sửa")
- [ ] Mỗi ⚠️ đã được xác nhận là rủi ro chấp nhận được hoặc nâng lên ❌
- [ ] Findings được sắp xếp theo độ ưu tiên (❌ trước)
- [ ] Có ít nhất một follow-up action hoặc skill được gợi ý nếu tìm thấy issue
