---
description: "Template danh sách task cho triển khai feature"
---

# Tasks: [TÊN TÍNH NĂNG]

**Đầu vào**: Design documents từ `/specs/[NNNNNN-ten-tinh-nang]/`

**Điều kiện tiên quyết**: `plan.md` (bắt buộc), `spec.md` (bắt buộc cho user stories), `research.md`, `data-model.md`, `contracts/`

**Tests**: Test task là TÙY CHỌN. Chỉ sinh test task khi `spec.md`, `plan.md`, constitution hoặc convention project yêu cầu. Nếu có test task, test PHẢI được viết trước implementation và fail trước khi code.

**Tổ chức**: Task được nhóm theo user story để mỗi story có thể được implement, kiểm tra và deliver độc lập.

## Format: `[ID] [P?] [Story?] Description with path`

- **[ID]**: ID duy nhất, tăng tuần tự từ `T001`, `T002`, `T003`...
- **[P]**: Parallelizable, có thể chạy song song vì sửa khác file và không phụ thuộc task khác. `[P]` KHÔNG liên quan tới priority `P1`/`P2`/`P3`.
- **[Story]**: User story mà task thuộc về, ví dụ `[US1]`, `[US2]`, `[US3]`. Setup/Foundation task có thể không có story label.
- **Description**: Phải nêu hành động cụ thể, đối tượng cụ thể và file path cụ thể.

Ví dụ format hợp lệ:

- [ ] T001 Tạo migration `AddBookingTable` trong `backend/src/Infrastructure/Persistence/Migrations/20260709_AddBookingTable.cs`
- [ ] T012 [P] [US1] Tạo DTO `CreateBookingRequest` trong `backend/src/Application/Bookings/CreateBookingRequest.cs`
- [ ] T014 [US1] Implement `CreateBookingHandler` trong `backend/src/Application/Bookings/CreateBookingHandler.cs`

## Quy tắc sinh task cho `/speckit-tasks`

Khi sinh file `tasks.md`:

1. Xóa toàn bộ task ví dụ khỏi template.
2. Đọc user stories từ `spec.md` và sắp theo priority `P1`, `P2`, `P3`.
3. Đọc `plan.md` để xác định project structure, path thật, technical scope, impact, rollout, observability và test strategy.
4. Đọc `data-model.md` để sinh task model/schema/repository/service phù hợp.
5. Đọc `contracts/` để sinh task API/event/contract và contract test khi cần.
6. Chỉ sinh test task nếu spec, plan, constitution hoặc convention project yêu cầu.
7. Mỗi task PHẢI có file path cụ thể hoặc command validate cụ thể.
8. Mỗi task PHẢI có đúng một trách nhiệm chính.
9. Không dùng placeholder như `[Entity]`, `[endpoint]`, `[file]` trong output cuối.
10. Đánh số task tuần tự từ `T001`; KHÔNG dùng `TXXX` trong output cuối.
11. Không sinh test task chỉ để lấp phase. Test task phải map với acceptance criteria, contract, business rule, permission rule hoặc regression risk cụ thể.

## Quy tắc chất lượng task

Mỗi task PHẢI:

- Có ID duy nhất, tăng tuần tự.
- Có file path cụ thể hoặc command cụ thể.
- Có phạm vi nhỏ, có thể hoàn thành trong một lần làm việc.
- Có đầu ra kiểm chứng được qua diff, test, command, log, UI/manual check hoặc artifact.
- Trace được về `US`/`FR`/`AC`/`BR`/`SEC`/`NFR` khi áp dụng.
- Ghi rõ dependency task ID nếu phụ thuộc task khác, ví dụ `(phụ thuộc T012, T013)`.
- Không dùng mô tả mơ hồ như "implement logic", "xử lý nghiệp vụ", "cập nhật các file liên quan".
- Không gom nhiều lớp không liên quan vào một task.
- Không đánh dấu `[P]` nếu task sửa cùng file với task khác hoặc phụ thuộc task khác.

Task không có file path cụ thể là KHÔNG HỢP LỆ, trừ task chạy command validate/review có command rõ ràng.

## Task Size Rules

Một task nên tương ứng với một thay đổi nhỏ, thường là:

- Một file mới.
- Một thay đổi rõ trong một file.
- Một command validation.
- Một artifact cụ thể.

Nếu task cần sửa nhiều hơn 3 file hoặc gồm nhiều layer như database + service + endpoint + UI, PHẢI tách nhỏ.

## Foundational Scope Rules

Chỉ đưa task vào Foundational nếu task đó:

- Được ít nhất 2 user stories sử dụng chung.
- Là điều kiện bắt buộc để bất kỳ story nào chạy được.
- Là schema/migration/base infrastructure cần có trước implementation.
- Là contract hoặc security foundation ảnh hưởng toàn bộ feature.

Không đưa task story-specific vào Foundational. Nếu task chỉ phục vụ `US1`/`US2`/`US3`, đặt task trong phase của user story tương ứng.

Ví dụ không tốt:

- [ ] T005 Tạo DTO `CreateBookingRequest` trong `backend/src/Application/Bookings/CreateBookingRequest.cs`

Ví dụ tốt hơn:

- [ ] T012 [US1] Tạo DTO `CreateBookingRequest` trong `backend/src/Application/Bookings/CreateBookingRequest.cs`

## File Conflict Rules

Nếu nhiều user stories cùng sửa một file tổng hợp như `FeatureNameEndpoints.cs`, `routes.ts`, `index.ts`, `DependencyInjection.cs`, thì:

- Không coi các story đó là parallel hoàn toàn; hoặc
- Tách file theo story/use case; hoặc
- Ghi rõ dependency/integration task để merge endpoint/router/module sau.

Ưu tiên ví dụ path tách theo use case:

- `backend/src/Features/[FeatureName]/Endpoints/Create[Resource]Endpoint.cs`
- `backend/src/Features/[FeatureName]/Endpoints/Update[Resource]Endpoint.cs`
- `backend/src/Features/[FeatureName]/Endpoints/List[Resource]Endpoint.cs`

## Data & Migration Safety Rules

Nếu feature thay đổi database/data:

- Phải có task tạo migration.
- Phải có task kiểm tra backward compatibility nếu hệ thống deploy rolling.
- Phải có task seed/backfill nếu cần.
- Phải có task rollback hoặc recovery note nếu migration có rủi ro.
- Không gộp migration schema và business handler vào cùng một task.

## Contract Task Rules

Nếu `contracts/` có API/event contract:

- Mỗi endpoint/event phải có implementation task.
- Mỗi request/response schema thay đổi phải có DTO/validator task.
- Nếu test strategy yêu cầu contract test, mỗi contract quan trọng phải có contract test task.
- Nếu breaking change, phải có compatibility hoặc migration task.

## Coverage Requirements

Khi sinh `tasks.md`, phải đảm bảo:

- Mỗi user story trong `spec.md` có ít nhất một phase riêng.
- Mỗi acceptance criteria quan trọng có task implementation hoặc validation tương ứng.
- Mỗi requirement P1/P2 hoặc requirement ảnh hưởng code/data/API/permission có task tương ứng.
- Mỗi business rule quan trọng có task implementation hoặc test/validation tương ứng.
- Mỗi security/permission rule có task implementation và test/validation tương ứng khi áp dụng.
- Mỗi entity trong `data-model.md` có task model/schema/repository/service phù hợp.
- Mỗi endpoint/event trong `contracts/` có task implementation hoặc contract test tương ứng khi áp dụng.
- Mỗi constraint trong `plan.md` có task hoặc ghi chú xử lý tương ứng.
- Rollout, rollback, migration, feature flag, observability và security review có task khi `plan.md` đánh dấu liên quan.

## Quy ước path

- **Single project**: `src/`, `tests/` tại repository root.
- **Backend service**: `backend/src/`, `backend/tests/`.
- **Web app**: `backend/src/`, `frontend/src/`.
- **Mobile**: `api/src/`, `ios/src/` hoặc `android/src/`.
- **Monorepo**: dùng path thật trong `plan.md`, ví dụ `apps/admin-web/`, `services/gov-api/`, `packages/shared/`.
- Path ví dụ bên dưới chỉ minh họa; output cuối PHẢI dùng path thật theo `plan.md`.

## Invalid Task Examples

Các task sau KHÔNG hợp lệ:

- [ ] T001 Implement chức năng đặt lịch
  - Lý do: quá rộng, không có file path.
- [ ] T002 Cập nhật backend và frontend
  - Lý do: gom nhiều phần, dễ conflict, không chỉ rõ path.
- [ ] T003 [P] Sửa `BookingService` trong `backend/src/Application/Bookings/BookingService.cs`
- [ ] T004 [P] Thêm validation vào `BookingService` trong `backend/src/Application/Bookings/BookingService.cs`
  - Lý do: cùng sửa một file nên không parallel.
- [ ] T005 [US1] Xử lý lỗi
  - Lý do: mơ hồ, không nói lỗi nào, hành vi nào, ở file nào.

<!--
  ============================================================================
  QUAN TRỌNG: Các task bên dưới chỉ là VÍ DỤ MINH HỌA.

  Lệnh /speckit-tasks PHẢI thay thế chúng bằng task thực tế dựa trên:
  - User stories từ spec.md với priority P1/P2/P3
  - Traceability và technical scope từ plan.md
  - Entities từ data-model.md
  - Endpoints/events từ contracts/
  - Test strategy, rollout, observability, permission và migration trong plan.md

  Task PHẢI được tổ chức theo user story để mỗi story có thể:
  - Implement độc lập
  - Test hoặc validate độc lập
  - Deliver như một MVP increment

  KHÔNG giữ các task ví dụ này trong file tasks.md được sinh ra.
  ============================================================================
-->

## Example Phases Only - MUST BE REPLACED

Các phase bên dưới là ví dụ structure. File `tasks.md` được sinh ra KHÔNG ĐƯỢC chứa bất kỳ placeholder nào như `[FeatureName]`, `[Entity]`, `[UseCaseName]`, `[resource]`, `[command]`.

## Phase 1: Setup (Shared Infrastructure)

**Mục đích**: Khởi tạo cấu trúc project và công cụ dùng chung.

- [ ] T001 Tạo thư mục feature `backend/src/Features/[FeatureName]/` theo cấu trúc trong `plan.md`
- [ ] T002 Tạo file module feature `backend/src/Features/[FeatureName]/[FeatureName]Module.cs`
- [ ] T003 [P] Cấu hình formatter rule trong `.editorconfig`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Hạ tầng lõi PHẢI hoàn tất trước khi implement BẤT KỲ user story nào.

**CRITICAL**: Không bắt đầu user story work cho tới khi phase này hoàn tất.

Ví dụ foundational tasks:

- [ ] T004 Tạo migration `[MigrationName]` trong `backend/src/Infrastructure/Persistence/Migrations/[Timestamp]_[MigrationName].cs`
- [ ] T005 Tạo rollback note cho migration `[MigrationName]` trong `specs/[NNNNNN-ten-tinh-nang]/rollback.md`
- [ ] T006 [P] Cấu hình permission policy dùng chung `[PolicyName]` trong `backend/src/Infrastructure/Auth/[PolicyName].cs`
- [ ] T007 Tạo dependency injection cho `[FeatureName]` trong `backend/src/Features/[FeatureName]/DependencyInjection.cs`
- [ ] T008 Cấu hình structured logging event dùng chung `[EventName]` trong `backend/src/Features/[FeatureName]/Logging/[EventName].cs`
- [ ] T009 Cấu hình feature flag `[FeatureFlagName]` trong `backend/src/Infrastructure/Configuration/FeatureFlags.cs`

**Checkpoint**: Foundation đã sẵn sàng, user story implementation có thể bắt đầu song song nếu không conflict file/dependency.

---

## Phase 3: User Story 1 - [Title] (Priority: P1) MVP

**Goal**: [Mô tả ngắn story này deliver gì]

**Independent Test**:

1. [Gọi API/chạy command/thao tác UI cụ thể]
2. [Kiểm tra response/kết quả nghiệp vụ cụ thể]
3. [Kiểm tra dữ liệu/log/audit nếu liên quan]

Independent Test KHÔNG ĐƯỢC để placeholder chung chung như "kiểm tra hoạt động đúng".

### Tests for User Story 1 (OPTIONAL - chỉ thêm nếu có yêu cầu test)

> **NOTE**: Nếu sinh test task, viết test TRƯỚC và đảm bảo test fail trước implementation.

- [ ] T010 [P] [US1] Tạo contract test cho `POST /api/[resource]` trong `backend/tests/Contract/[FeatureName]ContractTests.cs`
- [ ] T011 [P] [US1] Tạo integration test cho luồng `[user journey]` trong `backend/tests/Integration/[FeatureName]FlowTests.cs`

### Implementation for User Story 1

- [ ] T012 [P] [US1] Tạo entity `[Entity1]` trong `backend/src/Domain/[FeatureName]/[Entity1].cs`
- [ ] T013 [P] [US1] Tạo request validator `[RequestName]Validator` trong `backend/src/Application/[FeatureName]/[RequestName]Validator.cs`
- [ ] T014 [US1] Implement handler `[UseCaseName]Handler` trong `backend/src/Application/[FeatureName]/[UseCaseName]Handler.cs` (phụ thuộc T012, T013)
- [ ] T015 [US1] Implement endpoint `POST /api/[resource]` theo contract `contracts/[contract-name].openapi.yaml` trong `backend/src/Features/[FeatureName]/Endpoints/Create[Resource]Endpoint.cs` (phụ thuộc T014)
- [ ] T016 [US1] Thêm permission check `[PermissionName]` trong `backend/src/Application/[FeatureName]/[UseCaseName]Handler.cs`
- [ ] T017 [US1] Thêm structured logging cho operation `[operation]` trong `backend/src/Application/[FeatureName]/[UseCaseName]Handler.cs`
- [ ] T018 [US1] Thêm audit record cho action `[action]` trong `backend/src/Application/[FeatureName]/[UseCaseName]Handler.cs`

**Definition of Done**:

- Implementation tasks của story đã hoàn tất.
- Independent Test chạy pass.
- Permission/validation/error handling liên quan story đã được xử lý.
- Log/audit liên quan story đã được kiểm tra nếu áp dụng.
- Không làm hỏng các story đã hoàn tất trước đó.

**Checkpoint**: User Story 1 đã hoàn chỉnh và có thể test/validate độc lập.

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Mô tả ngắn story này deliver gì]

**Independent Test**:

1. [Gọi API/chạy command/thao tác UI cụ thể]
2. [Kiểm tra response/kết quả nghiệp vụ cụ thể]
3. [Kiểm tra dữ liệu/log/audit nếu liên quan]

### Tests for User Story 2 (OPTIONAL - chỉ thêm nếu có yêu cầu test)

- [ ] T019 [P] [US2] Tạo integration test cho luồng `[user journey]` trong `backend/tests/Integration/[FeatureName]UpdateTests.cs`

### Implementation for User Story 2

- [ ] T020 [US2] Implement handler `[UseCaseName]Handler` trong `backend/src/Application/[FeatureName]/[UseCaseName]Handler.cs`
- [ ] T021 [US2] Implement endpoint `PATCH /api/[resource]/{id}` trong `backend/src/Features/[FeatureName]/Endpoints/Update[Resource]Endpoint.cs` (phụ thuộc T020)
- [ ] T022 [US2] Thêm idempotency/concurrency check trong `backend/src/Application/[FeatureName]/[UseCaseName]Handler.cs`

**Definition of Done**:

- Implementation tasks của story đã hoàn tất.
- Independent Test chạy pass.
- Permission/validation/error handling liên quan story đã được xử lý.
- Log/audit liên quan story đã được kiểm tra nếu áp dụng.
- Không làm hỏng các story đã hoàn tất trước đó.

**Checkpoint**: User Story 1 và User Story 2 đều hoạt động độc lập.

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Mô tả ngắn story này deliver gì]

**Independent Test**:

1. [Gọi API/chạy command/thao tác UI cụ thể]
2. [Kiểm tra response/kết quả nghiệp vụ cụ thể]
3. [Kiểm tra dữ liệu/log/audit nếu liên quan]

### Tests for User Story 3 (OPTIONAL - chỉ thêm nếu có yêu cầu test)

- [ ] T023 [P] [US3] Tạo integration test cho luồng `[user journey]` trong `backend/tests/Integration/[FeatureName]QueryTests.cs`

### Implementation for User Story 3

- [ ] T024 [US3] Implement query handler `[QueryName]Handler` trong `backend/src/Application/[FeatureName]/[QueryName]Handler.cs`
- [ ] T025 [US3] Implement endpoint `GET /api/[resource]` trong `backend/src/Features/[FeatureName]/Endpoints/List[Resource]Endpoint.cs` (phụ thuộc T024)
- [ ] T026 [US3] Thêm permission scope filter trong `backend/src/Application/[FeatureName]/[QueryName]Handler.cs`

**Definition of Done**:

- Implementation tasks của story đã hoàn tất.
- Independent Test chạy pass.
- Permission/validation/error handling liên quan story đã được xử lý.
- Log/audit liên quan story đã được kiểm tra nếu áp dụng.
- Không làm hỏng các story đã hoàn tất trước đó.

**Checkpoint**: Tất cả user stories đã hoạt động độc lập.

---

[Thêm các phase user story khác nếu cần, theo cùng pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Mục đích**: Hoàn tất kiểm tra chéo, tài liệu, observability và validation ảnh hưởng nhiều user story.

- [ ] T027 [P] Cập nhật tài liệu feature trong `docs/[feature-name].md`
- [ ] T028 Kiểm tra error response không leak internal exception trong `backend/src/Features/[FeatureName]/Endpoints/`
- [ ] T029 Kiểm tra log không chứa token, secret, API key hoặc dữ liệu nhạy cảm trong `backend/src/Application/[FeatureName]/`
- [ ] T030 Kiểm tra authorization cho toàn bộ endpoint mới trong `backend/tests/Integration/[FeatureName]PermissionTests.cs`
- [ ] T031 Chạy validation quickstart bằng command trong `specs/[NNNNNN-ten-tinh-nang]/quickstart.md`

---

## Validation Commands

Điền command thật từ `plan.md` và `quickstart.md`.

- Build backend: `[command]`
- Run tests: `[command]`
- Run API contract tests: `[command hoặc Không áp dụng]`
- Run frontend checks: `[command hoặc Không áp dụng]`
- Run migration/smoke check: `[command hoặc Không áp dụng]`

---

## Traceability Matrix

Điền bảng này trong output cuối để reviewer thấy requirement đã được phủ bởi task nào.

| Source | Covered by tasks |
|--------|------------------|
| US1 | T010-T018 |
| FR-001 | T014, T015 |
| AC-001 | T011, Independent Test US1 |
| BR-001 | T014 |
| SEC-001 | T016, T030 |
| NFR-001 | T017, T029 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không có dependency, có thể bắt đầu ngay.
- **Foundational (Phase 2)**: Phụ thuộc Setup completion, CHẶN mọi user story.
- **User Stories (Phase 3+)**: Đều phụ thuộc Foundational phase completion.
  - User stories có thể chạy song song nếu đủ người và không conflict file/dependency.
  - Nếu nhiều stories cùng sửa file tổng hợp, phải tách file theo use case hoặc ghi rõ integration/dependency task.
  - Hoặc chạy tuần tự theo priority `P1` -> `P2` -> `P3`.
- **Polish (Final Phase)**: Phụ thuộc tất cả user stories trong scope đã hoàn tất.

### User Story Dependencies

- **User Story 1 (P1)**: Có thể bắt đầu sau Foundational (Phase 2), không phụ thuộc story khác.
- **User Story 2 (P2)**: Có thể bắt đầu sau Foundational (Phase 2). Nếu cần component từ US1, component đó phải được tách lên Foundational hoặc ghi rõ dependency task ID.
- **User Story 3 (P3)**: Có thể bắt đầu sau Foundational (Phase 2). Nếu cần component từ US1/US2, component đó phải được tách lên Foundational hoặc ghi rõ dependency task ID.

### Trong từng user story

- Tests (nếu có) PHẢI được viết và fail trước implementation.
- Models/entities trước services/handlers.
- Services/handlers trước endpoints/UI.
- Core implementation trước integration.
- Permission, validation, logging/audit liên quan story phải nằm trong story đó, không đẩy hết xuống Polish.
- Story hoàn tất trước khi chuyển sang priority tiếp theo nếu team chọn triển khai tuần tự.

### Parallel Opportunities

- Mọi Setup task có marker `[P]` có thể chạy song song.
- Mọi Foundational task có marker `[P]` có thể chạy song song trong Phase 2.
- Khi Foundational phase hoàn tất, user stories có thể bắt đầu song song nếu không conflict file/dependency.
- Mọi test trong một user story có marker `[P]` có thể chạy song song.
- Models/entities trong cùng story có marker `[P]` có thể chạy song song.
- Task sửa cùng file KHÔNG ĐƯỢC đánh dấu `[P]`.
- Story chạy song song nhưng cùng sửa file tổng hợp KHÔNG được coi là song song hoàn toàn.

---

## Parallel Example: User Story 1

```bash
# Chạy mọi test cho User Story 1 cùng lúc nếu có yêu cầu test:
Task: "Tạo contract test cho POST /api/[resource] trong backend/tests/Contract/[FeatureName]ContractTests.cs"
Task: "Tạo integration test cho luồng [user journey] trong backend/tests/Integration/[FeatureName]FlowTests.cs"

# Chạy các task model/validator khác file cùng lúc:
Task: "Tạo entity [Entity1] trong backend/src/Domain/[FeatureName]/[Entity1].cs"
Task: "Tạo request validator [RequestName]Validator trong backend/src/Application/[FeatureName]/[RequestName]Validator.cs"
```

---

## Implementation Strategy

### MVP First (chỉ User Story 1)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational (CRITICAL, chặn mọi story).
3. Complete Phase 3: User Story 1.
4. **STOP and VALIDATE**: Test hoặc validate User Story 1 độc lập.
5. Deploy/demo nếu sẵn sàng.

### Incremental Delivery

1. Complete Setup + Foundational -> Foundation ready.
2. Add User Story 1 -> Test/validate independently -> Deploy/Demo (MVP).
3. Add User Story 2 -> Test/validate independently -> Deploy/Demo.
4. Add User Story 3 -> Test/validate independently -> Deploy/Demo.
5. Mỗi story thêm giá trị mà không làm hỏng story trước.

### Parallel Team Strategy

Với nhiều developer:

1. Team hoàn tất Setup + Foundational cùng nhau.
2. Khi Foundational xong:
   - Developer A: User Story 1.
   - Developer B: User Story 2.
   - Developer C: User Story 3.
3. Nếu các stories cùng cần sửa file tổng hợp, phân một integration task riêng hoặc tách file theo use case trước khi chia song song.
4. Stories hoàn tất và tích hợp độc lập.

---

## Checklist chất lượng trước khi implement

- [ ] Không còn task ví dụ hoặc placeholder `[Entity]`, `[endpoint]`, `[file]` trong output cuối.
- [ ] Không còn `TXXX`; toàn bộ task được đánh số tuần tự từ `T001`.
- [ ] Mỗi task có path cụ thể hoặc command cụ thể.
- [ ] Task phụ thuộc task khác đã ghi rõ dependency task ID.
- [ ] Mỗi user story có Independent Test cụ thể.
- [ ] Mỗi user story có Definition of Done cụ thể.
- [ ] Mỗi `US`/`FR` P1/P2 và requirement ảnh hưởng code/data/API/permission có task tương ứng.
- [ ] Traceability Matrix đã map source quan trọng sang task.
- [ ] Migration, permission, contract, observability, rollout/rollback có task khi `plan.md` đánh dấu liên quan.
- [ ] Task `[P]` không sửa cùng file và không phụ thuộc nhau.
- [ ] Không có dependency chéo làm mất khả năng deliver độc lập của user story.
- [ ] Không có story song song cùng sửa file tổng hợp mà chưa có cách xử lý conflict.

## Ghi chú

- `[P]` tasks = khác file, không phụ thuộc nhau, không liên quan tới priority `P1`/`P2`/`P3`.
- `[Story]` label map task tới user story cụ thể để traceability.
- Mỗi user story nên có thể hoàn tất và test/validate độc lập.
- Nếu specification KHÔNG yêu cầu test, không sinh test task chỉ để đủ format; dùng Independent Test/manual validation cụ thể.
- Test task phải map với acceptance criteria, contract, business rule, permission rule hoặc regression risk cụ thể.
- Commit sau từng task hoặc nhóm logic.
- Dừng ở bất kỳ checkpoint nào để validate story độc lập.
- Tránh: task mơ hồ, conflict cùng file, dependency chéo giữa story làm mất tính độc lập.
