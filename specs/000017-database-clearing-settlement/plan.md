# Kế hoạch triển khai: Nền dữ liệu bền vững từ MVP 01 đến MVP 08

**Branch**: `000017-database-clearing-settlement` | **Ngày**: 2026-07-19 | **Đặc tả**: [spec.md](spec.md)

## Tóm tắt

Persistence được chia theo tổ chức mô phỏng: Sở giao dịch quản lý order/trade, CTCK quản lý account/reservation và VSD quản lý ledger/settlement/reconciliation. Mỗi tổ chức có PostgreSQL database và Liquibase master changelog riêng; các contract giữ stable business reference xuyên tổ chức.

## Phạm vi kỹ thuật

**Trong phạm vi**: schema/seed, persistent repositories/adapters, rehydration order/trade, reservation, ledger/settlement/reconciliation, internal trace/health/recovery APIs và tests.

**Ngoài phạm vi**: identity/credential store, service mới, EF Core/generic repository, external settlement, production data import.

## Bối cảnh kỹ thuật

| Hạng mục | Quyết định |
|---|---|
| Runtime | C#/.NET 9, ASP.NET Core tại `flex-exchange-service` |
| Data access | `Npgsql` + SQL transaction trực tiếp |
| Migration | Liquibase SQL-first tại `flex-database/changelog/databases/{exchange,broker,vsd}` |
| Ownership | `exchange` (HoSE/HNX), `broker` (CTCK), `vsd` (VSD); không shared database |
| Tests | xUnit domain/API, PostgreSQL integration, Liquibase validate/update-sql smoke, staging restore drill |

## Kiểm tra constitution

| Gate | Ban đầu | Sau design | Ghi chú |
|---|---|---|---|
| Scope/traceability | Pass | Pass | Mapping P1/P2 bên dưới. |
| Security | Pass | Pass | Scope và audit trên toàn bộ read/write. |
| Compatibility/release | Pass | Pass | API cũ additive; migration forward-only. |
| Observability/test | Pass | Pass | Health, correlation, restore drill và test matrix. |
| Simplicity | Pass | Pass | Không thêm persistence service hay ORM. |

## Thiết kế tổng quan

1. `exchange` persist reference/order/trade và công bố `TradeExecuted` với `tradeId`, order IDs, broker ID, tenant ID, sequence và correlation.
2. `broker` persist customer/account/reservation; chỉ lưu external order/trade references, không đọc bảng `exchange`.
3. `vsd` persist journal/obligation/statement/reconciliation; chỉ nhận clearing instruction có trade/account references, không foreign key sang `exchange`/`broker`.
4. Mỗi database dùng outbox/inbox để xử lý lặp; trace tổng hợp theo business reference và correlation, không join xuyên database.
5. Backup/restore staging được xác minh độc lập từng database rồi chạy trace/reconciliation end-to-end.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec | Hướng xử lý | Module/path | Data/contract | Kiểm thử |
|---|---|---|---|---|
| US-001, FR-001–003, BR-001/002, NFR-001/003 | Persist/rebuild exchange state theo sequence. | `Application/Exchange`, `Infrastructure/ExchangePersistence` | `exchange`: reference, order, history, trade | Restart/rehydration integration. |
| US-002, FR-004–006, BR-003, NFR-002 | Persist account/reservation source-linked và consume exchange reference. | `Application/PreTrade`, `Infrastructure/BrokerPersistence` | `broker`: customer, account, reservation, inbox/outbox | Duplicate/restart tests. |
| US-003, FR-007–010, BR-004/005, NFR-004 | VSD consume clearing instruction và ghi ledger/T+. | `Application/{Ledger,Settlement}`, `Infrastructure/VsdPersistence` | `vsd`: journal, entry, balance, obligation | Balance/T+ integration. |
| US-004, FR-011–014, BR-006, NFR-006 | Statement/reconciliation and tenant restore. | `Application/Reconciliation`; `Api/Controllers` | statement, result, alert, audit | Alert/no-fix, restore drill. |
| US-005, FR-015–018, BR-007, SEC-001–003, NFR-005 | Scope guard, audit, health/trace. | `Api/Controllers`, `Application`, `Infrastructure` | audit, inbox/outbox | Cross-tenant/security tests. |

## Phân tích tác động

| Khu vực | Tác động | Cách kiểm tra |
|---|---|---|
| Database | Ba Liquibase master độc lập theo tổ chức; seed Alpha/Beta tách khỏi changelog production. | Validate/update-sql từng database và contract trace end-to-end. |
| Existing API | Giữ contract MVP 01–07; internal trace/health additive. | API regression/contract tests. |
| Permission | Tenant/broker guard cho read/write/recovery. | Cross-scope denial tests. |
| Logging/Audit | Correlation/source/action/result không chứa secret. | Audit/log assertions. |

## API/Contract Detail

| Contract | Thay đổi | Consumer |
|---|---|---|
| Existing order/broker endpoints | Giữ response hiện có, đọc/ghi qua persistence. | MVP 01–07 consumers |
| `GET /internal/persistence/trace` | Tổng hợp trace qua business reference/correlation, không join database. | Operator |
| `GET /internal/persistence/health` | Readiness, migration, backlog, dead-letter, restore state. | Operator/monitoring |
| Existing settlement/reconciliation/replay endpoints | Additive internal operations, scope-protected. | Operator/admin |

## Dữ liệu & Migration

Mỗi database có điểm vào riêng: `changelog/databases/exchange/db.changelog-master.yaml`, `broker/...` và `vsd/...`; pipeline truyền đúng master changelog mục tiêu. SQL là Liquibase formatted SQL với changeset bất biến. Không có foreign key hoặc transaction xuyên database: external IDs/correlation là contract, outbox/inbox bảo đảm xử lý lặp. Seed local/test tách khỏi changelog production; forward-fix hoặc restore backup áp dụng độc lập từng database.

## Quyết định kỹ thuật

| ID | Quyết định | Lý do | Loại bỏ |
|---|---|---|---|
| DEC-001 | SQL trực tiếp với Npgsql | Atomicity rõ và khớp Liquibase SQL-first. | EF Core/repository generic. |
| DEC-002 | Database theo ownership tổ chức | Khớp mô phỏng HoSE/HNX, CTCK và VSD. | Một shared database. |
| DEC-003 | Rehydrate theo sequence/event history | Khôi phục deterministic MVP 01. | Snapshot-only không trace được. |
| DEC-004 | Internal operations additive | Không phá contract cũ. | Service clearing riêng. |

## Chiến lược kiểm thử

- Unit: sequence/lifecycle, source link, idempotency, balancing, T+, reconciliation.
- Integration: migration, restart rehydration, transaction, duplicate, trace, cross-tenant denial.
- Contract/regression: các endpoint MVP 01–07 không đổi response semantics.
- Manual staging: backup/restore tenant và reconciliation smoke.

## Cấu trúc project

```text
flex-database/changelog/databases/{exchange,broker,vsd}/{releases,repeatable}/
flex-database/seed/{local,test}/
flex-exchange-service/src/Flex.Exchange.{Application,Infrastructure,Api}/
flex-exchange-service/tests/Flex.Exchange.{Domain.Tests,Api.Tests}/
```

## Rollout & Rollback

Pull request chạy `liquibase validate` và `update-sql` cho cả ba master changelog. Staging backup → cập nhật `exchange`, `broker`, `vsd` bởi một CI/CD pipeline/Kubernetes Job duy nhất mỗi database → contract smoke theo thứ tự exchange→broker→vsd → deploy ứng dụng. Seed chỉ chạy local/test; lỗi dùng forward-fix hoặc restore backup cho database bị ảnh hưởng.

## Observability & Debug

Log/audit: `tenantId`, `brokerId`, `orderId`, `tradeId`, `accountId`, `journalId`, `correlationId`, action/result; không log secret/statement đầy đủ. Metrics: migration readiness, rehydration duration, duplicate/conflict, backlog/DLQ, projection lag, T+ due/completed, reconciliation alerts. Health và trace là quick checks sau release.

## Checklist sẵn sàng cho `$speckit-tasks`

- [x] Không còn câu hỏi chặn thiết kế/task generation.
- [x] P1/P2 trace tới module, data, contract và test.
- [x] Migration, rollback, security, observability và restore validation rõ.
