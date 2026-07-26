# Contracts: Quản lý Vòng đời & Ràng buộc Trạng thái Phiên Giao dịch

Phạm vi: `flex-exchange-service` — REST API (`Flex.Exchange.Api`) và sự kiện WebSocket (SignalR `MarketHub`).

---

## 1. `GET /api/session?market={market}`

Không đổi shape, chỉ đổi tập giá trị hợp lệ của `state`.

**Response `state`**: một trong `preopen`, `ato`, `continuous`, `intermission`, `atc`, `plo`, `close` (trước đây chỉ `open`, `continuous`, `close`).

**Breaking change**: Có, đối với consumer đang hardcode 3 giá trị cũ (`open`/`continuous`/`close`). `flex-microfrontend` (`market-board.component.ts`) là consumer duy nhất trong workspace hiện hardcode `state === 'open' || 'continuous'` để gate đặt/hủy lệnh — đây là phần **trong phạm vi kỹ thuật của phase này** (xem plan.md § Phạm vi kỹ thuật), chỉ sửa gate, không mở rộng UI hiển thị đầy đủ nhãn/màu cho 7 trạng thái (vẫn ngoài phạm vi).

---

## 2. `POST /api/orders` (`PlaceOrderRequest`)

**Request — trường mới**:

```jsonc
{
  "brokerId": "string",
  "symbol": "string",
  "side": "Buy | Sell",
  "price": 0,
  "quantity": 0,
  "orderType": "LO | ATO | ATC"   // MỚI — optional, mặc định "LO" nếu không gửi (backward compatible)
}
```

**Response — `reason` có thể trả thêm**:
- `SessionNotOpen` (đã có — nay áp dụng cho `PreOpen`)
- `OrderTypeNotAllowedInCurrentSession` (**mới** — FR-003/MVP-004)

**Backward compatibility**: `orderType` là optional, mặc định `LO` — client cũ (bao gồm `MarketMakerBot`/`DemoBrokerService` nội bộ) không cần đổi để tiếp tục hoạt động đúng trong `Continuous`. Client muốn đặt lệnh `ATO`/`ATC` phải gửi rõ `orderType`.

---

## 3. `DELETE /api/orders/{orderId}?brokerId={brokerId}`

**Request**: Không đổi shape (không thêm `market`/`symbol` — resolve qua order đã tồn tại, xem [research.md TQ-002](../research.md)).

**Response — `reason` có thể trả thêm**:
- `CancelNotAllowedInCurrentSession` (**mới** — FR-002/MVP-002, khi phiên đang `ATO` hoặc `ATC`)

**Backward compatibility**: Không breaking — chỉ thêm 1 giá trị `reason` mới, response shape giữ nguyên.

---

## 4. WebSocket event `SESSION_STATE_CHANGED` (`MarketHub`, `IMarketEventPublisher`)

**Payload** (`TradingSessionView`): không đổi field, chỉ đổi tập giá trị `state` giống mục 1 (7 giá trị thay vì 3).

**Breaking change**: Có, đối với consumer WebSocket đang hardcode 3 giá trị cũ — cùng lưu ý như mục 1 (`market-board.component.ts` nhận `state` qua cả REST polling lẫn `applyRealtimeEvent`, cả 2 đường đều dùng chung 3 getter đã sửa).

---

## 5. Tổng hợp breaking change

| Contract | Breaking? | Consumer bị ảnh hưởng | Cách xử lý |
|---|---|---|---|
| `state`/`SESSION_STATE_CHANGED.state` (3→7 giá trị) | Có | `flex-microfrontend` (`market-board.component.ts`), mọi client WebSocket đang switch theo 3 giá trị cũ | **Trong phạm vi phase này** — sửa 3 getter gate (`canStartSession`/`canPlaceOrder`/`canCancelOrder`) trong `market-board.component.ts`; hiển thị nhãn/UI đầy đủ cho 7 trạng thái vẫn ngoài phạm vi |
| `PlaceOrderRequest.orderType` (field mới, optional) | Không | — | Mặc định `LO` giữ nguyên hành vi cũ |
| `CancelOrderResponse.reason` (thêm giá trị) | Không | — | Giá trị enum mới, consumer switch theo `reason` không vỡ nếu có default case |
| `PlaceOrderResponse.reason` (thêm giá trị) | Không | — | Tương tự |
