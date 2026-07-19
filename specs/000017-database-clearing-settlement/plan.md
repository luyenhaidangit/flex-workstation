# Kế hoạch triển khai: Nền dữ liệu bền vững từ MVP 01 đến MVP 08

**Branch**: `000017-database-clearing-settlement` | **Ngày**: 2026-07-19 | **Đặc tả**: [spec.md](spec.md)

## Tóm tắt

Persistence được đưa vào theo thứ tự domain: order/trade → broker/account/reservation → ledger → settlement/reconciliation. `flex-database` quản lý Liquibase SQL-first; `flex-exchange-service` thay persistence in-memory bằng adapter PostgreSQL nhưng giữ các contract MVP trước tương thích.

## Phạm vi kỹ thuật

**Trong phạm vi**: schema/seed, persistent repositories/adapters, rehydration order/trade, reservation, ledger/settlement/reconciliation, internal trace/health/recovery APIs và tests.

**Ngoài phạm vi**: identity/credential store, service mới, EF Core/generic repository, external settlement, production data import.

## Bối cảnh kỹ thuật

| Hạng mục | Quyết định |
|---|---|
| Runtime | C#/.NET 9, ASP.NET Core tại `flex-exchange-service` |
| Data access | `Npgsql` + SQL transaction trực tiếp |
| Migration | Liquibase SQL-first tại `flex-database/changelog/databases/exchange` |
| Isolation | Database per tenant; mọi record/query vẫn có tenant/broker scope |
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

1. Liquibase master changelog include các release SQL theo thứ tự reference/order/trade, broker/account/reservation, ledger, rồi settlement/reconciliation.
2. Adapter persistence ghi event/state transactionally và rehydrate engine state theo sequence khi service khởi động.
3. Reservation, journal và obligation chỉ nhận source order/trade/account đã tồn tại; idempotency chặn bản ghi lặp.
4. Trace nội bộ liên kết order/trade/account/journal/obligation/reconciliation theo tenant/broker scope.
5. Backup/restore staging được xác minh bằng rehydration, trace và reconciliation smoke.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec | Hướng xử lý | Module/path | Data/contract | Kiểm thử |
|---|---|---|---|---|
| US-001, FR-001–003, BR-001/002, NFR-001/003 | Persist/rebuild exchange state theo sequence. | `src/Flex.Exchange.Infrastructure/Persistence`; `src/Flex.Exchange.Application` | reference, order, order history, trade | Restart/rehydration integration. |
| US-002, FR-004–006, BR-003, NFR-002 | Persist account/reservation source-linked and idempotent. | `Application/PreTrade`, `Infrastructure/Persistence` | broker, customer, account, reservation | Duplicate/restart tests. |
| US-003, FR-007–010, BR-004/005, NFR-004 | Ledger and T+ from persisted trade/account. | `Application/{Ledger,Settlement}` | journal, entry, balance, obligation | Balance/T+ integration. |
| US-004, FR-011–014, BR-006, NFR-006 | Statement/reconciliation and tenant restore. | `Application/Reconciliation`; `Api/Controllers` | statement, result, alert, audit | Alert/no-fix, restore drill. |
| US-005, FR-015–018, BR-007, SEC-001–003, NFR-005 | Scope guard, audit, health/trace. | `Api/Controllers`, `Application`, `Infrastructure` | audit, inbox/outbox | Cross-tenant/security tests. |

## Phân tích tác động

| Khu vực | Tác động | Cách kiểm tra |
|---|---|---|
| Database | Liquibase formatted SQL theo release; seed Alpha/Beta tách khỏi changelog production. | `liquibase validate`, `update-sql` và re-run seed smoke. |
| Existing API | Giữ contract MVP 01–07; internal trace/health additive. | API regression/contract tests. |
| Permission | Tenant/broker guard cho read/write/recovery. | Cross-scope denial tests. |
| Logging/Audit | Correlation/source/action/result không chứa secret. | Audit/log assertions. |

## API/Contract Detail

| Contract | Thay đổi | Consumer |
|---|---|---|
| Existing order/broker endpoints | Giữ response hiện có, đọc/ghi qua persistence. | MVP 01–07 consumers |
| `GET /internal/persistence/trace` | Trace source từ order/trade tới hậu giao dịch. | Operator |
| `GET /internal/persistence/health` | Readiness, migration, backlog, dead-letter, restore state. | Operator/monitoring |
| Existing settlement/reconciliation/replay endpoints | Additive internal operations, scope-protected. | Operator/admin |

## Dữ liệu & Migration

`changelog/databases/exchange/db.changelog-master.yaml` là điểm vào duy nhất và include release tường minh. Mỗi SQL file là Liquibase formatted SQL, có changeset bất biến và rollback khi phù hợp. Không backfill dữ liệu production vì feature chưa có persistent data; seed local/test tách khỏi changelog production. Rollback data dùng restore backup hoặc forward-fix, tuyệt đối không xóa/sửa history.

## Quyết định kỹ thuật

| ID | Quyết định | Lý do | Loại bỏ |
|---|---|---|---|
| DEC-001 | SQL trực tiếp với Npgsql | Atomicity rõ và khớp Liquibase SQL-first. | EF Core/repository generic. |
| DEC-002 | Persist theo timeline order→post-trade | Bảo toàn nguồn dữ liệu nghiệp vụ. | Ledger độc lập. |
| DEC-003 | Rehydrate theo sequence/event history | Khôi phục deterministic MVP 01. | Snapshot-only không trace được. |
| DEC-004 | Internal operations additive | Không phá contract cũ. | Service clearing riêng. |

## Chiến lược kiểm thử

- Unit: sequence/lifecycle, source link, idempotency, balancing, T+, reconciliation.
- Integration: migration, restart rehydration, transaction, duplicate, trace, cross-tenant denial.
- Contract/regression: các endpoint MVP 01–07 không đổi response semantics.
- Manual staging: backup/restore tenant và reconciliation smoke.

## Cấu trúc project

```text
flex-database/changelog/databases/exchange/{releases,repeatable}/
flex-database/seed/{local,test}/
flex-exchange-service/src/Flex.Exchange.{Application,Infrastructure,Api}/
flex-exchange-service/tests/Flex.Exchange.{Domain.Tests,Api.Tests}/
```

## Rollout & Rollback

Pull request chạy `liquibase validate` và `update-sql`; staging chạy backup → Liquibase update bởi một CI/CD pipeline hoặc Kubernetes Job → smoke → deploy ứng dụng. Seed chỉ chạy local/test. Migration không rollback bằng delete; lỗi sau rollout dùng forward-fix hoặc restore backup. Tắt persistence chỉ khi không mất dữ liệu mới cần giữ.

## Observability & Debug

Log/audit: `tenantId`, `brokerId`, `orderId`, `tradeId`, `accountId`, `journalId`, `correlationId`, action/result; không log secret/statement đầy đủ. Metrics: migration readiness, rehydration duration, duplicate/conflict, backlog/DLQ, projection lag, T+ due/completed, reconciliation alerts. Health và trace là quick checks sau release.

## Checklist sẵn sàng cho `$speckit-tasks`

- [x] Không còn câu hỏi chặn thiết kế/task generation.
- [x] P1/P2 trace tới module, data, contract và test.
- [x] Migration, rollback, security, observability và restore validation rõ.
