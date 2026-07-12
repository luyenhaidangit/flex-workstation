# Tasks: Nền tảng lưu trữ PostgreSQL

**Đầu vào**: Design documents từ `specs/000002-postgresql-database/`

**Điều kiện tiên quyết**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`

**Tests**: Không tạo automated test vì feature chỉ thay đổi Docker Compose local/dev. Các task validation thủ công bên dưới là bắt buộc và map trực tiếp tới acceptance criteria, security và regression risk.

**Tổ chức**: Task được nhóm theo user story để mỗi story có thể được kiểm tra và deliver độc lập.

## Format: `[ID] [P?] [Story?] Description with path`

- **[P]**: Có thể chạy song song do không sửa cùng file và không phụ thuộc task chưa hoàn tất.
- **[US1]**, **[US2]**: User story được phục vụ bởi task.

## Phase 1: Setup

**Mục đích**: Bảo vệ secret local trước khi thêm PostgreSQL configuration.

- [ ] T001 Tạo `flex-environment/.gitignore` để ignore `.env`, `secrets/`, `*.secret` và file password PostgreSQL local; không ignore compose hoặc tài liệu cần review.

**Checkpoint**: Secret local có vị trí rõ ràng ngoài Git trước khi service được cấu hình.

---

## Phase 2: Foundational

**Mục đích**: Cấu hình secret dùng chung cho mọi luồng PostgreSQL.

- [ ] T002 Khai báo top-level secret `postgres_password` và mount nó chỉ vào service PostgreSQL trong `flex-environment/docker-compose.yml`, dùng `POSTGRES_PASSWORD_FILE` thay vì password plaintext. (phụ thuộc T001)

**Checkpoint**: Docker Compose có thể nhận password từ file/secret ngoài Git mà không đưa credential vào configuration tracked.

---

## Phase 3: User Story 1 — Lưu và truy xuất dữ liệu bền vững (Priority: P1) MVP

**Goal**: Cung cấp PostgreSQL local/dev có data directory bền vững, để dữ liệu smoke vẫn đọc được sau khi recreate container.

**Independent Test**:

1. Khởi động `postgresdb` trong `flex-environment` với secret local hợp lệ.
2. Tạo và đọc một bản ghi smoke bằng client được cấp quyền trong Docker network.
3. Recreate service mà không xóa `postgresdb_data`, rồi xác nhận bản ghi smoke vẫn tồn tại.

- [ ] T003 [US1] Khai báo named volume `postgresdb_data` trong `flex-environment/docker-compose.yml` để lưu data directory PostgreSQL 16 tại `/var/lib/postgresql/data`. (phụ thuộc T002)
- [ ] T004 [US1] Thêm service `postgresdb` dùng image `postgres:16-alpine`, network `flex_net`, `POSTGRES_USER`, `POSTGRES_DB` và named volume trong `flex-environment/docker-compose.yml`; không publish host port mặc định. (phụ thuộc T003)
- [ ] T005 [US1] Bổ sung section PostgreSQL local/dev trong `flex-environment/INSTALL.md`: cấp secret local, khởi động service, tạo/đọc smoke data bằng `psql`, recreate container giữ volume và điều kiện pass theo AC-001/AC-002. (phụ thuộc T004)
- [ ] T006 [US1] Chạy validation persistence theo `specs/000002-postgresql-database/quickstart.md`: `docker compose config`, khởi động `postgresdb`, tạo/đọc smoke data, recreate không xóa volume và ghi kết quả không chứa secret. (phụ thuộc T005)

**Checkpoint**: US-001 pass khi data smoke đọc lại đúng sau recreate và không có credential trong tracked files/output lưu giữ.

---

## Phase 4: User Story 2 — Nhận biết trạng thái không sẵn sàng của kho dữ liệu (Priority: P1)

**Goal**: Người vận hành có thể xác định PostgreSQL sẵn sàng hay không sẵn sàng, mà không nhầm container đã start với database dùng được.

**Independent Test**:

1. Khởi động `postgresdb` với secret hợp lệ và xác nhận Docker báo `healthy`.
2. Dừng PostgreSQL hoặc dùng secret sai trong môi trường disposable.
3. Xác nhận trạng thái fail/unhealthy rõ ràng, không có smoke write thành công giả.

- [ ] T007 [US2] Thêm `pg_isready` healthcheck cho `postgresdb` trong `flex-environment/docker-compose.yml` với `interval: 5s`, `timeout: 3s`, `retries: 3` và `start_period: 30s`. (phụ thuộc T004)
- [ ] T008 [US2] Cập nhật section PostgreSQL trong `flex-environment/INSTALL.md` với lệnh kiểm tra `docker compose ps`, cách nhận biết unhealthy/khởi động lỗi và lưu ý consumer tương lai phải dùng `depends_on: condition: service_healthy` cùng retry/timeout riêng. (phụ thuộc T007)
- [ ] T009 [US2] Chạy validation unavailable-path theo `specs/000002-postgresql-database/quickstart.md`: xác nhận `healthy` khi secret hợp lệ, sau đó dừng service hoặc dùng secret sai ở môi trường disposable và xác nhận failure rõ ràng. (phụ thuộc T008)

**Checkpoint**: US-002 pass khi readiness check hoàn tất trong tối đa 5 giây và database không sẵn sàng không bị báo là usable.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Hoàn tất governance migration, security review, rollback và regression của stack.

- [ ] T010 Cập nhật section PostgreSQL trong `flex-environment/INSTALL.md` với quy ước migration versioned thuộc repo consumer, không dùng `/docker-entrypoint-initdb.d/` làm migration lặp lại, cùng rollback giữ `postgresdb_data` trừ môi trường disposable.
- [ ] T011 Chạy security/review command: `git -C flex-environment diff --check`, `git -C flex-environment status --short` và `docker compose --project-directory flex-environment config`; xác nhận không có password, secret hoặc connection string trong diff/output lưu giữ. (phụ thuộc T001, T002, T004, T007, T010)
- [ ] T012 Chạy regression validation trong `flex-environment`: khởi động stack Compose hiện có và xác nhận Redis, SQL Server và các volume hiện hữu không bị thay thế bởi `postgresdb`. (phụ thuộc T011)

---

## Validation Commands

- Compose syntax: `docker compose --project-directory flex-environment config`
- Start PostgreSQL: `docker compose --project-directory flex-environment up -d postgresdb`
- Readiness status: `docker compose --project-directory flex-environment ps postgresdb`
- Service logs: `docker compose --project-directory flex-environment logs postgresdb`
- Security/diff review: `git -C flex-environment diff --check`
- Full validation guide: `specs/000002-postgresql-database/quickstart.md`

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US-001 | T003, T004, T005, T006 |
| AC-001 / FR-001 / FR-002 | T004, T005, T006 |
| AC-002 / FR-003 | T003, T006 |
| US-002 | T007, T008, T009 |
| AC-003 / FR-004 / NFR-001 | T007, T008, T009 |
| AC-004 / FR-005 / BR-001 / BR-002 | T008, T009 |
| FR-006 / NFR-003 | T010 |
| BR-003 / SEC-002 | T001, T002, T011 |
| SEC-001 | T002, T008, T011 |
| NFR-002 | T005, T006 |
| SC-001 | T006 |
| SC-002 | T009 |
| SC-003 | T008, T009 |

## Dependencies & Execution Order

- **Setup (T001)**: Có thể bắt đầu ngay.
- **Foundational (T002)**: Phụ thuộc T001 và chặn mọi task PostgreSQL.
- **US-001 (T003–T006)**: Chạy tuần tự sau T002 vì cùng thay đổi Compose/hướng dẫn.
- **US-002 (T007–T009)**: Bắt đầu sau T004; thực hiện sau US-001 để tránh conflict `docker-compose.yml` và `INSTALL.md`.
- **Polish (T010–T012)**: Chạy sau hai user story.

## Parallel Opportunities

- Không có task `[P]` trong feature này: các task implementation và tài liệu đều lần lượt thay đổi `flex-environment/docker-compose.yml` hoặc `flex-environment/INSTALL.md`. Validation phụ thuộc Compose configuration hoàn chỉnh.

## Implementation Strategy

### MVP first — US-001

1. Hoàn tất T001–T006.
2. Xác nhận PostgreSQL giữ được smoke data qua recreate container.
3. Có thể demo nền tảng persistence mà chưa cần application consumer.

### Incremental delivery

1. Bổ sung healthcheck và unavailable-path qua T007–T009.
2. Hoàn tất migration governance, security review và regression qua T010–T012.
3. Feature tiêu thụ sau này mới thêm connection configuration, schema và migration thực tế.

## Checklist chất lượng

- [x] Mỗi task có checkbox, ID, mô tả cụ thể và file path hoặc command validation.
- [x] Mỗi user story có phase, independent test và checkpoint riêng.
- [x] Không có task ngoài scope schema/API/application consumer.
- [x] Security, persistence, healthcheck, rollback, migration ownership và regression đều có task tương ứng.
- [x] Không có placeholder hoặc task ví dụ từ template.
