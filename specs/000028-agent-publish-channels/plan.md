# Kế hoạch triển khai: Tab Thiết lập thông tin chung & Phát hành đa kênh cho Agent

**Branch**: `000028-agent-publish-channels` | **Ngày**: 2026-08-05 | **Đặc tả**: [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000028-agent-publish-channels/spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000028-agent-publish-channels/spec.md`

---

## Tóm tắt

**Yêu cầu chính từ spec**:
- Tổ chức lại modal chi tiết/sửa agent thành 2 tab: "Thiết lập thông tin chung" (giữ nguyên hành vi hiện có của `specs/000026-agent-catalog`) và "Phát hành" (mới) (MVP-001 → MVP-002).
- Tab "Phát hành" hiển thị đủ 5 kênh dự kiến (Fanpage Facebook, Zalo OA, Website, Chatbot, Zalo cá nhân); chỉ kênh Website bật/tắt và lưu được thật, 4 kênh còn lại "chưa khả dụng" (MVP-005, FR-009).
- Bật/tắt kênh dùng chung 1 hành động "Lưu" với tab thông tin chung — không auto-save, không nút riêng (MVP-003, FR-008, BR-004).
- Tab "Phát hành" bị khóa cho tới khi agent đã được tạo lần đầu (MVP-004, FR-007).

**Hướng tiếp cận kỹ thuật dự kiến**:
- Backend: mở rộng `flex-agent-service` — thêm bảng/entity `AgentPublishLocation`, mở rộng payload 2 endpoint đã có (`POST`/`PUT /api/v1/agents`), không tạo endpoint mới.
- Frontend: mở rộng `flex-microfrontend` — thêm tab navigation vào `AgentFormModalComponent` hiện có (modal-xl), không tạo modal/màn hình mới.
- Migration: `flex-database/agentdb/` (versioned SQL), theo đúng convention đã document, khác với tiền lệ lệch chuẩn của `specs/000022-instagram-business`.

**Kết quả sau research**: Đã hoàn thành Phase 0 Research, ghi tại [research.md](file:///C:/Workspace/Project/flex-workstation/specs/000028-agent-publish-channels/research.md). 4 câu hỏi kỹ thuật (TQ-001 → TQ-004) đã resolve, gồm 1 xung đột thực tế giữa tài liệu convention và tiền lệ code (`specs/000022-instagram-business`) — đã hỏi và được người dùng xác nhận chọn theo tài liệu convention (`flex-database/agentdb/`).

---

## Phạm vi kỹ thuật

**Trong phạm vi**:
- **Backend (`flex-agent-service`)**:
  - Domain Entity `AgentPublishLocation` trong `Flex.Agent.Domain`.
  - `AppDbContext` mapping bảng `agent_publish_locations` (Fluent API, không sinh EF Core Migration — schema quản lý ở `flex-database/agentdb/`).
  - Repository mới cho `AgentPublishLocation` trong `Flex.Agent.Infrastructures`.
  - Mở rộng `CreateAgentRequestDto`/`UpdateAgentRequestDto`/`AgentResponseDto` và logic `AgentsController.CreateAgent`/`UpdateAgent`/`GetAgentById`/`GetAgents` để nhận/trả `publishLocations`.
  - Validate whitelist `locationCode` (chỉ `"website"` được ghi ở MVP — FR-009).
  - Backend Unit & Integration Tests cho phần mở rộng.
- **Frontend (`flex-microfrontend`)**:
  - Thêm tab navigation ("Thiết lập thông tin chung" / "Phát hành") vào `AgentFormModalComponent` hiện có.
  - Catalog tĩnh 5 kênh (code, tên, mô tả, khả dụng/chưa khả dụng) trong module `agent-catalog`.
  - Component/section hiển thị danh sách kênh dạng thẻ + công tắc bật/tắt (chỉ Website thao tác được).
  - Cập nhật `Agent`/`CreateAgentRequest`/`UpdateAgentRequest` model, `AgentService` gửi kèm `publishLocations`.
  - Client-side validate: khóa tab "Phát hành" khi chưa ở edit mode (agent chưa tồn tại).

**Ngoài phạm vi kỹ thuật**:
- Tích hợp OAuth/kết nối thật cho Facebook, Zalo, Chatbot — các kênh này chỉ là danh sách tĩnh Frontend, không có backend logic (khớp §15 spec).
- Sinh mã nhúng widget Website, xử lý runtime chat qua bất kỳ kênh nào — thuộc `specs/000008-agent-platform-mvp`.
- Đồng bộ/dọn dẹp lại migration lệch chuẩn của `specs/000022-instagram-business` (`AddInstagramTables.sql` trong `flex-agent-service`) — ghi nhận là nợ kỹ thuật riêng ở [research.md](file:///C:/Workspace/Project/flex-workstation/specs/000028-agent-publish-channels/research.md) TQ-001, không xử lý trong feature này.
- Các file `.tsx` mồ côi tại `flex-microfrontend/src/components/publish/` (không nằm trong Angular build, không được import ở bất kỳ module nào đã kiểm tra) và trang sandbox test Instagram độc lập tại `flex-microfrontend/src/app/pages/publish/` (route `/publish`, không gắn với agent cụ thể) — không liên quan tới tab "Phát hành" theo agent của feature này, không được sửa/xóa trong phạm vi này (ghi nhận riêng, không tự ý dọn dead code chưa được yêu cầu).

---

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: C# 13 / .NET 9.0 (Backend), TypeScript / Angular (Frontend) — giống `specs/000026-agent-catalog`.

**Service/App liên quan**: `flex-agent-service` (API backend), `flex-microfrontend` (UI frontend). Không chạm `flex-auth-service` (tái sử dụng JWT hiện có).

**Convention skill áp dụng**: `flex-agent-service` (.NET) → `flex-dotnet-engineering`; `flex-microfrontend` (Angular) → `flex-frontend-engineering`.

**Phụ thuộc chính**: ASP.NET Core 9 Web API, Entity Framework Core 9.0 (`Npgsql.EntityFrameworkCore.PostgreSQL`), Angular Reactive Forms + HttpClient — toàn bộ đã có sẵn trong 2 repo, không thêm package mới.

**Lưu trữ**: PostgreSQL (`agentdb`), bảng mới `agent_publish_locations` — cùng database với bảng `agents` (`specs/000026-agent-catalog`), repo migration `flex-database/agentdb/` (xem TQ-001/TQ-002 ở research.md).

**Kiểm thử**: xUnit cho Backend Unit/Integration tests.

**Nền tảng chạy**: Linux container / Windows Service (giống `flex-agent-service` hiện có).

**Đơn vị deploy**: `flex-agent-service` (Docker container / Web API executable), `flex-microfrontend` (Static Web App) — không thêm đơn vị deploy mới.

**Loại project**: web-service & admin-web.

**Mục tiêu hiệu năng**: Mở tab "Phát hành" và tìm đúng vị trí trong vòng 5 giây (SC-001); lưu cấu hình kênh cùng request với thông tin chung, không cộng thêm round-trip.

**Ràng buộc**: Mọi thao tác đọc/ghi `publishLocations` PHẢI đi qua endpoint `/api/v1/agents` đã có JWT Bearer Auth (SEC-001/SEC-002, kế thừa từ `specs/000026-agent-catalog`).

**Quy mô/Phạm vi**: Tối đa 5 kênh hiển thị mỗi agent (danh sách cố định MVP), tối đa 1 row `agent_publish_locations` được ghi thật mỗi agent (`location_code = 'website'`).

---

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Phạm vi kỹ thuật khớp 100% MVP-001 → MVP-006 và "Ngoài phạm vi" của spec |
| Traceability Gate | Pass | Pass | 100% US/FR P1–P3 có mapping sang module/path/API/data/test bên dưới |
| Security Gate | Pass | Pass | Tái sử dụng JWT Auth + `[Authorize]` hiện có trên `AgentsController`, không mở endpoint mới không auth |
| Test Gate | Pass | Pass | Có unit/integration test cho entity, repository, controller mở rộng và validate whitelist |
| Complexity Gate | Pass | Pass | Không tạo endpoint mới, không tạo service/module mới ngoài 1 bảng + repository; tái sử dụng modal hiện có thay vì màn hình mới |
| Nguyên tắc VI (database/repo migration) | Cần research | Pass | Xung đột tài liệu vs. tiền lệ Instagram đã được ghi nhận và hỏi người dùng (TQ-001); quyết định cuối: `flex-database/agentdb/`, đúng tài liệu convention |

---

## Câu hỏi kỹ thuật cần research

Đã resolve toàn bộ ở [research.md](file:///C:/Workspace/Project/flex-workstation/specs/000028-agent-publish-channels/research.md):

- **TQ-001**: Vị trí migration cho bảng mới trong `agentdb` — xung đột giữa tài liệu convention (`flex-database/agentdb/`) và tiền lệ `specs/000022-instagram-business` (`flex-agent-service/.../Persistence/Migrations/`).
  - **Kết quả**: `flex-database/agentdb/migrations/V1.2__create_table_agent_publish_locations.sql`, xác nhận bởi người dùng (2026-08-05), theo đúng tài liệu convention (constitution ưu tiên cao hơn code precedent lệch chuẩn).
- **TQ-002**: Mô hình dữ liệu lưu trạng thái kênh — cột boolean trên `agents` hay bảng riêng?
  - **Kết quả**: Bảng riêng `agent_publish_locations` với cột `configuration JSONB` dự phòng mở rộng, theo yêu cầu người dùng (2026-08-05).
- **TQ-003**: Tab "Phát hành" có API/nút lưu riêng không?
  - **Kết quả**: Không — mở rộng payload 2 endpoint `POST`/`PUT /api/v1/agents` đã có, đúng theo Clarifications của spec (Session 2026-08-05).
- **TQ-004**: Danh sách 5 kênh cố định + trạng thái khả dụng lấy từ đâu?
  - **Kết quả**: Catalog tĩnh phía Frontend, không lưu DB, không expose API riêng (MVP chỉ cần hiển thị, không có hành vi backend gắn với 4 kênh chưa khả dụng).

---

## Thiết kế tổng quan

**Luồng chính**:
1. Quản trị viên mở modal chi tiết/sửa agent trên `flex-microfrontend` (`AgentFormModalComponent`).
2. Modal hiển thị 2 tab: "Thiết lập thông tin chung" (mặc định, active) và "Phát hành". Nếu đang ở luồng tạo mới (chưa có `agent.id`), tab "Phát hành" bị vô hiệu hóa.
3. Khi mở tab "Phát hành": component render 5 thẻ kênh từ catalog tĩnh; giá trị công tắc Website lấy từ `agent.publishLocations` (tìm `locationCode === 'website'`, mặc định `false` nếu không có); 4 kênh còn lại luôn hiển thị công tắc vô hiệu hóa.
4. Quản trị viên chỉnh thông tin chung và/hoặc bật/tắt công tắc Website — mọi thay đổi chỉ ở `FormGroup` phía client, chưa gửi lên server.
5. Bấm nút "Lưu"/"Cập nhật" (chung cho cả 2 tab) → Frontend gọi `PUT /api/v1/agents/{id}` (hoặc `POST` khi tạo mới) với payload gồm `name`/`description`/`status` như cũ + `publishLocations: [{ locationCode: 'website', isEnabled }]`.
6. Backend `AgentsController` validate tên (như cũ) + validate `publishLocations` (chỉ chấp nhận `locationCode = 'website'`, từ chối 400 nếu khác); dùng repository mới upsert row `agent_publish_locations (agent_id, 'website')` trong cùng transaction với cập nhật `agents`.
7. Response trả về `AgentResponse` gồm `publishLocations` mới nhất; Frontend cập nhật lại state modal.

**Component/module tham gia**:
- `Flex.Agent.Domain`: thêm entity `AgentPublishLocation`.
- `Flex.Agent.Infrastructures`: `AppDbContext` mapping bảng mới; `AgentPublishLocationRepository` mới.
- `Flex.Agent.Api`: mở rộng `AgentsController`, `CreateAgentRequestDto`, `UpdateAgentRequestDto`, `AgentResponseDto`, thêm `PublishLocationDto`/`PublishLocationRequestDto`.
- `flex-microfrontend` (`agent-catalog` module): mở rộng `AgentFormModalComponent` (tab UI), `Agent`/`CreateAgentRequest`/`UpdateAgentRequest` model, `AgentService` (không đổi method signature, chỉ đổi shape payload).

**Điểm mở rộng/thay đổi chính**:
- `AgentsController.CreateAgent`/`UpdateAgent`: thêm bước validate + upsert `publishLocations` sau khi validate tên như cũ, trước `SaveChangesAsync`.
- `AgentFormModalComponent`: thêm state `activeTab` và `websiteEnabled` (FormControl), giữ nguyên toàn bộ logic tab "Thiết lập thông tin chung" hiện có (BR-002).

**Luồng thay thế/lỗi chính**:
- `publishLocations` chứa `locationCode` ngoài whitelist với `isEnabled=true` → Backend trả 400 `PUBLISH_LOCATION_NOT_AVAILABLE` (FR-009). UI không cho phép trường hợp này xảy ra qua thao tác chuột (công tắc các kênh khác disabled), lỗi này chỉ xảy ra nếu client gọi thẳng API.
- Lưu thất bại (lỗi mạng/500) → Frontend giữ nguyên trạng thái form hiện tại (bao gồm công tắc Website đang bật/tắt tạm thời), báo lỗi qua toast, không tự đóng modal (khớp §6 spec "Lỗi hệ thống").
- Agent chưa tồn tại (route tạo mới) mà cố truy cập tab "Phát hành" → tab bị vô hiệu hóa ở UI; nếu client cố gọi thẳng `POST /api/v1/agents` với `publishLocations` không rỗng, Backend vẫn xử lý bình thường vì tại thời điểm đó `agent.Id` vừa được tạo trong cùng request (Create + publishLocations upsert trong cùng transaction) — không có race condition vì đây là 1 request duy nhất.

**Thay đổi boundary giữa service/module**: Không áp dụng — mọi thay đổi nằm trong 2 boundary hiện có (`flex-agent-service` ↔ `flex-microfrontend`), không thêm service mới, không đổi hợp đồng với `flex-auth-service`.

**Idempotency/Concurrency**:
- Upsert `agent_publish_locations` theo `UNIQUE(agent_id, location_code)`: gọi `PUT` nhiều lần với cùng `isEnabled` chỉ update `updated_at`, không tạo row trùng (khớp spec "Người dùng thao tác lặp lại").
- Không có concurrent-edit handling đặc biệt (giống `specs/000026-agent-catalog`, ghi đè theo lần lưu cuối — MVP chưa yêu cầu optimistic locking).

---

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001, FR-003 | P1 | Đủ rõ | Thêm tab navigation vào modal hiện có, tab thông tin chung mặc định active | `flex-microfrontend/src/app/features/agent-catalog/components/agent-form-modal/agent-form-modal.component.ts` + `.html` | Không áp dụng (thuần UI) | Không áp dụng | Manual/E2E |
| US-001 / FR-002 | P1 | Đủ rõ | Giữ nguyên toàn bộ control/validate hiện có của tab thông tin chung, chỉ đổi vị trí render | `agent-form-modal.component.html` | `POST`/`PUT /api/v1/agents` (không đổi field cũ) | Bảng `agents` (không đổi) | Regression: chạy lại quickstart 000026 |
| US-001 / FR-007 | P2 | Đủ rõ | Disable tab "Phát hành" khi `!isEditMode` | `agent-form-modal.component.ts` (`get isEditMode`) | Không áp dụng | Không áp dụng | Manual: tạo mới agent, xác nhận tab khóa |
| US-002 / US-003 / FR-004, FR-005, FR-006, FR-008 | P1 | Đủ rõ | Thêm `FormControl('websiteEnabled')`; submit gộp `publishLocations` vào payload chung; Backend upsert `agent_publish_locations` trong cùng transaction với update `agents` | FE: `agent-form-modal.component.ts`; BE: `Flex.Agent.Api/Controllers/AgentsController.cs`, `Flex.Agent.Infrastructures/Repositories/AgentPublishLocationRepository.cs` | `POST`/`PUT /api/v1/agents` (field mới `publishLocations`) | Bảng `agent_publish_locations` | Unit (DTO/validate) & Integration (upsert + đọc lại) |
| US-004 / FR-009 | P3 | Đủ rõ | Catalog tĩnh 5 kênh phía FE; công tắc ngoài Website luôn `disabled`; Backend từ chối 400 nếu `locationCode` ngoài whitelist | FE: `agent-catalog/publish-locations.catalog.ts` (mới); BE: `AgentsController` (validate) | `POST`/`PUT /api/v1/agents` (400 `PUBLISH_LOCATION_NOT_AVAILABLE`) | Không áp dụng | Unit (whitelist validate) & Manual (UI hiển thị 5 kênh) |

---

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Thêm bảng mới `agent_publish_locations` trong PostgreSQL `agentdb`, FK tới `agents(id)` | Không đổi bảng `agents` hiện có; additive-only | Chạy migration `flex-database/agentdb/migrations/V1.2__create_table_agent_publish_locations.sql`, verify `psql \d agent_publish_locations` |
| API/Contract | Mở rộng field `publishLocations` trên `POST`/`PUT`/`GET /api/v1/agents` (request optional, response thêm field) | Backward compatible — client cũ không gửi field vẫn hoạt động như trước | Xem [contracts/agent-publish-channels-api.md](file:///C:/Workspace/Project/flex-workstation/specs/000028-agent-publish-channels/contracts/agent-publish-channels-api.md); chạy lại test cũ của `AgentsController` (000026) đảm bảo không regression |
| Permission/Security | Không đổi permission model — cùng `[Authorize]` JWT như CRUD agent hiện có | Không phát sinh rủi ro quyền mới | Integration test: gọi `PUT` với `publishLocations` mà không có token → 401 |
| Logging/Audit | Không áp dụng ở MVP (spec §11: audit đầy đủ thuộc `specs/000008-agent-platform-mvp`) | Không áp dụng | Không áp dụng |
| UI/UX | Modal `AgentFormModalComponent` đổi từ layout phẳng sang tab; thêm section danh sách kênh | Rủi ro: hồi quy layout/validate tab thông tin chung nếu tách sai; giảm thiểu bằng cách giữ nguyên `FormGroup` gốc, chỉ bọc thêm tab UI | Manual/E2E theo `quickstart.md` (Kịch bản 1, 6) |
| Job/Worker/Integration | Không áp dụng — không có job/async/webhook mới | Không áp dụng | Không áp dụng |

---

## API/Contract Detail

**Có thay đổi contract không**: Có — mở rộng field trên contract đã có (không tạo endpoint mới).

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `POST /api/v1/agents` | API | Thêm field optional `publishLocations` vào request; thêm field `publishLocations` vào response | Có (additive) | `flex-microfrontend` (`AgentService`) |
| `PUT /api/v1/agents/{id}` | API | Thêm field optional `publishLocations` vào request; thêm field `publishLocations` vào response | Có (additive) | `flex-microfrontend` (`AgentService`) |
| `GET /api/v1/agents`, `GET /api/v1/agents/{id}` | API | Thêm field `publishLocations` vào response | Có (additive) | `flex-microfrontend` (`AgentService`) |

Chi tiết: [contracts/agent-publish-channels-api.md](file:///C:/Workspace/Project/flex-workstation/specs/000028-agent-publish-channels/contracts/agent-publish-channels-api.md) (delta so với [`specs/000026-agent-catalog/contracts/agent-catalog-api.yaml`](file:///C:/Workspace/Project/flex-workstation/specs/000026-agent-catalog/contracts/agent-catalog-api.yaml)).

---

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---------------|-----|-----|-----|-----|-------------|---------|
| Quản trị viên (đã đăng nhập, JWT hợp lệ) | Có | Có | Có | Không áp dụng (không xóa row kênh riêng lẻ ở MVP) | Không áp dụng | Giống hệt quyền CRUD agent hiện có (`specs/000026-agent-catalog`) |
| Khách / chưa đăng nhập | Không | Không | Không | Không áp dụng | Không áp dụng | 401 Unauthorized, kế thừa `[Authorize]` hiện có |

---

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Có (thêm bảng `agent_publish_locations` mới).

**Database đích**: PostgreSQL `agentdb` — cùng database với bảng `agents` (`specs/000026-agent-catalog`), database riêng cho Agent Platform/Agent Catalog, tách khỏi `flexdb` control plane. Xác nhận theo [system-map.md](file:///C:/Workspace/Project/flex-workstation/docs/architecture/system-map.md) §5 Data Architecture.

**Repo chứa migration**: `flex-database/agentdb/` — xác nhận bởi người dùng (2026-08-05) sau khi phát hiện xung đột với tiền lệ `specs/000022-instagram-business` (đặt migration trong `flex-agent-service`, lệch tài liệu convention). Xem [research.md](file:///C:/Workspace/Project/flex-workstation/specs/000028-agent-publish-channels/research.md) TQ-001.

**Migration**:
- File mới: `flex-database/agentdb/migrations/V1.2__create_table_agent_publish_locations.sql`.
- Nội dung: `CREATE TABLE IF NOT EXISTS agent_publish_locations (...)` theo schema ở [data-model.md](file:///C:/Workspace/Project/flex-workstation/specs/000028-agent-publish-channels/data-model.md), gồm FK `agent_id REFERENCES agents(id) ON DELETE CASCADE`, `UNIQUE(agent_id, location_code)`, `INDEX(agent_id)`.
- `Flex.Agent.Infrastructures/Persistence/AppDbContext.cs` chỉ cấu hình Fluent API mapping tới bảng có sẵn (giống cách `agents` đã làm), KHÔNG sinh EF Core Migration.

**Backfill/Cleanup**: Không áp dụng — bảng mới, không có dữ liệu cũ cần backfill.

**Tương thích dữ liệu cũ**: Agent đã tạo trước feature này không có row `agent_publish_locations` nào → Backend trả `publishLocations: []` → Frontend hiển thị Website mặc định tắt (khớp AC-006, ràng buộc tương thích ngược ở spec §14).

**Rủi ro dữ liệu**:
- Ghi sai `location_code` ngoài whitelist nếu thiếu validate tầng ứng dụng → giảm thiểu bằng validate ở `AgentsController` (không dùng CHECK constraint DB để giữ linh hoạt mở rộng — xem data-model.md).
- Row mồ côi nếu xóa `Agent` mà không cascade → giảm thiểu bằng `ON DELETE CASCADE` trên FK.

**Cách xác minh**: `SELECT * FROM agent_publish_locations WHERE agent_id = '<id>';` sau khi bật/lưu kênh Website từ UI, xác nhận đúng 1 row `location_code='website', is_enabled=true`.

---

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Bảng riêng `agent_publish_locations` (không thêm cột vào `agents`) | Theo yêu cầu người dùng (2026-08-05); mở rộng được nhiều kênh sau này qua cột `configuration JSONB` mà không đổi schema `agents` | Cột boolean `is_website_enabled` trên bảng `agents` | Không mở rộng được khi có kênh thứ 2 hoạt động thật; phải thêm cột mới mỗi lần |
| DEC-002 | Migration tại `flex-database/agentdb/migrations/V1.2__...sql` | Đúng tài liệu convention (constitution.md/system-map.md) và tiền lệ bảng `agents` gốc; xác nhận bởi người dùng sau khi phát hiện xung đột với Instagram feature | `flex-agent-service/.../Persistence/Migrations/` (theo tiền lệ Instagram) | Người dùng chọn không tiếp tục lệch chuẩn; constitution.md ưu tiên cao nhất khi tài liệu và code precedent mâu thuẫn |
| DEC-003 | Mở rộng payload `POST`/`PUT /api/v1/agents` hiện có, không tạo endpoint mới | Khớp chính xác yêu cầu "1 nút Lưu chung" (Clarifications spec); tái sử dụng transaction/validation pipeline có sẵn | Endpoint riêng `PUT /api/v1/agents/{id}/publish-locations` | Phải tự đồng bộ 2 network call ở FE để giả lập "1 nút Lưu" — phức tạp không cần thiết |
| DEC-004 | Catalog 5 kênh định nghĩa tĩnh ở Frontend, không lưu DB/API | MVP chỉ 1 kênh có hành vi backend thật; tạo bảng/endpoint cho danh sách tĩnh là over-engineering (Constitution V) | Bảng `channel_catalog` dùng chung, API `GET /api/channels` | Không có nhu cầu nghiệp vụ thật ở MVP (4/5 kênh chưa có tích hợp nào); có thể bổ sung khi kênh thứ 2 triển khai thật |
| DEC-005 | Không dùng CHECK constraint DB cho `location_code`, validate ở tầng ứng dụng (`AgentsController`) | Linh hoạt thêm `location_code` mới (khi kênh khác được kích hoạt thật) mà không cần migration đổi CHECK constraint | CHECK constraint `location_code IN (...)` ở DB | Mỗi lần mở kênh mới phải chạy thêm migration đổi constraint, không cần thiết ở MVP |

---

## Chiến lược kiểm thử

**Unit test**:
- `AgentPublishLocation` entity mapping/validation cơ bản.
- Validate whitelist `locationCode` trong `AgentsController` (chấp nhận `"website"`, từ chối giá trị khác với 400).
- DTO mapping `PublishLocationDto`/`PublishLocationRequestDto`.

**Integration test**:
- `AgentsControllerIntegrationTests` mở rộng: `PUT /api/v1/agents/{id}` với `publishLocations: [{locationCode:"website", isEnabled:true}]` → verify row DB đúng + response đúng.
- Bật rồi tắt lại nhiều lần → verify chỉ có 1 row (`UNIQUE(agent_id, location_code)`, không duplicate).
- `POST`/`PUT` với `locationCode` ngoài whitelist → verify 400 `PUBLISH_LOCATION_NOT_AVAILABLE`.
- `GET /api/v1/agents/{id}` cho agent chưa từng cấu hình kênh → verify `publishLocations: []`.

**Contract test**:
- Verify response `AgentResponse` vẫn chứa đầy đủ field cũ (`id`, `name`, `status`, `createdAt`, `updatedAt`) khi thêm `publishLocations` — không breaking change cho client cũ.

**Permission/security test**:
- Gọi `PUT /api/v1/agents/{id}` kèm `publishLocations` mà không có JWT token → 401 (kế thừa test case có sẵn của 000026, mở rộng payload).

**E2E/manual test**:
- Theo 6 kịch bản trong [quickstart.md](file:///C:/Workspace/Project/flex-workstation/specs/000028-agent-publish-channels/quickstart.md).

**Regression test**:
- Chạy lại toàn bộ 6 kịch bản quickstart của `specs/000026-agent-catalog/quickstart.md` — đảm bảo tab "Thiết lập thông tin chung" không đổi hành vi (SC-003).

---

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000028-agent-publish-channels/
├── spec.md               # Đặc tả nghiệp vụ
├── plan.md                # File kế hoạch này
├── research.md             # Output Phase 0
├── data-model.md           # Output Phase 1
├── quickstart.md           # Output Phase 1
├── contracts/
│   └── agent-publish-channels-api.md  # Output Phase 1 (delta contract)
└── tasks.md                # Output Phase 2 (lệnh /speckit-tasks)
```

### Source code (repository root)

```text
# Backend: flex-agent-service/
flex-agent-service/
├── src/
│   ├── Flex.Agent.Domain/
│   │   ├── Entities/
│   │   │   ├── Agent.cs                          # Không đổi
│   │   │   └── AgentPublishLocation.cs           # MỚI
│   │   └── Repositories/
│   │       ├── IAgentRepository.cs                # Không đổi
│   │       └── IAgentPublishLocationRepository.cs # MỚI
│   ├── Flex.Agent.Infrastructures/
│   │   ├── Persistence/
│   │   │   └── AppDbContext.cs                    # Sửa: thêm DbSet + Fluent mapping agent_publish_locations
│   │   └── Repositories/
│   │       ├── AgentRepository.cs                 # Không đổi
│   │       └── AgentPublishLocationRepository.cs  # MỚI
│   └── Flex.Agent.Api/
│       ├── Controllers/
│       │   └── AgentsController.cs                # Sửa: nhận/trả publishLocations, validate whitelist
│       └── DTOs/
│           ├── AgentResponseDto.cs                # Sửa: thêm PublishLocations
│           ├── CreateAgentRequestDto.cs           # Sửa: thêm PublishLocations
│           ├── UpdateAgentRequestDto.cs           # Sửa: thêm PublishLocations
│           └── PublishLocationDto.cs              # MỚI (response + request item)
└── tests/
    └── Flex.Agent.Tests/
        └── Agents/
            ├── UpdateAgentIntegrationTests.cs      # Sửa: thêm case publishLocations
            └── PublishLocationValidationTests.cs   # MỚI

# Database: flex-database/agentdb/
flex-database/
└── agentdb/
    └── migrations/
        ├── V1.1__create_table_agents.sql           # Không đổi
        └── V1.2__create_table_agent_publish_locations.sql  # MỚI

# Frontend: flex-microfrontend/
flex-microfrontend/
└── src/
    └── app/
        └── features/
            └── agent-catalog/
                ├── components/
                │   └── agent-form-modal/
                │       ├── agent-form-modal.component.ts    # Sửa: tab state, websiteEnabled control
                │       ├── agent-form-modal.component.html  # Sửa: tab nav + section kênh
                │       └── agent-form-modal.component.scss  # Sửa nhỏ nếu cần style tab
                ├── models/
                │   └── agent.model.ts                       # Sửa: thêm PublishLocation, publishLocations field
                ├── services/
                │   └── agent.service.ts                     # Không đổi signature, payload tự rộng theo model
                └── publish-locations.catalog.ts              # MỚI — catalog tĩnh 5 kênh
```

**Quyết định cấu trúc**: Tái sử dụng nguyên vẹn cấu trúc module `agent-catalog` đã có từ `specs/000026-agent-catalog`; không tạo module/route Angular mới, không tạo project/service .NET mới. Toàn bộ thay đổi backend nằm trong 3 project hiện có của `flex-agent-service` (`Flex.Agent.Domain`, `Flex.Agent.Infrastructures`, `Flex.Agent.Api`), đúng Complexity Gate.

---

## Rollout & Rollback

**Kế hoạch rollout**:
1. Chạy migration `flex-database/agentdb/migrations/V1.2__create_table_agent_publish_locations.sql` trên Staging/Production.
2. Deploy `flex-agent-service` (đã có endpoint mở rộng — backward compatible với client cũ).
3. Deploy `flex-microfrontend` (tab UI mới).

**Tương thích ngược**: Client Frontend cũ (chưa deploy) gọi API mới vẫn hoạt động bình thường vì `publishLocations` là field optional trên request và field mới (bỏ qua được) trên response. Backend mới nhận request từ Frontend cũ (không có `publishLocations`) vẫn xử lý bình thường (không update bảng kênh).

**Feature flag/config**: Không áp dụng — tính năng additive, không cần bật/tắt qua flag; rủi ro thấp vì không đổi hành vi hiện có, chỉ thêm tab mới.

**Thực thi migration/backfill khi rollout**: Chạy migration trước khi deploy `flex-agent-service` (bước 1 → 2), tránh service khởi động với entity mapping tới bảng chưa tồn tại.

**Rollback code/config**:
1. Revert commit frontend & backend.
2. Backend cũ (không biết `AgentPublishLocation`) vẫn chạy được với bảng mới tồn tại trong DB (bảng thừa, không gây lỗi).

**Rollback dữ liệu/migration**: Ưu tiên forward-fix theo quy ước `flex-database` (không rollback tự động); nếu bắt buộc gỡ bảng, thêm script rollback riêng trong `flex-database/agentdb/` (`DROP TABLE agent_publish_locations;`), chỉ chạy khi chắc chắn không còn service nào phụ thuộc.

**Điều kiện kích hoạt rollback**: Lỗi 500 hàng loạt trên `POST`/`PUT /api/v1/agents` sau deploy (nghi ngờ do mapping bảng mới sai), hoặc phát hiện dữ liệu `agent_publish_locations` sai lệch nghiêm trọng ảnh hưởng tab thông tin chung.

---

## Observability & Debug

**Log cần có**:
- `AgentPublishLocationUpdated`: `agentId`, `locationCode`, `isEnabled`, `userId`, `timestamp`.
- `AgentPublishLocationRejected`: `agentId`, `attemptedLocationCode`, `userId`, `timestamp` (khi validate whitelist từ chối).

**Dữ liệu không được log**: Không áp dụng — `agent_publish_locations` MVP không chứa token/secret (khác `meta_account_connections`/`instagram_page_connections` của 000022, không liên quan tính năng này).

**Metric cần theo dõi**:
- Tỷ lệ lỗi 400 `PUBLISH_LOCATION_NOT_AVAILABLE` trên `AgentsController` (bất thường nếu tăng đột biến — có thể do bug FE gửi sai locationCode).
- API Response latency `POST`/`PUT /api/v1/agents` p95 < 500ms (kế thừa mục tiêu của 000026, không tăng thêm round-trip).

**Trace/Correlation**: Không áp dụng — dùng chung request pipeline/logging middleware hiện có của `flex-agent-service` (không có traceId riêng cho tính năng này).

**Cách kiểm tra sau release**: Query `SELECT COUNT(*) FROM agent_publish_locations WHERE location_code = 'website' AND is_enabled = true;` để xác nhận tính năng được dùng sau khi rollout; Swagger UI smoke test `PUT /api/v1/agents/{id}` với payload mẫu ở [contracts/agent-publish-channels-api.md](file:///C:/Workspace/Project/flex-workstation/specs/000028-agent-publish-channels/contracts/agent-publish-channels-api.md).

**Tình huống debug chính**:
- Toggle Website không lưu được → kiểm tra log `AgentPublishLocationRejected` (sai locationCode) hoặc lỗi transaction giữa update `agents` và upsert `agent_publish_locations`.
- Tab "Phát hành" hiển thị sai trạng thái sau khi lưu → kiểm tra response `GET /api/v1/agents/{id}` có đúng `publishLocations` không, hay lỗi cache phía FE.
- Migration lỗi khi deploy → kiểm tra FK `agent_id REFERENCES agents(id)` (bảng `agents` phải tồn tại trước — đã đảm bảo vì `agents` tạo từ 000026).

---

## Theo dõi độ phức tạp

Không áp dụng — không có vi phạm constitution nào cần biện minh (xem "Kiểm tra constitution" ở trên, toàn bộ gate Pass).

---

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research (TQ-001 → TQ-004), bao gồm 1 xung đột thực tế đã hỏi và được người dùng xác nhận.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá (upsert theo UNIQUE constraint).
- [x] Mỗi US/FR P1–P3 liên quan code/data/API đều có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá.
- [x] Contract thay đổi đã có consumer bị ảnh hưởng (`flex-microfrontend`) và cách kiểm tra backward compatibility.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ.
- [x] Database đích (`agentdb`) và repo chứa migration (`flex-database/agentdb/`) đã được xác định, đối chiếu `system-map.md`, và xử lý xung đột tiền lệ qua xác nhận người dùng (Constitution VI).
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại (DEC-001 → DEC-005).
- [x] Chiến lược kiểm thử đã bao phủ unit, integration, contract, permission/security, E2E/manual và regression.
- [x] Rollout, rollback code/config, rollback dữ liệu/migration, feature flag/config và backward compatibility đã rõ.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật đã xác minh trong repository.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
