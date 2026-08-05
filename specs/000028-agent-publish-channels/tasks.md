# Tasks: Tab Thiết lập thông tin chung & Phát hành đa kênh cho Agent

**Đầu vào**: Design documents từ `specs/000028-agent-publish-channels/` (`spec.md`, `plan.md`, `data-model.md`, `contracts/agent-publish-channels-api.md`, `quickstart.md`, `research.md`)

**Điều kiện tiên quyết**: `plan.md` (đã hoàn thành checklist), `spec.md`, `data-model.md`, `contracts/agent-publish-channels-api.md`

**Tests**: Test Gate là bắt buộc. Đã sinh test tasks cho rủi ro validation whitelist, regression API `AgentsController`, integration test upsert DB `agent_publish_locations`, kiểm tra 401 unauthorized, và 400 error codes (`PUBLISH_LOCATION_NOT_AVAILABLE`).

**Tổ chức**: Task được nhóm theo user story để mỗi story có thể được implement, kiểm tra và deliver độc lập.

---

## Phase 1: Setup (Infrastructure & Catalog)

**Mục đích**: Chuẩn bị migration database script và catalog tĩnh phía frontend.

- [X] T001 Tạo migration script `V1.2__create_table_agent_publish_locations.sql` tạo bảng `agent_publish_locations` với FK `agents(id)` `ON DELETE CASCADE` và `UNIQUE(agent_id, location_code)` trong `flex-database/agentdb/migrations/V1.2__create_table_agent_publish_locations.sql`
- [X] T002 [P] Tạo catalog tĩnh chứa danh sách 5 kênh (Website, Fanpage Facebook, Zalo OA, Chatbot, Zalo cá nhân) và trạng thái khả dụng trong `flex-microfrontend/src/app/features/agent-catalog/publish-locations.catalog.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Hạ tầng backend entity, repository mapping và DTOs / models lõi PHẢI hoàn tất trước khi implement các user story.

**CRITICAL**: Không bắt đầu user story implementation cho tới khi phase này hoàn tất.

- [X] T003 Tạo entity `AgentPublishLocation` trong `flex-agent-service/src/Flex.Agent.Domain/Entities/AgentPublishLocation.cs`
- [X] T004 Tạo repository interface `IAgentPublishLocationRepository` trong `flex-agent-service/src/Flex.Agent.Domain/Repositories/IAgentPublishLocationRepository.cs` (phụ thuộc T003)
- [X] T005 [P] Cấu hình Fluent API mapping cho bảng `agent_publish_locations` trong `flex-agent-service/src/Flex.Agent.Infrastructures/Persistence/AppDbContext.cs` (phụ thuộc T003)
- [X] T006 Implement `AgentPublishLocationRepository` hỗ trợ query và upsert theo `(agent_id, location_code)` trong `flex-agent-service/src/Flex.Agent.Infrastructures/Repositories/AgentPublishLocationRepository.cs` (phụ thuộc T004, T005)
- [X] T007 [P] Tạo DTO `PublishLocationDto` chứa `LocationCode` và `IsEnabled` trong `flex-agent-service/src/Flex.Agent.Api/DTOs/PublishLocationDto.cs`
- [X] T008 [P] Cập nhật `AgentResponseDto`, `CreateAgentRequestDto`, `UpdateAgentRequestDto` thêm field optional `PublishLocations` trong `flex-agent-service/src/Flex.Agent.Api/DTOs/` (phụ thuộc T007)
- [X] T009 [P] Khai báo interface `PublishLocation` và mở rộng model `Agent`, `CreateAgentRequest`, `UpdateAgentRequest` thêm field `publishLocations` trong `flex-microfrontend/src/app/features/agent-catalog/models/agent.model.ts`

**Checkpoint**: Foundation backend domain/data/DTOs và frontend models đã sẵn sàng.

---

## Phase 3: User Story 1 - Xem/sửa thông tin chung trong tab riêng (Priority: P1) MVP

**Goal**: Tái cấu trúc modal Agent thành dạng 2 tab ("Thiết lập thông tin chung" và "Phát hành"), giữ nguyên 100% logic CRUD thông tin chung hiện có, khóa tab Phát hành khi ở luồng tạo mới agent.

**Independent Test**:
1. Mở modal chi tiết một agent đã có -> Xác nhận tab "Thiết lập thông tin chung" active mặc định với đúng dữ liệu tên, mô tả, trạng thái (AC-001, FR-001, FR-003).
2. Sửa tên hoặc mô tả và bấm "Cập nhật" -> Xác nhận lưu thành công, giữ nguyên các rule validate cũ (AC-002, FR-002).
3. Bấm "Thêm mới Agent" -> Xác nhận tab "Phát hành" hiển thị ở trạng thái vô hiệu hóa không bấm được (AC-003, FR-007).

### Tests for User Story 1

- [X] T010 [P] [US1] Tạo unit test kiểm tra regression DTO mapping cho `AgentsController` khi request không có `publishLocations` trong `flex-agent-service/tests/Flex.Agent.Tests/Agents/PublishLocationValidationTests.cs`

### Implementation for User Story 1

- [X] T011 [US1] Cập nhật `AgentFormModalComponent` TypeScript để quản lý state `activeTab` ('general' | 'publish'), mặc định 'general', và tính toán getter vô hiệu hóa tab Phát hành khi `!isEditMode` trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-form-modal/agent-form-modal.component.ts` (phụ thuộc T009)
- [X] T012 [US1] Sửa template HTML `agent-form-modal.component.html` thêm header tab navigation ("Thiết lập thông tin chung", "Phát hành") và bọc toàn bộ form điều khiển thông tin chung hiện có vào container tab general trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-form-modal/agent-form-modal.component.html` (phụ thuộc T011)
- [X] T013 [P] [US1] Thêm SCSS style cho tab navigation bar, active tab highlight và trạng thái disabled tab trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-form-modal/agent-form-modal.component.scss`

**Definition of Done**:
- Modal hiển thị 2 tab UI chuẩn. Tab "Thiết lập thông tin chung" active mặc định.
- Luồng xem/sửa thông tin chung hoạt động không bị hồi quy.
- Tab "Phát hành" bị disabled khi tạo mới agent.

**Checkpoint**: User Story 1 hoàn chỉnh và có thể test độc lập UI/UX.

---

## Phase 4: User Story 2 - Bật kênh Website và lưu cấu hình phát hành (Priority: P1) MVP

**Goal**: Cho phép quản trị viên bật công tắc kênh Website trên tab Phát hành và lưu cùng với thông tin chung qua 1 nút "Lưu" duy nhất; backend validate và upsert row vào `agent_publish_locations` trong cùng transaction với agent update.

**Independent Test**:
1. Mở agent đã tồn tại, chuyển sang tab "Phát hành" -> Bật công tắc Website (AC-004, FR-004).
2. Tải lại trang/đóng modal mà **chưa** bấm "Lưu" -> Mở lại agent, xác nhận Website vẫn ở trạng thái tắt trước đó (AC-008, FR-008, BR-004).
3. Bật công tắc Website và bấm "Lưu" (nút chung) -> Toast lưu thành công. Mở lại tab "Phát hành", xác nhận Website hiển thị ở trạng thái đã bật (AC-004, AC-005, FR-005).
4. Mở tab "Phát hành" của agent mới tạo chưa cấu hình kênh -> Xác nhận Website mặc định tắt (AC-006, FR-006).

### Tests for User Story 2

- [X] T014 [P] [US2] Tạo unit test cho validation whitelist `locationCode` (chấp nhận "website", từ chối mã khác với status 400 `PUBLISH_LOCATION_NOT_AVAILABLE`) trong `flex-agent-service/tests/Flex.Agent.Tests/Agents/PublishLocationValidationTests.cs`
- [X] T016 [US2] Tạo integration test cho luồng `PUT /api/v1/agents/{id}` kèm `publishLocations` (upsert DB, trả `publishLocations` trong response, verify 401 khi không có JWT token) trong `flex-agent-service/tests/Flex.Agent.Tests/Agents/UpdateAgentIntegrationTests.cs` (phụ thuộc T015)

### Implementation for User Story 2

- [X] T015 [US2] Mở rộng `AgentsController.cs` để validate `publishLocations` (chỉ chấp nhận `"website"` ở MVP, trả 400 `PUBLISH_LOCATION_NOT_AVAILABLE` nếu khác), gọi `IAgentPublishLocationRepository` upsert dữ liệu trong cùng transaction với update `agents`, và map `PublishLocations` vào `AgentResponseDto` trong `flex-agent-service/src/Flex.Agent.Api/Controllers/AgentsController.cs` (phụ thuộc T006, T008, T014)
- [X] T017 [US2] Cập nhật `AgentFormModalComponent` TypeScript thêm `websiteEnabled` control vào `FormGroup`, map giá trị từ `agent.publishLocations` khi load form, và bọc `publishLocations` vào payload khi submit nút Lưu chung trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-form-modal/agent-form-modal.component.ts` (phụ thuộc T009, T011)
- [X] T018 [US2] Cập nhật `agent-form-modal.component.html` render phần nội dung tab "Phát hành" với thẻ kênh Website và công tắc bật/tắt (toggle switch) bind vào `websiteEnabled` control trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-form-modal/agent-form-modal.component.html` (phụ thuộc T012, T017)
- [X] T019 [US2] Cập nhật `AgentService` đảm bảo payload request `POST`/`PUT` truyền mảng `publishLocations` xuống API Backend trong `flex-microfrontend/src/app/features/agent-catalog/services/agent.service.ts` (phụ thuộc T009, T017)

**Definition of Done**:
- Bật công tắc Website và bấm Lưu -> Ghi DB thành công, response trả về `publishLocations`.
- Đóng modal không lưu -> Thay đổi bật/tắt tạm thời bị hủy.
- Mở lại agent -> Hiển thị đúng trạng thái Website đã lưu từ DB.

**Checkpoint**: MVP tính năng (US1 + US2) đã hoạt động hoàn chỉnh end-to-end.

---

## Phase 5: User Story 3 - Tắt kênh đã bật (Priority: P2)

**Goal**: Cho phép quản trị viên tắt kênh Website đã từng bật và lưu cấu hình "đã tắt" bằng 1 nút "Lưu" chung.

**Independent Test**:
1. Với agent đang có kênh Website ở trạng thái đã bật, mở tab "Phát hành".
2. Tắt công tắc Website và bấm nút "Lưu" -> Toast lưu thành công.
3. Mở lại tab "Phát hành", xác nhận kênh Website hiển thị ở trạng thái đã tắt (AC-007, FR-005, FR-008).

### Tests for User Story 3

- [X] T020 [P] [US3] Thêm integration test case cho luồng tắt kênh Website đã bật (`publishLocations: [{ locationCode: "website", isEnabled: false }]`) trong `flex-agent-service/tests/Flex.Agent.Tests/Agents/UpdateAgentIntegrationTests.cs`

### Implementation for User Story 3

- [X] T021 [US3] Kiểm tra và đảm bảo logic toggle off `websiteEnabled` control trong `agent-form-modal.component.ts` gửi đúng `publishLocations: [{ locationCode: "website", isEnabled: false }]` khi submit form trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-form-modal/agent-form-modal.component.ts` (phụ thuộc T017)

**Definition of Done**:
- Tắt công tắc Website và lưu -> Cập nhật `is_enabled = false` trong DB.
- Mở lại modal -> Hiển thị Website ở trạng thái tắt.

**Checkpoint**: US1, US2, US3 đều hoạt động và có thể test độc lập.

---

## Phase 6: User Story 4 - Xem danh sách kênh chưa khả dụng (Priority: P3)

**Goal**: Display tĩnh 5 kênh dự kiến hệ thống (Fanpage Facebook, Zalo OA, Website, Chatbot, Zalo cá nhân) trên tab Phát hành. 4 kênh còn lại hiển thị ở trạng thái "chưa khả dụng" (disabled toggle switch). API Backend chặn 400 nếu client cố gửi locationCode ngoài whitelist.

**Independent Test**:
1. Mở tab "Phát hành" của bất kỳ agent nào -> Xác nhận hiển thị đủ 5 thẻ kênh (Fanpage Facebook, Zalo OA, Website, Chatbot, Zalo cá nhân) (AC-009, FR-009).
2. Thử thao tác trên 4 kênh ngoài Website -> Xác nhận công tắc bị vô hiệu hóa, không bật được (AC-010, FR-009).
3. Dùng API Client (Postman/curl) gửi `PUT /api/v1/agents/{id}` kèm `publishLocations: [{ locationCode: "facebook_fanpage", isEnabled: true }]` -> Xác nhận API trả về HTTP 400 `PUBLISH_LOCATION_NOT_AVAILABLE` (FR-009).

### Tests for User Story 4

- [X] T022 [P] [US4] Thêm integration test case từ chối request chứa `locationCode` ngoài whitelist (ví dụ `"facebook_fanpage"`) trả về HTTP 400 `PUBLISH_LOCATION_NOT_AVAILABLE` trong `flex-agent-service/tests/Flex.Agent.Tests/Agents/PublishLocationValidationTests.cs`

### Implementation for User Story 4

- [X] T023 [US4] Cập nhật template HTML `agent-form-modal.component.html` render 4 kênh còn lại từ catalog tĩnh `PUBLISH_LOCATIONS_CATALOG` với công tắc disabled và badge/nhãn "Chưa khả dụng" trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-form-modal/agent-form-modal.component.html` (phụ thuộc T002, T018)
- [X] T024 [P] [US4] Thêm SCSS style cho 4 thẻ kênh chưa khả dụng (grayed out / opacity / disabled cursor) và badge "Chưa khả dụng" trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-form-modal/agent-form-modal.component.scss` (phụ thuộc T013)

**Definition of Done**:
- Hiển thị đủ 5 kênh trên UI tab Phát hành, 4 kênh disabled.
- Direct API call với kênh chưa khả dụng bị từ chối 400.

**Checkpoint**: Tất cả 4 User Stories (US1 - US4) hoàn tất 100%.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Verification tổng thể, security logging check và chạy full regression check.

- [X] T025 [P] Kiểm tra log không chứa token, API key hoặc dữ liệu nhạy cảm và format error response chuẩn RFC 7807 trong `flex-agent-service/src/Flex.Agent.Api/Controllers/AgentsController.cs`
- [X] T026 Chạy toàn bộ 6 kịch bản kiểm thử trong `specs/000028-agent-publish-channels/quickstart.md` và xác minh không có regression trên `specs/000026-agent-catalog`

---

## Validation Commands

- Build Backend: `dotnet build flex-agent-service/src/Flex.Agent.Api/Flex.Agent.Api.csproj`
- Run Backend Tests: `dotnet test flex-agent-service/tests/Flex.Agent.Tests/Flex.Agent.Tests.csproj`
- Build Frontend: `cd flex-microfrontend && npm run build`
- Verify DB Migration: `psql -U postgres -d agentdb -c "\d agent_publish_locations"`

---

## Traceability Matrix

| Source Requirement / User Story | Covered by tasks |
|---|---|
| US-001 | T010, T011, T012, T013 |
| US-002 | T014, T015, T016, T017, T018, T019 |
| US-003 | T020, T021 |
| US-004 | T022, T023, T024 |
| FR-001 | T011, T012 |
| FR-002 | T010, T012 |
| FR-003 | T011, T012 |
| FR-004 | T017, T018 |
| FR-005 | T015, T016, T017, T021 |
| FR-006 | T015, T016, T017 |
| FR-007 | T011, T012 |
| FR-008 | T015, T017, T019 |
| FR-009 | T014, T022, T023, T024 |
| BR-001 | T001, T003, T015 |
| BR-002 | T010, T012 |
| BR-004 | T017, T018 |
| SEC-001, SEC-002 | T015, T016 |
| AC-001 | T011, T012 |
| AC-002 | T010, T012 |
| AC-003 | T011, T012 |
| AC-004 | T015, T016, T017, T018 |
| AC-005 | T015, T016, T017 |
| AC-006 | T015, T017 |
| AC-007 | T020, T021 |
| AC-008 | T017, T018 |
| AC-009 | T023, T024 |
| AC-010 | T022, T023 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không có dependency, làm trước.
- **Foundational (Phase 2)**: Phụ thuộc Setup completion. CHẶN mọi user story implementation.
- **User Stories (Phase 3-6)**: Đều phụ thuộc Foundational phase completion.
  - Phase 3 (US1) & Phase 4 (US2) là MVP core.
  - Phase 5 (US3) phụ thuộc Phase 4 (US2).
  - Phase 6 (US4) phụ thuộc Phase 4 (US2) & Setup (Phase 1).
- **Polish (Final Phase)**: Phụ thuộc tất cả User Stories đã hoàn tất.

### Parallel Opportunities

- T002 [P] (Catalog tĩnh FE) có thể làm song song với T001 (Migration DB).
- T005 [P], T007 [P], T008 [P], T009 [P] có thể làm song song trong Phase 2.
- T010 [P], T013 [P] có thể làm song song trong Phase 3.
- T014 [P] có thể làm song song với T017 trong Phase 4.
- T020 [P] có thể làm song song trong Phase 5.
- T022 [P], T024 [P] có thể làm song song trong Phase 6.

---

## Implementation Strategy

### MVP First (Phase 1 + 2 + 3 + 4)

1. Hoàn tất Phase 1 Setup & Phase 2 Foundational.
2. Hoàn tất Phase 3 (US1 - Tab layout + General Info UI) & Phase 4 (US2 - Enable Website + Save).
3. **VALIDATE**: Đã có màn hình 2 tab hoàn chỉnh, bật/lưu được kênh Website thành công end-to-end.

### Incremental Delivery (Phase 5 -> Phase 6 -> Final)

4. Thêm Phase 5 (US3 - Disable Website + Save).
5. Thêm Phase 6 (US4 - Hiển thị 4 kênh chưa khả dụng + API whitelist enforcement).
6. Hoàn tất Final Phase Polish & Quickstart E2E test.
