# Data Model: Quản lý Vòng đời & Ràng buộc Trạng thái Phiên Giao dịch

**Input**: [spec.md](./spec.md) mục 9, [research.md](./research.md)

---

## 1. `TradingSessionPhase` (mở rộng enum, `Flex.Exchange.Domain.TradingSession`)

Từ 3 giá trị hiện có (`Open`, `Continuous`, `Close`) mở rộng thành 7 giá trị theo FR-001:

```
PreOpen, ATO, Continuous, Intermission, ATC, PLO, Close
```

**Lifecycle** (theo BR-001..BR-007 và bảng luồng trạng thái ở spec.md mục 8):

```
PreOpen --(hết PreOpenDuration)--> ATO --(hết AtoDuration)--> Continuous(sáng)
Continuous(sáng) --(hết ContinuousMorningDuration)--> Intermission
Intermission --(hết IntermissionDuration)--> Continuous(chiều)
Continuous(chiều) --(hết ContinuousAfternoonDuration)--> ATC
ATC --(hết AtcDuration)--> PLO | Close   [PLO nếu market.HasPlo, ngược lại Close]
PLO --(hết PloDuration)--> Close
```

Với market không có `ATO` (UPCoM, HNX cơ sở — BR-002/BR-003): `PreOpen` chuyển thẳng sang `Continuous`, bỏ qua `ATO`.
Với market không có `ATC`/`PLO` (UPCoM — BR-002): `Continuous`(chiều) chuyển thẳng sang `Close`, bỏ qua `ATC`/`PLO`.

**Ghi chú**: `Continuous` chỉ có một giá trị enum dùng chung cho cả 2 khoảng sáng/chiều — phân biệt bằng việc đã đi qua `Intermission` hay chưa (không cần thêm state riêng).

## 2. `TradingSessionState` (Domain entity, thay thế bản 3-phase hiện có)

| Field | Type | Ghi chú |
|---|---|---|
| `SessionId` | `Guid` | Không đổi |
| `Market` | `string` | Không đổi (`HOSE`, `HNX`, `UPCOM`, `DERIVATIVES`) |
| `SessionDate` | `DateOnly` | Không đổi |
| `Phase` | `TradingSessionPhase` | Mở rộng 7 giá trị |
| `StartedAt` | `DateTimeOffset` | Không đổi |
| `PhaseStartedAt` | `DateTimeOffset` | **Mới** — thời điểm bắt đầu phase hiện tại (thay `ContinuousStartedAt` cũ, tổng quát cho mọi phase) |
| `ClosedAt` | `DateTimeOffset?` | Không đổi |
| `HasAto` | `bool` | **Mới** — market có phiên ATO không (BR-002/BR-003) |
| `HasPlo` | `bool` | **Mới** — market có phiên PLO không (BR-003) |
| `PhaseDurations` | `IReadOnlyDictionary<TradingSessionPhase, TimeSpan>` | **Mới** — thời lượng cấu hình cho từng phase của market này |

**Method**: `TryAdvance(TradingSessionPhase expected, DateTimeOffset now)` — logic chuyển tiếp cập nhật để nhảy qua `ATO`/`ATC`/`PLO` khi `HasAto`/`HasPlo` = false, theo thứ tự lifecycle ở mục 1.

## 3. `OrderType` (enum mới, `Flex.Exchange.Domain.Enums`)

```csharp
public enum OrderType { LO, ATO, ATC }
```

Phạm vi MVP chỉ gồm 3 giá trị này (xem spec.md mục 13 — `MP`/`MTL`/`MOK`/`MAK` ngoài phạm vi).

## 4. `SessionOrderTypeRule` (rule tĩnh trong code, không lưu DB)

Ánh xạ `TradingSessionPhase` → tập `OrderType` được phép, dùng chung cho mọi market (không phụ thuộc market vì luật loại lệnh theo phase là như nhau across markets):

| Phase | OrderType cho phép | Nhận lệnh mới? |
|---|---|---|
| `PreOpen` | (không) | Không — từ chối tất cả (`SessionNotOpen`, BR-005) |
| `ATO` | `LO`, `ATO` | Có |
| `Continuous` | `LO` | Có |
| `Intermission` | `LO` | Có (queue, không khớp — theo mục 6 spec) |
| `ATC` | `LO`, `ATC` | Có |
| `PLO` | (không) | Không — từ chối tất cả (`SessionClosed`, BR-006) |
| `Close` | (không) | Không — từ chối tất cả (hành vi hiện có `SessionClosed`) |

Triển khai dưới dạng `Dictionary<TradingSessionPhase, OrderType[]>` tĩnh trong `SessionService` hoặc file cấu hình riêng — không cần entity/table DB vì rule này là quy tắc nghiệp vụ cố định (BR-001), không đổi theo runtime.

## 5. `RejectReason` (mở rộng enum, `Flex.Exchange.Domain.Enums`)

Thêm 2 giá trị mới vào enum hiện có (`UnknownSymbol, InvalidQuantity, InvalidLotSize, InvalidPrice, InvalidTickSize, OutOfPriceBand, MissingBrokerId, BrokerMismatch, OrderNotFound, SessionNotOpen, SessionClosed`):

```
CancelNotAllowedInCurrentSession, OrderTypeNotAllowedInCurrentSession
```

## 6. `TradingSessionOptions` (cấu hình, mở rộng `appsettings.json`)

Từ cấu hình phẳng hiện có (`OpenDurationSeconds`, `ContinuousDurationSeconds` áp dụng chung mọi market) chuyển sang cấu hình theo từng market:

```jsonc
"TradingSession": {
  "Enabled": true,
  "Markets": {
    "HOSE":            { "HasAto": true,  "HasPlo": false, "PreOpenSeconds": 5, "AtoSeconds": 15, "ContinuousMorningSeconds": 30, "IntermissionSeconds": 10, "ContinuousAfternoonSeconds": 30, "AtcSeconds": 15 },
    "HNX":              { "HasAto": false, "HasPlo": true,  "PreOpenSeconds": 5, "ContinuousMorningSeconds": 30, "IntermissionSeconds": 10, "ContinuousAfternoonSeconds": 30, "AtcSeconds": 15, "PloSeconds": 15 },
    "UPCOM":            { "HasAto": false, "HasPlo": false, "PreOpenSeconds": 5, "ContinuousMorningSeconds": 30, "IntermissionSeconds": 10, "ContinuousAfternoonSeconds": 30 },
    "DERIVATIVES":      { "HasAto": true,  "HasPlo": false, "PreOpenSeconds": 5, "AtoSeconds": 15, "ContinuousMorningSeconds": 30, "IntermissionSeconds": 10, "ContinuousAfternoonSeconds": 30, "AtcSeconds": 15 }
  }
}
```

Field không áp dụng cho market đó (vd. `AtoSeconds` khi `HasAto: false`) bị bỏ qua khi build `PhaseDurations`.

## 7. `SessionDto` / bảng `exchange_sessions` (PostgreSQL, `flex-database`)

**Không cần migration** — cột `status VARCHAR(24)` đã đủ rộng để chứa 7 giá trị phase mới (`preopen`, `ato`, `continuous`, `intermission`, `atc`, `plo`, `close`), không có `CHECK` constraint giới hạn giá trị. Chỉ cần đổi giá trị string được ghi bởi `SessionService`/`SessionRepository`.

## 8. `exchange_orders.order_type` (PostgreSQL, `flex-database`)

**Không cần migration** — cột `order_type VARCHAR(16) NOT NULL` đã tồn tại sẵn từ changeset gốc (`001-create-base-table-for-hnx.sql`), hiện chưa được ghi giá trị đúng loại từ code (domain chưa có `OrderType`). Sau thay đổi này, `order_type` sẽ được ghi giá trị canonical viết hoa khớp `OrderType` enum (`LO`/`ATO`/`ATC`), nhất quán với cách `status`/`side` hiện đang lưu.

## 9. Relationships

```
TradingSessionState (1) --- (N) Order [qua Market/Symbol, không phải FK trực tiếp]
TradingSessionPhase (1) --- (N) OrderType cho phép [SessionOrderTypeRule, static]
Market (1) --- (1) TradingSessionOptions.Markets[market] [cấu hình lịch phiên]
```

Không có thay đổi quan hệ FK trong DB — `session_id` trên `exchange_orders`/`exchange_trades` đã tồn tại sẵn từ trước.
