# Kế hoạch triển khai: Ledger tiền và chứng khoán

**Branch**: `000016-cash-securities-ledger` | **Ngày**: 2026-07-19 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: `specs/000016-cash-securities-ledger/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**: Thay số dư có thể sửa trực tiếp bằng journal double-entry bất biến cho tiền và chứng khoán theo tenant; derive `available`, `reserved`, `receivable`, `payable`; ghi nhận nạp demo, reserve, fill, fee, cancel; hỗ trợ trace và idempotency.

**Hướng tiếp cận kỹ thuật**: Mở rộng `flex-exchange-service` trong `Flex.Exchange.Application` bằng append-only in-memory ledger và balance projector. `DemoBrokerService` ghi journal qua một service boundary sau transition hiện có. Thêm API read-only cho balance/trace và giữ nguyên Broker/Exchange contract cũ.

**Kết quả sau research**: Dùng integer minor units và quantity hiện có, một `Journal` gồm các `LedgerEntry` phải cân bằng trước khi append, source reference làm idempotency key, tenant scope bắt buộc. Không thêm database/migration/settlement trong MVP.

## Phạm vi kỹ thuật

**Trong phạm vi**:
- `flex-exchange-service/src/Flex.Exchange.Application/Ledger`: journal, entry, balance projector, idempotency và ledger service.
- Tích hợp ledger vào nạp demo, reserve/release, fill, fee và cancel của `DemoBrokerService`.
- API additive để đọc balance và trace journal theo tenant/account/source reference.
- Unit, API integration, contract, permission và regression tests; cập nhật `.http` quickstart.

**Ngoài phạm vi kỹ thuật**:
- Database/persistence production, migration/backfill hoặc recovery sau restart.
- Clearing, settlement T+, reconciliation, margin, custody và kết nối VSDC/ngân hàng.
- Thay đổi matching rules hoặc breaking change cho `/api/orders` và `/api/broker/orders`.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: C# / .NET 9 (`net9.0`).

**Service/App liên quan**: `flex-exchange-service`, các project `Flex.Exchange.Application`, `Flex.Exchange.Api` và test projects.

**Phụ thuộc chính**: `IExchangeService`, `ITradingSessionService`, `DemoBrokerService`, `ExchangeEvent`/`TradeExecuted`, ASP.NET Core, xUnit, `WebApplicationFactory`.

**Lưu trữ**: Append-only in-memory state; restart reset ledger đúng giới hạn demo, không schema/migration.

**Kiểm thử**: xUnit unit, API integration/contract, permission/security, manual `.http`, regression toàn solution.

**Nền tảng chạy**: Local/dev process hoặc container hiện có của `Flex.Exchange.Api`.

**Đơn vị deploy**: `Flex.Exchange.Api` cùng các assembly Application/Domain hiện có.

**Loại project**: REST web service và class library application/domain.

**Mục tiêu hiệu năng**: Truy vấn balance/trace và append journal trong vòng 3 giây ở tải demo thông thường.

**Ràng buộc**: Journal phải cân bằng trước khi append; state mutation tuần tự; không log secret hoặc dữ liệu ngoài tenant.

**Quy mô/Phạm vi**: Hai tenant Alpha/Beta, tài khoản demo và một symbol theo MVP 06; không tối ưu production scale.

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|---|---|---|---|
| Spec-before-code/traceability | Pass | Pass | US/FR/BR/SEC/NFR map tới ledger, API và test |
| Workstation boundary | Pass | Pass | Code chỉ ở `flex-exchange-service`; artifact ở workstation |
| Clean Architecture/boundary | Pass | Pass | Ledger orchestration ở Application; Domain không phụ thuộc ledger |
| Security/no secret | Pass | Pass | Tenant scope kiểm tra trước read/write; không log secret |
| Testability/quality | Pass | Pass | Unit, integration, contract, permission và manual |
| Simplicity/scope | Pass | Pass | In-memory append-only; không thêm DB/process |
| Compatibility | Pass | Pass | API mới additive; Broker/Exchange endpoint cũ giữ nguyên |
| Observability/audit | Pass | Pass | Journal bất biến, source reference, correlation và metric |

## Câu hỏi kỹ thuật cần research

Không còn câu hỏi chặn design. Các quyết định được xác nhận trong [research.md](research.md): ledger in-memory append-only, integer minor units, source reference idempotency và API additive.

## Thiết kế tổng quan

**Luồng chính**:
1. `DemoBrokerService` nhận transition nạp/reserve/fill/fee/cancel cùng tenant, account và source reference.
2. `LedgerService` dựng journal double-entry, kiểm tra scope, non-negative invariant, debit/credit và idempotency rồi append bất biến.
3. `BalanceProjector` derive bốn trạng thái từ entries; Broker response vẫn cung cấp field cũ để backward compatibility.
4. `GET /api/broker/ledger/accounts/{accountId}` trả balance; `GET /api/broker/ledger/trace/{sourceReference}` trả journal trace.

**Component/module tham gia**:
- `Application/Ledger`: `LedgerEntry`, `Journal`, `LedgerAccountBalance`, `ILedgerService`, `InMemoryLedgerService`, `BalanceProjector`.
- `Application/PreTrade/DemoBrokerService` và `ReservationManager`: phát sinh ledger transition sau state transition hợp lệ.
- `Api/Controllers/LedgerController.cs`: read-only balance/trace boundary.
- Tests: `Flex.Exchange.Domain.Tests` cho invariants; `Flex.Exchange.Api.Tests` cho API, tenant và lifecycle.

**Điểm mở rộng/thay đổi chính**:
- Thêm `TenantId` và `SourceReference` vào ledger context; giữ `DemoAccountState` làm compatibility view.
- Map `TradeExecuted` một lần cho buy/sell; ghi fee vào tài khoản của bên phát sinh theo BR-006.
- Bổ sung trace metadata nhưng không đổi payload hiện có theo cách breaking.

**Luồng thay thế/lỗi chính**:
- Journal mất cân bằng, thiếu source hoặc sai tenant bị reject atomic; không append và không đổi projector.
- Duplicate source reference trả journal cũ; payload khác trả conflict.
- Fill/cancel event không xác định account được audit lỗi và không tạo entry trùng.

**Thay đổi boundary giữa service/module**: Application Ledger boundary được gọi từ Broker; API expose read-only ledger contract. Domain matching không đổi.

**Idempotency/Concurrency**: Một lock trong ledger service bao quanh validate → lookup → append → project; source reference duy nhất trong tenant. Không giữ lock khi gọi I/O ngoài ledger.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---|---:|---|---|---|---|---|
| US-001 / FR-001 | P1 | Validate balanced journal trước append | `Application/Ledger/InMemoryLedgerService` | `Journal` internal | `Journal`, `LedgerEntry` | Unit/integration |
| FR-002 / BR-001 | P1 | Source, tenant, account metadata và debit/credit invariant | `LedgerEntry`, `Journal` | Ledger response | `LedgerEntry` | Unit/contract |
| FR-003 / BR-006 | P1 | Transition seed/reserve/fill/fee/cancel | `DemoBrokerService`, `LedgerTransitionFactory` | Internal transition | `SourceTransaction` | Unit/API |
| US-001 / FR-004 / BR-002 | P1 | Append-only; correction tạo reversal journal | `ILedgerService` | Adjustment contract | `Journal.ReversalOf` | Unit/security |
| US-002 / FR-005/006 | P1 | Project entries thành bốn bucket | `BalanceProjector`, `LedgerController` | Balance endpoint | `LedgerAccountBalance` | API/contract |
| US-003 / FR-007 | P2 | Query journal theo source reference | `LedgerController`, `ILedgerService` | Trace endpoint | `Journal`, `LedgerEntry` | API/permission |
| FR-008 / BR-005 | P2* | Unique source reference/idempotency conflict | `InMemoryLedgerService` | Stable `409` | Idempotency record | Unit/integration |
| SEC-001/002 | P1 | Tenant scope trên command/query | `LedgerController`, service | Tenant context | All ledger entities | Security tests |
| NFR/SC | P1/P2 | Invariant, latency, regression, Alpha/Beta trace | Application/API/tests | API/.http | Journal/balances | E2E/manual |

## Phân tích tác động

`*` FR-008 được ghi nhận trong nền tảng US1 để ngăn duplicate event ngay từ MVP, nhưng priority nghiệp vụ vẫn là P2 theo spec/US-003.

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---|---|---|---|
| Database/Migration | Không schema/migration; in-memory journal | Restart mất lịch sử đúng MVP | Smoke restart |
| API/Contract | Thêm balance/trace endpoints; giữ endpoint cũ | Consumer cũ không đổi payload | Contract tests |
| Permission/Security | Tenant/account scope cho mọi read/write | Cross-tenant leak | Security tests |
| Logging/Audit | Journal/source reference là audit; thêm correlation/metric | Không log secret | Log review |
| UI/UX | Không sửa frontend; dùng Swagger/.http | UI tương lai cần contract mới | Manual API |
| Job/Worker/Integration | Map `TradeExecuted`, retry idempotent | Duplicate/out-of-order event | Integration tests |

## API/Contract Detail

**Có thay đổi contract không**: Có, additive.

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|---|---|---|---|---|
| `GET /api/broker/ledger/accounts/{accountId}?tenantId=...` | API | Balance theo bốn bucket | Có | Operator/client mới |
| `GET /api/broker/ledger/trace/{sourceReference}?tenantId=...` | API | Journal, entries, source, delta | Có | Operator/test tooling |
| `POST /api/broker/ledger/adjustments` | API | Reversal/adjustment có lý do | Có | Operator demo |
| Internal `TradeExecuted` mapping | Event consumer | Ghi buy/sell entries theo event id | Có | `DemoBrokerService` |

Payload chi tiết: [contracts/ledger.md](contracts/ledger.md).

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---|---:|---:|---:|---:|---:|---|
| Tenant operator / own tenant | Có | Nạp demo/điều chỉnh được cấp quyền | Không | Không | Xử lý event | Không thấy tenant khác |
| Tenant customer / own account | Có | Không | Không | Không | Không | Chỉ account thuộc mình |
| Cross-tenant/unknown | Không | Không | Không | Không | Không | Trả `404/403` không leak |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không schema; có in-memory runtime entities mới.

**Migration**: Không áp dụng; ledger reset khi process restart.

**Backfill/Cleanup**: Không backfill; số dư seed hiện tại chuyển thành opening journal khi khởi tạo.

**Tương thích dữ liệu cũ**: `DemoAccountState` vẫn phục vụ Broker response; projector là nguồn mới cho ledger API.

**Rủi ro dữ liệu**: Double-write giữa state cũ và ledger; giảm bằng một transition service và invariant tests.

**Cách xác minh**: So sánh summary cũ với projection; verify debit=credit và source idempotency trong quickstart.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|---|---|---|---|---|
| DEC-001 | Append-only in-memory ledger ở Application | Phù hợp MVP và boundary hiện có | Database ledger ngay | Vượt scope, cần migration/recovery |
| DEC-002 | Derive balance từ journal | Loại mutable source of truth | Tiếp tục sửa `DemoAccountState` | Không audit được |
| DEC-003 | Integer minor units/quantity | Tránh sai số, tương thích code | Decimal/float mới | Tăng conversion risk |
| DEC-004 | Tenant + source reference + event type | Retry không duplicate | Timestamp dedupe | Không deterministic |
| DEC-005 | API additive/read-first | Giữ consumer cũ | Đổi Broker payload | Breaking change không cần thiết |

## Chiến lược kiểm thử

**Unit test**: Journal balance, validation, projection, fee attribution, reversal, idempotency, non-negative invariant.

**Integration test**: Broker reserve/fill/cancel → journal/projected balance; duplicate `TradeExecuted`; Alpha/Beta trade.

**Contract test**: Balance/trace/adjustment response, stable `409/403/404`, existing Broker/Exchange regression.

**Permission/security test**: Own-tenant/account read, cross-tenant deny, adjustment authorization, no leak.

**E2E/manual test**: Alpha buys/Beta sells, fee line, reserve → receivable/payable, trace và duplicate event.

**Regression test**: `dotnet test Flex.Exchange.sln --configuration Release` và test matching/session/Broker hiện có.

## Cấu trúc project

```text
specs/000016-cash-securities-ledger/{spec.md,plan.md,research.md,data-model.md,quickstart.md,contracts/ledger.md,tasks.md}
flex-exchange-service/src/Flex.Exchange.Application/Ledger/{LedgerEntry.cs,Journal.cs,LedgerAccountBalance.cs,LedgerTransitionFactory.cs,ILedgerService.cs,InMemoryLedgerService.cs,BalanceProjector.cs}
flex-exchange-service/src/Flex.Exchange.Api/Controllers/LedgerController.cs
flex-exchange-service/tests/Flex.Exchange.Domain.Tests/LedgerInvariantTests.cs
flex-exchange-service/tests/Flex.Exchange.Api.Tests/{LedgerApiTests.cs,LedgerSecurityTests.cs}
```

**Quyết định cấu trúc**: Thêm module `Ledger` trong Application và một controller mỏng; không thêm project/layer/database, không sửa frontend.

## Rollout & Rollback

**Kế hoạch rollout**: Build/test solution, bật ledger trong Development, chạy opening journal seed và quickstart; adjustment chỉ cho operator demo.

**Tương thích ngược**: Giữ endpoint/payload Broker và Exchange hiện có.

**Feature flag/config**: `Ledger:Enabled` và `Ledger:DemoOpeningEntries` trong Development.

**Thực thi migration/backfill khi rollout**: Không áp dụng; seed opening journal khi process khởi tạo.

**Rollback code/config**: Tắt `Ledger:Enabled` hoặc revert code; không có data rollback vì in-memory.

**Rollback dữ liệu/migration**: Không áp dụng; nếu projection sai, restart và forward-fix code/seed.

**Điều kiện kích hoạt rollback**: Journal mất cân bằng, duplicate fill lệch balance, cross-tenant read hoặc regression cũ.

## Observability & Debug

**Log cần có**: `correlationId`, `tenantId`, `accountId`, `journalId`, `sourceReference`, `eventType`, debit/credit totals, bucket delta, idempotency outcome, error reason.

**Dữ liệu không được log**: Token, secret, API key và toàn bộ số dư/ledger khi không cần.

**Metric cần theo dõi**: Journal append, rejected-unbalanced, duplicate-source, cross-tenant-deny, balance/trace latency.

**Trace/Correlation**: `X-Correlation-Id` từ API → Broker → ledger; giữ `sourceReference` và `journalId`.

**Cách kiểm tra sau release**: Health check, quickstart balance/trace, debit=credit, duplicate không tăng entries, cross-tenant deny.

**Tình huống debug chính**: Mapping fill sai account, fee attribution sai bên, duplicate event, projector lệch summary, permission leak.

## Theo dõi độ phức tạp

Không có vi phạm constitution cần ngoại lệ. Ledger module là boundary cần thiết; không thêm repository/database abstraction ngoài MVP.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn design/task generation đã được resolve trong research.
- [x] Thiết kế tổng quan, component/module, boundary và error flow đã rõ.
- [x] Idempotency/concurrency/retry đã được đánh giá.
- [x] US/FR P1/P2 và yêu cầu ảnh hưởng code/data/API/permission có mapping.
- [x] Database, API, permission, logging/audit và integration đã được đánh giá.
- [x] Contract/API/event thay đổi có consumer và compatibility check.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ.
- [x] Quyết định kỹ thuật có lý do và phương án loại.
- [x] Chiến lược test bao phủ unit, integration, contract, security, manual và regression.
- [x] Rollout, rollback, config và backward compatibility đã rõ.
- [x] Observability/debug có log, metric, trace và smoke check.
- [x] Cây thư mục chỉ dùng path thật trong repository.
- [x] Constitution gate không còn blocker.
