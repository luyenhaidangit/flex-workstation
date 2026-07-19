# Tasks: Persistence theo tổ chức HoSE/HNX, CTCK và VSD

## Phase 1: Setup

- [ ] T001 Thêm `Npgsql` vào `flex-exchange-service/src/Flex.Exchange.Infrastructure/Flex.Exchange.Infrastructure.csproj`.
- [ ] T002 Tạo mẫu configuration connection riêng cho `exchange`, `broker`, `vsd` trong `flex-exchange-service/src/Flex.Exchange.Api/appsettings.json`.
- [ ] T003 Tạo `liquibase.properties.example` với master changelog chọn theo database trong `flex-database/liquibase.properties.example`.

## Phase 2: Foundational — Liquibase và contract xuyên tổ chức

- [ ] T004 Tạo master changelog `exchange` trong `flex-database/changelog/databases/exchange/db.changelog-master.yaml`.
- [ ] T005 [P] Tạo master changelog `broker` trong `flex-database/changelog/databases/broker/db.changelog-master.yaml`.
- [ ] T006 [P] Tạo master changelog `vsd` trong `flex-database/changelog/databases/vsd/db.changelog-master.yaml`.
- [ ] T007 Tạo contract `TradeExecuted` và `ClearingInstruction` dùng external IDs/correlation trong `specs/000017-database-clearing-settlement/contracts/persistence.md`.
- [ ] T008 Tạo `OrganizationPersistenceOptions` trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/OrganizationPersistenceOptions.cs`.
- [ ] T009 Tạo outbox/inbox envelope chung trong `flex-exchange-service/src/Flex.Exchange.Application/Persistence/OrganizationMessage.cs`.
- [ ] T010 Viết Liquibase validate/update-sql smoke cho ba master changelog trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/LiquibaseOrganizationTests.cs`.

## Phase 3: US-001 — HoSE/HNX: order và trade

**Independent Test**: Restart `exchange` vẫn rehydrate order/trade theo sequence và công bố đúng `TradeExecuted`.

- [ ] T011 [P] [US1] Tạo release changelog order/trade trong `flex-database/changelog/databases/exchange/releases/v1.0/db.changelog-v1.0.yaml`.
- [ ] T012 [P] [US1] Tạo Liquibase formatted SQL reference/order/history/trade trong `flex-database/changelog/databases/exchange/releases/v1.0/001-create-exchange-core.sql`.
- [ ] T013 [P] [US1] Viết rehydration sequence test trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Persistence/ExchangeRehydrationTests.cs` cho FR-001/002/NFR-003.
- [ ] T014 [US1] Tạo `ExchangePersistenceRepository` trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/ExchangePersistence/ExchangePersistenceRepository.cs` (phụ thuộc T011, T012, T008).
- [ ] T015 [US1] Tạo `ExchangeStateRehydrator` trong `flex-exchange-service/src/Flex.Exchange.Application/Exchange/ExchangeStateRehydrator.cs` (phụ thuộc T013, T014).
- [ ] T016 [US1] Ghi `TradeExecuted` vào exchange outbox trong `flex-exchange-service/src/Flex.Exchange.Application/Exchange/ExchangeTradePublisher.cs` (phụ thuộc T007, T009, T014).
- [ ] T017 [US1] Viết restart và `TradeExecuted` contract integration test trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/ExchangePersistenceTests.cs` (phụ thuộc T015, T016).

## Phase 4: US-002 — CTCK: account và reservation

**Independent Test**: Broker consume trade/order reference, tạo reservation idempotent và không truy cập database `exchange`.

- [ ] T018 [P] [US2] Tạo release changelog account/reservation trong `flex-database/changelog/databases/broker/releases/v1.0/db.changelog-v1.0.yaml`.
- [ ] T019 [P] [US2] Tạo Liquibase formatted SQL customer/account/reservation/inbox/outbox trong `flex-database/changelog/databases/broker/releases/v1.0/001-create-broker-core.sql`.
- [ ] T020 [P] [US2] Viết reservation duplicate/external-reference test trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Persistence/BrokerReservationTests.cs` cho FR-004–006/NFR-002.
- [ ] T021 [US2] Tạo `BrokerPersistenceRepository` trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/BrokerPersistence/BrokerPersistenceRepository.cs` (phụ thuộc T018, T019, T008).
- [ ] T022 [US2] Tạo `BrokerTradeConsumer` consume `TradeExecuted` qua inbox trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/BrokerTradeConsumer.cs` (phụ thuộc T007, T009, T020, T021).
- [ ] T023 [US2] Viết integration test broker không join `exchange` và reservation restart-safe trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/BrokerPersistenceTests.cs` (phụ thuộc T017, T022).

## Phase 5: US-003 — VSD: ledger và settlement

**Independent Test**: VSD consume clearing instruction, tạo journal cân bằng/T+ theo external trade/account reference.

- [ ] T024 [P] [US3] Tạo release changelog ledger/settlement trong `flex-database/changelog/databases/vsd/releases/v1.0/db.changelog-v1.0.yaml`.
- [ ] T025 [P] [US3] Tạo Liquibase formatted SQL journal/entry/balance/inbox/outbox/audit/obligation trong `flex-database/changelog/databases/vsd/releases/v1.0/001-create-vsd-core.sql`.
- [ ] T026 [P] [US3] Viết ledger balance/T+ external-reference test trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Persistence/VsdLedgerSettlementTests.cs` cho FR-007–010/NFR-004.
- [ ] T027 [US3] Tạo `VsdPersistenceRepository` trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/VsdPersistence/VsdPersistenceRepository.cs` (phụ thuộc T024, T025, T008).
- [ ] T028 [US3] Tạo `VsdClearingConsumer` consume `ClearingInstruction` qua inbox trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/VsdClearingConsumer.cs` (phụ thuộc T007, T009, T026, T027).
- [ ] T029 [US3] Cập nhật `SettlementService` dùng VSD repository và cycle idempotent trong `flex-exchange-service/src/Flex.Exchange.Application/Settlement/SettlementService.cs` (phụ thuộc T027, T028).
- [ ] T030 [US3] Viết integration trace trade reference→journal→obligation trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/VsdLedgerSettlementTests.cs` (phụ thuộc T023, T029).

## Phase 6: US-004 — VSD reconciliation và restore

**Independent Test**: Statement đúng/lệch tạo matched/alert; restore `vsd` vẫn reconcile theo reference.

- [ ] T031 [P] [US4] Tạo Liquibase formatted SQL statement/result/alert trong `flex-database/changelog/databases/vsd/releases/v1.0/002-create-vsd-reconciliation.sql`.
- [ ] T032 [P] [US4] Viết reconciliation no-auto-fix test trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Persistence/VsdReconciliationTests.cs`.
- [ ] T033 [US4] Tạo `VsdReconciliationRepository` trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/VsdPersistence/VsdReconciliationRepository.cs` (phụ thuộc T031, T027).
- [ ] T034 [US4] Cập nhật `ReconciliationService` append-only trong `flex-exchange-service/src/Flex.Exchange.Application/Reconciliation/ReconciliationService.cs` (phụ thuộc T032, T033).
- [ ] T035 [US4] Chạy restore drill `exchange`/`broker`/`vsd` và contract smoke trong `specs/000017-database-clearing-settlement/quickstart.md` (phụ thuộc T023, T030, T034).

## Phase 7: US-005 — Scope, audit, health và trace

**Independent Test**: Trace/health đọc từng boundary qua contract, cross-scope bị chặn và audit không lộ secret.

- [ ] T036 [P] [US5] Viết cross-scope/cross-organization security test trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/OrganizationScopeTests.cs`.
- [ ] T037 [P] [US5] Viết trace/health contract test trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/OrganizationTraceHealthTests.cs`.
- [ ] T038 [US5] Tạo `OrganizationAuditWriter` trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/OrganizationAuditWriter.cs` (phụ thuộc T025, T027).
- [ ] T039 [US5] Tạo internal trace/health endpoint tổng hợp contract trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/OrganizationPersistenceController.cs` (phụ thuộc T007, T036, T037, T038).
- [ ] T040 [US5] Bổ sung metrics cho từng database, inbox/outbox và restore trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/OrganizationPersistenceTelemetry.cs` (phụ thuộc T039).

## Final Phase

- [ ] T041 Cập nhật lệnh Liquibase ba database và kết quả validation trong `specs/000017-database-clearing-settlement/quickstart.md` (phụ thuộc T010, T035, T040).
- [ ] T042 Chạy domain/API tests, lưu kết quả trong `specs/000017-database-clearing-settlement/quickstart.md` (phụ thuộc T017, T023, T030, T035, T040).

## Dependencies & Execution Order

`Setup → Foundational → US-001 (exchange) → US-002 (broker) → US-003 (vsd) → US-004 → US-005 → Polish`.

## Traceability Matrix

| Source | Tasks |
|---|---|
| US-001 / FR-001–003 / NFR-001/003 | T011–T017 |
| US-002 / FR-004–006 / NFR-002 | T018–T023 |
| US-003 / FR-007–010 / NFR-004 | T024–T030 |
| US-004 / FR-011–014 / NFR-006 | T031–T035 |
| US-005 / FR-015–018 / SEC-001–003 / NFR-005 | T036–T040 |
