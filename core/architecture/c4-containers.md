# C4 Container - Flex Platform

Nguồn: `workstation.json` và `docs/architecture/system-map.md` (mục 4, 5, 6, 7). Chỉ vẽ cạnh đã có bằng chứng trong tài liệu; chưa đối chiếu với code từng repo.

```mermaid
C4Container
  title Container Diagram - Flex Platform

  Person(user, "Người dùng", "Dùng giao diện web")

  System_Boundary(flex, "Flex Platform") {
    Container(frontend, "flex-microfrontend", "Angular", "Giao diện người dùng")
    Container(gateway, "flex-api-gateway", ".NET", "Route và proxy API")
    Container(auth, "flex-auth-service", ".NET", "Xác thực, phân quyền")
    Container(agent, "flex-agent-service", ".NET 9, SignalR", "Nền tảng AI Agent đa tenant")
    Container(dbmigrate, "flex-database", "Liquibase SQL", "Migration và seed dùng chung")
    Container(exchange, "flex-exchange-service", ".NET", "Lõi khớp lệnh limit in-memory")
  }

  System_Boundary(data, "Data stores") {
    ContainerDb(agentdb, "PostgreSQL agentdb", "PostgreSQL", "Agent catalog")
    ContainerDb(authdb, "PostgreSQL auth", "PostgreSQL", "Identity của auth-service")
    ContainerDb(qdrant, "Qdrant", "Vector DB", "Tri thức agent theo tenant")
    System_Ext(oracle, "Oracle Cloud DB", "Legacy, đang bỏ dần")
  }

  UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")

  Rel_D(user, frontend, "Sử dụng", "HTTPS")
  Rel_R(frontend, gateway, "Gọi API", "HTTPS")
  Rel_R(gateway, auth, "Chuyển tiếp", "HTTP")
  Rel_D(auth, authdb, "Đọc/ghi", "SQL")
  Rel_D(auth, oracle, "Legacy", "SQL")
  Rel_D(agent, agentdb, "Đọc/ghi", "SQL")
  Rel_D(agent, qdrant, "Tìm vector", "HTTP")
  Rel_U(dbmigrate, agentdb, "Migrate", "SQL")

  UpdateRelStyle(agent, qdrant, $offsetX="30", $offsetY="-30")
  UpdateRelStyle(auth, oracle, $offsetX="-90", $offsetY="40")
```

## Ghi chú

| Cạnh / thành phần | Trạng thái | Bằng chứng |
| --- | --- | --- |
| frontend → gateway → auth | `Inferred` | `system-map.md` mục 6 (sơ đồ cũ) |
| auth → PostgreSQL | `Confirmed`, đang migrate | `specs/000009-auth-postgres-migration` |
| auth → Oracle | `Confirmed by user`, sẽ bỏ | `system-map.md` mục 5 |
| agent → agentdb, Qdrant | `Confirmed` | `specs/000008-agent-platform-mvp`, mục 5 |
| dbmigrate → agentdb | `Confirmed by user` | `flex-database/agentdb/` |
| `flex-exchange-service` | Chạy độc lập, chưa có cạnh | `system-map.md` mục 4 |

## Chưa vẽ (cần xác minh)

- `flex-k8s`: mới khởi tạo, chưa có workload.
- `flex-environment`: stack local/dev (Redis, RabbitMQ, MinIO, Elasticsearch, Kibana, Jenkins, Portainer, Ollama). Nên vẽ ở `c4-deployment.md`.
- MySQL database-per-tenant và PostgreSQL `flexdb`: chưa rõ service nào truy cập.
- Giao thức `gateway → auth`, `agent → qdrant` đang ghi theo giả định, cần đối chiếu code.
