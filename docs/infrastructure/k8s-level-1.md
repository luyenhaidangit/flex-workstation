# Kubernetes Level 1: Hiểu và dùng Kubernetes trên máy cá nhân

Level 1 dành cho người mới. Mục tiêu là **hiểu Kubernetes làm gì và dùng thành thạo các đối tượng cốt lõi**, chưa cần dựng hạ tầng. Bạn dùng một cluster giả lập chạy ngay trên máy (minikube), nên không cần server, VM hay các bước cài đặt như trong [k8s-level-2.md](k8s-level-2.md).

Nguyên tắc học: **làm thật, quan sát, rồi cố tình làm hỏng để hiểu vì sao**. Mỗi bài có 4 phần: khái niệm, thực hành, hiểu sâu, thử phá.

---

## Mục tiêu và tiêu chí hoàn thành

Sau Level 1 bạn phải tự làm được, không cần nhìn tài liệu:

- Giải thích được đường đi của một lệnh `kubectl apply` từ máy bạn đến container đang chạy.
- Deploy một app gồm Deployment, Service, ConfigMap, Secret và PVC.
- Cập nhật phiên bản không downtime và rollback khi lỗi.
- Đọc `describe` và `logs` để tìm nguyên nhân khi pod lỗi (`Pending`, `CrashLoopBackOff`, `ImagePullBackOff`).

## Lộ trình

| Bài | Nội dung | Thời lượng gợi ý |
| --- | --- | --- |
| 0 | Chuẩn bị môi trường | 1 giờ |
| 1 | Bức tranh kiến trúc | 1 giờ |
| 2 | Pod | 1–2 giờ |
| 3 | Deployment | 2 giờ |
| 4 | Service | 2 giờ |
| 5 | ConfigMap và Secret | 1–2 giờ |
| 6 | Volume và PVC | 1–2 giờ |
| 7 | Probe và resources | 2 giờ |
| 8 | Namespace | 1 giờ |
| 9 | Ingress (tuỳ chọn) | 1 giờ |
| 10 | Bài tập tổng hợp | 3–4 giờ |

Học theo đúng thứ tự vì bài sau dùng lại kiến thức bài trước.

## Quy ước

- Toàn bộ lệnh chạy trong **terminal WSL** (Ubuntu, bash), không chạy trong PowerShell.
- Tạo một thư mục riêng trong WSL để chứa file YAML: `mkdir -p ~/k8s-lab && cd ~/k8s-lab`. Đặt trong filesystem của WSL (`~`), **không** đặt dưới `/mnt/c` vì chậm. Không đặt trong repo này và không commit.
- Lệnh có `port-forward`, `minikube service` hoặc `minikube tunnel` chạy liên tục. Hãy mở một cửa sổ terminal WSL thứ hai cho chúng.
- Trình duyệt trên Windows mở được `http://localhost:8080` cho các port mà WSL đang lắng nghe (WSL2 tự chuyển tiếp localhost). Nếu không mở được, xem [Phụ lục D](#phụ-lục-d-lưu-ý-riêng-khi-dùng-wsl).

---

## Bài 0: Chuẩn bị môi trường

**Giả định:** WSL2 với distro Ubuntu 22.04/24.04, CPU amd64, còn khoảng 4 GB RAM trống cho WSL. Kiểm tra phiên bản WSL bằng `wsl -l -v` trong PowerShell, cột `VERSION` phải là `2`.

**Bước 1. Docker chạy được trong WSL.** Chọn một trong hai cách, miễn `docker ps` chạy được trong terminal WSL:

- **Đã có Docker Desktop:** bật *Settings → Resources → WSL Integration* cho distro Ubuntu của bạn.
- **Chưa có:** cài Docker Engine trực tiếp trong WSL. Cách này cần **systemd**:
  ```bash
  ps -p 1 -o comm=        # phải in ra: systemd
  ```
  Nếu không in `systemd`, thêm vào `/etc/wsl.conf` rồi chạy `wsl --shutdown` trong PowerShell và mở lại WSL:
  ```ini
  [boot]
  systemd=true
  ```
  Sau đó cài Docker:
  ```bash
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $USER      # đóng và mở lại terminal để có hiệu lực
  docker ps
  ```

**Bước 2. Cài kubectl và minikube trong WSL:**

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl

curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
```

**Bước 3. Tạo cluster:**

```bash
minikube start --driver=docker
kubectl get nodes
kubectl cluster-info
```

Kết quả mong đợi: có đúng 1 node tên `minikube`, `STATUS` là `Ready`, `ROLES` là `control-plane`.

**Hiểu sâu:**

- `minikube` tạo cluster, `kubectl` là công cụ để **nói chuyện với cluster**. Đây là hai công cụ khác nhau.
- Với driver Docker, node `minikube` thực chất là một container Docker. Kiểm tra bằng `docker ps`. Như vậy cluster của bạn nằm trong container, bên trong WSL, bên trong Windows.
- `kubectl` đọc file `~/.kube/config` (trong WSL) để biết cluster nào cần gọi. Xem bằng `kubectl config get-contexts`.
- Sau khi tắt WSL hoặc khởi động lại máy, cluster dừng. Chạy lại `minikube start`, dữ liệu vẫn còn.

**Dừng và xoá cluster khi không dùng:**

```bash
minikube stop      # tắt, giữ dữ liệu
minikube delete    # xoá hẳn
```

---

## Bài 1: Bức tranh kiến trúc

**Khái niệm cốt lõi:** Kubernetes hoạt động theo **mô hình khai báo**. Bạn không ra lệnh "hãy chạy container", mà khai báo **trạng thái mong muốn** ("tôi muốn 3 bản sao của app này"). Kubernetes liên tục so sánh trạng thái thực tế với trạng thái mong muốn, và sửa cho khớp. Vòng lặp này gọi là **reconciliation loop**.

```text
kubectl apply -f app.yaml
        │
        ▼
 ┌─────────────┐    lưu trạng thái     ┌──────┐
 │ API server  │ ────────────────────▶ │ etcd │
 └──────┬──────┘                       └──────┘
        │ thông báo có thay đổi
        ▼
 ┌────────────────────┐   tạo Pod chưa có chỗ chạy   ┌───────────┐
 │ Controller manager │ ───────────────────────────▶ │ Scheduler │
 └────────────────────┘                              └─────┬─────┘
                                                           │ chọn node
                                                           ▼
                                                    ┌────────────┐
                                                    │  kubelet   │ chạy container
                                                    │ (trên node)│ qua containerd
                                                    └────────────┘
```

| Thành phần | Vai trò |
| --- | --- |
| API server | Cổng duy nhất. Mọi thứ (kubectl, kubelet, controller) đều gọi qua đây. |
| etcd | Cơ sở dữ liệu lưu toàn bộ trạng thái cluster. |
| Scheduler | Quyết định pod mới chạy trên node nào. |
| Controller manager | Chạy các vòng lặp giữ trạng thái đúng (đủ số replica, v.v.). |
| kubelet | Agent trên mỗi node, thực sự tạo và giám sát container. |
| kube-proxy | Cấu hình mạng để Service hoạt động. |

**Thực hành:** xem chính các thành phần đó đang chạy dưới dạng pod.

```bash
kubectl get pods -n kube-system
```

Bạn sẽ thấy `etcd-minikube`, `kube-apiserver-minikube`, `kube-scheduler-minikube`, `kube-controller-manager-minikube`, `kube-proxy-...`, `coredns-...`. Chính Kubernetes cũng chạy trên Kubernetes.

**Tự kiểm tra:**

1. Vì sao mọi thành phần đều phải đi qua API server?
2. Nếu một pod bị xoá thủ công, thành phần nào phát hiện và tạo lại pod mới?

---

## Bài 2: Pod

**Khái niệm:** Pod là đơn vị nhỏ nhất Kubernetes chạy. Một pod chứa một hoặc nhiều container dùng chung IP và storage. Thông thường mỗi pod chỉ có một container.

**Thực hành:** tạo file `pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web
  labels:
    app: web
spec:
  containers:
    - name: nginx
      image: nginx:1.27
      ports:
        - containerPort: 80
```

Bốn trường `apiVersion`, `kind`, `metadata`, `spec` có mặt trong mọi manifest Kubernetes.

```bash
kubectl apply -f pod.yaml
kubectl get pods -o wide          # thấy IP của pod và node đang chạy
kubectl describe pod web          # đọc phần Events ở cuối
kubectl logs web
kubectl exec -it web -- sh        # vào trong container, thoát bằng exit
kubectl port-forward pod/web 8080:80
```

Với `port-forward` đang chạy, mở `http://localhost:8080` sẽ thấy trang nginx.

**Hiểu sâu:**

- Pod có IP riêng, nhưng IP đó **thay đổi mỗi lần pod bị tạo lại**. Vì vậy sau này cần Service (Bài 4).
- `describe` là công cụ debug quan trọng nhất. Phần **Events** cho biết pod đã được schedule, pull image, khởi động ra sao.

**Thử phá:**

1. Xoá pod: `kubectl delete pod web`. Pod **không** tự quay lại, vì không có ai quản lý nó. Đây là lý do cần Deployment ở Bài 3.
2. Sửa `image` thành `nginx:khong-ton-tai`, `apply` lại và chạy `kubectl get pods`. Bạn sẽ thấy `ErrImagePull` rồi `ImagePullBackOff`. Chạy `kubectl describe pod web` để đọc lý do trong Events.

Dọn dẹp: `kubectl delete -f pod.yaml`.

**Tự kiểm tra:**

1. Vì sao không nên dùng Pod trực tiếp cho ứng dụng thật?
2. Hai container trong cùng một pod giao tiếp với nhau bằng địa chỉ nào?

---

## Bài 3: Deployment

**Khái niệm:** Deployment khai báo "tôi muốn N bản sao của pod này" và quản lý việc cập nhật. Cấu trúc quản lý:

```text
Deployment ──quản lý──▶ ReplicaSet ──quản lý──▶ Pod, Pod, Pod
```

Deployment lo việc cập nhật phiên bản. ReplicaSet lo việc giữ đủ số pod.

**Thực hành:** tạo file `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

```bash
kubectl apply -f deployment.yaml
kubectl get deployment,rs,pods
```

Chú ý tên pod có dạng `web-<hash-replicaset>-<hash-pod>`, thể hiện quan hệ cha con.

**Hiểu sâu: `selector` và `labels`.** Deployment tìm pod của mình bằng **label**, không phải bằng tên. `spec.selector.matchLabels` phải khớp `spec.template.metadata.labels`. Đây là cơ chế xuyên suốt Kubernetes (Service cũng dùng nó).

**Thử phá và quan sát:**

1. **Tự phục hồi:** mở terminal thứ hai chạy `kubectl get pods -w`. Ở terminal đầu, xoá một pod: `kubectl delete pod <tên-pod>`. Pod mới xuất hiện ngay.
2. **Scale:** `kubectl scale deployment web --replicas=5`, rồi giảm về 2.
3. **Rolling update:**
   ```bash
   kubectl set image deployment/web nginx=nginx:1.28
   kubectl rollout status deployment/web
   kubectl get rs      # ReplicaSet cũ còn lại với 0 pod, ReplicaSet mới có đủ pod
   ```
   Pod được thay dần từng phần (mặc định `maxSurge` và `maxUnavailable` là 25%), nên luôn có pod đang phục vụ.
4. **Update lỗi, rồi rollback:**
   ```bash
   kubectl set image deployment/web nginx=nginx:9.9.9
   kubectl get pods            # pod mới ImagePullBackOff, pod cũ VẪN chạy
   kubectl rollout undo deployment/web
   kubectl rollout history deployment/web
   ```
   Cập nhật lỗi không làm sập app, vì pod cũ chỉ bị thay khi pod mới sẵn sàng. Đây là giá trị lớn nhất của Deployment.

**Tự kiểm tra:**

1. Sau `set image`, vì sao ReplicaSet cũ không bị xoá mà giữ lại 0 pod?
2. Nếu sửa label của một pod đang chạy thành `app: khac`, chuyện gì xảy ra?

---

## Bài 4: Service

**Khái niệm:** IP của pod thay đổi liên tục. Service cấp cho một nhóm pod **một địa chỉ ổn định** (IP ảo và tên DNS), đồng thời cân bằng tải giữa các pod.

| Loại | Truy cập từ | Dùng khi |
| --- | --- | --- |
| `ClusterIP` (mặc định) | Bên trong cluster | Service nội bộ (app gọi database) |
| `NodePort` | Bên ngoài, qua IP node và port 30000–32767 | Test nhanh, hạ tầng đơn giản |
| `LoadBalancer` | Bên ngoài, qua load balancer của cloud | Production trên cloud |

**Thực hành:** giữ Deployment `web` từ Bài 3 (chạy `kubectl apply -f deployment.yaml` lại nếu đã xoá). Tạo `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

```bash
kubectl apply -f service.yaml
kubectl get svc web
kubectl describe svc web          # xem dòng Endpoints: danh sách IP:port của các pod
```

**Gọi Service từ bên trong cluster** bằng một pod tạm:

```bash
kubectl run tmp --rm -it --image=busybox:1.36 --restart=Never -- wget -qO- http://web
```

Tên `web` được CoreDNS phân giải thành IP của Service. Tên đầy đủ là `web.default.svc.cluster.local`.

**Quan sát cân bằng tải:** gửi nhiều request rồi xem pod nào nhận:

```bash
kubectl run tmp --rm -it --image=busybox:1.36 --restart=Never -- sh -c "for i in 1 2 3 4 5 6; do wget -qO- http://web > /dev/null; done"
kubectl logs -l app=web --prefix --tail=10
```

Access log xuất hiện ở nhiều pod khác nhau, chứng tỏ request được chia đều.

**Truy cập từ máy bạn:**

```bash
kubectl port-forward svc/web 8080:80
```

Hoặc đổi `type: NodePort` trong `service.yaml`, `apply` lại, rồi chạy `minikube service web --url` (giữ terminal mở với driver Docker).

**Hiểu sâu: Service không "biết" pod nào cả**, nó chỉ chứa `selector`. Danh sách Endpoints được tự động cập nhật theo các pod khớp label và đang **Ready**.

**Thử phá:**

1. Sửa `selector` thành `app: web-sai`, `apply`, rồi `kubectl describe svc web`. Endpoints là `<none>`, request bị treo. Đây là lỗi kinh điển: Service không tìm thấy pod vì label lệch.
2. Scale Deployment lên 5 rồi xuống 2, mỗi lần chạy `describe svc web` để thấy Endpoints tự cập nhật.

**Tự kiểm tra:**

1. `port` và `targetPort` trong Service khác nhau thế nào?
2. Vì sao app nên gọi database bằng tên Service thay vì IP của pod?

---

## Bài 5: ConfigMap và Secret

**Khái niệm:** tách cấu hình khỏi image. Cùng một image chạy ở dev hay prod chỉ khác cấu hình được truyền vào.

- **ConfigMap:** cấu hình thường.
- **Secret:** dữ liệu nhạy cảm (mật khẩu, token).

**Thực hành với ConfigMap:** tạo `configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-config
data:
  APP_MODE: "dev"
  index.html: |
    <h1>Xin chao tu ConfigMap</h1>
```

Sửa `deployment.yaml`, thêm hai phần vào `spec.template.spec`: biến môi trường và volume.

```yaml
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
          env:
            - name: APP_MODE
              valueFrom:
                configMapKeyRef:
                  name: web-config
                  key: APP_MODE
          volumeMounts:
            - name: html
              mountPath: /usr/share/nginx/html
      volumes:
        - name: html
          configMap:
            name: web-config
            items:
              - key: index.html
                path: index.html
```

```bash
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl exec deploy/web -- printenv APP_MODE
kubectl port-forward svc/web 8080:80      # mở http://localhost:8080
```

**Hiểu sâu: hai cách dùng ConfigMap cập nhật khác nhau.**

1. Sửa `index.html` trong ConfigMap rồi `apply`. Sau khoảng 1 phút, file trong pod **tự đổi** (mount dạng volume được kubelet đồng bộ).
2. Sửa `APP_MODE` thành `prod` rồi `apply`. Biến môi trường trong pod **không đổi**. Bạn phải khởi động lại pod: `kubectl rollout restart deployment/web`.

**Thực hành với Secret:**

```bash
kubectl create secret generic db-secret --from-literal=password=MatKhau123
kubectl get secret db-secret -o yaml
```

Giá trị nằm ở dạng base64. Giải mã:

```bash
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 -d
```

**Lưu ý quan trọng:** base64 **không phải mã hoá**, ai đọc được Secret là giải mã được. Secret chỉ tách dữ liệu nhạy cảm ra khỏi image và manifest chung, và có thể được kiểm soát quyền truy cập riêng (RBAC). Không commit manifest chứa Secret thật vào Git.

Secret dùng giống ConfigMap: qua `env` với `secretKeyRef`, hoặc mount thành file.

**Tự kiểm tra:**

1. Vì sao đổi ConfigMap dạng env không có tác dụng ngay?
2. Secret có an toàn hơn ConfigMap ở điểm nào, và không an toàn ở điểm nào?

---

## Bài 6: Volume và PersistentVolumeClaim

**Khái niệm:** filesystem của container **mất khi pod bị xoá**. Muốn giữ dữ liệu, dùng volume.

- **PVC (PersistentVolumeClaim):** lời xin "cho tôi 1 GB ổ đĩa".
- **StorageClass:** cách cấp ổ đĩa. Minikube có sẵn StorageClass `standard` tự cấp ổ khi có PVC.

**Thực hành:** tạo `pvc-demo.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: writer
spec:
  containers:
    - name: busybox
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: data-pvc
```

```bash
kubectl apply -f pvc-demo.yaml
kubectl get pvc,pv                                   # PVC ở trạng thái Bound
kubectl exec writer -- sh -c "echo xin-chao > /data/hello.txt"

kubectl delete pod writer
kubectl apply -f pvc-demo.yaml                       # tạo lại pod
kubectl exec writer -- cat /data/hello.txt           # dữ liệu vẫn còn
```

**Hiểu sâu:**

- Vòng đời của PVC **độc lập** với pod. Xoá pod không xoá dữ liệu. Xoá PVC mới xoá.
- `ReadWriteOnce` nghĩa là chỉ một node được ghi tại một thời điểm. Vì vậy Deployment nhiều replica dùng chung một PVC dễ gặp vấn đề. Cơ sở dữ liệu thường dùng StatefulSet, sẽ học ở Level sau.

**Thử phá:** thử ghi file vào `/tmp` trong container, xoá pod, rồi kiểm tra lại. File đã mất, vì `/tmp` không nằm trên volume.

Dọn dẹp: `kubectl delete -f pvc-demo.yaml`.

**Tự kiểm tra:**

1. Phân biệt PVC, PV và StorageClass bằng một câu mỗi loại.
2. Xoá pod có làm mất dữ liệu trên PVC không? Vì sao?

---

## Bài 7: Probe và resources

**Khái niệm:** Kubernetes chỉ biết container **đang chạy**, không biết app **hoạt động đúng**. Probe giúp nó biết.

| Probe | Câu hỏi | Khi thất bại |
| --- | --- | --- |
| `readinessProbe` | Pod sẵn sàng nhận request chưa? | Pod bị **loại khỏi Service**, không bị restart |
| `livenessProbe` | Pod còn sống không? | Container bị **restart** |
| `startupProbe` | App khởi động xong chưa? | Hoãn liveness cho app khởi động chậm |

`resources.requests` là lượng tài nguyên **đảm bảo** cho pod (scheduler dùng để chọn node). `resources.limits` là mức **trần** (vượt bộ nhớ thì bị `OOMKilled`, vượt CPU thì bị làm chậm).

**Thực hành:** thêm vào container `nginx` trong `deployment.yaml`:

```yaml
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 3
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 128Mi
```

```bash
kubectl apply -f deployment.yaml
kubectl get pods            # cột READY 1/1
kubectl describe pod <tên-pod>    # xem phần Liveness, Readiness, Limits, Requests
```

**Thử phá:**

1. **Readiness lỗi:** đổi `readinessProbe.path` thành `/khong-co` rồi `apply`. Pod mới ở `0/1 READY`. Chạy `kubectl describe svc web` để thấy Endpoints **không chứa** pod đó. Đây là cách rolling update tránh chuyển traffic vào pod chưa sẵn sàng.
2. **Liveness lỗi:** đổi `livenessProbe.path` thành `/khong-co`. Sau một lúc cột `RESTARTS` tăng liên tục.
3. **Request quá lớn:** đặt `requests.cpu: "100"` (100 core). Pod chuyển sang `Pending`. Chạy `kubectl describe pod` sẽ thấy `Insufficient cpu`. Scheduler không tìm được node đủ tài nguyên.

Sau mỗi thử nghiệm, đưa file về giá trị đúng và `apply` lại.

**Tự kiểm tra:**

1. Khác biệt giữa readiness và liveness về hậu quả khi thất bại?
2. Pod dùng quá `limits.memory` thì chuyện gì xảy ra? Còn quá `limits.cpu`?

---

## Bài 8: Namespace và label

**Khái niệm:** namespace chia cluster thành các vùng tách biệt (theo môi trường hoặc team). Cùng tên đối tượng có thể tồn tại ở nhiều namespace.

**Thực hành:**

```bash
kubectl create namespace dev
kubectl create namespace staging

kubectl apply -f deployment.yaml -n dev
kubectl apply -f service.yaml -n dev
kubectl apply -f deployment.yaml -n staging

kubectl get pods -n dev
kubectl get pods -A                    # tất cả namespace
```

Đặt namespace mặc định để khỏi gõ `-n` liên tục:

```bash
kubectl config set-context --current --namespace=dev
```

**Hiểu sâu:**

- Gọi Service ở namespace khác cần thêm tên namespace: `web.dev` hoặc `web.dev.svc.cluster.local`. Cùng namespace chỉ cần `web`.
- Xoá namespace sẽ xoá **toàn bộ** thứ bên trong: `kubectl delete namespace staging`.
- Label lọc theo nhóm: `kubectl get pods -l app=web`, `kubectl get pods --show-labels`.

Đưa context về mặc định sau khi học: `kubectl config set-context --current --namespace=default`.

**Tự kiểm tra:**

1. Namespace có cách ly mạng giữa các pod không? (Gợi ý: thử gọi `web.dev` từ pod ở namespace `staging`.)
2. Vì sao nên tách `dev` và `staging` thành namespace riêng?

---

## Bài 9: Ingress (tuỳ chọn)

**Khái niệm:** Service `NodePort` mở mỗi port cho từng app. Ingress cho phép **một cổng vào chung** (port 80/443) rồi định tuyến theo host hoặc path tới các Service khác nhau. Ingress cần một **Ingress Controller** để thực thi.

> Ingress-nginx (controller mà minikube dùng) đã được công bố ngừng bảo trì, và Gateway API là hướng thay thế. Ở Level 1 bạn chỉ cần hiểu **khái niệm** Ingress. Bài này tuỳ chọn.

**Thực hành:**

```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx       # đợi controller Running
```

Tạo `ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
spec:
  ingressClassName: nginx
  rules:
    - host: web.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 80
```

```bash
kubectl apply -f ingress.yaml
minikube tunnel                          # giữ terminal mở, có thể hỏi mật khẩu sudo
curl -H "Host: web.local" http://127.0.0.1
```

Ở đây bạn giả lập tên miền bằng header `Host`, không cần sửa file hosts.

**Tự kiểm tra:** Ingress và Ingress Controller khác nhau thế nào? Điều gì xảy ra nếu chỉ có Ingress mà không có Controller?

---

## Bài 10: Bài tập tổng hợp

Tự dựng, không nhìn lại bài cũ. Nếu bí thì mới tra cứu.

**Đề bài:** trong namespace `capstone`, dựng hệ thống gồm:

1. **web:** Deployment nginx 2 replica, nội dung trang lấy từ ConfigMap, có readiness và liveness probe, có requests và limits.
2. **db:** Deployment Postgres 1 replica (`postgres:16`), mật khẩu lấy từ Secret, dữ liệu nằm trên PVC.
3. **Hai Service** ClusterIP: `web` và `db`.

**Tiêu chí hoàn thành:**

- [ ] Truy cập được trang web qua `port-forward`.
- [ ] Từ một pod tạm, kết nối được database qua tên `db`:
  ```bash
  kubectl run psql -n capstone --rm -it --image=postgres:16 --restart=Never --env PGPASSWORD=<mật-khẩu> -- psql -h db -U postgres -c "select 1"
  ```
- [ ] Tạo bảng và thêm dữ liệu, xoá pod `db`, khi pod mới lên dữ liệu vẫn còn.
- [ ] Cập nhật phiên bản `web` không downtime, rồi rollback về bản cũ.
- [ ] Không có mật khẩu dạng chữ thường nào trong manifest Deployment.
- [ ] Tự sửa được ít nhất 2 lỗi cố ý (ví dụ image sai tên, selector lệch label) chỉ bằng `describe` và `logs`.

**Gợi ý:** với Postgres, đặt thêm biến `PGDATA=/var/lib/postgresql/data/pgdata` để tránh lỗi thư mục gốc của volume không rỗng.

---

## Phụ lục A: Thử nhiều node trên một máy

Để thấy pod được phân bổ và di chuyển giữa các node, tạo cluster 3 node. Cần khoảng 6 GB RAM cho WSL, xem cách tăng ở [Phụ lục D](#phụ-lục-d-lưu-ý-riêng-khi-dùng-wsl):

```bash
minikube start -p multi --nodes 3 --driver=docker
kubectl get nodes                     # multi, multi-m02, multi-m03
kubectl apply -f deployment.yaml
kubectl get pods -o wide              # cột NODE cho thấy pod rải trên nhiều node
```

Mô phỏng bảo trì node:

```bash
kubectl drain multi-m03 --ignore-daemonsets --delete-emptydir-data
kubectl get pods -o wide              # pod trên node đó được chuyển sang node khác
kubectl uncordon multi-m03
```

Xoá cluster thử nghiệm: `minikube delete -p multi`.

## Phụ lục B: Bảng lỗi thường gặp

| Triệu chứng | Nguyên nhân thường gặp | Cách kiểm tra |
| --- | --- | --- |
| `ImagePullBackOff` | Sai tên hoặc tag image, registry cần đăng nhập | `describe pod`, đọc Events |
| `CrashLoopBackOff` | App thoát ngay khi khởi động: lỗi cấu hình, thiếu biến môi trường | `kubectl logs <pod> --previous` |
| `Pending` | Không đủ tài nguyên, PVC chưa Bound | `describe pod`, đọc Events |
| `0/1 READY` | Readiness probe thất bại | `describe pod`, `logs` |
| Service gọi không được | Selector lệch label, hoặc pod chưa Ready | `describe svc`, xem Endpoints |
| `OOMKilled` | Vượt `limits.memory` | `describe pod`, mục Last State |

## Phụ lục C: Lệnh kubectl cần thuộc

```bash
kubectl get <loại> [-o wide] [-A] [-n <ns>] [-l key=value] [-w]
kubectl describe <loại> <tên>
kubectl logs <pod> [-f] [--previous] [-l app=web --prefix]
kubectl exec -it <pod> -- sh
kubectl apply -f <file>
kubectl delete -f <file>
kubectl rollout status|history|undo|restart deployment/<tên>
kubectl scale deployment <tên> --replicas=N
kubectl port-forward svc/<tên> 8080:80
kubectl explain <loại>.spec        # tra cấu trúc trường ngay trong terminal
```

`kubectl explain` rất hữu ích: khi không nhớ trường YAML, tra ngay trong terminal thay vì tìm trên mạng.

## Phụ lục D: Lưu ý riêng khi dùng WSL

| Triệu chứng | Nguyên nhân thường gặp | Cách xử lý |
| --- | --- | --- |
| `permission denied` khi chạy `docker` | User chưa thuộc group `docker` | `sudo usermod -aG docker $USER`, rồi đóng và mở lại terminal |
| `Cannot connect to the Docker daemon` | Docker chưa chạy (Engine trong WSL thiếu systemd, hoặc Docker Desktop chưa bật) | `sudo systemctl start docker`, hoặc bật Docker Desktop và WSL Integration |
| `minikube start` báo thiếu RAM hoặc bị treo | WSL2 mặc định chỉ được dùng khoảng 50% RAM máy | Tạo `%UserProfile%\.wslconfig` trên Windows (xem bên dưới), rồi `wsl --shutdown` |
| Mở `http://localhost:8080` trên Windows không được | Port-forward chưa chạy, hoặc localhost forwarding của WSL tắt | Kiểm tra `curl localhost:8080` **trong WSL** trước. Nếu WSL gọi được mà Windows không, kiểm tra `localhostForwarding` trong `.wslconfig` |
| `kubectl` báo `connection refused` sau khi mở lại máy | Cluster đã dừng cùng WSL | `minikube start` |
| Đọc và ghi file YAML rất chậm | Thư mục nằm dưới `/mnt/c` | Chuyển về `~/k8s-lab` |

Cấu hình `%UserProfile%\.wslconfig` để cấp thêm RAM cho WSL:

```ini
[wsl2]
memory=6GB
```

Sau khi sửa, chạy `wsl --shutdown` trong PowerShell rồi mở lại WSL. Chọn mức `memory` sao cho Windows vẫn còn đủ RAM để chạy.

Mẹo: chạy `code .` trong thư mục `~/k8s-lab` để sửa YAML bằng VS Code qua Remote WSL.

---

## Đánh giá cuối Level 1

Bạn sẵn sàng sang Level 2 khi trả lời được, không cần tra cứu:

1. Điều gì xảy ra từ lúc chạy `kubectl apply` đến lúc container chạy?
2. Vì sao cần Deployment thay vì Pod, và Service thay vì IP của pod?
3. Khi Service không kết nối được, bạn kiểm tra theo thứ tự nào?
4. Dữ liệu database nên nằm ở đâu để không mất khi pod bị tạo lại?

**Tiếp theo:** [k8s-level-2.md](k8s-level-2.md) hướng dẫn tự dựng cluster thật bằng kubeadm. Lúc này bạn sẽ hiểu các thành phần (containerd, CNI, kubelet, control-plane) mà minikube đã cài sẵn giúp bạn.

**Lưu ý khi làm Level 2 trên WSL:** Level 2 giả định 3 máy riêng, mỗi máy có hostname và IP tĩnh riêng. Các distro WSL2 dùng chung một máy ảo và cùng địa chỉ IP, nên không dựng được cluster kubeadm nhiều node trên WSL. Trên WSL bạn chỉ dựng được **single-node** (cần bật systemd), còn muốn thực hành nhiều node thì dùng Phụ lục A hoặc tạo VM riêng.
