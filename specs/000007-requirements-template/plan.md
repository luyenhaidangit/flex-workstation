# Kế hoạch triển khai: Chuẩn hóa requirements template

**Branch**: `000007-requirements-template` | **Ngày**: 2026-07-12 | **Đặc tả**: [spec.md](spec.md)

## Tóm tắt

Tạo requirements template riêng cho quality gate của `spec.md`, sau đó thay đổi `$speckit-specify` để bắt buộc resolve template này khi sinh `checklists/requirements.md`. Giữ nguyên vai trò của `$speckit-checklist` đối với checklist tùy biến theo domain.

## Phạm vi kỹ thuật

**Trong phạm vi**:

- Thêm template requirements checklist trong `.specify/templates/`.
- Cập nhật hướng dẫn `$speckit-specify` để dùng template thay vì Markdown hard-code.
- Cập nhật hướng dẫn template và bảo trì Speckit.
- Kiểm tra thủ công artifact sinh từ template.

**Ngoài phạm vi kỹ thuật**:

- Không sửa checklist của feature đã tồn tại.
- Không thay đổi `$speckit-checklist`, API, data, permission hoặc repo con.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: Markdown và PowerShell helper hiện có.

**Service/App liên quan**: Runtime guidance trong `.agents/skills/speckit-specify/` và `.specify/templates/`.

**Phụ thuộc chính**: Spec Kit templates, Markdown preview và Git diff.

**Lưu trữ**: Không áp dụng.

**Kiểm thử**: Static validation và kiểm tra artifact thủ công.

**Nền tảng chạy**: Codex/Claude skill runtime trong workstation.

**Đơn vị deploy**: Không áp dụng; thay đổi có hiệu lực khi workspace sử dụng skill/template cập nhật.

**Loại project**: Workspace cấu hình AI tooling.

**Mục tiêu hiệu năng**: Không áp dụng.

**Ràng buộc**: Nội dung người đọc dùng tiếng Việt có dấu; không làm thay đổi vai trò checklist domain.

**Quy mô/Phạm vi**: Một template mới, một skill instruction và tài liệu Speckit liên quan.

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Chỉ thay template/runtime guidance trong workstation |
| Traceability Gate | Pass | Pass | FR-001..FR-005 map sang template, skill và validation |
| Test Gate | Pass | Pass | Có static diff và kiểm tra artifact |
| Security Gate | Không áp dụng | Không áp dụng | Không có secret hoặc model quyền |
| Compatibility Gate | Pass | Pass | Checklist domain và artifact cũ không bị thay thế |
| Complexity Gate | Pass | Pass | Dùng template Markdown, không thêm automation mới |
| Release Gate | Không áp dụng | Không áp dụng | Không có deployment runtime |

## Câu hỏi kỹ thuật cần research

- Không có câu hỏi chặn. `research.md` ghi quyết định dùng template riêng thay vì tái dùng `checklist-template.md` để tránh chồng vai trò giữa quality gate bắt buộc và checklist domain.

## Thiết kế tổng quan

**Luồng chính**:

1. `$speckit-specify` tạo `spec.md` như hiện tại.
2. Skill resolve requirements template riêng và tạo `checklists/requirements.md` từ đó.
3. Skill điền metadata, đánh giá item, ghi evidence và kết luận transition gate.
4. `$speckit-checklist` tiếp tục tạo checklist domain độc lập từ `checklist-template.md`.

**Component/module tham gia**:

- `.specify/templates/requirements-template.md`: cấu trúc quality gate mặc định.
- `.agents/skills/speckit-specify/SKILL.md`: quy tắc resolve, điền và đánh giá requirements checklist.
- `docs/speckit/template-guidelines.md`: chuẩn template.
- `docs/speckit/maintenance.md`: ranh giới artifact và cách bảo trì.

**Luồng thay thế/lỗi chính**:

- Nếu không resolve được requirements template, dừng generation với lỗi rõ ràng; không fallback về checklist hard-code.
- Nếu một item fail, ghi phát hiện và chặn bước sau theo severity/quy tắc kết luận.

**Thay đổi boundary giữa service/module**: Không áp dụng.

**Idempotency/Concurrency**: Tạo lại artifact không được tạo mã `CHK###` trùng trong cùng checklist; không xử lý concurrent write ngoài quy tắc Git hiện có.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Template requirements riêng | `.specify/templates/requirements-template.md` | Không áp dụng | Checklist item | Rà artifact sinh ra |
| US-001 / FR-002, FR-003 | P1 | Đủ rõ | Metadata, severity, status, evidence và ID | Template + `SKILL.md` | Không áp dụng | Checklist item | Rà template và static search |
| US-002 / FR-004 | P1 | Đủ rõ | Summary và transition gate | Template + `SKILL.md` | Không áp dụng | Kết quả review | Rà trường hợp Blocker fail |
| US-001 / FR-005 | P2 | Đủ rõ | Ghi rõ ranh giới với checklist domain | `SKILL.md` + docs | Không áp dụng | Không áp dụng | Rà guidance |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không áp dụng | Không áp dụng | Không áp dụng |
| API/Contract | Không áp dụng | Không áp dụng | Không áp dụng |
| Permission/Security | Không áp dụng | Không áp dụng | Rà không có secret |
| Logging/Audit | Metadata review trong Markdown | Không có runtime audit | Rà template |
| UI/UX | Markdown preview | Có thể khó đọc nếu quá dài | Rà preview/text |
| Job/Worker/Integration | Skill generation | Không fallback về hard-code | Rà `SKILL.md` |

## API/Contract Detail

**Có thay đổi contract không**: Không áp dụng.

## Permission Matrix

Không áp dụng.

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng; artifact cũ không được migrate.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Template `requirements-template.md` riêng | Vai trò quality gate bắt buộc rõ ràng, dễ bảo trì | Tái dùng `checklist-template.md` | Template đó dành cho checklist domain tùy biến |
| DEC-002 | Resolve template từ `$speckit-specify` | Xóa điểm không nhất quán giữa template và artifact sinh ra | Markdown hard-code trong skill | Khó đồng bộ và thiếu cấu trúc review |
| DEC-003 | Không migrate checklist cũ | Giảm blast radius và giữ lịch sử feature | Chuyển đổi hàng loạt | Không cần thiết, có thể làm mất ngữ cảnh review cũ |

## Chiến lược kiểm thử

**Unit test**: Không áp dụng.

**Integration test**: Không áp dụng.

**Contract test**: Không áp dụng.

**Permission/security test**: Rà không có secret hoặc thay đổi quyền.

**E2E/manual test**: Đối chiếu `requirements-template.md` với artifact mẫu; xác nhận có metadata, `CHK###`, severity, status, evidence và transition gate.

**Regression test**: Rà `$speckit-checklist` vẫn dùng `checklist-template.md` và không bị đổi vai trò.

## Cấu trúc project

```text
.specify/templates/requirements-template.md
.agents/skills/speckit-specify/SKILL.md
docs/speckit/template-guidelines.md
docs/speckit/maintenance.md
specs/000007-requirements-template/
```

## Rollout & Rollback

**Kế hoạch rollout**: Commit thay đổi template, skill và docs cùng feature.

**Tương thích ngược**: Checklist domain và artifact cũ giữ nguyên.

**Feature flag/config**: Không áp dụng.

**Rollback code/config**: Khôi phục bốn artifact runtime/docs về revision trước nếu generation không đáp ứng requirement.

**Rollback dữ liệu/migration**: Không áp dụng.

**Điều kiện kích hoạt rollback**: Artifact mới thiếu quality gate hoặc làm `$speckit-checklist` thay đổi vai trò.

## Observability & Debug

**Log cần có**: Không áp dụng.

**Dữ liệu không được log**: Secret, token, mật khẩu, API key và connection string.

**Metric cần theo dõi**: Không áp dụng.

**Trace/Correlation**: `CHK###`, link `spec.md` và metadata lần review làm tham chiếu artifact.

**Cách kiểm tra sau release**: Sinh một feature mẫu và rà artifact requirements checklist.

**Tình huống debug chính**: Template không được resolve, placeholder không được thay hoặc checklist domain bị dùng nhầm.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component và điểm thay đổi.
- [x] Idempotency/concurrency đã được đánh giá.
- [x] Mỗi `US`/`FR` P1/P2 có mapping sang path và kiểm thử.
- [x] Tác động data, contract, permission, logging và integration đã được đánh giá.
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử, rollout và rollback đã rõ.
- [x] Constitution gate không còn blocker.
