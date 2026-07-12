# Contract: Management Script — Provision Tenant MySQL Database

**Feature**: 000005-mysql-tenant-db
**Loại contract**: Management script CLI interface
**Ngày**: 2026-07-12
**Trạng thái**: Draft

---

## Mô tả

Script quản trị để khởi tạo MySQL database riêng cho một tenant. Chạy trực tiếp bởi System Administrator từ host hoặc qua Docker Exec vào management container.

---

## Script: `provision-tenant-db`

### Vị trí dự kiến

```
flex-environment/scripts/provision-tenant-db.ps1   # PowerShell (Windows host)
flex-environment/scripts/provision-tenant-db.sh    # Bash (Linux/Mac host hoặc Docker Exec)
```

### Giao diện gọi

```bash
# Cú pháp
provision-tenant-db <TENANT_ID>

# Ví dụ
./provision-tenant-db.sh "abc123"
.\provision-tenant-db.ps1 "abc123"
```

### Tham số đầu vào

| Tham số | Bắt buộc | Mô tả |
|---------|----------|-------|
| `TENANT_ID` | Có | Định danh duy nhất của tenant (string, alphanumeric + hyphens) |

### Biến môi trường / Secret yêu cầu

| Biến | Nguồn | Mô tả |
|------|-------|-------|
| `MYSQL_ADMIN_HOST` | Config/Secret | Host MySQL instance (ví dụ: `mysql` trong Docker network, `localhost` ngoài) |
| `MYSQL_ADMIN_PORT` | Config/Secret | Port MySQL, mặc định `3306` |
| `MYSQL_ADMIN_USER` | Secret | MySQL admin user có quyền CREATE DATABASE, CREATE USER, GRANT |
| `MYSQL_ADMIN_PASSWORD` | Secret | Password của MySQL admin user |
| `PLATFORM_DB_DSN` | Secret | Connection string tới PostgreSQL platform DB (để ghi TenantDatabase record) |
| `SECRET_STORE_PATH` | Config | Đường dẫn hoặc namespace của secret store để lưu tenant password |

### Hành vi

**Happy path**:
1. Validate `TENANT_ID` (không rỗng, không chứa ký tự đặc biệt).
2. Sanitize thành `sanitized_id` (lowercase, `[a-z0-9_]`, max 20 ký tự).
3. Kiểm tra PostgreSQL: tenant tồn tại và chưa có `tenant_databases` record với status=`active` hay `pending`.
4. INSERT `tenant_databases` với `status=pending`.
5. Kết nối MySQL với admin credentials.
6. Kiểm tra database `tenant_{sanitized_id}` chưa tồn tại trên MySQL.
7. `CREATE DATABASE tenant_{sanitized_id} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`.
8. Sinh password ngẫu nhiên (≥ 32 ký tự, mixed alphanumeric + symbols).
9. `CREATE USER 'usr_{sanitized_id}'@'%' IDENTIFIED BY '<password>'`.
10. `GRANT ALL PRIVILEGES ON tenant_{sanitized_id}.* TO 'usr_{sanitized_id}'@'%'`.
11. Lưu password vào secret store; nhận về `secret_ref`.
12. UPDATE `tenant_databases` SET `status=active`, `connection_secret_ref=<secret_ref>`, `provisioned_at=now()`.
13. INSERT `tenant_database_audit_logs` với `action=provision_succeeded`.
14. In ra: `[OK] Database provisioned for tenant <TENANT_ID>`.

**Lỗi / Rollback**:
- Nếu bước 3 thất bại (tenant không tồn tại): exit với code 1, không tạo gì.
- Nếu tenant đã có DB active: exit với code 2, in thông báo rõ, không tạo trùng.
- Nếu bất kỳ bước 5-11 thất bại: DROP DATABASE và DROP USER nếu đã tạo, UPDATE status=`error`, log lý do, exit với code 3.
- Không bao giờ in password ra stdout hay log file.

### Exit codes

| Code | Ý nghĩa |
|------|---------|
| 0 | Thành công |
| 1 | Tenant không tồn tại hoặc input không hợp lệ |
| 2 | Database đã tồn tại (idempotency guard) |
| 3 | Lỗi trong quá trình tạo (đã rollback) |
| 4 | Lỗi kết nối MySQL admin hoặc platform DB |

### Output (stdout)

```
[INFO] Provisioning MySQL database for tenant: abc123
[INFO] Sanitized ID: abc123
[INFO] Creating tenant_databases record (status=pending)...
[INFO] Connecting to MySQL at mysql:3306...
[INFO] Creating database: tenant_abc123
[INFO] Creating user: usr_abc123
[INFO] Granting permissions...
[INFO] Storing credentials in secret store...
[INFO] Updating tenant_databases record (status=active)...
[OK]   Database provisioned successfully for tenant: abc123
       DB Name: tenant_abc123
       DB User: usr_abc123
       Host:    mysql:3306
       Secret:  <secret_ref>
```

**KHÔNG in**: password, MYSQL_ADMIN_PASSWORD, PLATFORM_DB_DSN hoặc bất kỳ credential nào.

---

## Script: `check-tenant-db-status`

### Giao diện gọi

```bash
./check-tenant-db-status.sh <TENANT_ID>
.\check-tenant-db-status.ps1 <TENANT_ID>
```

### Hành vi

1. Query PostgreSQL: lấy bản ghi `tenant_databases` cho `TENANT_ID`.
2. Nếu không có bản ghi: in `[NOT PROVISIONED]`.
3. Nếu có bản ghi: in status, db_name, db_user, db_host, provisioned_at.
4. Nếu status=`active`: thử kết nối MySQL (không chạy query, chỉ kiểm tra connect được không).
5. In kết quả kết nối: `[CONNECTED]` hoặc `[CONNECTION FAILED: <lý do>]`.

### Output mẫu

```
[STATUS] Tenant: abc123
         Status:       active
         DB Name:      tenant_abc123
         DB User:      usr_abc123
         Host:         mysql:3306
         Provisioned:  2026-07-12T10:30:00Z
         Connection:   [CONNECTED]
```
