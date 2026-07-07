---

description: "Template danh sách task cho triển khai feature"
---

# Tasks: [TÊN TÍNH NĂNG]

**Đầu vào**: Design documents từ `/specs/[NNNNNN-ten-tinh-nang]/`

**Điều kiện tiên quyết**: plan.md (bắt buộc), spec.md (bắt buộc cho user stories), research.md, data-model.md, contracts/

**Tests**: Các ví dụ bên dưới có task test. Test là TÙY CHỌN - chỉ thêm nếu feature specification yêu cầu rõ.

**Tổ chức**: Task được nhóm theo user story để mỗi story có thể được implement và kiểm tra độc lập.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Có thể chạy song song (khác file, không phụ thuộc nhau)
- **[Story]**: User story mà task thuộc về (ví dụ: US1, US2, US3)
- Description phải có file path cụ thể

## Quy ước path

- **Single project**: `src/`, `tests/` tại repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` hoặc `android/src/`
- Path ví dụ bên dưới giả định single project - điều chỉnh theo cấu trúc trong plan.md

<!--
  ============================================================================
  QUAN TRỌNG: Các task bên dưới chỉ là VÍ DỤ MINH HỌA.

  Lệnh /speckit-tasks PHẢI thay thế chúng bằng task thực tế dựa trên:
  - User stories từ spec.md (với priority P1, P2, P3...)
  - Yêu cầu feature từ plan.md
  - Entities từ data-model.md
  - Endpoints từ contracts/

  Task PHẢI được tổ chức theo user story để mỗi story có thể:
  - Implement độc lập
  - Test độc lập
  - Deliver như một MVP increment

  KHÔNG giữ các task ví dụ này trong file tasks.md được sinh ra.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Mục đích**: Khởi tạo project và cấu trúc cơ bản

- [ ] T001 Tạo cấu trúc project theo implementation plan
- [ ] T002 Khởi tạo project [language] với dependency [framework]
- [ ] T003 [P] Cấu hình linting và formatting tools

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Hạ tầng lõi PHẢI hoàn tất trước khi implement BẤT KỲ user story nào

**CRITICAL**: Không bắt đầu user story work cho tới khi phase này hoàn tất

Ví dụ foundational tasks (điều chỉnh theo project):

- [ ] T004 Thiết lập database schema và migrations framework
- [ ] T005 [P] Implement authentication/authorization framework
- [ ] T006 [P] Thiết lập API routing và middleware structure
- [ ] T007 Tạo base models/entities mà mọi story phụ thuộc
- [ ] T008 Cấu hình error handling và logging infrastructure
- [ ] T009 Thiết lập environment configuration management

**Checkpoint**: Foundation đã sẵn sàng - user story implementation có thể bắt đầu song song

---

## Phase 3: User Story 1 - [Title] (Priority: P1) MVP

**Goal**: [Mô tả ngắn story này deliver gì]

**Independent Test**: [Cách xác minh riêng story này hoạt động]

### Tests for User Story 1 (OPTIONAL - chỉ thêm nếu có yêu cầu test)

> **NOTE: Viết các test này TRƯỚC, đảm bảo chúng FAIL trước implementation**

- [ ] T010 [P] [US1] Contract test cho [endpoint] trong tests/contract/test_[name].py
- [ ] T011 [P] [US1] Integration test cho [user journey] trong tests/integration/test_[name].py

### Implementation for User Story 1

- [ ] T012 [P] [US1] Tạo model [Entity1] trong src/models/[entity1].py
- [ ] T013 [P] [US1] Tạo model [Entity2] trong src/models/[entity2].py
- [ ] T014 [US1] Implement [Service] trong src/services/[service].py (phụ thuộc T012, T013)
- [ ] T015 [US1] Implement [endpoint/feature] trong src/[location]/[file].py
- [ ] T016 [US1] Thêm validation và error handling
- [ ] T017 [US1] Thêm logging cho operation của user story 1

**Checkpoint**: User Story 1 đã hoàn chỉnh và có thể test độc lập

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Mô tả ngắn story này deliver gì]

**Independent Test**: [Cách xác minh riêng story này hoạt động]

### Tests for User Story 2 (OPTIONAL - chỉ thêm nếu có yêu cầu test)

- [ ] T018 [P] [US2] Contract test cho [endpoint] trong tests/contract/test_[name].py
- [ ] T019 [P] [US2] Integration test cho [user journey] trong tests/integration/test_[name].py

### Implementation for User Story 2

- [ ] T020 [P] [US2] Tạo model [Entity] trong src/models/[entity].py
- [ ] T021 [US2] Implement [Service] trong src/services/[service].py
- [ ] T022 [US2] Implement [endpoint/feature] trong src/[location]/[file].py
- [ ] T023 [US2] Tích hợp với component của User Story 1 (nếu cần)

**Checkpoint**: User Story 1 và User Story 2 đều hoạt động độc lập

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Mô tả ngắn story này deliver gì]

**Independent Test**: [Cách xác minh riêng story này hoạt động]

### Tests for User Story 3 (OPTIONAL - chỉ thêm nếu có yêu cầu test)

- [ ] T024 [P] [US3] Contract test cho [endpoint] trong tests/contract/test_[name].py
- [ ] T025 [P] [US3] Integration test cho [user journey] trong tests/integration/test_[name].py

### Implementation for User Story 3

- [ ] T026 [P] [US3] Tạo model [Entity] trong src/models/[entity].py
- [ ] T027 [US3] Implement [Service] trong src/services/[service].py
- [ ] T028 [US3] Implement [endpoint/feature] trong src/[location]/[file].py

**Checkpoint**: Tất cả user stories đã hoạt động độc lập

---

[Thêm các phase user story khác nếu cần, theo cùng pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Mục đích**: Cải thiện ảnh hưởng tới nhiều user story

- [ ] TXXX [P] Cập nhật tài liệu trong docs/
- [ ] TXXX Dọn code và refactoring
- [ ] TXXX Tối ưu hiệu năng trên nhiều story
- [ ] TXXX [P] Bổ sung unit tests (nếu được yêu cầu) trong tests/unit/
- [ ] TXXX Gia cố bảo mật
- [ ] TXXX Chạy validation trong quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không có dependency - có thể bắt đầu ngay
- **Foundational (Phase 2)**: Phụ thuộc Setup completion - CHẶN mọi user story
- **User Stories (Phase 3+)**: Đều phụ thuộc Foundational phase completion
  - User stories có thể chạy song song nếu đủ người
  - Hoặc chạy tuần tự theo priority (P1 -> P2 -> P3)
- **Polish (Final Phase)**: Phụ thuộc tất cả user stories mong muốn đã hoàn tất

### User Story Dependencies

- **User Story 1 (P1)**: Có thể bắt đầu sau Foundational (Phase 2) - không phụ thuộc story khác
- **User Story 2 (P2)**: Có thể bắt đầu sau Foundational (Phase 2) - có thể tích hợp với US1 nhưng phải test độc lập được
- **User Story 3 (P3)**: Có thể bắt đầu sau Foundational (Phase 2) - có thể tích hợp với US1/US2 nhưng phải test độc lập được

### Trong từng user story

- Tests (nếu có) PHẢI được viết và FAIL trước implementation
- Models trước services
- Services trước endpoints
- Core implementation trước integration
- Story hoàn tất trước khi chuyển sang priority tiếp theo

### Parallel Opportunities

- Mọi Setup task có marker [P] có thể chạy song song
- Mọi Foundational task có marker [P] có thể chạy song song trong Phase 2
- Khi Foundational phase hoàn tất, mọi user story có thể bắt đầu song song nếu team đủ capacity
- Mọi test trong một user story có marker [P] có thể chạy song song
- Models trong cùng story có marker [P] có thể chạy song song
- Các user story khác nhau có thể được thực hiện song song bởi các thành viên khác nhau

---

## Parallel Example: User Story 1

```bash
# Chạy mọi test cho User Story 1 cùng lúc (nếu có yêu cầu test):
Task: "Contract test cho [endpoint] trong tests/contract/test_[name].py"
Task: "Integration test cho [user journey] trong tests/integration/test_[name].py"

# Chạy mọi model cho User Story 1 cùng lúc:
Task: "Tạo model [Entity1] trong src/models/[entity1].py"
Task: "Tạo model [Entity2] trong src/models/[entity2].py"
```

---

## Implementation Strategy

### MVP First (chỉ User Story 1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - chặn mọi story)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 độc lập
5. Deploy/demo nếu sẵn sàng

### Incremental Delivery

1. Complete Setup + Foundational -> Foundation ready
2. Add User Story 1 -> Test independently -> Deploy/Demo (MVP)
3. Add User Story 2 -> Test independently -> Deploy/Demo
4. Add User Story 3 -> Test independently -> Deploy/Demo
5. Mỗi story thêm giá trị mà không làm hỏng story trước

### Parallel Team Strategy

Với nhiều developer:

1. Team hoàn tất Setup + Foundational cùng nhau
2. Khi Foundational xong:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories hoàn tất và tích hợp độc lập

---

## Ghi chú

- [P] tasks = khác file, không phụ thuộc nhau
- [Story] label map task tới user story cụ thể để traceability
- Mỗi user story nên có thể hoàn tất và test độc lập
- Xác minh test fail trước khi implement
- Commit sau từng task hoặc nhóm logic
- Dừng ở bất kỳ checkpoint nào để validate story độc lập
- Tránh: task mơ hồ, conflict cùng file, dependency chéo giữa story làm mất tính độc lập
