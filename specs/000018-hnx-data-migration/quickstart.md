# Quickstart validation: HNX reference data migration

## Prerequisites

- .NET SDK theo `flex-exchange-service/global.json` (9.0.308 hoặc roll-forward tương thích).
- PostgreSQL HNX database đã được tạo và Liquibase driver/config được chuẩn bị theo `flex-database/README.md`.
- Không dùng password/connection string thật trong repository.

## 1. Validate database changelog

Từ `flex-database/hnx`:

```text
liquibase --changelog-file=changelog/db.changelog-master.xml validate
liquibase --changelog-file=changelog/db.changelog-master.xml update-sql
```

Kiểm tra `exchange_instruments` tồn tại và có dữ liệu seed HNX hợp lệ.

## 2. Chạy BE test

Từ `flex-exchange-service`:

```text
dotnet restore
dotnet test --configuration Release
```

Các test mới phải chạy qua PostgreSQL thật/containerized provider cho mapping, unique constraint, transaction và restart recovery; không dùng EF in-memory để kết luận database behavior.

## 3. Kiểm tra từng source mode

Chạy lần lượt `LegacyOnly`, `DualRead`, `Database` bằng cấu hình test/local:

1. Gọi luồng FE/API đọc dữ liệu HNX.
2. Xác nhận payload/status hiện tại không đổi.
3. Ở `DualRead`, tạo mismatch có kiểm soát và xác nhận không cutover, có log/metric.
4. Ở `Database`, restart BE và xác nhận HNX reference data vẫn còn.

## 4. Kiểm tra retry và rollback

- Chạy seed/backfill hai lần và xác nhận không duplicate.
- Làm DB unavailable trong dual-read và xác nhận fallback/observability theo mode.
- Đổi config về `LegacyOnly` để rollback runtime; xác nhận FE vẫn hoạt động.

## Expected result

- Changelog valid, dữ liệu reference HNX đối chiếu khớp.
- Public FE/BE contract không đổi.
- Cutover chỉ xảy ra sau khi đối chiếu đạt.
- Restart không làm mất reference data đã migrate.
