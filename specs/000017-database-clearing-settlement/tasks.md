# Tasks: Persistence foundation MVP 01–08

## Phase 1: Setup

- [ ] T001 Thêm `MySqlConnector` vào `flex-exchange-service/src/Flex.Exchange.Infrastructure/Flex.Exchange.Infrastructure.csproj`.
- [ ] T002 Thêm configuration key `Persistence:ConnectionString` không chứa secret vào `flex-exchange-service/src/Flex.Exchange.Api/appsettings.json`.
- [ ] T003 Cập nhật prerequisite MySQL/Flyway/secret tại `specs/000017-database-clearing-settlement/quickstart.md`.

## Phase 2: Foundational

- [ ] T004 Tạo migration reference/order/order history/trade trong `flex-database/exchange/migrations/V1.0__create_exchange_core.sql`.
- [ ] T005 [P] Tạo migration broker/customer/account/reservation trong `flex-database/exchange/migrations/V1.1__create_broker_accounts.sql`.
- [ ] T006 [P] Tạo migration journal/entry/balance/inbox/outbox/audit trong `flex-database/exchange/migrations/V1.2__create_ledger.sql`.
- [ ] T007 [P] Tạo migration obligation/statement/reconciliation/alert trong `flex-database/exchange/migrations/V1.3__create_post_trade.sql`.
- [ ] T008 Tạo seed Alpha/Beta idempotent trong `flex-database/exchange/seeders/V1.0__seed_demo_tenants.sql` (phụ thuộc T004–T007).
- [ ] T009 Tạo `PersistenceConnectionOptions` trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/PersistenceConnectionOptions.cs`.
- [ ] T010 Tạo `PersistenceScopeGuard` cho tenant/broker trong `flex-exchange-service/src/Flex.Exchange.Application/Persistence/PersistenceScopeGuard.cs`.
- [ ] T011 Tạo fixture MySQL trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/MySqlPersistenceFixture.cs`.
- [ ] T012 Tạo Flyway/seed smoke test trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/PersistenceMigrationTests.cs` (phụ thuộc T008, T011).

## Phase 3: US-001 — Khôi phục lõi giao dịch MVP 01–04

**Independent Test**: Tạo order/trade, restart service, xác nhận thứ tự và trạng thái được khôi phục.

- [ ] T013 [P] [US1] Viết rehydration lifecycle test trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Persistence/OrderRehydrationTests.cs` cho FR-001/002.
- [ ] T014 [P] [US1] Viết trade-to-two-orders trace test trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/TradePersistenceTests.cs` cho FR-003/NFR-001.
- [ ] T015 [US1] Tạo repository SQL order/history/trade trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/MySqlExchangeRepository.cs` (phụ thuộc T004, T009).
- [ ] T016 [US1] Tạo `ExchangeStateRehydrator` theo sequence trong `flex-exchange-service/src/Flex.Exchange.Application/Persistence/ExchangeStateRehydrator.cs` (phụ thuộc T013, T015).
- [ ] T017 [US1] Wire persistent exchange state vào `AddExchangeApplication` trong `flex-exchange-service/src/Flex.Exchange.Application/DependencyInjection.cs` (phụ thuộc T016).
- [ ] T018 [US1] Viết restart integration test trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/ExchangeRestartTests.cs` (phụ thuộc T014, T017).

## Phase 4: US-002 — Broker/account/reservation bền vững

**Independent Test**: Tạo reservation từ order, restart và gửi lặp source; không có reservation/balance trùng.

- [ ] T019 [P] [US2] Viết reservation idempotency test trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Persistence/ReservationPersistenceTests.cs` cho FR-005/006/NFR-002.
- [ ] T020 [US2] Tạo repository SQL broker/customer/account/reservation trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/MySqlBrokerRepository.cs` (phụ thuộc T005, T009).
- [ ] T021 [US2] Cập nhật `ReservationManager` dùng repository và source order trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/ReservationManager.cs` (phụ thuộc T019, T020).
- [ ] T022 [US2] Viết restart/duplicate integration test trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/BrokerReservationTests.cs` (phụ thuộc T018, T021).

## Phase 5: US-003 — Ledger và settlement theo trade nguồn

**Independent Test**: Trade nguồn tạo journal cân bằng, obligation T+ và trace xuyên order/account.

- [ ] T023 [P] [US3] Viết ledger balance/T+ tests trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Persistence/LedgerSettlementPersistenceTests.cs` cho FR-007–010/NFR-004.
- [ ] T024 [US3] Tạo repository SQL ledger/obligation trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/MySqlLedgerRepository.cs` (phụ thuộc T006, T007, T009).
- [ ] T025 [US3] Cập nhật `ILedgerService` persistence adapter trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/ILedgerService.cs` để yêu cầu trade/account source (phụ thuộc T022, T024).
- [ ] T026 [US3] Tạo `SettlementService` idempotent trong `flex-exchange-service/src/Flex.Exchange.Application/Settlement/SettlementService.cs` (phụ thuộc T023–T025).
- [ ] T027 [US3] Viết integration trace order→trade→account→journal→obligation trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/LedgerSettlementTraceTests.cs` (phụ thuộc T026).

## Phase 6: US-004 — Reconciliation và restore tenant

**Independent Test**: Statement đúng/lệch trả matched/alert; restore tenant staging vẫn trace/reconcile được.

- [ ] T028 [P] [US4] Viết reconciliation no-auto-fix test trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Persistence/ReconciliationPersistenceTests.cs` cho FR-011–013.
- [ ] T029 [US4] Tạo repository SQL statement/result/alert trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/MySqlReconciliationRepository.cs` (phụ thuộc T007, T009).
- [ ] T030 [US4] Tạo `ReconciliationService` append-only trong `flex-exchange-service/src/Flex.Exchange.Application/Reconciliation/ReconciliationService.cs` (phụ thuộc T028, T029).
- [ ] T031 [US4] Viết restore/reconciliation integration test trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/TenantRestoreTests.cs` (phụ thuộc T027, T030).
- [ ] T032 [US4] Ghi staging backup/restore drill và evidence NFR-006 trong `specs/000017-database-clearing-settlement/quickstart.md` (phụ thuộc T031).

## Phase 7: US-005 — Scope, audit, health và trace

**Independent Test**: Cross-tenant/broker bị chặn; health/trace cùng scope trả backlog và chuỗi nguồn đúng.

- [ ] T033 [P] [US5] Viết cross-scope security test trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/PersistenceScopeTests.cs` cho FR-015/016/SEC-001/002.
- [ ] T034 [P] [US5] Viết audit/health test trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/PersistenceOperationsTests.cs` cho FR-017/018/SEC-003/NFR-005.
- [ ] T035 [US5] Tạo `PersistenceAuditWriter` trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/PersistenceAuditWriter.cs` (phụ thuộc T006, T009).
- [ ] T036 [US5] Tạo internal trace/health controllers trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/PersistenceController.cs` theo `contracts/persistence.md` (phụ thuộc T010, T024, T029, T035).
- [ ] T037 [US5] Bổ sung metrics/correlation cho rehydration, duplicate, backlog, DLQ, T+ và alert trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/PersistenceTelemetry.cs` (phụ thuộc T036).
- [ ] T038 [US5] Viết API trace/health authorization test trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/PersistenceControllerTests.cs` (phụ thuộc T033, T034, T036, T037).

## Final Phase: Polish

- [ ] T039 Cập nhật API contract cuối cùng trong `specs/000017-database-clearing-settlement/contracts/persistence.md` (phụ thuộc T036).
- [ ] T040 Chạy `dotnet test flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Flex.Exchange.Domain.Tests.csproj` và `dotnet test flex-exchange-service/tests/Flex.Exchange.Api.Tests/Flex.Exchange.Api.Tests.csproj`, lưu kết quả trong `specs/000017-database-clearing-settlement/quickstart.md` (phụ thuộc T018, T022, T027, T031, T038).

## Dependencies & Execution Order

`Setup → Foundational → US-001 → US-002 → US-003 → US-004 → US-005 → Polish`.

## Traceability Matrix

| Source | Tasks |
|---|---|
| US-001 / FR-001–003 / NFR-001/003 | T013–T018 |
| US-002 / FR-004–006 / NFR-002 | T019–T022 |
| US-003 / FR-007–010 / NFR-004 | T023–T027 |
| US-004 / FR-011–014 / NFR-006 | T028–T032 |
| US-005 / FR-015–018 / SEC-001–003 / NFR-005 | T033–T038 |

## Checklist chất lượng

- [x] 40 task tuần tự, có path và requirement/story traceability.
- [x] Mỗi story có independent test; migration, restore, security và observability có validation task.
