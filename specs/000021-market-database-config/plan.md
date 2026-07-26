# Kế hoạch triển khai: Chuyển cấu hình danh sách market và schedule từ hardcode JSON sang CSDL

**Branch**: `000021-market-database-config` | **Ngày**: 2026-07-26 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng từ `/specs/000021-market-database-config/spec.md`

---

## Tóm tắt

**Yêu cầu chính từ spec**:
- Chuyển việc quản lý danh sách thị trường (`Markets`) và cấu hình thời lượng phiên (`MarketSchedules`) từ `appsettings.json` sang bảng CSDL PostgreSQL.
- Quản lý gộp thuộc tính thông tin thị trường và tham số phiên trong 1 bảng duy nhất (`exchange_markets`).
- `flex-exchange-service` đọc danh sách thị trường active & lịch trình phiên từ CSDL để vận hành vòng lặp `SessionWorker`.
- Cung cấp API `GET /api/v1/markets` trả về danh sách thị trường động.

**Hướng tiếp cận kỹ thuật dự kiến**:
- Tạo migration script `V5.1__create_table_exchange_markets.sql` trong `flex-database`.
- Xây dựng `MarketRepository` và `MarketService` trong `flex-exchange-service` với `IMemoryCache`.
- Cập nhật `SessionWorker` để tải thị trường từ CSDL thay cho `TradingSessionOptions`.
- Thêm `MarketController` xử lý HTTP Request `GET /api/v1/markets`.

**Kết quả sau research**:
- [DEC-001]: Gộp thuộc tính thị trường và cấu hình phiên vào bảng `exchange_markets`.
- [DEC-002]: Sử dụng `IMemoryCache` bọc ngoài `MarketRepository` để tối ưu độ trễ cho vòng lặp phiên.
- [DEC-003]: Hỗ trợ cơ chế Fallback về `appsettings.json` trong trường hợp ngắt kết nối CSDL khi bootup.

---

## Phạm vi kỹ thuật

**Trong phạm vi**:
- `flex-database`: Migration script tạo bảng `exchange_markets` và seed data 4 thị trường (`HOSE`, `HNX`, `UPCOM`, `DERIVATIVES`).
- `flex-exchange-service`:
  - Interface `IMarketRepository` & class `MarketRepository` (Dapper/Npgsql).
  - Class `MarketService` (MemoryCache wrapper).
  - Cập nhật `SessionWorker` & `TradingSessionService`.
  - Endpoint `MarketController` (`GET /api/v1/markets`, `GET /api/v1/markets/{code}`).

**Ngoài phạm vi kỹ thuật**:
- Giao diện Admin Portal Web cho việc thêm/sửa/xóa thị trường (trong MVP quản lý qua SQL/API direct).

---

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: C# 12 / .NET 9.0  
**Service/App liên quan**: `flex-exchange-service`, `flex-database`  
**Phụ thuộc chính**: `Dapper`, `Npgsql`, `Microsoft.Extensions.Caching.Memory`  
**Lưu trữ**: PostgreSQL (`securities` database)  
**Kiểm thử**: xUnit, Integration Test, Manual API Test  
**Nền tảng chạy**: Windows / Linux Docker container  
**Đơn vị deploy**: `flex-exchange-service` (.NET Web API service), `flex-database` (DB Migration)  
**Loại project**: web-service & database migration  
**Mục tiêu hiệu năng**: Đọc danh sách market & schedule từ In-Memory Cache với latency < 1ms  

---

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Đơn giản là ưu tiên | Pass | Pass | Gộp 1 bảng duy nhất, dùng MemoryCache thay vì Redis cầu kỳ |
| Thay đổi phẫu thuật | Pass | Pass | Chỉ điều chỉnh `SessionWorker`, `ServiceExtensions` và bổ sung Controller mới |
| Bảo tồn hợp đồng API | Pass | Pass | Endpoint mới `GET /api/v1/markets` không ảnh hưởng API cũ |

---

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Cần cấu hình các trường dữ liệu nào trong bảng `exchange_markets`? -> **ĐÃ GIẢI QUYẾT** (Xem [research.md](research.md)).
- **TQ-002**: Có cần In-Memory Caching không? -> **ĐÃ GIẢI QUYẾT** (Dùng `IMemoryCache` để giảm tải DB cho vòng lặp `SessionWorker`).

---

## Thiết kế tổng quan

**Luồng chính**:
1. `flex-database` chạy migration `V5.1__create_table_exchange_markets.sql` tạo bảng `exchange_markets` và chèn seed data.
2. Khi `flex-exchange-service` khởi động, `SessionWorker` gọi `IMarketService.GetActiveMarketsAsync()`.
3. `MarketService` kiểm tra `IMemoryCache`. Nếu trống, gọi `MarketRepository` lấy dữ liệu từ PostgreSQL bảng `exchange_markets` và lưu vào Cache.
4. `SessionWorker` lặp qua từng thị trường active, đọc lịch phiên từ entity và tạo vòng lặp chạy phiên cho từng thị trường.
5. Khi người dùng gọi `GET /api/v1/markets`, `MarketController` gọi `MarketService` trả về danh sách thị trường.

**Component/module tham gia**:
- `flex-database/securities/migrations`: Tạo schema CSDL.
- `Flex.Exchange.Api/Repositories/MarketRepository.cs`: Truy vấn PostgreSQL bằng Dapper.
- `Flex.Exchange.Api/Services/MarketService.cs`: Cache & Logic xử lý.
- `Flex.Exchange.Api/HostedServices/SessionWorker.cs`: Chạy phiên theo thị trường động từ DB.
- `Flex.Exchange.Api/Controllers/MarketController.cs`: Endpoint HTTP.

---

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Tạo bảng `exchange_markets` gộp market + schedule | `flex-database/securities/migrations` | N/A | `exchange_markets` | SQL Migration Test |
| US-001 / FR-002 | P1 | Đủ rõ | Cập nhật `SessionWorker` đọc từ `IMarketService` | `Flex.Exchange.Api/HostedServices/SessionWorker.cs` | N/A | `MarketEntity` | Integration Test |
| US-001 / FR-003 | P1 | Đủ rõ | Đọc chỉ thị trường có `status = 'active'` | `Flex.Exchange.Api/Repositories/MarketRepository.cs` | N/A | `exchange_markets` | Unit Test |
| US-002 / FR-004 | P2 | Đủ rõ | Thêm endpoint `GET /api/v1/markets` | `Flex.Exchange.Api/Controllers/MarketController.cs` | `GET /api/v1/markets` | `MarketView` | API Integration Test |
| FR-005 | P1 | Đủ rõ | Không tách bảng `market_schedules` riêng | `flex-database/securities/migrations` | N/A | `exchange_markets` | Code Review |

---

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Bổ sung bảng `exchange_markets` | Không ảnh hưởng các bảng hiện có | Chạy SQL script trên DB dev |
| API/Contract | Thêm `MarketController` | Tương thích ngược 100% | Swagger / Postman check |
| SessionWorker | Đọc danh sách thị trường động | Nếu DB ngắt kết nối, fallback về config appsettings | Tắt DB và test bootup |

---

## API/Contract Detail

**Có thay đổi contract không**: Có (bổ sung API mới)

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `GET /api/v1/markets` | REST API | Thêm endpoint mới | Có | Microfrontend / API Gateway |
| `GET /api/v1/markets/{code}` | REST API | Thêm endpoint chi tiết | Có | Admin / Microfrontend |

---

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Có  
**Migration**: File SQL `V5.1__create_table_exchange_markets.sql`  
**Backfill/Cleanup**: Chèn sẵn 4 thị trường (`HOSE`, `HNX`, `UPCOM`, `DERIVATIVES`) qua `INSERT ... ON CONFLICT DO NOTHING`.  
**Tương thích dữ liệu cũ**: Giữ nguyên cấu hình trong `appsettings.json` làm fallback.

---

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| [DEC-001] | Gộp bảng `exchange_markets` | Đơn giản mô hình dữ liệu, tối ưu truy vấn | Tách 2 bảng `markets` & `schedules` | Phức tạp không cần thiết |
| [DEC-002] | `IMemoryCache` | Đơn giản, độ trễ <1ms, không tốn thêm infra | Redis Distributed Cache | Dư thừa cho bài toán đơn giản |

---

## Chiến lược kiểm thử

**Unit test**:
- Test `MarketService` trả về đúng danh sách thị trường từ Cache / Repository.
- Test `SessionWorker` xử lý chính xác danh sách thị trường active.

**Integration test**:
- Test `MarketRepository` truy vấn dữ liệu thật từ DB PostgreSQL.

**E2E/manual test**:
- Khởi động `flex-exchange-service` và kiểm tra log khởi động phiên tự động cho 4 thị trường.
- Gọi API `GET /api/v1/markets` xác minh dữ liệu JSON trả về.

---

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000021-market-database-config/
├── plan.md              # File này
├── research.md          # Output Phase 0
├── data-model.md        # Output Phase 1
├── quickstart.md        # Output Phase 1
└── contracts/           # Output Phase 1
    └── exchange-api-contracts.md
```

### Source code (repository root)

```text
flex-database/
└── hnx/
    └── changelog/
        ├── db.changelog-master.xml
        └── releases/
            └── 1.0.0.1/
                ├── changelog.xml
                └── 001-create-exchange-markets.sql

flex-exchange-service/
└── src/
    └── Flex.Exchange.Api/
        ├── Controllers/
        │   └── MarketController.cs
        ├── Models/
        │   ├── MarketEntity.cs
        │   └── MarketView.cs
        ├── Repositories/
        │   ├── IMarketRepository.cs
        │   └── MarketRepository.cs
        ├── Services/
        │   ├── IMarketService.cs
        │   └── MarketService.cs
        └── HostedServices/
            └── SessionWorker.cs
```

---

## Observability & Debug

**Log cần có**:
- Log danh sách thị trường được nạp khi `SessionWorker` khởi chạy: `Loaded {Count} active markets from database/cache: {Markets}`.
- Log khi fallback về config: `Failed to load markets from DB. Falling back to appsettings configuration.`

---

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Các câu hỏi kỹ thuật đã được resolve trong `research.md`.
- [x] Thiết kế tổng quan đã mô tả luồng chính và component tham gia.
- [x] Mapping từ Spec sang Kỹ thuật đã đầy đủ.
- [x] Phân tích tác động đến CSDL và API contract đã rõ.
- [x] Dữ liệu & Migration script đã được định nghĩa.
- [x] Cấu trúc project sử dụng các đường dẫn thực tế trong repo.
- [x] Đã sẵn sàng cho việc sinh danh sách công việc (`/speckit-tasks`).
