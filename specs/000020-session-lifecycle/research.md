# Research: Quản lý Vòng đời & Ràng buộc Trạng thái Phiên Giao dịch

**Input**: [spec.md](./spec.md), câu hỏi kỹ thuật trong `plan.md`

---

## TQ-001: Lịch phiên theo giờ thực (wall-clock) hay theo thời lượng cấu hình (virtual/giây)?

**Decision**: Giữ mô hình thời lượng cấu hình theo giây (virtual day), mở rộng từ 2 khoảng (`OpenDurationSeconds`, `ContinuousDurationSeconds`) hiện có thành 7 khoảng theo từng phase, cấu hình riêng cho từng market.

**Rationale**:
- `flex-exchange-service` là "Service demo local" (theo `CLAUDE.md` của repo) — không kết nối Sở thật, không cần đồng bộ giờ tường thực.
- `SessionWorker` hiện tại đã dùng pattern `Task.Delay(duration)` cho từng phase; giữ pattern này giúp thay đổi tối thiểu, nhất quán với code có sẵn (nguyên tắc "thay đổi phẫu thuật").
- Cho phép rút ngắn thời lượng phiên khi demo/test (giây thay vì giờ thực) mà vẫn giữ đúng **thứ tự và tỷ lệ** các phase theo BR-001/002/003.
- Khớp với quyết định đã chốt ở Clarifications spec.md (Q1): chuyển ATO/ATC theo timer, không tính giá khớp thực sự.

**Alternatives considered**:
- Lịch giờ thực (cron-like, đối chiếu `DateTimeOffset.Now` với khung giờ 09:00/11:30/...): loại vì phá vỡ khả năng demo/test nhanh, và không có giá trị thêm khi hệ thống không nối Sở thật.

---

## TQ-002: Cách xác định `market` khi hủy lệnh (`CancelOrder` không có `Symbol`)?

**Decision**: Trước khi gọi `MatchingEngine.CancelOrder`, tra `Order` hiện có qua `FindEngineForOrder`/`engine.GetOrder(orderId)` để lấy `Symbol`, sau đó map `Symbol` → `market` bằng `KnownSymbolMarkets` (pattern đã dùng trong `PlaceOrder`). Nếu không tìm thấy order, giữ hành vi hiện tại (`OrderNotFound`) — không cần check phiên.

**Rationale**: Tái dùng cơ chế resolve market đã có sẵn trong `ExchangeService.PlaceOrder`, tránh thêm tham số `market`/`symbol` vào `CancelOrderCommand`/API contract (giữ backward compatible cho `DELETE /api/orders/{orderId}`).

**Alternatives considered**:
- Thêm `market`/`symbol` bắt buộc vào `CancelOrderRequest`: loại vì đây là breaking change cho API hiện có mà không cần thiết (order đã tự chứa symbol).

---

## TQ-003: Vị trí đặt van chặn loại lệnh (`FR-003`/`FR-006`) và hủy lệnh (`FR-002`/`FR-005`)?

**Decision**: Đặt cả hai van chặn trong `SessionService` (tầng Application), gọi từ `ExchangeService.PlaceOrder` (đã có sẵn gọi `IsAcceptingOrders`) và `ExchangeService.CancelOrder` (chưa có gọi nào — bổ sung mới). Không đặt van chặn trong `MatchingEngine` (Domain) vì trạng thái phiên là khái niệm cross-market thuộc Application, không thuộc về một engine đơn lẻ.

**Rationale**: Nhất quán với vị trí `IsAcceptingOrders` hiện tại; `MatchingEngine` không biết về khái niệm phiên multi-market.

**Alternatives considered**:
- Đặt van chặn trong `MatchingEngine`: loại vì `MatchingEngine` không có tham chiếu tới `ISessionService` và mỗi engine chỉ biết 1 symbol, không phải market.

---

## TQ-004: Cách đảo ngược thứ tự ghi CSDL/transition theo BR-007

**Decision**: Sửa `SessionService.TryAdvance`/`CloseAndReset` để **ghi CSDL trước, mutate in-memory sau**: tính `TradingSessionState` mới (không mutate state hiện có), thử ghi CSDL; nếu thành công mới gọi `TryAdvance` thật để mutate in-memory và publish `SESSION_STATE_CHANGED`. Nếu ghi CSDL thất bại, retry với backoff (không chặn vô hạn thread gọi — `SessionWorker` retry trong vòng lặp của chính nó), ghi log `LogCritical` mỗi lần thất bại (NFR-002).

**Rationale**: Đáp ứng BR-007 (đã chốt ở Clarifications Q4) mà không cần đổi kiến trúc lock hiện tại (`lock (gate)` trong `SessionService`); retry nằm trong `SessionWorker`/`SessionService` chứ không chặn caller khác.

**Alternatives considered**:
- Rollback in-memory nếu ghi CSDL thất bại sau khi đã mutate: loại vì phức tạp hơn (cần lưu snapshot để revert) so với việc chỉ đơn giản không mutate cho đến khi ghi thành công.

---

## Tóm tắt quyết định

| # | Quyết định | Ảnh hưởng chính |
|---|-----------|------------------|
| TQ-001 | Virtual/giây theo từng market, không đồng bộ giờ thực | `TradingSessionOptions`, `TradingSessionState`, `SessionWorker` |
| TQ-002 | Resolve market từ Order đã tìm thấy khi cancel | `ExchangeService.CancelOrder` |
| TQ-003 | Van chặn đặt tại `SessionService`/`ExchangeService`, không đụng `MatchingEngine` | `SessionService`, `ExchangeService` |
| TQ-004 | Ghi CSDL trước khi mutate in-memory + retry có log critical | `SessionService.TryAdvance`/`CloseAndReset` |
