# Kiến trúc Kubernetes on-premise cho Flex

Tài liệu mô tả kiến trúc đích khi Flex chạy trên Kubernetes theo mô hình on-premise, các thành phần của từng lớp, và cách chúng tương ứng với hạ tầng Docker Compose hiện tại. Đây là tài liệu kiến trúc; lộ trình từng bước nằm ở roadmap.

Tài liệu liên quan (không lặp lại nội dung ở đây):

- [request-flow-reference.md](request-flow-reference.md): luồng request của một kiến trúc production tham chiếu và cách giả lập trên minikube.
- [roadmap.md](roadmap.md): thứ tự triển khai theo giai đoạn; kiến trúc này tương ứng giai đoạn 3 (nhiều service và Ingress) và giai đoạn 6 (cluster thật).
- [k8s-level-1.md](k8s-level-1.md): Pod, Deployment, Service, Ingress cơ bản.
- `flex-k8s/`: repo chứa manifest và script; `flex-environment/`: topology Docker Compose hiện tại.

## 1. Nguyên tắc kiến trúc

1. **Tách lớp theo trách nhiệm.** Mỗi lớp chỉ làm một việc (phân giải tên, nhận traffic, định tuyến, chạy app, lưu dữ liệu) và chỉ biết lớp ngay sau nó.
2. **Chỉ lớp ngoài cùng được public.** Pod, Service và DB nằm trong mạng riêng; không truy cập trực tiếp từ ngoài.
3. **Định tuyến theo host rồi path.** Một host cho mỗi hệ thống, path chọn namespace và service.
4. **Cân bằng tải hai tầng.** Ingress chọn Service; Service chia tải round-robin tới các replica.
5. **Manifest là YAML thuần.** Helm chỉ dùng cho cài controller nếu bắt buộc (xem mục 7).

## 2. Kiến trúc đích

```text
Client (trình duyệt, app.flex.local)
  │  1. DNS phân giải tên → IP của cổng vào
  ▼
Cổng vào (LB ngoài cluster: HAProxy)
  │  2. Nhận 80/443, chuyển vào NodePort của Ingress; health check node
  ▼
Ingress Controller (namespace ingress)
  │  3. TLS terminate, (tuỳ chọn) WAF ModSecurity
  │  4. VirtualServer khớp host app.flex.local
  ▼
Định tuyến theo path tới VirtualServerRoute của từng namespace
  ├─ /app             → flex-common   (tầng gateway: flex-api-gateway, flex-auth-service)
  ├─ /app/g1          → flex-g1
  └─ /app/g2          → flex-g2
  ▼
K8s Service (ClusterIP): cân bằng tải tới các pod
  ▼
Pod .NET → PostgreSQL / Redis / RabbitMQ / MinIO
```

## 3. Các lớp và thành phần

| Lớp | Thành phần | Vai trò | Ghi chú |
| --- | --- | --- | --- |
| Phân giải tên | DNS (hosts khi học, DNS thật khi lên server) | Tên → IP của cổng vào | Chỉ trả IP, không chuyển traffic |
| Cổng vào | HAProxy | IP cố định, nhận 80/443, chuyển vào NodePort, health check | Đã có trong `flex-environment` |
| Ingress | NGINX Ingress Controller (CRD VirtualServer/VirtualServerRoute) | TLS, định tuyến host/path, WAF | Namespace `ingress`, Service dạng NodePort |
| Định tuyến | VirtualServer (cha, theo host) + VirtualServerRoute (con, theo namespace) | Chia route để mỗi nhóm app tự quản route của mình | |
| Workload | Deployment + Service ClusterIP | Chạy app, nhiều replica | Tên Service: `<ns>-<service>-svc` |
| Dữ liệu | PostgreSQL, Redis, RabbitMQ, MinIO | Lưu trạng thái | Giai đoạn đầu giữ ở Docker Compose, chuyển sau (giai đoạn 5) |

## 4. Namespace

| Namespace | Nội dung |
| --- | --- |
| `ingress` | Ingress controller (và controller riêng cho WebSocket nếu cần) |
| `flex-common` | Tầng gateway dùng chung: `flex-api-gateway`, `flex-auth-service` |
| `flex-g1`, `flex-g2` | Nhóm app theo thế hệ; chạy song song để chuyển người dùng dần (blue/green) |

Quy ước tên Service: `<namespace>-<service>-svc` (ví dụ `flex-g1-flex-api-gateway-svc`). Label theo `app.kubernetes.io/name`, `part-of`, `version` (xem roadmap, giai đoạn 3).

## 5. Hiện trạng và khoảng cách

| Hạng mục | Hiện trạng (đã xác nhận) | Kiến trúc đích |
| --- | --- | --- |
| DNS | `app.flex.local` → `127.0.0.1` trong `scripts/windows/hosts` | Giữ nguyên khi học; DNS thật khi lên server |
| Cổng vào | HAProxy trong Docker Compose, nghe 80/443; ACL cho `portainer.local`, `jenkins.local`, `api.flex.internal`; host lạ trả 404 | Thêm ACL `app.flex.local` → NodePort của Ingress |
| Ingress | Chưa có | NGINX Ingress Controller trong namespace `ingress` |
| Cluster | minikube đã cài, đang dừng | minikube để học; kubeadm nhiều node ở giai đoạn 6 |
| Manifest | `flex-k8s/manifests/nginx.yaml`, `flex-api-gateway.yaml` | Thêm namespace, VirtualServer, VirtualServerRoute |
| Frontend | Chưa có service trong `docker-compose.app.yml` | Pod nginx phục vụ build Angular |
| WAF | Chưa có | ModSecurity trên Ingress (làm sau cùng) |

## 6. Ranh giới trách nhiệm

| Việc | Ai làm |
| --- | --- |
| DNS record, cấp IP, expose cổng vào | Hạ tầng (ở môi trường học: bạn tự làm bằng hosts và HAProxy) |
| TLS cert | Hạ tầng; dự án nhận Secret. Môi trường học dùng cert tự ký |
| VirtualServer / VirtualServerRoute, Deployment, Service | Dự án (`flex-k8s`) |

## 7. Quyết định và câu hỏi mở

| # | Nội dung | Trạng thái |
| --- | --- | --- |
| 1 | Dùng NGINX Ingress bản `nginxinc` (CRD VirtualServer) thay vì `ingress-nginx` với Ingress thường, để học đúng mô hình tham chiếu | Đề xuất, chưa chốt |
| 2 | Cài controller bằng Helm, còn lại giữ YAML thuần (trái quy ước "không dùng Helm" của `flex-k8s` nên cần người dùng đồng ý) | Chờ xác nhận |
| 3 | HAProxy làm LB đứng trước cluster; cần kiểm tra container HAProxy tới được IP minikube (mạng Docker khác nhau) | Chưa kiểm chứng |
| 4 | Prefix path (`/app`) và tên namespace (`flex-common`, `flex-g1`, `flex-g2`) | Đề xuất |
| 5 | WAF ModSecurity: cần image controller có module | Làm sau cùng |

## 8. Thứ tự dựng

Namespace, backend giả (`whoami`) và Service, cài Ingress Controller, VirtualServer và VirtualServerRoute, nối HAProxy vào NodePort, TLS tự ký, redirect, WAF, rồi thay backend giả bằng service Flex thật. Từng bước có lệnh kiểm tra được mô tả trong [request-flow-reference.md](request-flow-reference.md) (mục giả lập) và [roadmap.md](roadmap.md) (giai đoạn 3).
