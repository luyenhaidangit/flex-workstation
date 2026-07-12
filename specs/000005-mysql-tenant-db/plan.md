# Kế hoạch triển khai: Triển khai DB MySQL cho các Tenant

**Branch**: `000005-mysql-tenant-db` | **Ngày**: 2026-07-12 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000005-mysql-tenant-db/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**: Provision MySQL database riêng cho từng tenant khi được kích hoạt thủ công bởi admin; đảm bảo cô lập dữ liệu, thông tin xác thực an toàn, idempotency và rollback khi lỗi.

**Hướng tiếp cận kỹ thuật dự kiến**: Thêm MySQL service vào Docker Compose (`flex-environment`); xây dựng management script PowerShell/Bash để provision DB + user + secret; ghi metadata vào bảng `tenant_databases` trong PostgreSQL platform DB; cung cấp script kiểm tra trạng thái.

**Kết quả sau research**: Dùng single MySQL container (nhất quán với pattern PostgreSQL trong 000002); script-based provisioning cho MVP (không cần admin API); đặt tên `tenant_{sanitized_id}` / `usr_{sanitized_id}`; lưu password vào Docker secret/env file ngoài Git, tham chiếu qua `connection_secret_ref`; xử lý rollback theo thứ tự rõ ràng (xem research.md).

---

## Phạm vi kỹ thuật

**Trong phạm vi**:
- Thêm MySQL service, named volume, healthcheck và network attachment vào `flex-environment/docker-compose.yml`.
- Cấu hình MySQL admin credentials qua Docker secret hoặc environment file ngoài Git.
- Script `provision-tenant-db` (PowerShell + Bash) thực hiện tạo DB, user, grant, lưu secret, ghi PostgreSQL.
- Script `check-tenant-db-status` kiểm tra trạng thái và kết nối.
- Migration PostgreSQL: tạo bảng `tenant_databases` và `tenant_database_audit_logs` trong platform DB.
- Cập nhật `flex-environment/INSTALL.md` với hướng dẫn cấu hình MySQL admin secret.

**Ngoài phạm vi kỹ thuật**:
- Admin REST API endpoint (để sau khi có admin auth layer).
- Schema migration hay seed data trong MySQL tenant DB.
- Backup/restore tự động cho tenant DB.
- Event-driven provisioning tự động khi tenant đăng ký.
- Chính sách xóa/archive database khi tenant bị hủy.
- Multi-region hay cloud-managed MySQL.

---

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: Docker Compose V2; MySQL Docker Official Image, pin `mysql:8.0`; PowerShell 5.1+ và Bash 4+.

**Service/App liên quan**: `flex-environment` infrastructure stack; platform DB PostgreSQL 16 (spec 000002).

**Phụ thuộc chính**: Docker Engine/Compose, MySQL 8.0 Docker image, PostgreSQL client (`psql`) trong script, MySQL client (`mysql`) trong script.

**Lưu trữ**:
- MySQL 8.0, named volume `mysqldb_data`, mount `/var/lib/mysql`.
- PostgreSQL 16 (đã có) cho metadata `tenant_databases`, `tenant_database_audit_logs`.

**Kiểm thử**: `docker compose config`, `docker compose up`, healthcheck, script smoke test, isolation test (connect bằng tenant user), audit log verification.

**Nền tảng chạy**: Docker Engine trên môi trường local/dev (Windows + Linux/Mac).

**Đơn vị deploy**: Service `mysqldb` trong Compose project `flex-environment`; scripts trong `flex-environment/scripts/`.

**Loại project**: Local/dev infrastructure stack + management scripts.

**Mục tiêu hiệu năng**: Script provision hoàn tất trong 30 giây (NFR-001). Status check hoàn tất trong 5 giây (SC-003).

**Ràng buộc**: Không lưu MySQL admin password, tenant password hay connection string trong Git, log hay artifact Speckit. Password tenant PHẢI được sinh ngẫu nhiên ≥ 32 ký tự.

---

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Scope khớp MVP: tạo MySQL service + provision script + metadata PostgreSQL. Không mở rộng sang API hay auto-trigger. |
| Traceability Gate | Pass | Pass | Mọi FR P1/P2 có mapping sang module/path/data/test trong bảng Traceability. |
| Test Gate | Pass | Pass | Có smoke test, isolation test, idempotency test và rollback test trong quickstart. |
| Security Gate | Pass | Pass | Admin credential và tenant password qua Docker secret/env ngoài Git; `connection_secret_ref` không lưu password; script không in secret. |
| Compatibility Gate | Pass | Pass | Thêm service mới, không thay đổi service hiện có; migration PostgreSQL thêm bảng mới. |
| Observability Gate | Pass | Pass | Audit log mọi thao tác; script log từng bước; không log secret. |
| Complexity Gate | Pass | Pass | Management script + Docker Compose: đơn giản, nhất quán với pattern 000002. Không thêm orchestration phức tạp. |
| Release Gate | Không áp dụng | Không áp dụng | Local/dev infrastructure; rollout Compose và script backup được mô tả trong Rollout section. |

---

## Câu hỏi kỹ thuật cần research

Không còn câu hỏi chặn. Mọi quyết định đã được resolve tại [research.md](research.md):
- TQ-001: MySQL trong Docker (nhất quán pattern 000002)
- TQ-002: Lưu secret ref trong PostgreSQL, password trong Docker secret/env
- TQ-003: Naming convention `tenant_` / `usr_` với sanitized ID
- TQ-004: Management script (không phải API) cho MVP
- TQ-005: Thứ tự provision và rollback strategy

---

## Thiết kế tổng quan

**Luồng chính (US-001 — Provision)**:

1. Admin chạy `./provision-tenant-db.sh <TENANT_ID>` trên host.
2. Script validate input và đọc credentials từ environment/secret.
3. Script kiểm tra PostgreSQL: tenant tồn tại, chưa có `tenant_databases` active/pending.
4. INSERT `tenant_databases` với `status=pending` — tạo anchor record trước.
5. Script kết nối MySQL admin; kiểm tra database chưa tồn tại.
6. `CREATE DATABASE tenant_{id}` → `CREATE USER usr_{id}` → `GRANT ALL ON tenant_{id}.*`.
7. Sinh password ngẫu nhiên ≥ 32 ký tự, lưu vào Docker secret/env file, nhận `secret_ref`.
8. UPDATE `tenant_databases` status=`active`, ghi `connection_secret_ref`, `provisioned_at`.
9. INSERT `tenant_database_audit_logs` với `provision_succeeded`.
10. Script in tóm tắt (không in password), exit 0.

**Luồng thất bại / Rollback**:
- Lỗi ở bước 2-3: exit 1/2 ngay, không INSERT gì.
- Lỗi ở bước 5-8: DROP DATABASE/USER nếu đã tạo; UPDATE status=`error`; INSERT audit log `provision_failed`; exit 3.

**Luồng kiểm tra trạng thái (US-002)**:
1. Admin chạy `./check-tenant-db-status.sh <TENANT_ID>`.
2. Script query PostgreSQL lấy bản ghi `tenant_databases`.
3. Nếu không có: in `[NOT PROVISIONED]`.
4. Nếu có: in metadata; thử kết nối MySQL (không query data); in `[CONNECTED]` hoặc lỗi.

**Component/module tham gia**:
- `flex-environment/docker-compose.yml`: thêm `mysqldb` service
- `flex-environment/scripts/provision-tenant-db.ps1|sh`: logic provision
- `flex-environment/scripts/check-tenant-db-status.ps1|sh`: logic status check
- `flex-environment/migrations/`: SQL migration tạo bảng PostgreSQL
- PostgreSQL platform DB: bảng `tenant_databases`, `tenant_database_audit_logs`
- MySQL `mysqldb` service: lưu dữ liệu tenant

**Idempotency/Concurrency**:
- Nếu tenant đã có `tenant_databases` với status=`active`: script exit 2, không tạo trùng (FR-004).
- Nếu status=`pending` (đang có provision đang chạy): script từ chối, yêu cầu wait hoặc check status.
- MySQL DDL không transactional: rollback thực hiện bằng DROP statement riêng nếu tạo thất bại.
- Concurrent provision cùng tenant: UNIQUE constraint trên `tenant_id` trong PostgreSQL chặn race condition ở INSERT bước 4.

---

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Script gọi `CREATE DATABASE` với tên sinh từ tenant ID | `scripts/provision-tenant-db` | Script CLI (xem contracts/provision-script.md) | `tenant_databases` | Integration: tạo DB, verify SHOW DATABASES |
| US-001 / FR-002 | P1 | Đủ rõ | Script tạo MySQL user, sinh password ngẫu nhiên, lưu `connection_secret_ref` | `scripts/provision-tenant-db` | Script CLI | `tenant_databases.connection_secret_ref` | Integration: verify user tồn tại, secret_ref không null |
| US-001 / FR-003 | P1 | Đủ rõ | GRANT chỉ trên `tenant_{id}.*`; test bằng cách đăng nhập bằng tenant user | `scripts/provision-tenant-db` | Không áp dụng | MySQL GRANT | Permission test: tenant user không thấy DB khác |
| US-001 / FR-004 | P1 | Đủ rõ | Kiểm tra PostgreSQL UNIQUE constraint + check status trước khi tạo | `scripts/provision-tenant-db` | Script CLI exit code 2 | `tenant_databases` UNIQUE(tenant_id) | Idempotency test: chạy lại → exit 2, không tạo trùng |
| US-002 / FR-005 | P2 | Đủ rõ | Script query PostgreSQL + thử kết nối MySQL | `scripts/check-tenant-db-status` | Script CLI | `tenant_databases` | Smoke test: status=active → CONNECTED; chưa provision → NOT PROVISIONED |
| US-003 / FR-006 | P2 | Đủ rõ | Thứ tự provision + DROP rollback nếu lỗi | `scripts/provision-tenant-db` | Script CLI exit code 3 | `tenant_databases.status=error` | Rollback test: mô phỏng lỗi, verify không có orphan resource |
| US-003 / FR-007 | P2 | Đủ rõ | INSERT vào `tenant_database_audit_logs` tại mọi bước quan trọng | `scripts/provision-tenant-db` | Không áp dụng | `tenant_database_audit_logs` | Verify audit record sau provision thành công và thất bại |
| SEC-001 | - | Đủ rõ | Script đọc admin credentials từ env/secret, không hardcode | `scripts/provision-tenant-db` | Không áp dụng | Không áp dụng | Security: credentials không xuất hiện trong log/output |
| SEC-002 | - | Đủ rõ | GRANT chỉ trên DB riêng của tenant | `scripts/provision-tenant-db` | Không áp dụng | MySQL GRANT | Permission isolation test |
| SEC-003 | - | Đủ rõ | Password không lưu plain text; `connection_secret_ref` là tham chiếu | `scripts/provision-tenant-db` | Không áp dụng | `tenant_databases.connection_secret_ref` | Verify: column không chứa password format |
| NFR-001 | - | Đủ rõ | Script hoàn tất trong 30 giây | `scripts/provision-tenant-db` | Không áp dụng | Không áp dụng | Timing test trong môi trường local |
| NFR-003 | - | Đủ rõ | Check status=active/pending trước khi tạo | `scripts/provision-tenant-db` | Script CLI exit code 2 | `tenant_databases` | Idempotency test |

---

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Thêm bảng `tenant_databases` và `tenant_database_audit_logs` vào PostgreSQL platform DB; không thay đổi bảng hiện có | Không có rủi ro — thêm bảng mới, không sửa schema cũ | Verify bảng tồn tại sau migration; rollback = DROP TABLE |
| API/Contract | Không có API change — chỉ thêm management scripts | Không áp dụng | Không áp dụng |
| Permission/Security | MySQL admin credentials cần được cấu hình trước khi script chạy | Nếu admin credentials sai hoặc thiếu quyền: script fail rõ ràng với exit 4 | Test với credentials đúng/sai trong môi trường test |
| Logging/Audit | Thêm bảng `tenant_database_audit_logs`; script ghi stdout log | Password không được log | Verify log không chứa password; verify audit record đủ field |
| UI/UX | Không áp dụng (script-based, không có UI) | Không áp dụng | Không áp dụng |
| Job/Worker/Integration | Thêm MySQL service vào Compose stack; các service khác không bị ảnh hưởng | MySQL service khởi động chậm có thể delay toàn bộ stack; xử lý bằng `depends_on: condition: service_healthy` | `docker compose up --wait`; health check pass trong 30s |

---

## API/Contract Detail

**Có thay đổi contract không**: Không áp dụng

Tính năng này không expose REST API hay event contract. Interface duy nhất là management scripts (xem [contracts/provision-script.md](contracts/provision-script.md)).

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `provision-tenant-db` script | CLI script | Mới | Không áp dụng | System Administrator |
| `check-tenant-db-status` script | CLI script | Mới | Không áp dụng | System Administrator |

---

## Permission Matrix

| Vai trò/Scope | Xem trạng thái DB | Provision DB | Kiểm tra kết nối | Xóa DB | Ghi chú |
|---------------|-------------------|--------------|------------------|--------|---------|
| System Administrator | Có | Có | Có | Không (ngoài phạm vi MVP) | Cần truy cập host và admin credentials |
| Automation Pipeline | Không (MVP) | Không (MVP) | Không | Không | Trigger tự động để sau |
| Tenant Application | Không | Không | Có (chỉ DB của mình) | Không | Dùng tenant credentials được cấp |
| Tenant (end user) | Không | Không | Không | Không | Không có direct DB access |

---

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Có (PostgreSQL platform DB)

**Migration**:
- Thêm bảng `tenant_databases` vào PostgreSQL platform DB (xem data-model.md §1).
- Thêm bảng `tenant_database_audit_logs` vào PostgreSQL platform DB (xem data-model.md §3).
- Migration versioned, đặt tại `flex-environment/migrations/` hoặc migration folder của platform service.

**Backfill/Cleanup**:
- Không áp dụng. Không có tenant nào đã có MySQL DB trước feature này.

**Tương thích dữ liệu cũ**:
- Bảng mới không ảnh hưởng bảng cũ. Các service hiện có không query `tenant_databases`.

**Rủi ro dữ liệu**:
- Nếu script provision bị interrupt giữa chừng: bản ghi có thể ở status=`pending` mãi mãi. Giải quyết: admin chạy script với `--force` để override pending, hoặc UPDATE thủ công status=`error` rồi retry.

**Cách xác minh**:
- Query `SELECT * FROM tenant_databases LIMIT 10` sau migration để xác nhận bảng tồn tại và rỗng.

---

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001: MySQL deployment model | Single MySQL Docker service trong flex-environment | Nhất quán với PostgreSQL pattern (000002); đơn giản, tái lập được | Per-tenant container / Cloud MySQL | Quá phức tạp hoặc ngoài phạm vi MVP |
| DEC-002: Provisioning interface | Management script (Bash/PowerShell) | Trigger thủ công không cần API surface; dễ audit; phù hợp MVP spec | Admin REST API endpoint | Cần admin auth layer chưa có; thêm complexity không cần thiết |
| DEC-003: Secret storage cho tenant password | Docker secret / env file ngoài Git; `connection_secret_ref` trong PostgreSQL | Không lộ password trong Git hay log; nhất quán với pattern 000002 | Encrypted column trong PostgreSQL | Thêm complexity quản lý encryption key |
| DEC-004: DB naming | `tenant_{sanitized_id}` / `usr_{sanitized_id}` | Duy nhất, readable, trong giới hạn MySQL; tránh SQL injection trong DDL | UUID thuần | Dấu `-` không hợp lệ trong MySQL identifier |
| DEC-005: Rollback strategy | DROP statement sau lỗi + status=`error` | MySQL không hỗ trợ transactional DDL; DROP là cách duy nhất dọn sạch | Transactional DDL | Không khả thi với MySQL |

---

## Chiến lược kiểm thử

**Unit test**: Không áp dụng — script không có logic phức tạp đủ để unit test; integration test đủ bao phủ.

**Integration test**:
- Script provision tạo được DB, user, grant trong MySQL.
- Script đọc/ghi được vào PostgreSQL `tenant_databases`.
- Script rollback đúng khi lỗi giữa chừng (mô phỏng lỗi bằng revoke privilege).
- Xem kịch bản đầy đủ tại [quickstart.md](quickstart.md).

**Contract test**: Không áp dụng — không có REST API hay event contract.

**Permission/security test**:
- Tenant user chỉ thấy DB của mình trong `SHOW DATABASES`.
- Tenant user không thể USE database của tenant khác.
- Script output không chứa password.
- Audit log không chứa password.

**E2E/manual test**:
- Admin chạy script provision cho tenant test → xác minh DB sẵn sàng.
- Ứng dụng tenant test dùng credentials để kết nối MySQL → CRUD thành công.
- Admin chạy check status → kết quả đúng.

**Regression test**:
- Docker Compose `flex-environment` vẫn `up` bình thường sau khi thêm MySQL service.
- PostgreSQL service không bị ảnh hưởng (kiểm tra health status).

---

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000005-mysql-tenant-db/
├── spec.md
├── plan.md              # File này
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── provision-script.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Sinh bởi /speckit-tasks
```

### Source code (flex-environment)

```text
flex-environment/
├── docker-compose.yml                          # Thêm service mysqldb
├── .env.example                                # Thêm MYSQL_ADMIN_* placeholders
├── INSTALL.md                                  # Thêm hướng dẫn cấu hình MySQL admin
├── migrations/
│   └── 001_create_tenant_databases.sql         # Migration PostgreSQL (bảng tenant_databases, audit_log)
└── scripts/
    ├── provision-tenant-db.sh                  # Bash script (Linux/Mac/Docker)
    ├── provision-tenant-db.ps1                 # PowerShell script (Windows)
    ├── check-tenant-db-status.sh
    └── check-tenant-db-status.ps1
```

**Quyết định cấu trúc**: Scripts trong `flex-environment/scripts/` nhất quán với bootstrap scripts hiện có. Migration trong `flex-environment/migrations/` tương tự pattern quản lý schema của spec 000002.

---

## Rollout & Rollback

**Kế hoạch rollout**:
1. Chạy migration PostgreSQL: `psql $PLATFORM_DB_DSN -f migrations/001_create_tenant_databases.sql`.
2. Cấu hình MySQL admin credentials trong Docker secret hoặc `.env` file ngoài Git.
3. `docker compose up -d mysqldb` — khởi động MySQL service, chờ healthy.
4. Xác minh MySQL healthy: `docker compose ps mysqldb`.
5. Chạy smoke test provision cho tenant test.

**Tương thích ngược**: Không thay đổi service, schema hay contract hiện có. Rollout hoàn toàn additive.

**Feature flag/config**: Không áp dụng — feature hoạt động khi MySQL service up và script được deploy.

**Thực thi migration/backfill khi rollout**: Chạy migration PostgreSQL trước khi deploy scripts (migration idempotent: dùng `CREATE TABLE IF NOT EXISTS`).

**Rollback code/config**:
- Xóa `mysqldb` service khỏi `docker-compose.yml` (hoặc comment out).
- `docker compose down mysqldb` — dừng và xóa container MySQL.
- Xóa scripts `provision-tenant-db.*` và `check-tenant-db-status.*`.

**Rollback dữ liệu/migration**:
- DROP TABLE `tenant_database_audit_logs`, DROP TABLE `tenant_databases` (theo thứ tự vì FK).
- Named volume `mysqldb_data`: `docker volume rm flex-environment_mysqldb_data` (chú ý: xóa toàn bộ dữ liệu tenant MySQL — chỉ làm khi chắc chắn).

**Điều kiện kích hoạt rollback**: MySQL service không healthy sau 5 lần retry; script provision lỗi trên >50% tenant thử nghiệm; rủi ro bảo mật phát hiện liên quan đến credential exposure.

---

## Observability & Debug

**Log cần có** (stdout của script):
- `tenantId`, `sanitizedId`, `dbName`, `dbUser`, `action` (CREATE DATABASE / CREATE USER / GRANT / ROLLBACK), `result` (success/failure), `error_message` nếu lỗi, `duration_ms`.

**Dữ liệu không được log**:
- `MYSQL_ADMIN_PASSWORD`, `MYSQL_ADMIN_USER` value, tenant MySQL password, `PLATFORM_DB_DSN`, `connection_secret_ref` value.

**Metric cần theo dõi**:
- Số lượng `tenant_databases` theo status (pending/active/error) — query PostgreSQL.
- Thời gian provision (đo bằng script, ghi vào audit log).
- Số lần provision thất bại (query audit log).

**Trace/Correlation**: Script ghi `tenant_id` và timestamp vào mọi log line và audit record — đủ để trace khi lỗi.

**Cách kiểm tra sau release**:
- `docker compose ps mysqldb` — MySQL service healthy.
- `psql -c "SELECT count(*) FROM tenant_databases WHERE status='active'"` — số tenant đã provision.
- Chạy `check-tenant-db-status.sh <tenant_id>` cho một tenant đã provision — kết quả CONNECTED.

**Tình huống debug chính**:
- Script exit 4 (không kết nối được MySQL): kiểm tra MySQL service healthy, admin credentials đúng, network Docker.
- Script exit 3 (lỗi giữa chừng): query `tenant_databases` WHERE status=`error`, xem `status_reason`; kiểm tra MySQL user quyền admin đủ.
- Tenant user không kết nối được: verify `connection_secret_ref` trỏ đúng secret, secret còn hạn, user chưa bị drop.

---

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research.md.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá.
- [x] Mỗi FR P1/P2 có mapping sang module/path, data/entity và kiểm thử.
- [x] Tác động tới database, permission, logging/audit đã được đánh giá.
- [x] Không có API/event contract thay đổi cần consumer check.
- [x] Migration PostgreSQL rõ ràng; không có backfill.
- [x] Quyết định kỹ thuật chính có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử bao phủ integration, permission/security, E2E và regression.
- [x] Rollout, rollback code và rollback dữ liệu đã rõ.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric và cách kiểm tra.
- [x] Cấu trúc source code dùng path thật trong `flex-environment`.
- [x] Constitution gate không còn blocker.
