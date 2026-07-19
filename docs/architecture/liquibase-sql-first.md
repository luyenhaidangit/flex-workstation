# Triển khai database PostgreSQL với Liquibase SQL-first

Tài liệu này quy định cách tổ chức và triển khai migration PostgreSQL (bao gồm `pgvector`) trong repository độc lập `flex-database`. Liquibase chỉ theo dõi, kiểm tra và chạy các file SQL; schema không phụ thuộc vào EF Core migration.

## Mục tiêu và phạm vi

- Giữ lịch sử thay đổi schema rõ ràng, có thứ tự và có thể audit.
- Dùng SQL thuần để tận dụng đầy đủ khả năng PostgreSQL/`pgvector`.
- Chạy migration tập trung qua CI/CD hoặc Kubernetes Job; không chạy từ từng pod ứng dụng.
- Không đưa mật khẩu, connection string thật hoặc secret vào repository.

Ví dụ dưới đây dùng PostgreSQL shared/control plane cho nền tảng AI. Quy ước này cũng áp dụng được cho từng database PostgreSQL khác, với một master changelog riêng.

## Cấu trúc repository

```text
flex-database/
├── README.md
├── CHANGELOG.md
├── docker-compose.yml
├── liquibase.properties.example
├── changelog/
│   ├── db.changelog-master.yaml
│   ├── releases/
│   │   ├── v1.0/
│   │   │   ├── db.changelog-v1.0.yaml
│   │   │   ├── 001-create-schema.sql
│   │   │   ├── 002-enable-pgvector.sql
│   │   │   ├── 003-create-knowledge-document.sql
│   │   │   └── 004-create-knowledge-chunk.sql
│   │   └── v1.1/
│   │       ├── db.changelog-v1.1.yaml
│   │       ├── 001-add-document-status.sql
│   │       └── 002-create-vector-index.sql
│   └── repeatable/
│       ├── functions/
│       ├── procedures/
│       └── views/
├── environments/
│   ├── local.properties
│   ├── development.properties
│   ├── staging.properties
│   └── production.properties
├── scripts/
│   ├── validate.sh
│   ├── update.sh
│   ├── status.sh
│   └── rollback.sh
├── seed/
│   ├── local/
│   └── test/
└── pipelines/
    ├── gitlab-ci.yml
    └── azure-pipelines.yml
```

`seed/` chỉ chứa dữ liệu dành cho local hoặc test; pipeline production không được gọi các script này. `repeatable/` dành cho database objects có thể thay thế như view, function và procedure; cần có changelog/quy ước thực thi rõ ràng trước khi đưa vào master changelog để tránh chạy ngoài ý muốn.

## Tổ chức changelog theo release

`changelog/db.changelog-master.yaml` là điểm vào duy nhất. Khai báo từng release tường minh để thứ tự migration được review và kiểm soát trong Git, thay vì tự động quét thư mục.

```yaml
databaseChangeLog:
  - include:
      file: releases/v1.0/db.changelog-v1.0.yaml
      relativeToChangelogFile: true

  - include:
      file: releases/v1.1/db.changelog-v1.1.yaml
      relativeToChangelogFile: true
```

Mỗi release có changelog riêng và cũng include file SQL theo thứ tự mong muốn:

```yaml
databaseChangeLog:
  - include:
      file: 001-create-schema.sql
      relativeToChangelogFile: true

  - include:
      file: 002-enable-pgvector.sql
      relativeToChangelogFile: true

  - include:
      file: 003-create-knowledge-document.sql
      relativeToChangelogFile: true

  - include:
      file: 004-create-knowledge-chunk.sql
      relativeToChangelogFile: true
```

Khi cần nhiều database, chuyển sang `changelog/databases/<database-name>/`; mỗi database phải có `db.changelog-master.yaml` riêng và pipeline truyền đúng master changelog mục tiêu.

## Viết migration bằng Liquibase formatted SQL

Mỗi file migration bắt đầu bằng `--liquibase formatted sql`. Một changeset phải có tổ hợp `id`, `author` và đường dẫn file duy nhất. Liquibase dùng tổ hợp này để nhận biết changeset đã chạy, đồng thời lưu checksum để phát hiện việc sửa nội dung đã được áp dụng.

Ví dụ bảng tài liệu tri thức:

```sql
--liquibase formatted sql

--changeset lhdang:20260719-001 labels:knowledge
CREATE TABLE knowledge_documents
(
    id          UUID PRIMARY KEY,
    tenant_id   UUID         NOT NULL,
    name        VARCHAR(255) NOT NULL,
    source_type VARCHAR(50)  NOT NULL,
    status      VARCHAR(30)  NOT NULL DEFAULT 'pending',
    metadata    JSONB,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX ix_knowledge_documents_tenant_id
    ON knowledge_documents (tenant_id);

--rollback DROP TABLE knowledge_documents;
```

Ví dụ bảng chunk dùng `pgvector`:

```sql
--liquibase formatted sql

--changeset lhdang:20260719-002 labels:knowledge
CREATE TABLE knowledge_chunks
(
    id          UUID PRIMARY KEY,
    tenant_id   UUID         NOT NULL,
    document_id UUID         NOT NULL,
    content     TEXT         NOT NULL,
    embedding   VECTOR(1536),
    metadata    JSONB,
    chunk_index INTEGER      NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_knowledge_chunks_document
        FOREIGN KEY (document_id)
        REFERENCES knowledge_documents (id)
);

CREATE INDEX ix_knowledge_chunks_tenant_document
    ON knowledge_chunks (tenant_id, document_id);

--rollback DROP TABLE knowledge_chunks;
```

File `002-enable-pgvector.sql` phải tạo extension trước khi có bất kỳ cột `VECTOR` nào:

```sql
--liquibase formatted sql

--changeset lhdang:20260719-000 labels:platform
CREATE EXTENSION IF NOT EXISTS vector;

--rollback DROP EXTENSION IF EXISTS vector;
```

## Cấu hình theo môi trường

Commit `liquibase.properties.example`, không commit file chứa thông tin xác thực thực. Ví dụ:

```properties
changelogFile=changelog/db.changelog-master.yaml
driver=org.postgresql.Driver
url=jdbc:postgresql://localhost:5432/ai_platform
username=postgres
password=change-me
logLevel=info
```

Ở staging và production, CI/CD nhận kết nối từ secret store hoặc environment variables:

```bash
liquibase \
  --changelog-file=changelog/db.changelog-master.yaml \
  --url="$DATABASE_URL" \
  --username="$DATABASE_USERNAME" \
  --password="$DATABASE_PASSWORD" \
  update
```

Tài khoản chạy Liquibase chỉ nên có quyền DDL/DML cần thiết trên database đích. Không dùng tài khoản owner hoặc superuser của cluster nếu không bắt buộc, ngoại trừ quyền tạo extension được cấp theo chính sách vận hành.

## Luồng CI/CD

```text
Pull request
  → liquibase validate
  → liquibase update-sql
  → review SQL dự kiến
  → merge

Deploy staging
  → backup/snapshot
  → liquibase update
  → smoke test
  → deploy ứng dụng

Deploy production
  → approval
  → backup/snapshot
  → liquibase update
  → smoke test
  → deploy ứng dụng
```

`liquibase validate` kiểm tra cấu trúc changelog, file tham chiếu, changeset trùng và checksum. Lệnh này không chứng minh SQL nghiệp vụ sẽ chạy thành công trên dữ liệu thực tế; migration vẫn phải được thử trên database staging có cấu trúc và tải đại diện.

Trước khi chạy production, bảo đảm chỉ có một pipeline hoặc Kubernetes Job được phép chạy Liquibase. Liquibase tạo `DATABASECHANGELOG` để lưu lịch sử và `DATABASECHANGELOGLOCK` để khóa đồng thời, nhưng cơ chế điều phối triển khai vẫn phải ngăn nhiều job cạnh tranh không cần thiết.

## Quy ước bất biến

- Không sửa, đổi tên hoặc xóa changeset đã chạy trên môi trường dùng chung. Mọi thay đổi tạo changeset mới.
- Một changeset chỉ gộp các thay đổi có cùng mục đích và có thể review cùng nhau.
- Dùng tên file có tiền tố thứ tự trong release, ví dụ `005-add-knowledge-language.sql`.
- Thay đổi có rủi ro dữ liệu triển khai theo hướng tương thích ngược: thêm cấu trúc mới → deploy ứng dụng tương thích → chuyển dữ liệu → xóa cấu trúc cũ ở release sau.
- Rollback phù hợp nhất với thay đổi nhỏ và chưa có dữ liệu quan trọng. Với production, ưu tiên forward-fix và kế hoạch khôi phục từ backup/snapshot.
- Tách migration schema khỏi seed data. Không đưa dữ liệu local/test vào changelog production.
- Migration tạo vector index cần được benchmark trên staging; chọn loại index và tham số dựa trên số lượng vector, kiểu truy vấn và yêu cầu recall thực tế.

## Lệnh vận hành tối thiểu

```bash
liquibase --defaults-file=liquibase.properties validate
liquibase --defaults-file=liquibase.properties status --verbose
liquibase --defaults-file=liquibase.properties update-sql
liquibase --defaults-file=liquibase.properties update
```

Chỉ chạy `rollback` khi changeset có rollback hợp lệ, tác động dữ liệu đã được đánh giá và người phụ trách deployment chấp thuận. Với production, ghi nhận release, timestamp backup/snapshot và output `update-sql` cùng artifact triển khai để có thể audit.

## Tham khảo

- [Liquibase `update`](https://docs.liquibase.com/secure/reference-guide-5-1-1/init-update-and-rollback-commands/update)
- [Liquibase `validate`](https://docs.liquibase.com/secure/reference-guide-5-2/database-inspection-change-tracking-and-utility-commands/validate)
- [Liquibase changelog và lock tables](https://docs.liquibase.com/secure/user-guide-5-2-1/what-is-the-database-changelog-lock-table)
