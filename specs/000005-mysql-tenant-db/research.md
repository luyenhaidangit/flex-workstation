# Research: Triển khai DB MySQL cho các Tenant

**Feature**: 000005-mysql-tenant-db
**Ngày**: 2026-07-12
**Nguồn**: Phân tích spec, tham chiếu plan PostgreSQL (000002), context Docker Compose flex-environment

---

## TQ-001: MySQL chạy trong Docker hay external?

**Quyết định**: MySQL chạy như một Docker Compose service trong `flex-environment`, tương tự cách PostgreSQL đã được thiết lập trong spec 000002.

**Lý do chọn**:
- Nhất quán với pattern đã có: PostgreSQL service trong `docker-compose.yml` của `flex-environment`.
- Môi trường vận hành là Docker-based; không có bằng chứng về managed MySQL external.
- Dễ bootstrap trên máy mới (một lệnh `docker compose up`).
- Named volume đảm bảo data persistence qua container restart.

**Phương án đã loại**:
- MySQL managed cloud (RDS, Cloud SQL): ngoài phạm vi MVP, thêm dependency cloud và chi phí.
- Per-tenant MySQL container: quá phức tạp cho MVP; khó quản lý container lifecycle.

**Rủi ro còn lại**: Single MySQL instance là single point of failure. Đây là rủi ro chấp nhận được cho MVP per spec §13 (ràng buộc single-region, single instance).

---

## TQ-002: Lưu thông tin xác thực tenant MySQL như thế nào?

**Quyết định**: Lưu thông tin kết nối tenant (host, port, dbname, user) vào bảng `tenant_databases` trong PostgreSQL (main platform DB). Password MySQL của tenant được lưu trong Docker secret hoặc environment file ngoài Git, tham chiếu bởi `connection_secret_ref` trong bảng.

**Lý do chọn**:
- Password không bao giờ nằm plain text trong database hay log — khớp với SEC-003.
- Metadata kết nối (host, port, dbname, user) không nhạy cảm, lưu DB thuận tiện cho query/audit.
- `connection_secret_ref` là key/path trỏ đến giá trị thực trong secret store (không phải password).
- Nhất quán với pattern 000002: PostgreSQL credentials cũng dùng Docker secret.

**Phương án đã loại**:
- Lưu encrypted password trong PostgreSQL: tăng complexity, cần quản lý encryption key.
- Lưu tất cả trong file `.env` per-tenant: khó scale, dễ lộ khi không cẩn thận.
- HashiCorp Vault: đúng hướng dài hạn nhưng overkill cho MVP chưa có Vault infrastructure.

**Rủi ro còn lại**: Nếu secret store bị lộ, mọi tenant credentials bị ảnh hưởng. Giảm thiểu bằng cách giới hạn quyền đọc secret chỉ cho service cần thiết.

---

## TQ-003: Quy tắc đặt tên database và user MySQL

**Quyết định**:
- Database name: `tenant_{sanitized_tenant_id}` (ví dụ: `tenant_abc123`)
- MySQL user: `usr_{sanitized_tenant_id}` (rút ngắn để tránh vượt giới hạn 32 ký tự của MySQL)
- `sanitized_tenant_id`: chỉ giữ `[a-z0-9_]`, thay ký tự không hợp lệ bằng `_`, cắt ở 20 ký tự nếu quá dài.

**Lý do chọn**:
- Tên duy nhất khi tenant ID là unique (đã đảm bảo bởi hệ thống quản lý tenant).
- `tenant_` prefix giúp phân biệt rõ với database platform (không bị nhầm với `flex_platform` hay `flex_auth`).
- Giới hạn 32 ký tự của MySQL username buộc phải rút ngắn; dùng prefix `usr_` thay vì `tenant_` cho user.
- Sanitize đảm bảo không bị SQL injection trong DDL.

**Phương án đã loại**:
- Dùng tên tự đặt (human-readable slug): vi phạm BR-002 (phải sinh từ tenant ID).
- UUID không sanitize: chứa dấu `-` không hợp lệ trong MySQL identifier.

---

## TQ-004: Provisioning qua admin API hay management script?

**Quyết định**: MVP dùng management script PowerShell/Bash chạy trực tiếp, gọi qua Docker Exec hoặc từ host. Admin API endpoint là bước mở rộng sau (khi có admin panel).

**Lý do chọn**:
- Spec xác định trigger thủ công bởi admin — không yêu cầu API surface trong MVP.
- Script đơn giản hơn, ít dependency hơn, dễ audit command history.
- Không phải expose thêm admin endpoint mới khi chưa có admin auth surface rõ ràng.
- Consistent với pattern scripts trong `flex-environment` (đã có scripts bootstrap).

**Phương án đã loại**:
- Admin REST API endpoint: đúng hướng dài hạn nhưng cần thêm admin auth layer, không có trong MVP scope.
- MySQL Workbench / GUI manual: không tái lập được, không audit được, vi phạm MT-003.

**Rủi ro còn lại**: Script-based provisioning khó tích hợp automation sau này. Giải quyết ở iteration sau bằng cách wrap script thành API endpoint hoặc event handler.

---

## TQ-005: Thứ tự tạo resource và xử lý rollback nếu thất bại

**Quyết định**: Thứ tự tạo: (1) INSERT bản ghi `tenant_databases` với status=`pending` → (2) CREATE DATABASE → (3) CREATE USER → (4) GRANT → (5) lưu secret ref → (6) UPDATE status=`active`. Rollback: nếu bất kỳ bước nào sau (1) thất bại, DROP DATABASE/USER nếu đã tạo, UPDATE status=`error` + log lý do.

**Lý do chọn**:
- INSERT trước đảm bảo luôn có bản ghi để tracking và rollback.
- Từng bước riêng biệt cho phép rollback từng phần mà không để orphan resource.
- Status `error` giữ lại bản ghi để quản trị viên kiểm tra, không tự xóa record.

**Phương án đã loại**:
- Tạo hết rồi mới INSERT record: nếu INSERT lỗi, MySQL resources bị orphan.
- Transaction DDL: MySQL không hỗ trợ transactional DDL, không khả thi.
