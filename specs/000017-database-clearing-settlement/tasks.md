# Tasks: Nền dữ liệu bền vững từ MVP 01 đến MVP 08

**Input**: Design documents from `specs/000017-database-clearing-settlement/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/persistence.md`, `quickstart.md`

**Tests**: Unit, integration, migration smoke, contract/regression và staging restore drill là bắt buộc theo `plan.md`.

**Organization**: Task được nhóm theo user story để mỗi increment có thể kiểm tra độc lập. `exchange`, `broker` và `vsd` là ba PostgreSQL database độc lập; không tạo cross-database foreign key, join hoặc transaction.

## Phase 1: Setup (cấu trúc và công cụ dùng chung)

**Mục đích**: Chuẩn bị repository Liquibase SQL-first, cấu hình an toàn và điểm chạy migration độc lập theo database.

- [ ] T001 Tạo skeleton `flex-database/README.md`, `docker-compose.yml` và `liquibase.properties.example` mô tả ba database `exchange`, `broker`, `vsd` không chứa secret.
- [ ] T002 [P] Tạo mẫu cấu hình môi trường tại `flex-database/environments/local.properties.example`, `development.properties.example`, `staging.properties.example` và `production.properties.example`.
- [ ] T003 [P] Tạo cấu trúc seed tách production tại `flex-database/seed/{local,test}/{exchange,broker,vsd}/` và README hướng dẫn Alpha/Beta chỉ dùng local/test.
- [ ] T004 Tạo các script `flex-database/scripts/validate-all.sh`, `update-sql.sh`, `migrate.sh`, `status.sh` và `rollback.sh` nhận database mục tiêu, không hard-code connection string.
- [ ] T005 Tạo pipeline validate tại `flex-database/pipelines/database-ci.yml` chạy Liquibase `validate` và `update-sql` cho cả ba master changelog.

---

## Phase 2: Foundational (nền tảng chặn các user story)

**Mục đích**: Thiết lập master/release changelog bất biến, contract liên tổ chức và hạ tầng persistence dùng chung trước khi ghi dữ liệu nghiệp vụ.

**CRITICAL**: Hoàn tất phase này trước khi bắt đầu bất kỳ user story nào.

- [ ] T006 Tạo master changelog độc lập tại `flex-database/changelog/databases/{exchange,broker,vsd}/db.changelog-master.yaml`, chỉ include release được review.
- [ ] T007 [P] Tạo release descriptor `v1.0` cho `exchange` tại `flex-database/changelog/databases/exchange/releases/v1.0/db.changelog-v1.0.yaml` và release `v1.1` tại `flex-database/changelog/databases/exchange/releases/v1.1/db.changelog-v1.1.yaml`.
- [ ] T008 [P] Tạo release descriptor `v1.0` cho CTCK tại `flex-database/changelog/databases/broker/releases/v1.0/db.changelog-v1.0.yaml`, với giả định một database ứng với một CTCK.
- [ ] T009 [P] Tạo release descriptor `v1.0` cho VSD tại `flex-database/changelog/databases/vsd/releases/v1.0/db.changelog-v1.0.yaml`.
- [ ] T010 [P] Thiết lập thư mục `repeatable/views` và `repeatable/functions` cho từng database tại `flex-database/changelog/databases/{exchange,broker,vsd}/repeatable/`, kèm quy tắc không tự include file repeatable.
- [ ] T011 Thêm options `ExchangeDatabase`, `BrokerDatabase`, `VsdDatabase` và đăng ký `NpgsqlDataSource` riêng trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/DependencyInjection.cs`.
- [ ] T012 Tạo abstraction transaction/outbox-inbox chỉ dùng trong từng database tại `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/OrganizationDatabaseSession.cs`.
- [ ] T013 Tạo model contract external reference/correlation không phụ thuộc bảng database khác tại `flex-exchange-service/src/Flex.Exchange.Application/Persistence/ExternalBusinessReference.cs`.
- [ ] T014 Tạo contract test cho các endpoint nội bộ trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/PersistenceContractTests.cs` dựa trên `specs/000017-database-clearing-settlement/contracts/persistence.md`.
- [ ] T015 Tạo migration smoke test chạy `validate` và `update-sql` với từng master changelog tại `flex-database/tests/migration/ValidateAllDatabasesTests.ps1`.

**Checkpoint**: Ba master changelog validate được độc lập, ứng dụng có connection factory theo tổ chức và không có cơ chế join/transaction xuyên database.

---

## Phase 3: User Story 1 — Khôi phục lõi giao dịch MVP 01–04 (Priority: P1) MVP

**Goal**: Persist và rehydrate dữ liệu reference/order/history/trade của Sở giao dịch theo sequence, giữ trạng thái order và hai order nguồn của trade sau restart.

**Independent Test**:

1. Chạy migration `exchange`, tạo order có trade, sau đó khởi động lại service.
2. Đọc lại order/trade, xác nhận sequence và trạng thái pending/partial/completed/cancelled/rejected không thay đổi.
3. Xác nhận mỗi trade truy được đến hai order và broker source mà không cần database CTCK/VSD.

### Tests for User Story 1

- [ ] T016 [P] [US1] Tạo integration test migration, restart và rehydration thứ tự order/trade trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/ExchangePersistence/OrderTradeRehydrationTests.cs`.
- [ ] T017 [P] [US1] Tạo unit test sequence/lifecycle để order đã hủy hoặc hoàn tất không được rehydrate thành order chờ trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Exchange/OrderLifecycleRehydrationTests.cs`.
- [ ] T018 [P] [US1] Tạo integration test xác nhận trade giữ buy/sell order và broker external reference tại `flex-exchange-service/tests/Flex.Exchange.Api.Tests/ExchangePersistence/TradeSourceTraceTests.cs`.

### Implementation for User Story 1

- [ ] T019 [P] [US1] Tạo reference tables bằng Liquibase formatted SQL tại `flex-database/changelog/databases/exchange/releases/v1.0/001-create-reference-tables.sql`.
- [ ] T020 [P] [US1] Tạo bảng orders, tenant/broker scope, lifecycle và idempotency constraints tại `flex-database/changelog/databases/exchange/releases/v1.0/002-create-orders.sql`.
- [ ] T021 [P] [US1] Tạo bảng order history append-only theo sequence tại `flex-database/changelog/databases/exchange/releases/v1.0/003-create-order-history.sql`.
- [ ] T022 [P] [US1] Tạo bảng trades với hai order external/business references và trade sequence tại `flex-database/changelog/databases/exchange/releases/v1.0/004-create-trades.sql`.
- [ ] T023 [US1] Include `001`–`004` theo thứ tự bất biến trong `flex-database/changelog/databases/exchange/releases/v1.0/db.changelog-v1.0.yaml`.
- [ ] T024 [US1] Thêm changeset trade sequence không sửa release cũ tại `flex-database/changelog/databases/exchange/releases/v1.1/001-add-trade-sequence.sql` và include trong `db.changelog-v1.1.yaml`.
- [ ] T025 [US1] Implement SQL repository ghi order, history và trade atomically trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/ExchangePersistence/ExchangeOrderTradeRepository.cs`.
- [ ] T026 [US1] Implement rehydration deterministic theo history/trade sequence trong `flex-exchange-service/src/Flex.Exchange.Application/Exchange/RehydrateExchangeStateHandler.cs`.
- [ ] T027 [US1] Cập nhật composition root để endpoint order/trade hiện có dùng persistence mà không đổi response semantics trong `flex-exchange-service/src/Flex.Exchange.Api/Program.cs`.
- [ ] T028 [US1] Ghi `TradeExecuted` vào outbox exchange với `tradeId`, hai order ID, `brokerId`, `tenantId`, sequence và correlation tại `flex-database/changelog/databases/exchange/releases/v1.0/005-create-outbox.sql`, rồi include changeset trong `db.changelog-v1.0.yaml`.

**Checkpoint**: US1 hoàn chỉnh khi restart test pass và endpoint MVP 01–04 giữ nguyên semantics.

---

## Phase 4: User Story 2 — Vận hành broker và kiểm soát trước lệnh bền vững (Priority: P1)

**Goal**: Database CTCK riêng persist khách hàng, account và reservation idempotent, chỉ tham chiếu order/trade external từ Sở giao dịch.

**Independent Test**:

1. Chạy migration `broker`, tạo customer/account/reservation từ order source demo và khởi động lại service.
2. Gửi lại cùng source/correlation, xác nhận reservation và balance không trùng.
3. Xác nhận broker database không có foreign key hay truy vấn bảng `exchange`.

### Tests for User Story 2

- [ ] T029 [P] [US2] Tạo integration test account/reservation restart và idempotency source/correlation trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/BrokerPersistence/ReservationIdempotencyTests.cs`.
- [ ] T030 [P] [US2] Tạo constraint test chống duplicate reservation và nguồn external thiếu scope trong `flex-database/tests/constraints/BrokerReservationConstraintsTests.ps1`.
- [ ] T031 [P] [US2] Tạo regression test giữ nguyên response semantics endpoint broker MVP 05–06 trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/BrokerPersistence/BrokerEndpointRegressionTests.cs`.

### Implementation for User Story 2

- [ ] T032 [P] [US2] Tạo bảng customers scoped theo tenant trong `flex-database/changelog/databases/broker/releases/v1.0/001-create-customers.sql`.
- [ ] T033 [P] [US2] Tạo bảng accounts và balance buckets nghiệp vụ trong `flex-database/changelog/databases/broker/releases/v1.0/002-create-accounts.sql`.
- [ ] T034 [P] [US2] Tạo bảng reservations với unique source reference/correlation và external order/trade fields trong `flex-database/changelog/databases/broker/releases/v1.0/003-create-reservations.sql`.
- [ ] T035 [P] [US2] Tạo bảng inbox idempotency và outbox CTCK trong `flex-database/changelog/databases/broker/releases/v1.0/004-create-inbox.sql` và `005-create-outbox.sql`.
- [ ] T036 [US2] Include `001`–`005` theo thứ tự trong `flex-database/changelog/databases/broker/releases/v1.0/db.changelog-v1.0.yaml`.
- [ ] T037 [US2] Implement SQL adapter customer/account/reservation, gồm transaction và idempotency check, trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/BrokerPersistence/BrokerAccountReservationRepository.cs`.
- [ ] T038 [US2] Implement handler consume `TradeExecuted` theo inbox và tạo reservation chỉ từ external reference trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/ApplyTradeReservationHandler.cs`.
- [ ] T039 [US2] Cập nhật endpoint broker hiện có để read/write qua broker persistence và không join `exchange` trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/BrokerController.cs`.

**Checkpoint**: US2 hoàn chỉnh khi cùng yêu cầu không tạo reservation/balance trùng và migration broker chạy độc lập.

---

## Phase 5: User Story 3 — Ghi nhận ledger và settlement theo nguồn giao dịch (Priority: P1)

**Goal**: VSD ghi journal/entry/balance/obligation riêng, tiêu thụ clearing instruction idempotent và chỉ chuyển khả dụng sau cycle T+.

**Independent Test**:

1. Chạy migration `vsd`, gửi clearing instruction có trade/account external reference.
2. Xác nhận journal cân bằng, obligation truy vết được nguồn và không có duplicate khi replay.
3. Chạy cycle T+ hai lần, xác nhận balance chỉ chuyển available một lần khi obligation hoàn tất.

### Tests for User Story 3

- [ ] T040 [P] [US3] Tạo unit test double-entry balance và projection bucket available/reserved/receivable/payable trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Ledger/JournalBalancingTests.cs`.
- [ ] T041 [P] [US3] Tạo integration test clearing replay idempotent, obligation trace và cycle T+ trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/VsdPersistence/SettlementCycleTests.cs`.
- [ ] T042 [P] [US3] Tạo constraint test append-only journal/audit và unique clearing source tại `flex-database/tests/constraints/VsdLedgerConstraintsTests.ps1`.

### Implementation for User Story 3

- [ ] T043 [P] [US3] Tạo journals và ledger entries append-only tại `flex-database/changelog/databases/vsd/releases/v1.0/001-create-journals.sql` và `002-create-ledger-entries.sql`.
- [ ] T044 [P] [US3] Tạo balance projection buckets tại `flex-database/changelog/databases/vsd/releases/v1.0/003-create-balances.sql`.
- [ ] T045 [P] [US3] Tạo settlement obligations có external trade/order/account references và T+ lifecycle tại `flex-database/changelog/databases/vsd/releases/v1.0/004-create-obligations.sql`.
- [ ] T046 [P] [US3] Tạo inbox/outbox VSD xử lý lặp tại `flex-database/changelog/databases/vsd/releases/v1.0/007-create-inbox.sql` và `008-create-outbox.sql`.
- [ ] T047 [US3] Include `001`–`004`, `007` và `008` trong `flex-database/changelog/databases/vsd/releases/v1.0/db.changelog-v1.0.yaml`, giữ chỗ include `005`, `006`, `009` cho US4/US5.
- [ ] T048 [US3] Implement SQL adapter ghi journal/entry/balance/obligation bằng transaction trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/VsdPersistence/VsdLedgerSettlementRepository.cs`.
- [ ] T049 [US3] Implement handler replay clearing source idempotent và cycle T+ trong `flex-exchange-service/src/Flex.Exchange.Application/{Ledger,Settlement}/ProcessClearingAndSettlementHandlers.cs`.
- [ ] T050 [US3] Implement `POST /internal/ledger/replay` và `POST /internal/settlement/run` theo contract scope-protected trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/SettlementOperationsController.cs`.

**Checkpoint**: US3 hoàn chỉnh khi journal cân bằng, replay không nhân đôi effect và cycle T+ idempotent.

---

## Phase 6: User Story 4 — Đối chiếu và phục hồi dữ liệu tenant (Priority: P1)

**Goal**: VSD tiếp nhận statement, ghi kết quả matched/alert bất biến không auto-fix và chứng minh restore staging độc lập từng database.

**Independent Test**:

1. Nạp statement matched và lệch; chạy reconciliation.
2. Xác nhận alert có source/correlation, dữ liệu journal/balance nguồn không bị cập nhật tự động.
3. Restore tenant staging của mỗi database, sau đó chạy trace/reconciliation smoke.

### Tests for User Story 4

- [ ] T051 [P] [US4] Tạo integration test reconciliation matched/alert và bảo vệ journal/balance nguồn khỏi auto-fix trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Reconciliation/ReconciliationNoAutoFixTests.cs`.
- [ ] T052 [P] [US4] Tạo restore drill script backup/restore độc lập exchange, broker, vsd và trace smoke trong `flex-database/tests/restore/StagingTenantRestoreDrill.ps1`.
- [ ] T053 [P] [US4] Tạo upgrade test migration từ exchange `v1.0` đến `v1.1` không thay đổi data/history cũ trong `flex-database/tests/upgrade/ExchangeV10ToV11UpgradeTests.ps1`.

### Implementation for User Story 4

- [ ] T054 [P] [US4] Tạo statement storage tại `flex-database/changelog/databases/vsd/releases/v1.0/005-create-statements.sql`.
- [ ] T055 [P] [US4] Tạo reconciliation result và immutable alert tại `flex-database/changelog/databases/vsd/releases/v1.0/006-create-reconciliation.sql`.
- [ ] T056 [US4] Cập nhật `flex-database/changelog/databases/vsd/releases/v1.0/db.changelog-v1.0.yaml` để include `005` và `006` theo release order.
- [ ] T057 [US4] Implement SQL adapter statement/reconciliation không tự sửa source journal/balance trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/VsdPersistence/VsdReconciliationRepository.cs`.
- [ ] T058 [US4] Implement reconciliation operation và `POST /internal/reconciliation/run` trong `flex-exchange-service/src/Flex.Exchange.Application/Reconciliation/RunReconciliationHandler.cs` và `flex-exchange-service/src/Flex.Exchange.Api/Controllers/ReconciliationOperationsController.cs`.
- [ ] T059 [US4] Tạo seed Alpha/Beta idempotent cho trace order→trade→account→ledger→obligation→statement tại `flex-database/seed/test/{exchange,broker,vsd}/alpha-beta.sql`.

**Checkpoint**: US4 hoàn chỉnh khi alert là bằng chứng bất biến, không có auto-fix và restore drill pass.

---

## Phase 7: User Story 5 — Bảo vệ và kiểm tra phạm vi dữ liệu (Priority: P1)

**Goal**: Mọi read/write/replay/recovery kiểm tra tenant/broker scope, audit vận hành và trả health/trace mà không lộ dữ liệu ngoài phạm vi.

**Independent Test**:

1. Gọi trace/health/replay/recovery bằng scope A với references thuộc scope B.
2. Xác nhận response bị từ chối hoặc không tìm thấy, không chứa thông tin B.
3. Xác nhận operator đúng scope xem được health/backlog/DLQ/restore state và audit phù hợp.

### Tests for User Story 5

- [ ] T060 [P] [US5] Tạo API integration test cross-tenant/broker denial và non-disclosure cho trace/health/operations trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/PersistenceScopeAuthorizationTests.cs`.
- [ ] T061 [P] [US5] Tạo API integration test trace/health theo scope và contract regression trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/PersistenceTraceHealthTests.cs`.
- [ ] T062 [P] [US5] Tạo audit/log assertion không ghi secret hoặc statement đầy đủ trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/Persistence/PersistenceAuditLoggingTests.cs`.

### Implementation for User Story 5

- [ ] T063 [US5] Tạo bảng audit append-only cho replay, settlement, reconciliation, alert, initialization và recovery tại `flex-database/changelog/databases/vsd/releases/v1.0/009-create-audit.sql`.
- [ ] T064 [US5] Include `009-create-audit.sql` trong `flex-database/changelog/databases/vsd/releases/v1.0/db.changelog-v1.0.yaml` sau inbox/outbox.
- [ ] T065 [US5] Implement tenant/broker scope guard dùng trước mọi persistence read/write/replay/recovery trong `flex-exchange-service/src/Flex.Exchange.Application/Persistence/PersistenceScopeGuard.cs`.
- [ ] T066 [US5] Implement audit writer với action/result/source/correlation và redaction dữ liệu nhạy cảm trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/VsdPersistence/VsdAuditWriter.cs`.
- [ ] T067 [US5] Implement `GET /internal/persistence/trace` tổng hợp theo external IDs/correlation, không join database, trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/PersistenceTraceController.cs`.
- [ ] T068 [US5] Implement `GET /internal/persistence/health` trả migration readiness, backlog, DLQ, projection lag và restore state trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/PersistenceHealthController.cs`.
- [ ] T069 [US5] Thêm metrics rehydration, duplicate/conflict, backlog/DLQ, projection lag, T+ và reconciliation alert trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Observability/PersistenceMetrics.cs`.

**Checkpoint**: US5 hoàn chỉnh khi scope denial test, audit/log assertion và health/trace contract test đều pass.

---

## Phase 8: Polish & cross-cutting concerns

**Mục đích**: Xác nhận triển khai production-ready theo rollout/rollback, test matrix và quickstart.

- [ ] T070 [P] Cập nhật hướng dẫn vận hành và thứ tự migration exchange→broker→vsd trong `flex-database/README.md`.
- [ ] T071 [P] Cập nhật test matrix và lệnh validation trong `specs/000017-database-clearing-settlement/quickstart.md`.
- [ ] T072 Chạy migration smoke, PostgreSQL integration và API/domain test theo CI tại `flex-database/pipelines/database-ci.yml` và `flex-exchange-service/tests/`.
- [ ] T073 Ghi rollback/forward-fix và restore decision log cho từng database trong `flex-database/README.md`.
- [ ] T074 Thực hiện security review endpoint persistence để không lộ scope khác qua response, lỗi, trace hoặc log trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/`.
- [ ] T075 Thực hiện staging rollout: backup, migrate exchange→broker→vsd, contract smoke, deploy và restore drill theo `specs/000017-database-clearing-settlement/quickstart.md`.

---

## Dependencies & execution order

### Phase dependencies

- Phase 1 không có dependency.
- Phase 2 phụ thuộc Phase 1 và chặn toàn bộ user story.
- US1 bắt đầu sau Phase 2.
- US2 phụ thuộc T028 để có `TradeExecuted` contract; không truy vấn database `exchange`.
- US3 phụ thuộc US1 và US2 có external trade/account reference hợp lệ; không tạo cross-database FK/transaction.
- US4 phụ thuộc US3 có journal/obligation để đối chiếu.
- US5 dùng các adapter/operation của US1–US4 để áp scope/audit/trace đầy đủ.
- Phase 8 phụ thuộc mọi user story.

### User story completion order

`Setup → Foundation → US1 → US2 → US3 → US4 → US5 → Polish`

### Parallel opportunities

- T002–T003 có thể chạy song song; T007–T010 và T014–T015 cũng có thể chạy song song sau T006.
- Trong mỗi story, các test `[P]` và các SQL schema task `[P]` chạy song song vì chỉnh file khác nhau.
- Không chạy song song task include changelog với SQL file mà nó include; không chạy song song task cùng controller/repository.

## Parallel example: User Story 3

```text
Task: "Tạo unit test double-entry balance trong flex-exchange-service/tests/Flex.Exchange.Domain.Tests/Ledger/JournalBalancingTests.cs"
Task: "Tạo integration test clearing replay trong flex-exchange-service/tests/Flex.Exchange.Api.Tests/VsdPersistence/SettlementCycleTests.cs"
Task: "Tạo journals/ledger entries trong flex-database/changelog/databases/vsd/releases/v1.0/001-create-journals.sql và 002-create-ledger-entries.sql"
Task: "Tạo balance projection trong flex-database/changelog/databases/vsd/releases/v1.0/003-create-balances.sql"
```

## Implementation strategy

### MVP first

1. Hoàn tất Phase 1 và Phase 2.
2. Hoàn tất US1, chạy restart/rehydration và endpoint regression test.
3. Dừng để validate persistence nguồn giao dịch trước khi mở rộng sang CTCK/VSD.

### Incremental delivery

1. US1 tạo nguồn order/trade bền vững.
2. US2 thêm account/reservation trong database CTCK độc lập.
3. US3 thêm ledger/settlement VSD từ external references.
4. US4 thêm reconciliation/restore.
5. US5 đóng scope, audit, health và trace.

## Validation commands

- Migration validation: `flex-database/scripts/validate-all.sh`
- Review generated SQL: `flex-database/scripts/update-sql.sh`
- Migration theo ownership: `flex-database/scripts/migrate.sh exchange`, rồi `broker`, rồi `vsd`
- Trạng thái migration: `flex-database/scripts/status.sh <database>`
- Rollback/restore playbook: `flex-database/scripts/rollback.sh <database>`
- API/domain tests: `dotnet test flex-exchange-service/tests`

## Traceability matrix

| Source | Covered by tasks |
|---|---|
| US-001, FR-001–003, BR-001/002, NFR-001/003 | T016–T028 |
| US-002, FR-004–006, BR-003, NFR-002 | T029–T039 |
| US-003, FR-007–010, BR-004/005, NFR-004 | T040–T050 |
| US-004, FR-011–014, BR-006, NFR-006 | T051–T059 |
| US-005, FR-015–018, BR-007, SEC-001–003, NFR-005 | T060–T069 |
| Liquibase SQL-first, tách ba database, seed non-production | T001–T015, T019–T024, T032–T036, T043–T047, T054–T056, T063–T064 |
| Rollout, rollback, observability | T004–T005, T052–T053, T069–T075 |

## Checklist chất lượng trước khi implement

- [x] Không có placeholder hoặc task ví dụ.
- [x] Task đánh số tuần tự từ `T001` đến `T075`.
- [x] Mọi task có checklist, ID và path/command cụ thể.
- [x] Mỗi user story có phase, independent test và checkpoint riêng.
- [x] Migration, idempotency, compatibility, scope, audit, observability và restore đều có validation task.
- [x] Task `[P]` không cùng sửa một file và không phụ thuộc nhau.
