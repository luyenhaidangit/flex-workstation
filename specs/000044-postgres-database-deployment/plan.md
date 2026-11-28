# Kế hoạch triển khai: Triển khai database PostgreSQL

**Branch**: `000044-postgres-database-deployment` | **Ngày**: 2026-11-28 | **Chế độ Spec**: Full | **Đặc tả**: [spec.md](./spec.md)  
**Đầu vào**: `/specs/000044-postgres-database-deployment/spec.md` và phạm vi repo tại `repos.md`

## Tóm tắt

- **Yêu cầu chính từ spec**: Một PostgreSQL duy nhất (không replica) trên k3s một node, nhiều database trống, mỗi service một database và một tài khoản riêng (US-001); mật khẩu từ nơi lưu bí mật, không có mật khẩu mặc định, không truy cập được từ Internet (US-002); kiểm tra sức khỏe (US-003). Không sao lưu, không áp schema/dữ liệu cũ.
- **Hướng tiếp cận kỹ thuật**: Deployment 1 bản `Recreate` + PVC, image `postgres` ghim phiên bản, Service `ClusterIP` + NetworkPolicy; secret tạo bằng `set-secret.sh` từ giá trị trong OpenBao; script `kubectl exec` idempotent tạo database/role.
- **Kết quả research**: Xem [research.md](./research.md). Không còn câu hỏi kỹ thuật chặn thiết kế; còn hai điểm cần xác minh lúc implement (tag image, k3s thật trên server).

## Phạm vi kỹ thuật

- **Trong phạm vi**: `flex-k8s` (manifest `manifests/postgres/`, `scripts/postgres-bootstrap.sh`, README), `flex-environment` (dòng secret `postgres` trong `mounts/openbao/secrets.list`, ghi chú `SETUP_SERVER.md`), `docs/architecture/system-map.md` của workstation. Khớp `repos.md` và MVP-001..004.
- **Ngoài phạm vi kỹ thuật**: Sao lưu, replica, áp schema/dữ liệu (kể cả Liquibase của `flex-database`), đổi connection string của service, giám sát nâng cao, user deploy thay `root`.

## Bối cảnh kỹ thuật

- **Ngôn ngữ / Framework**: YAML Kubernetes thuần (không Kustomize/Helm theo `flex-k8s/AGENTS.md`), Bash, `psql`.
- **Service / Repo liên quan**: `flex-k8s` (Edit), `flex-environment` (Edit), `flex-database` (Read).
- **Convention skill áp dụng**: `flex-devops-engineering` (manifest K8s, probe, resource, secret, rollout/rollback), `flex-database-engineering` (ranh giới sở hữu database; v1 không có migration), `flex-repo-scope`.
- **Lưu trữ & Phụ thuộc chính**: PostgreSQL 16 (khớp stack cũ), StorageClass `local-path` mặc định của k3s, OpenBao làm nguồn mật khẩu, `kubectl` có quyền trên cụm.
- **Kiểm thử & Đơn vị deploy**: Kiểm tra tĩnh manifest/script; kiểm tra runtime bằng `kubectl` + `psql` trên cụm sau khi được phép; đơn vị deploy là Deployment `postgres`.
- **Mục tiêu hiệu năng & Ràng buộc**: Theo NFR-001/002: tối đa khoảng 1 GiB RAM, khoảng 10 GiB đĩa, sẵn sàng trong 5 phút sau khi khởi động lại. Server 3,8 GiB RAM, không swap, đĩa 38 GB.

## Kiểm tra constitution

*GATE: Đánh giá trước Phase 0 và xác nhận lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú / Dẫn chứng |
|------|--------------------|-----------------------|---------------------|
| Scope & Traceability Gate | Pass | Pass | Spec đã thu hẹp (bỏ áp schema) theo quyết định người dùng; mọi FR/NFR có mapping ở bảng Traceability |
| Test & Security Gate | Pass | Pass | Không secret trong repo, không NodePort, NetworkPolicy, role riêng và `REVOKE CONNECT` khỏi PUBLIC; kiểm thử ở mục Chiến lược kiểm thử |
| Compatibility & DB Placement (VI) | Pass | Pass | Database đích: instance PostgreSQL mới `postgres` trong cụm, ba database trống; không migration nên không có repo migration chịu trách nhiệm ở v1 (đối chiếu `system-map.md` mục 5 và ADR-002) |
| Observability & Complexity Gate | Pass | Pass | Probe `pg_isready`, `kubectl logs`; thiết kế tối giản: không operator, không Job, không StatefulSet |
| Specialist Skill Gate | Pass | Pass | Đã route `flex-devops-engineering` và `flex-database-engineering`, đọc và áp dụng trước khi quyết định |

## Câu hỏi kỹ thuật & Quyết định thiết kế

Chi tiết và phương án đã loại ở [research.md](./research.md).

| Mã | Vấn đề / Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại |
|----|---------------------|----------|------------|-------------------|
| DEC-001 | Kiểu workload | Deployment 1 bản, `strategy: Recreate`, PVC riêng | Khớp quy ước `restart.sh` (tên Deployment = tên thư mục); một bản duy nhất, `Recreate` tránh hai pod cùng ghi một PVC | StatefulSet (phá quy ước, không cần cho 1 bản); operator Postgres (quá nặng cho node 3,8 GiB) |
| DEC-002 | Image | `postgres` bản 16 alpine, ghim tag phiên bản cụ thể | Giữ major 16 như stack cũ, nhẹ; không `latest` | Bản 17/18 (chưa có yêu cầu, thêm rủi ro tương thích service) |
| DEC-003 | Tài nguyên | requests 100m CPU / 256Mi; limit memory 1Gi; `shared_buffers=128MB`, `max_connections=50` | Phù hợp NFR-001; limit memory đủ để tránh OOM với tải nhỏ | Không đặt limit (một service ngốn hết RAM node); limit thấp hơn 512Mi (rủi ro OOMKilled) |
| DEC-004 | Lưu trữ | PVC 10Gi, StorageClass mặc định `local-path`, `PGDATA` trong thư mục con | Đủ cho v1, tránh lỗi `lost+found` ở gốc volume | hostPath thủ công; PVC lớn hơn 10Gi (đĩa 38 GB còn dùng chung) |
| DEC-005 | Mạng | Service `ClusterIP`; NetworkPolicy chỉ cho pod nhãn `postgres-access: "true"`; vận hành qua `kubectl port-forward` | FR-008/AC-006; port-forward và kubelet probe không bị chặn | NodePort/hostPort (mở ra ngoài); chỉ dựa tường lửa host |
| DEC-006 | Tạo database/tài khoản | Script `scripts/postgres-bootstrap.sh` dùng `kubectl exec` + `psql`, idempotent bằng `\gexec` | Chạy lại an toàn (FR-010); mật khẩu truyền qua stdin/biến, không qua tham số | Job (bất biến, apply lại khi đổi spec sẽ lỗi); initContainer (server chưa chạy lúc đó) |
| DEC-007 | Mật khẩu | Secret `postgres-secret` tạo bằng `set-secret.sh`; nguồn ở OpenBao secret `postgres` | Theo quy trình sẵn có của repo; không secret trong Git | Ghi vào ConfigMap/manifest; dùng lại mật khẩu stack cũ |
| DEC-008 | Phân quyền database | Mỗi database một role sở hữu riêng (kể cả agent, không dùng `postgres`); `REVOKE CONNECT ON DATABASE ... FROM PUBLIC` rồi `GRANT CONNECT` cho role sở hữu | AC-003, BR-001, BR-002 | Dùng một role chung cho mọi database |

## Thiết kế tổng quan

- **Luồng xử lý chính**: (1) Người vận hành thêm secret `postgres` vào `secrets.list`, chạy job `infra/openbao-sync`, điền giá trị ở OpenBao. (2) Tạo Secret `postgres-secret` trên cụm bằng `set-secret.sh`. (3) `restart.sh postgres` apply PVC, Deployment, Service, NetworkPolicy và chờ rollout. (4) Chạy `scripts/postgres-bootstrap.sh` để tạo role và database. (5) Chạy quickstart để kiểm chứng.
- **Component / Module tham gia & Boundary**: `manifests/postgres/` giữ toàn bộ tài nguyên K8s; script bootstrap giữ logic tạo role/database; OpenBao chỉ là nơi lưu giá trị gốc, không được cụm đọc trực tiếp trong v1.
- **Luồng lỗi & Idempotency / Concurrency**: Script dừng ngay nếu thiếu key trong Secret hoặc pod chưa sẵn sàng; `CREATE ROLE`/`CREATE DATABASE` chỉ chạy khi chưa tồn tại; `ALTER ROLE` đồng bộ mật khẩu từ Secret, nên chạy lại không sinh trùng và không đổi dữ liệu. `Recreate` đảm bảo không có hai pod cùng PVC.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID (`MVP`/`US`/`FR`/`BR`/`SEC`/`NFR`) | Ưu tiên | Hướng xử lý kỹ thuật | Module / Path dự kiến | API / Contract | Data / Entity | Kiểm thử |
|---|---|---|---|---|---|---|
| US-001 / FR-001 / FR-003 | P1 | Deployment `Recreate` + PVC, tự khởi động lại | `flex-k8s/manifests/postgres/deployment.yaml`, `pvc.yaml` | Connection contract | Máy chủ PostgreSQL | Xóa pod, kiểm tra dữ liệu còn và pod lên lại |
| FR-002 / SC-003 | P1 | `replicas: 1`, không replica | `flex-k8s/manifests/postgres/deployment.yaml` | Không áp dụng | Máy chủ PostgreSQL | Đếm pod `postgres` bằng 1 |
| FR-004 / FR-005 / BR-001 / BR-002 | P1 | Role và database riêng, `REVOKE CONNECT` khỏi PUBLIC | `flex-k8s/scripts/postgres-bootstrap.sh` | Connection contract | Database nghiệp vụ, Tài khoản service, Tài khoản quản trị | Mỗi role vào DB của mình được, DB khác bị từ chối |
| FR-006 / FR-007 / BR-003 / SEC-001 | P1 | Secret từ OpenBao qua `set-secret.sh`; không mật khẩu mặc định | `flex-environment/mounts/openbao/secrets.list`, `flex-k8s/set-secret.sh` | Connection contract (tên key) | Tài khoản service | Thử mật khẩu cũ bị từ chối; thiếu key thì script dừng; quét diff không có secret |
| FR-008 / US-002 | P1 | `ClusterIP` + NetworkPolicy, không NodePort | `flex-k8s/manifests/postgres/service.yaml`, `networkpolicy.yaml` | Connection contract | Không áp dụng | Quét cổng 5432 từ máy ngoài; pod không nhãn bị chặn |
| FR-009 / US-003 | P2 | `startupProbe`, `readinessProbe`, `livenessProbe` dùng `pg_isready` | `flex-k8s/manifests/postgres/deployment.yaml` | Không áp dụng | Không áp dụng | Dừng tiến trình có chủ đích, trạng thái chuyển không khỏe trong 1 phút |
| FR-010 | P1 | Script idempotent, `apply` thuần khai báo | `flex-k8s/scripts/postgres-bootstrap.sh`, `restart.sh` | Không áp dụng | Không áp dụng | Chạy bootstrap và `restart.sh` lần hai, kết quả không đổi |
| NFR-001 / SC-005 / NFR-002 | P1 | Requests/limits, PVC 10Gi, probe | `flex-k8s/manifests/postgres/deployment.yaml`, `pvc.yaml` | Không áp dụng | Không áp dụng | `kubectl top`, khởi động lại node và đo thời gian sẵn sàng |
| BR-004 | P1 | Không `delete`/`down` dữ liệu; rollback không xóa PVC | `flex-k8s/README.md` | Không áp dụng | Không áp dụng | Rà soát lệnh trong README và script |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược / Rủi ro | Cách kiểm tra |
|---------|------------------|----------------------------|---------------|
| Database / Migration | Tạo ba database trống; không có migration | Không có dữ liệu cũ nên không rủi ro tương thích; mất đĩa node là mất dữ liệu (đã chấp nhận) | Query `\l` và `\du` trong quickstart |
| API / Contract | Không có API; có hợp đồng kết nối (tên Service, cổng, tên database/role, key Secret) | Mới hoàn toàn, chưa có consumer trong cụm | Đối chiếu [contracts/connection-contract.md](./contracts/connection-contract.md) |
| Permission / Security | Role riêng, `REVOKE` khỏi PUBLIC, NetworkPolicy, không NodePort | Sai nhãn pod hoặc CNI không enforce có thể để hở trong cụm | Kiểm thử cô lập ở quickstart |
| Logging / Audit | Log container PostgreSQL qua `kubectl logs`; script in kết quả từng bước | Log không được chứa mật khẩu; `log_statement` giữ mặc định | Đọc log sau triển khai |
| UI / UX | Không áp dụng | Không áp dụng | Không áp dụng |
| Job / Worker / Integration | Không có Job; script bootstrap chạy tay | Chạy khi pod chưa sẵn sàng sẽ dừng với thông báo rõ | Chạy script trước khi pod Ready |

## API/Contract Detail

**Có thay đổi contract không**: Có — thêm hợp đồng kết nối mới (không phá hợp đồng nào đang chạy).

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|-----------------------|
| `postgres:5432` và ba cặp database/role | Kết nối dữ liệu | Thêm mới | Có (chưa có consumer) | `flex-auth-service`, `flex-agent-service`, dịch vụ sàn HNX khi chuyển sang cụm; không đổi gì ở v1 |

## Permission Matrix

| Vai trò / Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Điều kiện / Ghi chú |
|-----------------|-----|-----|-----|-----|-------------|---------------------|
| Người vận hành (quản trị) | Có | Có | Có | Có (cần xác nhận) | Có | Qua `kubectl` và tài khoản quản trị; xóa dữ liệu cần xác nhận (BR-004) |
| Service (role sở hữu một database) | Có | Có | Có | Có | Không | Chỉ trong database của mình, chỉ từ pod nhãn `postgres-access: "true"` |
| Máy ngoài hạ tầng / role của service khác | Không | Không | Không | Không | Không | Bị chặn bởi mạng và `REVOKE CONNECT` |

## Dữ liệu & Migration

- **Có thay đổi dữ liệu/schema không**: Không áp dụng — v1 chỉ dựng máy chủ và tạo database/role trống; không có schema, bảng hay migration.
- **Database đích & Repo chứa migration**: Instance mới `postgres` (ba database `flex_exchange_hnx`, `aspnetidentity`, `agentdb`). `docs/architecture/system-map.md` mục 5 và ADR-002 xác nhận hướng bỏ Oracle sang PostgreSQL, và ghi `flex-database` là repo migration dùng chung; schema sẽ do feature sau áp (ví dụ `000009-auth-postgres-migration`). Hiện `flex-database` có Liquibase cho `hnx`/`agentdb`, còn `aspnetidentity` là SQL kiểu Oracle chưa dùng được.
- **Chi tiết Migration / Backfill / Tương thích dữ liệu cũ**: Không áp dụng; xem [data-model.md](./data-model.md) cho thực thể vận hành.
- **Rủi ro & Cách xác minh dữ liệu**: Rủi ro duy nhất là mất dữ liệu khi mất đĩa node (không sao lưu); xác minh bằng kiểm tra dữ liệu mẫu còn sau khi xóa pod.

## Chiến lược kiểm thử

- **Unit test**: Không áp dụng — không có mã ứng dụng; script bootstrap kiểm tra bằng `shellcheck` khi có.
- **Integration / Contract test**: Kiểm chứng hợp đồng kết nối trên cụm: từng role kết nối đúng database; xem quickstart.
- **Permission / Security test**: Role A vào database B bị từ chối; mật khẩu mặc định cũ bị từ chối; pod không nhãn bị NetworkPolicy chặn; cổng 5432 không mở từ máy ngoài.
- **E2E / Manual / Quickstart validation**: Thực hiện theo [quickstart.md](./quickstart.md) sau khi người dùng cho phép thao tác trên cụm.
- **Regression test**: Các workload hiện có (nginx, flex-api-gateway, Argo CD) vẫn chạy bình thường sau khi thêm PostgreSQL; theo dõi mức dùng RAM.

## Tác động tài liệu nghiệp vụ

- **Kết quả Documentation Impact Gate (`spec.md` §20)**: KHÔNG CẦN CẬP NHẬT
- **Tài liệu hiện hữu đã cập nhật**: Không áp dụng
- **Cập nhật còn lại sau implementation**: Tài liệu kỹ thuật (không phải nghiệp vụ): `docs/architecture/system-map.md` mục 5 (thêm instance PostgreSQL trên K8s), `flex-k8s/README.md`, `flex-environment/SETUP_SERVER.md`.

## Cấu trúc project

### Artifacts của feature
`specs/000044-postgres-database-deployment/`: `spec.md`, `plan.md`, `repos.md`, `research.md`, `data-model.md`, `contracts/connection-contract.md`, `quickstart.md`, `tasks.md` *(sinh bởi `/speckit-tasks`)*.

### Source code

```text
flex-k8s/
├── manifests/postgres/
│   ├── pvc.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── networkpolicy.yaml
├── scripts/postgres-bootstrap.sh
└── README.md                       # thêm mục PostgreSQL
flex-environment/
├── mounts/openbao/secrets.list     # thêm dòng secret postgres
└── SETUP_SERVER.md                 # ghi chú PostgreSQL chạy trong k3s
flex-workstation/
└── docs/architecture/system-map.md # thêm instance PostgreSQL trên K8s
```

**Quyết định cấu trúc**: Theo quy ước `flex-k8s`: một thư mục `manifests/postgres/`, mỗi kind một file, tên thư mục = tên Deployment để `restart.sh postgres` hoạt động; không cần `configmap.yaml` vì tham số chạy truyền bằng `args`. Script vận hành đặt ở `scripts/` cùng `cluster-info.sh`; file `.sh` mới phải `git add --chmod=+x`.

## Rollout & Rollback

- **Kế hoạch rollout & Feature flag/config**: Thứ tự: secret OpenBao, Secret K8s, `restart.sh postgres`, script bootstrap, quickstart. Không feature flag. Không bật tự sync Argo CD.
- **Rollback code/config**: `kubectl rollout undo deployment/postgres`; hoặc revert commit manifest rồi apply lại.
- **Rollback dữ liệu/migration & Điều kiện kích hoạt**: Không có migration. Không bao giờ xóa PVC khi chưa xác nhận; nếu PostgreSQL không lên sau 5 phút hoặc OOMKilled liên tục thì rollback về cấu hình trước và nâng limit sau khi đo.

## Observability & Debug

- **Log / Metric / Trace cần có**: Log container `kubectl logs deployment/postgres`; trạng thái Pod/Probe qua `kubectl describe`; mức dùng RAM qua `kubectl top pod`.
- **Dữ liệu KHÔNG ĐƯỢC log**: Mật khẩu, nội dung Secret, chuỗi kết nối đầy đủ; script không in giá trị Secret và không đặt mật khẩu trong tham số lệnh.
- **Cách kiểm tra sau release**: `kubectl rollout status deployment/postgres`; `pg_isready` trong pod; `psql` bằng từng role theo quickstart.

## Theo dõi độ phức tạp

> Chỉ điền khi có ngoại lệ vi phạm Constitution cần biện minh; mặc định ghi `Không có vi phạm.`

Không có vi phạm.

| ID / Nguyên tắc | Vì sao cần | Phương án đơn giản hơn bị loại vì | Người phê duyệt & Hạn xử lý |
|-----------------|------------|-----------------------------------|-----------------------------|
| Không áp dụng | — | — | — |

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật và `repos.md` (nếu chạm repo con) đã rõ, khớp MVP của `spec.md`.
- [x] Mọi câu hỏi kỹ thuật chặn thiết kế/task đã được chốt (trong `research.md` hoặc bảng quyết định ở trên).
- [x] Mỗi `US`/`FR`/`BR`/`SEC`/`NFR` quan trọng đã map sang module/path, contract, data và kiểm thử.
- [x] Database đích và repo chứa migration đã đối chiếu `docs/architecture/system-map.md` (hoặc ghi `Không áp dụng`).
- [x] Chiến lược kiểm thử, rollout/rollback và observability (kèm danh mục cấm log secret) đã rõ.
- [x] Khối cấu trúc source code đã thay hoàn toàn bằng path thật (không còn mẫu cần xóa).
- [x] Bảng Kiểm tra constitution không còn blocker chưa được phê duyệt.
