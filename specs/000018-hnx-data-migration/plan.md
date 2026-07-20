# Kế hoạch triển khai: Migrate dữ liệu HNX khỏi in-memory

**Branch**: `000018-hnx-data-migration` | **Ngày**: 2026-07-20 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000018-hnx-data-migration/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**: Rà soát dữ liệu HNX xuyên FE/BE/DB; migrate HNX reference data làm nhóm đầu tiên; đọc song song và đối chiếu trước khi cutover sang DB; giữ public contract, idempotency, audit/observability và rollback runtime.

**Hướng tiếp cận kỹ thuật dự kiến**: Xây một vertical slice reference-data trong `flex-exchange-service`: application port, PostgreSQL adapter dùng Npgsql, legacy adapter, comparison service và source-mode configuration. Dùng `flex-database` Liquibase để validate/seed schema hiện có; không mở rộng order/trade trong phase này.

**Kết quả sau research**: Đã resolve migration/backfill, boundary/port, backward compatibility, dual-read, idempotency và rollback theo [research.md](research.md).

## Phạm vi kỹ thuật

**Trong phạm vi**:
- `flex-exchange-service`: reference-data application port/use case, infrastructure PostgreSQL read/upsert adapter, source-mode configuration, comparison/telemetry và DI.
- `flex-database/hnx`: validation và nếu cần changeset/seed bổ sung cho `exchange_instruments`; không sửa changeset đã chạy.
- `flex-microfrontend`: chỉ contract/regression verification; không đổi UI/API shape nếu không cần.
- Test BE/FE cho dual-read, cutover, mismatch, retry, restart và backward compatibility.

**Ngoài phạm vi kỹ thuật**:
- Migrate order, order history, trade, outbox, ledger, trading session hoặc matching engine runtime state.
- Thay public endpoint/payload, redesign FE hoặc tạo service/database mới.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: C#/.NET 9 (`global.json` 9.0.308), TypeScript/Angular hiện có, SQL-first Liquibase.

**Service/App liên quan**: `flex-exchange-service`; `flex-microfrontend`; `flex-database/hnx`.

**Phụ thuộc chính**: ASP.NET Core controllers, Npgsql 9.0.5, existing `Flex.Exchange.Application`/`Infrastructure`, PostgreSQL, Liquibase.

**Lưu trữ**: PostgreSQL HNX database, bảng `exchange_instruments`.

**Kiểm thử**: xUnit/.NET integration tests, contract tests hiện có, Angular unit/contract regression, Liquibase validate/update-sql và smoke test.

**Nền tảng chạy**: ASP.NET Core service và browser Angular; database PostgreSQL do `flex-environment`/deployment cung cấp.

**Đơn vị deploy**: `flex-exchange-service`, database changelog/seed nếu có, FE không bắt buộc deploy.

**Loại project**: Web API + application/domain/infrastructure libraries, Angular microfrontend, database migration repository.

**Mục tiêu hiệu năng**: Không làm tăng đáng kể latency của exchange read path; dual-read phải có timeout bounded và metric để đo overhead trước cutover.

**Ràng buộc**: Không log secret; không dùng singleton mutable state cho dữ liệu bền vững; giữ compatibility public; changeset phát hành bất biến.

**Quy mô/Phạm vi**: HNX reference instruments trong MVP; scale cụ thể phải đo từ database thực tế trước khi chọn batch/page size.

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|---|---|---|---|
| Scope Gate | Pass | Pass | Chỉ HNX reference data; các nhóm khác ngoài phase |
| Traceability Gate | Pass | Pass | P1/P2 mapping trong bảng traceability |
| Test Gate | Pass | Pass | Có unit, integration, contract, security, FE regression và migration validation |
| Security Gate | Pass | Pass | Quyền vận hành, tenant/scope và secret-safe telemetry được giữ rõ |
| Compatibility Gate | Pass | Pass | Không đổi public contract; expand/dual-read/cutover |
| Observability Gate | Pass | Pass | Log/metric/correlation và mismatch diagnostics được thiết kế |
| Complexity Gate | Pass | Pass | Một port/reference slice; không generic repository hay service mới |
| Release Gate | Pass | Pass | Rollout flag, rollback config, forward-fix DB và smoke checks rõ |

## Câu hỏi kỹ thuật cần research

- **TQ-001**: Đã resolve — seed/backfill reference data, không backfill order/trade.
- **TQ-002**: Đã resolve — application-owned port và PostgreSQL adapter trong infrastructure.
- **TQ-003**: Đã resolve — giữ backward-compatible public contracts.
- **TQ-004**: Đã resolve — dual-read, compare, rồi cutover.
- **TQ-005**: Đã resolve — idempotent upsert, forward-only schema và config rollback.

## Thiết kế tổng quan

**Luồng chính**:
1. Liquibase validate schema HNX và seed/upsert `exchange_instruments` bằng stable identity/unique symbol.
2. BE đọc reference data qua application port; ở `DualRead`, gọi legacy source và PostgreSQL source trong bounded operation, canonicalize và compare.
3. Nếu khớp, trả payload hiện tại; nếu lệch/DB lỗi, ghi diagnostic và giữ legacy theo policy.
4. Sau khi đạt validation window, bật `Database`; các read path sử dụng DB làm nguồn chính.
5. FE tiếp tục gọi contract hiện tại và chạy regression; restart BE để xác nhận dữ liệu không mất.

**Component/module tham gia**:
- `Flex.Exchange.Application`: port/use case và comparison policy, không chứa Npgsql.
- `Flex.Exchange.Infrastructure.Persistence`: PostgreSQL adapter, connection/options, mapping/query.
- `Flex.Exchange.Api`: DI/configuration/health/diagnostic boundary; controller contract giữ nguyên.
- `flex-database/hnx`: Liquibase schema/seed/validation.
- `flex-microfrontend/src/app/exchange`: consumer regression, không đổi payload.

**Điểm mở rộng/thay đổi chính**:
- Reference-data read port thay thế việc đọc trực tiếp nguồn in-memory ở các consumer liên quan.
- `HnxReferenceDataSourceMode`/options với `LegacyOnly`, `DualRead`, `Database` và validation startup.
- Comparison result và structured telemetry cho match/mismatch/failure/cutover.

**Luồng thay thế/lỗi chính**:
- Dual-read mismatch: không cutover, trả legacy nếu policy cho phép, ghi mismatch.
- DB timeout/unavailable: bounded timeout; fallback chỉ ở `DualRead`, không fallback âm thầm ở `Database`.
- Seed retry: upsert idempotent, unique symbol và stable identity.
- Authorization/tenant mismatch: reject theo policy hiện có, không trả dữ liệu ngoài scope.

**Thay đổi boundary giữa service/module**: Không đổi service boundary hay public API; thêm application-to-infrastructure persistence boundary trong exchange service.

**Idempotency/Concurrency**: DB uniqueness là guard cuối; upsert dùng stable identity. Source mode là cấu hình immutable theo process/read operation, không dùng mutable singleton làm kho dữ liệu. Comparison snapshot phải có correlation và không cho phép một stale read tự động trigger cutover.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---|---|---|---|---|---|---|---|
| US-001 / FR-001..003 | P1 | Đủ rõ | Inventory artifact và source ownership matrix từ FE/BE/DB | `specs/.../research.md`, exchange source review | Không đổi | `exchange_instruments`, runtime source map | Review checklist + source scan |
| US-002 / FR-004..005 | P1 | Đủ rõ | Vertical slice port + legacy/PostgreSQL adapters + mode policy | `Flex.Exchange.Application`, `Infrastructure.Persistence` | Public endpoints giữ nguyên | HNX Instrument | Unit + PostgreSQL integration |
| US-002 / FR-006..007 | P1 | Đủ rõ | Chặn cutover khi mismatch; bounded retry/idempotent upsert | Persistence/use-case/config | Error behavior hiện có | Unique symbol/stable ID | Failure, retry, duplicate tests |
| US-003 / FR-008..009 | P2 | Đủ rõ | Comparison result, structured logs/metrics và migration status | Application/Infrastructure/Api observability | Diagnostic nội bộ, không breaking | Comparison result/audit | Contract/observability smoke |
| FR-010 | P1 | Đủ rõ | Giới hạn changeset/use case chỉ HNX reference data | `flex-database/hnx`, exchange feature | Không áp dụng | Không chạm order/trade/outbox | Scope review + migration diff |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---|---|---|---|
| Database/Migration | Seed/forward changeset cho `exchange_instruments` nếu thiếu; không sửa changeset cũ | Dirty data, duplicate, lock hoặc mismatch | Liquibase validate/update-sql, PostgreSQL integration, restart/reconcile |
| API/Contract | Không đổi endpoint/payload | FE cũ phải chạy ở cả ba source modes | ASP.NET contract tests + Angular service/component regression |
| Permission/Security | Giữ trusted scope hiện có; operator-only config/migration action | Lộ instrument ngoài HNX hoặc secret trong logs | Negative scope/permission tests, log review |
| Logging/Audit | Thêm source mode, comparison result, count, correlation, mismatch reason | Thiếu truy vết hoặc high-cardinality | Structured log/metric assertions |
| UI/UX | Không đổi UI; dữ liệu market board phải ổn định qua cutover | Empty/stale board khi DB lỗi | FE regression + manual smoke |
| Job/Worker/Integration | Seed/migration operation phải retry-safe; không mở rộng outbox phase này | Duplicate hoặc partial seed | Retry/failure integration test |

## API/Contract Detail

**Có thay đổi contract không**: Không.

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|---|---|---|---|---|
| Existing exchange read endpoints | API | Không đổi route/status/payload; thay nguồn dữ liệu phía sau | Có | `flex-microfrontend` exchange feature |

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---|---|---|---|---|---|---|
| Người dùng HNX hợp lệ | Có | Không áp dụng | Không | Không | Không | Chỉ dữ liệu trong scope được cấp |
| Operator/Admin được ủy quyền | Có | Không áp dụng | Không áp dụng | Không áp dụng | Có | Được chạy/đối chiếu/cutover theo quy trình |
| Người dùng ngoài HNX | Không | Không | Không | Không | Không | Bị chặn |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Có, ở mức seed/forward migration reference data; schema hiện có được tái sử dụng.

**Migration**:
- Validate `exchange_instruments` và tạo release changeset mới nếu cần bổ sung DDL/seed.
- Seed/upsert HNX instruments trước khi bật `DualRead`.

**Backfill/Cleanup**:
- Chỉ backfill reference instruments đã xác định thuộc HNX; không cleanup order/trade/runtime state.

**Tương thích dữ liệu cũ**:
- Legacy source tiếp tục hoạt động ở `LegacyOnly`/`DualRead`; DB trở thành source chính chỉ sau compare pass.

**Rủi ro dữ liệu**:
- Symbol/identity mismatch, duplicate seed, stale snapshot, DB unavailable, instrument ngoài HNX.

**Cách xác minh**:
- Count + key/attribute comparison, uniqueness query, sample payload comparison, restart test và Liquibase update-sql/validate.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|---|---|---|---|---|
| DEC-001 | Một vertical slice trong exchange service | Tận dụng boundary Application/Infrastructure hiện có, giảm scope | Tạo HNX service/database mới | Không cần boundary deploy độc lập cho reference phase |
| DEC-002 | Application-owned port + focused PostgreSQL adapter | Cô lập Npgsql và hỗ trợ legacy/DB dual-read | Generic repository | Tăng abstraction nhưng không giải quyết variation thực tế |
| DEC-003 | Dual-read rồi cutover bằng config | Cho phép đối chiếu trước khi đổi nguồn chính | Direct cutover | Rủi ro mất dữ liệu/sai payload cao |
| DEC-004 | Liquibase forward-only + config rollback | Phù hợp quy ước database hiện có và tránh destructive rollback | Rollback bằng drop/recreate | Có nguy cơ mất dữ liệu và phá lịch sử migration |

## Chiến lược kiểm thử

**Unit test**:
- Canonicalization/comparison, source-mode policy, mismatch handling, mode validation và idempotency decision.

**Integration test**:
- PostgreSQL thật/container: schema, precision, unique symbol, upsert, query, timeout, restart và migration từ empty/prior schema.

**Contract test**:
- Existing exchange endpoint payload/status không đổi ở `LegacyOnly`, `DualRead`, `Database`; FE service/model compatibility.

**Permission/security test**:
- Operator-only migration/cutover; HNX scope isolation; secret-safe logs; unauthorized/forbidden behavior.

**E2E/manual test**:
- Market board load, reference-backed order-book/trading flow, dual-read mismatch, DB unavailable và restart.

**Regression test**:
- Existing exchange API/domain suites, market board Angular tests, session/order/trade reads không bị thay đổi ngoài reference source.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000018-hnx-data-migration/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/reference-data-read.md
└── tasks.md                 # tạo bởi speckit-tasks
```

### Source code

```text
flex-exchange-service/
├── src/Flex.Exchange.Application/
│   └── Hnx/ReferenceData/       # port, models, comparison policy
├── src/Flex.Exchange.Infrastructure/
│   └── Persistence/Hnx/         # PostgreSQL adapter/options/mapping
├── src/Flex.Exchange.Api/
│   └── Extensions/              # configuration/DI wiring nếu cần
└── tests/
    ├── Flex.Exchange.Domain.Tests/
    └── Flex.Exchange.Api.Tests/  # integration/contract additions

flex-database/hnx/
├── changelog/releases/<new-release>/  # chỉ khi cần changeset/seed mới
└── scripts/                           # dùng validation hiện có

flex-microfrontend/src/app/exchange/
├── exchange-api.service.ts
├── exchange.models.ts
└── *.spec.ts                           # regression only nếu contract unchanged
```

**Quyết định cấu trúc**: Giữ repository/service boundaries hiện có; thêm feature folder focused cho HNX reference data và không tạo project/repository generic mới.

## Rollout & Rollback

**Kế hoạch rollout**:
1. Validate Liquibase và seed/backfill reference data.
2. Deploy BE có `LegacyOnly` mặc định và instrumentation.
3. Bật `DualRead` cho môi trường kiểm thử rồi HNX rollout nhỏ.
4. Theo dõi match rate, mismatch, latency và errors trong validation window.
5. Chỉ khi đối chiếu đạt mới bật `Database` cho HNX reference reads.

**Tương thích ngược**: Public API/payload giữ nguyên; legacy source tồn tại trong giai đoạn dual-read.

**Feature flag/config**: `Hnx:ReferenceDataSourceMode` với `LegacyOnly`, `DualRead`, `Database`; config phải validate allowed values và không chứa secret.

**Thực thi migration/backfill khi rollout**: Chạy Liquibase schema/seed trước khi bật `DualRead`; không để mỗi replica tự ý chạy destructive migration.

**Rollback code/config**:
- Đổi mode về `LegacyOnly`, xác nhận smoke test, sau đó điều tra mismatch.
- Không rollback public contract vì không đổi contract.

**Rollback dữ liệu/migration**: Không drop/revert changeset đã chạy; dùng forward-fix hoặc restore theo quy ước `flex-database`.

**Điều kiện kích hoạt rollback**:
- Mismatch bất kỳ thuộc tính bắt buộc, DB error/timeout vượt ngưỡng vận hành, FE regression, duplicate/unique violation hoặc unauthorized data exposure.

## Observability & Debug

**Log cần có**:
- `traceId`, `correlationId`, `market`, `sourceMode`, `operation`, `instrumentCount`, `matchCount`, `mismatchCount`, `result`, `durationMs`, `errorCode`.

**Dữ liệu không được log**:
- Connection string, password, token, API key, secret và payload chứa dữ liệu nhạy cảm không cần cho debug.

**Metric cần theo dõi**:
- `hnx_reference_compare_match`, `hnx_reference_compare_mismatch`, `hnx_reference_db_failure`, `hnx_reference_read_duration`, `hnx_reference_cutover_state`, `hnx_reference_seed_duplicates`.

**Trace/Correlation**: Truyền request `traceId`/`correlationId` qua application operation và persistence call; seed/migration batch có `jobId` hoặc batch id.

**Cách kiểm tra sau release**: Liquibase status, query count/unique, API smoke, FE market-board smoke, restart test và dashboard mismatch/latency.

**Tình huống debug chính**: mismatch identity/attribute, DB timeout, duplicate seed, stale dual-read snapshot, source-mode misconfiguration và scope violation.

## Theo dõi độ phức tạp

Không có vi phạm constitution cần ngoại lệ. Dual-read là complexity bắt buộc bởi quyết định nghiệp vụ đã chốt; scope được giới hạn ở một entity/reference slice và không thêm abstraction generic.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research hoặc ghi rủi ro rõ ràng.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá.
- [x] Mỗi `US`/`FR` P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá.
- [x] Contract/API/event thay đổi đã có consumer và cách compatibility; kết luận là không breaking change.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ.
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử đã bao phủ các lớp liên quan.
- [x] Rollout, rollback code/config, rollback dữ liệu/migration, feature flag/config và backward compatibility đã rõ.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và post-release check.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật trong repository.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
