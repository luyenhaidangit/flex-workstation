# Kế hoạch triển khai: Quản lý Vòng đời & Ràng buộc Trạng thái Phiên Giao dịch

**Branch**: `000020-session-lifecycle` | **Ngày**: 2026-07-26 | **Đặc tả**: [spec.md](./spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000020-session-lifecycle/spec.md`

**Ghi chú**: Template này được điền bởi lệnh `/speckit-plan`. Xem `.specify/templates/plan-template.md` để biết workflow tạo kế hoạch.

## Tóm tắt

**Yêu cầu chính từ spec**: Mở rộng máy trạng thái phiên từ 3 phase (`Open`/`Continuous`/`Close`) sang 7 phase (`PreOpen`, `ATO`, `Continuous`, `Intermission`, `ATC`, `PLO`, `Close`) cho 4 market (`HOSE`, `HNX`, `UPCoM`, `HNX-Derivatives`); chặn hủy lệnh trong `ATO`/`ATC` (MVP-002/FR-002); kiểm soát loại lệnh `LO`/`ATO`/`ATC` theo phase (MVP-004/FR-003); cấu hình lịch phiên riêng theo market (MVP-003/FR-004); đảm bảo ghi CSDL trước khi transition (BR-007).

**Hướng tiếp cận kỹ thuật dự kiến**: Mở rộng enum/state hiện có trong `Flex.Exchange.Domain`/`Flex.Exchange.Application` của `flex-exchange-service`, tái dùng pattern van chặn (`IsAcceptingOrders`) và cấu trúc worker (`SessionWorker`) đã có, không cần migration DB (cột đã đủ rộng).

**Kết quả sau research**: Hoàn thành — xem [research.md](./research.md) (4 quyết định TQ-001..004).

## Phạm vi kỹ thuật

**Trong phạm vi**:
- `flex-exchange-service/src/Flex.Exchange.Domain`: `TradingSessionPhase` (mở rộng enum), `TradingSessionState` (lifecycle 7-phase, per-market ATO/PLO), `OrderType` (enum mới), `RejectReason` (thêm 2 giá trị).
- `flex-exchange-service/src/Flex.Exchange.Application`: `SessionService` (van chặn cancel + order type, ghi CSDL trước transition), `TradingSessionOptions` (cấu hình per-market), `ISessionService` (thêm method), `ExchangeService` (gọi van chặn cancel, resolve market cho cancel, truyền `OrderType`).
- `flex-exchange-service/src/Flex.Exchange.Api`: `SessionWorker` (chạy lifecycle 7-phase per-market), `OrdersController`/`PlaceOrderRequest` (field `orderType` mới), `appsettings.json` (cấu hình `TradingSession:Markets`).
- `flex-exchange-service/tests`: unit test cho `TradingSessionState`, `SessionService`; test cho `OrdersController`/`SessionController`.
- `flex-microfrontend/src/app/exchange`: `market-board.component.ts` (tách `isTradingActive` hiện tại thành 2 gate riêng — đặt lệnh vs hủy lệnh — theo `state` mới, sửa gate "hiện nút khởi động phiên"), `exchange.models.ts` (`SessionView.state` vẫn là `string` nhưng nhận 7 giá trị mới, không cần đổi type).

  *Lý do đưa vào scope*: `market-board.component.ts:215-216` hiện hardcode `state === 'open' || state === 'continuous'` để bật form đặt lệnh/nút hủy. Sau khi backend không còn trả `'open'` (thay bằng `preopen`/`ato`/.../`close`), điều kiện này sẽ luôn `false` ngoài `continuous` — khóa hẳn khả năng đặt lệnh hợp lệ trong `ato`/`atc` dù backend cho phép (FR-003/BR-001), khiến tính năng chính của feature này không demo được qua UI. Đây là phần code FE phụ thuộc trực tiếp vào contract đang đổi, không phải mở rộng UI mới.

**Ngoài phạm vi kỹ thuật** (khớp mục 13 spec.md):
- `flex-microfrontend`: UI hiển thị đầy đủ nhãn tiếng Việt cho 7 trạng thái, bộ chọn `orderType` (`LO`/`ATO`/`ATC`) trên form đặt lệnh, hỗ trợ chọn nhiều market — **không** trong phạm vi phase này. FE chỉ sửa tối thiểu để không bị khóa sai chức năng (xem trên); mặc định `orderType` gửi lên vẫn là `LO` (được BR-001 cho phép trong cả `ATO`/`ATC`), nên không cần UI chọn loại lệnh để hoạt động đúng.
- DB migration cho `flex-database` — không cần, `exchange_sessions.status` và `exchange_orders.order_type` đã là `VARCHAR` không ràng buộc `CHECK`.
- Thuật toán đấu giá định kỳ (uniform-price call auction), cơ chế khớp PLO thực sự, loại lệnh `MP`/`MTL`/`MOK`/`MAK`, chặn sửa lệnh (amend) — như đã nêu ở spec.md mục 13.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: .NET 9 / C# (Nullable, ImplicitUsings enable)

**Service/App liên quan**: `flex-exchange-service` (`Flex.Exchange.Domain`, `Flex.Exchange.Application`, `Flex.Exchange.Infrastructure`, `Flex.Exchange.Api`); `flex-microfrontend` (Angular, module `src/app/exchange` — sửa tối thiểu để không vỡ theo contract mới)

**Phụ thuộc chính**: ASP.NET Core Web API + SignalR (`MarketHub`), Npgsql (raw ADO.NET, không ORM), Serilog, `Microsoft.Extensions.Options`

**Lưu trữ**: PostgreSQL — bảng `exchange_sessions`, `exchange_orders` (đã tồn tại, không cần migration — xem [data-model.md § 7-8](./data-model.md))

**Kiểm thử**: xUnit (`Flex.Exchange.Domain.Tests`, `Flex.Exchange.Api.Tests`)

**Nền tảng chạy**: ASP.NET Core Kestrel, chạy local demo (theo `flex-exchange-service/CLAUDE.md`: "Service demo local cho lõi khớp lệnh FXS")

**Đơn vị deploy**: `Flex.Exchange.Api` (self-contained service, không tách deploy unit mới)

**Loại project**: web-service (REST API + `BackgroundService` worker + SignalR hub)

**Mục tiêu hiệu năng**: Kế thừa NFR-001 (<1ms cho van chặn phiên); không đặt mục tiêu mới ngoài spec

**Ràng buộc**: Không phá vỡ shape API hiện có của `POST /api/orders`/`DELETE /api/orders/{orderId}` (field mới phải optional/backward-compatible — xem [contracts/session-lifecycle.md](./contracts/session-lifecycle.md))

**Quy mô/Phạm vi**: Demo/simulator nội bộ, single-instance, 4 market, không yêu cầu horizontal scale

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Phạm vi kỹ thuật khớp đúng MVP-001..004 và mục "Ngoài phạm vi" của spec.md |
| Traceability Gate | Cần plan | Pass | Xem bảng Traceability bên dưới — mọi FR/BR P1/P2 đều có mapping |
| Test Gate | Cần plan | Pass | Xem § Chiến lược kiểm thử — unit test cho lifecycle + van chặn, integration test cho API |
| Security Gate | Pass | Pass | Không có dữ liệu nhạy cảm mới; SEC-001 kế thừa cơ chế check phiên đã có |
| Compatibility Gate | Cần plan | Pass (có ghi breaking change) | `state` 7 giá trị là breaking đối với consumer WebSocket/REST cũ (flag ở contracts.md), nhưng `orderType`/`reason` mới đều backward-compatible |
| Observability Gate | Cần plan | Pass | NFR-002 yêu cầu log Critical khi retry ghi CSDL thất bại — đưa vào § Observability & Debug |
| Complexity Gate | Pass | Pass | Không thêm project/service mới; mở rộng trong đúng 4 project hiện có của `flex-exchange-service` |
| Release Gate | Không áp dụng | Không áp dụng | Service demo local, không có pipeline release chính thức |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Lịch phiên theo giờ thực hay theo thời lượng cấu hình (giây)? → **Resolved**, xem [research.md](./research.md#tq-001-lịch-phiên-theo-giờ-thực-wall-clock-hay-theo-thời-lượng-cấu-hình-virtualgiây).
- **TQ-002**: Cách xác định `market` khi hủy lệnh (API không có `symbol`)? → **Resolved**, xem [research.md](./research.md#tq-002-cách-xác-định-market-khi-hủy-lệnh-cancelorder-không-có-symbol).
- **TQ-003**: Vị trí đặt van chặn loại lệnh/hủy lệnh (Domain hay Application)? → **Resolved**, xem [research.md](./research.md#tq-003-vị-trí-đặt-van-chặn-loại-lệnh-fr-003fr-006-và-hủy-lệnh-fr-002fr-005).
- **TQ-004**: Cách đảm bảo ghi CSDL trước khi transition theo BR-007? → **Resolved**, xem [research.md](./research.md#tq-004-cách-đảo-ngược-thứ-tự-ghi-csdltransition-theo-br-007).

## Thiết kế tổng quan

**Luồng chính**:
1. `SessionWorker` (per-market loop) tính `TradingSessionState` kế tiếp dựa trên `PhaseDurations`/`HasAto`/`HasPlo` của market đó, rồi gọi `SessionService.TryAdvance`.
2. `SessionService.TryAdvance` **ghi CSDL trước** (qua `ISessionRepository.UpdateStatusAsync`, có retry), chỉ mutate `TradingSessionState` in-memory và publish `SESSION_STATE_CHANGED` sau khi ghi thành công (BR-007).
3. `ExchangeService.PlaceOrder` gọi `SessionService.IsAcceptingOrders` (đã có) **và** `SessionService.IsOrderTypeAllowed(market, orderType)` (mới) trước khi đẩy lệnh vào `MatchingEngine`.
4. `ExchangeService.CancelOrder` resolve `market` từ order đã tìm thấy, gọi `SessionService.IsAllowingCancel(market)` (mới) trước khi gọi `MatchingEngine.CancelOrder`.
5. Khi phase vào `Close`, `SessionService.CloseAndReset` hủy toàn bộ lệnh còn lại (hành vi `CancelAll` đã có, giữ nguyên — BR-004).

**Component/module tham gia**:
- `Flex.Exchange.Domain.TradingSession`: định nghĩa state machine 7-phase, không phụ thuộc Infrastructure.
- `Flex.Exchange.Application.TradingSession.SessionService`: điều phối van chặn, ghi CSDL, publish event.
- `Flex.Exchange.Application.Services.ExchangeService`: điểm gọi van chặn từ luồng đặt/hủy lệnh.
- `Flex.Exchange.Api.HostedServices.SessionWorker`: vòng lặp timer per-market.
- `Flex.Exchange.Api.Controllers.OrdersController`: nhận `orderType` từ request.

**Điểm mở rộng/thay đổi chính**:
- `TradingSessionPhase` enum: 3 → 7 giá trị (breaking cho mọi nơi switch theo enum cũ trong `flex-exchange-service` — đã rà soát, chỉ có `SessionService`/`SessionWorker`/`ToView` dùng, đều nằm trong phạm vi sửa).
- `PlaceOrderRequest`/`PlaceOrderCommand`: thêm `OrderType` optional (mặc định `LO`).
- `TradingSessionOptions`: đổi từ cấu hình phẳng sang `Dictionary<string, MarketSessionScheduleOptions>`.

**Luồng thay thế/lỗi chính**:
- Ghi CSDL thất bại khi transition: retry có backoff trong `SessionWorker`, không mutate state, log `Critical` mỗi lần thất bại (BR-007/NFR-002).
- Lệnh sai loại trong `ATO`/`ATC`/`PreOpen`/`PLO`: từ chối với `RejectReason` tương ứng, không đẩy vào `MatchingEngine`.
- Hủy lệnh trong `ATO`/`ATC`: từ chối với `CancelNotAllowedInCurrentSession`, không gọi `MatchingEngine.CancelOrder`.

**Thay đổi boundary giữa service/module**:
- Không áp dụng — toàn bộ thay đổi nằm trong `flex-exchange-service`, không đụng service khác (`flex-api-gateway`, `flex-auth-service`, ...).

**Idempotency/Concurrency**:
- `SessionService` đã dùng `lock (gate)` cho mọi thao tác đọc/ghi state per-market — giữ nguyên cơ chế này khi thêm van chặn mới, không cần thêm khóa.
- Retry ghi CSDL (BR-007) không tạo duplicate vì `UpdateStatusAsync` là idempotent theo `sessionId` (UPDATE theo khóa chính).

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-002 | P1 | Đủ rõ | Thêm `SessionService.IsAllowingCancel(market)`, gọi từ `ExchangeService.CancelOrder` trước khi cancel | `Flex.Exchange.Application/TradingSession/SessionService.cs`, `Flex.Exchange.Application/Services/ExchangeService.cs` | `DELETE /api/orders/{orderId}` — `reason: CancelNotAllowedInCurrentSession` | `RejectReason` (thêm giá trị) | Unit: `SessionService` trả `false` khi `ATO`/`ATC`; Integration: `OrdersController` cancel bị từ chối |
| US-001 / FR-003 | P1 | Đủ rõ | Thêm `SessionOrderTypeRule` (dict tĩnh) + `SessionService.IsOrderTypeAllowed(market, orderType)`, gọi từ `PlaceOrder` | `Flex.Exchange.Application/TradingSession/SessionService.cs` | `POST /api/orders` — request thêm `orderType`, `reason: OrderTypeNotAllowedInCurrentSession` | `OrderType` (enum mới), `RejectReason` | Unit: rule cho từng phase; Integration: `OrdersController` place bị từ chối sai loại |
| US-001 / FR-005 | P2 | Đủ rõ | `ISessionService.IsAllowingCancel(market)` | `Flex.Exchange.Application/TradingSession/ISessionService.cs` | Không áp dụng (internal interface) | Không áp dụng | Unit test trực tiếp trên `SessionService` |
| US-001 / FR-006 | P2 | Đủ rõ | `ISessionService.IsOrderTypeAllowed(market, orderType)` | `Flex.Exchange.Application/TradingSession/ISessionService.cs` | Không áp dụng | Không áp dụng | Unit test trực tiếp trên `SessionService` |
| US-002 / FR-001 | P1 | Đủ rõ | Mở rộng `TradingSessionPhase` thành 7 giá trị + logic bỏ qua ATO/PLO theo `HasAto`/`HasPlo` | `Flex.Exchange.Domain/TradingSession/TradingSessionState.cs` | `GET /api/session`, `SESSION_STATE_CHANGED` — `state` 7 giá trị | `TradingSessionPhase`, `TradingSessionState` | Unit: `TradingSessionStateTests` mở rộng cho lifecycle đầy đủ + market không ATO/PLO |
| US-002 / FR-004 | P1 | Đủ rõ | `TradingSessionOptions.Markets: Dictionary<string, MarketSessionScheduleOptions>` | `Flex.Exchange.Application/TradingSession/TradingSessionOptions.cs`, `appsettings.json` | Không áp dụng | `TradingSessionOptions` | Unit: `SessionWorker` chạy đúng lịch cho từng market (xem quickstart Kịch bản 1) |
| BR-004 | P1 | Đủ rõ | Giữ nguyên `CloseAndReset`/`engine.CancelAll` khi vào `Close` | `Flex.Exchange.Application/TradingSession/SessionService.cs` (không đổi logic, chỉ đổi điều kiện gọi theo phase mới) | Không áp dụng | Không áp dụng | Integration: quickstart Kịch bản 4 |
| BR-005 | P1 | Đủ rõ | `IsAcceptingOrders` trả `SessionNotOpen` cho `PreOpen` (đã đúng hành vi hiện tại, chỉ cần giữ khi mở rộng enum) | `Flex.Exchange.Application/TradingSession/SessionService.cs` | `POST /api/orders` — `reason: SessionNotOpen` | Không áp dụng | Integration: quickstart Kịch bản 3 |
| BR-006 | P1 | Đủ rõ | `IsAcceptingOrders` trả `SessionClosed` cho `PLO` | `Flex.Exchange.Application/TradingSession/SessionService.cs` | `POST /api/orders` — `reason: SessionClosed` | Không áp dụng | Integration: quickstart Kịch bản 3 |
| BR-007 / NFR-002 | P1 | Đủ rõ | Đảo thứ tự ghi CSDL trước khi mutate in-memory, retry + log `Critical` | `Flex.Exchange.Application/TradingSession/SessionService.cs`, `Flex.Exchange.Api/HostedServices/SessionWorker.cs` | Không áp dụng (internal) | `SessionDto` | Integration: quickstart Kịch bản 5 (giả lập DB lỗi) |
| SEC-001 | P1 | Đủ rõ | Kế thừa — mọi endpoint đặt/hủy lệnh đã gọi qua `SessionService` trước khi xử lý | `ExchangeService.cs` | Không áp dụng | Không áp dụng | Bao phủ bởi test FR-002/FR-003 |
| US-001/US-002 (hệ quả FE) | P1 | Đủ rõ | Tách `isTradingActive` thành `canStartSession` (state ∈ preopen — hoặc chưa có phiên), `canPlaceOrder` (state ∈ {ato, continuous, atc}), `canCancelOrder` (state === continuous) | `flex-microfrontend/src/app/exchange/market-board.component.ts`, `market-board.component.html` | `GET /api/session`, `SESSION_STATE_CHANGED` (đọc `state` mới) | `SessionView.state` (đã là `string`, không đổi type) | Unit: `market-board.component.spec.ts` mở rộng case cho `preopen`/`ato`/`atc`/`intermission`/`plo` |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không đổi schema — chỉ đổi giá trị string ghi vào cột `status`/`order_type` đã tồn tại | Không rủi ro — cột không có `CHECK` constraint | Query `SELECT DISTINCT status FROM exchange_sessions` sau khi chạy để xác nhận giá trị mới hợp lệ |
| API/Contract | `state` (7 giá trị), `orderType` (field mới, optional), `reason` (2 giá trị mới) | `state` là breaking cho consumer cũ; `orderType`/`reason` backward-compatible | Xem [contracts/session-lifecycle.md](./contracts/session-lifecycle.md) |
| Permission/Security | Không đổi — không có role/tenant mới | Không áp dụng | Không áp dụng |
| Logging/Audit | Thêm log `Critical` khi retry ghi CSDL thất bại (NFR-002) | Thiếu log này sẽ khiến phiên "treo" âm thầm | Kiểm tra log field `sessionId`, `market`, `attemptCount` khi giả lập DB lỗi (quickstart Kịch bản 5) |
| UI/UX | `market-board.component.ts` hardcode `state === 'open' \|\| 'continuous'` để gate đặt/hủy lệnh và nút khởi động phiên — vỡ hoàn toàn với `state` mới (`'open'` không còn tồn tại) | Nếu không sửa: form đặt lệnh bị khóa ngoài `continuous`, chặn demo đúng luồng ATO/ATC dù backend đã đúng | Sửa 3 getter riêng (`canStartSession`/`canPlaceOrder`/`canCancelOrder`) theo `state` mới — xem dòng traceability US-001/US-002 (hệ quả FE); nhãn hiển thị 7 trạng thái đầy đủ (i18n, market selector) vẫn ngoài phạm vi |
| Job/Worker/Integration | `SessionWorker` đổi từ loop 3-phase sang loop 7-phase per-market, có retry ghi CSDL | Retry vô hạn (theo BR-007, không có upper bound) có thể khiến worker "treo" ở 1 phase nếu DB down lâu — được ghi nhận là hành vi **chủ đích** (đánh đổi lấy nhất quán) | Integration test giả lập DB lỗi tạm thời (quickstart Kịch bản 5) |

## API/Contract Detail

**Có thay đổi contract không**: Có — xem chi tiết đầy đủ tại [contracts/session-lifecycle.md](./contracts/session-lifecycle.md).

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `GET /api/session`, `SESSION_STATE_CHANGED` | API + WebSocket Event | `state` mở rộng 3→7 giá trị | Không | `flex-microfrontend`, mọi WebSocket client hiện tại |
| `POST /api/orders` | API | Thêm field `orderType` (optional, mặc định `LO`) | Có | Không ai bị ảnh hưởng nếu không gửi field mới |
| `DELETE /api/orders/{orderId}` | API | `reason` có thêm giá trị `CancelNotAllowedInCurrentSession` | Có | Client cần xử lý giá trị `reason` chưa biết bằng default case (không có, vì đây là thêm case mới trong response, không phải request) |

## Permission Matrix

Không áp dụng — tính năng không thêm role/tenant/scope mới; mọi actor (nhà đầu tư, broker, worker) giữ nguyên quyền như hiện tại theo spec.md mục 10 (SEC-001 kế thừa).

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng.

**Migration**: Không áp dụng — `exchange_sessions.status` và `exchange_orders.order_type` đã là `VARCHAR` không ràng buộc `CHECK`, đủ chứa giá trị mới (xem [data-model.md § 7-8](./data-model.md)).

**Backfill/Cleanup**: Không áp dụng — không có dữ liệu lịch sử cần chuyển đổi (giá trị `status` cũ `open`/`continuous`/`close` vẫn là dữ liệu lịch sử hợp lệ, không cần backfill vì phiên mới sẽ dùng giá trị mới từ đầu).

**Tương thích dữ liệu cũ**: Các dòng `exchange_sessions` cũ với `status = 'open'` vẫn đọc được bình thường (chỉ là dữ liệu lịch sử, không có logic nào đọc lại các phiên đã đóng để tiếp tục xử lý).

**Rủi ro dữ liệu**: Không áp dụng.

**Cách xác minh**: Query thủ công theo mô tả ở bảng Phân tích tác động.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Lịch phiên theo thời lượng cấu hình (giây), không theo giờ thực | Nhất quán pattern demo hiện có, cho phép test nhanh | Lịch giờ thực (wall-clock) | Không cần thiết cho service demo local, phá vỡ khả năng test nhanh |
| DEC-002 | Resolve `market` khi cancel qua order đã tìm thấy (không đổi API contract) | Giữ backward compatible cho `DELETE /api/orders/{orderId}` | Thêm `market`/`symbol` bắt buộc vào request cancel | Breaking change không cần thiết |
| DEC-003 | Van chặn cancel/order-type đặt tại `SessionService`/`ExchangeService` (Application), không đụng `MatchingEngine` (Domain) | `MatchingEngine` không biết khái niệm phiên multi-market | Đặt van chặn trong `MatchingEngine` | `MatchingEngine` chỉ biết 1 symbol, không có tham chiếu `ISessionService` |
| DEC-004 | Ghi CSDL trước khi mutate in-memory + retry có log Critical (BR-007) | Đáp ứng yêu cầu nhất quán đã chốt ở Clarifications; không cần đổi cơ chế lock hiện có | Rollback in-memory nếu ghi CSDL thất bại sau khi đã mutate | Phức tạp hơn (cần snapshot để revert) so với việc chỉ trì hoãn mutate |
| DEC-005 | `PlaceOrderRequest.orderType` optional, mặc định `LO` | Giữ backward compatible cho client/bot hiện có chỉ hoạt động trong `Continuous` | `orderType` bắt buộc | Sẽ buộc mọi client hiện có phải sửa dù chỉ dùng `LO` |
| DEC-006 | FE (`market-board.component.ts`) chỉ sửa gate `isTradingActive` (tách 3 getter theo `state` mới), không thêm UI chọn `orderType`/market | `orderType` mặc định `LO` đã được BR-001 cho phép trong `ATO`/`ATC`, đủ để không bị chặn sai; thêm UI chọn loại lệnh là mở rộng UX, không phải sửa lỗi vỡ do contract đổi | Làm đầy đủ UI 7 trạng thái + chọn `orderType` + multi-market trong cùng phase này | Mở rộng scope UI vượt quá lý do bắt buộc (tránh vỡ chức năng), nên để phase riêng nếu cần |

## Chiến lược kiểm thử

**Unit test**:
- `TradingSessionState`: lifecycle đầy đủ 7-phase; market có/không có `ATO`/`PLO` (bỏ qua phase đúng thứ tự); không cho `TryAdvance` sai thứ tự (giữ test hiện có `AdvancesOnlyInLinearOrder`, mở rộng thêm case).
- `SessionService`: `IsAllowingCancel` trả `false` đúng lúc `ATO`/`ATC`; `IsOrderTypeAllowed` đúng theo `SessionOrderTypeRule` cho từng phase; ghi CSDL thất bại không mutate state (mock `ISessionRepository` throw).

**Integration test**:
- `OrdersController`: đặt lệnh sai loại trong `ATO`/`ATC`/`PreOpen`/`PLO` bị từ chối đúng `reason`; hủy lệnh trong `ATO`/`ATC` bị từ chối; hủy lệnh trong `Continuous` thành công.
- `SessionController`: `GET`/`POST /start` trả đúng `state` theo lifecycle mới cho từng market.
- `market-board.component.spec.ts` (Angular/Jasmine, đã có sẵn file test): mở rộng case cho `canStartSession`/`canPlaceOrder`/`canCancelOrder` theo từng giá trị `state` mới (`preopen`, `ato`, `continuous`, `intermission`, `atc`, `plo`, `close`).

**Contract test**: Không áp dụng — không có consumer ngoài `flex-exchange-service` tự động verify contract (chỉ có `flex-microfrontend`, xử lý thủ công/ngoài phạm vi phase này).

**Permission/security test**: Không áp dụng — không có thay đổi phân quyền.

**E2E/manual test**: 5 kịch bản trong [quickstart.md](./quickstart.md), chạy qua `Flex.Exchange.http`.

**Regression test**: Chạy lại toàn bộ `Flex.Exchange.Domain.Tests`/`Flex.Exchange.Api.Tests` hiện có để đảm bảo luồng `Continuous`/khớp lệnh cơ bản (MVP 000013) không bị phá vỡ bởi việc mở rộng enum.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000020-session-lifecycle/
├── plan.md              # File này (output của lệnh /speckit-plan)
├── research.md          # Output Phase 0 (lệnh /speckit-plan)
├── data-model.md        # Output Phase 1 (lệnh /speckit-plan)
├── quickstart.md        # Output Phase 1 (lệnh /speckit-plan)
├── contracts/           # Output Phase 1 (lệnh /speckit-plan)
└── tasks.md             # Output Phase 2 (lệnh /speckit-tasks - KHÔNG tạo bởi /speckit-plan)
```

### Source code (repository root)

**Quyết định cấu trúc**: `.NET/backend service` — thay đổi nằm trong 4 project hiện có của `flex-exchange-service`, không tạo project mới.

```text
flex-exchange-service/
├── src/
│   ├── Flex.Exchange.Domain/
│   │   ├── TradingSession/TradingSessionState.cs      # Mở rộng TradingSessionPhase, lifecycle 7-phase
│   │   └── Enums/
│   │       ├── OrderType.cs                            # MỚI
│   │       └── RejectReason.cs                          # Thêm 2 giá trị
│   ├── Flex.Exchange.Application/
│   │   ├── TradingSession/
│   │   │   ├── SessionService.cs                        # Thêm IsAllowingCancel, IsOrderTypeAllowed, ghi CSDL trước transition
│   │   │   ├── ISessionService.cs                       # Thêm 2 method mới
│   │   │   └── TradingSessionOptions.cs                 # Đổi sang Dictionary<string, MarketSessionScheduleOptions>
│   │   └── Services/ExchangeService.cs                   # Gọi van chặn cancel, resolve market, truyền OrderType
│   └── Flex.Exchange.Api/
│       ├── HostedServices/SessionWorker.cs               # Loop 7-phase per-market
│       ├── Controllers/OrdersController.cs                # PlaceOrderRequest thêm orderType
│       └── appsettings.json                              # TradingSession:Markets cấu hình mới
└── tests/
    ├── Flex.Exchange.Domain.Tests/TradingSessionStateTests.cs   # Mở rộng
    └── Flex.Exchange.Api.Tests/                                  # Thêm test controller

flex-microfrontend/
└── src/app/exchange/
    ├── market-board.component.ts        # Tách isTradingActive → canStartSession/canPlaceOrder/canCancelOrder
    └── market-board.component.spec.ts   # Mở rộng test case theo state mới
```

## Rollout & Rollback

**Kế hoạch rollout**: Deploy `flex-exchange-service` mới; không cần bước migration/backfill trước hay sau (không đổi schema). Cấu hình `appsettings.json` mặc định phải set `HasAto`/`HasPlo` đúng cho từng market trước khi bật.

**Tương thích ngược**: `orderType` optional giữ nguyên hành vi cho client cũ. `state` 7 giá trị là breaking cho FE — xử lý trong cùng phase này (`market-board.component.ts`), nên `flex-exchange-service` và `flex-microfrontend` PHẢI deploy đồng thời (hoặc FE deploy trước, vì code FE mới vẫn tương thích ngược với `state` cũ trong lúc chuyển tiếp — 3 getter mới không còn nhánh nào khớp `'open'` cũ nhưng cũng không lỗi, chỉ coi như "chưa sẵn sàng").

**Feature flag/config**: `TradingSession:Enabled` (đã có) tiếp tục dùng làm flag bật/tắt toàn bộ tính năng phiên; không cần flag mới vì đây là thay thế trực tiếp cơ chế cũ.

**Thực thi migration/backfill khi rollout**: Không áp dụng.

**Rollback code/config**: Revert lên version trước của `flex-exchange-service` — an toàn vì không đổi schema DB; dữ liệu `status`/`order_type` mới (7 giá trị, `LO`/`ATO`/`ATC`) vẫn là string hợp lệ, version cũ chỉ đơn giản không hiểu các giá trị mới nếu đọc lại (nhưng version cũ không có logic đọc lại phiên đã qua).

**Rollback dữ liệu/migration**: Không áp dụng — không có migration.

**Điều kiện kích hoạt rollback**: Log `Critical` liên tục từ NFR-002 (DB không ghi được, phiên bị treo) không tự khắc phục sau khi đã xử lý sự cố DB; hoặc lỗi tràn lan khi client cũ gửi `orderType` không hợp lệ ngoài `LO`/`ATO`/`ATC`.

## Observability & Debug

**Log cần có**:
- `SESSION_STATE_CHANGED` transition: `sessionId`, `market`, `phase` cũ/mới, `timestamp` (đã có pattern log trong `SessionService`).
- Retry ghi CSDL thất bại (BR-007/NFR-002): `sessionId`, `market`, `attemptCount`, exception — mức `Critical`.
- Lệnh bị từ chối do van chặn phiên: `orderId`/`brokerId`, `market`, `phase`, `reason` (`CancelNotAllowedInCurrentSession`/`OrderTypeNotAllowedInCurrentSession`) — mức `Warning` (theo pattern log hiện có của `CancelOrder`).

**Dữ liệu không được log**: Không áp dụng — không có token/secret/dữ liệu nhạy cảm liên quan đến tính năng này (chỉ là trạng thái phiên và loại lệnh).

**Metric cần theo dõi**: Số lần retry ghi CSDL thất bại theo market (dùng để phát hiện DB degradation sớm) — có thể suy ra từ log Critical, không bắt buộc thêm metric riêng trong MVP này.

**Trace/Correlation**: Giữ nguyên `correlationId` đã có trong `PlaceOrderCommand`/`CancelOrderCommand`/`MarketEvent`.

**Cách kiểm tra sau release**: Chạy các kịch bản trong [quickstart.md](./quickstart.md); theo dõi log tìm `Critical` bất thường trong giờ đầu sau deploy.

**Tình huống debug chính**: Phiên "treo" ở 1 phase do DB lỗi (xem log Critical NFR-002); lệnh bị từ chối sai (kiểm tra `SessionOrderTypeRule` và `phase` hiện tại qua `GET /api/session`).

## Theo dõi độ phức tạp

> Không có vi phạm constitution cần biện minh — mọi gate ở trên đều Pass sau design.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary nếu có.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá.
- [x] Mỗi `US`/`FR` P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá.
- [x] Các contract/API/event thay đổi đã có consumer bị ảnh hưởng và cách kiểm tra compatibility.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ (Không áp dụng, có lý do).
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử đã bao phủ unit, integration, E2E/manual và regression.
- [x] Rollout, rollback code/config, feature flag/config và backward compatibility đã rõ.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật trong repository.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
