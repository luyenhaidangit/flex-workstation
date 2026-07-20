# Tasks: Migrate dữ liệu HNX khỏi in-memory

**Đầu vào**: Design documents từ `specs/000018-hnx-data-migration/`

**Chiến lược**: MVP là `US1` inventory + migrate HNX reference data; sau đó `US2` dual-read/cutover và `US3` reconciliation/progress.

## Phase 1: Setup

**Mục đích**: Chuẩn bị cấu hình, inventory và baseline validation cho các repo liên quan.

- [ ] T001 [P] Ghi inventory FE/BE/DB cho HNX reference data, nguồn hiện tại, consumer và owner trong `specs/000018-hnx-data-migration/research.md` (FR-001, FR-002, FR-003).
- [ ] T002 [P] Kiểm tra baseline .NET/Angular/database bằng `dotnet test --configuration Release` tại `flex-exchange-service/`, `npm test -- --watch=false` tại `flex-microfrontend/` và `liquibase --changelog-file=changelog/db.changelog-master.xml validate` tại `flex-database/hnx/`; lưu command/result vào `specs/000018-hnx-data-migration/quickstart.md`.
- [ ] T003 [P] Xác định dữ liệu seed HNX hợp lệ và stable `instrument_id` trong `flex-database/hnx/README.md` hoặc artifact seed hiện hành, không ghi secret/connection string.

## Phase 2: Foundational

**Mục đích**: Tạo nền tảng persistence/config/telemetry dùng chung, chặn các user story phía sau.

- [ ] T004 Tạo application model và port đọc/upsert HNX reference data trong `flex-exchange-service/src/Flex.Exchange.Application/Hnx/ReferenceData/IHnxReferenceDataStore.cs` (FR-003, FR-005, BR-001).
- [ ] T005 [P] Tạo source mode enum/options `LegacyOnly`, `DualRead`, `Database` trong `flex-exchange-service/src/Flex.Exchange.Application/Hnx/ReferenceData/HnxReferenceDataOptions.cs` với validation giá trị và default `LegacyOnly` (FR-004, NFR-002).
- [ ] T006 [P] Tạo canonical HNX instrument model và comparison result trong `flex-exchange-service/src/Flex.Exchange.Application/Hnx/ReferenceData/HnxInstrumentModels.cs` (FR-001, FR-008, BR-002).
- [ ] T007 [P] Tạo Liquibase release changeset/seed forward-only cho `exchange_instruments` nếu baseline inventory xác định còn thiếu dữ liệu trong `flex-database/hnx/changelog/releases/1.0.0.0/` hoặc release mới, không sửa changeset đã chạy (FR-004, BR-001).
- [ ] T008 Tạo PostgreSQL options/connection factory và focused adapter cho `exchange_instruments` trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/Hnx/HnxReferenceDataStore.cs` (phụ thuộc T004, T006; FR-004, BR-004).
- [ ] T009 Tích hợp Npgsql HNX adapter và source options vào DI/configuration trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/DependencyInjection.cs` và `flex-exchange-service/src/Flex.Exchange.Api/Extensions/ServiceExtensions.cs` (phụ thuộc T005, T008).
- [ ] T010 [P] Thêm structured telemetry fields/events cho reference match, mismatch, DB failure, duration và cutover trong `flex-exchange-service/src/Flex.Exchange.Application/Hnx/ReferenceData/HnxReferenceDataTelemetry.cs` (FR-008, SEC-002, NFR-002).
- [ ] T011 Tạo recovery note cho Liquibase forward-fix, config rollback về `LegacyOnly` và điều kiện không được drop/recreate bảng trong `specs/000018-hnx-data-migration/rollback.md` (FR-006, FR-007).

## Phase 3: User Story 1 — Rà soát và migrate HNX reference data (P1) — MVP

**Goal**: Có inventory được xác nhận và dữ liệu HNX reference data tồn tại bền vững trong DB mà public exchange flow không đổi.

**Independent Test**:

1. Chạy Liquibase validate/update-sql và seed/upsert một bộ HNX instruments.
2. Gọi exchange read flow trước/sau restart BE với mode `LegacyOnly` hoặc DB source đã được bật theo acceptance.
3. Kiểm tra count, unique symbol, stable identity và payload FE không đổi.

### Tests for User Story 1

- [ ] T012 [P] [US1] Viết unit tests cho canonicalization, required fields, market HNX và comparison key trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/HnxReferenceDataTests.cs` (AC-001, BR-001, BR-002).
- [ ] T013 [P] [US1] Viết PostgreSQL integration tests cho `exchange_instruments` schema, unique symbol, stable identity và idempotent upsert trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/HnxReferenceDataPersistenceTests.cs` (AC-003, AC-004, SC-004).
- [ ] T014 [P] [US1] Viết migration validation test chạy Liquibase validate/update-sql và kiểm tra seed HNX trong `flex-database/tests/hnx-reference-data-validation.ps1` (AC-001, FR-004).
- [ ] T015 [P] [US1] Viết FE/API regression test bảo đảm exchange payload/status hiện tại không đổi khi reference source thay đổi trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/HnxReferenceDataContractTests.cs` và `flex-microfrontend/src/app/exchange/exchange-api.service.spec.ts` (AC-003, NFR-001).

### Implementation for User Story 1

- [ ] T016 [P] [US1] Implement HNX instrument validation và stable-identity mapping trong `flex-exchange-service/src/Flex.Exchange.Application/Hnx/ReferenceData/HnxInstrumentModels.cs` (phụ thuộc T006; FR-001, FR-002, BR-001).
- [ ] T017 [US1] Implement idempotent PostgreSQL read/upsert cho `exchange_instruments` trong `flex-exchange-service/src/Flex.Exchange.Infrastructure/Persistence/Hnx/HnxReferenceDataStore.cs` (phụ thuộc T008, T013; FR-004, FR-007, SC-004).
- [ ] T018 [US1] Wire HNX reference-data port vào exchange read use case hiện đang lấy instrument/order-book data trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` (phụ thuộc T004, T009, T016; FR-003, FR-005).
- [ ] T019 [US1] Đăng ký options, connection validation và DI lifetime an toàn cho HNX store trong `flex-exchange-service/src/Flex.Exchange.Api/Extensions/ServiceExtensions.cs` (phụ thuộc T005, T009; SEC-001, NFR-002).
- [ ] T020 [US1] Chạy seed/backfill HNX reference data theo quickstart và ghi số lượng trước/sau, duplicate check, restart result trong `specs/000018-hnx-data-migration/quickstart.md` (phụ thuộc T007, T014, T017; AC-003, AC-004).

**Definition of Done**:

- Inventory HNX reference data có owner/source/consumer.
- `exchange_instruments` seed/upsert idempotent và integration test pass.
- Luồng FE/BE hiện tại không đổi contract và dữ liệu không mất sau restart.

## Phase 4: User Story 2 — Dual-read và cutover có kiểm soát (P1)

**Goal**: Đối chiếu legacy với DB trước khi chuyển nguồn phục vụ chính sang DB, có fallback và rollback config.

**Dependencies**: Phụ thuộc toàn bộ Phase 2 và US1 T016–T019.

**Independent Test**:

1. Chạy `DualRead` với dữ liệu khớp và xác nhận match/cùng payload.
2. Tạo mismatch hoặc DB timeout và xác nhận không cutover, fallback đúng policy, có telemetry.
3. Bật `Database`, restart BE và xác nhận dữ liệu HNX vẫn phục vụ; đổi lại `LegacyOnly` để rollback.

### Tests for User Story 2

- [ ] T021 [P] [US2] Viết unit tests cho `LegacyOnly`, `DualRead`, `Database`, mismatch và fallback policy trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/HnxReferenceDataSourcePolicyTests.cs` (AC-005, FR-006, FR-007).
- [ ] T022 [P] [US2] Viết integration tests cho dual-read match/mismatch, bounded DB timeout và no-fallback ở `Database` mode trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/HnxReferenceDataDualReadTests.cs` (AC-005, FR-005, FR-006).
- [ ] T023 [P] [US2] Viết contract tests cho existing exchange endpoints ở cả ba source modes trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/HnxReferenceDataContractTests.cs` (AC-003, NFR-001).
- [ ] T024 [P] [US2] Viết configuration/permission negative tests cho invalid mode, unauthorized cutover và HNX scope trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/HnxReferenceDataSecurityTests.cs` (SEC-001, SEC-002).

### Implementation for User Story 2

- [ ] T025 [US2] Implement legacy adapter và `DualRead` comparison orchestration trong `flex-exchange-service/src/Flex.Exchange.Application/Hnx/ReferenceData/HnxReferenceDataReader.cs` (phụ thuộc T004, T006, T016, T021; FR-005, FR-006).
- [ ] T026 [US2] Implement mismatch/failure outcome và bounded timeout handling trong `flex-exchange-service/src/Flex.Exchange.Application/Hnx/ReferenceData/HnxReferenceDataReader.cs` (phụ thuộc T025; AC-005, FR-006, FR-007).
- [ ] T027 [US2] Áp dụng source-mode policy vào exchange read path mà không đổi public DTO trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` (phụ thuộc T018, T025, T022; FR-005, NFR-001).
- [ ] T028 [US2] Thêm config binding/validation và runtime rollback switch cho `Hnx:ReferenceDataSourceMode` trong `flex-exchange-service/src/Flex.Exchange.Api/Extensions/ServiceExtensions.cs` và `flex-exchange-service/src/Flex.Exchange.Api/appsettings.json` (phụ thuộc T005, T019, T024; FR-004, SEC-001).
- [ ] T029 [US2] Emit match/mismatch/failure/cutover telemetry với correlation và không log secret trong `flex-exchange-service/src/Flex.Exchange.Application/Hnx/ReferenceData/HnxReferenceDataTelemetry.cs` (phụ thuộc T010, T026; FR-008, NFR-002).
- [ ] T030 [US2] Thực hiện rollout validation `LegacyOnly → DualRead → Database` và config rollback theo `specs/000018-hnx-data-migration/quickstart.md` (phụ thuộc T022, T023, T028, T029; AC-004, AC-005).

**Definition of Done**:

- Dual-read mismatch không được đánh dấu thành công/cutover.
- Contract FE/BE pass ở cả ba modes.
- Config rollback về `LegacyOnly` phục hồi luồng an toàn.

## Phase 5: User Story 3 — Đối chiếu và theo dõi tiến độ (P2)

**Goal**: Reviewer xem được kết quả đối chiếu, trạng thái migration và sai lệch cần xử lý.

**Dependencies**: Phụ thuộc US2 T025–T030 để có comparison result và telemetry.

**Independent Test**:

1. Chạy reconciliation với dữ liệu khớp và kiểm tra trạng thái `Matched`.
2. Chạy với dữ liệu khác biệt và kiểm tra nhóm, counts, reason, correlation.
3. Kiểm tra status không chuyển `Completed` khi còn mismatch blocker.

### Tests for User Story 3

- [ ] T031 [P] [US3] Viết unit tests cho comparison result counts/status transitions `Matched`, `Mismatch`, `Failed` trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/HnxReferenceDataReconciliationTests.cs` (AC-006, AC-007, BR-002, BR-003).
- [ ] T032 [P] [US3] Viết integration test cho audit/structured telemetry fields và correlation khi mismatch trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/HnxReferenceDataObservabilityTests.cs` (FR-008, SEC-002, NFR-002).
- [ ] T033 [P] [US3] Viết manual reconciliation validation với query count/key/attribute và status report trong `specs/000018-hnx-data-migration/quickstart.md` (AC-006, AC-007).

### Implementation for User Story 3

- [ ] T034 [US3] Tạo reconciliation result/status model và transition rules trong `flex-exchange-service/src/Flex.Exchange.Application/Hnx/ReferenceData/HnxReferenceDataReconciliation.cs` (phụ thuộc T006, T025, T031; FR-008, FR-009, BR-002, BR-003).
- [ ] T035 [US3] Gắn reconciliation result vào comparison orchestration và telemetry trong `flex-exchange-service/src/Flex.Exchange.Application/Hnx/ReferenceData/HnxReferenceDataReader.cs` (phụ thuộc T029, T034; AC-006, AC-007).
- [ ] T036 [US3] Tạo operator diagnostic endpoint hoặc internal operation cho migration status theo permission matrix trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/HnxReferenceDataController.cs` (phụ thuộc T024, T034; FR-009, SEC-001).
- [ ] T037 [US3] Thêm contract/documentation test cho diagnostic result và không expose secret/sensitive payload trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/HnxReferenceDataObservabilityTests.cs` (phụ thuộc T036; SEC-002).

**Definition of Done**:

- Reviewer phân biệt được matched/mismatch/failed và nhóm còn in-memory.
- Mismatch blocker không thể chuyển trạng thái hoàn tất.
- Audit/telemetry có correlation và không lộ secret.

## Final Phase: Polish & Cross-Cutting Concerns

- [ ] T038 [P] Chạy `liquibase validate` và `update-sql`, review changeset bất biến/forward-only trong `flex-database/hnx/changelog/db.changelog-master.xml` (BR-004, release safety).
- [ ] T039 [P] Chạy `dotnet restore` và `dotnet test --configuration Release` cho `flex-exchange-service/`, xử lý failure thuộc feature trong test artifacts (NFR-001, Test Gate).
- [ ] T040 [P] Chạy Angular exchange unit tests từ `flex-microfrontend/` và kiểm tra `flex-microfrontend/src/app/exchange/exchange-api.service.ts` không cần breaking change (NFR-001).
- [ ] T041 Kiểm tra structured logs/metrics không chứa token, password, connection string hoặc payload nhạy cảm trong `flex-exchange-service/src/Flex.Exchange.Application/Hnx/ReferenceData/` (SEC-002).
- [ ] T042 Chạy toàn bộ quickstart validation và ghi kết quả/release guardrails trong `specs/000018-hnx-data-migration/quickstart.md` (SC-001, SC-002, SC-003, SC-004, SC-005).
- [ ] T043 Cập nhật review/convergence note nếu inventory phát hiện gap ngoài reference data trong `specs/000018-hnx-data-migration/research.md` (FR-010, scope control).

## Dependencies & Execution Order

### Phase Dependencies

- Setup T001–T003 có thể chạy song song.
- Foundational T004–T011 bắt đầu sau inventory/baseline phù hợp; T008 phụ thuộc T004/T006, T009 phụ thuộc T005/T008.
- US1 bắt đầu sau T004–T011; MVP checkpoint sau T020.
- US2 phụ thuộc US1 vì cần reference store/read path; checkpoint sau T030.
- US3 phụ thuộc US2 vì cần comparison result/telemetry; checkpoint sau T037.
- Polish T038–T043 sau các story liên quan hoàn tất.

### Parallel Opportunities

- T001, T002, T003 độc lập.
- T005, T006, T007, T010 có thể chạy song song sau baseline; không đánh dấu các task cùng file.
- T012–T015 là test-first, có thể chạy song song vì khác file.
- T021–T024 là test-first, có thể chạy song song nhưng T023 cùng file với T015 nên phải tích hợp tuần tự theo file.
- T031–T033 có thể chạy song song.
- T038–T041 có thể chạy song song sau implementation; T042 cần các validation trước đó.

## Traceability Matrix

| Source | Covered by tasks |
|---|---|
| US-001 / FR-001..003 | T001, T004, T006, T012, T016, T018 |
| US-001 / AC-001..002 | T001, T012, T014, T016 |
| US-002 / FR-004..007 | T007, T008, T013, T017, T020, T021, T022, T025–T030 |
| US-002 / AC-003..005 | T013, T015, T020, T021–T023, T030 |
| US-003 / FR-008..009 | T010, T029, T031–T037 |
| US-003 / AC-006..007 | T031–T037 |
| BR-001..004 | T003, T007, T012–T014, T017, T031, T038 |
| SEC-001..002 | T019, T024, T028–T029, T036–T037, T041 |
| NFR-001..003 | T015, T022–T023, T030, T039–T042 |
| Rollout/rollback/observability | T011, T028–T030, T038, T041–T042 |

## Validation Commands

- Database validation: `liquibase --changelog-file=changelog/db.changelog-master.xml validate` tại `flex-database/hnx`.
- SQL preview: `liquibase --changelog-file=changelog/db.changelog-master.xml update-sql` tại `flex-database/hnx`.
- Backend restore/test: `dotnet restore` và `dotnet test --configuration Release` tại `flex-exchange-service`.
- Frontend exchange tests: `npm test -- --watch=false` tại `flex-microfrontend`.
- Smoke: các request trong `flex-exchange-service/src/Flex.Exchange.Api/Flex.Exchange.http` và các bước `specs/000018-hnx-data-migration/quickstart.md`.

## Implementation Strategy

### MVP First

1. Hoàn tất T001–T011.
2. Viết test trước T012–T015, sau đó thực hiện T016–T020.
3. STOP và validate US1: HNX reference data bền vững, idempotent, không đổi FE/BE contract, restart không mất dữ liệu.

### Incremental Delivery

1. US1: reference-data persistence và inventory.
2. US2: dual-read/cutover/rollback.
3. US3: reconciliation/status/audit.
4. Chỉ sau khi các checkpoint pass mới lập feature riêng cho order, trade, outbox hoặc runtime state.

## Checklist chất lượng trước khi implement

- [x] Không còn task ví dụ hoặc placeholder trong output cuối.
- [x] Không còn `TXXX`, `Phase N` hoặc phase user story không tồn tại.
- [x] Toàn bộ task được đánh số tuần tự từ `T001` đến `T043`.
- [x] Mỗi task có path cụ thể hoặc command cụ thể.
- [x] Task phụ thuộc task khác đã ghi rõ dependency task ID.
- [x] Mỗi user story có Independent Test và Definition of Done.
- [x] Test Gate phủ risks: schema/DB, duplicate, mismatch, timeout, contract, permission, telemetry, restart và rollout.
- [x] Traceability Matrix map US/FR/AC/BR/SEC/NFR sang task IDs.
- [x] Migration, permission, contract, observability, rollout/rollback có task.
- [x] Không đánh dấu `[P]` cho task cùng file hoặc có dependency trực tiếp.
