# Tasks: Triển khai DB MySQL cho các Tenant

**Đầu vào**: Design documents từ `specs/000005-mysql-tenant-db/`

**Điều kiện tiên quyết**: `plan.md` ✅ | `spec.md` ✅ | `research.md` ✅ | `data-model.md` ✅ | `contracts/provision-script.md` ✅

**Tests**: Không có yêu cầu automated test trong spec hoặc plan. Mỗi phase có Independent Test bằng lệnh cụ thể. US-003 có validation task riêng để xác minh rollback behavior.

**Tổ chức**: 3 user stories từ `spec.md` — US-001 (P1 MVP), US-002 (P2), US-003 (P2).

## Format: `[ID] [P?] [Story?] Description with path`

- **[P]**: Parallelizable — khác file và không phụ thuộc nhau.
- **[US1/US2/US3]**: Map tới user story trong `spec.md`.

---

## Phase 1: Setup (MySQL Infrastructure)

**Mục đích**: Đưa MySQL service vào Docker Compose stack của `flex-environment` và chuẩn bị cấu hình admin credentials.

- [x] T001 Thêm service `mysqldb` (image: `mysql:8.0`, named volume `mysqldb_data` mount `/var/lib/mysql`, healthcheck `mysqladmin ping -h localhost` với interval 5s/timeout 3s/retries 3/start_period 30s, network `flex_net`) vào `flex-environment/docker-compose.yml`
- [x] T002 [P] Thêm placeholder `MYSQL_ADMIN_HOST`, `MYSQL_ADMIN_PORT`, `MYSQL_ADMIN_USER`, `MYSQL_ADMIN_PASSWORD`, `SECRET_STORE_PATH`, `PLATFORM_DB_DSN` vào `flex-environment/.env.example` (phần MySQL Admin Credentials)
- [x] T003 [P] Thêm section "MySQL Admin Credentials Setup" (giải thích cách đặt giá trị thật vào `.env` ngoài Git, lệnh `docker compose ps mysqldb` để verify healthy) vào `flex-environment/INSTALL.md`

**Checkpoint Phase 1**: `docker compose ps mysqldb` báo `(healthy)` trước khi sang Phase 2.

---

## Phase 2: Foundational (PostgreSQL Migration)

**Mục đích**: Tạo bảng metadata `tenant_databases` và `tenant_database_audit_logs` trong PostgreSQL platform DB. Cả US-001, US-002 và US-003 đều đọc/ghi hai bảng này.

**CRITICAL**: Không bắt đầu US-001/US-002/US-003 cho đến khi phase này hoàn tất.

- [x] T004 Tạo `flex-environment/migrations/001_create_tenant_databases.sql` chứa `CREATE TABLE IF NOT EXISTS tenant_databases` (id UUID PK, tenant_id VARCHAR/UUID UNIQUE NOT NULL, db_host VARCHAR(255), db_port INTEGER DEFAULT 3306, db_name VARCHAR(100) UNIQUE NOT NULL, db_user VARCHAR(32) UNIQUE NOT NULL, connection_secret_ref VARCHAR(500) NOT NULL, status VARCHAR(20) CHECK IN ('pending','active','error','archived'), status_reason TEXT, created_by VARCHAR(255) NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), provisioned_at TIMESTAMPTZ) và `CREATE TABLE IF NOT EXISTS tenant_database_audit_logs` (id UUID PK DEFAULT gen_random_uuid(), tenant_database_id UUID REFERENCES tenant_databases(id), tenant_id VARCHAR NOT NULL, action VARCHAR(50) NOT NULL, actor VARCHAR(255) NOT NULL, result VARCHAR(20) NOT NULL, detail TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())
- [x] T005 [P] Tạo `flex-environment/migrations/001_create_tenant_databases_rollback.sql` chứa `DROP TABLE IF EXISTS tenant_database_audit_logs` trước (FK), sau đó `DROP TABLE IF EXISTS tenant_databases`
- [x] T006 Chạy lệnh `psql $PLATFORM_DB_DSN -f flex-environment/migrations/001_create_tenant_databases.sql` và xác minh cả hai bảng tồn tại qua `psql $PLATFORM_DB_DSN -c "\dt tenant*"` (phụ thuộc T004)

**Checkpoint Phase 2**: Hai bảng xuất hiện trong `\dt tenant*`. Mọi user story có thể bắt đầu.

---

## Phase 3: User Story 1 — Provision Database cho Tenant Mới (Ưu tiên: P1) MVP

**Goal**: Admin chạy một lệnh để cấp phát MySQL DB + user riêng cho một tenant; thông tin kết nối được lưu an toàn.

**Independent Test**:

1. Chạy `./flex-environment/scripts/provision-tenant-db.sh "test-001"` → exit code `0`, stdout có dòng `[OK] Database provisioned successfully`, không có chuỗi `password` trong stdout.
2. Chạy `psql $PLATFORM_DB_DSN -c "SELECT db_name, db_user, status, provisioned_at FROM tenant_databases WHERE tenant_id='test-001'"` → thấy `status=active`, `db_name=tenant_test001`, `provisioned_at` không null.
3. Chạy `mysql -h $MYSQL_ADMIN_HOST -u $MYSQL_ADMIN_USER -p$MYSQL_ADMIN_PASSWORD -e "SHOW DATABASES LIKE 'tenant_test001'"` → thấy `tenant_test001`.
4. Đăng nhập MySQL bằng `usr_test001` (lấy password từ secret store): `SHOW DATABASES` chỉ ra `tenant_test001` và `information_schema`.
5. Chạy `psql $PLATFORM_DB_DSN -c "SELECT action, result FROM tenant_database_audit_logs WHERE tenant_id='test-001'"` → có bản ghi `action=provision_succeeded`, `result=success`.

### Implementation for User Story 1

- [x] T007 [P] [US1] Tạo `flex-environment/scripts/provision-tenant-db.sh` với các phần: (a) kiểm tra biến môi trường bắt buộc (MYSQL_ADMIN_*, PLATFORM_DB_DSN, SECRET_STORE_PATH), (b) hàm `sanitize_id` chuyển tenant_id thành `[a-z0-9_]` max 20 ký tự, (c) kiểm tra tenant tồn tại trong PostgreSQL, (d) kiểm tra không có bản ghi `tenant_databases` status=active/pending cho tenant, (e) INSERT pending record, (f) kết nối MySQL admin, (g) `CREATE DATABASE tenant_{id} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`, (h) sinh password ngẫu nhiên ≥32 ký tự, (i) `CREATE USER 'usr_{id}'@'%' IDENTIFIED BY '...'`, (j) `GRANT ALL PRIVILEGES ON tenant_{id}.* TO 'usr_{id}'@'%'`, (k) `FLUSH PRIVILEGES`, (l) lưu password vào secret store, nhận `secret_ref`, (m) `UPDATE tenant_databases SET status=active, connection_secret_ref, provisioned_at=NOW()`, (n) INSERT audit log `provision_succeeded`, (o) in summary không có password, exit 0 — và rollback path: nếu bước f-l thất bại thì `DROP DATABASE/USER` nếu đã tạo, UPDATE status=error+status_reason, INSERT audit `provision_failed`, exit 3; exit codes 0/1/2/3/4 per `contracts/provision-script.md`
- [x] T008 [P] [US1] Tạo `flex-environment/scripts/provision-tenant-db.ps1` implement logic giống T007 cho PowerShell 5.1+: cùng exit codes, cùng output contract (không in password), cùng rollback behavior, đọc credentials từ `$env:MYSQL_ADMIN_*` và `$env:PLATFORM_DB_DSN` per `contracts/provision-script.md`
- [ ] T009 [P] [US1] Validate idempotency của `flex-environment/scripts/provision-tenant-db.sh`: chạy lần 2 với cùng `test-001` → verify exit code `2`, stdout có `already has an active database`, xác nhận chỉ có 1 bản ghi trong `tenant_databases` WHERE tenant_id='test-001' (phụ thuộc T007)
- [ ] T010 [P] [US1] Validate permission isolation: kết nối MySQL bằng `usr_test001`, chạy `SHOW DATABASES`, xác nhận chỉ thấy `tenant_test001` và `information_schema`; chạy `USE mysql` và verify `ERROR 1044: Access denied`; chạy `USE tenant_test001` và verify thành công (phụ thuộc T007)

**Definition of Done**:
- T007 và T008 hoàn tất, script chạy được trên cả Linux và Windows.
- T009: idempotency pass (exit 2 lần 2).
- T010: isolation pass (tenant user không thấy DB khác).
- Audit log có bản ghi `provision_succeeded`.
- Không có password trong stdout của script.

**Checkpoint**: US-001 hoàn tất — tenant `test-001` có MySQL DB hoạt động, cô lập và an toàn.

---

## Phase 4: User Story 2 — Kiểm tra Trạng thái Database Tenant (Ưu tiên: P2)

**Goal**: Admin có thể kiểm tra trạng thái database của bất kỳ tenant nào và biết ngay DB có kết nối được không, không cần SSH vào server.

**Independent Test**:

1. Chạy `./flex-environment/scripts/check-tenant-db-status.sh "test-001"` → in `Status: active`, `Connection: [CONNECTED]`, `DB Name: tenant_test001`, exit 0.
2. Chạy `./flex-environment/scripts/check-tenant-db-status.sh "test-999"` (tenant tồn tại nhưng chưa provision) → in `[NOT PROVISIONED]`, exit 0.

### Implementation for User Story 2

- [x] T011 [P] [US2] Tạo `flex-environment/scripts/check-tenant-db-status.sh` với các phần: (a) validate TENANT_ID input không rỗng, (b) query `tenant_databases` từ PostgreSQL bằng `$PLATFORM_DB_DSN`, (c) nếu không có bản ghi: in `[NOT PROVISIONED] Tenant {id} does not have a database yet.`, (d) nếu có bản ghi: in tenant_id, status, db_name, db_user, db_host, provisioned_at, (e) nếu status=active: thử `mysql -h db_host -P db_port -u db_user -p<secret> -e "SELECT 1"` (không query data), in `[CONNECTED]` hoặc `[CONNECTION FAILED: <reason>]`, exit 0 trong mọi trường hợp (status check, không modify data) per `contracts/provision-script.md`
- [x] T012 [P] [US2] Tạo `flex-environment/scripts/check-tenant-db-status.ps1` implement logic giống T011 cho PowerShell 5.1+: cùng output format, cùng exit 0 trong mọi trường hợp per `contracts/provision-script.md`

**Definition of Done**:
- T011 và T012 hoàn tất.
- Tenant đã provision: script in status=active và [CONNECTED] trong dưới 5 giây.
- Tenant chưa provision: script in [NOT PROVISIONED].
- Script không in credential, không modify dữ liệu.

**Checkpoint**: US-002 hoàn tất — admin có thể dùng script để kiểm tra trạng thái bất kỳ tenant nào.

---

## Phase 5: User Story 3 — Xử lý Lỗi và Rollback (Ưu tiên: P2)

**Goal**: Xác minh rằng khi provision thất bại giữa chừng, không có resource MySQL bị orphan và trạng thái PostgreSQL rõ ràng để admin xử lý tiếp.

*Lưu ý: Logic rollback đã được implement trong T007/T008. Phase này thực hiện validation để xác minh hành vi đúng.*

**Independent Test**:

1. Revoke CREATE privilege khỏi MySQL admin user, chạy provision cho `test-002` → exit code `3`.
2. Chạy `SHOW DATABASES LIKE 'tenant_test002'` bằng admin → kết quả rỗng (không có orphan DB).
3. Chạy `SELECT User FROM mysql.user WHERE User='usr_test002'` → kết quả rỗng (không có orphan user).
4. Query PostgreSQL: `SELECT status, status_reason FROM tenant_databases WHERE tenant_id='test-002'` → `status=error`, `status_reason` không null.
5. Query audit log: `SELECT action, result FROM tenant_database_audit_logs WHERE tenant_id='test-002'` → có bản ghi `provision_failed`.
6. Restore CREATE privilege, chạy provision lại cho `test-002` → exit code `0` (retry sau error thành công).

### Validation for User Story 3

- [ ] T013 [US3] Validate rollback behavior của `flex-environment/scripts/provision-tenant-db.sh`: (a) chạy `REVOKE CREATE ON *.* FROM '<admin_user>'@'%'` trên MySQL, (b) chạy `./provision-tenant-db.sh "test-002"` và verify exit 3, (c) chạy `SHOW DATABASES LIKE 'tenant_test002'` → rỗng, (d) chạy `SELECT User FROM mysql.user WHERE User='usr_test002'` → rỗng, (e) query PostgreSQL verify status=error và status_reason không null, (f) query audit log verify provision_failed record, (g) chạy `GRANT CREATE ON *.* TO '<admin_user>'@'%'` để restore, (h) chạy provision lại → exit 0 (phụ thuộc T007)
- [ ] T014 [US3] Validate security: chạy `./flex-environment/scripts/provision-tenant-db.sh "test-003" 2>&1 | grep -iE 'password|passwd'` và verify không có kết quả; chạy `psql $PLATFORM_DB_DSN -c "SELECT detail FROM tenant_database_audit_logs WHERE tenant_id='test-003'"` và verify detail không chứa chuỗi có định dạng password; kiểm tra `flex-environment/scripts/provision-tenant-db.sh` không chứa hardcoded credential (phụ thuộc T013)

**Definition of Done**:
- T013: rollback behavior đúng — không orphan resource, status=error, audit log đầy đủ.
- T014: security audit pass — không có credential lộ trong output hoặc audit log.
- Retry sau error thành công (bước g-h trong T013).

**Checkpoint**: US-003 xác minh — hệ thống không để lại trạng thái không nhất quán khi lỗi.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Hoàn tất tài liệu, kiểm tra syntax Compose, và xác minh toàn bộ luồng end-to-end.

- [x] T015 [P] Thêm section "Validate MySQL Tenant DB Provisioning" vào `flex-environment/INSTALL.md` với tóm tắt 4 kịch bản từ `specs/000005-mysql-tenant-db/quickstart.md` (Provision, Status Check, Idempotency, Rollback) và lệnh chạy từng kịch bản (phụ thuộc T003)
- [ ] T016 [P] Chạy `docker compose -f flex-environment/docker-compose.yml config` và verify service `mysqldb`, volume `mysqldb_data`, network `flex_net` xuất hiện đúng trong output (phụ thuộc T001)
- [ ] T017 [P] Chạy toàn bộ quickstart end-to-end per `specs/000005-mysql-tenant-db/quickstart.md`: Scenario 1 (provision) → Scenario 2 (status check) → Scenario 3 (idempotency) → Scenario 4 (rollback), ghi kết quả PASS/FAIL cho từng scenario (phụ thuộc T007, T011, T013)

**Checkpoint Final**: Tất cả quickstart scenarios PASS. Feature sẵn sàng cho vận hành.

---

## Validation Commands

```bash
# Kiểm tra MySQL service healthy
docker compose -f flex-environment/docker-compose.yml ps mysqldb

# Kiểm tra compose syntax
docker compose -f flex-environment/docker-compose.yml config

# Chạy PostgreSQL migration
psql $PLATFORM_DB_DSN -f flex-environment/migrations/001_create_tenant_databases.sql

# Verify migration thành công
psql $PLATFORM_DB_DSN -c "\dt tenant*"

# Provision tenant test
./flex-environment/scripts/provision-tenant-db.sh "test-001"

# Kiểm tra trạng thái tenant
./flex-environment/scripts/check-tenant-db-status.sh "test-001"

# Rollback migration (nếu cần)
psql $PLATFORM_DB_DSN -f flex-environment/migrations/001_create_tenant_databases_rollback.sql
```

---

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US1 | T007, T008, T009, T010 |
| US2 | T011, T012 |
| US3 | T013, T014 |
| FR-001 (CREATE DATABASE) | T007, T008 |
| FR-002 (CREATE USER + secret) | T007, T008 |
| FR-003 (GRANT scope) | T007, T008, T010 |
| FR-004 (không tạo trùng) | T007, T008, T009 |
| FR-005 (kiểm tra trạng thái) | T011, T012 |
| FR-006 (rollback khi lỗi) | T007, T008, T013 |
| FR-007 (audit log) | T004, T007, T008, T014 |
| BR-001 (1 DB per tenant) | T007, T008, T009 |
| BR-002 (tên từ tenant ID) | T007, T008 |
| BR-003 (password ngẫu nhiên) | T007, T008, T014 |
| SEC-001 (kiểm tra quyền admin) | T007, T008 |
| SEC-002 (không truy cập DB khác) | T007, T008, T010 |
| SEC-003 (không lưu password plain text) | T007, T008, T014 |
| NFR-001 (provision ≤30s) | T007, T008 |
| NFR-003 (idempotent) | T007, T008, T009 |
| SC-001 (100% provision thành công ≤30s) | T007, T008, T009 |
| SC-002 (không có incident cô lập dữ liệu) | T010 |
| SC-003 (status check ≤5s) | T011, T012 |
| SC-004 (rollback 100% không orphan) | T013 |
| data-model: tenant_databases | T004, T007, T008 |
| data-model: tenant_database_audit_logs | T004, T007, T008 |
| contracts: provision-tenant-db script | T007, T008 |
| contracts: check-tenant-db-status script | T011, T012 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Không có dependency — bắt đầu ngay.
- **Phase 2 (Foundational)**: Phụ thuộc `docker compose up` (platform DB online), **CHẶN** mọi user story.
- **Phase 3 (US-001)**: Phụ thuộc Phase 2 hoàn tất.
- **Phase 4 (US-002)**: Phụ thuộc Phase 2 hoàn tất. Có thể chạy song song với Phase 3 (script và migration khác nhau).
- **Phase 5 (US-003)**: Phụ thuộc Phase 3 hoàn tất (cần T007 để validate rollback).
- **Final Phase**: Phụ thuộc Phase 3, 4, 5 hoàn tất.

### Trong từng user story

- T007 và T008 (provision scripts Bash + PS): song song — khác file, không phụ thuộc nhau.
- T009 và T010 (idempotency + isolation validation): song song sau T007.
- T011 và T012 (status check scripts Bash + PS): song song — khác file.
- T013 trước T014 (T013 thay đổi MySQL privilege state, T014 cần MySQL ổn định).

---

## Parallel Opportunities

```bash
# Phase 1 — Song song T002 và T003 sau T001:
Task T002: Thêm env placeholders vào flex-environment/.env.example
Task T003: Thêm MySQL admin setup vào flex-environment/INSTALL.md

# Phase 2 — Song song T005 sau T004:
Task T004: Tạo migration SQL (phải trước)
Task T005: Tạo rollback SQL    ← song song với T006
Task T006: Chạy validate migration ← song song với T005

# Phase 3 — Song song nhiều task sau Phase 2:
Task T007: Tạo provision-tenant-db.sh
Task T008: Tạo provision-tenant-db.ps1   ← song song với T007

# Sau T007 — Song song T009 và T010:
Task T009: Validate idempotency
Task T010: Validate isolation    ← song song với T009

# Phase 4 — Song song sau Phase 2:
Task T011: Tạo check-tenant-db-status.sh
Task T012: Tạo check-tenant-db-status.ps1  ← song song với T011

# Final Phase — Song song T015, T016, T017:
Task T015: Update INSTALL.md với quickstart summary
Task T016: Docker compose config validation
Task T017: End-to-end quickstart run
```

---

## Implementation Strategy

### MVP First (chỉ US-001)

1. Hoàn tất Phase 1: Setup (T001-T003).
2. Hoàn tất Phase 2: Foundational (T004-T006) — CRITICAL.
3. Hoàn tất Phase 3: US-001 (T007-T010).
4. **STOP và VALIDATE**: Chạy Independent Test của US-001.
5. Tenant `test-001` có MySQL DB, user cô lập, audit log đầy đủ → **MVP đạt**.

### Incremental Delivery

1. Setup + Foundational → MySQL service và PostgreSQL schema sẵn sàng.
2. US-001 → Admin provision được DB mới, cô lập và an toàn (MVP).
3. US-002 → Admin kiểm tra trạng thái mà không cần SSH.
4. US-003 → Xác minh rollback behavior ổn định.
5. Final Phase → Documentation và end-to-end validation.

### Parallel Team Strategy (2 người)

1. Cả hai hoàn tất Phase 1 + Phase 2 cùng nhau.
2. Khi Foundational xong:
   - Người A: T007 (provision Bash) + T009 + T010 (validation).
   - Người B: T008 (provision PS) + T011 (status Bash) + T012 (status PS).
3. Người A chuyển sang T013, T014 (US-003 validation).
4. Người B chuyển sang T015, T016, T017 (Final Phase).

---

## Checklist chất lượng trước khi implement

- [x] Không còn task ví dụ hoặc placeholder `[Entity]`, `[endpoint]`, `[file]` trong output cuối.
- [x] Không còn `TXXX`, `Phase N` hoặc phase user story không tồn tại trong `spec.md`.
- [x] Toàn bộ task được đánh số tuần tự từ `T001` đến `T017`.
- [x] Mỗi task có path cụ thể (file) hoặc command cụ thể (validation).
- [x] Task sửa file có sẵn (T013, T014, T015, T016, T017) đã nêu rõ hành động cụ thể.
- [x] Task phụ thuộc task khác đã ghi rõ dependency task ID.
- [x] Mỗi user story có Independent Test cụ thể với lệnh thật.
- [x] US-003 không có automated test task — có validation task T013, T014 với commands cụ thể.
- [x] Mỗi user story có Definition of Done cụ thể.
- [x] Mỗi FR P1/P2 và SEC, BR, NFR quan trọng có task tương ứng.
- [x] Traceability Matrix dùng task ID thực tế, không có range.
- [x] Migration (T004, T005, T006), permission (T010, T013), security (T014), observability (T007 audit log) đều có task.
- [x] Task `[P]` không sửa cùng file và không phụ thuộc nhau.
- [x] US-001 và US-002 có thể chạy song song sau Phase 2 (không conflict file).
