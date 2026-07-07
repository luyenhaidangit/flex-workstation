# Tasks: Sửa template checklist Speckit sang tiếng Việt

**Input**: Design documents from `specs/000004-checklist-template-vietnamese/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [quickstart.md](quickstart.md)

**Tests**: Không sinh test suite tự động; feature này được kiểm chứng bằng static search và sinh thử checklist theo [quickstart.md](quickstart.md).

**Organization**: Tasks được nhóm theo user story để có thể implement và kiểm tra độc lập.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Có thể chạy song song vì khác file và không phụ thuộc task chưa hoàn tất
- **[Story]**: User story tương ứng trong `spec.md`
- Mỗi task có file path hoặc lệnh validation cụ thể

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Xác định phạm vi nguồn sinh checklist trước khi sửa nội dung

- [ ] T001 Rà soát các nhãn checklist tiếng Anh hiện có bằng lệnh `rtk rg "Purpose|Created|Feature|Content Quality|Requirement Completeness|Feature Readiness|Notes|Checklist Purpose|Acceptance Criteria Quality|Scenario Coverage|Edge Case Coverage" .specify/templates .agents/skills`
- [ ] T002 [P] Đọc nguồn template canonical trong `.specify/templates/checklist-template.md`
- [ ] T003 [P] Đọc instruction sinh checklist trong `.agents/skills/speckit-checklist/SKILL.md`
- [ ] T004 [P] Đọc block checklist chất lượng spec trong `.agents/skills/speckit-specify/SKILL.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Chốt quy tắc dịch dùng chung để các user story không mâu thuẫn

**CRITICAL**: Không bắt đầu sửa từng nguồn sinh checklist cho tới khi hoàn tất phase này

- [ ] T005 Xác định danh sách technical identifiers phải giữ nguyên English trong `specs/000004-checklist-template-vietnamese/research.md`
- [ ] T006 Xác định bộ nhãn tiếng Việt chuẩn cho checklist metadata và category trong `specs/000004-checklist-template-vietnamese/data-model.md`

**Checkpoint**: Có quy tắc dịch chung để sửa template và skill instruction nhất quán.

---

## Phase 3: User Story 1 - Template sinh checklist tiếng Việt (Priority: P1) MVP

**Goal**: Checklist mới sinh từ template canonical có tiêu đề, metadata, category mẫu và ghi chú bằng tiếng Việt có dấu.

**Independent Test**: Mở `.specify/templates/checklist-template.md` và xác nhận các nhãn người dùng đọc là tiếng Việt, trong khi Markdown checkbox và `CHK###` vẫn giữ nguyên.

### Implementation for User Story 1

- [ ] T007 [US1] Sửa tiêu đề, nhãn metadata, ghi chú sinh checklist và section notes trong `.specify/templates/checklist-template.md`
- [ ] T008 [US1] Sửa category mẫu và sample item trong `.specify/templates/checklist-template.md` sang tiếng Việt mà vẫn giữ format `- [ ] CHK###`
- [ ] T009 [US1] Kiểm tra template canonical bằng lệnh `rtk powershell -NoProfile -Command "Get-Content -Raw -LiteralPath '.specify/templates/checklist-template.md'"`

**Checkpoint**: Template canonical đủ để sinh checklist mẫu bằng tiếng Việt.

---

## Phase 4: User Story 2 - Checklist giữ nguyên giá trị quality gate (Priority: P2)

**Goal**: Hướng dẫn agent vẫn sinh checklist kiểm tra chất lượng requirement, không biến thành test implementation và không còn ép heading/category tiếng Anh.

**Independent Test**: Đọc `.agents/skills/speckit-checklist/SKILL.md` và `.agents/skills/speckit-specify/SKILL.md` để xác nhận instruction hướng tới checklist tiếng Việt nhưng vẫn giữ nguyên nguyên tắc requirement-quality gate.

### Implementation for User Story 2

- [ ] T010 [US2] Sửa phần giải thích mục đích checklist trong `.agents/skills/speckit-checklist/SKILL.md` sang tiếng Việt
- [ ] T011 [US2] Sửa category guidance và item writing rules trong `.agents/skills/speckit-checklist/SKILL.md` sang tiếng Việt, giữ các marker kỹ thuật như `[Gap]`, `[Spec §X]`, `CHK###`
- [ ] T012 [US2] Sửa ví dụ đúng/sai trong `.agents/skills/speckit-checklist/SKILL.md` để item mẫu là tiếng Việt và vẫn kiểm tra requirement, không kiểm tra implementation
- [ ] T013 [US2] Sửa fallback checklist structure và report guidance trong `.agents/skills/speckit-checklist/SKILL.md` sang tiếng Việt
- [ ] T014 [US2] Sửa block "Spec Quality Checklist" trong `.agents/skills/speckit-specify/SKILL.md` sang tiếng Việt
- [ ] T015 [US2] Kiểm tra instruction bằng lệnh `rtk rg "Unit Tests for English|Requirement Completeness|Requirement Clarity|WRONG|CORRECT|Purpose|Created|Feature|Notes" .agents/skills/speckit-checklist/SKILL.md .agents/skills/speckit-specify/SKILL.md`

**Checkpoint**: Skill instruction sinh checklist bằng tiếng Việt và vẫn giữ đúng vai trò quality gate.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation cuối và cập nhật tài liệu theo quy tắc workstation nếu hành vi workflow thay đổi

- [ ] T016 Chạy static search tổng thể bằng lệnh `rtk rg "Purpose|Created|Feature|Content Quality|Requirement Completeness|Feature Readiness|Notes|Checklist Purpose|Acceptance Criteria Quality|Scenario Coverage|Edge Case Coverage" .specify/templates .agents/skills`
- [ ] T017 Sinh thử checklist validation-only bằng `$speckit-checklist requirements`; nếu file sinh ra chỉ phục vụ kiểm tra thì không giữ lại như artifact chính thức, và kiểm tra nội dung trong `specs/000004-checklist-template-vietnamese/checklists/`
- [ ] T018 Review checklist sinh thử trong `specs/000004-checklist-template-vietnamese/checklists/` để xác nhận tiêu đề, mục đích, category, item và ghi chú là tiếng Việt; ghi nhận người review quen workflow hiểu mục đích và nhóm kiểm tra chính trong dưới 2 phút
- [ ] T019 Cập nhật `docs/tasks.md` và rà `docs/speckit/workflow.md` để phản ánh thay đổi hành vi sinh checklist tiếng Việt của workflow workstation
- [ ] T020 Kiểm tra phạm vi thay đổi bằng lệnh `rtk git status --short`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không có dependency, có thể bắt đầu ngay
- **Foundational (Phase 2)**: Phụ thuộc Phase 1, chặn mọi user story
- **User Story 1 (Phase 3)**: Phụ thuộc Phase 2, là MVP
- **User Story 2 (Phase 4)**: Phụ thuộc Phase 2, có thể làm sau hoặc song song với US1 nếu tránh sửa cùng file
- **Polish (Phase 5)**: Phụ thuộc US1 và US2

### User Story Dependencies

- **US1 (P1)**: Không phụ thuộc US2; hoàn tất US1 đã cải thiện template canonical
- **US2 (P2)**: Không phụ thuộc US1 về file, nhưng phải dùng cùng quy tắc dịch từ Phase 2

### Parallel Opportunities

- T002, T003, T004 có thể làm song song vì chỉ đọc file khác nhau
- US1 và US2 có thể làm song song sau Phase 2 nếu người thực hiện không sửa cùng file
- T010, T011, T012, T013 cùng sửa một file nên nên làm tuần tự trong một lượt edit
- T016 và T020 có thể chạy song song sau khi edits hoàn tất

---

## Parallel Example: User Story 1

```text
Task: "Sửa `.specify/templates/checklist-template.md` metadata và notes"
Task: "Review `.agents/skills/speckit-checklist/SKILL.md` để chuẩn bị US2"
```

## Parallel Example: User Story 2

```text
Task: "Sửa `.agents/skills/speckit-checklist/SKILL.md`"
Task: "Sửa `.agents/skills/speckit-specify/SKILL.md`"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Stop and validate `.specify/templates/checklist-template.md`

### Incremental Delivery

1. US1 sửa template canonical để checklist mẫu chuyển sang tiếng Việt
2. US2 sửa skill instruction để agent không sinh checklist tiếng Anh từ hướng dẫn
3. Polish chạy static search và sinh thử checklist

### Scope Control

- Không sửa checklist cũ ngoài feature này
- Không đổi tên command, path, workflow hoặc mã `CHK###`
- Không sửa sub-repo
