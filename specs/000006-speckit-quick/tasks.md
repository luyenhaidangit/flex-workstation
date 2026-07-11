# Tasks: Speckit Quick

**Đầu vào**: Design documents từ `specs/000006-speckit-quick/`

**Điều kiện tiên quyết**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/quick-flow-contract.md`, `quickstart.md`

**Tests**: Không có automated test framework vì feature là Markdown guidance. Mỗi user story có manual/static validation task cụ thể theo `quickstart.md` và contract.

**Tổ chức**: Task được nhóm theo user story để mỗi story có thể implement và validate độc lập.

## Phase 1: Setup

**Mục đích**: Chuẩn bị cấu trúc skill quick và xác nhận không có source-of-truth mới ngoài `.agents/skills/`.

- [ ] T001 Tạo thư mục skill quick `.agents/skills/speckit-quick/`
- [ ] T002 Tạo khung frontmatter cho skill `speckit-quick` trong `.agents/skills/speckit-quick/SKILL.md`
- [ ] T003 Chạy command `Get-Content -First 20 .agents/skills/speckit-quick/SKILL.md` để kiểm frontmatter có `name: "speckit-quick"` và `user-invocable: true`

**Checkpoint**: Skill file tồn tại với frontmatter hợp lệ trước khi viết behavior guidance.

---

## Phase 2: Foundational

**Mục đích**: Viết nền tảng behavior contract dùng chung cho mọi user story.

- [ ] T004 Viết section `Command Identity` trong `.agents/skills/speckit-quick/SKILL.md` nêu `/speckit.quick`, `$speckit-quick` và `/speckit-quick` là cùng một quick flow
- [ ] T005 Viết section `Quick Eligibility Gate` trong `.agents/skills/speckit-quick/SKILL.md` theo `specs/000006-speckit-quick/contracts/quick-flow-contract.md`
- [ ] T006 Viết section `Safety Guardrails` trong `.agents/skills/speckit-quick/SKILL.md` cấm secret/credential, bypass permission/data/contract và sửa project con ngoài phạm vi
- [ ] T007 Chạy command `rg -n "speckit\\.quick|speckit-quick|secret|credential|permission|contract" .agents/skills/speckit-quick/SKILL.md` để kiểm identity và guardrail đã có

**Checkpoint**: Quick flow có identity, gate và safety rule trước khi thêm luồng xử lý cụ thể.

---

## Phase 3: User Story 1 - Chạy quick flow cho tác vụ nhỏ (Priority: P1) MVP

**Goal**: Người dùng gọi quick flow cho tác vụ nhỏ; agent nêu phạm vi/giả định/tiêu chí kiểm tra trước khi sửa và báo cáo kết quả sau khi hoàn tất.

**Independent Test**:

1. Đọc `.agents/skills/speckit-quick/SKILL.md` và xác nhận có pre-change statement gồm giả định, phạm vi, ngoài phạm vi và tiêu chí kiểm tra.
2. Đọc `.agents/skills/speckit-quick/SKILL.md` và xác nhận có completion report gồm file/khu vực đã đổi, kiểm tra đã chạy hoặc lý do không chạy, phần chưa làm nếu có.
3. So sánh với `specs/000006-speckit-quick/quickstart.md` Manual Scenario 1.

### Implementation for User Story 1

- [ ] T008 [US1] Viết section `Input Intake` trong `.agents/skills/speckit-quick/SKILL.md` yêu cầu hoặc suy ra mục tiêu, phạm vi, đầu ra mong đợi và cách kiểm tra tối thiểu
- [ ] T009 [US1] Viết section `Pre-Change Statement` trong `.agents/skills/speckit-quick/SKILL.md` yêu cầu agent nêu giả định, phạm vi sẽ chạm, ngoài phạm vi và tiêu chí kiểm tra trước khi sửa
- [ ] T010 [US1] Viết section `Execution Rules` trong `.agents/skills/speckit-quick/SKILL.md` yêu cầu thay đổi phẫu thuật, đọc trạng thái hiện có và tránh tạo trùng artifact khi re-run
- [ ] T011 [US1] Viết section `Completion Report` trong `.agents/skills/speckit-quick/SKILL.md` theo contract gồm phạm vi, file/khu vực đã đổi, checks run, checks not run, not done, risk remaining và audit fields `actor`, `timestamp`, `action`, `changed artifacts`
- [ ] T012 [US1] Cập nhật bảng command trong `docs/speckit/workflow.md` để thêm `$speckit-quick` / `/speckit-quick` với tên hiển thị `/speckit.quick` và output là pre-change statement + completion report
- [ ] T013 [US1] Chạy command `rg -n "Pre-Change Statement|Completion Report|checks run|checks not run|speckit\\.quick|speckit-quick" .agents/skills/speckit-quick/SKILL.md docs/speckit/workflow.md` để validate US1

**Definition of Done**:

- Skill hướng dẫn đủ intake, pre-change statement, execution rules và completion report.
- Workflow docs có command quick và không yêu cầu tạo full `spec.md`/`plan.md`/`tasks.md` cho từng quick task hợp lệ.
- Independent Test của US1 pass.

**Checkpoint**: MVP quick flow cho tác vụ nhỏ có thể review độc lập.

---

## Phase 4: User Story 2 - Chặn tác vụ vượt phạm vi quick (Priority: P1)

**Goal**: Quick flow nhận diện task vượt phạm vi hoặc mơ hồ, dừng trước khi sửa và hướng sang Speckit đầy đủ.

**Independent Test**:

1. Đọc `.agents/skills/speckit-quick/SKILL.md` và xác nhận có escalation rule cho data, permission, contract, release, nhiều repo và nghiệp vụ chưa specify.
2. Đọc `.agents/skills/speckit-quick/SKILL.md` và xác nhận task mơ hồ phải hỏi làm rõ hoặc thu hẹp phạm vi.
3. So sánh với `specs/000006-speckit-quick/quickstart.md` Manual Scenario 2 và Manual Scenario 3.

### Implementation for User Story 2

- [ ] T014 [US2] Viết section `Escalation Rules` trong `.agents/skills/speckit-quick/SKILL.md` yêu cầu dừng quick flow khi task đụng dữ liệu, permission, contract, release, nhiều repo hoặc nghiệp vụ chưa specify
- [ ] T015 [US2] Viết section `Ambiguous Input Handling` trong `.agents/skills/speckit-quick/SKILL.md` yêu cầu hỏi làm rõ hoặc thu hẹp phạm vi khi mô tả có thể làm đổi scope
- [ ] T016 [US2] Viết section `Escalation Report` trong `.agents/skills/speckit-quick/SKILL.md` yêu cầu nêu `Không xử lý bằng quick flow`, lý do cụ thể, bước `$speckit-specify <mô tả nghiệp vụ>`, xác nhận chưa sửa file nếu chưa có thay đổi và audit fields `actor`, `timestamp`, `action`, `escalation reason`
- [ ] T017 [US2] Cập nhật phần ghi chú quan trọng trong `docs/speckit/workflow.md` để nêu quick flow phải chuyển sang `$speckit-specify` khi task vượt quick gate
- [ ] T018 [US2] Chạy command `rg -n "Escalation|Không xử lý bằng quick flow|data|permission|contract|release|nhiều repo|speckit-specify|mơ hồ|làm rõ" .agents/skills/speckit-quick/SKILL.md docs/speckit/workflow.md` để validate US2

**Definition of Done**:

- Skill có rule dừng rõ cho task vượt scope và task mơ hồ.
- Escalation report không cho phép sửa tiếp như quick task.
- Workflow docs nêu đường chuyển sang Speckit đầy đủ.
- Independent Test của US2 pass.

**Checkpoint**: Quick flow có chặn phạm vi trước khi bổ sung ví dụ học tập.

---

## Phase 5: User Story 3 - Dùng ví dụ quick làm mẫu học tập (Priority: P2)

**Goal**: Người dùng đọc ví dụ và hiểu input tối thiểu, output mong đợi, điều kiện quick hợp lệ và điều kiện chuyển sang full Speckit.

**Independent Test**:

1. Đọc ví dụ trong `.agents/skills/speckit-quick/SKILL.md` và xác nhận có input, quyết định phạm vi, hành động, kiểm tra và báo cáo.
2. Đọc `docs/speckit/workflow.md` và xác nhận quick flow không thay thế workflow Speckit đầy đủ.
3. So sánh với `specs/000006-speckit-quick/quickstart.md` regression check.

### Implementation for User Story 3

- [ ] T019 [US3] Viết section `Complete Quick Example` trong `.agents/skills/speckit-quick/SKILL.md` minh họa task tài liệu nhỏ với input, scope decision, actions, checks và completion report
- [ ] T020 [US3] Viết section `Escalation Example` trong `.agents/skills/speckit-quick/SKILL.md` minh họa task đụng permission/contract/project con phải chuyển sang `$speckit-specify`
- [ ] T021 [US3] Viết section `Classification Examples` trong `.agents/skills/speckit-quick/SKILL.md` gồm 5 tình huống mẫu và expected classification `quick` hoặc `cần Speckit đầy đủ`
- [ ] T022 [US3] Cập nhật `docs/speckit/workflow.md` để thêm mô tả ngắn vị trí quick flow trước nhánh full feature workflow
- [ ] T023 [US3] Cập nhật `AGENTS.md` section `Speckit Workflow (Spec-Before-Code)` để thêm dòng `$speckit-quick` là quick flow cho tác vụ nhỏ và không dùng cho data/permission/contract/release/nhiều repo
- [ ] T024 [US3] Cập nhật `CLAUDE.md` section Speckit tương ứng để giữ quy tắc quick flow đồng bộ với `AGENTS.md`
- [ ] T025 [US3] Chạy command `rg -n "Complete Quick Example|Escalation Example|Classification Examples|speckit-quick|speckit\\.quick|permission|contract|release" .agents/skills/speckit-quick/SKILL.md docs/speckit/workflow.md AGENTS.md CLAUDE.md` để validate US3

**Definition of Done**:

- Skill có ví dụ quick hợp lệ và ví dụ phải escalate.
- Tài liệu workflow và agent context nêu quick flow rõ ràng, không thay thế full Speckit.
- Independent Test của US3 pass.

**Checkpoint**: Người dùng có mẫu học tập hoàn chỉnh.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Kiểm tra traceability, docs maintenance và regression cho workflow Speckit hiện có.

- [ ] T026 Cập nhật `docs/speckit/maintenance.md` section `Quick Flow` để ghi quy ước quick flow và điều kiện không dùng quick cho data/permission/contract/release/nhiều repo
- [ ] T027 Chạy command `rg -n "\\$speckit-specify|\\$speckit-plan|\\$speckit-tasks|\\$speckit-implement" docs/speckit/workflow.md AGENTS.md CLAUDE.md` để xác nhận workflow Speckit đầy đủ vẫn được document
- [ ] T028 Chạy command `rg -n "token|password|API key|connection string|credential|secret" .agents/skills/speckit-quick/SKILL.md` để xác nhận safety guidance không bỏ sót secret/credential
- [ ] T029 Chạy command `rg -n "T[X]{3}|Phase\\s+N" .agents/skills/speckit-quick/SKILL.md docs/speckit/workflow.md docs/speckit/maintenance.md AGENTS.md CLAUDE.md` để xác nhận không còn marker template trong output implementation
- [ ] T030 Chạy command `rg -n "speckit-quick|speckit\\.quick|Quick flow|quick flow" .agents/skills docs AGENTS.md CLAUDE.md` theo `specs/000006-speckit-quick/quickstart.md` để smoke check toàn bộ feature

---

## Validation Commands

- Static quick identity check: `rg -n "speckit-quick|speckit\.quick|Quick flow|quick flow" .agents/skills docs AGENTS.md CLAUDE.md`
- Frontmatter check: `Get-Content -First 20 .agents/skills/speckit-quick/SKILL.md`
- Full Speckit regression check: `rg -n "\$speckit-specify|\$speckit-plan|\$speckit-tasks|\$speckit-implement" docs/speckit/workflow.md AGENTS.md CLAUDE.md`
- Template marker check: `rg -n "T[X]{3}|Phase\\s+N" .agents/skills/speckit-quick/SKILL.md docs/speckit/workflow.md docs/speckit/maintenance.md AGENTS.md CLAUDE.md`
- Secret guidance check: `rg -n "token|password|API key|connection string|credential|secret" .agents/skills/speckit-quick/SKILL.md`

---

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US-001 | T008, T009, T010, T011, T012, T013 |
| AC-001 | T008, T009, T013 |
| AC-002 | T010, T011, T013 |
| FR-001 | T001, T002, T004, T012 |
| FR-002 | T008, T009 |
| FR-003 | T010, T012 |
| FR-004 | T011, T013 |
| US-002 | T014, T015, T016, T017, T018 |
| AC-003 | T014, T016, T017, T018 |
| AC-004 | T015, T018 |
| FR-005 | T005, T014, T018 |
| FR-006 | T016, T017, T018 |
| BR-001 | T005, T008 |
| BR-002 | T005, T014 |
| BR-003 | T010 |
| BR-004 | T014, T016 |
| SEC-001 | T006, T027 |
| SEC-002 | T006, T014, T018 |
| US-003 | T019, T020, T021, T022, T023, T024, T025 |
| AC-005 | T019, T020, T021, T022, T025 |
| FR-007 | T019, T020, T021 |
| FR-008 | T019, T020, T021, T025 |
| NFR-001 | T019, T021, T022, T025 |
| NFR-002 | T008, T009, T015 |
| NFR-003 | T011, T013, T030 |
| SC-001 | T011, T013, T030 |
| SC-002 | T019, T020, T021, T025 |
| SC-003 | T014, T016, T018 |
| SC-004 | T008, T009, T010, T011 |
| Audit & Lịch sử thay đổi | T011, T016 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không có dependency, bắt đầu ngay.
- **Foundational (Phase 2)**: Phụ thuộc Setup completion, chặn mọi user story.
- **US1 (Phase 3)**: Phụ thuộc Foundational, là MVP.
- **US2 (Phase 4)**: Phụ thuộc Foundational; nên chạy sau US1 vì cùng sửa `.agents/skills/speckit-quick/SKILL.md` và `docs/speckit/workflow.md`.
- **US3 (Phase 5)**: Phụ thuộc US1 và US2 để ví dụ phản ánh đúng cả quick path và escalation path.
- **Polish**: Phụ thuộc tất cả user stories.

### User Story Dependencies

- **US1 (P1)**: Có thể deliver sau Phase 2, không phụ thuộc US2/US3.
- **US2 (P1)**: Có thể deliver sau Phase 2 nhưng task sửa cùng file với US1, nên thực hiện tuần tự sau US1 để giảm conflict.
- **US3 (P2)**: Phụ thuộc nội dung US1/US2 để viết ví dụ đúng.

### Parallel Opportunities

- Không đánh dấu `[P]` cho các task implementation vì nhiều task sửa cùng `.agents/skills/speckit-quick/SKILL.md` hoặc cùng `docs/speckit/workflow.md`.
- Sau khi hoàn tất implementation, các validation command T027, T028, T029, T030 có thể chạy tuần tự hoặc song song thủ công vì chỉ đọc file.

---

## Parallel Example

Không áp dụng cho implementation chính vì các task chủ yếu sửa cùng skill file và workflow docs. Có thể chạy các command validation sau cùng ở nhiều terminal nếu cần:

```powershell
rg -n "token|password|API key|connection string|credential|secret" .agents/skills/speckit-quick/SKILL.md
rg -n "\$speckit-specify|\$speckit-plan|\$speckit-tasks|\$speckit-implement" docs/speckit/workflow.md AGENTS.md CLAUDE.md
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: US1.
4. Stop and validate US1 bằng T013.

### Incremental Delivery

1. Deliver US1 để có quick path hợp lệ.
2. Deliver US2 để có quick gate và escalation path an toàn.
3. Deliver US3 để hoàn tất ví dụ học tập và cập nhật context/docs.
4. Run Final Phase validation.

### Rollback

Nếu runtime không nhận skill mới hoặc quick flow gây nhầm lẫn, rollback bằng cách revert thay đổi ở:

- `.agents/skills/speckit-quick/SKILL.md`
- `docs/speckit/workflow.md`
- `AGENTS.md`
- `CLAUDE.md`
- `docs/speckit/maintenance.md`

---

## Checklist chất lượng trước khi implement

- Status: Pass - Không còn task ví dụ hoặc marker template trong task list.
- Status: Pass - Toàn bộ task được đánh số tuần tự từ `T001` đến `T030`.
- Status: Pass - Mỗi task có file path cụ thể hoặc command cụ thể.
- Status: Pass - Task sửa file có sẵn nêu rõ section cần sửa.
- Status: Pass - Mỗi user story có Independent Test cụ thể.
- Status: Pass - User story không có automated test task đã có manual/static validation task.
- Status: Pass - Traceability Matrix map source quan trọng sang task ID thực tế.
- Status: Pass - Migration, database và service deploy không áp dụng theo `plan.md`.
- Status: Pass - Không có task `[P]` sai conflict file.

## Ghi chú

- `[US1]` map với `US-001`, `[US2]` map với `US-002`, `[US3]` map với `US-003`.
- Feature này là Markdown guidance trong workstation, không tạo code executable hoặc database migration.
- Dừng ở checkpoint sau từng user story để validate độc lập trước khi tiếp tục.
