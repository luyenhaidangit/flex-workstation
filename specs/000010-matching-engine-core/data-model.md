# Data Model: Lõi khớp lệnh và order book (FlexSim MVP 01)

**Ngày**: 2026-07-14
**Phạm vi**: Thực thể in-memory trong `src/Flex.Exchange.Domain` của `flex-exchange-service`. Không có database/schema (FR-010).

Quy ước chung: giá và khối lượng là `long` (VND nguyên / số cổ phiếu nguyên); mọi ID và sequence là `long` tuần tự do engine cấp (DEC-003, DEC-004).

---

## 1. Order — Lệnh

Đại diện một yêu cầu mua/bán limit của broker.

| Trường | Kiểu | Ý nghĩa | Ràng buộc |
|--------|------|---------|-----------|
| `OrderId` | `long` | Định danh lệnh, engine cấp tuần tự khi chấp nhận | Duy nhất trong một phiên chạy engine |
| `BrokerId` | `string` | Broker gửi lệnh (`DemoBroker`) | Bắt buộc, không rỗng (SEC-001) |
| `Symbol` | `string` | Mã cổ phiếu (`FXS`) | Phải khớp `InstrumentConfig.Symbol`, sai → `UnknownSymbol` |
| `Side` | `OrderSide` | `Buy` / `Sell` | Bắt buộc |
| `Price` | `long` | Giá đặt (VND) | > 0; chia hết cho `TickSize`; trong [`FloorPrice`, `CeilingPrice`] |
| `Quantity` | `long` | Khối lượng đặt ban đầu | > 0; chia hết cho `LotSize` |
| `RemainingQuantity` | `long` | Khối lượng chưa khớp | 0 ≤ x ≤ `Quantity`; giảm dần theo từng lần khớp |
| `SequenceNumber` | `long` | Số tuần tự cấp khi nhận — khóa ưu tiên thời gian | Tăng dần nghiêm ngặt; không dùng timestamp để so ưu tiên |
| `Status` | `OrderStatus` | Trạng thái vòng đời | Theo bảng chuyển trạng thái bên dưới |

`ReceivedAt` không thuộc Domain MVP 01: “thời điểm” trong đặc tả được chuẩn hóa thành thứ tự logic khi engine tiếp nhận lệnh. Kết quả phải tái lập hoàn toàn nên `SequenceNumber` là nguồn sự thật cho priority; `ExecutedSequence`/`EventSequence` là nguồn sự thật cho thứ tự khớp và sự kiện. Nếu cần wall-clock metadata ở MVP sau, nó phải được thiết kế ở presentation/audit boundary và không tham gia priority hay event determinism.

### OrderStatus — chuyển trạng thái (khớp spec §7)

| Từ | Sự kiện | Sang | Điều kiện |
|----|---------|------|-----------|
| (mới) | Validate fail | `Rejected` | Vi phạm ràng buộc FR-001 |
| (mới) | Validate pass, không có đối ứng khớp được | `Pending` | Vào sổ chờ |
| (mới) | Validate pass, khớp một phần ngay | `PartiallyFilled` | Phần dư vào sổ |
| (mới) | Validate pass, khớp hết ngay | `Filled` | Không vào sổ |
| `Pending` | Khớp một phần | `PartiallyFilled` | `RemainingQuantity` > 0 |
| `Pending` / `PartiallyFilled` | Khớp hết phần còn lại | `Filled` | `RemainingQuantity` = 0, rời sổ |
| `Pending` / `PartiallyFilled` | `CancelOrder` | `Cancelled` | Rời sổ, phần dư không bao giờ khớp (BR-004) |
| `Filled` / `Cancelled` / `Rejected` | `CancelOrder` | (không đổi) | Từ chối hủy kèm lý do (AC-008) |

## 2. OrderBook — Sổ lệnh

Tập lệnh đang chờ (`Pending`/`PartiallyFilled`) của một mã, hai bên Buy/Sell.

**Bất biến (invariants)**:
- Bên mua duyệt theo giá **giảm dần**, bên bán theo giá **tăng dần** (FR-002).
- Trong cùng mức giá, duyệt theo `SequenceNumber` **tăng dần** — FIFO (FR-003).
- Chỉ lưu lệnh có `RemainingQuantity` > 0; lệnh `Filled`/`Cancelled` bị gỡ khỏi cấu trúc nội bộ ngay.
- Không tồn tại trạng thái "crossed" sau khi xử lý xong một command: giá mua tốt nhất < giá bán tốt nhất (nếu cả hai bên có lệnh) — vì lệnh vào được khớp ngay đến khi hết khả năng khớp (BR-005).
- Thứ tự duyệt phải xác định tuyệt đối (không phụ thuộc hash order) — FR-009.

## 3. Trade — Giao dịch

Kết quả một lần khớp giữa lệnh mới vào (aggressive) và lệnh chờ (passive).

| Trường | Kiểu | Ý nghĩa | Ràng buộc |
|--------|------|---------|-----------|
| `TradeId` | `long` | Định danh giao dịch, tuần tự | Tăng dần theo thứ tự khớp |
| `Symbol` | `string` | Mã | = `FXS` |
| `BuyOrderId` / `SellOrderId` | `long` | Hai lệnh tham gia | Phải tồn tại (FR-007) |
| `Price` | `long` | Giá khớp | = giá của **lệnh chờ** (BR-003, FR-005) |
| `Quantity` | `long` | Khối lượng khớp | = min(remaining hai bên) tại thời điểm khớp; > 0 |
| `ExecutedSequence` | `long` | Thứ tự khớp toàn cục | Trùng với `EventSequence` của `TradeExecuted` tương ứng |

## 4. InstrumentConfig — Cấu hình mã

Tham số nghiệp vụ truyền vào engine (NFR-003), không hardcode trong quy tắc khớp.

| Trường | Kiểu | Giá trị mặc định FXS (DEC-007) |
|--------|------|-------------------------------|
| `Symbol` | `string` | `FXS` |
| `ReferencePrice` | `long` | 20.000 |
| `TickSize` | `long` | 100 |
| `CeilingPrice` | `long` | 21.400 (tham chiếu +7%, làm tròn xuống tick) |
| `FloorPrice` | `long` | 18.600 (tham chiếu −7%, làm tròn lên tick) |
| `LotSize` | `long` | 100 |

Ràng buộc nội tại: `FloorPrice` ≤ `ReferencePrice` ≤ `CeilingPrice`; cả ba chia hết cho `TickSize`; `TickSize`, `LotSize` > 0.

## 5. ExchangeEvent — Dòng sự kiện

Base cho 4 sự kiện đầu ra; dòng sự kiện append-only là audit/trace duy nhất của hệ thống (spec §10).

| Trường chung | Kiểu | Ý nghĩa |
|--------------|------|---------|
| `EventSequence` | `long` | Số tuần tự toàn cục, tăng dần nghiêm ngặt — khóa so sánh determinism (SC-002) |
| `BrokerId` | `string` | Broker liên quan (SEC-001) |

| Event | Trường riêng |
|-------|--------------|
| `OrderAccepted` | `OrderId`, `Symbol`, `Side`, `Price`, `Quantity`, `SequenceNumber` |
| `OrderRejected` | `Symbol`, `Side`, `Price`, `Quantity`, `Reason` (`RejectReason`) — không có `OrderId` (lệnh chưa được cấp) |
| `TradeExecuted` | Toàn bộ trường của `Trade` (mục 3) |
| `OrderCancelled` | `OrderId`, `CancelledQuantity` (phần dư bị gỡ) |

Kết quả từ chối **hủy** (hủy lệnh không tồn tại/đã hoàn tất — AC-008) trả về cho caller dưới dạng kết quả command kèm `RejectReason`, không phát event `OrderCancelled`. Chi tiết trong [contracts/exchange-core.md](contracts/exchange-core.md).

## 6. RejectReason — Mã lý do từ chối

| Mã | Áp dụng cho | Ý nghĩa |
|----|-------------|---------|
| `UnknownSymbol` | PlaceOrder | Mã không khớp config |
| `InvalidQuantity` | PlaceOrder | Khối lượng ≤ 0 |
| `InvalidLotSize` | PlaceOrder | Không chia hết lô chẵn |
| `InvalidPrice` | PlaceOrder | Giá ≤ 0 |
| `InvalidTickSize` | PlaceOrder | Giá không chia hết bước giá |
| `OutOfPriceBand` | PlaceOrder | Giá ngoài [sàn, trần] |
| `MissingBrokerId` | PlaceOrder / CancelOrder | Thiếu `BrokerId` |
| `OrderNotFound` | CancelOrder | `OrderId` không tồn tại hoặc không còn trong sổ (đã khớp hết/đã hủy) |

## 7. OrderBookSnapshot — Ảnh chụp sổ lệnh

Kết quả truy vấn read-only (FR-008), không phải state sống.

- `Symbol`, `AsOfEventSequence` (sequence sự kiện cuối cùng trước khi chụp).
- `Bids` / `Asks`: danh sách mức giá theo đúng thứ tự ưu tiên; mỗi mức gồm `Price`, `TotalQuantity` và danh sách `(OrderId, RemainingQuantity, SequenceNumber)` theo FIFO.

## Quan hệ giữa thực thể

```text
InstrumentConfig 1 ── 1 MatchingEngine ── 1 OrderBook ── * Order (Pending/PartiallyFilled)
MatchingEngine ── * ExchangeEvent (append-only, EventSequence tăng dần)
TradeExecuted * ── 2 Order (BuyOrderId, SellOrderId)
OrderBookSnapshot = ảnh chụp OrderBook tại một EventSequence
```
