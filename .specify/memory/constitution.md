<!--
BÁO CÁO TÁC ĐỘNG ĐỒNG BỘ
==================
Thay đổi phiên bản: 1.1.1 -> 1.2.0
Section đã sửa:
  - Nguyên tắc cốt lõi: giữ 5 nguyên tắc hiện có, mở rộng thành cấu trúc có Quy định/Lý do/Áp dụng/Cách kiểm tra/Ngoại lệ
  - Quy trình phát triển: làm rõ cú pháp command dùng được trong Codex (`$speckit-*`) và slash command (`/speckit-*`)
  - Quản trị: mở rộng thành chính sách SemVer, compliance review và lịch sử thay đổi
Đã thêm:
  - Phạm vi áp dụng
  - Quy ước từ khóa
  - Source of Truth và thứ tự ưu tiên artifact
  - Tiêu chuẩn artifact Speckit
  - Cổng chất lượng
  - Definition of Done
  - Checklist review tối thiểu
  - Ngoại lệ và biện minh độ phức tạp
  - Lịch sử thay đổi
Đã bỏ: Không có
Template đã cập nhật:
  ✅ .specify/templates/plan-template.md — đã kiểm tra, đang chứa Constitution Check, traceability, rollout/rollback và observability phù hợp
  ✅ .specify/templates/spec-template.md — đã kiểm tra, đang giữ WHY/WHAT, MVP, quyền, audit, NFR và readiness phù hợp
  ✅ .specify/templates/tasks-template.md — đã kiểm tra, đang có rule traceability, coverage, migration, contract, permission và validation phù hợp
  ✅ .specify/templates/checklist-template.md — đã kiểm tra, không cần đổi cho amendment này
  ✅ .specify/templates/constitution-template.md — source template hiện hành đã được áp dụng vào constitution
  ✅ .specify/templates/commands/*.md — không tồn tại trong workspace này
Tài liệu đã cập nhật:
  ✅ docs/speckit/workflow.md — làm rõ cú pháp `$speckit-*` cho Codex và `/speckit-*` cho slash command
  ✅ docs/speckit/template-guidelines.md — quy ước thiết kế và bảo trì template Speckit
  ✅ docs/speckit/maintenance.md — ghi chú amendment constitution v1.2.0 và bảo trì Speckit
TODO hoãn lại: Không có
-->

# Quy ước flex-workstation

**Phiên bản**: 1.2.0

**Trạng thái**: Active

**Phê chuẩn**: 2026-07-05

**Sửa đổi gần nhất**: 2026-07-11

**Chủ sở hữu**: Nhóm Flex

---

## 1. Mục đích

Quy ước này là nguồn điều phối cao nhất cho `flex-workstation`: cách viết spec,
lập plan, sinh task, review, bootstrap và vận hành AI tooling cho các project Flex.
Nó đảm bảo mọi thay đổi đi qua cùng một chuẩn có thể kiểm tra, không phụ thuộc vào
một agent cụ thể và không làm workstation biến thành nơi triển khai code sản phẩm.

---

## 2. Phạm vi áp dụng

Quy ước này áp dụng cho:

- `spec.md`
- `plan.md`
- `research.md`
- `data-model.md`
- `contracts/`
- `quickstart.md`
- `tasks.md`
- Pull request / code review
- Release / rollback nếu có
- Tài liệu workspace trong `README.md` và `docs/`
- Runtime guidance trong `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`, `.codex/`

---

## 3. Quy ước từ khóa

- **PHẢI**: Bắt buộc tuân thủ. Nếu vi phạm, spec/plan/task/review/release không được thông qua trừ khi có ngoại lệ được phê duyệt.
- **KHÔNG ĐƯỢC**: Bị cấm.
- **NÊN**: Mặc định phải làm, chỉ bỏ qua khi có lý do rõ ràng.
- **CÓ THỂ**: Tùy chọn, áp dụng khi phù hợp.

---

## 4. Source of Truth và thứ tự ưu tiên artifact

Khi có mâu thuẫn giữa các artifact, thứ tự ưu tiên PHẢI là:

1. `constitution.md`
2. `spec.md`
3. `plan.md`
4. `tasks.md`
5. Code implementation

**Quy định**:
- Nếu `plan.md` khác `spec.md`, PHẢI cập nhật `spec.md` hoặc ghi ngoại lệ được phê duyệt.
- Nếu `tasks.md` khác `plan.md`, PHẢI cập nhật `plan.md` trước khi code.
- Nếu code khác task/plan, PR PHẢI giải thích lý do thay đổi.
- AI/dev KHÔNG ĐƯỢC tự mở rộng hoặc thay đổi ý nghĩa nghiệp vụ đã được duyệt trong spec.

---

## 5. Nguyên tắc cốt lõi

### I. Điều phối workspace, không triển khai sản phẩm

**Quy định**: `flex-workstation` điều phối tài liệu, bootstrap, skill source và AI tooling config. Code sản phẩm PHẢI nằm trong sub-repo tương ứng, không nằm trong workstation root.

**Lý do**: Workstation là lớp điều phối chung. Trộn code sản phẩm vào đây sẽ phá vỡ ranh giới repo, lịch sử Git và quy trình release độc lập.

**Áp dụng cho**: `workstation.json`, `docs/`, scripts bootstrap, runtime config, sub-repo trong workspace root.

**Cách kiểm tra**:
- Thay đổi code sản phẩm nằm trong repo con được khai báo trong `workstation.json`.
- Workstation Git ignore toàn bộ thư mục sub-repo.
- PR workstation không chứa thay đổi source code của sub-repo nếu yêu cầu chỉ thuộc workstation.
- Không có submodule, subtree hoặc version link giữa repo khi chưa có yêu cầu rõ ràng.

**Ngoại lệ**:
- Chỉ được sửa code trong sub-repo khi yêu cầu của người dùng nêu rõ repo con đó là phạm vi làm việc.
- Mọi liên kết version giữa repo PHẢI có lý do, người phê duyệt và tài liệu rollback.

### II. Spec trước code

**Quy định**: Mọi tính năng PHẢI bắt đầu bằng spec nghiệp vụ trước khi có implementation. Spec mô tả WHY/WHAT; plan mô tả HOW; tasks chia nhỏ công việc kiểm chứng được.

**Lý do**: Spec là nguồn sự thật nghiệp vụ. Code theo sau spec để tránh scope creep, assumption âm thầm và implementation không trace được.

**Áp dụng cho**: `spec.md`, `plan.md`, `tasks.md`, code review, `/speckit-*` và `$speckit-*`.

**Cách kiểm tra**:
- Chạy `speckit-specify` với mô tả nghiệp vụ trước bất kỳ implementation nào.
- Tech stack và architecture chỉ được đưa vào `speckit-plan`, không đưa vào `speckit-specify`.
- `spec.md` được lưu tại `specs/<feature-id>/spec.md` và được cập nhật khi scope thay đổi.
- `speckit-implement` chỉ chạy sau khi `spec.md`, `plan.md` và `tasks.md` đầy đủ.
- KHÔNG ĐƯỢC implement feature không có trong spec hoặc task list.

**Ngoại lệ**:
- Hotfix khẩn cấp CÓ THỂ code trước khi hoàn tất đầy đủ artifact, nhưng PR PHẢI ghi lý do, rủi ro, người phê duyệt và task cập nhật spec/plan/tasks ngay sau đó.

### III. Tooling không phụ thuộc agent

**Quy định**: Cấu hình AI tooling KHÔNG ĐƯỢC lock-in vào một agent cụ thể. Claude Code, Codex CLI và các agent khác PHẢI có runtime config riêng nhưng dùng chung nguyên tắc và skill source khi phù hợp.

**Lý do**: Workspace cần dùng được qua nhiều agent mà không nhân đôi logic hoặc lệ thuộc runtime của một công cụ.

**Áp dụng cho**: `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/`, `.codex/`, `skills/`, `.specify/`.

**Cách kiểm tra**:
- Mỗi agent có runtime config riêng.
- Skill source dùng chung lưu tại `skills/` hoặc `.agents/skills/` theo cấu trúc đã document.
- Tài liệu workflow nêu rõ cú pháp phù hợp từng agent: `$speckit-*` cho Codex skill invocation và `/speckit-*` cho slash command khi runtime hỗ trợ.
- Không hardcode API key, token hoặc credential vào bất kỳ file config nào trong repo.

**Ngoại lệ**:
- Runtime-specific wrapper được phép nằm trong thư mục config của agent nếu không thay đổi source-of-truth chung.

### IV. Bootstrap có thể tái lập

**Quy định**: Máy mới PHẢI đạt trạng thái làm việc đầy đủ bằng `SYNC_WORKSPACE.cmd`. Không yêu cầu setup thủ công ngoài script và tài liệu onboarding.

**Lý do**: Bootstrap tái lập giảm sai lệch môi trường và giúp agent/dev mới vào workspace không cần kiến thức ngầm.

**Áp dụng cho**: `SYNC_WORKSPACE.cmd`, `scripts/bootstrap.ps1`, `workstation.json`, `docs/onboarding.md`.

**Cách kiểm tra**:
- Tool dependency như Claude Code, `uv`, `specify-cli`, `rtk`, `ccusage` được kiểm tra/cài tự động khi phù hợp.
- `specify init` chạy tự động với `--force --script-type ps` khi cần.
- `.claude/settings.local.json` được giữ nguyên nếu đã tồn tại.
- Mọi bước setup thủ công bắt buộc đều được document trong `docs/onboarding.md`.
- Repo có local changes, origin khác cấu hình hoặc detached HEAD được cảnh báo và bỏ qua, không force overwrite.

**Ngoại lệ**:
- Tool yêu cầu đăng nhập cá nhân CÓ THỂ cần thao tác thủ công, nhưng onboarding PHẢI ghi rõ.

### V. Thay đổi phẫu thuật và đơn giản

**Quy định**: Chỉ thay đổi đúng những gì cần để giải quyết yêu cầu. KHÔNG ĐƯỢC thêm tính năng suy đoán, abstraction dùng một lần, refactor/format/comment không liên quan hoặc error handling cho tình huống không thể xảy ra.

**Lý do**: Thay đổi nhỏ, rõ, đúng phạm vi giúp review nhanh, giảm rủi ro và tránh làm nhiễu lịch sử.

**Áp dụng cho**: code, docs, scripts, templates, runtime config, task implementation.

**Cách kiểm tra**:
- Diff chỉ chạm file liên quan trực tiếp đến yêu cầu.
- Xóa import/biến/hàm mà chính thay đổi hiện tại làm thừa.
- Không tự ý xóa dead code từ trước khi chưa được yêu cầu.
- Không sửa source code project con khi yêu cầu chỉ thuộc workstation.
- Khi thay đổi hành vi Speckit/template/runtime, cập nhật tài liệu tương ứng trong `docs/speckit/`.
- Khi thay đổi onboarding hoặc cấu trúc workspace, cập nhật `docs/onboarding.md` hoặc `docs/architecture/system-map.md`.

**Ngoại lệ**:
- Refactor nhỏ được phép nếu là điều kiện trực tiếp để thay đổi hiện tại chạy đúng và được nêu rõ trong task/PR.

---

## 6. Tiêu chuẩn cho artifact Speckit

### Cấu trúc artifact

- Các section bắt buộc trong template PHẢI được giữ nguyên.
- Nếu section không liên quan, PHẢI ghi `Không áp dụng` và nêu lý do ngắn.
- KHÔNG ĐƯỢC xóa section bắt buộc chỉ vì feature hiện tại không dùng.
- Artifact sinh ra PHẢI dùng tiếng Việt có dấu cho phần người đọc/review, giữ nguyên technical identifiers bằng English/ASCII khi đó là định danh kỹ thuật.

### `spec.md`

- PHẢI mô tả WHY và WHAT; HOW thuộc về `plan.md`.
- PHẢI có vấn đề cần giải quyết, MVP, user scenario, acceptance criteria, yêu cầu chức năng, quy tắc nghiệp vụ và ngoài phạm vi.
- PHẢI làm rõ phân quyền/bảo mật hoặc đánh dấu là câu hỏi mở.
- PHẢI dùng ID traceable như `US`, `AC`, `FR`, `BR`, `SEC`, `NFR`, `SC` khi áp dụng.
- NÊN ghi `Không áp dụng` cho section không liên quan thay vì xóa section nếu template yêu cầu cấu trúc cố định.

### `plan.md`

- PHẢI mô tả HOW ở mức kỹ thuật đủ để sinh task độc lập.
- PHẢI có traceability từ `US`/`FR`/`BR`/`SEC`/`NFR` sang module/path/API/data/test cho P1/P2 hoặc yêu cầu ảnh hưởng code/data/API/permission.
- PHẢI có phân tích tác động, quyết định kỹ thuật, chiến lược kiểm thử, rollout/rollback và observability/debug khi áp dụng.
- PHẢI ghi rõ ngoại lệ hoặc rủi ro nếu constitution gate chưa pass.
- KHÔNG ĐƯỢC giữ cây thư mục mẫu/generic trong plan cuối.

### `research.md`

- PHẢI trả lời các câu hỏi kỹ thuật được ghi trong `plan.md`.
- PHẢI ghi rõ quyết định, lý do chọn, phương án đã loại và rủi ro còn lại.
- KHÔNG ĐƯỢC đưa ra quyết định kỹ thuật không liên quan đến spec/plan.
- Các quyết định quan trọng PHẢI được tóm tắt lại trong `plan.md`.

### `contracts/`

- PHẢI phản ánh đúng API/event/public contract được mô tả trong `plan.md`.
- PHẢI nêu rõ breaking change nếu có.
- PHẢI hỗ trợ contract test hoặc consumer check khi contract thay đổi.

### `data-model.md`

- PHẢI mô tả entity, quan hệ, migration/backfill nếu có.
- KHÔNG ĐƯỢC thay đổi dữ liệu/schema ngoài phạm vi đã nêu trong `plan.md`.

### `tasks.md`

- PHẢI sinh task theo dependency order và có thể kiểm tra độc lập.
- PHẢI tham chiếu `US`/`FR`/`AC` hoặc artifact thiết kế liên quan khi có thể.
- KHÔNG ĐƯỢC sinh task ngoài spec/plan.
- PHẢI bao gồm task kiểm thử cho rủi ro đã nêu trong plan, hoặc ghi rõ lý do không áp dụng.
- KHÔNG ĐƯỢC sinh `tasks.md` nếu còn câu hỏi `CẦN LÀM RÕ` chặn phạm vi, thiết kế, dữ liệu, permission, contract hoặc rollout.
- Task PHẢI có đầu ra kiểm tra được.
- KHÔNG ĐƯỢC tạo task mơ hồ như "cập nhật logic", "xử lý lỗi", "tối ưu code" nếu không nêu module, hành vi và tiêu chí hoàn thành.
- Task liên quan code PHẢI chỉ rõ file/module/path dự kiến khi có thể.
- Task test PHẢI chỉ rõ loại test và hành vi cần xác minh.

---

## 7. Cổng chất lượng

| Gate | Áp dụng tại | Điều kiện pass | Nếu fail |
|------|-------------|----------------|----------|
| Scope Gate | `spec.md` / `plan.md` | Scope khớp MVP và ngoài phạm vi | Cập nhật spec hoặc ghi rủi ro |
| Traceability Gate | `plan.md` / `tasks.md` | `US`/`FR`/`BR`/`SEC`/`NFR` P1/P2 có mapping sang thiết kế/test/task | Không sinh task |
| Test Gate | `plan.md` / `tasks.md` / PR | Có chiến lược test phù hợp rủi ro | Bổ sung test hoặc biện minh |
| Security Gate | `spec.md` / `plan.md` / PR | Quyền và dữ liệu nhạy cảm được xử lý rõ | Chặn review/release |
| Compatibility Gate | `plan.md` / release | Contract/data migration có phương án tương thích | Bổ sung rollout/rollback |
| Observability Gate | `plan.md` / release | Có log/trace/metric/check sau release | Bổ sung observability |
| Complexity Gate | `plan.md` / review | Độ phức tạp thêm vào có lý do và phương án đơn giản hơn đã được xem xét | Giảm scope/thiết kế hoặc ghi ngoại lệ |
| Release Gate | release | Rollout, rollback, migration/backfill, observability và smoke test đã rõ | Không release |

---

## 8. Definition of Done

Một feature chỉ được xem là hoàn thành khi:

- Scope khớp `spec.md`.
- Plan/tasks/code trace được tới yêu cầu liên quan.
- Test phù hợp rủi ro đã được thực hiện hoặc có biện minh được duyệt.
- Permission/security impact đã được xử lý.
- Contract/migration/rollback đã rõ nếu có.
- Observability và smoke check sau release đã sẵn sàng.
- Không còn ngoại lệ blocker chưa được phê duyệt.
- `/speckit-converge` hoặc `$speckit-converge` không tìm thấy gap còn lại trong phạm vi đã specify.

---

## 9. Checklist review tối thiểu

Reviewer PHẢI kiểm tra:

- Scope có khớp spec không?
- Requirement P1/P2 có trace sang plan/task/test không?
- Có còn câu hỏi `CẦN LÀM RÕ` chặn task/code/release không?
- Có thay API/contract không? Consumer bị ảnh hưởng là ai?
- Có thay dữ liệu/schema không? Migration/backfill/rollback thế nào?
- Có permission/security impact không?
- Có log/trace đủ debug không? Có lộ dữ liệu nhạy cảm không?
- Có task/test cho rủi ro chính không?
- Có over-engineering hoặc abstraction ngoài scope không?
- Có chạm source code sub-repo khi yêu cầu chỉ thuộc workstation không?

---

## 10. Ngoại lệ và biện minh độ phức tạp

Mọi ngoại lệ với constitution PHẢI ghi rõ:

- Nguyên tắc bị vi phạm
- Lý do cần vi phạm
- Phương án đơn giản hơn đã xem xét
- Rủi ro chấp nhận
- Người phê duyệt
- Kế hoạch xử lý sau nếu có

Mỗi ngoại lệ PHẢI có trạng thái:

- `Proposed`: Đang đề xuất
- `Approved`: Đã được phê duyệt
- `Rejected`: Bị từ chối
- `Expired`: Hết hiệu lực
- `Resolved`: Đã xử lý xong

Format ngoại lệ chuẩn:

| ID | Nguyên tắc vi phạm | Lý do | Rủi ro | Người phê duyệt | Trạng thái | Hạn xử lý |
|----|--------------------|-------|--------|------------------|------------|-----------|
| EX-001 | Principle | Lý do | Rủi ro | Tên | Approved | 2026-07-11 |

Nếu ngoại lệ ảnh hưởng release, ngoại lệ PHẢI được phản ánh trong `plan.md` và review/release note tương ứng.

---

## 11. Quản trị

- Constitution có hiệu lực cao hơn template, practice cá nhân và đề xuất tự động từ AI.
- Mọi thay đổi constitution PHẢI có lý do, người phê duyệt và lịch sử thay đổi.
- Thay đổi nguyên tắc cốt lõi PHẢI cập nhật các template liên quan: `spec-template.md`, `plan-template.md`, `tasks-template.md`.
- Nếu plan hoặc task vi phạm constitution, PHẢI ghi ngoại lệ trong `plan.md`.
- Mọi PR/review PHẢI xác minh các gate liên quan đã pass hoặc có ngoại lệ được phê duyệt.
- Khi thay đổi hành vi Speckit/template/runtime, PHẢI cập nhật tài liệu tương ứng trong `docs/speckit/`.
- Khi thay đổi onboarding hoặc cấu trúc workspace, PHẢI cập nhật `docs/onboarding.md` hoặc `docs/architecture/system-map.md`.
- Version dùng SemVer:
  - **MAJOR**: xóa hoặc tái định nghĩa nguyên tắc cốt lõi/gate bắt buộc theo cách không tương thích.
  - **MINOR**: thêm nguyên tắc, section hoặc gate mới; mở rộng guidance có hiệu lực kiểm tra.
  - **PATCH**: làm rõ, sửa diễn đạt, ví dụ, lỗi chính tả hoặc tinh chỉnh không đổi nghĩa.

---

## 12. Lịch sử thay đổi

| Phiên bản | Ngày | Người thay đổi | Thay đổi | Lý do |
|-----------|------|----------------|----------|-------|
| 1.2.0 | 2026-07-11 | Nhóm Flex | Mở rộng constitution theo template hiện hành, thêm gate/DoD/exception/source-of-truth và làm rõ cú pháp command đa agent | Đồng bộ constitution với template Speckit tiếng Việt và quy tắc làm việc của workspace |
| 1.1.1 | 2026-07-08 | Nhóm Flex | Làm rõ vai trò command Speckit và Việt hóa label hiển thị | Đồng bộ workflow Spec-Before-Code |
| 1.1.0 | 2026-07-05 | Nhóm Flex | Thiết lập nguyên tắc workstation ban đầu | Khởi tạo governance cho `flex-workstation` |
