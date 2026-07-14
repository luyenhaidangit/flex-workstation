# Kế hoạch triển khai: Lõi khớp lệnh và order book (FlexSim MVP 01)

**Branch**: `000010-matching-engine-core` | **Ngày**: 2026-07-14 (cập nhật lần 2 — điều chỉnh phạm vi stakeholder) | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng từ `/specs/000010-matching-engine-core/spec.md`

**Ghi chú**: Template này được điền bởi lệnh `/speckit-plan`. Xem `.specify/templates/plan-template.md` để biết workflow tạo kế hoạch.

## Tóm tắt

**Yêu cầu chính từ spec**: Service Exchange hoàn chỉnh theo chuẩn service Flex: lõi khớp lệnh limit mua/bán một mã FXS, phiên `continuous`, ưu tiên giá — thời gian (FR-002/003), khớp một phần (FR-004), giá khớp theo lệnh chờ (FR-005), hủy lệnh (FR-006), 4 sự kiện + snapshot (FR-007/008), kết quả xác định (FR-009), API đặt/hủy/truy vấn (FR-011); không database/UI/WebSocket/bot/số dư và lõi khớp độc lập với API (FR-010). Không có bộ test tự động (quyết định stakeholder — MVP-005).

**Hướng tiếp cận kỹ thuật dự kiến**: Dựng `flex-exchange-service` theo đúng pattern `flex-auth-service`: .NET 9, solution 3 project `src/Flex.Exchange` (ASP.NET Core Web API host) + `src/Flex.Domain` (engine khớp lệnh thuần) + `src/Flex.Infrastructures` (hạ tầng cross-cutting: logging, exception, observability, OpenAPI, response). Engine là pure logic trong `Flex.Domain`; API là lớp giao tiếp mỏng; kiểm chứng bằng file `.http` + Swagger theo kịch bản demo.

**Kết quả sau research**: Đã chốt trong [research.md](research.md): lấy đúng 3 project như auth nhưng `Flex.Infrastructures` chỉ gồm các thành phần dùng ngay (Logging/Serilog, Exceptions, Observability, OpenApi, Json, Responses — bỏ EF/Oracle, RabbitMQ, JWT, RateLimiting, Resilience); giá/khối lượng `long`; ưu tiên thời gian theo sequence number; truy cập engine được tuần tự hóa bằng lock ở lớp service; config FXS bind từ `appsettings.json`.

## Phạm vi kỹ thuật

**Trong phạm vi**:
- Repo `flex-exchange-service`: solution `Flex.Exchange.sln` với `src/Flex.Exchange` (Web API host: controllers, services, models, extensions, appsettings, launchSettings, file `.http` demo), `src/Flex.Domain` (entities, enums, events, commands, engine), `src/Flex.Infrastructures` (Logging, Exceptions, Observability, OpenApi, Json, Responses).
- File nền repo: `README.md` (cách chạy/demo), `CLAUDE.md` (context agent), `.gitignore`, `.gitattributes`, `.env.example` — theo pattern auth service.

**Ngoài phạm vi kỹ thuật**:
- Bộ test tự động (unit/integration) — bỏ theo quyết định stakeholder (EX-001 bên dưới).
- Persistence (EF Core/Oracle), messaging (RabbitMQ/outbox-inbox), xác thực JWT, rate limiting, resilience — các module infra này của auth chưa có nhu cầu; thêm ở MVP sau khi nghiệp vụ cần.
- Dockerfile, Jenkinsfile, CI/CD — chưa deploy ở MVP 01.
- WebSocket/sự kiện đẩy realtime (MVP 02); bảng điện UI (MVP 03).
- Mọi thay đổi ngoài repo `flex-exchange-service` và artifact Speckit của feature này.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: C# / .NET 9 (`net9.0`) — đồng bộ `flex-auth-service`.

**Service/App liên quan**: `flex-exchange-service` (repo mới, trống); pattern tham chiếu `flex-auth-service` (chỉ đọc, không sửa).

**Phụ thuộc chính**: ASP.NET Core (host), Serilog.AspNetCore + Serilog sinks (logging), Swashbuckle.AspNetCore (Swagger) — cùng bộ package auth đang dùng, chỉ lấy phần cần. `Flex.Domain` không tham chiếu package runtime nào (engine thuần BCL).

**Lưu trữ**: Không áp dụng — trạng thái in-memory trong tiến trình service, mất khi restart (đúng spec §Ngoài phạm vi).

**Kiểm thử**: Không có test tự động (EX-001). Kiểm chứng thủ công qua `Flex.Exchange.http` (bộ kịch bản chuẩn hóa 6 nhóm hành vi) + Swagger UI; quy trình trong [quickstart.md](quickstart.md).

**Nền tảng chạy**: Kestrel self-host cục bộ trên máy dev (`dotnet run`), Windows/Linux đều được.

**Đơn vị deploy**: Không áp dụng — chưa deploy; chạy cục bộ phục vụ demo.

**Loại project**: web-service (API host) + domain library + infrastructure library.

**Mục tiêu hiệu năng**: Toàn bộ kịch bản demo hoàn tất trong vài giây (NFR-002); không có mục tiêu throughput.

**Ràng buộc**: Tính xác định tuyệt đối (FR-009/NFR-001): không đồng hồ hệ thống trong logic khớp, không random, xử lý lệnh tuần tự (BR-005) — kể cả khi request API đến đồng thời (spec §Rủi ro).

**Quy mô/Phạm vi**: 1 mã, 1 broker giả lập, hàng trăm lệnh mỗi kịch bản — quy mô demo.

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Phạm vi khớp MVP-001..005 (spec đã được stakeholder cập nhật 2026-07-14); code nằm trong sub-repo `flex-exchange-service` do người dùng chỉ định |
| Traceability Gate | Pass | Pass | Bảng traceability map FR-001..FR-011 sang module/path/cách kiểm chứng |
| Test Gate | Fail → Ngoại lệ | Ngoại lệ Approved | Không có test tự động theo quyết định stakeholder — xem EX-001 tại "Theo dõi độ phức tạp"; thay bằng bộ kịch bản kiểm tra chuẩn hóa qua `.http` (SC-003) |
| Security Gate | Pass | Pass | API chỉ demo cục bộ, không deploy công khai (SEC-002); không dữ liệu nhạy cảm; `BrokerId` trên mọi lệnh/sự kiện (SEC-001); không hardcode secret |
| Compatibility Gate | Không áp dụng | Không áp dụng | Repo mới, chưa có consumer; contract thiết kế cho MVP 02 tái dùng (SC-004) |
| Observability Gate | Pass | Pass | Serilog + correlation ID + global logging middleware theo pattern auth; dòng sự kiện engine là audit nghiệp vụ; endpoint truy vấn event log |
| Complexity Gate | Pass | Pass | Lấy đúng pattern auth nhưng chỉ các module infra dùng ngay; không repository/DB layer khi không có DB (DEC-008) |
| Release Gate | Không áp dụng | Không áp dụng | Không release/deploy; hoàn thành = demo + kịch bản kiểm tra đạt trên máy dev |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Migration/backfill? → Không (không có DB).
- **TQ-002**: Layout solution theo pattern auth — thành phần nào của `Flex.Infrastructures` lấy vào MVP 01, engine đặt ở đâu, API host tổ chức thế nào? → Đã resolve (DEC-001, DEC-002, DEC-008).
- **TQ-003**: Contract backward compatibility? → Chưa có consumer; REST contract + engine contract thiết kế đủ cho MVP 02 (DEC-005).
- **TQ-004**: Biểu diễn giá/khối lượng và cơ chế bảo đảm tính xác định khi có API đồng thời? → Đã resolve (DEC-003, DEC-004, DEC-009).
- **TQ-005**: Chiến lược kiểm chứng khi không có test tự động? → Đã resolve (DEC-006).
- **TQ-006**: Giá trị mặc định config FXS và cách nạp config? → Đã resolve (DEC-007).

## Thiết kế tổng quan

**Luồng chính**:
1. `DemoBroker` (dev dùng Swagger UI hoặc `Flex.Exchange.http`) gọi `POST /api/orders` (đặt lệnh) / `DELETE /api/orders/{orderId}` (hủy) / `GET /api/orderbook` / `GET /api/events`.
2. Controller nhận request model, chuyển cho `ExchangeService` (singleton, DI) — lớp application service duy nhất giữ `MatchingEngine`.
3. `ExchangeService` tuần tự hóa mọi thao tác ghi bằng lock (BR-005) rồi gọi engine: validate theo `InstrumentConfig` (từ `appsettings.json`, options pattern) → `OrderRejected`/`OrderAccepted` → khớp theo ưu tiên giá — thời gian → `TradeExecuted`* → phần dư vào sổ.
4. Kết quả (accepted/rejected + danh sách sự kiện) trả về qua response wrapper chuẩn (`Flex.Infrastructures/Responses`), đồng thời sự kiện nằm trong event log truy vấn được qua `GET /api/events`.
5. Middleware hạ tầng (theo pattern auth): correlation ID, global request/response logging (Serilog), global exception handler; Swagger bật ở môi trường Development.

**Component/module tham gia**:
- `src/Flex.Domain`: engine thuần — entities (`Order`, `OrderBook`, `Trade`, `InstrumentConfig`), enums, commands, events, `Matching/MatchingEngine.cs`, `Matching/OrderValidator.cs`. Không phụ thuộc ASP.NET/package ngoài.
- `src/Flex.Exchange` (Web API host): `Controllers/OrdersController.cs`, `Controllers/OrderBookController.cs`, `Controllers/EventsController.cs`; `Services/ExchangeService.cs` (+ interface); `Models/` request/response; `Extensions/HostExtensions.cs`, `ServiceExtensions.cs`, `ApplicationExtensions.cs` (mirror auth); `Program.cs`; `appsettings*.json`; `Flex.Exchange.http`.
- `src/Flex.Infrastructures`: `Logging/` (SeriLogger + options), `Exceptions/` (global handler + ValidationException), `Observability/` (CorrelationIdMiddleware, GlobalLoggingMiddleware, LogFields), `OpenApi/` (SwaggerConfiguration), `Json/` (JsonOptions), `Responses/` (API response wrapper), `AssemblyReference.cs`.

**Điểm mở rộng/thay đổi chính**:
- Repo trống → toàn bộ code mới, không đụng repo khác.
- Seam cho MVP 02: engine trả danh sách sự kiện — MVP 02 chỉ thêm publisher (WebSocket/MQ) tiêu thụ event log, không sửa engine; infra thêm module Messaging như auth khi đó.

**Luồng thay thế/lỗi chính**:
- Lệnh vi phạm FR-001 → HTTP 200 với body business-reject (`OrderRejected` + `RejectReason`) — từ chối nghiệp vụ không phải lỗi HTTP; request sai cấu trúc (thiếu trường, sai kiểu) → 400 qua model validation.
- Hủy lệnh không tồn tại/đã hoàn tất → business-reject `OrderNotFound` (AC-008), order book không đổi.
- Exception bất thường → global exception handler trả 500 chuẩn hóa, có correlation ID; engine mutate sổ chỉ sau khi command xử lý trọn vẹn nên không có trạng thái dở dang.

**Thay đổi boundary giữa service/module**:
- Boundary mới: API host ↔ engine qua `IExchangeService`; quy tắc khớp không được rò rỉ lên controller (FR-010).

**Idempotency/Concurrency**:
- Request API có thể đến đồng thời → `ExchangeService` serialize toàn bộ thao tác ghi (đặt/hủy) bằng lock quanh engine; thứ tự nhận lock = thứ tự vào sổ (`SequenceNumber`). Snapshot/event đọc cũng qua cùng cơ chế để nhất quán (quy mô demo — lock đơn là đủ, DEC-009).
- `PlaceOrder` không idempotent theo thiết kế (gửi lại = lệnh mới, spec §5); `CancelOrder` lặp lại → `OrderNotFound`, trạng thái không đổi.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-005 / FR-001 | P2 | Đủ rõ | `OrderValidator` kiểm tra tick/biên độ/lô/trường bắt buộc theo `InstrumentConfig` | `src/Flex.Domain/Matching/OrderValidator.cs` | `OrderRejected` + `RejectReason` | `InstrumentConfig` | Kịch bản `.http` nhóm validate (AC-009) |
| US-001, US-003 / FR-002 | P1 | Đủ rõ | Sổ hai bên sort theo giá (mua giảm, bán tăng); khớp từ mức giá tốt nhất đối ứng | `src/Flex.Domain/Matching/MatchingEngine.cs`, `Entities/OrderBook.cs` | `TradeExecuted` | `OrderBook`, `Order` | Kịch bản `.http` AC-001, AC-005 |
| US-003 / FR-003 | P1 | Đủ rõ | FIFO theo `SequenceNumber` trong cùng mức giá | `src/Flex.Domain/Entities/OrderBook.cs` | Không áp dụng | `Order.SequenceNumber` | Kịch bản `.http` AC-006 |
| US-002 / FR-004 | P1 | Đủ rõ | `RemainingQuantity` giảm dần; >0 nằm lại sổ | `src/Flex.Domain/Matching/MatchingEngine.cs` | `TradeExecuted`, snapshot | `Order` (`PartiallyFilled`) | Kịch bản `.http` AC-003/004 |
| US-001..003 / FR-005 | P1 | Đủ rõ | Giá khớp lấy từ lệnh chờ (passive) | `src/Flex.Domain/Matching/MatchingEngine.cs` | `TradeExecuted.Price` | `Trade` | Kịch bản `.http` AC-005 (mua 20.000 khớp 19.900) |
| US-004 / FR-006 | P1 | Đủ rõ | Hủy theo `OrderId`: còn dư → gỡ + `OrderCancelled`; không còn → `OrderNotFound` | `src/Flex.Domain/Matching/MatchingEngine.cs` | `DELETE /api/orders/{orderId}` | `Order` (`Cancelled`) | Kịch bản `.http` AC-007/008 |
| US-001, US-002 / FR-007 | P1 | Đủ rõ | `TradeExecuted` đủ trường đối chiếu | `src/Flex.Domain/Events/TradeExecuted.cs` | Event schema trong contract | `Trade` | Soi payload `GET /api/events` |
| US-001, US-002, US-004 / FR-008 | P1 | Đủ rõ | Snapshot hai bên theo mức giá + FIFO | `src/Flex.Domain/Entities/OrderBookSnapshot.cs` | `GET /api/orderbook` | `OrderBookSnapshot` | Kịch bản `.http` AC-002/004/007 |
| FR-009 | P1 | Đủ rõ | Không đồng hồ/random trong logic; sequence tuần tự; lock tuần tự hóa | `src/Flex.Domain` + `src/Flex.Exchange/Services/ExchangeService.cs` | Guarantee trong contract | Event log | Chạy lại kịch bản sau restart, so sánh `GET /api/events` (SC-002) |
| FR-010 | P1 | Đủ rõ | Engine không tham chiếu ASP.NET/package; controller không chứa quy tắc khớp | `src/Flex.Domain/Flex.Domain.csproj` | Không áp dụng | Không áp dụng | Review csproj + review controller mỏng |
| FR-011 | P1 | Đủ rõ | REST API đặt/hủy/truy vấn qua controllers + `ExchangeService` | `src/Flex.Exchange/Controllers/*`, `Services/ExchangeService.cs` | [contracts/exchange-core.md](contracts/exchange-core.md) | Request/response models | Toàn bộ kịch bản `.http` + Swagger |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không áp dụng — không có DB | Không áp dụng | Không áp dụng |
| API/Contract | REST API mới (orders/orderbook/events) + engine contract in-process | Không có consumer hiện hữu; rủi ro thiếu trường cho MVP 02 | Review contract theo "Đầu ra cho MVP 02" của tài liệu MVP |
| Permission/Security | API không xác thực, chỉ demo cục bộ | Rủi ro nếu deploy công khai — bị cấm bởi SEC-002 | Review: không có cấu hình expose ngoài localhost trong launchSettings |
| Logging/Audit | Serilog + correlation ID + global logging middleware; event log engine là audit nghiệp vụ | Thiếu truy vết nếu sự kiện thiếu trường | Soi log console + `GET /api/events` |
| UI/UX | Không áp dụng — Swagger UI là bề mặt demo duy nhất | Không áp dụng | Mở Swagger, chạy kịch bản |
| Job/Worker/Integration | Không áp dụng — không async/integration | Không áp dụng | Không áp dụng |

## API/Contract Detail

**Có thay đổi contract không**: Có — tạo mới REST API + contract in-process (chưa có consumer bên ngoài).

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `POST /api/orders` (đặt lệnh), `DELETE /api/orders/{orderId}` (hủy) | REST API | Tạo mới | Không áp dụng (mới) | `.http`/Swagger demo; MVP 02 mở rộng |
| `GET /api/orderbook` (snapshot), `GET /api/events` (event log) | REST API | Tạo mới | Không áp dụng (mới) | `.http`/Swagger demo; MVP 03 bảng điện (tương lai) |
| `MatchingEngine` commands/events/snapshot | In-process API | Tạo mới | Không áp dụng (mới) | `ExchangeService`; MVP 02 publisher (tương lai) |

Chi tiết schema: [contracts/exchange-core.md](contracts/exchange-core.md).

## Permission Matrix

Không áp dụng — một `DemoBroker`, API demo cục bộ không xác thực (spec §Phân quyền); `BrokerId` trên lệnh/sự kiện làm nền cho đa broker MVP 06.

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng — trạng thái in-memory, mất khi restart service (đúng spec §Ngoài phạm vi).

**Migration**: Không áp dụng.

**Backfill/Cleanup**: Không áp dụng.

**Tương thích dữ liệu cũ**: Không áp dụng.

**Rủi ro dữ liệu**: Không áp dụng.

**Cách xác minh**: Không áp dụng.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Solution 3 project đúng pattern auth: `src/Flex.Exchange` (Web API host) + `src/Flex.Domain` + `src/Flex.Infrastructures` | Yêu cầu stakeholder: service hoàn chỉnh theo chuẩn Flex, đồng nhất cấu trúc giữa các service, MVP sau không phải tái cấu trúc | Console demo không API (plan v1) | Stakeholder đổi phạm vi 2026-07-14: cần API + hạ tầng ngay MVP 01 |
| DEC-002 | Engine khớp lệnh trong `Flex.Domain`; API host chỉ có `ExchangeService` mỏng + controllers | Engine thuần logic, tách khỏi API (FR-010); MVP 02 thêm publisher không sửa engine | Đặt engine trong `Services/` của host như auth | Logic auth gắn HTTP/DB nên ở host hợp lý; engine ở đây là domain thuần |
| DEC-003 | Giá/khối lượng dùng `long` (VND nguyên, cổ phiếu nguyên) | Số học nguyên tuyệt đối xác định (FR-009); giá VN không lẻ dưới đồng | `decimal` | Không cần độ chính xác thập phân; kiểm tra tick/lô bằng modulo nguyên đơn giản hơn |
| DEC-004 | Ưu tiên thời gian theo `SequenceNumber` engine cấp; timestamp chỉ hiển thị | Loại bỏ phụ thuộc đồng hồ — nguồn phi xác định chính (NFR-001) | `DateTime.UtcNow` làm khóa ưu tiên | Trùng timestamp là thực tế; kết quả phụ thuộc máy chạy |
| DEC-005 | Engine expose API đồng bộ (command in → events out + snapshot); REST controller bọc 1-1, business-reject trả HTTP 200 với body reject | Đơn giản, tái lập; phân biệt rõ lỗi nghiệp vụ (200 + reason) và lỗi request (400)/hệ thống (500) | Event bus nội bộ; map reject sang 4xx | Indirection thừa; reject nghiệp vụ không phải lỗi giao thức, MVP 02 cần nguyên payload sự kiện |
| DEC-006 | Kiểm chứng bằng `Flex.Exchange.http` (bộ kịch bản chuẩn hóa, commit vào repo) + Swagger; không test tự động | Quyết định stakeholder (EX-001); `.http` là pattern auth đã có (`Flex.Auth.http`), lặp lại được và làm tài liệu sống | Bộ xUnit test (plan v1) | Stakeholder bỏ yêu cầu test tự động để tập trung dựng skeleton |
| DEC-007 | Config FXS bind từ `appsettings.json` section `Exchange:Instrument` (options pattern như auth): tham chiếu 20.000, tick 100, trần 21.400/sàn 18.600 (±7%), lô 100 | Đúng NFR-003 (đổi config không sửa code), đúng pattern options của auth (`{Feature}Options`) | Hardcode trong code | Vi phạm NFR-003 |
| DEC-008 | `Flex.Infrastructures` chỉ gồm Logging, Exceptions, Observability, OpenApi, Json, Responses | Đây là các module auth đang dùng mà exchange cần ngay (log/debug/swagger/response chuẩn); giữ namespace + cấu trúc thư mục giống auth để MVP sau thêm Messaging/Persistence đúng chỗ | Copy đủ 16 module infra của auth | EF/Oracle, RabbitMQ, JWT, RateLimiting, Resilience, Random... không có nhu cầu → project phình to, vi phạm nguyên tắc V |
| DEC-009 | `ExchangeService` singleton, serialize thao tác ghi bằng `lock` quanh engine | Bảo toàn BR-005/FR-009 khi request API đồng thời; quy mô demo không cần queue/channel | `System.Threading.Channels` + background processor | Phức tạp hơn đáng kể, chỉ cần khi có yêu cầu throughput — chưa phải MVP 01 |

## Chiến lược kiểm thử

**Unit test**: Không áp dụng — bỏ theo quyết định stakeholder (EX-001). Lõi khớp tách biệt trong `Flex.Domain` để có thể bổ sung test sau mà không refactor.

**Integration test**: Không áp dụng — như trên.

**Contract test**: Không áp dụng ở MVP 01; contract REST được mô tả trong [contracts/exchange-core.md](contracts/exchange-core.md) và Swagger là nguồn đối chiếu khi MVP 02 mở rộng.

**Permission/security test**: Không áp dụng — không có mô hình quyền; kiểm tra thủ công service chỉ bind localhost (SEC-002).

**E2E/manual test** (cơ chế kiểm chứng chính — SC-001/002/003): Bộ kịch bản chuẩn hóa trong `Flex.Exchange.http` commit vào repo, bao phủ 8 nhóm: (1) không khớp, (2) khớp toàn phần AC-001/002, (3) khớp một phần AC-003/004, (4) ưu tiên giá AC-005 + khớp xuyên mức giá, (5) ưu tiên thời gian AC-006, (6) hủy lệnh AC-007/008 + hủy lặp, (7) validate AC-009 từng ràng buộc, (8) determinism — restart service, chạy lại kịch bản, so sánh `GET /api/events`. Quy trình chi tiết trong [quickstart.md](quickstart.md).

**Regression test**: Không áp dụng — repo mới; rủi ro regression tương lai đã ghi ở spec §Rủi ro và được stakeholder chấp nhận.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000010-matching-engine-core/
├── plan.md              # File này (output của lệnh /speckit-plan)
├── research.md          # Output Phase 0 (lệnh /speckit-plan)
├── data-model.md        # Output Phase 1 (lệnh /speckit-plan)
├── quickstart.md        # Output Phase 1 (lệnh /speckit-plan)
├── contracts/
│   └── exchange-core.md # Output Phase 1 (lệnh /speckit-plan)
└── tasks.md             # Output Phase 2 (lệnh /speckit-tasks - KHÔNG tạo bởi /speckit-plan)
```

### Source code (repository root: `flex-exchange-service/`)

```text
flex-exchange-service/
├── Flex.Exchange.sln
├── README.md                          # Mô tả service + cách chạy demo
├── CLAUDE.md                          # Context cho agent trong repo con
├── .gitignore                         # .NET, theo pattern flex-auth-service
├── .gitattributes
├── .env.example                       # Placeholder biến môi trường (theo pattern auth)
├── src/
│   ├── Flex.Exchange/                 # ASP.NET Core Web API host (mirror src/Flex.Auth)
│   │   ├── Flex.Exchange.csproj       # net9.0; ref Flex.Domain + Flex.Infrastructures
│   │   ├── Program.cs                 # Bootstrap qua HostExtensions (như auth)
│   │   ├── Flex.Exchange.http         # Bộ kịch bản demo/kiểm tra chuẩn hóa (SC-003)
│   │   ├── appsettings.json           # Serilog + Exchange:Instrument (config FXS)
│   │   ├── appsettings.Development.json
│   │   ├── Properties/launchSettings.json  # HTTP/HTTPS port cục bộ
│   │   ├── Controllers/
│   │   │   ├── OrdersController.cs    # POST /api/orders, DELETE /api/orders/{orderId}
│   │   │   ├── OrderBookController.cs # GET /api/orderbook
│   │   │   └── EventsController.cs    # GET /api/events
│   │   ├── Services/
│   │   │   ├── Interfaces/IExchangeService.cs
│   │   │   └── ExchangeService.cs     # Singleton giữ MatchingEngine, lock tuần tự hóa
│   │   ├── Models/
│   │   │   ├── PlaceOrderRequest.cs
│   │   │   ├── PlaceOrderResponse.cs
│   │   │   ├── CancelOrderResponse.cs
│   │   │   └── ExchangeOptions.cs     # Bind Exchange:Instrument → InstrumentConfig
│   │   └── Extensions/
│   │       ├── HostExtensions.cs      # Cấu hình host/logging (mirror auth)
│   │       ├── ServiceExtensions.cs   # DI: ExchangeService, options, swagger
│   │       └── ApplicationExtensions.cs # Pipeline: middleware, swagger, routing
│   ├── Flex.Domain/                   # Engine thuần, 0 package runtime
│   │   ├── Flex.Domain.csproj
│   │   ├── Entities/{Order, OrderBook, OrderBookSnapshot, Trade, InstrumentConfig}.cs
│   │   ├── Enums/{OrderSide, OrderStatus, RejectReason}.cs
│   │   ├── Events/{ExchangeEvent, OrderAccepted, OrderRejected, TradeExecuted, OrderCancelled}.cs
│   │   ├── Commands/{PlaceOrder, CancelOrder}.cs
│   │   └── Matching/{MatchingEngine, OrderValidator}.cs
│   └── Flex.Infrastructures/          # Subset module auth đang dùng (DEC-008)
│       ├── Flex.Infrastructures.csproj # Serilog.AspNetCore, Swashbuckle
│       ├── AssemblyReference.cs
│       ├── Logging/SeriLogger.cs      # + options như auth
│       ├── Exceptions/                # Global exception handler, ValidationException
│       ├── Observability/             # CorrelationIdMiddleware, GlobalLoggingMiddleware, LogFields
│       ├── OpenApi/SwaggerConfiguration.cs
│       ├── Json/JsonOptions.cs
│       └── Responses/                 # API response wrapper chuẩn
└── (không có tests/ — EX-001)
```

**Quyết định cấu trúc**: Mirror 1-1 cấu trúc `flex-auth-service` (host + Domain + Infrastructures, cùng naming convention); `Flex.Infrastructures` chỉ chứa module có nhu cầu ngay (DEC-008); không thư mục `Repositories`/`Persistence` vì không có DB; không `tests/` (EX-001).

## Rollout & Rollback

**Kế hoạch rollout**: Không áp dụng — không deploy; hoàn thành = merge vào `main` của `flex-exchange-service` với bộ kịch bản `.http` đạt và demo chạy đúng trên máy dev.

**Tương thích ngược**: Không áp dụng — repo mới, chưa có consumer.

**Feature flag/config**: `Exchange:Instrument` trong `appsettings.json` là điểm cấu hình nghiệp vụ duy nhất (NFR-003); không cần feature flag.

**Thực thi migration/backfill khi rollout**: Không áp dụng.

**Rollback code/config**: Revert commit/PR trên `flex-exchange-service` — không có state ngoài code.

**Rollback dữ liệu/migration**: Không áp dụng.

**Điều kiện kích hoạt rollback**: Không áp dụng.

## Observability & Debug

**Log cần có** (theo pattern auth: Serilog + middleware):
- Request/response log qua `GlobalLoggingMiddleware`: method, path, status, duration, correlationId.
- Log nghiệp vụ từ `ExchangeService`: command nhận (loại, BrokerId, symbol, side, price, quantity), kết quả (accepted/rejected + reason, số trade sinh ra).
- Dòng sự kiện engine (truy vấn `GET /api/events`): `EventSequence`, loại event, `OrderId`/`TradeId`, `BrokerId`, price/quantity — audit nghiệp vụ đầy đủ (spec §Audit).

**Dữ liệu không được log**: Không áp dụng — toàn bộ dữ liệu giả lập, không secret/PII; không đưa credential thật vào `appsettings.json` (repo public pattern).

**Metric cần theo dõi**: Không áp dụng ở MVP 01 (không deploy); đếm event/trade từ `GET /api/events` khi cần.

**Trace/Correlation**: `X-Correlation-Id` qua `CorrelationIdMiddleware` (pattern auth) cho lớp HTTP; `EventSequence` + `OrderId`/`TradeId` cho lớp nghiệp vụ — dựng lại toàn bộ diễn biến từ event log (FR-009).

**Cách kiểm tra sau release**: Chạy quy trình [quickstart.md](quickstart.md): build → run → Swagger mở được → bộ kịch bản `.http` đạt cả 8 nhóm.

**Tình huống debug chính**: Kết quả khớp sai kỳ vọng → phát lại đúng chuỗi lệnh (deterministic) và soi `GET /api/events` từng bước; kết quả không tái lập → tìm nguồn phi xác định trong `Flex.Domain/Matching` (DateTime/random/hash-order); lỗi 500 → tra correlationId trong log console.

## Theo dõi độ phức tạp

Ngoại lệ constitution (theo format constitution §10):

| ID | Nguyên tắc vi phạm | Lý do | Rủi ro | Người phê duyệt | Trạng thái | Hạn xử lý |
|----|--------------------|-------|--------|------------------|------------|-----------|
| EX-001 | Test Gate (constitution §7) — không có test tự động cho engine rủi ro cao | Stakeholder quyết định 2026-07-14: tập trung dựng service skeleton + API, bỏ unit test để rút ngắn phạm vi | Regression khó phát hiện khi MVP sau sửa engine; sai sót quy tắc khớp chỉ lộ qua kiểm tra thủ công | Luyện Hải Đăng | Approved | Xem lại khi bắt đầu MVP 02 (khuyến nghị bổ sung test cho engine trước khi mở rộng API) |

**Phương án đơn giản hơn đã xem xét**: giữ bộ xUnit tối thiểu cho 6 nhóm hành vi (plan v1) — bị loại theo chỉ đạo trực tiếp của stakeholder. Biện pháp giảm thiểu: engine tách biệt trong `Flex.Domain` (thêm test sau không cần refactor) + bộ kịch bản `.http` chuẩn hóa commit vào repo.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research hoặc ghi rủi ro rõ ràng.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary nếu có.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá hoặc ghi `Không áp dụng` (DEC-009).
- [x] Mỗi `US`/`FR` P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Các contract/API/event thay đổi đã có consumer bị ảnh hưởng và cách kiểm tra compatibility.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử đã bao phủ các lớp liên quan; việc bỏ test tự động có ngoại lệ EX-001 được phê duyệt.
- [x] Rollout, rollback code/config, rollback dữ liệu/migration, feature flag/config và backward compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật trong repository.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks` (Test Gate: ngoại lệ EX-001 Approved).
