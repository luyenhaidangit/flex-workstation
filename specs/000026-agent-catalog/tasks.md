# Danh sách Task: Danh mục Agent (CRUD cơ bản)

**Feature**: `000026-agent-catalog` | **Ngày**: 2026-08-01

**Đầu vào**: Design documents từ `specs/000026-agent-catalog/` ([spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000026-agent-catalog/spec.md), [plan.md](file:///C:/Workspace/Project/flex-workstation/specs/000026-agent-catalog/plan.md), [data-model.md](file:///C:/Workspace/Project/flex-workstation/specs/000026-agent-catalog/data-model.md), [contracts/agent-catalog-api.yaml](file:///C:/Workspace/Project/flex-workstation/specs/000026-agent-catalog/contracts/agent-catalog-api.yaml), [quickstart.md](file:///C:/Workspace/Project/flex-workstation/specs/000026-agent-catalog/quickstart.md))

---

## Phase 1: Setup (Shared Infrastructure)

**Mục đích**: Khởi tạo vị trí thư mục và cấu hình hạ tầng cho Agent Catalog.

- [X] T001 Khởi tạo thư mục feature Angular `flex-microfrontend/src/app/features/agent-catalog/`
- [X] T002 [P] Khai báo OpenAPI Contract cho Agent Catalog API trong `specs/000026-agent-catalog/contracts/agent-catalog-api.yaml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Thiết lập entity, repository, database migration và cấu hình Auth JWT cho backend.

**CRITICAL**: Không bắt đầu triển khai các User Story cho đến khi phase này hoàn tất.

- [ ] T003 **CẦN LÀM LẠI** — Tạo migration SQL `V1.1__create_table_agents.sql` cho bảng `agents` trong `flex-database/agentdb/migrations/` (theo quy ước versioned SQL của repo `flex-database`, KHÔNG dùng EF Core Migration). Task này trước đó đã tạo nhầm `flex-agent-service/src/Flex.Agent.Infrastructures/Persistence/Migrations/AddAgentCatalogTable.sql` — cần xóa file đó sau khi migration đúng vị trí đã chạy được, và cấu hình `Flex.Agent.Infrastructures` chỉ Fluent API mapping tới bảng có sẵn (không giữ thư mục `Migrations/` trong service).
- [X] T004 [P] Implement entity `Agent` với các thuộc tính `Id`, `Name`, `Description`, `Status`, `CreatedAt`, `UpdatedAt` trong `flex-agent-service/src/Flex.Agent.Domain/Entities/Agent.cs`
- [X] T005 [P] Interface repository `IAgentRepository` khai báo các phương thức CRUD cho Agent trong `flex-agent-service/src/Flex.Agent.Domain/Repositories/IAgentRepository.cs`
- [X] T006 Implement EF Core repository `AgentRepository` kết nối PostgreSQL `agentdb` trong `flex-agent-service/src/Flex.Agent.Infrastructures/Repositories/AgentRepository.cs` (phụ thuộc T003, T004, T005)
- [X] T007 Cấu hình Dependency Injection cho `IAgentRepository` và JWT Bearer Authentication cho API endpoints trong `flex-agent-service/src/Flex.Agent.Api/Program.cs` (phụ thuộc T006)

**Checkpoint**: Hạ tầng lõi backend (Database, Repository, Entity, Auth) đã sẵn sàng.

---

## Phase 3: User Story 1 - Tạo agent mới (Priority: P1) MVP

**Goal**: Quản trị viên tạo agent mới thành công với tên (bắt buộc, 1..100 ký tự, duy nhất phân biệt hoa/thường) và mô tả (tùy chọn, tối đa 500 ký tự). Hệ thống từ chối nếu tên trống, tên trùng hoặc vượt quá độ dài.

**Independent Test**:
1. Gọi `POST /api/v1/agents` với tên hợp lệ `"Customer Support Bot"` $\rightarrow$ Trả về HTTP 201 Created và thông tin Agent.
2. Gọi `POST /api/v1/agents` với tên trống hoặc vượt quá 100 ký tự $\rightarrow$ Trả về HTTP 400 Bad Request.
3. Gọi `POST /api/v1/agents` với tên trùng `"Customer Support Bot"` $\rightarrow$ Trả về HTTP 409 Conflict.
4. Gọi `POST /api/v1/agents` với tên trùng khác hoa/thường `"customer support bot"` $\rightarrow$ Trả về HTTP 201 Created (BR-001 phân biệt hoa/thường).

### Tests for User Story 1

- [X] T008 [P] [US1] Tạo integration test `CreateAgentIntegrationTests` kiểm tra tạo agent thành công (201), validate tên trống/dài (400), tên trùng (409) và thiếu JWT Token (401) trong `flex-agent-service/tests/Flex.Agent.IntegrationTests/CreateAgentIntegrationTests.cs`

### Implementation for User Story 1

- [X] T009 [P] [US1] Tạo DTOs `CreateAgentRequestDto` và `AgentResponseDto` với Data Annotations validation cho Name (Required, StringLength 1..100) và Description (StringLength 500) trong `flex-agent-service/src/Flex.Agent.Api/DTOs/CreateAgentRequestDto.cs` và `flex-agent-service/src/Flex.Agent.Api/DTOs/AgentResponseDto.cs`
- [X] T010 [US1] Implement controller action `POST /api/v1/agents` trong `flex-agent-service/src/Flex.Agent.Api/Controllers/AgentsController.cs` kiểm tra trùng tên và lưu DB (phụ thuộc T006, T007, T009)
- [X] T011 [P] [US1] Tạo TypeScript interface `Agent` và `CreateAgentRequest` trong `flex-microfrontend/src/app/features/agent-catalog/models/agent.model.ts`
- [X] T012 [P] [US1] Implement service method `createAgent` trong Angular service `flex-microfrontend/src/app/features/agent-catalog/services/agent.service.ts`
- [X] T013 [US1] Implement Angular component `AgentFormModalComponent` hỗ trợ tạo agent mới với client-side validation trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-form-modal/agent-form-modal.component.ts` (phụ thuộc T011, T012)

**Definition of Done**:
- Tạo mới Agent thành công từ cả API và Form Angular UI.
- Test `CreateAgentIntegrationTests` chạy pass.
- Đã validate từ chối tên trống, trùng tên (409) và vượt độ dài (400).

---

## Phase 4: User Story 2 - Xem danh sách và chi tiết agent (Priority: P1)

**Goal**: Quản trị viên xem được toàn bộ danh sách agent hiện có (không cần phân trang ở v1) và xem chi tiết từng agent. Hiển thị trạng thái rỗng rõ ràng nếu danh mục chưa có agent.

**Independent Test**:
1. Truy cập màn hình danh mục agent khi chưa có bản ghi nào $\rightarrow$ Hiển thị màn hình rỗng "Chưa có Agent nào trong danh mục".
2. Gọi `GET /api/v1/agents` $\rightarrow$ Trả về danh sách chứa toàn bộ agent đã tạo kèm tên và trạng thái `'active'`.
3. Gọi `GET /api/v1/agents/{id}` $\rightarrow$ Trả về đúng chi tiết agent theo `id`.

### Tests for User Story 2

- [X] T014 [P] [US2] Tạo integration test `GetAgentsIntegrationTests` kiểm tra lấy danh sách agent (200), lấy chi tiết agent (200/404) và danh sách rỗng trong `flex-agent-service/tests/Flex.Agent.IntegrationTests/GetAgentsIntegrationTests.cs`

### Implementation for User Story 2

- [X] T015 [US2] Implement controller actions `GET /api/v1/agents` và `GET /api/v1/agents/{id}` trong `flex-agent-service/src/Flex.Agent.Api/Controllers/AgentsController.cs` (phụ thuộc T010)
- [X] T016 [P] [US2] Bổ sung service methods `getAgents` và `getAgentById` trong `flex-microfrontend/src/app/features/agent-catalog/services/agent.service.ts`
- [X] T017 [US2] Implement Angular component `AgentListComponent` hiển thị danh sách agent và trạng thái rỗng trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-list/agent-list.component.ts` (phụ thuộc T016)

**Definition of Done**:
- Hiển thị đầy đủ danh sách agent và xem chi tiết thành công.
- Trạng thái rỗng hiển thị thân thiện khi danh sách trống.
- Test `GetAgentsIntegrationTests` chạy pass.

---

## Phase 5: User Story 3 - Sửa thông tin agent (Priority: P2)

**Goal**: Quản trị viên cập nhật tên hoặc mô tả của một agent đã tồn tại. Tên mới được kiểm tra duy nhất (không trùng với agent khác đang có).

**Independent Test**:
1. Sửa tên agent `"Sales Bot"` thành `"Sales Bot v2"` $\rightarrow$ Cập nhật thành công và danh sách hiển thị tên mới.
2. Sửa tên agent `"Sales Bot v2"` thành tên của agent khác đang có trong DB $\rightarrow$ Trả về lỗi 409 Conflict và giữ nguyên dữ liệu cũ.

### Tests for User Story 3

- [X] T018 [P] [US3] Tạo integration test `UpdateAgentIntegrationTests` kiểm tra cập nhật tên/mô tả thành công (200), trùng tên agent khác (409) trong `flex-agent-service/tests/Flex.Agent.IntegrationTests/UpdateAgentIntegrationTests.cs`

### Implementation for User Story 3

- [X] T019 [P] [US3] Tạo DTO `UpdateAgentRequestDto` với Data Annotations validation trong `flex-agent-service/src/Flex.Agent.Api/DTOs/UpdateAgentRequestDto.cs`
- [X] T020 [US3] Implement controller action `PUT /api/v1/agents/{id}` trong `flex-agent-service/src/Flex.Agent.Api/Controllers/AgentsController.cs` (phụ thuộc T015, T019)
- [X] T021 [P] [US3] Bổ sung service method `updateAgent` trong `flex-microfrontend/src/app/features/agent-catalog/services/agent.service.ts`
- [X] T022 [US3] Cập nhật `AgentFormModalComponent` để hỗ trợ chế độ Edit agent trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-form-modal/agent-form-modal.component.ts` (phụ thuộc T013, T021)

**Definition of Done**:
- Cập nhật thông tin agent thành công từ UI và API.
- Lỗi trùng tên với agent khác được báo rõ trên UI.
- Test `UpdateAgentIntegrationTests` chạy pass.

---

## Phase 6: User Story 4 - Xóa agent (Priority: P2)

**Goal**: Quản trị viên xóa một agent khỏi danh mục sau khi mở modal popup xác nhận trước khi thực hiện xóa vĩnh viễn (BR-003).

**Independent Test**:
1. Bấm nút "Xóa" trên dòng Agent $\rightarrow$ Modal popup hiển thị yêu cầu xác nhận.
2. Bấm "Hủy" trên modal $\rightarrow$ Modal đóng, Agent vẫn còn nguyên trong danh mục.
3. Bấm "Xác nhận xóa" $\rightarrow$ Bảng `agents` mất bản ghi, UI tự động loại bỏ agent khỏi danh sách.

### Tests for User Story 4

- [X] T023 [P] [US4] Tạo integration test `DeleteAgentIntegrationTests` kiểm tra xóa agent thành công (204) và 404 Not Found trong `flex-agent-service/tests/Flex.Agent.IntegrationTests/DeleteAgentIntegrationTests.cs`

### Implementation for User Story 4

- [X] T024 [US4] Implement controller action `DELETE /api/v1/agents/{id}` trong `flex-agent-service/src/Flex.Agent.Api/Controllers/AgentsController.cs` (phụ thuộc T020)
- [X] T025 [P] [US4] Bổ sung service method `deleteAgent` trong `flex-microfrontend/src/app/features/agent-catalog/services/agent.service.ts`
- [X] T026 [US4] Implement Angular component `AgentDeleteConfirmModalComponent` và tích hợp vào `AgentListComponent` trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-delete-confirm-modal/agent-delete-confirm-modal.component.ts` (phụ thuộc T017, T025)

**Definition of Done**:
- Xóa agent thành công sau khi xác nhận trên UI modal.
- Test `DeleteAgentIntegrationTests` chạy pass.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Đảm bảo bảo mật auth route, logging và chạy lại toàn bộ test suite.

- [X] T027 [P] Cấu hình Sidebar menu cha "Quản lý Agent" với menu con "Danh mục Agent" trong `flex-microfrontend/src/app/layouts/sidebar/menu.ts` và gắn `AuthGuard` cho route `/agents` trong `flex-microfrontend/src/app/app-routing.module.ts`
- [X] T028 Thêm cấu hình Exception Handling Middleware không rò rỉ stack trace trong `flex-agent-service/src/Flex.Agent.Api/Program.cs`
- [X] T029 Chạy toàn bộ các câu lệnh kiểm thử và xác minh trong `specs/000026-agent-catalog/quickstart.md`

---

## Validation Commands

- **Backend Build**: `cd flex-agent-service && dotnet build`
- **Backend Tests**: `cd flex-agent-service && dotnet test`
- **Database Migration**: chạy script migrate của repo `flex-database` trỏ vào `agentdb/migrations/V1.1__create_table_agents.sql` (theo quy ước migrate hiện có của `flex-database`, không dùng `dotnet ef database update`)
- **Frontend Build/Start**: `cd flex-microfrontend && npm run build`

---

## Traceability Matrix

| Requirement / Source | Covered by tasks |
|----------------------|------------------|
| US-001 / FR-001 | T008, T009, T010, T011, T012, T013 |
| US-001 / FR-002 (Validation Tên) | T008, T009, T010, T013 |
| US-001 / FR-005 (Unique Name) | T006, T008, T010 |
| US-002 / FR-003 (Xem DS & Chi tiết) | T014, T015, T016, T017 |
| US-003 / FR-004 (Sửa Agent) | T018, T019, T020, T021, T022 |
| US-004 / FR-006 (Xóa Agent) | T023, T024, T025, T026 |
| FR-007 / SEC-003 (Auth JWT) | T007, T008, T027 |
| AC-001 (Tạo thành công) | T008, T010, T013 |
| AC-002 (Tên trống) | T008, T009, T013 |
| AC-003 (Tên trùng) | T008, T010 |
| AC-004 (Danh sách đầy đủ) | T014, T015, T017 |
| AC-005 (Trạng thái rỗng) | T014, T017 |
| AC-006 (Sửa thành công) | T018, T020, T022 |
| AC-007 (Sửa trùng tên) | T018, T020 |
| AC-008 (Xóa thành công) | T023, T024, T026 |
| AC-009 (Popup xác nhận xóa) | T026 |
| AC-010 (Độ dài tên/mô tả) | T008, T009, T013 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Có thể bắt đầu ngay.
- **Foundational (Phase 2)**: Phụ thuộc Setup completion. CHẶN tất cả User Story phases.
- **User Story 1 (Phase 3)**: Phụ thuộc Foundational phase completion. (Lập MVP).
- **User Story 2 (Phase 4)**: Phụ thuộc User Story 1 API endpoints.
- **User Story 3 (Phase 5)**: Phụ thuộc User Story 2 API endpoints.
- **User Story 4 (Phase 6)**: Phụ thuộc User Story 2 & 3 API endpoints.
- **Polish (Final Phase)**: Phụ thuộc tất cả User Stories hoàn tất.

### Parallel Opportunities

- Task T002 (OpenAPI Contract) có thể làm song song với T001.
- Task T004 (Domain Entity) và T005 (Repository Interface) có thể làm song song.
- Trong từng User Story phase, Integration tests (`[P]`) và Frontend models/services (`[P]`) có thể làm song song với DTOs backend.
