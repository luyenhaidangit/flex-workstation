# Quickstart validation: Nền tảng lưu trữ PostgreSQL

## Điều kiện

- Docker Engine và Docker Compose V2 đã sẵn sàng.
- Đứng tại repo `flex-environment`.
- PostgreSQL password được cấp qua Docker secret hoặc file local ngoài Git theo hướng dẫn `INSTALL.md`.
- Không đưa password hoặc connection string vào terminal history, log, screenshot hay ticket.

## Kiểm tra cấu hình

1. Chạy `docker compose config` mà không in secret vào output lưu trữ.
2. Xác nhận service `postgresdb` dùng image PostgreSQL pin version, named volume `postgresdb_data`, healthcheck `pg_isready` và không publish host port mặc định.
3. Xác nhận secret local không xuất hiện trong `git status` hoặc `git diff`.

## Kiểm tra readiness và persistence

1. Khởi động service bằng `docker compose up -d postgresdb`.
2. Chờ `docker compose ps` báo PostgreSQL là `healthy`.
3. Dùng `psql` từ môi trường được cấp quyền để tạo một bản ghi smoke và đọc lại nó.
4. Recreate riêng service PostgreSQL mà không xóa named volume.
5. Đọc lại bản ghi smoke; kết quả phải đúng sau recreate container.

## Kiểm tra không sẵn sàng

1. Dừng service PostgreSQL hoặc dùng secret sai trong môi trường disposable.
2. Xác nhận health status không là `healthy` hoặc service khởi động thất bại rõ ràng.
3. Xác nhận không có bước nào báo thao tác ghi là thành công khi PostgreSQL không truy cập được.

## Kiểm tra rollback

1. Dừng service và khôi phục Compose revision trước nếu smoke test hoặc security review fail.
2. Giữ named volume để bảo toàn dữ liệu, trừ khi môi trường disposable đã được xác nhận có thể xóa.
3. Chạy lại smoke test sau rollback.

## Kết quả mong đợi

- Mỗi lần readiness check hoàn tất trong tối đa 5 giây; thời gian khởi động database ban đầu được theo dõi riêng qua health status.
- Smoke data được đọc lại đúng sau recreate service.
- Khi PostgreSQL không sẵn sàng, hệ thống thể hiện failure rõ ràng và không có xác nhận ghi giả.
- Không có secret hoặc connection string trong Git artifact hay output lưu giữ.
