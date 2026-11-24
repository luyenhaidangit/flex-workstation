# C4 Dynamic - Luồng CI/CD deploy ứng dụng

Áp dụng cho `flex-api-gateway` và `flex-auth-service` (hai repo có `Jenkinsfile` giống nhau). Nguồn: `flex-api-gateway/Jenkinsfile`, `flex-auth-service/Jenkinsfile`, `flex-environment/mounts/jenkins/jobs/misa.groovy`, `flex-environment/mounts/jenkins/seeds/seed.groovy`, `flex-environment/mounts/jenkins/jenkins.yaml`, `flex-k8s/README.md`, `flex-k8s/restart.sh`, `flex-k8s/argocd/application.yaml`, cùng xác nhận của người dùng về vị trí Jenkins. Chỉ đọc cấu hình trong repo, chưa chạy thử pipeline.

```mermaid
C4Dynamic
  title Dynamic Diagram - CI/CD deploy ứng dụng (api-gateway, auth-service)

  Person(dev, "Developer", "Viết code, bấm build, cập nhật tag")
  System_Ext(apprepo, "GitHub: repo ứng dụng", "flex-api-gateway, flex-auth-service")
  System_Ext(envrepo, "GitHub: flex-environment", "Khai báo job Jenkins (jobs/*.groovy)")
  System_Ext(k8srepo, "GitHub: flex-k8s", "Manifest Kubernetes")
  System_Ext(registry, "Docker Hub", "Lưu image đã build")

  Container_Boundary(dockerhost, "Docker host dùng chung toàn công ty") {
    Container(jenkins, "Jenkins", "Jenkins LTS, JCasC, Job DSL", "Seed Job và pipeline folder misa (hiển thị MISA)")
    Container(openbao, "OpenBao", "KV flex", "Giữ credential GitHub SSH, Docker Hub")
  }

  Container_Boundary(k3s, "k3s riêng của project Flex") {
    Container(argocd, "Argo CD", "v3.5.7", "Application flex, sync thủ công")
    Container(workload, "Deployment ứng dụng", "Kubernetes", "Rolling update")
  }

  UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")

  Rel(jenkins, openbao, "Đọc credential qua JCasC, token chỉ đọc", "HTTP")
  Rel(jenkins, envrepo, "Seed Job poll, đọc jobs/*.groovy", "SSH")
  Rel(dev, apprepo, "Push code", "Git")
  Rel(dev, jenkins, "Bấm Build with Parameters", "HTTPS")
  Rel(jenkins, apprepo, "Checkout nhánh main", "SSH")
  Rel(jenkins, apprepo, "Multibranch quét flex-api-gateway bằng github-token", "HTTPS, GitHub API")
  Rel(jenkins, registry, "Build và push image", "HTTPS")
  Rel(dev, k8srepo, "Sửa tag image trong flex-k8s, push", "Git")
  Rel(dev, argocd, "Bấm Sync", "HTTPS")
  Rel(argocd, k8srepo, "Lấy manifests/", "HTTPS")
  Rel(argocd, workload, "Apply, rolling update", "Kubernetes API")

  UpdateElementStyle(jenkins, $bgColor="#7f8c8d", $borderColor="#5d6d6e")
  UpdateElementStyle(openbao, $bgColor="#7f8c8d", $borderColor="#5d6d6e")
```

**Chú giải màu**: xám = hạ tầng Docker dùng chung toàn công ty; xanh (mặc định) = thành phần riêng của project Flex trong k3s.

## Các bước

| Bước | Hành động | Thuộc về | Tự động? | Bằng chứng |
| --- | --- | --- | --- | --- |
| 0 | Seed Job poll `flex-environment` (~5 phút một lần và mỗi lần Jenkins khởi động), tạo hoặc cập nhật folder và job từ `mounts/jenkins/jobs/*.groovy`; job bị bỏ khỏi DSL chỉ bị DISABLE, không bị xóa | Docker dùng chung (Jenkins) | Tự động | `seeds/seed.groovy` (`triggers { scm }`, `queue('seed')`, `removedJobAction('DISABLE')`) |
| 1 | Push code lên GitHub | Repo ứng dụng | Thủ công | Jenkins job lấy nhánh `main`; `flex-api-gateway` là Multibranch chỉ nhận `main` |
| 2 | Chạy build với tham số `TARGET_ENV` (dev/uat/prod), `MAJOR`, `MINOR`, `PROD_PATCH`, `DEPLOY`. Với `flex-api-gateway` (Multibranch), bấm Scan Repository hoặc Build with Parameters trên nhánh `main`; lần quét đầu tự build một lần với tham số mặc định | Docker dùng chung (Jenkins) | Thủ công (`flex-api-gateway`: lần quét đầu tự động) | `Jenkinsfile` không có `triggers`; `misa.groovy` không có webhook hay `periodicFolderTrigger` cho cả hai kiểu job (chỉ Seed Job có poll SCM) |
| 3 | Checkout, tính `VERSION` | Docker dùng chung (Jenkins) | Tự động | stage `Checkout`, `Prepare` |
| 4 | `docker build` rồi tag và push `<user>/<app>:<VERSION>` lên Docker Hub (chỉ khi `DEPLOY=true`) | Docker dùng chung (Jenkins) | Tự động | stage `Image`, `Publish`, credential `dockerhub-creds` |
| 5 | Sửa `image:` trong `flex-k8s/manifests/<app>/deployment.yaml` rồi push | Repo `flex-k8s` | **Thủ công** | README `flex-k8s` mục "Cập nhật nhanh" |
| 6 đến 8 | Argo CD sync `manifests/` vào namespace `default` | k3s riêng Flex | Thủ công | `syncPolicy: {}` trong `argocd/application.yaml` |

Ranh giới dùng chung / riêng nằm giữa bước 4 và bước 5: Jenkins (dùng chung) chỉ đẩy image lên Docker Hub; từ đó trở đi là phần riêng của Flex (repo `flex-k8s`, Argo CD, k3s), và hai bên không gọi trực tiếp nhau.

Quy tắc version: môi trường không phải prod dùng `MAJOR.MINOR.<BUILD_NUMBER>-<env>` (ví dụ `1.0.12-dev`); prod dùng `MAJOR.MINOR.PROD_PATCH` và bắt buộc có `PROD_PATCH`.

Cách deploy thay thế bước 6 đến 8: chạy `bash restart.sh [app]` trong `flex-k8s` trên server. Script `kubectl apply`, restart deployment nếu ConfigMap đổi, chờ `rollout status` 180 giây; lỗi thì in log và gợi ý `kubectl rollout undo deployment/<tên>` (không tự rollback).

## Điểm cần lưu ý

- **Chưa liền mạch**: sau khi build xong image, không có bước nào tự cập nhật tag trong `flex-k8s` (bước 5) và Argo CD không tự sync. Mỗi lần deploy cần hai thao tác tay.
- **Stage Build, Test, Quality & Security chỉ in "Nothing to do"** trong cả hai Jenkinsfile, nên pipeline hiện chưa có kiểm tra chất lượng nào trước khi push image.
- **Vị trí Jenkins**: Docker host dùng chung; cấu hình nằm ở `flex-environment/docker-compose.infra.yml` và `mounts/jenkins/`. Người dùng đã chạy thành công Seed Job (build #2) và thấy folder `misa`; chưa chạy thử pipeline ứng dụng.
- **Phụ thuộc OpenBao**: credential `github-ssh` và `dockerhub-creds` do JCasC đọc từ OpenBao lúc Jenkins khởi động. OpenBao còn sealed hoặc secret còn `CHANGE_ME` thì biến secret thành chuỗi rỗng hoặc sai, Seed Job không checkout được (đã gặp lỗi `error in libcrypto` khi key sai định dạng). Thứ tự đúng: unseal OpenBao, điền secret, rồi mới khởi động Jenkins.
- **`flex-api-gateway` chuyển sang Multibranch** (khai báo trong `misa.groovy`, chưa chạy thử): chỉ nhận nhánh `main`, không build PR nên chưa có trạng thái build trên PR; quét repo bằng credential `github-token`, checkout bằng `github-ssh`; không có `periodicFolderTrigger` và chưa cấu hình webhook. Hai repo còn lại vẫn là `pipelineJob` chạy tay.
- **Multibranch tự build lần quét đầu**: `Jenkinsfile` có `DEPLOY=true` mặc định, nên lần quét đầu build `main` và push một image `<VERSION>` lên Docker Hub mà không cần bấm. Khi thêm webhook, mỗi push vào `main` cũng sẽ tự build và push như vậy, khác với bước 2 hiện là thủ công. Muốn build PR thì phải thêm điều kiện chặn `Publish` cho PR trong `Jenkinsfile` của từng repo trước.
- **Phụ thuộc OpenBao (GitHub)**: khoá `github_username`, `github_token` phải được thêm tay vào secret `flex/github` (service `openbao-sync` không thêm khoá mới vào secret đã có); thiếu thì credential `github-token` là chuỗi rỗng.
- **Chưa xác minh**: pipeline `flex-ai-gateway` (khai báo trong `misa.groovy` nhưng repo này không có trong `workstation.json`).
- **`flex-exchange-service`** có `.github/workflows/ci.yml` riêng, mình chưa đọc nên không vẽ.

## Luồng khác: GitHub Actions cho `flex-environment` (không vẽ)

`flex-environment/.github/workflows/ci-cd.yml` chạy khi push hoặc **pull request** vào `main` (và thủ công): SSH vào server rồi chạy `./restart.sh`. Theo `flex-environment/AGENTS.md`, `restart.sh` không có terminal sẽ chạy `all`, tức là `git pull`, `down` rồi `up -d` toàn bộ container. Trigger `pull_request` nghĩa là PR cũng có thể kích hoạt deploy, cần xem lại.
