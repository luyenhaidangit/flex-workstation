# Quy ước của [PROJECT_NAME]

**Phiên bản**: [CONSTITUTION_VERSION]

**Trạng thái**: [Draft/Active/Deprecated]

**Phê chuẩn**: [RATIFICATION_DATE]

**Sửa đổi gần nhất**: [LAST_AMENDED_DATE]

**Chủ sở hữu**: [OWNER/TEAM]

---

## 1. Mục đích

<!--
  Mô tả ngắn gọn constitution này dùng để làm gì.
  Constitution là quy ước cao nhất cho spec, plan, tasks, review và release.
-->

[Mô tả mục đích của constitution: bảo đảm feature được đặc tả, lập plan, sinh task, kiểm thử và triển khai theo cùng một chuẩn có thể kiểm tra.]

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

---

## 3. Quy ước từ khóa

- **PHẢI**: Bắt buộc tuân thủ. Nếu vi phạm, spec/plan/task/review/release không được thông qua trừ khi có ngoại lệ được phê duyệt.
- **KHÔNG ĐƯỢC**: Bị cấm.
- **NÊN**: Mặc định phải làm, chỉ bỏ qua khi có lý do rõ ràng.
- **CÓ THỂ**: Tùy chọn, áp dụng khi phù hợp.

---

## 4. Nguyên tắc cốt lõi

<!--
  Mỗi nguyên tắc phải có Quy định, Lý do, Áp dụng cho, Cách kiểm tra và Ngoại lệ.
  Dùng PHẢI/KHÔNG ĐƯỢC/NÊN/CÓ THỂ để tránh diễn giải mơ hồ.
-->

### I. Traceability bắt buộc

**Quy định**: Mỗi yêu cầu P1/P2 trong spec PHẢI được mapping sang hướng xử lý kỹ thuật trong plan và task kiểm thử tương ứng trong tasks.

**Lý do**: Traceability giúp đảm bảo implementation bám đúng WHY/WHAT trong spec và không sinh task ngoài phạm vi.

**Áp dụng cho**: `spec.md`, `plan.md`, `tasks.md`, test, review.

**Cách kiểm tra**:
- `spec.md` có ID rõ cho `US`, `AC`, `FR`, `BR`, `SEC`, `NFR`, `SC` khi áp dụng.
- `plan.md` có bảng traceability từ `US`/`FR` sang module/path/API/data/test.
- `tasks.md` có task tham chiếu `US`/`FR`/`AC` liên quan.
- KHÔNG ĐƯỢC sinh task không liên quan đến spec hoặc plan.

**Ngoại lệ**:
- [Khi nào được phép thiếu mapping, ai phê duyệt, và rủi ro được chấp nhận]

### II. Kiểm soát phạm vi

**Quy định**: Plan và tasks KHÔNG ĐƯỢC mở rộng phạm vi nghiệp vụ ngoài MVP và ngoài phạm vi đã ghi trong spec.

**Lý do**: Giữ feature nhỏ, review được và tránh scope creep khi chuyển từ spec sang code.

**Áp dụng cho**: `spec.md`, `plan.md`, `tasks.md`, review.

**Cách kiểm tra**:
- `spec.md` có phạm vi MVP và ngoài phạm vi rõ ràng.
- Mọi thay đổi trong `plan.md` PHẢI liên kết với `US`/`FR`/MVP.
- Technical scope trong `plan.md` PHẢI có phần trong phạm vi và ngoài phạm vi.
- Nếu phát hiện yêu cầu mới, PHẢI cập nhật spec trước khi sinh task.

**Ngoại lệ**:
- [Khi nào được phép mở rộng phạm vi, ai phê duyệt, và spec được cập nhật thế nào]

### III. Kiểm thử theo rủi ro

**Quy định**: Mọi thay đổi ảnh hưởng logic nghiệp vụ, dữ liệu, quyền, API contract hoặc integration PHẢI có chiến lược kiểm thử tương ứng.

**Lý do**: Kiểm thử phải tập trung vào rủi ro thật thay vì áp dụng cứng một kiểu test cho mọi thay đổi.

**Áp dụng cho**: `plan.md`, `tasks.md`, PR, CI/CD nếu có.

**Cách kiểm tra**:
- Logic nghiệp vụ có unit test hoặc lý do `Không áp dụng`.
- API/event thay đổi có contract test hoặc consumer check.
- Phân quyền có permission/security test.
- Migration/backfill có cách xác minh dữ liệu.
- Luồng P1 có integration/e2e/manual test phù hợp.

**Ngoại lệ**:
- [Khi nào được phép không thêm test, ai phê duyệt, và rủi ro còn lại]

### IV. Tương thích ngược và migration an toàn

**Quy định**: Thay đổi API, event, schema, permission hoặc dữ liệu PHẢI đánh giá tương thích ngược trước khi triển khai.

**Lý do**: Hệ thống backend/enterprise thường có nhiều consumer, dữ liệu tồn tại lâu dài, và rollback dữ liệu không đơn giản như rollback code.

**Áp dụng cho**: `plan.md`, `contracts/`, `data-model.md`, release/rollback.

**Cách kiểm tra**:
- `plan.md` có `API/Contract Detail` nếu contract thay đổi.
- `plan.md` có `Dữ liệu & Migration` nếu thay schema/data.
- Rollout/rollback nêu rõ xử lý code/config/data.
- Nếu không rollback được dữ liệu, PHẢI có phương án forward-fix.

**Ngoại lệ**:
- [Khi nào chấp nhận breaking change, ai phê duyệt, cách thông báo consumer]

### V. Bảo mật và phân quyền theo phạm vi dữ liệu

**Quy định**: Hệ thống PHẢI kiểm tra quyền theo đúng vai trò và phạm vi dữ liệu trước khi cho phép xem hoặc thay đổi dữ liệu.

**Lý do**: Các tính năng liên quan tenant, department, member, restricted access hoặc publish/runtime có rủi ro rò rỉ hoặc sửa sai phạm vi dữ liệu.

**Áp dụng cho**: `spec.md`, `plan.md`, `tasks.md`, code review, release.

**Cách kiểm tra**:
- `spec.md` có phân quyền/bảo mật ở mức nghiệp vụ.
- `plan.md` có `Permission Matrix` nếu feature liên quan quyền.
- `tasks.md` có kiểm thử quyền hợp lệ và không hợp lệ.
- KHÔNG ĐƯỢC log token, secret, API key hoặc dữ liệu nhạy cảm.

**Ngoại lệ**:
- [Khi nào ngoại lệ quyền được chấp nhận, ai phê duyệt, và cách giảm thiểu rủi ro]

### VI. Có khả năng quan sát và debug

**Quy định**: Mọi luồng quan trọng PHẢI có đủ log/trace/metric để xác minh sau release và debug khi lỗi.

**Lý do**: Feature không thể vận hành an toàn nếu không biết nó đang chạy đúng hay sai sau khi release.

**Áp dụng cho**: `plan.md`, `tasks.md`, code review, release.

**Cách kiểm tra**:
- `plan.md` có log field chính như `traceId`/`requestId`, `tenantId`, `userId`, `entityId`, `action`, `result` khi phù hợp.
- `plan.md` nêu dữ liệu không được log.
- Có cách kiểm tra sau release: log query, dashboard, health check hoặc smoke test.

**Ngoại lệ**:
- [Khi nào observability tối thiểu được chấp nhận, ai phê duyệt, và kế hoạch bổ sung sau]

### VII. Đơn giản hóa và tránh over-engineering

**Quy định**: Thiết kế PHẢI chọn cách đơn giản nhất đáp ứng spec hiện tại; KHÔNG ĐƯỢC thêm abstraction, service, dependency hoặc workflow mới nếu chưa có nhu cầu rõ ràng.

**Lý do**: Giữ hệ thống dễ hiểu, dễ review, dễ rollback và giảm chi phí vận hành.

**Áp dụng cho**: `plan.md`, `tasks.md`, code review.

**Cách kiểm tra**:
- `plan.md` có quyết định kỹ thuật và phương án đã loại khi có nhiều lựa chọn.
- Vi phạm độ phức tạp PHẢI được ghi trong `Theo dõi độ phức tạp`.
- Tasks KHÔNG ĐƯỢC tạo refactor hoặc abstraction ngoài phạm vi feature.

**Ngoại lệ**:
- [Khi nào được phép tăng độ phức tạp, ai phê duyệt, và kế hoạch kiểm soát]

---

## 5. Tiêu chuẩn cho tài liệu spec/plan/tasks

### `spec.md`

- PHẢI mô tả WHY và WHAT; HOW thuộc về `plan.md`.
- PHẢI có vấn đề cần giải quyết, MVP, user scenario, acceptance criteria, yêu cầu chức năng, quy tắc nghiệp vụ và ngoài phạm vi.
- PHẢI làm rõ phân quyền/bảo mật hoặc đánh dấu là câu hỏi mở.
- NÊN ghi `Không áp dụng` cho section không liên quan thay vì xóa section nếu template yêu cầu cấu trúc cố định.

### `plan.md`

- PHẢI mô tả HOW ở mức kỹ thuật đủ để sinh task độc lập.
- PHẢI có traceability từ `US`/`FR` sang module/path/API/data/test cho P1/P2 hoặc yêu cầu ảnh hưởng code/data/API/permission.
- PHẢI có phân tích tác động, quyết định kỹ thuật, chiến lược kiểm thử, rollout/rollback và observability/debug khi áp dụng.
- PHẢI ghi rõ ngoại lệ hoặc rủi ro nếu constitution gate chưa pass.

### `tasks.md`

- PHẢI sinh task theo dependency order và có thể kiểm tra độc lập.
- PHẢI tham chiếu `US`/`FR`/`AC` hoặc artifact thiết kế liên quan khi có thể.
- KHÔNG ĐƯỢC sinh task ngoài spec/plan.
- PHẢI bao gồm task kiểm thử cho rủi ro đã nêu trong plan, hoặc ghi rõ lý do không áp dụng.

---

## 6. Cổng chất lượng

| Gate | Áp dụng tại | Điều kiện pass | Nếu fail |
|------|-------------|----------------|----------|
| Scope Gate | `spec.md` / `plan.md` | Scope khớp MVP và ngoài phạm vi | Cập nhật spec hoặc ghi rủi ro |
| Traceability Gate | `plan.md` / `tasks.md` | `US`/`FR` P1/P2 có mapping sang thiết kế/test/task | Không sinh task |
| Test Gate | `plan.md` / `tasks.md` / PR | Có chiến lược test phù hợp rủi ro | Bổ sung test hoặc biện minh |
| Security Gate | `spec.md` / `plan.md` / PR | Quyền và dữ liệu nhạy cảm được xử lý rõ | Chặn review/release |
| Compatibility Gate | `plan.md` / release | Contract/data migration có phương án tương thích | Bổ sung rollout/rollback |
| Observability Gate | `plan.md` / release | Có log/trace/metric/check sau release | Bổ sung observability |
| Complexity Gate | `plan.md` / review | Độ phức tạp thêm vào có lý do và phương án đơn giản hơn đã được xem xét | Giảm scope/thiết kế hoặc ghi ngoại lệ |

---

## 7. Ngoại lệ và biện minh độ phức tạp

Mọi ngoại lệ với constitution PHẢI ghi rõ:

- Nguyên tắc bị vi phạm
- Lý do cần vi phạm
- Phương án đơn giản hơn đã xem xét
- Rủi ro chấp nhận
- Người phê duyệt
- Kế hoạch xử lý sau nếu có

Nếu ngoại lệ ảnh hưởng release, ngoại lệ PHẢI được phản ánh trong `plan.md` và review/release note tương ứng.

---

## 8. Quản trị

- Constitution có hiệu lực cao hơn template, practice cá nhân và đề xuất tự động từ AI.
- Mọi thay đổi constitution PHẢI có lý do, người phê duyệt và lịch sử thay đổi.
- Thay đổi nguyên tắc cốt lõi PHẢI cập nhật các template liên quan: `spec-template.md`, `plan-template.md`, `tasks-template.md`.
- Nếu plan hoặc task vi phạm constitution, PHẢI ghi ngoại lệ trong `plan.md`.
- Mọi PR/review PHẢI xác minh các gate liên quan đã pass hoặc có ngoại lệ được phê duyệt.
- Version dùng SemVer:
  - **MAJOR**: thay đổi nguyên tắc cốt lõi hoặc gate bắt buộc.
  - **MINOR**: thêm nguyên tắc/gate mới nhưng không phá vỡ quy trình hiện có.
  - **PATCH**: sửa diễn đạt, ví dụ, lỗi chính tả.

---

## 9. Lịch sử thay đổi

| Phiên bản | Ngày | Người thay đổi | Thay đổi | Lý do |
|-----------|------|----------------|----------|-------|
| [CONSTITUTION_VERSION] | [LAST_AMENDED_DATE] | [OWNER/TEAM] | [Mô tả thay đổi] | [Lý do thay đổi] |
