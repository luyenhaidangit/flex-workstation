# Nghiên cứu kỹ thuật: Triển khai database PostgreSQL (000044)

Căn cứ đọc thực tế (2026-11-28): `flex-k8s/AGENTS.md`, `manifests/flex-api-gateway/*`, `manifests/nginx/*`, `restart.sh`, `set-secret.sh`, README; `flex-environment/AGENTS.md`, `SETUP_SERVER.md`, `temp/docker-compose.infra.yml`, `scripts/postgres-bootstrap/*.sh`, `mounts/openbao/secrets.list`; `flex-database` (cấu trúc thư mục); `docs/architecture/system-map.md`.

## Hiện trạng đã xác minh

- `flex-k8s` có manifest cho `nginx` và `flex-api-gateway` trong namespace mặc định, chưa có workload dữ liệu nào; Argo CD Application `flex` sync thủ công; `restart.sh <app>` apply `manifests/<app>/*.yaml` và yêu cầu tên Deployment trùng tên thư mục.
- Stack PostgreSQL cũ (`flex-environment/temp/`) dùng `postgres:16-alpine`, mật khẩu mặc định ghi cứng, mở cổng 5432 mọi interface, script bootstrap tạo role/database bằng `\gexec`. Một script cũ dùng role `postgres` làm chủ database `agentdb`.
- `flex-database`: `hnx` và `agentdb` có changelog Liquibase PostgreSQL; `aspnetidentity` chứa SQL cú pháp Oracle. Không dùng trong v1.
- Chưa xác minh được: trạng thái thật của k3s trên server mới, tag `postgres` cụ thể, CNI có enforce NetworkPolicy hay không (k3s mặc định có, chưa kiểm chứng).

## Quyết định

### R-001 Kiểu workload
- **Quyết định**: Deployment 1 bản, `strategy: Recreate`, PVC `ReadWriteOnce` riêng.
- **Lý do**: Khớp quy ước `restart.sh`; một bản duy nhất; `Recreate` ngăn hai pod cùng ghi PVC khi cập nhật.
- **Phương án đã loại**: StatefulSet (cần headless Service và phá quy ước tên); operator như CloudNativePG (quá nặng, thêm CRD cho node 3,8 GiB, dư cho một bản không replica).
- **Rủi ro còn lại**: Khi cập nhật có khoảng gián đoạn ngắn (đã chấp nhận ở spec §6).

### R-002 Image
- **Quyết định**: `postgres:16.16-alpine` (đã chốt 2026-11-28: tag là bản 16.x mới nhất theo Docker Hub, `docker manifest inspect` có manifest `linux/amd64`); không `latest`.
- **Lý do**: Giữ major của stack cũ; image nhỏ.
- **Phương án đã loại**: Major mới hơn (chưa có yêu cầu).
- **Rủi ro còn lại**: Chưa chạy thử image trên server thật; uid `70` của user `postgres` trong image alpine là theo Dockerfile chính thức, chưa kiểm bằng `docker run`.

### R-003 Tài nguyên và tham số
- **Quyết định**: requests 100m CPU và 256Mi; limit memory 1Gi, không đặt limit CPU; `shared_buffers=128MB`, `max_connections=50` truyền bằng `args`.
- **Lý do**: Server 3,8 GiB không swap còn chạy k3s, OpenBao, nginx, Portainer, code-server (NFR-001); limit memory 1Gi cho ba database trống với tải nhỏ; bỏ limit CPU tránh throttling không cần thiết.
- **Phương án đã loại**: Không có limit; limit 512Mi (dễ OOMKilled khi nhiều kết nối).
- **Rủi ro còn lại**: Con số là ước lượng, chưa đo; điều chỉnh theo `kubectl top`.

### R-004 Lưu trữ
- **Quyết định**: PVC 10Gi trên StorageClass mặc định của k3s (`local-path`); `PGDATA` đặt ở thư mục con của điểm mount.
- **Lý do**: Đơn giản, đủ cho v1; thư mục con tránh lỗi khởi tạo do `lost+found`.
- **Phương án đã loại**: `hostPath` thủ công; PVC lớn hơn (đĩa 38 GB dùng chung).
- **Rủi ro còn lại**: Dữ liệu gắn với đĩa node, không sao lưu (người dùng đã chấp nhận); xác minh StorageClass thực tế trên cụm.

### R-005 Mạng
- **Quyết định**: Service `ClusterIP` tên `postgres` cổng 5432; NetworkPolicy chỉ cho phép pod nhãn `postgres-access: "true"`; người vận hành truy cập bằng `kubectl port-forward`.
- **Lý do**: Đáp ứng FR-008; port-forward và probe kubelet đi từ node nên không bị NetworkPolicy chặn (đúng như ghi chú trong `networkpolicy.yaml` của gateway).
- **Phương án đã loại**: NodePort/hostPort (mở cổng ra ngoài); chỉ dựa tường lửa host.
- **Rủi ro còn lại**: Nếu CNI không enforce thì NetworkPolicy không có tác dụng; kiểm tra bằng pod thử không nhãn.

### R-006 Tạo database và tài khoản
- **Quyết định**: Script `scripts/postgres-bootstrap.sh` chạy `kubectl exec` vào pod và dùng `psql`; tạo role/database theo mẫu `\gexec` idempotent; đồng bộ mật khẩu bằng `ALTER ROLE`; `REVOKE CONNECT ... FROM PUBLIC` rồi chỉ `GRANT CONNECT` cho role sở hữu.
- **Lý do**: Chạy lại an toàn (FR-010); không bị ràng buộc bất biến của Job; tái dùng mẫu đã có trong `flex-environment`.
- **Phương án đã loại**: Job (spec Job bất biến, apply lại khi đổi nội dung sẽ lỗi); initContainer (server chưa chạy ở thời điểm đó).
- **Rủi ro còn lại**: Phải chạy tay sau khi pod Ready; script dừng rõ ràng nếu pod chưa sẵn sàng.

### R-007 Mật khẩu
- **Quyết định**: Secret K8s `postgres-secret` tạo bằng `set-secret.sh` với các key `POSTGRES_PASSWORD`, `HNX_DB_PASSWORD`, `AUTH_DB_PASSWORD`, `AGENT_DB_PASSWORD`; giá trị gốc nằm ở OpenBao secret `postgres` (thêm dòng vào `mounts/openbao/secrets.list`, chạy job Jenkins `infra/openbao-sync`, điền giá trị thật ở UI).
- **Lý do**: Đúng quy trình thêm secret của `flex-environment`; mật khẩu không vào Git, log hay tham số lệnh (`set-secret.sh` nhận giá trị qua stdin).
- **Phương án đã loại**: Mật khẩu trong ConfigMap/manifest; dùng lại mật khẩu stack cũ (vi phạm BR-003); đồng bộ OpenBao vào cụm tự động (cần External Secrets/Vault agent, dư cho v1).
- **Rủi ro còn lại**: Việc chép giá trị từ OpenBao sang Secret K8s làm tay; ghi rõ trong quickstart.

### R-008 Đặt tên database và tài khoản
- **Quyết định**: Giữ tên ở cấu hình hiện hữu: `flex_exchange_hnx`, `aspnetidentity`, `agentdb`; mỗi database một role sở hữu riêng (`hnx`, `aspnetidentity`, `agentdb`); role `agentdb` thay cho việc dùng `postgres` như cấu hình cũ.
- **Lý do**: Giữ tương thích tên với các service sẽ chuyển sang; tách quyền theo BR-001/BR-002.
- **Phương án đã loại**: Một role chung cho mọi database.
- **Rủi ro còn lại**: Service sau này có thể muốn đổi tên; đổi tên là việc của feature đó.

## Câu hỏi kỹ thuật còn lại (không chặn thiết kế)

- **TQ-001**: Đã giải quyết (2026-11-28): `postgres:16.16-alpine`, có manifest `linux/amd64`.
- **TQ-002**: Chưa xác minh (2026-11-28): máy dev chưa có context `kubectl` và người dùng chưa chọn cách truy cập cụm. Đang giả định k3s có StorageClass mặc định `local-path` và CNI có enforce NetworkPolicy; cần kiểm bằng `kubectl get storageclass` và pod thử khi truy cập được cụm. **Cập nhật 2026-11-29:** người dùng tự kiểm tra thủ công trên cụm và xác nhận mọi bước đạt (không đính kèm output); không có đo đạc số liệu lưu lại.
