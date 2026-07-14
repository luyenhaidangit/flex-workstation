# Kế hoạch triển khai: Lõi khớp lệnh và order book (FlexSim MVP 01)

**Branch**: `000010-matching-engine-core` | **Ngày**: 2026-07-14 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng từ `/specs/000010-matching-engine-core/spec.md`

**Ghi chú**: Template này được điền bởi lệnh `/speckit-plan`. Xem `.specify/templates/plan-template.md` để biết workflow tạo kế hoạch.

## Tóm tắt

**Yêu cầu chính từ spec**: Lõi khớp lệnh limit mua/bán cho một mã FXS, phiên `continuous`, ưu tiên giá — thời gian (FR-002, FR-003), khớp một phần (FR-004), giá khớp theo lệnh chờ (FR-005), hủy lệnh (FR-006), sự kiện `OrderAccepted`/`OrderRejected`/`TradeExecuted`/`OrderCancelled` + snapshot order book (FR-007, FR-008), kết quả xác định 100% (FR-009), không API/DB/UI/WebSocket/bot/số dư (FR-010).

**Hướng tiếp cận kỹ thuật dự kiến**: Dựng repo `flex-exchange-service` (hiện trống) theo pattern `flex-auth-service`: .NET 9, solution phân lớp `src/Flex.Exchange` (host) + `src/Flex.Domain` (domain). Toàn bộ engine khớp lệnh là pure in-process logic nằm trong `Flex.Domain`; host MVP 01 là console demo chạy kịch bản trong `docs/mvp/01-matching-rules.md`; bộ unit test xUnit bao phủ 6 nhóm hành vi bắt buộc.

**Kết quả sau research**: Đã chốt toàn bộ trong [research.md](research.md): bỏ `Flex.Infrastructures` ở MVP 01 (không có infra concern), giá/khối lượng dùng số nguyên `long` (VND/cổ phiếu), ưu tiên thời gian theo sequence number cấp khi nhận lệnh, test bằng xUnit, cấu hình FXS mặc định tick 100 — biên ±7% quanh tham chiếu 20.000 — lô 100.

## Phạm vi kỹ thuật

**Trong phạm vi**:
- Repo `flex-exchange-service` (sub-repo, đã khai báo trong `workstation.json`): tạo solution `Flex.Exchange.sln`, project `src/Flex.Domain` (entities, events, engine khớp lệnh, validator, order book), project `src/Flex.Exchange` (console demo host), project `tests/Flex.Exchange.UnitTests`.
- File nền repo theo pattern auth service: `.gitignore`, `.gitattributes`, `README.md`, `CLAUDE.md` (context cho agent khi làm việc trong repo con).

**Ngoài phạm vi kỹ thuật**:
- `Flex.Infrastructures` (EF Core, RabbitMQ, Serilog, JWT...) — chưa có nhu cầu ở MVP 01, sẽ thêm ở MVP 02 khi có API/hạ tầng.
- Dockerfile, Jenkinsfile, CI/CD — MVP 01 chạy cục bộ, chưa deploy.
- Mọi thay đổi trong `flex-workstation` ngoài artifact Speckit của feature này (`workstation.json` đã cập nhật xong ở bước specify).

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: C# / .NET 9 (`net9.0`) — đồng bộ với `flex-auth-service`.

**Service/App liên quan**: `flex-exchange-service` (repo mới, trống); tham chiếu pattern từ `flex-auth-service` (không sửa repo auth).

**Phụ thuộc chính**: Không có package runtime ngoài BCL — engine là pure logic. Test dùng xUnit + `Microsoft.NET.Test.Sdk`.

**Lưu trữ**: Không áp dụng — trạng thái in-memory, không persist (FR-010).

**Kiểm thử**: xUnit (unit test cho engine + test tính xác định); demo console đóng vai smoke test thủ công.

**Nền tảng chạy**: Console app chạy cục bộ trên máy dev (Windows/Linux đều được với .NET 9 SDK).

**Đơn vị deploy**: Không áp dụng — chưa deploy; đầu ra là library `Flex.Domain` + console demo.

**Loại project**: library (domain engine) + console demo + test project.

**Mục tiêu hiệu năng**: Bộ kịch bản demo và toàn bộ test chạy xong trong vài giây trên máy dev (NFR-002); không có mục tiêu throughput ở MVP 01.

**Ràng buộc**: Tính xác định tuyệt đối (FR-009/NFR-001): không phụ thuộc đồng hồ hệ thống, không random, không concurrency trong luồng khớp; xử lý lệnh tuần tự (BR-005).

**Quy mô/Phạm vi**: 1 mã cổ phiếu, 1 broker giả lập, hàng trăm lệnh mỗi kịch bản test — quy mô demo.

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Phạm vi kỹ thuật khớp MVP-001..004 và mục Ngoài phạm vi của spec; code sản phẩm nằm trong sub-repo `flex-exchange-service` do người dùng chỉ định (đúng Nguyên tắc I và ngoại lệ cho phép) |
| Traceability Gate | Pass | Pass | Bảng traceability bên dưới map đủ FR-001..FR-010 sang module/path/test |
| Test Gate | Pass | Pass | Chiến lược test bao phủ 6 nhóm hành vi bắt buộc (SC-003) + test tính xác định (SC-002) |
| Security Gate | Pass | Pass | Không mở bề mặt mạng (SEC-002), không dữ liệu nhạy cảm; `BrokerId` gắn trên mọi lệnh/sự kiện (SEC-001) |
| Compatibility Gate | Không áp dụng | Không áp dụng | Repo mới, chưa có consumer; contract in-process được thiết kế để MVP 02 tái dùng (SC-004) |
| Observability Gate | Pass | Pass | Dòng sự kiện có thứ tự là log nghiệp vụ đầy đủ; demo in sự kiện ra console; không cần metric/alert khi chưa deploy |
| Complexity Gate | Pass | Pass | Bỏ `Flex.Infrastructures`, không repository/DB layer, không abstraction thừa — chỉ 3 project tối thiểu |
| Release Gate | Không áp dụng | Không áp dụng | Không release/deploy ở MVP 01; điều kiện hoàn thành là test + demo chạy đúng |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Có cần migration/backfill không? → Đã resolve: Không (không có DB).
- **TQ-002**: Dựng layout solution theo pattern auth service như thế nào khi MVP 01 không có API/DB — có tạo `Flex.Infrastructures` không, engine đặt ở project nào? → Đã resolve trong research (DEC-001, DEC-002).
- **TQ-003**: Contract có cần backward compatibility không? → Đã resolve: chưa có consumer; contract in-process phải đủ cho MVP 02 (DEC-005).
- **TQ-004**: Biểu diễn giá/khối lượng và cơ chế bảo đảm tính xác định (thời gian, thứ tự)? → Đã resolve (DEC-003, DEC-004).
- **TQ-005**: Test framework? → Đã resolve: xUnit (DEC-006).
- **TQ-006**: Giá trị mặc định bước giá/biên độ/lô chẵn cho FXS? → Đã resolve (DEC-007).

## Thiết kế tổng quan

**Luồng chính**:
1. `DemoBroker` (console demo hoặc test) tạo lệnh `PlaceOrder`/`CancelOrder` và gọi engine `MatchingEngine` tuần tự.
2. Engine kiểm tra hợp lệ lệnh qua `OrderValidator` theo `InstrumentConfig` (tick/biên độ/lô chẵn) → phát `OrderRejected` (kèm mã lý do) hoặc `OrderAccepted`.
3. Lệnh hợp lệ được khớp ngay với sổ đối ứng trong `OrderBook`: lặp qua các lệnh chờ theo ưu tiên giá — thời gian, phát `TradeExecuted` cho mỗi lần khớp (giá theo lệnh chờ), phần dư vào sổ.
4. `CancelOrder` gỡ lệnh còn khối lượng chờ khỏi sổ → `OrderCancelled`; lệnh không còn trong sổ → từ chối hủy kèm lý do.
5. Mọi sự kiện được ghi vào dòng sự kiện có thứ tự (append-only, đánh số tuần tự); snapshot order book truy vấn được bất kỳ lúc nào.

**Component/module tham gia**:
- `src/Flex.Domain` (`Flex.Domain.csproj`): toàn bộ lõi — entities (`Order`, `Trade`, `OrderBook`, `InstrumentConfig`), events (4 loại + base), engine (`MatchingEngine`, `OrderValidator`), snapshot model.
- `src/Flex.Exchange` (`Flex.Exchange.csproj`, console): host demo — dựng `MatchingEngine` với config FXS, chạy 3 kịch bản demo của tài liệu MVP, in sự kiện và snapshot ra console.
- `tests/Flex.Exchange.UnitTests`: xUnit test cho 6 nhóm hành vi + determinism + validator.

**Điểm mở rộng/thay đổi chính**:
- Repo trống → toàn bộ là code mới; không đụng repo khác.
- `MatchingEngine` nhận command và trả về danh sách sự kiện — đây là seam để MVP 02 bọc API/WebSocket lên trên mà không sửa engine.

**Luồng thay thế/lỗi chính**:
- Lệnh không hợp lệ → `OrderRejected` với mã lý do (`InvalidTickSize`, `OutOfPriceBand`, `InvalidLotSize`, `InvalidQuantity`, `UnknownSymbol`...); order book không đổi.
- Hủy lệnh không tồn tại/đã hoàn tất/đã hủy → kết quả từ chối hủy kèm lý do; order book không đổi (AC-008).
- Exception bất thường trong lúc khớp: engine xử lý mỗi lệnh trọn vẹn (BR-005); command gây lỗi không để lại trạng thái dở dang (mutate sổ chỉ sau khi tính xong kết quả khớp, hoặc fail-fast trước khi mutate).

**Thay đổi boundary giữa service/module**:
- Không áp dụng — service mới độc lập, chưa tích hợp với service nào.

**Idempotency/Concurrency**:
- Engine xử lý tuần tự đơn luồng (single-threaded, BR-005); không có concurrency trong MVP 01.
- `PlaceOrder` không idempotent theo thiết kế: gửi lại lệnh giống hệt là lệnh mới (spec §5); `OrderId` do engine cấp tuần tự.
- `CancelOrder` lặp lại: lần sau bị từ chối vì lệnh không còn trong sổ — trạng thái cuối không đổi.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-005 / FR-001 | P2 | Đủ rõ | `OrderValidator` kiểm tra tick/biên độ/lô chẵn/trường bắt buộc theo `InstrumentConfig`, trả mã lý do từ chối | `src/Flex.Domain/Matching/OrderValidator.cs` | `OrderRejected` + `RejectReason` ([contract](contracts/exchange-core.md)) | `InstrumentConfig` | Unit: mỗi ràng buộc một nhóm case hợp lệ/vi phạm |
| US-001, US-003 / FR-002 | P1 | Đủ rõ | Sổ hai bên sort theo giá (mua giảm dần, bán tăng dần); lệnh vào khớp từ mức giá tốt nhất của bên đối ứng | `src/Flex.Domain/Matching/MatchingEngine.cs`, `src/Flex.Domain/Entities/OrderBook.cs` | `TradeExecuted` | `OrderBook`, `Order` | Unit: AC-001, AC-005; khớp xuyên nhiều mức giá |
| US-003 / FR-003 | P1 | Đủ rõ | Cùng mức giá xếp FIFO theo `SequenceNumber` cấp khi nhận lệnh | `src/Flex.Domain/Entities/OrderBook.cs` | Không áp dụng | `Order.SequenceNumber` | Unit: AC-006 |
| US-002 / FR-004 | P1 | Đủ rõ | `Order.RemainingQuantity` giảm dần theo từng lần khớp; >0 thì nằm lại sổ | `src/Flex.Domain/Matching/MatchingEngine.cs` | `TradeExecuted`, snapshot | `Order` (trạng thái `PartiallyFilled`) | Unit: AC-003, AC-004 |
| US-001..003 / FR-005 | P1 | Đủ rõ | Giá khớp lấy từ lệnh chờ (passive side), không lấy giá lệnh mới | `src/Flex.Domain/Matching/MatchingEngine.cs` | `TradeExecuted.Price` | `Trade` | Unit: AC-001, AC-005 (mua 20.000 khớp bán chờ 19.900 → giá 19.900) |
| US-004 / FR-006 | P1 | Đủ rõ | `CancelOrder` tìm lệnh theo `OrderId` trong sổ; còn dư → gỡ + `OrderCancelled`; không còn → từ chối kèm lý do | `src/Flex.Domain/Matching/MatchingEngine.cs` | `CancelOrder`, `OrderCancelled` | `Order` (trạng thái `Cancelled`) | Unit: AC-007, AC-008, hủy lặp lại |
| US-001, US-002 / FR-007 | P1 | Đủ rõ | `TradeExecuted` chứa TradeId, BuyOrderId, SellOrderId, Price, Quantity, thứ tự khớp | `src/Flex.Domain/Events/TradeExecuted.cs` | Event schema trong contract | `Trade` | Unit: assert đủ trường trên mọi kịch bản khớp |
| US-001, US-002, US-004 / FR-008 | P1 | Đủ rõ | `GetSnapshot()` trả các mức giá hai bên với danh sách lệnh chờ theo thứ tự ưu tiên | `src/Flex.Domain/Entities/OrderBookSnapshot.cs` | `OrderBookSnapshot` trong contract | `OrderBookSnapshot` | Unit: AC-002, AC-004, AC-007 |
| FR-009 | P1 | Đủ rõ | Không dùng đồng hồ/random; thứ tự theo `SequenceNumber`; sự kiện đánh số tuần tự; cấu trúc dữ liệu duyệt theo thứ tự xác định | Toàn bộ `src/Flex.Domain` | Bảo đảm ghi trong contract | Dòng sự kiện | Unit: chạy cùng kịch bản 10 lần, so sánh chuỗi sự kiện + snapshot bằng nhau tuyệt đối (SC-002) |
| FR-010 | P1 | Đủ rõ | Không tham chiếu package hạ tầng; `Flex.Domain` chỉ dùng BCL | `src/Flex.Domain/Flex.Domain.csproj` | Không áp dụng | Không áp dụng | Review csproj: 0 package runtime; solution không có project infra |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không áp dụng — không có DB | Không áp dụng | Không áp dụng |
| API/Contract | Contract in-process mới (commands/events/snapshot) — nền cho MVP 02 | Không có consumer hiện hữu; rủi ro thiếu trường cho MVP 02 | Review contract theo "Đầu ra cho MVP 02" trong `docs/mvp/01-matching-rules.md` |
| Permission/Security | Không áp dụng — không mở mạng, một `DemoBroker` | Không áp dụng | Review: không package network, `BrokerId` có mặt trên lệnh/sự kiện |
| Logging/Audit | Dòng sự kiện tuần tự là audit nghiệp vụ; demo in console | Thiếu truy vết nếu sự kiện thiếu trường | Unit test assert trường sự kiện; xem output demo |
| UI/UX | Không áp dụng — không có UI (console output của demo là đủ) | Không áp dụng | Chạy demo, đối chiếu kịch bản MVP |
| Job/Worker/Integration | Không áp dụng — không async/integration | Không áp dụng | Không áp dụng |

## API/Contract Detail

**Có thay đổi contract không**: Có — tạo mới contract in-process (chưa có consumer bên ngoài).

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `PlaceOrder`, `CancelOrder` (command) | In-process API | Tạo mới | Không áp dụng (mới) | Console demo, unit tests; MVP 02 API host (tương lai) |
| `OrderAccepted`, `OrderRejected`, `TradeExecuted`, `OrderCancelled` (event) | In-process event | Tạo mới | Không áp dụng (mới) | Console demo, unit tests; MVP 02 event publisher (tương lai) |
| `OrderBookSnapshot` | In-process query result | Tạo mới | Không áp dụng (mới) | Console demo, unit tests; MVP 03 bảng điện (tương lai) |

Chi tiết schema: [contracts/exchange-core.md](contracts/exchange-core.md).

## Permission Matrix

Không áp dụng — MVP 01 chỉ có một `DemoBroker` giả lập trong tiến trình, không có mô hình quyền (spec §9). `BrokerId` được gắn trên lệnh/sự kiện làm nền cho đa broker ở MVP 06.

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng — trạng thái hoàn toàn in-memory, không persist, mất khi tắt tiến trình (đúng phạm vi FR-010, spec §14).

**Migration**: Không áp dụng.

**Backfill/Cleanup**: Không áp dụng.

**Tương thích dữ liệu cũ**: Không áp dụng.

**Rủi ro dữ liệu**: Không áp dụng.

**Cách xác minh**: Không áp dụng.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Solution `Flex.Exchange.sln` với `src/Flex.Exchange` (console host) + `src/Flex.Domain` (domain), **không** tạo `Flex.Infrastructures` ở MVP 01 | Giữ đúng layout/naming pattern auth service ở phần có nhu cầu thật; MVP 01 không có DB/MQ/logging infra nên project infra sẽ rỗng | Tạo đủ 3 project như auth ngay từ đầu | Vi phạm Nguyên tắc V (abstraction suy đoán); MVP 02 thêm sau không tốn chi phí chuyển đổi |
| DEC-002 | Engine khớp lệnh đặt trong `Flex.Domain` (entities + `Matching/`), host chỉ wiring + demo | Engine là pure business logic không phụ thuộc hạ tầng — đúng vai trò project Domain trong pattern auth; MVP 02 bọc API lên mà không đụng engine | Đặt engine trong `src/Flex.Exchange/Services` như auth service | Auth đặt Services ở host vì logic gắn HTTP/DB; engine ở đây thuần domain, đặt ở host sẽ buộc MVP 02 refactor |
| DEC-003 | Giá và khối lượng dùng `long` (VND nguyên, số cổ phiếu nguyên) | Số học nguyên tuyệt đối xác định (FR-009), tránh sai số thập phân; giá VN không có lẻ dưới đồng | `decimal` | Không cần độ chính xác thập phân; so sánh/chia lô bằng số nguyên đơn giản và an toàn hơn |
| DEC-004 | Ưu tiên thời gian theo `SequenceNumber` (số tuần tự engine cấp khi nhận lệnh); timestamp chỉ ghi nhận để hiển thị | Loại bỏ phụ thuộc đồng hồ hệ thống — nguồn phi xác định chính (spec Giả định, FR-009) | Dùng `DateTime.UtcNow` làm khóa ưu tiên | Hai lệnh có thể trùng timestamp; đồng hồ khác nhau giữa máy phá vỡ NFR-001 |
| DEC-005 | `MatchingEngine` expose API đồng bộ: nhận command → trả `IReadOnlyList<ExchangeEvent>`; engine không tự publish ra ngoài | Đơn giản, dễ test, dễ tái lập; MVP 02 tự quyết cách publish (WebSocket/MQ) từ danh sách sự kiện trả về | Event bus/observer pattern trong engine | Thêm indirection không cần thiết khi chỉ có một consumer trong tiến trình (Complexity Gate) |
| DEC-006 | xUnit + `Microsoft.NET.Test.Sdk` cho test project | Chuẩn de-facto .NET, không có precedent test framework trong repo Flex nào để phải theo | NUnit, MSTest | Không có lợi thế; xUnit phổ biến nhất với .NET 9 |
| DEC-007 | Config FXS mặc định: tham chiếu 20.000, tick 100, biên độ ±7% (trần 21.400/sàn 18.600), lô chẵn 100 | Theo quy tắc HOSE quen thuộc; khớp kịch bản demo (giá 20.000, khối lượng 100/200 đều hợp lệ); là config thay đổi được (NFR-003) | Hardcode không biên độ | Vi phạm NFR-003 và FR-001 (phải có kiểm tra biên độ) |

## Chiến lược kiểm thử

**Unit test** (`tests/Flex.Exchange.UnitTests`, xUnit):
- `OrderValidatorTests`: từng ràng buộc tick/biên độ/lô chẵn/khối lượng/mã — case hợp lệ và vi phạm, đúng mã lý do (FR-001, AC-009).
- `MatchingEngineTests`: 6 nhóm hành vi bắt buộc (SC-003) — không khớp (lệnh vào sổ nằm chờ), khớp toàn phần (AC-001/002), khớp một phần (AC-003/004), ưu tiên giá (AC-005, kèm khớp xuyên nhiều mức giá), ưu tiên thời gian (AC-006), hủy lệnh (AC-007/008, kèm hủy lặp lại và hủy lệnh khớp một phần).
- `DeterminismTests`: chạy kịch bản hỗn hợp (đặt/khớp/hủy ≥20 lệnh) 10 lần, so sánh chuỗi sự kiện và snapshot cuối bằng nhau tuyệt đối (FR-009, SC-002).
- `TradeExecutedTests`: mọi giao dịch có đủ trường đối chiếu (FR-007).

**Integration test**: Không áp dụng — không có DB/service ngoài; toàn bộ hành vi test được ở mức unit.

**Contract test**: Không áp dụng ở MVP 01 — contract là in-process; unit test trên schema sự kiện đóng vai trò này. MVP 02 sẽ thêm contract test khi có API.

**Permission/security test**: Không áp dụng — không có mô hình quyền; review csproj bảo đảm không có package network (SEC-002).

**E2E/manual test**: Chạy console demo `src/Flex.Exchange` với 3 kịch bản trong `docs/mvp/01-matching-rules.md`, đối chiếu output với kỳ vọng (SC-001) — ghi trong [quickstart.md](quickstart.md).

**Regression test**: Không áp dụng — repo mới, chưa có luồng hiện hữu.

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
├── README.md                          # Cập nhật: mô tả service + cách chạy demo/test
├── CLAUDE.md                          # Context cho agent trong repo con
├── .gitignore                         # Theo pattern flex-auth-service (.NET)
├── src/
│   ├── Flex.Domain/
│   │   ├── Flex.Domain.csproj         # net9.0, không package runtime
│   │   ├── Entities/
│   │   │   ├── Order.cs               # Lệnh + trạng thái vòng đời + RemainingQuantity
│   │   │   ├── OrderBook.cs           # Sổ hai bên, sort giá + FIFO theo sequence
│   │   │   ├── OrderBookSnapshot.cs   # Kết quả truy vấn snapshot
│   │   │   ├── Trade.cs               # Kết quả một lần khớp
│   │   │   └── InstrumentConfig.cs    # Tick, trần/sàn, lô chẵn, mã
│   │   ├── Enums/
│   │   │   ├── OrderSide.cs           # Buy/Sell
│   │   │   ├── OrderStatus.cs         # Pending/PartiallyFilled/Filled/Cancelled/Rejected
│   │   │   └── RejectReason.cs        # Mã lý do từ chối đặt/hủy lệnh
│   │   ├── Events/
│   │   │   ├── ExchangeEvent.cs       # Base: EventSequence, BrokerId
│   │   │   ├── OrderAccepted.cs
│   │   │   ├── OrderRejected.cs
│   │   │   ├── TradeExecuted.cs
│   │   │   └── OrderCancelled.cs
│   │   ├── Commands/
│   │   │   ├── PlaceOrder.cs
│   │   │   └── CancelOrder.cs
│   │   └── Matching/
│   │       ├── MatchingEngine.cs      # Entry point: command in → events out + snapshot
│   │       └── OrderValidator.cs      # Kiểm tra hợp lệ theo InstrumentConfig
│   └── Flex.Exchange/
│       ├── Flex.Exchange.csproj       # Console host, tham chiếu Flex.Domain
│       └── Program.cs                 # Chạy 3 kịch bản demo, in sự kiện + snapshot
└── tests/
    └── Flex.Exchange.UnitTests/
        ├── Flex.Exchange.UnitTests.csproj  # xUnit, tham chiếu Flex.Domain
        ├── OrderValidatorTests.cs
        ├── MatchingEngineTests.cs
        ├── DeterminismTests.cs
        └── TradeExecutedTests.cs
```

**Quyết định cấu trúc**: Theo pattern `flex-auth-service` (`src/` chứa host + `Flex.Domain`), lược bỏ `Flex.Infrastructures` (DEC-001) và bổ sung `tests/` (auth service chưa có test project — bộ test là điều kiện hoàn thành bắt buộc của MVP 01 nên phải thêm).

## Rollout & Rollback

**Kế hoạch rollout**: Không áp dụng — MVP 01 không deploy; hoàn thành = merge code vào `main` của `flex-exchange-service` với test pass và demo chạy đúng.

**Tương thích ngược**: Không áp dụng — repo mới, chưa có consumer.

**Feature flag/config**: Không áp dụng — tham số nghiệp vụ (tick/biên độ/lô) nằm trong `InstrumentConfig` truyền vào engine.

**Thực thi migration/backfill khi rollout**: Không áp dụng.

**Rollback code/config**: Revert commit/PR trên `flex-exchange-service` — không có state ngoài code.

**Rollback dữ liệu/migration**: Không áp dụng.

**Điều kiện kích hoạt rollback**: Không áp dụng.

## Observability & Debug

**Log cần có**:
- Dòng sự kiện engine (chính là output nghiệp vụ): mỗi event có `EventSequence`, loại event, `OrderId`, `BrokerId`, symbol, side, price, quantity, và với `TradeExecuted`: `TradeId`, `BuyOrderId`, `SellOrderId`, giá/khối lượng khớp.
- Console demo in từng sự kiện và snapshot sau mỗi kịch bản — đủ để debug bằng mắt.

**Dữ liệu không được log**: Không áp dụng — toàn bộ dữ liệu là giả lập, không có secret/PII.

**Metric cần theo dõi**: Không áp dụng ở MVP 01 (không deploy); số lượng event/trade đếm được từ dòng sự kiện khi cần.

**Trace/Correlation**: `EventSequence` (toàn cục, tuần tự) + `OrderId`/`TradeId` cho phép dựng lại toàn bộ diễn biến — đây là cơ chế trace chính (FR-009).

**Cách kiểm tra sau release**: `dotnet test` pass toàn bộ + chạy demo đối chiếu 3 kịch bản (quickstart.md).

**Tình huống debug chính**: Kết quả khớp sai kỳ vọng → phát lại chuỗi lệnh đầu vào (deterministic) và soi dòng sự kiện từng bước; test chập chờn → nghi ngờ nguồn phi xác định lọt vào (kiểm tra không có DateTime/random trong `Matching/`).

## Theo dõi độ phức tạp

Không có vi phạm constitution cần biện minh. (Việc bỏ `Flex.Infrastructures` là giảm độ phức tạp so với pattern gốc, đã ghi tại DEC-001.)

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research hoặc ghi rủi ro rõ ràng.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary nếu có.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Mỗi `US`/`FR` P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Các contract/API/event thay đổi đã có consumer bị ảnh hưởng và cách kiểm tra compatibility.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử đã bao phủ unit, integration, contract, permission/security, E2E/manual và regression khi liên quan.
- [x] Rollout, rollback code/config, rollback dữ liệu/migration, feature flag/config và backward compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật trong repository.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
