# Data model: Nền tảng lưu trữ PostgreSQL

Feature này không tạo schema nghiệp vụ. Data model chỉ mô tả resource hạ tầng và ranh giới sở hữu dữ liệu.

| Entity/Resource | Thuộc tính | Quan hệ và quy tắc |
|-----------------|------------|--------------------|
| PostgreSQL service | Tên `postgresdb`, image pin version, health status, internal network | Chạy trong `flex-environment`; chỉ service được phê duyệt mới kết nối. |
| PostgreSQL data directory | Data path `/var/lib/postgresql/data`, lifecycle theo container | Được lưu trên named volume; không bị xóa khi recreate container. |
| Named volume | Tên `postgresdb_data`, persistent lifecycle | Gắn vào PostgreSQL service; chỉ xóa ở môi trường disposable sau khi xác nhận không còn dữ liệu cần giữ. |
| Secret truy cập | PostgreSQL password, nguồn secret, rotation owner | Cấp ngoài Git qua secret/file; không xuất hiện trong Compose tracked, log hoặc artifact Speckit. |
| Migration nghiệp vụ tương lai | Version, checksum/ledger, rollout, rollback, owner repo | Chưa tồn tại trong feature này; bắt buộc do repo consumer sở hữu khi thêm schema. |

## Validation rules

- PostgreSQL không được báo healthy trước khi `pg_isready` pass.
- Không có consumer nào được coi là kết nối thành công khi transaction chưa commit.
- Không dùng init script để thay thế migration versioned.
- Không commit secret, password hoặc connection string.
- Không thay đổi/xóa volume có dữ liệu cần giữ bằng rollback cấu hình.

## State transitions

| Trạng thái hiện tại | Sự kiện | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chưa tạo | `docker compose up` | Starting | Secret và Compose config hợp lệ |
| Starting | `pg_isready` pass | Healthy | PostgreSQL nhận kết nối |
| Starting/Healthy | PostgreSQL không phản hồi | Unhealthy | Healthcheck fail theo ngưỡng cấu hình |
| Healthy | Recreate container giữ volume | Healthy | Smoke data vẫn đọc lại được |
| Healthy | Xóa volume ở môi trường disposable | Chưa tạo | Đã xác nhận dữ liệu không cần giữ |
