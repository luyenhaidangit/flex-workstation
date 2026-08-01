# Kế hoạch triển khai: Danh mục Agent (CRUD cơ bản)

**Branch**: `000026-agent-catalog` | **Ngày**: 2026-08-01 | **Đặc tả**: [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000026-agent-catalog/spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000026-agent-catalog/spec.md`

---

## Tóm tắt

**Yêu cầu chính từ spec**:
- Quản trị viên tạo mới, xem danh sách/chi tiết, sửa và xóa Agent trong danh mục (MVP-001 $\rightarrow$ MVP-004).
- Bắt buộc đăng nhập xác thực trước khi truy cập hoặc thực hiện thao tác CRUD (MVP-006, FR-007, SEC-003).
- Tên Agent là bắt buộc, duy nhất (phân biệt hoa/thường theo BR-001), tối đa 100 ký tự (AC-010, BR-004).
- Mô tả Agent là tùy chọn, tối đa 500 ký tự (AC-010, BR-004).
- Xóa Agent phải có popup yêu cầu xác nhận trước khi thực hiện (AC-009, BR-003).

**Hướng tiếp cận kỹ thuật dự kiến**:
- Backend: REST API trong sub-repo `flex-agent-service` (.NET 9.0 Web API, EF Core 9 với PostgreSQL `agentdb`; EF Core chỉ mapping tới schema có sẵn, không sinh Migration).
- Frontend: Module Angular trong sub-repo `flex-microfrontend` (giao diện quản trị, form validation, modal xác nhận).
- Authentication: JWT Bearer authentication tích hợp với `flex-auth-service`.

**Kết quả sau research**:
- Đã hoàn thành Phase 0 Research và ghi nhận trong [research.md](file:///C:/Workspace/Project/flex-workstation/specs/000026-agent-catalog/research.md). Các quyết định kỹ thuật chính bao gồm: dùng PostgreSQL `agentdb` (database riêng cho Agent Platform, tách khỏi `flexdb` control plane — xem [system-map.md](file:///C:/Workspace/Project/flex-workstation/docs/architecture/system-map.md)) lưu bảng `agents`, dùng `Flex.Agent.Api` cho Backend REST API và Angular cho Frontend.

---

## Phạm vi kỹ thuật

**Trong phạm vi**:
- **Backend (`flex-agent-service`)**:
  - Domain Entity `Agent` trong `Flex.Agent.Domain`.
  - DbContext mapping (Fluent API, không sinh EF Core Migration) tới bảng `agents` có sẵn trong `Flex.Agent.Infrastructures`; schema được tạo bởi migration SQL trong `flex-database/agentdb/`.
  - AgentRepository implementation trong `Flex.Agent.Infrastructures`.
  - `AgentsController` REST endpoints (GET list/detail, POST create, PUT update, DELETE) với JWT Auth Attribute trong `Flex.Agent.Api`.
  - Request DTOs & Response DTOs với Data Annotations Validation.
  - Backend Unit & Integration Tests.
- **Frontend (`flex-microfrontend`)**:
  - `AgentCatalogModule` / components (`AgentListComponent`, `AgentDetailModal`, `AgentFormModal`, `AgentDeleteConfirmModal`).
  - `AgentService` (Angular HttpClient) kết nối tới `flex-agent-service`.
  - Client-side form validation (Tên required, max length 100, mô tả max length 500).

**Ngoài phạm vi kỹ thuật**:
- Nạp tri thức (Knowledge Base) & Vector Search Qdrant.
- Chạy thử hội thoại (Test Chat Sandbox).
- Phát hành Agent lên các kênh (Web Widget, Instagram...).
- Phân quyền multi-tenant MySQL DB per tenant (xây dựng sau ở `specs/000008-agent-platform-mvp`).

---

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: C# 13 / .NET 9.0 (Backend), TypeScript / Angular (Frontend)

**Service/App liên quan**: `flex-agent-service` (API backend), `flex-microfrontend` (UI frontend), `flex-auth-service` (Auth token issuer)

**Phụ thuộc chính**: ASP.NET Core 9 Web API, Entity Framework Core 9.0 (`Npgsql.EntityFrameworkCore.PostgreSQL`), Angular HTTP Client

**Lưu trữ**: PostgreSQL (`agentdb`), bảng `agents` — database riêng của Agent Platform trong repo `flex-database` (không dùng chung `flexdb`)

**Kiểm thử**: xUnit cho Backend Unit/Integration tests

**Nền tảng chạy**: Linux container / Windows Service

**Đơn vị deploy**: `flex-agent-service` (Docker container / Web API executable), `flex-microfrontend` (Static Web App)

**Loại project**: web-service & admin-web

**Mục tiêu hiệu năng**: Thời gian phản hồi thao tác CRUD < 3 giây (NFR-001)

**Ràng buộc**: Mọi thao tác CRUD phải kèm theo JWT Bearer Token hợp lệ (SEC-003)

**Quy mô/Phạm vi**: Quy mô danh mục nhỏ (tối đa vài chục agent ở v1), không cần phân trang (AC-004)

---

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Phạm vi khớp 100% với spec v1 (CRUD cơ bản) |
| Traceability Gate | Pass | Pass | 100% US/FR/AC có mapping sang thiết kế kỹ thuật và test |
| Security Gate | Pass | Pass | Yêu cầu JWT Auth bắt buộc trên tất cả endpoint CRUD (SEC-003) |
| Test Gate | Pass | Pass | Có đầy đủ Unit test & Integration test cho Backend API |
| Complexity Gate | Pass | Pass | Thiết kế đơn giản, đúng kiến trúc hiện có của `flex-agent-service` |

---

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Model lưu trữ DB ở v1 nên nằm ở PostgreSQL hay MySQL per-tenant?
  - **Kết quả**: PostgreSQL, database riêng `agentdb` (tách khỏi `flexdb` control plane dùng chung) là nơi tối ưu cho v1 để quản lý metadata danh mục agent tập trung trước khi mở rộng multi-tenant. Migration schema thuộc repo `flex-database/agentdb/` theo Constitution VI, không phải EF Core Migration trong `flex-agent-service`.
- **TQ-002**: So khớp trùng tên Agent thực hiện như thế nào để đảm bảo phân biệt chữ hoa/thường theo BR-001?
  - **Kết quả**: UNIQUE constraint trên PostgreSQL mặc định so sánh binary exact match (case-sensitive) cho kiểu `VARCHAR`, đảm bảo `"Agent A"` và `"agent a"` không trùng nhau.
- **TQ-003**: Cấu trúc API endpoint RESTful thế nào?
  - **Kết quả**: Sử dụng chuẩn RESTful `/api/v1/agents` với OpenAPI schema tại [contracts/agent-catalog-api.yaml](file:///C:/Workspace/Project/flex-workstation/specs/000026-agent-catalog/contracts/agent-catalog-api.yaml).

---

## Thiết kế tổng quan

**Luồng chính**:
1. Admin truy cập màn hình Danh mục Agent trên Frontend (`flex-microfrontend`).
2. Auth Guard kiểm tra JWT Bearer Token. Nếu chưa đăng nhập, chuyển hướng Login.
3. Frontend gọi `GET /api/v1/agents` có kèm JWT header.
4. Backend `Flex.Agent.Api` xác thực token, gọi `AgentRepository` truy vấn bảng `agents` trong PostgreSQL `agentdb` và trả về JSON list.
5. Admin thực hiện Tạo/Sửa/Xóa:
   - Form validate dữ liệu ở client (Tên length 1..100, Mô tả max 500).
   - Backend validate lại DTO & check unique name. Nếu vi phạm, trả 400 hoặc 409 Conflict.
   - Xóa agent hiển thị Modal confirm trên UI trước khi gọi `DELETE /api/v1/agents/{id}`.

**Component/module tham gia**:
- `Flex.Agent.Domain`: Định nghĩa `Agent` entity và `IAgentRepository` interface.
- `Flex.Agent.Infrastructures`: Implements `AgentDbContext`, EF Core Configuration & `AgentRepository`.
- `Flex.Agent.Api`: Implements `AgentsController`, DTOs, Mapping và Authentication pipeline.
- `flex-microfrontend`: Angular Agent Catalog Components & Services.

**Luồng thay thế/lỗi chính**:
- Token hết hạn / Chưa đăng nhập: Backend trả HTTP 401 Unauthorized $\rightarrow$ UI chuyển hướng Login.
- Trùng tên Agent: Backend trả HTTP 409 Conflict $\rightarrow$ UI hiển thị câu thông báo lỗi "Tên Agent đã tồn tại".
- Lỗi kết nối DB: Backend trả HTTP 500 $\rightarrow$ UI báo lỗi hệ thống, giữ nguyên input Admin đã nhập.

---

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Tạo Agent mới | `flex-agent-service/src/Flex.Agent.Api/Controllers/AgentsController.cs` | `POST /api/v1/agents` | Bảng `agents` | Unit & Integration Test |
| US-001 / FR-002 | P1 | Đủ rõ | Validate tên trống/trùng/độ dài | `flex-agent-service/src/Flex.Agent.Api/DTOs/CreateAgentRequest.cs` | `POST /api/v1/agents` | Unique Index `name` | Unit Test DTO & DB Constraint |
| US-002 / FR-003 | P1 | Đủ rõ | Xem danh sách và chi tiết Agent | `flex-agent-service/src/Flex.Agent.Api/Controllers/AgentsController.cs` | `GET /api/v1/agents`, `GET /api/v1/agents/{id}` | Bảng `agents` | Integration Test |
| US-003 / FR-004 | P2 | Đủ rõ | Cập nhật thông tin Agent | `flex-agent-service/src/Flex.Agent.Api/Controllers/AgentsController.cs` | `PUT /api/v1/agents/{id}` | Bảng `agents` | Unit & Integration Test |
| US-001 / FR-005 | P1 | Đủ rõ | Enforce unique name constraint | `flex-agent-service/src/Flex.Agent.Infrastructures/Repositories/AgentRepository.cs` | `POST`, `PUT` | `uq_agents_name` | DB Integration Test |
| US-004 / FR-006 | P2 | Đủ rõ | Xóa Agent sau xác nhận | `flex-agent-service/src/Flex.Agent.Api/Controllers/AgentsController.cs` | `DELETE /api/v1/agents/{id}` | Bảng `agents` | Integration & E2E Test |
| FR-007 / SEC-003 | P1 | Đủ rõ | Yêu cầu JWT Auth trước CRUD | `flex-agent-service/src/Flex.Agent.Api/Program.cs` | `[Authorize]` Header | N/A | Security Integration Test |

---

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Thêm mới bảng `agents` trong PostgreSQL `agentdb` (database riêng, repo `flex-database/agentdb/`) | Không tác động tới các bảng hiện có | Chạy migration script SQL trong `flex-database/agentdb/` theo quy ước repo (`migrate-*` script), verify bằng `psql \d agents` |
| API/Contract | Thêm mới REST endpoints `/api/v1/agents` | Endpoint mới, không ảnh hưởng API cũ | Swagger UI & OpenAPI contract check |
| Permission/Security | Áp dụng `[Authorize]` trên `AgentsController` | Ngăn chặn truy cập chưa xác thực | Integration Test với/không có Token |
| UI/UX | Thêm menu cha "Quản lý Agent" với menu con "Danh mục Agent" (`/agents`) trong `flex-microfrontend` (`menu.ts`) | Không làm gián đoạn luồng UI khác | Visual & Manual E2E Check |

---

## API/Contract Detail

**Có thay đổi contract không**: Có (Thêm mới API Contract).

Chi tiết OpenAPI specification được định nghĩa tại: [contracts/agent-catalog-api.yaml](file:///C:/Workspace/Project/flex-workstation/specs/000026-agent-catalog/contracts/agent-catalog-api.yaml).

---

## Permission Matrix

| Vai trò/Scope | Xem danh sách/chi tiết | Tạo Agent | Sửa Agent | Xóa Agent | Ghi chú |
|---------------|-----------------------|-----------|-----------|-----------|---------|
| Quản trị viên (Đã đăng nhập) | Có | Có | Có | Có | Có JWT Token hợp lệ |
| Khách / Chưa đăng nhập | Không | Không | Không | Không | Trả về 401 Unauthorized |

---

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Có (Thêm bảng `agents` mới).

**Database đích**: PostgreSQL `agentdb` — database riêng cho Agent Platform/Agent Catalog, tách khỏi `flexdb` control plane dùng chung. Xác nhận bởi user (2026-08-01), ghi nhận tại [system-map.md](file:///C:/Workspace/Project/flex-workstation/docs/architecture/system-map.md).

**Repo chứa migration**: `flex-database/agentdb/` — theo quy ước versioned SQL hiện có của repo `flex-database` (`migrations/V<major>.<minor>__mo-ta.sql`, `seeders/`), giống `investordb`/`systemdb`/`notification`/`securities`. KHÔNG dùng EF Core Migration trong `flex-agent-service`.

**Migration**:
- Script: `flex-database/agentdb/migrations/V1.1__create_table_agents.sql` — tạo bảng `agents` (đúng convention `CREATE TABLE IF NOT EXISTS`, `uq_agents_name` case-sensitive unique index theo BR-001).
- `Flex.Agent.Infrastructures` chỉ cấu hình Fluent API mapping tới bảng `agents` có sẵn, không sinh EF Core Migration để tránh 2 nguồn quản lý schema song song.

**Backfill/Cleanup**: Không áp dụng (Tính năng mới, database trống ban đầu).

---

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | ASP.NET Core 9 Web API (`flex-agent-service`) | Đã có sẵn repo `flex-agent-service` | Service NodeJS mới | Thừa thãi, không đồng bộ kiến trúc |
| DEC-002 | PostgreSQL `agentdb` (`agents` table), migration quản lý tại `flex-database/agentdb/` | Tách database riêng cho Agent Platform, tránh gộp schema dùng chung vào `flexdb` hoặc migration vào repo service (Constitution VI) | MySQL DB per tenant ở v1; EF Core Migration trong `flex-agent-service` | MySQL: đổi lại độ phức tạp chưa cần thiết ở v1. EF Core Migration trong service: phân mảnh nguồn sự thật schema, sai quy ước migration dùng chung của workstation |
| DEC-003 | Bearer JWT Auth middleware | Đảm bảo an toàn SEC-003 | Allow Anonymous | Vi phạm quy tắc bảo mật |
| DEC-004 | Case-sensitive unique index | Chuẩn BR-001 & PostgreSQL default | Case-insensitive index | Vi phạm BR-001 |

---

## Chiến lược kiểm thử

**Unit test**:
- DTO Validations (`CreateAgentRequest`, `UpdateAgentRequest`).
- Domain Agent entity logic & repository mock tests.

**Integration test**:
- `AgentsControllerIntegrationTests` với WebApplicationFactory & Postgres testcontainer.
- Test CRUD full cycle & unique name violation (409 Conflict).
- Test Unauthorized (401) khi không gửi Token.

**E2E/manual test**:
- Kiểm thử giao diện Angular UI end-to-end theo 6 kịch bản trong [quickstart.md](file:///C:/Workspace/Project/flex-workstation/specs/000026-agent-catalog/quickstart.md).

---

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000026-agent-catalog/
├── spec.md              # Đặc tả nghiệp vụ
├── plan.md              # File kế hoạch này
├── research.md          # Kết quả nghiên cứu Phase 0
├── data-model.md        # Mô hình dữ liệu Phase 1
├── quickstart.md        # Hướng dẫn xác minh & test Phase 1
└── contracts/
    └── agent-catalog-api.yaml # OpenAPI Contract Phase 1
```

### Source code

#### Backend: `flex-agent-service/`
```text
flex-agent-service/
├── src/
│   ├── Flex.Agent.Domain/
│   │   └── Entities/
│   │       └── Agent.cs
│   ├── Flex.Agent.Infrastructures/
│   │   ├── Persistence/
│   │   │   └── AgentDbContext.cs   # Fluent API mapping, KHÔNG có Migrations/ (schema quản lý ở flex-database/agentdb/)
│   │   └── Repositories/
│   │       └── AgentRepository.cs
│   └── Flex.Agent.Api/
│       ├── Controllers/
│       │   └── AgentsController.cs
│       ├── DTOs/
│       │   ├── AgentResponseDto.cs
│       │   ├── CreateAgentRequestDto.cs
│       │   └── UpdateAgentRequestDto.cs
│       └── Program.cs
└── tests/
    ├── Flex.Agent.UnitTests/
    └── Flex.Agent.IntegrationTests/
```

#### Database: `flex-database/agentdb/`
```text
flex-database/
└── agentdb/
    ├── migrations/
    │   └── V1.1__create_table_agents.sql
    └── seeders/          # Chỉ dùng nếu cần seed dữ liệu mẫu, hiện "Không áp dụng"
```

#### Frontend: `flex-microfrontend/`
```text
flex-microfrontend/
└── src/
    └── app/
        └── features/
            └── agent-catalog/
                ├── components/
                │   ├── agent-list/
                │   ├── agent-form-modal/
                │   └── agent-delete-confirm-modal/
                ├── services/
                │   └── agent.service.ts
                └── models/
                    └── agent.model.ts
```

---

## Rollout & Rollback

**Kế hoạch rollout**:
1. Chạy migration script `flex-database/agentdb/migrations/V1.1__create_table_agents.sql` trên môi trường Staging/Production (theo script migrate của repo `flex-database`).
2. Deploy backend service `flex-agent-service`.
3. Deploy frontend bundle `flex-microfrontend`.

**Rollback code/config**:
1. Revert commit frontend & backend.
2. Rollback dữ liệu/migration: ưu tiên forward-fix theo quy ước `flex-database` (không rollback tự động); nếu bắt buộc gỡ bảng, thêm script rollback riêng trong `flex-database/agentdb/`.

---

## Observability & Debug

**Log cần có**:
- `AgentCreated`: `agentId`, `agentName`, `userId`, `timestamp`
- `AgentUpdated`: `agentId`, `agentName`, `userId`, `timestamp`
- `AgentDeleted`: `agentId`, `userId`, `timestamp`
- `AgentDuplicateNameRejected`: `attemptedName`, `userId`, `timestamp`

**Metric cần theo dõi**:
- API Response latency $p95 < 500\text{ms}$
- Tỷ lệ lỗi 4xx / 5xx trên `AgentsController`

---

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component tham gia.
- [x] Traceability matrix đã map 100% US/FR/AC sang module/path, contract & test.
- [x] API contract đã được định nghĩa tại `contracts/agent-catalog-api.yaml`.
- [x] Data model & migration strategy đã rõ trong `data-model.md`.
- [x] Chiến lược kiểm thử đã bao phủ unit, integration & manual E2E.
- [x] Cấu trúc project đã liệt kê path thật trong sub-repos.
- [x] Constitution gate không còn blocker.
