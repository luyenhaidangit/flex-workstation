# Research: Ledger tiền và chứng khoán

## DEC-001 — Append-only in-memory ledger trong Application

**Quyết định**: Đặt `ILedgerService` và implementation in-memory trong `Flex.Exchange.Application/Ledger`, journal chỉ append sau khi validate cân bằng.

**Lý do**: MVP 06 đã dùng in-memory state và chưa có persistence contract. Cùng boundary giảm thay đổi, dễ kiểm thử và đúng ngoài phạm vi chưa có database/settlement.

**Phương án loại**: Thêm database ledger ngay trong MVP 7 vì cần migration, durability/recovery và operational scope chưa được yêu cầu.

## DEC-002 — Journal là nguồn tính balance

**Quyết định**: `BalanceProjector` derive balance buckets từ entries; `DemoAccountState` chỉ giữ compatibility view trong transition.

**Lý do**: Mục tiêu MVP là loại mutable balance source và bảo đảm audit.

**Phương án loại**: Tiếp tục mutate `DemoAccountState` rồi ghi audit phụ vì audit phụ có thể lệch trạng thái thực.

## DEC-003 — Đơn vị tiền và quantity

**Quyết định**: Dùng `long` integer minor units cho tiền và quantity như contracts hiện có; entry có `AssetType` và `AssetCode`.

**Lý do**: Tránh floating-point và không cần conversion ở Exchange/Broker hiện tại.

**Phương án loại**: `decimal` cho mọi amount vì không cần trong demo và tăng khác biệt với code hiện hữu.

## DEC-004 — Idempotency theo source reference

**Quyết định**: Unique key gồm `TenantId`, `SourceReference`, `EventType`; duplicate cùng payload trả journal hiện có, payload khác trả conflict.

**Lý do**: `TradeExecuted.EventId`/source reference ổn định hơn timestamp và hỗ trợ retry.

**Phương án loại**: Dedupe theo thời điểm nhận hoặc hash toàn payload vì không deterministic và khó trace.

## DEC-005 — API additive và read-first

**Quyết định**: Thêm endpoint balance/trace; adjustment chỉ dành cho operator demo và có liên kết reversal. Giữ API cũ.

**Lý do**: Không phá consumer MVP 1–6 và hỗ trợ kiểm chứng nghiệp vụ.

**Phương án loại**: Đổi `BrokerAccountSummary` thành ledger payload mới vì sẽ gây breaking change không cần thiết.

## DEC-006 — Không persistence/settlement

**Quyết định**: Restart reset journal; opening entries được seed lại khi process khởi tạo.

**Lý do**: Khớp giới hạn MVP 7; MVP 8 mới xử lý clearing/settlement/reconciliation.

**Phương án loại**: Backfill số dư hiện tại thành lịch sử giả vì không có source transaction đáng tin cậy.
