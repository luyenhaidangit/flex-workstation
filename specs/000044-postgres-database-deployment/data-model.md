# Mô hình dữ liệu: Triển khai database PostgreSQL (000044)

v1 không tạo bảng hay schema. Tài liệu này mô tả các thực thể vận hành và quan hệ giữa chúng; không có migration hay backfill.

## Thực thể

| Thực thể | Ý nghĩa | Thuộc tính chính | Quan hệ |
|----------|---------|------------------|---------|
| Máy chủ PostgreSQL | Một tiến trình PostgreSQL duy nhất của Flex trong cụm | Tên dịch vụ `postgres`, cổng 5432, một bản chạy, dung lượng lưu trữ 10Gi | Chứa nhiều Database nghiệp vụ |
| Database nghiệp vụ | Kho dữ liệu riêng của một service, bàn giao ở trạng thái trống | Tên: `flex_exchange_hnx`, `aspnetidentity`, `agentdb` | Thuộc đúng một Tài khoản service sở hữu |
| Tài khoản service | Danh tính một service dùng để truy cập database của mình | Tên role: `hnx`, `aspnetidentity`, `agentdb`; mật khẩu lấy từ Secret | Sở hữu đúng một Database; không truy cập database khác |
| Tài khoản quản trị | Danh tính của người vận hành | Tên role `postgres`; mật khẩu từ Secret; không cấp cho service | Quản lý Máy chủ PostgreSQL |
| Secret mật khẩu | Nơi giữ mật khẩu trong cụm | Tên `postgres-secret`; key `POSTGRES_PASSWORD`, `HNX_DB_PASSWORD`, `AUTH_DB_PASSWORD`, `AGENT_DB_PASSWORD` | Cấp mật khẩu cho Tài khoản quản trị và ba Tài khoản service |

## Quy tắc xác thực

- Mỗi database có đúng một role sở hữu; `PUBLIC` không có quyền `CONNECT` (BR-001, FR-005).
- Mật khẩu không rỗng; thiếu bất kỳ key nào thì không tạo hay cập nhật tài khoản (AC-007).
- Không dùng lại mật khẩu từ cấu hình cũ (BR-003).

## Chuyển trạng thái

Không áp dụng — không có vòng đời trạng thái nghiệp vụ.

## Migration / Backfill

Không áp dụng — v1 không áp schema hay dữ liệu.
