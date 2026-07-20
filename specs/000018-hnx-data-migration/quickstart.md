# Quickstart validation: MVP 1 Matching Engine DB

## Prerequisites

- .NET SDK theo `flex-exchange-service/global.json`.
- PostgreSQL HNX database và Liquibase theo `flex-database/README.md`.
- Không ghi password/connection string thật vào repository.

## Database

Từ `flex-database/hnx`:

```text
liquibase --changelog-file=changelog/db.changelog-master.xml validate
liquibase --changelog-file=changelog/db.changelog-master.xml update-sql
```

Kiểm tra bốn bảng và seed `FXS` + một HNX `CONTINUOUS` session.

## Backend

Từ `flex-exchange-service`:

```text
dotnet restore
dotnet test --configuration Release
```

Integration tests phải dùng PostgreSQL thật/containerized provider cho transaction, constraint và restart recovery.

## Smoke flow

Khi gửi `X-Correlation-Id`, client phải dùng UUID hợp lệ; nếu không cần truy vết do client cung cấp thì bỏ header để BE tự sinh UUID. Header không phải UUID nhận `400 Problem Details`.

1. Mở HNX continuous session.
2. Đặt hai lệnh không đối ứng và kiểm tra order book.
3. Đặt lệnh đối ứng để kiểm tra full/partial match và trade.
4. Hủy order còn mở.
5. Restart BE và kiểm tra open orders/trades vẫn tồn tại.
6. Chạy hai lệnh đối ứng đồng thời và kiểm tra không duplicate trade.

## Frontend

Từ `flex-microfrontend`:

```text
npm test -- --watch=false
```

Public order-book/trade payload phải giữ nguyên.
