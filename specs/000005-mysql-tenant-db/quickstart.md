# Quickstart: Xác thực Triển khai DB MySQL cho Tenant

**Feature**: 000005-mysql-tenant-db
**Ngày**: 2026-07-12

Hướng dẫn này mô tả cách xác nhận tính năng hoạt động end-to-end trong môi trường local/dev.

---

## Điều kiện tiên quyết

- [ ] Docker Engine và Docker Compose V2 đang chạy.
- [ ] `flex-environment` đã được clone và `docker compose up -d` đã chạy thành công.
- [ ] MySQL service trong Compose đang healthy (kiểm tra: `docker compose ps`).
- [ ] PostgreSQL service đang healthy (spec 000002 đã được triển khai).
- [ ] MySQL admin credentials đã được cấu hình trong secret/environment (không lưu trong Git).
- [ ] Platform DB connection string (`PLATFORM_DB_DSN`) đã được cấu hình.
- [ ] Có ít nhất một tenant test trong platform DB (tenant_id: `test-001`).

---

## Kịch bản 1 — Provision database cho tenant mới (US-001, AC-001 đến AC-003)

### Bước 1: Chạy provision script

```bash
cd flex-environment/scripts
./provision-tenant-db.sh "test-001"
```

**Kết quả mong đợi**:

```
[INFO] Provisioning MySQL database for tenant: test-001
...
[OK]   Database provisioned successfully for tenant: test-001
       DB Name: tenant_test001
       DB User: usr_test001
       Host:    mysql:3306
       Secret:  <secret_ref_value>
```

Exit code: `0`

### Bước 2: Xác minh bản ghi trong PostgreSQL

```sql
SELECT tenant_id, db_name, db_user, status, provisioned_at
FROM tenant_databases
WHERE tenant_id = 'test-001';
```

**Kết quả mong đợi**:

| tenant_id | db_name | db_user | status | provisioned_at |
|-----------|---------|---------|--------|----------------|
| test-001 | tenant_test001 | usr_test001 | active | 2026-07-12T... |

### Bước 3: Xác minh database tồn tại trong MySQL (dùng admin credentials)

```sql
-- Kết nối bằng MySQL admin
SHOW DATABASES LIKE 'tenant_test001';
SELECT User, Host FROM mysql.user WHERE User = 'usr_test001';
SHOW GRANTS FOR 'usr_test001'@'%';
```

**Kết quả mong đợi**:
- Database `tenant_test001` xuất hiện.
- User `usr_test001` tồn tại.
- Grants chỉ bao gồm `GRANT ALL PRIVILEGES ON tenant_test001.*`.

### Bước 4: Xác minh cô lập — user tenant không truy cập DB khác

```bash
# Kết nối MySQL bằng usr_test001 (lấy password từ secret store)
mysql -h localhost -P 3306 -u usr_test001 -p<password_from_secret>
```

```sql
-- Chạy trong session của usr_test001
SHOW DATABASES;         -- Chỉ thấy: information_schema, tenant_test001
USE mysql;              -- ERROR 1044: Access denied
USE tenant_test001;     -- OK
CREATE TABLE test_isolation (id INT); -- OK (trong DB của mình)
```

**Kết quả mong đợi**: usr_test001 chỉ thấy `tenant_test001` và `information_schema`. Không có quyền truy cập `mysql`, `performance_schema`, hay database của tenant khác.

### Bước 5: Xác minh audit log

```sql
SELECT action, actor, result, detail, created_at
FROM tenant_database_audit_logs
WHERE tenant_id = 'test-001'
ORDER BY created_at DESC;
```

**Kết quả mong đợi**: Có bản ghi `action=provision_succeeded`, `result=success`.

---

## Kịch bản 2 — Kiểm tra trạng thái database (US-002, AC-004, AC-005)

### Tenant đã có database

```bash
./check-tenant-db-status.sh "test-001"
```

**Kết quả mong đợi**:

```
[STATUS] Tenant: test-001
         Status:       active
         DB Name:      tenant_test001
         ...
         Connection:   [CONNECTED]
```

### Tenant chưa có database

```bash
./check-tenant-db-status.sh "test-999"   # Tenant tồn tại nhưng chưa provision
```

**Kết quả mong đợi**:

```
[NOT PROVISIONED] Tenant test-999 does not have a database yet.
```

---

## Kịch bản 3 — Idempotency: chạy lại trên tenant đã có DB (FR-004)

```bash
./provision-tenant-db.sh "test-001"    # Chạy lần 2
```

**Kết quả mong đợi**:

```
[SKIP] Tenant test-001 already has an active database (tenant_test001). No action taken.
```

Exit code: `2`

Xác minh trong PostgreSQL: vẫn chỉ có 1 bản ghi, status không đổi.

---

## Kịch bản 4 — Rollback khi lỗi giữa chừng (US-003, AC-006, AC-007)

*Chạy trong môi trường test, sau khi mô phỏng lỗi (ví dụ: revoke CREATE privilege của admin user trước khi chạy)*

```bash
./provision-tenant-db.sh "test-002"
```

**Kết quả mong đợi**:

```
[INFO] Provisioning MySQL database for tenant: test-002
[INFO] Creating tenant_databases record (status=pending)...
[INFO] Connecting to MySQL...
[ERROR] Failed at step: CREATE DATABASE — Access denied
[INFO] Rolling back: no database was created
[INFO] Updating tenant_databases record (status=error)...
[FAIL] Provisioning failed for tenant: test-002
```

Exit code: `3`

**Xác minh**:

```sql
-- PostgreSQL: bản ghi ở trạng thái error, không phải pending hay active
SELECT status, status_reason FROM tenant_databases WHERE tenant_id = 'test-002';
-- Expected: status=error, status_reason contains lý do lỗi

-- MySQL: không có database hay user nào được tạo
SHOW DATABASES LIKE 'tenant_test002';  -- Rỗng
SELECT User FROM mysql.user WHERE User = 'usr_test002';  -- Rỗng
```

---

## Kiểm tra bảo mật nhanh

```bash
# Xác minh password không xuất hiện trong output script
./provision-tenant-db.sh "test-003" 2>&1 | grep -i password
# Expected: không có kết quả

# Xác minh password không xuất hiện trong audit log
psql -c "SELECT detail FROM tenant_database_audit_logs WHERE tenant_id='test-003';" | grep -i password
# Expected: không có kết quả
```

---

## Tham chiếu

- Data model: [data-model.md](data-model.md)
- Script contract: [contracts/provision-script.md](contracts/provision-script.md)
- Spec: [spec.md](spec.md)
