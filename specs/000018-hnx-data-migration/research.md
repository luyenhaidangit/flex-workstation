# Research: Migrate dữ liệu HNX khỏi in-memory

## Phạm vi khảo sát

- `flex-exchange-service`: .NET 9, ASP.NET Core controllers, Npgsql 9, Application/Domain/Infrastructure/Api; `TradingSessionService` và ledger hiện dùng state in-memory.
- `flex-database`: HNX PostgreSQL/Liquibase; release `1.0.0.0` đã có `exchange_instruments`, `exchange_orders`, `exchange_order_history`, `exchange_trades`, `exchange_outbox`.
- `flex-microfrontend`: Angular exchange feature gọi `GET /api/orderbook`, `GET /api/trades` và trading-session APIs; không cần đổi public contract cho phase reference data.

## TQ-001 — Có cần migration/backfill không?

**Decision**: Có schema validation và seed/backfill reference data; không backfill order/trade trong phase đầu.

**Rationale**: Reference data là nhóm được chọn để migrate đầu tiên. Cần dữ liệu instrument HNX tồn tại trong DB trước cutover, trong khi order/trade còn thuộc các phase sau và không nên mở rộng scope.

**Alternatives considered**:

- Cutover khi DB rỗng: loại vì có thể làm FE/BE mất instrument hiện tại.
- Backfill toàn bộ order/trade: loại vì vượt MVP và tăng rủi ro consistency.

## TQ-002 — Dùng flow/module hiện có hay tạo extension point mới?

**Decision**: Thêm một application-owned port cho HNX reference data, implementation PostgreSQL trong `Flex.Exchange.Infrastructure`, đăng ký ở composition root; không tạo repository generic.

**Rationale**: Port bảo vệ Application khỏi Npgsql/schema details và cho phép giữ implementation hiện tại làm legacy/fallback trong giai đoạn dual-read. Một port tập trung phù hợp hơn abstraction CRUD tổng quát.

**Alternatives considered**:

- Đưa Npgsql trực tiếp vào controller/service: loại vì làm rò rỉ persistence vào application/presentation.
- Generic repository cho mọi bảng: loại vì chưa có nhu cầu và che khuất query/transaction semantics.

## TQ-003 — Contract hiện tại có cần backward compatibility không?

**Decision**: Có. Không đổi endpoint/payload FE trong phase reference data; chỉ thay nguồn dữ liệu phía sau service và bổ sung telemetry/diagnostic nội bộ.

**Rationale**: FE hiện dùng exchange APIs và spec yêu cầu không gián đoạn luồng hiện tại. Giữ contract giúp rollout độc lập giữa BE và FE.

**Alternatives considered**:

- Thêm endpoint reference-data mới ngay: loại vì không cần cho user flow MVP và tăng consumer surface.

## TQ-004 — Chiến lược dual-read và cutover

**Decision**: DB reference data là nguồn candidate; trong giai đoạn dual-read đọc legacy và DB, canonicalize rồi so sánh identity/symbol/market/status, phát hiện mismatch thì giữ legacy làm nguồn phục vụ và chặn cutover. Khi đạt ngưỡng kiểm tra đã định, bật config cutover sang DB.

**Rationale**: Phù hợp quyết định Clarify và cho phép phát hiện sai lệch mà không làm gián đoạn FE/BE.

**Alternatives considered**:

- Cutover trực tiếp: loại vì không có cửa sổ đối chiếu an toàn.
- Ghi DB nhưng vẫn đọc legacy vô thời hạn: loại vì không đạt mục tiêu loại bỏ phụ thuộc in-memory.

## TQ-005 — Transaction, idempotency và rollback

**Decision**: Seed/backfill reference data dùng stable `instrument_id` và unique `symbol`; ghi kiểu upsert idempotent. Schema rollout forward-only theo Liquibase. Rollback runtime bằng config về legacy; rollback dữ liệu dùng forward-fix/restore theo quy ước database.

**Rationale**: Liquibase repo quy định changeset đã chạy là bất biến và không rollback production tự động. Reference data có thể retry an toàn nhờ uniqueness.

**Alternatives considered**:

- Xóa/recreate bảng khi rollback: loại vì rủi ro mất dữ liệu và không phù hợp database convention.

## Kết luận research

Không còn câu hỏi kỹ thuật chặn thiết kế. Phase này chỉ thiết kế reference-data vertical slice; order/order history/trade/outbox và runtime state tiếp tục được inventory/migrate ở các phase sau.
