# Tasks: Chuẩn hóa requirements template

**Đầu vào**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [quickstart.md](quickstart.md)

## Dependencies

- US-001 phải hoàn tất trước US-002 vì transition gate dùng item và metadata của requirements template.
- US-002 và phase Polish chỉ thực hiện sau US-001.

## Phase 1: Setup

- [x] T001 Xác nhận scope và template hiện có trong `specs/000007-requirements-template/spec.md`, `.specify/templates/checklist-template.md` và `.agents/skills/speckit-specify/SKILL.md`

## Phase 2: Foundational

- [x] T002 Tạo cấu trúc requirements quality gate trong `.specify/templates/requirements-template.md`

## Phase 3: User Story 1 — Đánh giá chất lượng spec (P1)

**Mục tiêu**: Feature mới nhận requirements checklist có metadata, mã item, severity, status và evidence.

**Independent Test**: Rà template và xác nhận artifact mẫu có metadata review, `CHK###`, severity, status, tham chiếu/gap và format fail.

- [x] T003 [US1] Hoàn thiện metadata, scope, artifact, summary và quy tắc item trong `.specify/templates/requirements-template.md`
- [x] T004 [US1] Thay nội dung checklist hard-code bằng quy trình resolve, copy và điền `.specify/templates/requirements-template.md` trong `.agents/skills/speckit-specify/SKILL.md`
- [x] T005 [US1] Cập nhật chuẩn Requirements Template trong `docs/speckit/template-guidelines.md`

## Phase 4: User Story 2 — Quyết định chuyển bước (P1)

**Mục tiêu**: Checklist thể hiện kết quả gate và hành động tiếp theo dựa trên status/severity.

**Independent Test**: Đánh dấu một item Blocker là Fail trong artifact mẫu và xác nhận template/skill quy định kết luận chặn bước tiếp theo.

- [x] T006 [US2] Bổ sung quy tắc tổng hợp Pass, Pass có điều kiện và Fail cùng transition gate trong `.specify/templates/requirements-template.md`
- [x] T007 [US2] Cập nhật hướng dẫn đánh giá, ghi nhận fail/ngoại lệ và chặn chuyển bước trong `.agents/skills/speckit-specify/SKILL.md`
- [x] T008 [US2] Làm rõ ranh giới giữa requirements quality gate và checklist domain trong `docs/speckit/maintenance.md`

## Phase 5: Polish & Validation

- [x] T009 Rà `.agents/skills/speckit-checklist/SKILL.md` để xác nhận vẫn tham chiếu `.specify/templates/checklist-template.md`
- [x] T010 Rà `.specify/templates/requirements-template.md` theo `specs/000007-requirements-template/quickstart.md` và chạy `git diff --check`

## Traceability Matrix

| Spec | Tasks |
|------|-------|
| FR-001 | T002, T003, T004 |
| FR-002, FR-003 | T003, T004, T005 |
| FR-004 | T006, T007 |
| FR-005 | T008, T009 |
