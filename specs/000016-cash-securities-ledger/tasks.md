# Tasks: Ledger tiền và chứng khoán

**Input**: `specs/000016-cash-securities-ledger/spec.md`, `plan.md`, `data-model.md`, `contracts/ledger.md`, `research.md`, `quickstart.md`

**Mục tiêu**: triển khai MVP07 bằng append-only in-memory double-entry ledger, giữ tương thích các Broker/Exchange API hiện có.

## Phase 1: Setup

**Mục đích**: chuẩn bị module, cấu hình và bộ test cho feature.

- [x] T001 [P] Tạo thư mục `flex-exchange-service/src/Flex.Exchange.Application/Ledger/` và đăng ký namespace/module theo cấu trúc Application hiện có
- [x] T002 [P] Tạo khung test ledger trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/LedgerInvariantTests.cs` và `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerApiTests.cs`
- [x] T003 [P] Thêm các key `Ledger:Enabled` và `Ledger:DemoOpeningEntries` vào `flex-exchange-service/src/Flex.Exchange.Api/appsettings.Development.json`

## Phase 2: Foundational

**Mục đích**: hoàn tất các invariant và dependency injection dùng chung trước mọi user story.

- [x] T004 Tạo các value type/entity `LedgerEntry`, `Journal`, `LedgerAccountBalance` trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/` với `TenantId`, asset, bucket, debit/credit, source reference và timestamp
- [x] T005 Tạo `ILedgerService` và `LedgerTransitionFactory` trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/` cho append journal, query balance/trace và tạo reversal/adjustment
- [x] T006 Tạo `BalanceProjector` trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/` để derive bốn bucket `available`, `reserved`, `receivable`, `payable` từ entries
- [x] T007 Implement `InMemoryLedgerService` trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/InMemoryLedgerService.cs` với atomic validate → idempotency lookup → append → project dưới một lock
- [x] T008 Đăng ký `ILedgerService`/`InMemoryLedgerService` và feature flag trong composition root của `flex-exchange-service/src/Flex.Exchange.Api/Program.cs`
- [x] T009 [P] Viết unit test invariant journal cân bằng (BR-001), entry bất biến, thiếu source/tenant và non-negative bucket trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/LedgerInvariantTests.cs`
- [x] T010 [P] Viết unit test idempotency theo `TenantId + SourceReference + EventType`, duplicate cùng payload và conflict payload trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/LedgerIdempotencyTests.cs`

**Checkpoint**: ledger service có thể append journal cân bằng, từ chối journal lỗi và project balance độc lập với Broker.

## Phase 3: User Story 1 - Ghi nhận biến động tài sản bằng bút toán cân bằng (P1) - MVP

**Goal**: ghi nhận opening, reserve, fill, fee và cancel thành journal double-entry bất biến, đúng phí của bên phát sinh và không ghi trùng event.

**Independent Test**:

1. Gửi các transition opening/reserve/fill/fee/cancel cho tài khoản demo Alpha/Beta.
2. Xác nhận mỗi journal có debit và credit bằng nhau, source reference/tenant/account đầy đủ.
3. Gửi lại cùng event và xác nhận số journal/balance không tăng; thử sửa/xóa entry và xác nhận bị từ chối.

### Tests for User Story 1

- [ ] T011 [P] [US1] Viết unit test mapping opening/reserve/fill/fee/cancel và fee attribution theo BR-006 trong `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/LedgerTransitionFactoryTests.cs`
- [ ] T012 [P] [US1] Viết integration test lifecycle Broker → journal cho reserve/fill/cancel trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerLifecycleTests.cs`
- [ ] T013 [P] [US1] Viết integration test duplicate `TradeExecuted`/retry và conflict source reference trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerIdempotencyApiTests.cs`

### Implementation for User Story 1

- [x] T014 [US1] Implement transition builders cho opening/reserve/release/fill/fee/cancel theo BR-003 trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/LedgerTransitionFactory.cs`
- [x] T015 [US1] Tích hợp `ILedgerService` vào các transition hợp lệ của `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/DemoBrokerService.cs`, giữ `DemoAccountState` là compatibility view
- [ ] T016 [US1] Tích hợp mapping `TradeExecuted` cho buy/sell và source event id vào `flex-exchange-service/src/Flex.Exchange.Application/ExchangeService.cs`
- [x] T017 [US1] Thêm opening journal seed theo `Ledger:DemoOpeningEntries` trong `flex-exchange-service/src/Flex.Exchange.Api/Program.cs` mà không tạo duplicate khi khởi tạo lại cùng runtime
- [x] T018 [US1] Từ chối mọi đường sửa/xóa journal và tạo adjustment/reversal liên kết `ReversalOfJournalId` trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/InMemoryLedgerService.cs`
- [x] T019 [US1] Chạy `dotnet test Flex.Exchange.sln --configuration Release --no-restore` và xác nhận các test ledger cùng test Broker/Exchange hiện có đều pass

**Definition of Done**: mọi event P1 tạo journal cân bằng, append-only, fee ghi cho đúng bên phát sinh, retry idempotent và regression suite không giảm.

## Phase 4: User Story 2 - Theo dõi trạng thái tiền và chứng khoán (P1)

**Goal**: operator đọc được balance theo bốn bucket, đúng tenant/account và phản ánh fill chưa settlement là receivable/payable.

**Independent Test**:

1. Nạp opening, reserve và fill một giao dịch mua/bán.
2. Gọi balance endpoint theo từng account và đối chiếu bốn bucket với journal.
3. Gọi bằng tenant khác hoặc account không thuộc tenant và xác nhận không lộ dữ liệu.

### Tests for User Story 2

- [ ] T020 [P] [US2] Viết contract test response balance, bucket totals và lỗi `404/403` trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerBalanceContractTests.cs`
- [ ] T021 [P] [US2] Viết API security test own-tenant allow và cross-tenant deny trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerSecurityTests.cs`
- [ ] T022 [P] [US2] Viết integration test projector chuyển reserve/fill sang `receivable`/`payable` và không coi là available trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerBalanceProjectionTests.cs`

### Implementation for User Story 2

- [x] T023 [US2] Implement `GET /api/broker/ledger/accounts/{accountId}?tenantId=...` trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/LedgerController.cs` theo `contracts/ledger.md`
- [x] T024 [US2] Thêm tenant/account scope validation trước mọi balance query trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/InMemoryLedgerService.cs` và controller
- [x] T025 [US2] Hoàn thiện projection delta cho tiền/chứng khoán và expose `LedgerAccountBalance` không sửa payload Broker cũ trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/BalanceProjector.cs`
- [x] T026 [US2] Bổ sung log structured gồm `correlationId`, `tenantId`, `accountId`, `journalId`, bucket delta và không log secret/balance ngoài scope trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/InMemoryLedgerService.cs`
- [ ] T027 [US2] Chạy contract/security test và kiểm tra truy vấn balance hoàn tất dưới 3 giây ở tải demo theo `specs/000016-cash-securities-ledger/quickstart.md`

**Definition of Done**: balance API trả đúng bốn bucket, scope tenant được kiểm tra trước read, không lộ dữ liệu chéo tenant và projection khớp journal.

## Phase 5: User Story 3 - Truy vết từ lệnh đến ledger (P2)

**Goal**: operator tra được toàn bộ journal/entry theo source reference, bao gồm dòng fee và metadata audit.

**Independent Test**:

1. Tạo giao dịch Alpha mua/Beta bán có fee.
2. Gọi trace theo source reference ở từng tenant.
3. Xác nhận đủ journal/entry, fee tách biệt, source/correlation đầy đủ và trace tenant khác bị từ chối.

### Tests for User Story 3

- [ ] T028 [P] [US3] Viết contract test trace response, journal entries và source metadata trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerTraceContractTests.cs`
- [ ] T029 [P] [US3] Viết API permission test trace cross-tenant và unknown source không leak dữ liệu trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerTraceSecurityTests.cs`

### Implementation for User Story 3

- [x] T030 [US3] Implement `GET /api/broker/ledger/trace/{sourceReference}?tenantId=...` trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/LedgerController.cs`
- [x] T031 [US3] Implement query trace theo tenant/source và trả metadata fee, event type, correlation trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/InMemoryLedgerService.cs`
- [x] T032 [US3] Bổ sung `POST /api/broker/ledger/adjustments` cho operator với reason và `ReversalOfJournalId` theo contract trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/LedgerController.cs`
- [ ] T033 [US3] Cập nhật luồng gọi trace/balance/duplicate event trong `specs/000016-cash-securities-ledger/quickstart.md` và file `.http` liên quan của `flex-exchange-service`
- [ ] T034 [US3] Chạy E2E/manual Alpha/Beta trace, fee attribution và duplicate-event smoke check theo `specs/000016-cash-securities-ledger/quickstart.md`

**Definition of Done**: trace theo source trả đủ journal liên quan, fee được phân biệt, adjustment có audit link và không có cross-tenant leak.

## Phase 6: User Story 3 - Bổ sung kiểm thử adjustment và correlation (P2)

- [ ] T035 [P] [US3] Viết contract test cho `POST /api/broker/ledger/adjustments`, gồm payload reason, `ReversalOfJournalId` và lỗi validation trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerAdjustmentContractTests.cs`
- [ ] T036 [US3] Viết security test xác nhận chỉ operator được phép tạo adjustment và tenant scope không bị vượt qua trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerAdjustmentSecurityTests.cs`
- [ ] T037 [P] Kiểm tra truyền `X-Correlation-Id` từ API vào journal/log và metric trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerCorrelationTests.cs`

## Final Phase: Polish & Cross-Cutting Concerns

- [ ] T038 [P] Cập nhật tài liệu API và giới hạn in-memory/restart trong `specs/000016-cash-securities-ledger/contracts/ledger.md` và `specs/000016-cash-securities-ledger/quickstart.md`
- [ ] T039 [P] Bổ sung metric/check sau release cho append, rejected-unbalanced, duplicate-source, cross-tenant-deny và latency trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/InMemoryLedgerService.cs`
- [x] T040 Kiểm tra backward compatibility của `/api/orders` và `/api/broker/orders` bằng regression tests hiện có trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/`
- [ ] T041 Kiểm tra rollback bằng cách tắt `Ledger:Enabled`, restart process và xác nhận không có migration/data rollback cần thực hiện trong `specs/000016-cash-securities-ledger/quickstart.md`
- [x] T042 Chạy đầy đủ `dotnet test Flex.Exchange.sln --configuration Release --no-restore` và rà soát `git diff --check`

## Dependencies & Execution Order

### Phase dependencies

- Setup (T001–T003) không phụ thuộc phase khác.
- Foundational (T004–T010) phụ thuộc Setup và chặn mọi user story.
- US1 (T011–T019) và US2 (T020–T027) phụ thuộc Foundational; US2 cần projector từ T006/T025.
- US3 (T028–T034) phụ thuộc Foundational và các transition/source metadata từ US1.
- Polish (T038–T042) phụ thuộc các story đã hoàn thành.

### Dependency graph

`Setup → Foundational → US1 → US2 → US3 → Polish`

US1 và US2 có thể bắt đầu song song sau Foundational nếu tách phần controller/test; US3 chỉ tích hợp sau khi source mapping của US1 ổn định.

## Parallel execution examples

- Setup: T001, T002, T003 có thể chạy song song.
- Foundational: T009 và T010 có thể chạy song song sau khi có model ở T004.
- US1: T011, T012, T013 có thể chạy song song; T014–T018 tuần tự theo service integration.
- US2: T020, T021, T022 có thể chạy song song; T023–T026 không song song nếu cùng sửa `LedgerController`/service.
- US3: T028 và T029 có thể chạy song song; T030–T033 tuần tự theo contract.

## Implementation Strategy

1. Hoàn tất Setup + Foundational.
2. Triển khai US1 và dừng để xác nhận journal cân bằng/idempotency — đây là MVP tối thiểu.
3. Thêm US2 để đọc balance và kiểm soát tenant.
4. Thêm US3 để trace/adjustment.
5. Chạy Polish và full regression trước demo/release.

## Validation commands

- `dotnet test Flex.Exchange.sln --configuration Release --no-restore`
- `git diff --check`
- Manual/API smoke theo `specs/000016-cash-securities-ledger/quickstart.md`

## Traceability Matrix

| Source | Covered by tasks |
|---|---|
| MT-001 / US-001 / FR-001 / FR-002 / BR-001 | T004–T019 |
| FR-003 / BR-003 / BR-006 | T011, T014–T016 |
| FR-004 / BR-002 | T009, T018 |
| FR-008 / BR-005 | T010, T013, T019 |
| US-002 / FR-005 / FR-006 | T006, T020–T027 |
| SEC-001 / SEC-002 / BR-004 | T021, T024, T029, T031 |
| MT-002 / US-003 / FR-007 | T028–T034 |
| NFR-001 / NFR-002 / NFR-003 | T009, T019, T027, T040, T042 |
| MT-003 / SC-001–SC-004 | T006, T012, T013, T022, T027, T034, T042 |
| SEC-001 / SEC-002 adjustment authorization | T035, T036 |
| Correlation/observability | T026, T037, T039 |
| Risks: mapping, duplicate, tenant leak | T011–T013, T021, T029, T034 |

## Checklist chất lượng

- [x] Mọi task có checkbox, ID tuần tự, nhãn story phù hợp và file path/command cụ thể.
- [x] Mỗi user story có independent test, implementation và Definition of Done.
- [x] Test gate bao phủ invariant, mapping event, idempotency, permission, contract, regression và manual smoke.
- [x] Không có database/migration/settlement task ngoài scope MVP07.
- [x] Không còn placeholder hoặc task mô tả mơ hồ.

## Phase 7: Convergence

- [x] T043 [US1] Implement các transition builder cụ thể cho opening/reserve/fill/fee/cancel và test mapping event trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/LedgerTransitionFactory.cs` và `flex-exchange-service/tests/Flex.Exchange.Domain.Tests/LedgerTransitionFactoryTests.cs` per FR-003/BR-006 (partial)
- [x] T044 [US1] Implement fee attribution cho bên phát sinh giao dịch, fee income đối ứng và source reference trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/DemoBrokerService.cs` per FR-003/BR-006/US1/AC-008 (missing)
- [ ] T045 [US1] Hoàn thiện mapping `TradeExecuted` theo event id cho cả buy/sell account và kiểm thử retry/conflict trong `flex-exchange-service/src/Flex.Exchange.Application/Services/ExchangeService.cs` và `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerIdempotencyApiTests.cs` per FR-008/BR-005 (partial)
- [ ] T046 [US1] Bổ sung integration test cho reserve/fill/cancel và đối chiếu journal với Broker response trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerLifecycleTests.cs` per US1/AC-001/AC-003 (missing)
- [x] T047 [US2] Khôi phục invariant không bucket nào âm bằng cách phân biệt contra/equity account khỏi account khách hàng và thêm test projection reserve/fill trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/BalanceProjector.cs` và `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerBalanceProjectionTests.cs` per BR-003/NFR-001 (contradicts)
- [x] T048 [US2] Thực thi tenant/account authorization thực tế trước balance/trace/adjustment, không chỉ kiểm tra chuỗi `tenantId`, trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/LedgerController.cs` và `flex-exchange-service/src/Flex.Exchange.Application/Ledger/InMemoryLedgerService.cs` per SEC-001/SEC-002/BR-004 (partial)
- [ ] T049 [US2] Bổ sung contract và security tests cho balance endpoint, gồm own-tenant allow, cross-tenant deny và lỗi `403/404`, trong `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerBalanceContractTests.cs` và `LedgerSecurityTests.cs` per US2/AC-004/AC-006 (missing)
- [ ] T050 [US3] Bổ sung contract/permission test cho trace và adjustment; thêm trường `reason` bắt buộc vào request/response adjustment trong `flex-exchange-service/src/Flex.Exchange.Api/Controllers/LedgerController.cs` và `flex-exchange-service/tests/Flex.Exchange.Api.Tests/` per FR-004/FR-007/SEC-001 (missing)
- [x] T051 [US3] Áp dụng idempotency/conflict check cho `CreateAdjustment` và bảo đảm journal reversal append-only trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/InMemoryLedgerService.cs` per FR-004/FR-008/BR-002/BR-005 (partial)
- [ ] T052 [P] Cập nhật `DemoBrokerOptions` và opening seed để biểu diễn đúng Alpha/Beta tenant thay vì tenant cố định `demo`, đồng thời thêm test cô lập dữ liệu hai tenant trong `flex-exchange-service/src/Flex.Exchange.Application/PreTrade/` và `flex-exchange-service/tests/Flex.Exchange.Api.Tests/` per MVP-001/BR-004/SC-001/SC-004 (partial)
- [ ] T053 [P] Bổ sung structured metrics, correlation propagation từ `X-Correlation-Id` và test kiểm tra log không chứa dữ liệu nhạy cảm trong `flex-exchange-service/src/Flex.Exchange.Application/Ledger/` và `flex-exchange-service/tests/Flex.Exchange.Api.Tests/LedgerCorrelationTests.cs` per plan: observability/NFR-002 (missing)
- [ ] T054 [P] Hoàn thiện quickstart, contract examples, rollback smoke và kiểm tra latency dưới 3 giây trong `specs/000016-cash-securities-ledger/quickstart.md` và file `.http` của `flex-exchange-service` per NFR-002/SC-003/plan: rollout-rollback (missing)
