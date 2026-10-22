# Lộ trình triển khai Kubernetes cho Flex

Lộ trình đi từ đơn giản đến nâng cao, mỗi giai đoạn **đưa thêm một phần thật của Flex** lên cluster thay vì chỉ học ví dụ mẫu. Học xong giai đoạn nào thì có ngay sản phẩm chạy được của giai đoạn đó.

Tài liệu liên quan (không lặp lại nội dung ở đây):

- [k8s-level-1.md](k8s-level-1.md): bài học chi tiết về Pod, Deployment, Service, ConfigMap, PVC, probe, namespace, Ingress trên minikube.
- [k8s-level-2.md](k8s-level-2.md): dựng cluster nhiều node bằng kubeadm, add-on, CI/CD.
- Repo `flex-k8s/`: nơi chứa manifest và script, là sản phẩm đầu ra của lộ trình này.
- `flex-environment/docker-compose.*.yml`: topology hiện tại, nguồn tham chiếu khi chuyển từng service.

## Nguyên tắc

1. **Mỗi giai đoạn ra một thứ chạy được**, commit vào `flex-k8s/`, kèm lệnh kiểm tra và lệnh rollback.
2. **Làm, quan sát, rồi cố tình làm hỏng.** Mỗi giai đoạn có mục "Thử phá" để hiểu cơ chế, vì lúc sự cố thật mới là lúc cần hiểu.
3. **Stateless trước, stateful sau.** Database, message broker và storage để lại Docker Compose cho đến giai đoạn 5. Đây cũng là cách nhiều đội làm khi chuyển thật.
4. **Không thêm công cụ khi chưa thấy nỗi đau.** Chỉ đưa Kustomize/Helm/ArgoCD vào khi YAML thuần bắt đầu lặp và khó quản lý.
5. Image luôn pin version, không commit secret hay kubeconfig (theo quy ước của `flex-k8s/README.md`).

## Tổng quan

| GĐ | Chủ đề | Sản phẩm của Flex | Môi trường | Thời lượng gợi ý |
| --- | --- | --- | --- | --- |
| 0 | Nền tảng trước k8s | Hiểu đúng Compose đang chạy gì | Docker | 2–3 ngày |
| 1 | Đối tượng cốt lõi | `nginx` chạy, scale, rolling update | minikube | 1 tuần |
| 2 | Service .NET thật đầu tiên | `flex-api-gateway` trên k8s, gọi DB còn ở Compose | minikube + Compose | 1 tuần |
| 3 | Nhiều service và ingress | auth-service + gateway + microfrontend, Ingress thay HAProxy | minikube | 1–2 tuần |
| 4 | Đóng gói cấu hình theo môi trường | Kustomize `base` + `overlays/dev,staging` | minikube | 1 tuần |
| 5 | Workload có trạng thái | Redis, RabbitMQ, PostgreSQL, Job migration Liquibase | minikube | 2 tuần |
| 6 | Cluster thật nhiều node | k3s hoặc kubeadm 1 master + 2 worker | VM/server | 1–2 tuần |
| 7 | CI/CD và GitOps | Jenkins build image, ArgoCD tự đồng bộ | cluster thật | 1–2 tuần |
| 8 | Quan sát và tự co giãn | Prometheus/Grafana, log về ELK, HPA | cluster thật | 1–2 tuần |
| 9 | Production hardening | RBAC, NetworkPolicy, PDB, quản lý secret, backup, nâng cấp cluster | cluster thật | liên tục |

Giai đoạn 0–4 chỉ cần laptop. Từ giai đoạn 6 trở đi mới cần VM hoặc server.

---

## Giai đoạn 0: Nền tảng trước Kubernetes

**Mục tiêu:** nắm chắc những gì k8s sẽ thay thế. Nếu không hiểu Compose đang làm gì thì cũng không biết k8s cần làm gì thay nó.

**Học:**

- Container: image, layer, tag, registry, biến môi trường, volume, port.
- Linux networking cơ bản: DNS, port, `curl`, `ss`, `nslookup`.
- YAML: indentation, list, map, multi-document (`---`).

**Làm trên Flex:**

- Đọc `flex-environment/docker-compose.infra.yml` và `docker-compose.app.yml`, lập bảng cho mỗi service: image, port, env, volume, phụ thuộc, healthcheck.
- Bảng này chính là **danh sách việc cần chuyển** cho các giai đoạn sau.

**Hoàn thành khi:** giải thích được vì sao `flex-api-gateway` gọi được `postgresdb` bằng tên (Docker DNS trên mạng `flex_net`).

---

## Giai đoạn 1: Đối tượng cốt lõi với nginx

**Mục tiêu:** hiểu vòng lặp *desired state*: bạn khai báo trạng thái mong muốn, controller liên tục kéo trạng thái thực tế về đúng như vậy.

**Học:** theo [k8s-level-1.md](k8s-level-1.md), bài 0–4 và bài 7: kiến trúc control plane, Pod, Deployment/ReplicaSet, Service, probe, resources.

**Làm:**

```bash
cd flex-k8s
bash scripts/create-cluster.sh
kubectl apply -f manifests/nginx.yaml
kubectl scale deployment/nginx --replicas=4
kubectl set image deployment/nginx nginx=nginx:1.28-alpine
kubectl rollout status deployment/nginx
kubectl rollout undo deployment/nginx
```

**Thử phá:**

- `kubectl delete pod <tên>`: xem Deployment tự tạo pod mới ngay lập tức.
- Đổi image thành tag không tồn tại: quan sát `ImagePullBackOff`, rolling update dừng lại, pod cũ vẫn phục vụ.
- Sửa label trong `selector` của Service: Endpoints trống, request lỗi dù pod vẫn chạy.
- Hạ `limits.memory` xuống mức quá thấp: quan sát `OOMKilled`.

**Hoàn thành khi:** vẽ lại được đường đi của `kubectl apply` → API server → etcd → scheduler → kubelet → container mà không cần xem tài liệu.

---

## Giai đoạn 2: Service .NET thật đầu tiên (flex-api-gateway)

**Mục tiêu:** chạy một service production thật trên k8s, trong khi hạ tầng vẫn ở Compose (mô hình **hybrid**, cách chuyển ít rủi ro nhất).

**Học:** ConfigMap, Secret, `envFrom`, startup/readiness/liveness probe với app khởi động chậm, Service gọi ra ngoài cluster.

**Làm:**

- Dùng lại `flex-environment/k8s/flex-api-gateway.yaml` (đã có ConfigMap, 3 loại probe, resources) và chuyển vào `flex-k8s/manifests/`.
- Đồng bộ tag image với `docker-compose.app.yml` (hiện manifest đang dùng `1.0.1-dev`, Compose dùng `1.0.12-dev`).
- Tạo Secret bằng lệnh, không commit file: `kubectl create secret generic flex-api-gateway-secret --from-env-file=.env.local`.
- Cho pod gọi DB/Redis/RabbitMQ đang chạy bằng Compose trên máy host qua `host.minikube.internal`. Làm sạch hơn bằng một Service `ExternalName` hoặc Service không selector kèm `EndpointSlice`, để code chỉ thấy tên `postgresdb` giống trong Compose.

**Thử phá:**

- Xoá một key bắt buộc trong Secret: quan sát `CrashLoopBackOff`, đọc `kubectl logs --previous`.
- Dừng PostgreSQL trên Compose: `/health/ready` fail, pod bị rút khỏi Service nhưng **không** bị restart. Đây là khác biệt giữa readiness và liveness.
- Đặt `startupProbe.failureThreshold` quá thấp: pod bị kill trước khi .NET khởi động xong.

**Hoàn thành khi:** gateway chạy 2 replica, qua `port-forward` gọi được API thật, rolling update đổi version không rớt request (kiểm bằng vòng lặp `curl` chạy trong lúc update).

---

## Giai đoạn 3: Nhiều service và Ingress

**Mục tiêu:** chạy một lát cắt hoàn chỉnh của Flex: UI → gateway → auth-service. Ingress thay vai trò của HAProxy.

**Học:** Namespace, quy ước label (`app.kubernetes.io/name`, `part-of`, `version`), service discovery qua DNS nội bộ (`<svc>.<ns>.svc.cluster.local`), Ingress (hoặc Gateway API), so sánh với HAProxy config hiện tại.

**Làm:**

- Namespace `flex-dev`.
- Thêm `flex-auth-service` (Deployment + Service), gateway gọi auth bằng tên Service.
- Thêm `flex-microfrontend`: build Angular thành static, phục vụ bằng nginx image.
- Bật ingress controller (`minikube addons enable ingress`), đối chiếu route trong `flex-environment/haproxy/` và viết Ingress tương ứng: `/` → microfrontend, `/api` → gateway.
- Thêm vào hosts: `flex.local` → IP minikube.

**Thử phá:**

- Scale auth-service về 0: gateway trả lỗi gì, log ở đâu? Có trả về 503 rõ ràng không?
- Gọi Service sai namespace bằng tên ngắn: hiểu vì sao DNS không resolve.

**Hoàn thành khi:** mở `http://flex.local`, đăng nhập được end-to-end, toàn bộ app layer chạy trên k8s.

---

## Giai đoạn 4: Đóng gói cấu hình theo môi trường

**Mục tiêu:** cùng một bộ manifest deploy được dev và staging mà không copy-paste.

**Học:** Kustomize (`base`, `overlays`, `images`, `configMapGenerator`, patch). Đọc qua Helm để biết khi nào nên dùng: chủ yếu để **cài** phần mềm bên thứ ba (ingress-nginx, Prometheus, ArgoCD), ít khi cần cho app nội bộ.

**Làm:**

```text
flex-k8s/
  apps/
    flex-api-gateway/base/
    flex-auth-service/base/
    flex-microfrontend/base/
  overlays/
    dev/        # 1 replica, resources thấp, image *-dev
    staging/    # 2 replica, resources gần prod
```

`kubectl apply -k overlays/dev` và `kubectl diff -k overlays/staging` trước mỗi lần apply.

> Cần quyết định: `flex-k8s/README.md` đang chốt "YAML thuần, không Kustomize/Helm". Chỉ chuyển sang Kustomize khi đã thấy YAML bị lặp ở giai đoạn 3, và cập nhật README khi chuyển.

**Hoàn thành khi:** đổi version một service chỉ phải sửa một dòng `images:` trong overlay.

---

## Giai đoạn 5: Workload có trạng thái

**Mục tiêu:** hiểu vì sao stateful khó trên k8s và khi nào **không nên** tự chạy database trong cluster.

**Học:** StatefulSet, headless Service, PVC/StorageClass, `volumeClaimTemplates`, Job/CronJob, initContainer, thứ tự khởi động.

**Làm (theo thứ tự rủi ro tăng dần):**

1. Redis: StatefulSet 1 replica + PVC.
2. RabbitMQ: StatefulSet + PVC, thử RabbitMQ Cluster Operator để thấy giá trị của operator.
3. PostgreSQL: tự viết StatefulSet để học, sau đó so sánh với **CloudNativePG** (operator lo failover, backup, replica).
4. Chuyển `postgres-bootstrap` và migration Liquibase của `flex-database` thành **Job** chạy trước khi deploy app.
5. Backup: CronJob `pg_dump` ra MinIO.

**Thử phá:**

- Xoá pod PostgreSQL: dữ liệu còn không? Pod mới gắn lại đúng PVC không?
- Xoá PVC: hiểu `reclaimPolicy` (`Delete` hay `Retain`).
- Chạy Job migration lỗi: app có deploy tiếp không? Cần cơ chế chặn ra sao?

**Hoàn thành khi:** restore được DB từ bản backup vào một namespace mới. **Backup chưa restore thử thì chưa được tính là có backup.**

> Khuyến nghị cho production: PostgreSQL dùng operator (CloudNativePG) hoặc tiếp tục chạy ngoài cluster/managed. Elasticsearch, Jenkins và Ollama/vLLM để sau cùng, hoặc giữ ở Compose.

---

## Giai đoạn 6: Cluster thật nhiều node

**Mục tiêu:** hiểu những thứ minikube che giấu: CNI, LoadBalancer trên bare-metal, storage phân tán, node lỗi.

**Học và làm:** theo [k8s-level-2.md](k8s-level-2.md). Có hai hướng:

| Lựa chọn | Phù hợp khi |
| --- | --- |
| **k3s** (`flex-environment/setup/install-k3s.sh`) | Muốn có cluster chạy nhanh, tài nguyên ít, gần với cách vận hành thật cho team nhỏ |
| **kubeadm** | Muốn hiểu từng thành phần control plane, chứng chỉ, containerd, CNI (phục vụ thi CKA) |

Gợi ý: dựng kubeadm một lần để hiểu, sau đó dùng k3s cho môi trường Flex lâu dài.

Add-on: MetalLB, ingress controller, metrics-server, StorageClass (local-path hoặc Longhorn), cert-manager.

**Thử phá:**

- Tắt một worker: pod mất bao lâu để được lên lịch lại? (đọc về `tolerationSeconds` cho `node.kubernetes.io/unreachable`).
- `kubectl drain` một node trong lúc vòng lặp `curl` đang chạy: có rớt request không? Đây là lý do cần PodDisruptionBudget (xem giai đoạn 9).

**Hoàn thành khi:** overlay `staging` từ giai đoạn 4 deploy lên cluster thật, truy cập được qua domain có TLS.

---

## Giai đoạn 7: CI/CD và GitOps

**Mục tiêu:** không ai `kubectl apply` bằng tay lên staging/prod nữa.

**Học:** registry (Docker Hub/Harbor), `imagePullSecrets`, push vs pull deploy, GitOps với ArgoCD (hoặc Flux).

**Làm:**

1. Jenkins (đang có trong `flex-environment/jenkins/`): build → test → push image có tag theo commit SHA hoặc semver.
2. Pipeline mở PR (hoặc commit) cập nhật `images:` trong overlay của `flex-k8s`.
3. ArgoCD theo dõi `flex-k8s/overlays/staging` và tự đồng bộ; prod đồng bộ thủ công có duyệt.
4. Rollback = `git revert` commit đổi image.

**Thử phá:** sửa tay một Deployment bằng `kubectl edit`: ArgoCD phát hiện drift và kéo về đúng trạng thái trong Git.

**Hoàn thành khi:** merge code vào `main` của một service → bản mới lên staging mà không cần thao tác tay.

---

## Giai đoạn 8: Quan sát và tự co giãn

**Mục tiêu:** biết hệ thống đang khoẻ hay yếu trước khi người dùng báo.

**Học:** metrics-server, kube-prometheus-stack (Prometheus Operator, ServiceMonitor, Alertmanager), log dạng DaemonSet, HPA, requests/limits ảnh hưởng HPA và scheduling thế nào.

**Làm:**

- Cài kube-prometheus-stack bằng Helm, tạo ServiceMonitor cho endpoint metrics của các service .NET.
- Dùng lại dashboard Grafana và rule Prometheus đang có trong `flex-environment/prometheus/`.
- Filebeat chạy DaemonSet, đẩy log container về ELK sẵn có (hoặc chuyển sang Loki).
- HPA cho `flex-api-gateway` theo CPU, sau đó theo request rate.
- Alert: pod restart liên tục, readiness fail, PVC sắp đầy, node NotReady.

**Thử phá:** chạy load test (k6) vào gateway: HPA scale lên, kết thúc test thì scale xuống. Tìm xem pod nào là điểm nghẽn.

**Hoàn thành khi:** có dashboard một trang cho toàn bộ Flex và ít nhất 3 alert đã được kích hoạt thử thành công.

---

## Giai đoạn 9: Production hardening

**Mục tiêu:** an toàn, chịu lỗi, khôi phục được. Đây là phần làm liên tục, không có điểm kết thúc.

| Chủ đề | Việc cụ thể |
| --- | --- |
| Truy cập | RBAC: mỗi người/pipeline một ServiceAccount, quyền tối thiểu; không dùng kubeconfig admin cho CI |
| Mạng | NetworkPolicy default-deny, chỉ mở gateway → auth, app → DB |
| Pod security | Pod Security Admission mức `restricted`: `runAsNonRoot`, `readOnlyRootFilesystem`, drop capabilities |
| Secret | Sealed Secrets hoặc External Secrets (Vault/cloud), không để secret dạng base64 trong Git |
| Chịu lỗi | PodDisruptionBudget, `topologySpreadConstraints`/anti-affinity, ít nhất 2 replica cho service quan trọng |
| Tài nguyên | ResourceQuota + LimitRange cho từng namespace |
| Backup/DR | Velero cho manifest + PV, kèm diễn tập restore định kỳ |
| Nâng cấp | Nâng version k8s từng minor một trên staging trước; đọc deprecation API |
| Supply chain | Quét image (Trivy), ký image (cosign), pin digest |

**Hoàn thành khi:** có runbook cho các sự cố hay gặp (node chết, DB đầy, deploy lỗi, rotate secret) và mỗi runbook đã được diễn tập ít nhất một lần.

---

## Sau lộ trình

- Chứng chỉ: CKAD (giai đoạn 1–5), CKA (giai đoạn 6–9), CKS (giai đoạn 9).
- Chủ đề nâng cao: Gateway API, service mesh (Istio/Linkerd) cho mTLS và traffic splitting, canary với Argo Rollouts, viết Operator/CRD, multi-cluster.

## Theo dõi tiến độ

| GĐ | Trạng thái | Ghi chú |
| --- | --- | --- |
| 0 | ☐ | |
| 1 | ◐ | `flex-k8s/manifests/nginx.yaml` đã có, chưa apply |
| 2 | ◐ | Manifest gateway đã có ở `flex-environment/k8s/` |
| 3 | ☐ | |
| 4 | ☐ | |
| 5 | ☐ | |
| 6 | ☐ | |
| 7 | ☐ | |
| 8 | ☐ | |
| 9 | ☐ | |
