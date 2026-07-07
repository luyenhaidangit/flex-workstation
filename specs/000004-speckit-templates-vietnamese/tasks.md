# Tasks: Việt hóa toàn bộ template Speckit

**Input**: Design documents from `specs/000004-speckit-templates-vietnamese/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [quickstart.md](quickstart.md)

**Tests**: Không sinh test suite tự động; feature này được kiểm chứng bằng static search trên `.specify/templates`, `git diff -- .agents/skills`, `git diff --check`, và review Markdown.

**Organization**: Tasks được nhóm theo user story để có thể implement và kiểm tra độc lập.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Có thể chạy song song vì khác file và không phụ thuộc task chưa hoàn tất
- **[Story]**: User story tương ứng trong `spec.md`
- Mỗi task có file path hoặc lệnh validation cụ thể

## Phase 1: Setup (Shared Infrastructure)

**Mục đích**: Xác định toàn bộ template trong scope và ràng buộc giữ technical identifiers

- [X] T001 Rà danh sách template bằng lệnh `rtk rg --files .specify/templates`
- [X] T002 [P] Đọc `.specify/templates/spec-template.md`
- [X] T003 [P] Đọc `.specify/templates/plan-template.md`
- [X] T004 [P] Đọc `.specify/templates/tasks-template.md`
- [X] T005 [P] Đọc `.specify/templates/checklist-template.md`
- [X] T006 [P] Đọc `.specify/templates/constitution-template.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Chốt quy tắc Việt hóa chung trước khi sửa template

**CRITICAL**: Không bắt đầu sửa template cho tới khi hoàn tất phase này

- [X] T007 Xác định technical identifiers phải giữ nguyên trong `specs/000004-speckit-templates-vietnamese/research.md`
- [X] T008 Xác định mô hình `Speckit Template` và `Template Set` trong `specs/000004-speckit-templates-vietnamese/data-model.md`
- [X] T009 Ghi nhận nguyên tắc không sửa `.agents/skills/**` trong `specs/000004-speckit-templates-vietnamese/plan.md`

**Checkpoint**: Có quy tắc dịch chung, danh sách template đầy đủ và ràng buộc không sửa skill gốc.

---

## Phase 3: User Story 1 - Template Speckit sinh artifact tiếng Việt (Priority: P1) MVP

**Goal**: Tất cả template trong `.specify/templates/` dùng tiếng Việt có dấu cho phần người đọc.

**Independent Test**: Chạy static search trong `.specify/templates` và review từng template.

### Implementation for User Story 1

- [X] T010 [US1] Việt hóa phần người đọc trong `.specify/templates/spec-template.md`, giữ placeholder như `[TÊN TÍNH NĂNG]`, `$ARGUMENTS`, `[CẦN LÀM RÕ: ...]`
- [X] T011 [US1] Việt hóa phần người đọc trong `.specify/templates/plan-template.md`, giữ các section tương đương với Constitution Check, Project Structure và code block path
- [X] T012 [US1] Việt hóa phần người đọc trong `.specify/templates/tasks-template.md`, giữ format `[ID] [P?] [Story] Description`, marker `[P]`, `[Story]` và task IDs `T###`
- [X] T013 [US1] Việt hóa phần người đọc trong `.specify/templates/checklist-template.md`, giữ `CHK###`, `[Gap]`, `[Spec §X]` và Markdown checkbox
- [X] T014 [US1] Việt hóa phần người đọc trong `.specify/templates/constitution-template.md`, giữ placeholder `[PROJECT_NAME]`, `[PRINCIPLE_*]`, `[CONSTITUTION_VERSION]`

**Checkpoint**: 5/5 template có nội dung hướng tới người đọc bằng tiếng Việt.

---

## Phase 4: User Story 2 - Template giữ đúng vai trò workflow (Priority: P2)

**Goal**: Template sau khi Việt hóa vẫn giữ cấu trúc và marker cần thiết cho workflow Speckit.

**Independent Test**: Kiểm tra từng template còn section/marker bắt buộc và không có diff trong `.agents/skills/**`.

### Implementation for User Story 2

- [X] T015 [US2] Rà `.specify/templates/spec-template.md` giữ đủ section 0-12 và marker clarification
- [X] T016 [US2] Rà `.specify/templates/plan-template.md` giữ đủ các section tương đương với Technical Context, Constitution Check, Project Structure và Complexity Tracking
- [X] T017 [US2] Rà `.specify/templates/tasks-template.md` giữ dependency model, parallel opportunities, MVP strategy và notes
- [X] T018 [US2] Rà `.specify/templates/checklist-template.md` giữ requirement-quality policy, sample checkbox và notes
- [X] T019 [US2] Rà `.specify/templates/constitution-template.md` giữ các section tương đương với Core Principles, Governance và version metadata
- [X] T020 [US2] Kiểm tra không có thay đổi trong skill gốc bằng lệnh `rtk powershell -NoProfile -Command "git diff -- .agents/skills"`

**Checkpoint**: Template vẫn dùng được cho workflow và skill gốc không bị sửa.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Mục đích**: Validation cuối và cập nhật tài liệu theo quy tắc workstation

- [X] T021 Chạy static search tiếng Anh phổ biến bằng lệnh `rtk rg "Purpose|Created|Feature|Summary|Technical Context|Constitution Check|Project Structure|Organization|Path Conventions|Notes|Core Principles|Governance|Requirements|Success Criteria" .specify/templates`; mọi hit còn lại phải là thuật ngữ kỹ thuật, ví dụ có chủ đích hoặc nội dung trong validation command
- [X] T022 Chạy kiểm technical identifiers và placeholder hợp lệ bằng lệnh `rtk rg "CHK###|\\[P\\]|\\[Story\\]|\\[TÊN TÍNH NĂNG\\]|\\[TÍNH NĂNG\\]|\\[LOẠI CHECKLIST\\]|\\[PROJECT_NAME\\]|/speckit-|\\.specify/templates|spec.md|plan.md|tasks.md" .specify/templates`
- [X] T023 Cập nhật `docs/tasks.md` và `docs/speckit/workflow.md` để phản ánh quy tắc toàn bộ Speckit templates dùng tiếng Việt
- [X] T024 Chạy `rtk powershell -NoProfile -Command "git diff --check"`
- [X] T025 Kiểm tra phạm vi thay đổi bằng lệnh `rtk powershell -NoProfile -Command "git status --short"`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không có dependency, có thể bắt đầu ngay
- **Foundational (Phase 2)**: Phụ thuộc Phase 1, chặn mọi user story
- **User Story 1 (Phase 3)**: Phụ thuộc Phase 2, là MVP
- **User Story 2 (Phase 4)**: Phụ thuộc US1 vì cần rà cấu trúc sau khi Việt hóa
- **Polish (Phase 5)**: Phụ thuộc US1 và US2

### User Story Dependencies

- **US1 (P1)**: Tạo output tiếng Việt từ toàn bộ template
- **US2 (P2)**: Bảo toàn vai trò workflow và ràng buộc không sửa skill gốc

### Parallel Opportunities

- T002-T006 có thể làm song song vì chỉ đọc file khác nhau
- T010-T014 có thể làm song song nếu mỗi người sửa một template riêng
- T015-T019 có thể làm song song sau khi T010-T014 hoàn tất
- T020-T025 có thể chạy tuần tự hoặc song song phù hợp sau khi edits hoàn tất

---

## Parallel Example: User Story 1

```text
Task: "Việt hóa `.specify/templates/plan-template.md`"
Task: "Việt hóa `.specify/templates/tasks-template.md`"
Task: "Việt hóa `.specify/templates/constitution-template.md`"
```

## Parallel Example: Polish

```text
Task: "Chạy static search tiếng Anh phổ biến trong `.specify/templates`"
Task: "Kiểm tra `git diff -- .agents/skills`"
Task: "Chạy `git diff --check`"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Stop and validate `.specify/templates/*.md`

### Incremental Delivery

1. US1 Việt hóa toàn bộ template Speckit
2. US2 rà cấu trúc workflow và technical identifiers
3. Polish chạy static search, diff checks và cập nhật docs

### Scope Control

- Không sửa artifact cũ ngoài feature artifact cần cập nhật scope
- Không đổi tên command, path, workflow hoặc technical marker
- Không sửa `.agents/skills/**`
- Không sửa sub-repo
