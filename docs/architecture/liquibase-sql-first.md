# Triển khai database PostgreSQL với Liquibase SQL-first

Tài liệu này quy định cách tổ chức và triển khai migration PostgreSQL trong repository độc lập `flex-database`. Liquibase chỉ theo dõi, kiểm tra và chạy các file SQL; schema không phụ thuộc vào EF Core migration.

## Mục tiêu và phạm vi

- Giữ lịch sử thay đổi schema rõ ràng, có thứ tự và có thể audit.
- Dùng SQL thuần để kiểm soát đầy đủ DDL PostgreSQL.
- Chạy migration tập trung qua CI/CD hoặc Kubernetes Job; không chạy từ từng pod ứng dụng.
- Không đưa mật khẩu, connection string thật hoặc secret vào repository.
- Mô phỏng ba tổ chức chứng khoán bằng ba database độc lập, không tạo foreign key, join hay transaction xuyên database.

Phân chia database theo tổ chức:

| Database | Phạm vi nghiệp vụ | MVP |
| --- | --- | --- |
| `exchange` | Sở giao dịch: reference data, order, trade và outbox | MVP 01–04 |
| `broker` | Back-office công ty chứng khoán: customer, account, reservation, inbox/outbox | MVP 05–06 |
| `vsd` | Lưu ký, thanh toán và đối soát: ledger, settlement, reconciliation, inbox/outbox | MVP 07–08 |

`exchange` là schema dùng chung cho một instance Sở giao dịch. Khi mô phỏng đồng thời HoSE và HNX, chạy cùng master changelog này vào hai database/instance riêng, chẳng hạn `flex_exchange_hose` và `flex_exchange_hnx`; không nhân bản bộ migration theo tên sàn khi schema không khác nhau.

## Cấu trúc repository

```text
flex-database/
├── README.md
├── docker-compose.yml
├── liquibase.properties.example
│
├── changelog/
│   └── databases/
│       ├── exchange/
│       │   ├── db.changelog-master.yaml
│       │   ├── releases/
│       │   │   ├── v1.0/
│       │   │   │   ├── db.changelog-v1.0.yaml
│       │   │   │   ├── 001-create-reference-tables.sql
│       │   │   │   ├── 002-create-orders.sql
│       │   │   │   ├── 003-create-order-history.sql
│       │   │   │   ├── 004-create-trades.sql
│       │   │   │   └── 005-create-outbox.sql
│       │   │   └── v1.1/
│       │   │       ├── db.changelog-v1.1.yaml
│       │   │       └── 001-add-trade-sequence.sql
│       │   └── repeatable/
│       │       ├── views/
│       │       └── functions/
│       ├── broker/
│       │   ├── db.changelog-master.yaml
│       │   ├── releases/
│       │   │   └── v1.0/
│       │   │       ├── db.changelog-v1.0.yaml
│       │   │       ├── 001-create-customers.sql
│       │   │       ├── 002-create-accounts.sql
│       │   │       ├── 003-create-reservations.sql
│       │   │       ├── 004-create-inbox.sql
│       │   │       └── 005-create-outbox.sql
│       │   └── repeatable/
│       │       ├── views/
│       │       └── functions/
│       └── vsd/
│           ├── db.changelog-master.yaml
│           ├── releases/
│           │   └── v1.0/
│           │       ├── db.changelog-v1.0.yaml
│           │       ├── 001-create-journals.sql
│           │       ├── 002-create-ledger-entries.sql
│           │       ├── 003-create-balances.sql
│           │       ├── 004-create-obligations.sql
│           │       ├── 005-create-statements.sql
│           │       ├── 006-create-reconciliation.sql
│           │       ├── 007-create-inbox.sql
│           │       └── 008-create-outbox.sql
│           └── repeatable/
│               ├── views/
│               └── functions/
│
├── seed/
│   ├── local/
│   │   ├── exchange/
│   │   ├── broker/
│   │   └── vsd/
│   └── test/
│       ├── exchange/
│       ├── broker/
│       └── vsd/
│
├── environments/
│   ├── local.properties.example
│   ├── development.properties.example
│   ├── staging.properties.example
│   └── production.properties.example
│
├── scripts/
│   ├── validate-all.sh
│   ├── update-sql.sh
│   ├── migrate.sh
│   ├── status.sh
│   └── rollback.sh
│
├── tests/
│   ├── migration/
│   ├── constraints/
│   ├── upgrade/
│   └── restore/
│
└── pipelines/
    └── database-ci.yml
```

Vai trò của các thư mục:

- `changelog/databases`: migration production, tách theo ownership database.
- `db.changelog-master.yaml`: entry point riêng cho `exchange`, `broker` và `vsd`.
- `releases`: changeset bất biến; chỉ thêm file mới, không sửa file đã áp dụng ở môi trường dùng chung.
- `repeatable`: view/function có thể chạy lại khi nội dung đổi, được include qua changeset `runOnChange` tường minh.
- `seed`: dữ liệu local/test; không được include vào production master changelog.
- `environments`: chỉ chứa cấu hình mẫu, không commit password thật.
- `scripts`: lệnh thống nhất cho local và CI/CD.
- `tests`: migration database rỗng, upgrade từ release cũ, constraint và kiểm tra khôi phục.
- `pipelines`: validate, tạo `update-sql` để review, rồi mới chạy `update` ở môi trường được phê duyệt.

Không thêm các thư mục `schema/`, `tables/` hoặc `indexes/` song song với `releases`. Chúng dễ tạo hai nguồn sự thật ngoài migration. DDL thuộc changeset release mà nó được áp dụng.

## Tổ chức changelog theo release

Mỗi database có một điểm vào riêng. Ví dụ `changelog/databases/exchange/db.changelog-master.yaml`:

```yaml
databaseChangeLog:
  - include:
      file: releases/v1.0/db.changelog-v1.0.yaml
      relativeToChangelogFile: true

  - include:
      file: releases/v1.1/db.changelog-v1.1.yaml
      relativeToChangelogFile: true
```

Mỗi release include file SQL theo thứ tự mong muốn:

```yaml
databaseChangeLog:
  - include:
      file: 001-create-reference-tables.sql
      relativeToChangelogFile: true
  - include:
      file: 002-create-orders.sql
      relativeToChangelogFile: true
  - include:
      file: 003-create-order-history.sql
      relativeToChangelogFile: true
  - include:
      file: 004-create-trades.sql
      relativeToChangelogFile: true
  - include:
      file: 005-create-outbox.sql
      relativeToChangelogFile: true
```

Khai báo include tường minh để thứ tự migration được review trong Git, thay vì tự quét thư mục. Một pipeline chỉ nhận một database đích và master changelog tương ứng.

## Viết migration bằng Liquibase formatted SQL

Mỗi file migration bắt đầu bằng `--liquibase formatted sql`. Một changeset phải có tổ hợp `id`, `author` và đường dẫn file duy nhất. Liquibase dùng tổ hợp này để nhận biết changeset đã chạy và lưu checksum để phát hiện nội dung bị sửa sau khi áp dụng.

```sql
--liquibase formatted sql

--changeset flex:exchange-v1.0-002 labels:exchange
CREATE TABLE exchange_orders
(
    order_id       BIGINT PRIMARY KEY,
    instrument_id  UUID        NOT NULL,
    broker_id      VARCHAR(50) NOT NULL,
    side           VARCHAR(4)  NOT NULL,
    quantity       BIGINT      NOT NULL,
    price          NUMERIC(20, 4),
    status         VARCHAR(30) NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ix_exchange_orders_instrument_status
    ON exchange_orders (instrument_id, status);

--rollback DROP TABLE exchange_orders;
```

`repeatable/` không tự chạy chỉ vì file tồn tại. Tạo changeset YAML hoặc formatted SQL include file đó với `runOnChange: true`, giới hạn cho object có thể thay thế an toàn như view và function. Không dùng cơ chế này cho table hoặc dữ liệu nghiệp vụ.

## Cấu hình theo môi trường

Commit các file `*.properties.example`, không commit file chứa thông tin xác thực thực. `liquibase.properties.example` chỉ chứa driver và biến tham chiếu:

```properties
classpath=postgresql-42.7.4.jar
driver=org.postgresql.Driver
url=${LIQUIBASE_URL}
username=${LIQUIBASE_USERNAME}
password=${LIQUIBASE_PASSWORD}
logLevel=info
```

Mỗi môi trường truyền URL và thông tin xác thực từ secret store hoặc environment variables. Chỉ định master changelog theo database đích:

```bash
liquibase \
  --defaults-file=liquibase.properties \
  --changelog-file=changelog/databases/exchange/db.changelog-master.yaml \
  --url="$LIQUIBASE_URL" \
  --username="$LIQUIBASE_USERNAME" \
  --password="$LIQUIBASE_PASSWORD" \
  update
```

Tài khoản Liquibase chỉ cần quyền DDL/DML cần thiết trên database đích. Không dùng superuser của cluster nếu không bắt buộc.

## Kiểm thử và luồng CI/CD

Mỗi thay đổi schema phải được kiểm tra ít nhất ở bốn hướng:

| Nhóm test | Mục tiêu |
| --- | --- |
| `migration` | Áp dụng toàn bộ changelog lên database rỗng. |
| `constraints` | Xác nhận primary key, foreign key nội bộ database, unique/check constraint và index quan trọng. |
| `upgrade` | Nâng cấp từ release cũ sang release hiện tại. |
| `restore` | Xác nhận quy trình backup/restore, đặc biệt khi release không thể rollback an toàn. |

```text
Pull request
  → liquibase validate cho exchange, broker, vsd
  → liquibase update-sql cho từng database
  → review SQL dự kiến và test migration/constraint/upgrade
  → merge

Deploy staging/production cho từng database
  → backup hoặc snapshot
  → liquibase update
  → smoke test
  → deploy thành phần ứng dụng phụ thuộc
```

`liquibase validate` kiểm tra cấu trúc changelog, file tham chiếu, changeset trùng và checksum. Lệnh này không chứng minh SQL nghiệp vụ chạy thành công trên dữ liệu thực tế; cần chạy test trên database staging có cấu trúc và tải đại diện.

Trước khi deploy, chỉ một pipeline hoặc Kubernetes Job được chạy Liquibase trên mỗi database đích. Liquibase tạo `DATABASECHANGELOG` để lưu lịch sử và `DATABASECHANGELOGLOCK` để khóa đồng thời, nhưng cơ chế điều phối vẫn phải ngăn nhiều job cạnh tranh không cần thiết.

## Quy ước bất biến và khôi phục

- Không sửa, đổi tên hoặc xóa changeset đã chạy ở môi trường dùng chung. Mọi thay đổi tạo changeset mới.
- Một changeset chỉ gộp thay đổi có cùng mục đích và có thể review cùng nhau.
- Dùng tên file có tiền tố thứ tự trong release, ví dụ `005-create-outbox.sql`.
- Thay đổi có rủi ro dữ liệu triển khai theo hướng tương thích ngược: thêm cấu trúc mới → deploy ứng dụng tương thích → chuyển dữ liệu → xóa cấu trúc cũ ở release sau.
- Không tạo foreign key, join hoặc transaction xuyên `exchange`, `broker` và `vsd`; trao đổi bằng event/message cùng business reference có thể truy vết.
- Tách migration schema khỏi seed data; không include seed local/test vào production changelog.
- Rollback chỉ phù hợp với thay đổi nhỏ, có rollback hợp lệ và chưa có dữ liệu quan trọng. Với production, ưu tiên forward-fix và khôi phục từ backup/snapshot.

## Lệnh vận hành tối thiểu

```bash
./scripts/validate-all.sh
./scripts/update-sql.sh
./scripts/status.sh exchange
./scripts/migrate.sh exchange
```

`rollback.sh` chỉ hướng dẫn quy trình forward-fix hoặc restore; không được dùng để đảo migration production một cách tự động. Khi deploy production, lưu release, timestamp backup/snapshot và output `update-sql` cùng artifact triển khai để phục vụ audit.

## Tham khảo

- [Liquibase `update`](https://docs.liquibase.com/secure/reference-guide-5-1-1/init-update-and-rollback-commands/update)
- [Liquibase `validate`](https://docs.liquibase.com/secure/reference-guide-5-2/database-inspection-change-tracking-and-utility-commands/validate)
- [Liquibase changelog và lock tables](https://docs.liquibase.com/secure/user-guide-5-2-1/what-is-the-database-changelog-lock-table)
