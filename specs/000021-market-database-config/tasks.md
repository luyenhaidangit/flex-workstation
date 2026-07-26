# Tasks: Chuyển cấu hình danh sách market và schedule từ hardcode JSON sang CSDL

**Đầu vào**: Design documents từ `/specs/000021-market-database-config/`

**Điều kiện tiên quyết**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/exchange-api-contracts.md`

---

## Phase 1: Setup

**Mục đích**: Khởi tạo migration script trong CSDL `flex-database`.

- [x] T001 Tạo migration script `001-create-exchange-markets.sql` trong `flex-database/hnx/changelog/releases/1.0.0.1/001-create-exchange-markets.sql`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Tạo entity, repository, service và đăng ký DI trong `flex-exchange-service` trước khi gắn vào vòng lặp `SessionWorker` và Controller.

- [x] T002 [P] Tạo `MarketEntity.cs` trong `flex-exchange-service/src/Flex.Exchange.Api/Models/MarketEntity.cs`
- [x] T003 [P] Tạo `MarketView.cs` trong `flex-exchange-service/src/Flex.Exchange.Api/Models/MarketView.cs`
- [x] T004 [P] Tạo interface `IMarketRepository.cs` trong `flex-exchange-service/src/Flex.Exchange.Api/Repositories/Interfaces/IMarketRepository.cs`
- [x] T005 Implement `MarketRepository.cs` bằng Dapper/Npgsql truy vấn bảng `exchange_markets` trong `flex-exchange-service/src/Flex.Exchange.Api/Repositories/MarketRepository.cs` (phụ thuộc T002, T004)
- [x] T006 [P] Tạo interface `IMarketService.cs` trong `flex-exchange-service/src/Flex.Exchange.Api/Services/IMarketService.cs`
- [x] T007 Implement `MarketService.cs` bọc MemoryCache và hỗ trợ fallback về `appsettings.json` trong `flex-exchange-service/src/Flex.Exchange.Api/Services/MarketService.cs` (phụ thuộc T005, T006)
- [x] T008 Đăng ký `IMarketRepository` và `IMarketService` vào Service Container trong `flex-exchange-service/src/Flex.Exchange.Api/Extensions/ServiceExtensions.cs` (phụ thuộc T005, T007)

---

## Phase 3: User Story 1 - Dịch vụ khởi tạo phiên giao dịch từ CSDL (Priority: P1) MVP

**Goal**: `flex-exchange-service` đọc danh sách thị trường active và lịch trình phiên tự động từ CSDL để vận hành vòng lặp `SessionWorker`.

**Independent Test**:
1. Khởi chạy `flex-exchange-service` (`dotnet run`).
2. Quan sát log hệ thống nạp đúng 4 thị trường `HOSE`, `HNX`, `UPCOM`, `DERIVATIVES` từ CSDL.
3. Cập nhật `status = 'inactive'` cho thị trường `DERIVATIVES` trong CSDL, kiểm tra phiên tiếp theo thị trường đó không được nạp vào vòng lặp phiên.

### Implementation for User Story 1

- [x] T009 [US1] Cập nhật `SessionWorker.cs` đọc thị trường và lịch trình phiên động từ `IMarketService` thay vì `TradingSessionOptions` trong `flex-exchange-service/src/Flex.Exchange.Api/HostedServices/SessionWorker.cs` (phụ thuộc T007, T008)
- [x] T010 [US1] Cập nhật `SessionController.cs` validate mã thị trường hợp lệ theo `IMarketService` trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/SessionController.cs` (phụ thuộc T007)
- [x] T011 [US1] Cập nhật `MarketHub.cs` lấy default market từ `IMarketService` trong `flex-exchange-service/src/Flex.Exchange.Api/Hubs/MarketHub.cs` (phụ thuộc T007)
- [x] T012 [P] [US1] Tạo Unit Test kiểm tra `MarketService` xử lý cache và fallback thành công trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/MarketServiceTests.cs`

**Definition of Done**:
- `SessionWorker` tự động nạp danh sách thị trường từ CSDL.
- Independent Test của US1 chạy thành công.

---

## Phase 4: User Story 2 - Truy vấn danh sách thị trường động (Priority: P2)

**Goal**: Cung cấp API RESTful `GET /api/v1/markets` và `GET /api/v1/markets/{marketCode}` phục vụ các dịch vụ liên quan và Microfrontend.

**Independent Test**:
1. Gửi request HTTP `GET http://localhost:5000/api/v1/markets`.
2. Phản hồi 200 OK chứa mảng JSON danh sách các thị trường `active`.

### Implementation for User Story 2

- [x] T013 [US2] Tạo `MarketController.cs` định nghĩa các endpoint `GET /api/v1/markets` và `GET /api/v1/markets/{marketCode}` trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/MarketController.cs` (phụ thuộc T007)
- [x] T014 [P] [US2] Tạo Integration Test kiểm tra API `GET /api/v1/markets` trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/MarketControllerTests.cs`

**Definition of Done**:
- Endpoint `GET /api/v1/markets` trả về dữ liệu chuẩn theo contract `contracts/exchange-api-contracts.md`.
- Independent Test của US2 chạy thành công.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Kiểm tra toàn bộ luồng, tài liệu vận hành và kiểm thử độc lập.

- [x] T015 [P] Kiểm tra log và chạy smoke test bằng lệnh trong `specs/000021-market-database-config/quickstart.md`
- [x] T016 [P] Cập nhật sơ đồ danh mục thị trường trong `docs/architecture/system-map.md`

---

## Validation Commands

- Build service: `dotnet build flex-exchange-service/Flex.Exchange.sln`
- Run Unit & Integration Tests: `dotnet test flex-exchange-service/Flex.Exchange.sln`
- Run API Smoke Test: `curl -s http://localhost:5000/api/v1/markets`

---

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US-001 | T009, T010, T011, T012 |
| US-002 | T013, T014 |
| FR-001 | T001, T002, T005 |
| FR-002 | T007, T009 |
| FR-003 | T005, T007, T009 |
| FR-004 | T013, T014 |
| FR-005 | T001, T005 |
| BR-001 | T001, T005 |
| BR-002 | T005, T007 |
| BR-003 | T001, T002 |
| BR-004 | T007, T009 |
| NFR-001 | T007 |
| NFR-002 | T005, T007 |

---

## Dependencies & Execution Order

### Phase Dependencies

1. **Setup (Phase 1)**: Tạo migration SQL.
2. **Foundational (Phase 2)**: Tạo Models, Repositories, Services và DI.
3. **User Story 1 (Phase 3)**: Gắn `MarketService` vào `SessionWorker` & `MarketHub`.
4. **User Story 2 (Phase 4)**: Thêm `MarketController`.
5. **Polish (Final Phase)**: Kiểm tra tài liệu & smoke test.

### Parallel Opportunities

- Tasks T002, T003, T004, T006 trong Phase 2 có thể thực hiện song song vì khác file.
- Task T012 (Unit Test) và T014 (Integration Test) có thể thực hiện song song với các task khác.
- Task T015, T016 trong Polish phase có thể chạy song song.

---

## Implementation Strategy

### MVP Scope (Chỉ User Story 1)
1. Hoàn thành Phase 1 & Phase 2.
2. Hoàn thành Phase 3 (US1: `SessionWorker` đọc CSDL).
3. Validate độc lập việc khởi tạo phiên giao dịch từ CSDL.
