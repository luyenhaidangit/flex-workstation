# Luồng request tham chiếu: Ingress + WAF + nhiều namespace

Ghi chú về một kiến trúc production thực tế dùng Kubernetes, làm mẫu để giả lập trên minikube. Nội dung là kiến thức chung, không gắn với một công ty cụ thể.

Tài liệu liên quan:

- [roadmap.md](roadmap.md): lộ trình triển khai; luồng này tương ứng giai đoạn 3 (nhiều service và Ingress).
- [k8s-level-1.md](k8s-level-1.md): Deployment, Service, Ingress cơ bản.

## Luồng request

```text
Browser (app.example.com)
  │  DNS
  ▼
Ingress Controller + WAF (TLS terminate, ModSecurity quét tấn công)
  │  VirtualServer match theo host
  ▼
Định tuyến theo path tới từng namespace
  ├─ /app          → ns app-common/...-api   (tầng gateway: auth, proxy, sharding, monitor)
  ├─ /app/g1       → ns app-g1/app-g1-api    (Apps thế hệ g1)
  ├─ /app/g2       → ns app-g2/app-g2-api    (Apps thế hệ g2)
  ├─ /app/g1/apis/ai-chat-api/... → ns app-g1/app-g1-ai-api (AI apps)
  └─ /app/public-chat → 302 redirect sang host chat riêng
  ▼
Route con (VirtualServerRoute)
  ├─ /<path>/apis/<service-name>/ → upstream = K8s Service <ns>-<service>-svc
  └─ /<path>/                     → app-ui-api (serve frontend + catch-all)
  ▼
K8s Service (ClusterIP): cân bằng tải round-robin tới các pod
  (ví dụ app-ui-api 10 replicas, proxy-api 10 replicas)
  ▼
Pod microservice (.NET) → DB / Kafka / Redis ...
```

## Các lớp proxy

| Thành phần | Vai trò |
| --- | --- |
| Chart reverse proxy chính (nhiều replica) | TLS terminate, WAF ModSecurity, giữ VirtualServer cha theo host |
| Chart WAF riêng cho chat | Tách WAF cho luồng chat |
| Ingress controller riêng cho WebSocket | Cần timeout/buffering khác với HTTP thường |
| Chart theo nhóm app (Apps, AI, MCP...) | Tạo VirtualServerRoute trỏ vào K8s Service của từng microservice |

## Điểm đáng chú ý

1. **Cân bằng tải 2 tầng.** Ingress upstream trỏ vào K8s Service (không chọn từng pod); Service chia traffic qua các replica. Không có weighted LB giữa các pod, nhưng VirtualServerRoute hỗ trợ weighted split cho endpoint ngoài cluster (canary).
2. **Tách thế hệ g1/g2.** Hai generation (cluster/namespace) chạy song song, route theo path prefix. Đây là cơ chế blue/green: chuyển người dùng dần từ g1 sang g2.
3. **Frontend là một pod.** SPA build xong được serve qua `app-ui-api`, không có CDN riêng cho app chính; CDN chỉ phục vụ static assets.
4. **WebSocket đi ingress controller riêng** vì cần cấu hình timeout/buffering khác.
5. **Internal traffic có host riêng** (VirtualServer nội bộ, domain `.local`) cho service-to-service trong cluster.
6. **Mọi API call từ frontend đều quay lại Ingress**: browser → `/<path>/apis/<service>/` → WAF → service. Không có truy cập trực tiếp pod từ ngoài.

## Ranh giới trách nhiệm

| Việc | Ai làm |
| --- | --- |
| Đăng ký domain và DNS record trỏ về IP public của LB/cluster | Team hạ tầng/SRE (ngoài repo ứng dụng) |
| Cấp IP, expose ingress ra ngoài (Service LoadBalancer / NodePort) | Hạ tầng chung |
| TLS cert cho wildcard domain | Team hạ tầng; dự án chỉ nhận Secret mount vào |
| VirtualServer/VirtualServerRoute routing bên trong | Dự án (Helm chart trong repo) |

Dấu hiệu repo không tự quản DNS/TLS: `enableExternalDNS: false`, không có external-dns, không có cert-manager (TLS secret phải tạo thủ công), cluster dùng chung với node ingress dành riêng.

## Giả lập trên minikube

Cùng khái niệm, thu nhỏ; dùng `ingress-nginx` với Ingress thường thay cho CRD VirtualServer.

| Bước | Việc | Kiểm tra |
| --- | --- | --- |
| 1 | Tạo cluster minikube (`flex-k8s/scripts/create-cluster.sh`) | `kubectl get nodes` |
| 2 | Bật ingress: `minikube addons enable ingress` | Pod ingress-nginx Running |
| 3 | Tạo namespace `app-common`, `app-g1`, `app-g2` | `kubectl get ns` |
| 4 | Deploy app giả (nginx hoặc `flex-api-gateway`), `replicas: 2`, kèm Service ClusterIP mỗi namespace | `kubectl get endpoints -n app-g1` |
| 5 | Ingress với path `/app`, `/app/g1`, `/app/g2` trỏ tới Service tương ứng | `curl` từng path ra đúng app |
| 6 | Mỗi app trả về tên pod/namespace để thấy round-robin | Gọi lặp, tên pod đổi |
| 7 | TLS Secret tự ký cho `flex.local`, thêm vào `/etc/hosts` | `curl -k https://flex.local/app` |
| 8 | (Tuỳ chọn) ModSecurity qua annotation ingress-nginx để giả lập WAF | Payload tấn công bị chặn 403 |

Phần thay thế khi giả lập: DNS → `/etc/hosts`; cert thật → cert tự ký; LB public → `minikube tunnel`. Kafka, Redis, DB, WebSocket controller riêng để sau (workload có state, giai đoạn 5).

## Câu hỏi cần chốt trước khi dựng

1. App giả dùng `nginx` hay `flex-api-gateway` thật (cần Secret và DB)?
2. Có làm g1/g2 (blue/green) ngay, hay bắt đầu một namespace rồi mở rộng?
3. Có cần WAF không (để cuối)?
