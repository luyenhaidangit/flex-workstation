# Kiến trúc Kubernetes on-premise cho Flex

Tài liệu mô tả kiến trúc đích khi Flex chạy trên Kubernetes theo mô hình on-premise, các thành phần của từng lớp, và cách chúng tương ứng với hạ tầng Docker Compose hiện tại. Đây là tài liệu kiến trúc; lộ trình từng bước nằm ở roadmap.

Tài liệu liên quan (không lặp lại nội dung ở đây):

- [request-flow-reference.md](request-flow-reference.md): luồng request của một kiến trúc production tham chiếu và cách giả lập trên k3s.
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
Client (trình duyệt, luyenhaidangit.project.local)
  │  1. DNS phân giải tên → IP của cổng vào
  ▼
Cổng vào (LB ngoài cluster: nginx)
  │  2. Nhận 80/443, chuyển vào NodePort của Ingress; health check node
  ▼
Ingress Controller (namespace ingress)
  │  3. TLS terminate; ModSecurity (WAF) chạy trong chính process nginx này, quét header rồi body
  │  4. VirtualServer khớp host luyenhaidangit.project.local
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
| Cổng vào | nginx | IP cố định, nhận 80/443, chuyển vào NodePort | Đã có trong `flex-environment` (thay HAProxy) |
| Ingress | NGINX Ingress Controller (CRD VirtualServer/VirtualServerRoute) | TLS, định tuyến host/path, WAF | Namespace `ingress`, Service dạng NodePort |
| WAF | ModSecurity + OWASP CRS (module trong nginx Ingress) | Quét header/body, `DetectionOnly` trước rồi mới chặn | Không phải tầng riêng; cần image Ingress có module |
| Log | Fluentd (hoặc tương đương) → Kibana | Thu log WAF tập trung | Kibana đã có trong `flex-environment` (`/kibana/`) |
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
| DNS | `luyenhaidangit.project.local` → `127.0.0.1` trong `scripts/windows/hosts` | Giữ nguyên khi học; DNS thật khi lên server |
| Cổng vào | nginx trong Docker Compose, nghe 80/443; `server_name` cho `luyenhaidangit.project.local` (chỉ máy local, `sites-available/local.conf`; Portainer, Jenkins, Kibana dưới `/portainer/`, `/jenkins/`, `/kibana/`) và `luyenhaidangit.pro` (server); host lạ bị đóng kết nối (HTTP `444`, HTTPS từ chối handshake) | `luyenhaidangit.project.local` hiện có `location /fss/` trỏ tạm tới `host.docker.internal:30080` (chưa có backend); đổi sang NodePort của Ingress khi dựng xong |
| Ingress | Chưa có | NGINX Ingress Controller trong namespace `ingress` |
| Cluster | k3s 1 node đã cài trên server (`flex-environment/setup/04-init-k3s.sh`), chưa deploy workload | k3s để học; thêm worker hoặc kubeadm nhiều node ở giai đoạn 6 |
| Manifest | `flex-k8s/manifests/nginx.yaml`, `flex-api-gateway.yaml` | Thêm namespace, VirtualServer, VirtualServerRoute |
| Frontend | Chưa có service trong `docker-compose.app.yml` | Pod nginx phục vụ build Angular |
| WAF | Đã cấu hình ở nginx cổng vào Compose (`owasp/modsecurity-crs`, `DetectionOnly`; chưa chạy thử). Ingress k8s chưa có | Giai đoạn sau: ModSecurity trong nginx Ingress (xem mục 8) |
| Log WAF | Kibana đã có, chưa có đường đẩy log WAF vào | Fluentd đẩy log WAF vào Kibana |

## 6. Ranh giới trách nhiệm

| Việc | Ai làm |
| --- | --- |
| DNS record, cấp IP, expose cổng vào | Hạ tầng (ở môi trường học: bạn tự làm bằng hosts và nginx) |
| TLS cert | Hạ tầng; dự án nhận Secret. Môi trường học dùng cert tự ký |
| VirtualServer / VirtualServerRoute, Deployment, Service | Dự án (`flex-k8s`) |

## 7. Quyết định và câu hỏi mở

| # | Nội dung | Trạng thái |
| --- | --- | --- |
| 1 | Dùng NGINX Ingress bản `nginxinc` (CRD VirtualServer) thay vì `ingress-nginx` với Ingress thường, để học đúng mô hình tham chiếu | Đề xuất, chưa chốt |
| 2 | Cài controller bằng Helm, còn lại giữ YAML thuần (trái quy ước "không dùng Helm" của `flex-k8s` nên cần người dùng đồng ý) | Chờ xác nhận |
| 3 | nginx làm LB đứng trước cluster; k3s chạy trực tiếp trên host nên nginx trong Docker tới NodePort qua `host.docker.internal` (đã có `extra_hosts: host-gateway` trong `docker-compose.nginx.yml`) | Đã cấu hình, chưa kiểm chứng với backend thật |
| 4 | Prefix path (`/app`) và tên namespace (`flex-common`, `flex-g1`, `flex-g2`) | Đề xuất |
| 5 | WAF ModSecurity: cần image Ingress có module. Hướng A: tự build image NGINX Ingress + ModSecurity (sát kiến trúc tham chiếu); hướng B: dùng Ingress controller hỗ trợ ModSecurity sẵn cho giai đoạn học (cần kiểm tra bản còn được bảo trì) | Chưa chốt hướng; làm sau khi Ingress chạy |
| 6 | Giữ IP thật của client: nginx cổng vào truyền header, Ingress bật real IP; nếu thiếu thì log WAF và ACL chỉ thấy IP của LB | Chưa làm |

## 8. Thứ tự dựng

Namespace, backend giả (`whoami`) và Service, cài Ingress Controller, VirtualServer và VirtualServerRoute, nối nginx vào NodePort (kèm real IP), TLS tự ký, redirect, bật WAF ở `DetectionOnly`, đẩy log WAF vào Kibana, viết ngoại lệ cho false positive rồi mới chuyển sang chế độ chặn, rồi thay backend giả bằng service Flex thật. Từng bước có lệnh kiểm tra được mô tả trong [request-flow-reference.md](request-flow-reference.md) (mục giả lập) và [roadmap.md](roadmap.md) (giai đoạn 3).
