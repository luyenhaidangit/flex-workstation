# Tasks: Persistência DB cho MVP 1 — Matching rules và order book

**Phạm vi đã chốt**: MVP 1 sử dụng PostgreSQL cho bốn bảng lõi của Exchange:
`exchange_instruments`, `exchange_sessions`, `exchange_orders`, `exchange_trades`.

Không triển khai trong MVP 1: `exchange_order_history`, `exchange_outbox`, bảng migration/audit, account, balance, fee, settlement và các market khác.

## Phase 1: Setup

- [ ] T001 [P] Rà soát contract FE/BE và runtime in-memory hiện tại cho `OrderBook`, `TradingSession`, `Order` và `Trade`, ghi kết quả vào `specs/000018-hnx-data-migration/research.md`.
- [ ] T002 [P] Kiểm tra baseline bằng `dotnet test --configuration Release`, `npm test -- --watch=false` và Liquibase `validate`; ghi command/result vào `specs/000018-hnx-data-migration/quickstart.md`.
- [ ] T003 [P] Xác định seed instrument MVP 1 (`FXS`, `HNX`, `ACTIVE`) và quy tắc tạo identity/order sequence, không ghi secret.

## Phase 2: Database schema

- [ ] T004 [P] Tạo Liquibase changeset idempotent cho `exchange_instruments` với primary key, unique `symbol`, `market`, `status`, `created_at`.
- [ ] T005 [P] Tạo Liquibase changeset cho `exchange_sessions` với session date/type/status và thời gian mở/đóng; bảo đảm không có hai session active cùng market/date/type.
- [ ] T006 [P] Tạo hoặc điều chỉnh Liquibase changeset cho `exchange_orders` gồm session/instrument foreign key, side, limit price, quantity, filled/remaining quantity, status và accepted time; thêm unique client order identity.
- [ ] T007 [P] Tạo hoặc điều chỉnh Liquibase changeset cho `exchange_trades` gồm buy/sell order foreign key, instrument/session foreign key, execution price/quantity và trade sequence unique trong session.
- [ ] T008 [US1] Seed dữ liệu instrument và một continuous session HNX theo changeset forward-only; không sửa changeset đã chạy.

## Phase 3: Persistence ports và adapters

- [ ] T009 Tạo application ports cho instrument, session, order và trade persistence trong `flex-exchange-service`.
- [ ] T010 [P] Tạo canonical models và validation cho instrument, session, order, trade; giới hạn MVP 1 ở HNX, continuous session và limit order.
- [ ] T011 [P] Tạo PostgreSQL/Npgsql adapters cho bốn bảng, dùng transaction và parameterized SQL.
- [ ] T012 Tích hợp adapters vào DI/configuration của `Flex.Exchange.Infrastructure` và `Flex.Exchange.Api`.

## Phase 4: US1 — Place order và matching

### Tests trước implementation

- [ ] T013 [P] Viết integration tests cho schema, foreign keys, unique constraints và seed của bốn bảng.
- [ ] T014 [P] Viết tests cho order validation: symbol/session/status, BUY/SELL, limit price, quantity và duplicate client order.
- [ ] T015 [P] Viết tests cho no-match, full match, partial match, price priority, time priority và cancel order.
- [ ] T016 [P] Viết transaction tests bảo đảm một matching operation ghi order updates và trade atomically.
- [ ] T017 [P] Viết restart test: mở order book, restart BE, đọc lại open orders từ DB và tiếp tục matching.
- [ ] T018 [P] Review FE exchange consumer (`exchange-api.service.ts`, models và components) và viết FE/API regression tests bảo đảm order book/trades vẫn hiển thị đúng với DB-backed BE; nếu phát hiện contract mismatch thì cập nhật consumer trong phạm vi MVP 1.

### Implementation

- [ ] T019 [US1] Implement instrument/session repositories và khởi tạo active HNX continuous session.
- [ ] T020 [US1] Implement order repository với create, open-order query theo price-time priority, update remaining/status và cancel.
- [ ] T021 [US1] Implement trade repository với trade sequence và insert immutable trade record.
- [ ] T022 [US1] Thay `InMemoryLedgerService` trong exchange flow bằng DB-backed order/trade persistence, giữ nguyên public contract.
- [ ] T023 [US1] Implement matching transaction: lock các open orders cần xử lý, tạo trade, cập nhật order và commit atomically.
- [ ] T024 [US1] Implement order-book reconstruction từ các order chưa hoàn tất; không tạo bảng `exchange_order_book`.
- [ ] T025 [US1] Implement cancel order với điều kiện chỉ cancel order còn open/partial và thuộc session hợp lệ.

## Phase 5: Verification và vận hành

- [ ] T026 [P] Chạy Liquibase `validate` và `update-sql`, kiểm tra migration forward-only và index phục vụ order-book query.
- [ ] T027 [P] Chạy backend unit/integration tests và kiểm tra không còn code path MVP 1 ghi order/trade vào in-memory.
- [ ] T028 [P] Hoàn tất FE integration/regression cho DB-backed order book/trades, chạy Angular exchange tests và smoke test place/cancel/match; không đổi API payload nếu không có mismatch thực tế.
- [ ] T029 Kiểm tra transaction/concurrency cho hai lệnh đối ứng đồng thời, không tạo duplicate trade hoặc âm `remaining_quantity`.
- [ ] T030 Ghi quickstart cho seed, mở session, place/cancel order, restart và xác minh dữ liệu còn nguyên.
- [ ] T031 Ghi rõ các hạng mục để phase sau: order history, outbox, account/balance, fee, settlement và các market khác.

## Dependencies

- T001–T003 → T004–T008.
- T004–T008 → T009–T012.
- T009–T012 → T013–T018 và T019–T025.
- T019–T025 → T026–T031.

## Definition of Done

- Bốn bảng được tạo bằng Liquibase và seed idempotent.
- Place/cancel/matching persist được vào DB.
- Hỗ trợ no-match, full match, partial match, price-time priority và cancel.
- Restart BE không làm mất open orders hoặc trades đã ghi nhận.
- FE/BE public contract không đổi.
- Không triển khai thêm bảng ngoài phạm vi bốn bảng MVP 1.

## Validation Commands

- `liquibase --changelog-file=changelog/db.changelog-master.xml validate`
- `liquibase --changelog-file=changelog/db.changelog-master.xml update-sql`
- `dotnet test --configuration Release`
- `npm test -- --watch=false`
