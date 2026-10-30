# Luồng CI/CD: từ code đến service chạy trên Kubernetes

Ghi chú về một quy trình dựng và triển khai service mới theo mô hình Jenkins + Harbor + Helm + ArgoCD (GitOps), làm mẫu cho giai đoạn 7 của [roadmap](../k8s/roadmap.md). Nội dung là kiến thức chung, không gắn với một công ty cụ thể.

Tài liệu liên quan:

- [roadmap.md](../k8s/roadmap.md): giai đoạn 7 (CI/CD và GitOps).
- [k8s-level-2.md](../k8s/k8s-level-2.md): giai đoạn 8, tổng quan CI/CD và vận hành.
- [request-flow-reference.md](../k8s/request-flow-reference.md): luồng request sau khi service đã chạy.
- [new-service-checklist.md](../../../docs/checklists/new-service-checklist.md): checklist tạo service mới.

## Tổng quan luồng

```text
Dev push code / tạo service mới
  ▼
Webhook (Git server) → Job CI (Jenkins): build + test + quét chất lượng (Sonar)
  ▼
Job CD (Jenkins): publish + docker build + docker push → Registry (Harbor)
  ▼
Git tag chứa tham số sync (image tag, môi trường)
  ▼
Job sync Helm (Jenkins): cập nhật imageTag trong values + push Helm chart
  ▼
ArgoCD auto-sync: so khớp Git với cluster, rollout Deployment
  ▼
Verify: health check, Swagger, log tập trung; báo kết quả qua kênh chat
```

## Quy trình dựng service mới (theo thứ tự)

### 1. Tạo code service

- Thêm module mới theo layer chuẩn của repo (Api, Application, Contracts, Domain, Domain.<db>, Shared, Worker nếu có).
- Dùng generator/template của repo nếu có để sinh bộ source ban đầu.
- Bootstrap `Program.cs`/`Startup.cs` theo pattern chung (config, swagger, cache, auth, DB factory, storage).
- Thêm project vào file solution.

### 2. Config

- Tạo file config theo namespace của module, để được auto-load khi service khởi động.
- Service cần gọi qua proxy/gateway → thêm endpoint vào file cấu hình router.

### 3. Dockerfile: không viết tay

- Pipeline tự sinh Dockerfile theo loại ứng dụng rồi inject trước bước `docker build`.
- Chỉ thêm nhánh đặc biệt khi service có nhu cầu riêng (ví dụ cần font, tài nguyên mở rộng).

### 4. Đăng ký CI/CD (shared library)

- Khai báo service vào danh sách app của shared library: thư mục project, tên image, framework build.
- **`imageName` phải khớp key khai báo trong Helm values**: đây là điểm nối giữa CI và Helm.
- Đổi solution filter thì cập nhật file filter tương ứng.

### 5. Helm chart

- Thêm entry service vào values theo môi trường: `imageTag`, `servicePort`, `replicaCount`, `resources`. Tách values dùng chung và values theo tenant/thế hệ nếu có.
- Service có config riêng → tạo thư mục config và thêm pattern vào template configmap.
- Route ingress: route con thường tự sinh theo tên service; muốn expose ra ngoài thì khai báo thêm trong values của ingress/WAF.
- Tăng `version` trong `Chart.yaml`.
- Verify: `helm lint` và `helm template`.

### 6. Database

- Repo kế thừa lớp base repository tương ứng (tenant hoặc master DB).
- Migration SQL chạy qua chart riêng (K8s Job, hook ArgoCD PostSync): cập nhật tag file sync và version nâng cấp DB trong values.

### 7. Deploy và verify

- Tự động: webhook → job CI (build + Sonar) → job CD (publish + push image) → git tag chứa tham số sync → job sync Helm cập nhật `imageTag` và push chart → ArgoCD auto-sync theo namespace.
- Verify: endpoint `/health`, Swagger, log (Filebeat → Logstash), kết quả build báo qua kênh chat.

## Ánh xạ sang Flex

| Bước trong luồng | Công cụ mẫu | Nơi đặt trong Flex |
| --- | --- | --- |
| Source service | .NET | repo service (`flex-auth-service`, `flex-api-gateway`, ...) |
| Build + push image | Jenkins, Harbor | repo `flex-k8s` hoặc thư mục CI của từng service |
| Manifest/chart | YAML thuần → Kustomize/Helm | repo `flex-k8s` |
| GitOps sync | ArgoCD | cluster (giai đoạn 7) |
| Migration | Liquibase Job | repo `flex-database` |

> Công cụ cụ thể (Jenkins hay GitHub Actions, Helm hay Kustomize) chưa chốt cho Flex; theo nguyên tắc của roadmap, chỉ đưa vào khi YAML thuần bắt đầu lặp và khó quản lý.

## Lưu ý

- Service thuộc tier khác (gateway, MCP, AI) dùng chart riêng với cấu trúc values khác, không split common/g1/g2 như chart Apps.
- Luồng này chỉ mô tả phần DevOps; phần code của service xem tài liệu pattern của từng repo.
