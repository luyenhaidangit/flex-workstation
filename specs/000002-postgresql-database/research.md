# Research: Nền tảng lưu trữ PostgreSQL

## DEC-001 — PostgreSQL container và volume bền vững

**Decision**: Dùng Docker Official Image `postgres:16-alpine`, named volume `postgresdb_data` mount tại `/var/lib/postgresql/data`.

**Rationale**: Image được pin major version để tránh nâng major ngoài ý muốn. Named volume tách dữ liệu khỏi vòng đời container và đúng data path mặc định của PostgreSQL 16.

**Alternatives considered**:

- `postgres:latest`: Không chọn vì không kiểm soát được version thay đổi.
- Không dùng volume: Không chọn vì dữ liệu mất khi recreate container.
- Bind mount host: Không chọn vì phụ thuộc path và permission của từng máy.

**Risks remaining**: Không nâng PostgreSQL major bằng recreate trên volume hiện tại; mọi major upgrade cần backup, migration plan và rollback riêng.

**Nguồn**: [Docker Official PostgreSQL Image](https://hub.docker.com/_/postgres)

## DEC-002 — Readiness và thứ tự khởi động

**Decision**: PostgreSQL khai báo `healthcheck` dùng `pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}` với `interval: 5s`, `timeout: 3s`, `retries: 3` và `start_period: 30s`. Consumer sau này dùng long-form `depends_on` với `condition: service_healthy`, đồng thời có retry/timeout cho lỗi runtime.

**Rationale**: Container đã start không đồng nghĩa PostgreSQL đã sẵn sàng nhận kết nối. `pg_isready` cho biết server có đang nhận kết nối hay không; Compose chỉ chờ readiness khi dùng `service_healthy`.

**Alternatives considered**:

- `service_started`: Không chọn vì gây race condition khi PostgreSQL chưa sẵn sàng.
- TCP port check: Không chọn vì không chứng minh PostgreSQL đã ready.

**Risks remaining**: Healthcheck không xác minh quyền thao tác nghiệp vụ và không thay retry/reconnect của consumer khi database lỗi sau startup.

**Nguồn**: [PostgreSQL `pg_isready`](https://www.postgresql.org/docs/current/app-pg-isready.html), [Docker Compose startup order](https://docs.docker.com/compose/how-tos/startup-order/)

## DEC-003 — Secret và network exposure

**Decision**: Password được cấp bằng Docker secret hoặc file ngoài Git qua `POSTGRES_PASSWORD_FILE`; user/database không nhạy cảm được cấu hình riêng. PostgreSQL chỉ ở Docker network nội bộ, không publish host port mặc định.

**Rationale**: Password trong Compose hoặc tracked `.env` vi phạm BR-003 và SEC-002. Docker Compose secrets giới hạn secret cho service khai báo; network nội bộ giảm bề mặt truy cập.

**Alternatives considered**:

- Password qua environment variable trong file tracked: Không chọn vì dễ lộ qua Git, config inspection hoặc log.
- Publish cổng database ra mọi host interface: Không chọn vì không cần cho MVP và tăng bề mặt tấn công.

**Risks remaining**: Cần quy định nguồn và rotation secret theo từng môi trường; nếu local dev phải expose port, chỉ bind loopback sau khi có yêu cầu rõ.

**Nguồn**: [Docker Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/), [Docker Compose networking](https://docs.docker.com/compose/how-tos/networking/), [Docker Official PostgreSQL Image](https://hub.docker.com/_/postgres)

## DEC-004 — Khởi tạo database và migration

**Decision**: Init scripts chỉ dùng để bootstrap data directory rỗng. Schema/migration versioned, migration ledger, rollout và rollback thuộc repo consumer được xác định trong feature nghiệp vụ tiếp theo.

**Rationale**: Official image chỉ chạy init scripts khi data directory rỗng, nên chúng không phù hợp cho migration lặp lại trên môi trường đã có dữ liệu. Feature hiện tại chưa có schema hay owner dữ liệu.

**Alternatives considered**:

- Dùng `/docker-entrypoint-initdb.d/` như migration runner: Không chọn vì script không chạy lại trên volume đã tồn tại.
- Migration thủ công: Không chọn vì không nhất quán, không traceable và không rollback được.

**Risks remaining**: Consumer chưa xác định, do đó không được bắt đầu implementation schema/migration cho đến khi repo owner và feature nghiệp vụ được phê duyệt.

**Nguồn**: [Docker Official PostgreSQL Image](https://hub.docker.com/_/postgres)
