# Kế hoạch triển khai: Nền tảng lưu trữ PostgreSQL

**Branch**: `000002-postgresql-database` | **Ngày**: 2026-07-12 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: Đặc tả tính năng từ `specs/000002-postgresql-database/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**: Cung cấp PostgreSQL bền vững, có trạng thái sẵn sàng rõ ràng, không báo ghi thành công giả và có quy ước quản lý thay đổi cấu trúc dữ liệu giữa các môi trường.

**Hướng tiếp cận kỹ thuật dự kiến**: Bổ sung một PostgreSQL service vào Docker Compose của `flex-environment`, sử dụng image PostgreSQL pin major version, named volume, healthcheck và secret được cấp ngoài Git. Không tạo schema hoặc API nghiệp vụ trong feature nền tảng này.

**Kết quả sau research**: Dùng `pg_isready` làm readiness hạ tầng; service tiêu thụ sau này phải chờ `service_healthy` và tự kiểm tra kết nối/thao tác dữ liệu. Script trong `/docker-entrypoint-initdb.d/` chỉ dùng để bootstrap data directory rỗng, không thay migration lặp lại.

## Phạm vi kỹ thuật

**Trong phạm vi**:

- Bổ sung PostgreSQL service, named volume, healthcheck và network attachment vào `flex-environment/docker-compose.yml`.
- Bổ sung cấu hình local chưa theo dõi Git để cấp PostgreSQL user, database và password secret; cập nhật hướng dẫn setup/validation tại `flex-environment/INSTALL.md`.
- Ghi quy ước: schema và migration versioned thuộc repo feature tiêu thụ; mọi migration phải có rollout, rollback và kiểm tra sau áp dụng trước khi thay đổi cấu trúc dữ liệu.
- Kiểm chứng persistence, readiness và tình huống PostgreSQL không khả dụng bằng Docker Compose và client PostgreSQL.

**Ngoài phạm vi kỹ thuật**:

- Không thay đổi source code, connection string, ORM, schema nghiệp vụ hoặc API của `flex-auth-service`, `flex-api-gateway` hay `flex-microfrontend`.
- Không tạo migration/backfill dữ liệu nghiệp vụ, backup/disaster recovery hoặc high availability.
- Không tự động migrate requirements checklist hoặc cấu hình có secret hiện hữu.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: Docker Compose V2; PostgreSQL Docker Official Image, pin `postgres:16-alpine` trong phase này.

**Service/App liên quan**: `flex-environment` là infrastructure stack; consumer ứng dụng chưa được xác định.

**Phụ thuộc chính**: Docker Engine/Compose, Docker Official PostgreSQL image và Docker secret hoặc file secret ngoài Git.

**Lưu trữ**: PostgreSQL 16, named volume `postgresdb_data`, mount tại `/var/lib/postgresql/data`.

**Kiểm thử**: `docker compose config`, `docker compose up`, health status, `psql` smoke test và kiểm tra persistence sau recreate container.

**Nền tảng chạy**: Docker Engine trên môi trường local/dev.

**Đơn vị deploy**: Service `postgresdb` trong Compose project `flex-environment`.

**Loại project**: Local/dev infrastructure stack.

**Mục tiêu hiệu năng**: Mỗi lần healthcheck hoàn tất trong tối đa 5 giây theo NFR-001; đọc lại smoke data trong tối đa 3 giây theo NFR-002.

**Ràng buộc**: Không lưu secret, password, token hay connection string trong repository, log hoặc artifact Speckit; không publish cổng database ra host nếu chưa có nhu cầu local dev được xác nhận.

**Quy mô/Phạm vi**: Một service database không schema nghiệp vụ và một named volume trong stack local/dev hiện hữu.

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Chỉ tạo nền tảng database; schema, API và consumer vẫn ngoài phạm vi. |
| Traceability Gate | Pass | Pass | US/FR/BR/SEC/NFR có mapping sang Compose, hướng dẫn và validation. |
| Test Gate | Pass | Pass | Có validation config, healthcheck, persistence và unavailable-path. |
| Security Gate | Pass | Pass | Password dùng secret/file ngoài Git; không in giá trị cấu hình nhạy cảm. |
| Compatibility Gate | Pass | Pass | Thêm service độc lập; không thay contract, schema hay data hiện có. |
| Observability Gate | Pass | Pass | Health status, log service không chứa secret và smoke check được quy định. |
| Complexity Gate | Pass | Pass | Docker Compose và named volume có sẵn trong repo; không thêm orchestration hoặc HA. |
| Release Gate | Không áp dụng | Không áp dụng | Đây là local/dev infrastructure; rollout và rollback Compose vẫn được mô tả. |

## Câu hỏi kỹ thuật cần research

- Không còn câu hỏi chặn. Các quyết định và phương án bị loại được ghi tại [research.md](research.md).

## Thiết kế tổng quan

**Luồng chính**:

1. Docker Compose đọc cấu hình không nhạy cảm và secret PostgreSQL từ nguồn ngoài Git, rồi tạo service `postgresdb` trong network `flex_net` với healthcheck `pg_isready` có `interval: 5s`, `timeout: 3s`, `retries: 3` và `start_period: 30s`.
2. PostgreSQL khởi tạo data directory trống một lần, lưu dữ liệu trong named volume `postgresdb_data` và báo readiness qua `pg_isready`.
3. Consumer được xác định ở feature sau sẽ kết nối bằng service name trong network, chỉ chạy sau `service_healthy`, đồng thời tự xử lý timeout/retry và không xác nhận ghi khi transaction chưa hoàn tất.
4. Migration schema nghiệp vụ được quản lý versioned tại repo consumer; feature này chỉ cung cấp database trống và quy ước triển khai migration.

**Component/module tham gia**:

- `flex-environment/docker-compose.yml`: Khai báo image, service, healthcheck, volume và network của PostgreSQL.
- `flex-environment/docker-compose.override.yml`: Chỉ chứa wiring local không nhạy cảm khi cần; không hard-code password.
- `flex-environment/INSTALL.md`: Hướng dẫn secret provisioning, khởi động, smoke test, rollback và các tình huống lỗi.
- Repo consumer chưa xác định: Sẽ sở hữu connection configuration, schema, migration và retry policy khi có feature nghiệp vụ được duyệt.

**Luồng thay thế/lỗi chính**:

- Nếu secret không được cấp hoặc healthcheck không pass, service được xem là không sẵn sàng; không được đánh dấu ready.
- Nếu PostgreSQL không truy cập được, consumer sau này phải báo failure rõ ràng và không xác nhận ghi; retry chỉ được thực hiện an toàn theo transaction/idempotency của consumer.
- Nếu cần reset môi trường disposable sau khi init lỗi, dừng service và xóa riêng named volume theo runbook; không dùng thao tác này với dữ liệu cần giữ.

**Thay đổi boundary giữa service/module**: Không có public API hay event. Service name nội bộ `postgresdb` là interface hạ tầng nội bộ; consumer và connection contract sẽ được thiết kế trong feature tiêu thụ.

**Idempotency/Concurrency**: `docker compose up` có thể chạy lặp lại mà giữ volume. Init scripts chỉ chạy khi data directory rỗng; migration nghiệp vụ không được đặt ở init scripts vì phải chạy lặp lại, có version và rollback riêng.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001, FR-002 | P1 | Đủ rõ | PostgreSQL service trên `flex_net`, database trống sẵn sàng cho consumer | `flex-environment/docker-compose.yml` | Internal Compose service | PostgreSQL database | `psql` create/read smoke test |
| FR-003 / AC-002 | P1 | Đủ rõ | Named volume gắn đúng PGDATA của PostgreSQL 16 | `flex-environment/docker-compose.yml` | Không áp dụng | `postgresdb_data` | Recreate container và đọc lại smoke data |
| US-002 / FR-004, NFR-001 | P1 | Đủ rõ | `pg_isready` healthcheck, status và hướng dẫn kiểm tra | Compose + `INSTALL.md` | Health status nội bộ | Không áp dụng | Dừng service hoặc cấp secret sai, xác nhận unhealthy/fail |
| FR-005 / BR-001, BR-002 | P1 | Đủ rõ | Consumer chỉ xác nhận commit thành công; hạ tầng không giả trạng thái ready | Feature consumer tiếp theo | Không áp dụng | Transaction dữ liệu nghiệp vụ | Integration test ở consumer trước khi áp dụng |
| FR-006 / NFR-003 | P2 | Đủ rõ | Migration versioned thuộc repo consumer, không dùng init script làm migration | `INSTALL.md` + plan feature consumer | Không áp dụng | Migration ledger của consumer | Migration dry-run/rollback ở feature consumer |
| SEC-001, SEC-002 / BR-003 | P1 | Đủ rõ | Secret mount/file ngoài Git; giới hạn network và không log secret | Compose + `.gitignore`/runbook nếu cần | Không áp dụng | Secret file | Rà Git diff, `docker compose config` không in secret |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Thêm PostgreSQL trống và volume; chưa có schema/migration | Không chạm dữ liệu hiện có | Xác nhận service và volume mới |
| API/Contract | Không áp dụng | Không có consumer contract trong feature này | Rà không có endpoint/event mới |
| Permission/Security | Cần secret ngoài Git và network nội bộ | Lộ secret nếu dùng biến hard-code | Rà tracked files, logs và Compose config |
| Logging/Audit | Dùng health status và service logs; audit migration do consumer sở hữu | Không log credential/connection string | Rà log và runbook |
| UI/UX | Không áp dụng | Không áp dụng | Không áp dụng |
| Job/Worker/Integration | Docker Compose provisioning; consumer future chờ healthcheck | Consumer chưa xác định không được tự giả định | Rà scope feature tiếp theo |

## API/Contract Detail

**Có thay đổi contract không**: Không. Không tạo `contracts/` vì feature không expose API, event, CLI hay public library contract.

## Permission Matrix

| Actor | Quyền | Cách thực thi | Ghi chú |
|-------|-------|---------------|---------|
| Docker Compose operator | Khởi động/dừng và cấp secret | Docker host + secret store/file local | Không commit secret |
| Consumer được phê duyệt | Kết nối database qua `flex_net` | Credential tối thiểu theo feature consumer | Chưa tạo trong feature này |
| Thành phần không được cấp quyền | Không truy cập database | Không attach network/không có secret | Không publish host port mặc định |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Có PostgreSQL data directory trống; không có schema nghiệp vụ, backfill hoặc migration trong feature này.

**Persistence**: Named volume `postgresdb_data` bảo toàn dữ liệu khi container bị recreate; không đổi PostgreSQL major version bằng cách recreate trên volume cũ.

**Quy ước migration**: Mỗi repo consumer sở hữu migration versioned, migration ledger, kế hoạch rollout/rollback và post-migration check. Init scripts trong image chỉ dùng bootstrap database rỗng; không dùng để áp migration lặp lại.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | `postgres:16-alpine` pin major version | Cân bằng footprint local/dev và tính ổn định; tránh `latest` | `postgres:latest` | Có thể đổi major ngoài ý muốn |
| DEC-002 | Named volume `postgresdb_data` tại `/var/lib/postgresql/data` | Bảo toàn dữ liệu đúng layout PostgreSQL 16 | Không dùng volume hoặc bind mount | Không bền vững hoặc phụ thuộc path/permission host |
| DEC-003 | `pg_isready` healthcheck; consumer dùng `service_healthy` | Phân biệt container chạy với PostgreSQL nhận kết nối | `service_started` hoặc TCP check | Không chứng minh database usable |
| DEC-004 | Password qua Docker secret hoặc file ngoài Git với `POSTGRES_PASSWORD_FILE` | Phù hợp BR-003/SEC-002 | Password trong Compose hoặc tracked `.env` | Rủi ro lộ credential |
| DEC-005 | Migration schema do repo consumer sở hữu | Không có schema/người sở hữu dữ liệu trong feature nền tảng | SQL init script làm migration chung | Chỉ chạy khi volume rỗng, không có version/rollback lặp lại |

## Chiến lược kiểm thử

**Unit test**: Không áp dụng; feature là Compose configuration.

**Integration test**: Dùng client `psql` trong network để tạo và đọc một bản ghi smoke; xác nhận dữ liệu sau khi recreate service mà không xóa volume.

**Contract test**: Không áp dụng; không có public contract hoặc consumer được chọn.

**Permission/security test**: Rà `git diff`, files tracked và output lệnh để chắc password/connection string không xuất hiện; xác nhận service không có host port mặc định.

**E2E/manual test**: Chạy `docker compose config`, khởi động `postgresdb`, chờ `healthy`, tạo/read smoke data, recreate service và đọc lại. Dừng PostgreSQL để xác nhận health/failure rõ ràng.

**Regression test**: Khởi động các service Compose hiện có; xác nhận chúng giữ nguyên network/volume và PostgreSQL không thay thế SQL Server hay Redis hiện hữu.

## Cấu trúc project

```text
flex-environment/
├── docker-compose.yml
├── docker-compose.override.yml
├── INSTALL.md
└── .gitignore                 # Chỉ cập nhật nếu cần ignore secret local
specs/000002-postgresql-database/
├── plan.md
├── research.md
├── data-model.md
└── quickstart.md
```

## Rollout & Rollback

**Kế hoạch rollout**: Cập nhật Compose và runbook trong `flex-environment`; cấp secret qua cơ chế ngoài Git; chạy `docker compose config`, khởi động service, chờ healthy và thực hiện smoke test persistence.

**Tương thích ngược**: Service mới không thay thế `sqlserverdb`, Redis hay các volume hiện tại. Không có schema/API consumer để thay đổi.

**Feature flag/config**: Không áp dụng; service được quản lý bằng Docker Compose profile/cấu hình stack nếu repo hiện hữu yêu cầu.

**Rollback code/config**: Dừng và loại service PostgreSQL khỏi Compose revision mới; giữ named volume nếu cần bảo toàn dữ liệu phục vụ điều tra hoặc khôi phục.

**Rollback dữ liệu/migration**: Không có migration. Chỉ được xóa `postgresdb_data` tại môi trường disposable sau khi xác nhận dữ liệu không cần giữ.

**Điều kiện kích hoạt rollback**: Healthcheck không ổn định, persistence smoke test fail, secret bị xuất hiện trong artifact hoặc service mới ảnh hưởng stack hiện hữu.

## Observability & Debug

**Log cần có**: Lifecycle/health log của service PostgreSQL và kết quả smoke check; không log câu lệnh chứa password hoặc connection string.

**Dữ liệu không được log**: Password, secret file path có giá trị nhạy cảm, token, connection string và nội dung dữ liệu nghiệp vụ.

**Metric cần theo dõi**: Docker health status; thời gian từ start đến healthy; thời gian smoke create/read.

**Trace/Correlation**: Timestamp runbook, tên Compose project/service và phiên bản image; không dùng credential làm correlation field.

**Cách kiểm tra sau release**: `docker compose ps` báo `healthy`, `psql` smoke test pass, recreate service không xóa volume và data đọc lại đúng.

**Tình huống debug chính**: Secret thiếu/sai, volume mount sai, database không healthy, port/network không cần thiết bị expose, hoặc consumer sau này chạy trước database healthy.

## Checklist sẵn sàng cho `$speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component và điểm thay đổi.
- [x] Idempotency/concurrency đã được đánh giá.
- [x] Mỗi `US`/`FR` P1/P2 có mapping sang path và kiểm thử.
- [x] Tác động data, contract, permission, logging và integration đã được đánh giá.
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử, rollout và rollback đã rõ.
- [x] Constitution gate không còn blocker.
