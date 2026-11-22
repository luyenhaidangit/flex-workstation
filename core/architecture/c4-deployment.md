# C4 Deployment - Flex (server đang dựng)

Nguồn: `flex-environment/AGENTS.md`, `flex-environment/docker-compose.{nginx,tools,secrets}.yml`, `flex-k8s/README.md`, `flex-k8s/manifests/`, `flex-k8s/argocd/`, cùng xác nhận của người dùng về phân tách Docker dùng chung và k8s riêng từng project. Chỉ đọc cấu hình trong repo, chưa kiểm tra server thật (`kubectl`, `docker ps`), nên đây là topology khai báo, chưa phải trạng thái chạy.

```mermaid
C4Deployment
  title Deployment Diagram - Flex (server đang dựng, chưa production)

  Person(user, "Người dùng / Developer", "Truy cập qua trình duyệt")
  System_Ext(github, "GitHub", "Repo flex-k8s (nhánh main)")

  Deployment_Node(server, "Ubuntu server", "x86_64, 3,8 GiB RAM, không swap") {
    Deployment_Node(docker, "Docker host: dùng chung toàn công ty", "Docker Compose, flex-platform, mạng flex_net") {
      Container(dnginx, "nginx + WAF", "ModSecurity CRS", "TLS, cổng 80/443, route theo host")
      Container(infisical, "Infisical", "docker-compose.secrets.yml", "Quản lý secret, có thể đang tắt")
      Container(jenkins, "Jenkins", "Jenkins LTS, JCasC", "CI: build và push image")
    }
    Deployment_Node(k3s, "k3s: cụm riêng của project Flex", "1 node, NodePort 30080") {
      Deployment_Node(nsdefault, "namespace default", "Kubernetes") {
        Container(knginx, "nginx", "nginx-unprivileged 1.27, 2 replica", "Route /api/ và /argocd")
        Container(gateway, "flex-api-gateway", ".NET, 1 replica", "Route và proxy API")
      }
      Deployment_Node(nsargo, "namespace argocd", "Kubernetes") {
        Container(argocd, "argocd-server", "Argo CD v3.5.7", "UI /argocd, sync thủ công")
      }
    }
  }

  Rel(user, dnginx, "Truy cập", "HTTPS")
  Rel(dnginx, knginx, "Proxy mọi path", "HTTP, NodePort 30080")
  Rel(dnginx, infisical, "Proxy host infisical", "HTTP")
  Rel(knginx, gateway, "/api/", "HTTP")
  Rel(knginx, argocd, "/argocd", "HTTP")
  Rel(argocd, github, "Đồng bộ manifests/", "HTTPS")

  UpdateElementStyle(dnginx, $bgColor="#7f8c8d", $borderColor="#5d6d6e")
  UpdateElementStyle(jenkins, $bgColor="#7f8c8d", $borderColor="#5d6d6e")
  UpdateElementStyle(infisical, $bgColor="#7f8c8d", $borderColor="#5d6d6e")
```

**Chú giải màu**: xám = hạ tầng Docker dùng chung toàn công ty; xanh (mặc định) = thành phần riêng của project Flex chạy trong k3s. Ranh giới dùng chung / riêng Flex là cạnh nginx + WAF → nginx k3s qua NodePort `30080`.

## Ghi chú

| Thành phần | Thuộc về | Trạng thái | Bằng chứng |
| --- | --- | --- | --- |
| nginx Docker (WAF) → NodePort `30080` | Dùng chung (Docker) | `Confirmed` (khai báo) | `flex-k8s/README.md` mục "Cài Argo CD", `flex-environment/AGENTS.md` mục 3, 4 |
| Jenkins | Dùng chung (Docker) | `Confirmed by user` | Xác nhận của người dùng; cấu hình JCasC ở `flex-environment/temp/` |
| Infisical | Dùng chung (Docker) | `Cần làm rõ` | Có file riêng và host `infisical.luyenhaidangit.pro`, nhưng `restart.sh` ghi tạm tắt để giải phóng RAM |
| nginx k8s: 2 replica, `/api/` → gateway, `/argocd` → Argo CD | Riêng Flex (k3s) | `Confirmed` (khai báo) | `manifests/nginx/{deployment,configmap}.yaml` |
| `flex-api-gateway`: 1 replica, image `1.0.1-dev`, chỉ nginx được vào cổng 8080 | Riêng Flex (k3s) | `Confirmed` (khai báo) | `manifests/flex-api-gateway/{deployment,networkpolicy}.yaml` |
| Argo CD v3.5.7, non-HA, application `flex` sync thủ công | Riêng Flex (k3s) | `Confirmed` (khai báo) | `argocd/install/`, `argocd/application.yaml` |
| Portainer, netshoot | Dùng chung (Docker), không vẽ cạnh | Không vẽ | Portainer chỉ nghe `127.0.0.1:9000` trên server (SSH tunnel), có host riêng ở site prod |

## Chưa vẽ / cần xác minh

- **Trạng thái chạy thật**: README `flex-k8s` còn ghi "chưa apply lên cluster nào" nhưng cũng mô tả Argo CD đang truy cập qua `flex.luyenhaidangit.pro/argocd`. Cần `kubectl get pods -A` và `docker ps` trên server để chốt.
- **Phân tách dùng chung / riêng**: "Docker dùng chung toàn công ty" là xác nhận của người dùng. Trong repo, stack Docker vẫn mang tên Flex (`flex-platform`, `flex_net`, host `luyenhaidangit.pro`), và chưa thấy project khác đi qua nginx WAF, nên chưa vẽ project khác.
- **`flex-auth-service` chưa có trong cluster**: README `flex-k8s` ghi route `/api/*` trả 502/503 cho tới khi triển khai.
- **Frontend**: chưa thấy workload frontend trong `flex-k8s`; nginx k8s chỉ route `/api/` và `/argocd`. Chưa rõ frontend chạy ở đâu.
- **Cảnh báo bảo mật còn mở** (theo README): NodePort `30080` cần firewall host chặn Internet; `/argocd` đang cho mọi IP, chỉ có đăng nhập admin bảo vệ.
- **Stack dev cũ** (PostgreSQL, MySQL, Redis, RabbitMQ, MinIO, Elasticsearch, Ollama, Prometheus, Grafana) nằm ở `flex-environment/temp/`; `infra`, `app`, `monitoring` trên server hiện là file rỗng, chờ migrate nên chưa vẽ.
- Địa chỉ IP, cổng SSH và domain nội bộ không ghi vào tài liệu này.
