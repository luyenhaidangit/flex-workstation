# Data Model: Triển khai DB MySQL cho các Tenant

**Feature**: 000005-mysql-tenant-db
**Ngày**: 2026-07-12
**Lưu trữ metadata**: PostgreSQL (main platform DB — spec 000002)
**Lưu trữ dữ liệu tenant**: MySQL per-tenant database (feature này)

---

## 1. Thực thể: TenantDatabase

Lưu trữ metadata về cơ sở dữ liệu MySQL đã được cấp phát cho một tenant. Bảng này nằm trong **PostgreSQL platform DB**, không phải trong MySQL tenant DB.

### Thuộc tính

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `id` | UUID | Có | Khóa chính, sinh tự động |
| `tenant_id` | VARCHAR / UUID | Có | FK tới bảng `tenants`; unique constraint (1 tenant ↔ 1 DB) |
| `db_host` | VARCHAR(255) | Có | Host MySQL (trong MVP: service name trong Docker network) |
| `db_port` | INTEGER | Có | Port MySQL, mặc định 3306 |
| `db_name` | VARCHAR(100) | Có | Tên MySQL database đã tạo (ví dụ: `tenant_abc123`) |
| `db_user` | VARCHAR(32) | Có | Tên MySQL user đã tạo (ví dụ: `usr_abc123`) |
| `connection_secret_ref` | VARCHAR(500) | Có | Tham chiếu đến secret lưu password; không phải password trực tiếp |
| `status` | ENUM | Có | Xem phần Trạng thái bên dưới |
| `status_reason` | TEXT | Không | Lý do nếu status là `error`; null khi không lỗi |
| `created_by` | VARCHAR(255) | Có | ID hoặc tên của người/pipeline đã tạo |
| `created_at` | TIMESTAMP WITH TZ | Có | Thời điểm tạo bản ghi |
| `updated_at` | TIMESTAMP WITH TZ | Có | Thời điểm cập nhật gần nhất |
| `provisioned_at` | TIMESTAMP WITH TZ | Không | Thời điểm MySQL DB thực sự sẵn sàng (status=`active`) |

### Trạng thái

```
pending  →  active
pending  →  error
error    →  pending   (khi admin retry)
active   →  archived  (khi tenant bị hủy — ngoài phạm vi MVP)
```

| Trạng thái | Ý nghĩa |
|-----------|---------|
| `pending` | Bản ghi đã tạo, đang trong quá trình khởi tạo MySQL |
| `active` | MySQL DB, user và secret đã sẵn sàng; ứng dụng tenant có thể kết nối |
| `error` | Quá trình khởi tạo thất bại; `status_reason` ghi lý do |
| `archived` | Database đã ngừng hoạt động (ngoài phạm vi MVP) |

### Ràng buộc

- `UNIQUE(tenant_id)`: mỗi tenant chỉ có một bản ghi TenantDatabase
- `UNIQUE(db_name)`: không có hai tenant cùng tên MySQL database
- `UNIQUE(db_user)`: không có hai tenant cùng MySQL user
- `connection_secret_ref` KHÔNG ĐƯỢC chứa password; chỉ là key/path dẫn đến secret store

---

## 2. Thực thể: Tenant (tham chiếu, không tạo mới)

Bảng `tenants` đã tồn tại trong platform DB. TenantDatabase tham chiếu sang đây qua `tenant_id`.

| Trường tham chiếu | Mô tả |
|-------------------|-------|
| `id` | Định danh duy nhất của tenant (UUID hoặc slug) |
| `name` | Tên hiển thị của tenant |
| `status` | Trạng thái tenant (active, inactive, v.v.) |

---

## 3. Thực thể: TenantDatabaseAuditLog

Ghi lại mọi thao tác liên quan đến TenantDatabase phục vụ audit (xem spec §10). Bảng này cũng nằm trong **PostgreSQL platform DB**.

| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|------|----------|-------|
| `id` | UUID | Có | Khóa chính |
| `tenant_database_id` | UUID | Có | FK tới `tenant_databases.id` |
| `tenant_id` | UUID / VARCHAR | Có | Denormalized để query nhanh khi `tenant_databases` bị xóa |
| `action` | VARCHAR(50) | Có | `provision_started`, `provision_succeeded`, `provision_failed`, `status_checked`, `archived` |
| `actor` | VARCHAR(255) | Có | ID người thực hiện hoặc `system:pipeline` |
| `result` | VARCHAR(20) | Có | `success`, `failure` |
| `detail` | TEXT | Không | Thông tin bổ sung; KHÔNG ĐƯỢC chứa secret hay password |
| `created_at` | TIMESTAMP WITH TZ | Có | Thời điểm sự kiện |

---

## 4. MySQL: Per-Tenant Database Structure

Mỗi tenant có một MySQL database riêng. Feature này chỉ khởi tạo database trống và user — **không tạo schema nghiệp vụ**. Schema của tenant (tables, indexes) thuộc về luồng migration riêng của ứng dụng tenant.

**Tóm tắt resource MySQL được tạo cho mỗi tenant**:

```sql
-- Database
CREATE DATABASE tenant_{sanitized_id}
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- User (password được sinh ngẫu nhiên, không hiển thị ở đây)
CREATE USER 'usr_{sanitized_id}'@'%' IDENTIFIED BY '<generated_password>';

-- Permissions: chỉ trên database của tenant đó
GRANT ALL PRIVILEGES ON `tenant_{sanitized_id}`.* TO 'usr_{sanitized_id}'@'%';
FLUSH PRIVILEGES;
```

**Quy tắc đặt tên** (từ TQ-003 trong research.md):
- `sanitized_id`: từ `tenant_id`, chỉ giữ `[a-z0-9]`, thay ký tự khác bằng `_`, cắt ở 20 ký tự.
- Database: `tenant_<sanitized_id>` (tối đa 27 ký tự, trong giới hạn 64 của MySQL).
- User: `usr_<sanitized_id>` (tối đa 24 ký tự, trong giới hạn 32 của MySQL).

---

## 5. Quan hệ giữa các thực thể

```
Tenant (1) ─────── (0..1) TenantDatabase
                              │
                              └─── (0..*) TenantDatabaseAuditLog
```

- Một Tenant có thể chưa có TenantDatabase (chưa được provision).
- Một TenantDatabase thuộc đúng một Tenant.
- Một TenantDatabase có nhiều TenantDatabaseAuditLog.
