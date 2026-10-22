# Triển khai Kubernetes từ đầu đến deploy service

Hướng dẫn dưới đây dùng **kubeadm** trên **Ubuntu 22.04/24.04**, mô hình **1 master + 2 worker**. Đây là cách phổ biến cho môi trường on-premise hoặc VM. Nếu dùng cloud (EKS, GKE, AKS), bạn bỏ qua các giai đoạn 1 đến 4 và bắt đầu từ giai đoạn 5.

---

## Tổng quan các giai đoạn

1. Chuẩn bị hạ tầng và hệ điều hành
2. Cài container runtime (containerd)
3. Cài kubeadm, kubelet, kubectl
4. Khởi tạo control plane, cài mạng CNI, join các worker
5. Cài add-on: Helm, Ingress, LoadBalancer, storage, metrics
6. Đóng gói ứng dụng: Docker image, đẩy lên registry
7. Deploy service: Namespace, ConfigMap/Secret, Deployment, Service, Ingress, HPA
8. Kiểm tra, CI/CD và vận hành

---

## Giai đoạn 1: Chuẩn bị hạ tầng (làm trên **tất cả** node)

**Cấu hình tối thiểu:**

| Vai trò | CPU | RAM | Disk |
|---|---|---|---|
| Master | 2 vCPU | 2–4 GB | 30 GB |
| Worker | 2+ vCPU | 4+ GB | 50 GB |

Các node phải ping được nhau và có địa chỉ IP tĩnh.

```bash
# Đặt hostname (mỗi node một tên riêng)
sudo hostnamectl set-hostname k8s-master   # k8s-worker1, k8s-worker2

# Khai báo /etc/hosts
cat <<EOF | sudo tee -a /etc/hosts
192.168.1.10 k8s-master
192.168.1.11 k8s-worker1
192.168.1.12 k8s-worker2
EOF

# Tắt swap (kubelet yêu cầu mặc định)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Nạp kernel module
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Tham số sysctl cho networking
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
```

**Mở port firewall:**
- **Master:** 6443 (API server), 2379–2380 (etcd), 10250, 10257, 10259
- **Worker:** 10250, 30000–32767 (NodePort)
- **CNI:** mở thêm port riêng của CNI. Calico dùng BGP 179, hoặc IPIP/VXLAN 4789.

---

## Giai đoạn 2: Cài containerd (tất cả node)

```bash
sudo apt-get update
sudo apt-get install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Bắt buộc: dùng systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd
```

---

## Giai đoạn 3: Cài kubeadm, kubelet, kubectl (tất cả node)

Vào https://kubernetes.io/releases để xem phiên bản stable hiện tại, rồi thay vào biến bên dưới.

```bash
K8S_VERSION=v1.34   # thay bằng bản minor mới nhất

sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl   # tránh tự nâng cấp
sudo systemctl enable kubelet
```

---

## Giai đoạn 4: Dựng cluster

### 4.1 Khởi tạo control plane (chỉ trên master)

```bash
sudo kubeadm init \
  --apiserver-advertise-address=192.168.1.10 \
  --pod-network-cidr=10.244.0.0/16

# Cấu hình kubectl cho user hiện tại
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Sau khi chạy xong, bạn cần **lưu lại lệnh `kubeadm join ...`** in ra cuối output.

> **Nếu cần HA** (3 master): đặt load balancer (HAProxy + Keepalived) trước port 6443. Khi init, thêm `--control-plane-endpoint=<VIP>:6443 --upload-certs`.

### 4.2 Cài mạng CNI (chỉ trên master)

Chưa có CNI thì node sẽ ở trạng thái `NotReady`. Ví dụ dưới đây dùng Calico. Cilium cũng là lựa chọn tốt.

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/<version>/manifests/tigera-operator.yaml
# Tải custom-resources.yaml, sửa cidr thành 10.244.0.0/16, rồi apply
kubectl create -f custom-resources.yaml
```

### 4.3 Join worker (trên từng worker)

```bash
sudo kubeadm join 192.168.1.10:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

Nếu token đã hết hạn, tạo lệnh join mới trên master bằng:

```bash
kubeadm token create --print-join-command
```

### 4.4 Kiểm tra

```bash
kubectl get nodes -o wide         # tất cả phải Ready
kubectl get pods -A               # các pod kube-system đều Running
```

---

## Giai đoạn 5: Cài add-on cần thiết

### Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### MetalLB (chỉ cần cho bare-metal)

Trên bare-metal, Service kiểu `LoadBalancer` sẽ không có IP ngoài. MetalLB cấp IP cho loại Service này.

```bash
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -n metallb-system --create-namespace
```

Sau khi cài, khai báo dải IP:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata: { name: pool, namespace: metallb-system }
spec:
  addresses: ["192.168.1.200-192.168.1.220"]
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata: { name: l2, namespace: metallb-system }
```

### Ingress / Gateway controller

Lưu ý: dự án **ingress-nginx** của cộng đồng Kubernetes đã ngừng phát triển từ 3/2026. Với cluster mới, nên chọn **Traefik**, **NGINX Gateway Fabric** hoặc **Envoy Gateway** (các lựa chọn này hỗ trợ Gateway API).

```bash
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik -n traefik --create-namespace
```

### Metrics Server (để HPA và `kubectl top` hoạt động)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Với lab dùng cert tự ký, thêm arg `--kubelet-insecure-tls` vào metrics-server.

### Storage

Có hai lựa chọn chính:
- **Lab:** local-path-provisioner của Rancher.
- **Production:** NFS CSI, Longhorn hoặc Ceph (Rook).

Sau khi cài, đặt một StorageClass làm mặc định.

### cert-manager (tùy chọn, dùng cho TLS tự động với Let's Encrypt)

```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --set crds.enabled=true
```

---

## Giai đoạn 6: Đóng gói ứng dụng

```dockerfile
# Ví dụ: ứng dụng Java Spring Boot
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY target/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

```bash
docker build -t registry.example.com/myteam/my-api:1.0.0 .
docker push registry.example.com/myteam/my-api:1.0.0
```

Registry có thể là Harbor, GitLab Registry, Docker Hub, ECR... Nếu registry là private, tạo secret để cluster pull được image:

```bash
kubectl create secret docker-registry regcred -n my-app \
  --docker-server=registry.example.com --docker-username=<u> --docker-password=<p>
```

---

## Giai đoạn 7: Deploy service

Tạo file `my-api.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
---
apiVersion: v1
kind: ConfigMap
metadata: { name: my-api-config, namespace: my-app }
data:
  SPRING_PROFILES_ACTIVE: "prod"
  LOG_LEVEL: "INFO"
---
apiVersion: v1
kind: Secret
metadata: { name: my-api-secret, namespace: my-app }
type: Opaque
stringData:
  DB_PASSWORD: "change-me"
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: my-api, namespace: my-app }
spec:
  replicas: 2
  selector:
    matchLabels: { app: my-api }
  strategy:
    type: RollingUpdate
    rollingUpdate: { maxSurge: 1, maxUnavailable: 0 }
  template:
    metadata:
      labels: { app: my-api }
    spec:
      imagePullSecrets: [{ name: regcred }]
      containers:
        - name: my-api
          image: registry.example.com/myteam/my-api:1.0.0
          ports: [{ containerPort: 8080 }]
          envFrom:
            - configMapRef: { name: my-api-config }
            - secretRef: { name: my-api-secret }
          resources:
            requests: { cpu: "250m", memory: "512Mi" }
            limits:   { cpu: "1",    memory: "1Gi" }
          readinessProbe:
            httpGet: { path: /actuator/health/readiness, port: 8080 }
            initialDelaySeconds: 20
          livenessProbe:
            httpGet: { path: /actuator/health/liveness, port: 8080 }
            initialDelaySeconds: 40
---
apiVersion: v1
kind: Service
metadata: { name: my-api, namespace: my-app }
spec:
  selector: { app: my-api }
  ports: [{ port: 80, targetPort: 8080 }]
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: { name: my-api, namespace: my-app }
spec:
  ingressClassName: traefik
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: { name: my-api, port: { number: 80 } }
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: my-api, namespace: my-app }
spec:
  scaleTargetRef: { apiVersion: apps/v1, kind: Deployment, name: my-api }
  minReplicas: 2
  maxReplicas: 6
  metrics:
    - type: Resource
      resource: { name: cpu, target: { type: Utilization, averageUtilization: 70 } }
```

Deploy và kiểm tra:

```bash
kubectl apply -f my-api.yaml
kubectl get all -n my-app
kubectl rollout status deployment/my-api -n my-app
kubectl logs -f deploy/my-api -n my-app
kubectl describe pod <pod> -n my-app              # khi pod lỗi
kubectl port-forward svc/my-api 8080:80 -n my-app # test nội bộ
```

Cuối cùng, trỏ DNS `api.example.com` về EXTERNAL-IP của Traefik. Xem IP này bằng `kubectl get svc -n traefik`.

**Cập nhật phiên bản và rollback:**

```bash
kubectl set image deploy/my-api my-api=registry.example.com/myteam/my-api:1.0.1 -n my-app
kubectl rollout undo deploy/my-api -n my-app
```

---

## Giai đoạn 8: CI/CD và vận hành

- **Quản lý manifest:** đóng gói thành **Helm chart** hoặc dùng **Kustomize** để tách cấu hình theo môi trường dev/staging/prod.
- **CI/CD:** pipeline (GitLab CI, Jenkins, GitHub Actions) chạy build, test, build image, push image, rồi cập nhật tag image. Phần deploy nên dùng GitOps với **Argo CD** hoặc **Flux**, để cluster tự đồng bộ theo Git.
- **Monitoring:** kube-prometheus-stack (Prometheus + Grafana + Alertmanager).
- **Logging:** Loki + Promtail/Alloy, hoặc EFK.
- **Bảo mật:**
  - Phân quyền RBAC theo namespace.
  - Dùng NetworkPolicy để giới hạn traffic giữa các service.
  - Không lưu Secret dạng plain text trong Git, mà dùng Sealed Secrets, External Secrets hoặc Vault.
  - Bật Pod Security Admission.
- **Backup:**
  - Snapshot etcd định kỳ bằng `etcdctl snapshot save`.
  - Dùng Velero để backup resource và volume.
- **Nâng cấp cluster:** mỗi lần chỉ nâng một minor version. Thứ tự: `kubeadm upgrade plan`, rồi `kubeadm upgrade apply` trên master, sau đó lần lượt drain, nâng cấp, uncordon từng worker.

---

## Checklist lỗi thường gặp

| Triệu chứng | Nguyên nhân hay gặp |
|---|---|
| Node `NotReady` | Chưa cài CNI, hoặc containerd chưa bật SystemdCgroup |
| Pod `Pending` | Thiếu tài nguyên, PVC không có StorageClass, hoặc taint/nodeSelector không khớp |
| `ImagePullBackOff` | Sai tên/tag image, hoặc thiếu `imagePullSecrets` |
| `CrashLoopBackOff` | App lỗi khi khởi động (xem `kubectl logs --previous`), hoặc liveness probe chạy quá sớm |
| Service `LoadBalancer` treo ở `<pending>` | Bare-metal chưa cài MetalLB |
| HPA hiện `<unknown>` | Chưa có metrics-server, hoặc container thiếu `resources.requests` |

Nếu muốn, mình có thể viết thêm bộ Helm chart mẫu hoặc pipeline CI/CD (GitLab CI / Jenkins + Argo CD) cho service của bạn.