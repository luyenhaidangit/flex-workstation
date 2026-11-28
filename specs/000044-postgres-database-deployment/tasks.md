---
description: "Danh sách task triển khai PostgreSQL trên K8s"
---

# Tasks: Triển khai database PostgreSQL

**Đầu vào**: Artifacts thiết kế từ `/specs/000044-postgres-database-deployment/` (`spec.md`, `plan.md`, `data-model.md`, `contracts/connection-contract.md`, `research.md`, `quickstart.md`, `repos.md`)  
**Chế độ Spec**: Full  
**Test Gate**: v1 không có mã ứng dụng nên không có unit test; mọi rủi ro trong `plan.md` được phủ bằng task kiểm tra tĩnh (dry-run, `bash -n`, quét secret) hoặc task command validation trên cụm (theo `quickstart.md`), kèm lý do không áp dụng automated test.

## Format: `- [ ] T### [P?] [US#?] Mô tả hành động cụ thể kèm file path hoặc command`

- **`T###`**: Mã tăng tuần tự.
- **`[P]`**: Chạy song song được (khác file, không phụ thuộc task chưa xong trong cùng phase; không liên quan priority `P1`/`P2`).
- **`[US#]`**: Bắt buộc cho phase User Story. `US1` = US-001 (dựng một PostgreSQL, nhiều database riêng), `US2` = US-002 (mật khẩu và truy cập mạng), `US3` = US-003 (kiểm tra sức khỏe).

**Phạm vi**: Sửa `flex-k8s` và `flex-environment` (mỗi repo một branch riêng, xem T001) và `docs/architecture/system-map.md` của workstation. Không áp schema, dữ liệu, sao lưu hay đổi connection string của service.

**Quy tắc an toàn xuyên suốt**: Task nào ghi `(cần cho phép)` thay đổi cụm hoặc server thật: chỉ chạy khi người dùng cho phép và đã xác định đúng cụm của server mới, không bao giờ nhắm vào server production cũ `213.35.100.75`. Không xóa PVC `postgres-data` hay dữ liệu khi chưa xác nhận. Không in, ghi log hay đặt mật khẩu trong tham số lệnh. Cách truy cập cụm được chốt ở T002 và áp dụng cho mọi lệnh `kubectl` bên dưới.

---

## Phase 1: Setup (Shared Infrastructure)

**Mục đích**: Chốt branch cho repo con và xác minh hai điểm chưa kiểm chứng của plan (cụm thật, tag image).

- [x] T001 Hỏi người dùng tên branch riêng cho `flex-k8s` và cho `flex-environment` trước khi sửa (`flex-k8s/AGENTS.md`, `flex-repo-scope`: branch của workstation không áp dụng cho repo con). Kiểm tra được: tên hai branch được ghi lại trong phiên làm việc trước khi chạy T004 và T007. **Kết quả:** người dùng chọn sửa thẳng `main` của `flex-k8s` và `flex-environment`, không tạo branch (2026-11-28).
- [ ] T002 (cần cho phép) Trước lệnh đầu tiên, hỏi người dùng cách truy cập cụm của server mới (kubeconfig trỏ từ máy dev qua SSH tunnel, hoặc SSH vào server rồi chạy `kubectl` tại đó; địa chỉ và cổng lấy từ `~/.ssh/config` của WSL, không ghi vào repo) và ghi lại lựa chọn; mọi lệnh `kubectl` ở các task sau dùng đúng cách này. Rồi xác minh cụm trên server mới bằng lệnh chỉ đọc: `kubectl get nodes`, `kubectl get storageclass`, `kubectl get pods -A`, `kubectl get networkpolicy -A`, và `free -m` trên server. Ghi kết quả (k3s có chạy không, StorageClass mặc định có phải `local-path`, mức RAM còn trống) vào `specs/000044-postgres-database-deployment/research.md` mục `TQ-002`. Kiểm tra được: `TQ-002` có kết luận bằng số liệu; nếu cụm chưa chạy thì dừng và báo người dùng, không sang T007.
- [x] T003 Xác minh tag phiên bản cụ thể của `postgres` bản 16 alpine có manifest `linux/amd64` (`docker manifest inspect postgres:<tag>`), rồi ghi tag chốt vào `specs/000044-postgres-database-deployment/research.md` mục `R-002` và `TQ-001` (phụ thuộc T002 vì cùng sửa `research.md`). Kiểm tra được: lệnh `manifest inspect` thành công với tag đã chốt.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Mật khẩu phải có sẵn trong cụm trước khi bất kỳ user story nào chạy (Deployment đọc `POSTGRES_PASSWORD` từ Secret; script bootstrap đọc cả bốn key). Dùng chung cho US1 và US2.

- [x] T004 Thêm vào `flex-environment/mounts/openbao/secrets.list` bốn dòng cho secret `postgres` theo quy ước snake_case của file: `postgres admin_password`, `postgres hnx_db_password`, `postgres aspnetidentity_db_password`, `postgres agentdb_password` (phụ thuộc T001). Kiểm tra được: `git diff` chỉ thêm đúng bốn dòng, tên khóa không trùng khóa của secret khác theo quy tắc trong chính file đó, không có giá trị mật khẩu.
- [ ] T005 (cần cho phép) Người dùng merge branch `flex-environment` (T001) vào `main` (job `infra/openbao-sync` tự checkout `main`, không cần `git pull` trên server), chạy job Jenkins `infra/openbao-sync` (Build with Parameters, nhập token OpenBao) rồi điền giá trị thật cho bốn khóa ở UI OpenBao (phụ thuộc T004). Kiểm tra được: `git log main -1 -- mounts/openbao/secrets.list` có commit của T004; người dùng xác nhận secret `postgres` có đủ bốn khóa và không còn `CHANGE_ME`; mình không đọc giá trị.
- [ ] T006 (cần cho phép) Tạo Secret `postgres-secret` trên cụm bằng `bash set-secret.sh postgres-secret POSTGRES_PASSWORD HNX_DB_PASSWORD AUTH_DB_PASSWORD AGENT_DB_PASSWORD` trong `flex-k8s` (giá trị do người dùng nhập qua prompt, ánh xạ từ bốn khóa ở T004: `admin_password`→`POSTGRES_PASSWORD`, `hnx_db_password`→`HNX_DB_PASSWORD`, `aspnetidentity_db_password`→`AUTH_DB_PASSWORD`, `agentdb_password`→`AGENT_DB_PASSWORD`) (phụ thuộc T005). Kiểm tra được: `kubectl describe secret postgres-secret` liệt kê đủ bốn khóa với kích thước khác 0; không dùng `-o yaml` hay `jsonpath` in giá trị.

**Checkpoint**: Secret sẵn sàng trên cụm — bắt đầu triển khai từng User Story.

---

## Phase 3: User Story 1 - Dựng một PostgreSQL chứa nhiều database riêng (Priority: P1) MVP

**Goal**: Đúng một bản PostgreSQL chạy trên cụm, bền vững, có ba database trống, mỗi database một tài khoản sở hữu riêng và không vào được database khác.  
**Independent Test**: Sau khi `restart.sh postgres` và bootstrap: đếm pod `postgres` bằng 1; từng role vào database của mình qua Service thành công, vào database khác bị từ chối; xóa pod rồi dữ liệu thử vẫn còn; chạy lại bootstrap không lỗi.

### Implementation cho User Story 1

- [x] T007 [P] [US1] Tạo `flex-k8s/manifests/postgres/pvc.yaml`: PVC `postgres-data`, `ReadWriteOnce`, yêu cầu `10Gi`, StorageClass mặc định của k3s (kết quả T002) (phụ thuộc T001), nhãn `app: postgres`, comment tiếng Việt kiểu file `manifests/flex-api-gateway/`.
- [x] T008 [P] [US1] Tạo `flex-k8s/manifests/postgres/service.yaml`: Service `postgres` loại `ClusterIP`, cổng `5432`, selector `app: postgres`, không NodePort (phụ thuộc T001).
- [x] T009 [US1] Tạo `flex-k8s/manifests/postgres/deployment.yaml`: Deployment `postgres` `replicas: 1`, `strategy: Recreate`, `revisionHistoryLimit: 2`; image `postgres` theo tag chốt ở T003 (không `latest`); `args` `-c shared_buffers=128MB` và `-c max_connections=50`; `PGDATA` trỏ thư mục con của điểm mount PVC `postgres-data`; `POSTGRES_PASSWORD` lấy bằng `secretKeyRef` từ `postgres-secret` (không giá trị mặc định); `resources` requests `100m`/`256Mi`, limit memory `1Gi`; `securityContext` `runAsNonRoot`, `runAsUser`/`fsGroup` đúng uid của image, drop `ALL`, `seccompProfile` `RuntimeDefault`; chưa có probe (thêm ở T023) (phụ thuộc T003, T007).
- [x] T010 [P] [US1] Tạo `flex-k8s/scripts/postgres-bootstrap.sh` (bash, `set -euo pipefail`): `kubectl exec` vào pod `postgres` và dùng `psql`, đọc bốn mật khẩu từ Secret `postgres-secret` (tên Secret mặc định `postgres-secret`, cho ghi đè bằng biến `PG_SECRET` để thử ở T020); với mỗi cặp `flex_exchange_hnx`/`hnx`, `aspnetidentity`/`aspnetidentity`, `agentdb`/`agentdb` tạo role `LOGIN` và database với owner là role đó chỉ khi chưa tồn tại (mẫu `\gexec` của `flex-environment/scripts/postgres-bootstrap/020-auth-aspnetidentity.sh`), `ALTER ROLE ... PASSWORD` để đồng bộ mật khẩu, `REVOKE CONNECT ON DATABASE ... FROM PUBLIC` rồi `GRANT CONNECT` chỉ cho role sở hữu; mật khẩu truyền qua stdin/biến `psql`, không đặt trong tham số lệnh, không `echo`; dừng với thông báo rõ nếu pod chưa Ready; mỗi bước (kiểm tra Secret, tạo role, tạo database, thu hồi/cấp `CONNECT`) in một dòng dạng `<thời điểm ISO> <bước> <kết quả>` có tên role/database nhưng không có mật khẩu, làm nhật ký vận hành theo spec §11 (phụ thuộc T001).
- [x] T011 [US1] Chạy `git add --chmod=+x flex-k8s/scripts/postgres-bootstrap.sh` trong `flex-k8s` theo `flex-k8s/AGENTS.md` (phụ thuộc T010). Kiểm tra được: `git ls-files -s scripts/postgres-bootstrap.sh` hiển thị mode `100755`.

### Tests / Validation cho User Story 1

Lý do dùng command validation thay automated test: tài nguyên là manifest và script hạ tầng, không có logic ứng dụng để unit test; kiểm chứng đúng hành vi cần chạy trên cụm thật.

**Pod thử** (dùng ở T014, T016, T021, T022): pod tạm tạo bằng `kubectl run`, gắn nhãn `postgres-access=true`, image `postgres` cùng tag ở T003, kết nối qua TCP tới Service `postgres` (không dùng socket nội bộ của pod vì image mặc định tin cậy kết nối loopback); xóa pod thử sau mỗi lần dùng.

- [x] T012 [US1] Kiểm tra tĩnh, không đụng cụm: từ `flex-k8s` chạy `kubectl apply --dry-run=client -R -f manifests/postgres/`, `grep -rn "latest" manifests/postgres/` (kỳ vọng không có), `bash -n scripts/postgres-bootstrap.sh` và `shellcheck scripts/postgres-bootstrap.sh` nếu có cài (phụ thuộc T008, T009, T010, T011). Nếu `dry-run=client` cần API server mà cụm không với tới được thì ghi rõ giới hạn; không coi là đã triển khai. **Kết quả 2026-11-28:** `bash -n` OK, YAML parse OK, không có `latest`; `kubectl apply --dry-run=client` không chạy được vì không có API server (không có context kubectl), shellcheck chưa cài; chưa xác minh bằng cụm.
- [ ] T013 [US1] (cần cho phép) Triển khai: từ `flex-k8s` chạy `bash restart.sh postgres`, rồi `kubectl rollout status deployment/postgres` và `kubectl get pods -l app=postgres` (phụ thuộc T006, T012). Kiểm tra được: rollout thành công, đúng 1 pod Ready (FR-002, SC-003); nếu rollout lỗi thì in log và rollback bằng `kubectl rollout undo deployment/postgres`, không xóa PVC.
- [ ] T014 [US1] (cần cho phép) Chạy `bash scripts/postgres-bootstrap.sh`, rồi kiểm tra bằng pod thử: `\l` có đủ ba database; từng role (mật khẩu từ Secret, không in) vào database của mình thành công; role `hnx` vào `agentdb` và ngược lại bị từ chối; xóa pod thử sau khi xong (phụ thuộc T013). Kiểm tra được: khớp AC-001, AC-002, AC-003, SC-001.
- [ ] T015 [US1] (cần cho phép) Kiểm tra chạy lại an toàn: chạy `bash scripts/postgres-bootstrap.sh` và `bash restart.sh postgres` lần hai; so sánh danh sách `\l`, `\du` trước và sau (phụ thuộc T014). Kiểm tra được: không lỗi, không role/database trùng, pod không bị tạo lại ngoài ý muốn (FR-010, SC-004).
- [ ] T016 [US1] (cần cho phép) Kiểm tra bền vững: dùng pod thử như T014 tạo một bảng thử trong `agentdb`, chạy `kubectl delete pod -l app=postgres` (chỉ xóa pod, không xóa PVC), chờ Ready, xác nhận bảng thử còn, rồi xóa chính bảng thử đó (phụ thuộc T014). Kiểm tra được: khớp AC-004 và FR-003; PVC `postgres-data` vẫn `Bound`. Vế "server khởi động lại" của AC-004 chỉ được coi là đạt khi T030 chạy xong; nếu chưa được phép khởi động lại server thì báo cáo ghi rõ "AC-004 (vế reboot), NFR-002, SC-005 chưa xác minh".

**Definition of Done (US1)**: T007–T016 hoàn tất, Independent Test pass, không làm gãy nginx, gateway hay Argo CD hiện có; AC-004 (vế reboot) được xác minh ở T030 hoặc ghi rõ là chưa xác minh.

---

## Phase 4: User Story 2 - Bảo vệ thông tin đăng nhập và truy cập mạng (Priority: P1)

**Goal**: Không có mật khẩu mặc định hoạt động, thiếu mật khẩu thì quy trình dừng, và database không truy cập được từ Internet hay từ pod không được phép.  
**Independent Test**: Thử mật khẩu mặc định cũ và kết nối từ máy ngoài, từ pod không nhãn: đều bị từ chối; chạy bootstrap với Secret thiếu một khóa: dừng và nêu đúng khóa thiếu.

### Implementation cho User Story 2

- [x] T017 [P] [US2] Tạo `flex-k8s/manifests/postgres/networkpolicy.yaml`: NetworkPolicy `postgres-allow-clients` cho pod `app: postgres`, `policyTypes: [Ingress]`, chỉ cho phép từ pod có nhãn `postgres-access: "true"` vào TCP `5432` (theo mẫu `manifests/flex-api-gateway/networkpolicy.yaml`, giữ ghi chú kubelet probe và port-forward không bị chặn) (phụ thuộc T001).
- [x] T018 [US2] Sửa `flex-k8s/scripts/postgres-bootstrap.sh`: thêm hàm kiểm tra trước khi chạy `psql` đầu tiên, đọc từng key `POSTGRES_PASSWORD`, `HNX_DB_PASSWORD`, `AUTH_DB_PASSWORD`, `AGENT_DB_PASSWORD` trong Secret `PG_SECRET`; thiếu key hoặc rỗng thì in tên key thiếu, thoát mã khác 0 và chưa tạo hay đổi gì; không có mật khẩu mặc định thay thế, không in giá trị (phụ thuộc T010).

### Tests / Validation cho User Story 2

- [x] T019 [US2] Quét secret trong diff: từ `flex-k8s` và `flex-environment` chạy `git diff` rồi `grep -rEni "password\s*[:=]\s*['\"]?[A-Za-z0-9]" manifests/postgres scripts/postgres-bootstrap.sh` (kỳ vọng chỉ thấy tên key và `secretKeyRef`, không thấy giá trị), kiểm tra không có mật khẩu mặc định nào của cấu hình cũ trong file mới (phụ thuộc T009, T018). Kiểm tra được: không có kết quả khớp giá trị thật (FR-006, BR-003, SEC-001).
- [ ] T020 [US2] (cần cho phép) Kiểm tra thiếu mật khẩu: tạo Secret thử `postgres-secret-test` chỉ có ba trong bốn key bằng `set-secret.sh`, chạy `PG_SECRET=postgres-secret-test bash scripts/postgres-bootstrap.sh`, rồi xóa Secret thử (chỉ Secret do mình tạo) (phụ thuộc T018, T013). Kiểm tra được: script thoát mã khác 0, nêu đúng key thiếu, `\du` không đổi so với trước khi chạy (AC-007).
- [ ] T021 [US2] (cần cho phép) Kiểm tra mật khẩu cũ bị từ chối: từ pod thử gắn nhãn `postgres-access=true` kết nối qua Service bằng một mật khẩu mặc định từng có trong `flex-environment/temp/docker-compose.infra.yml` (đọc từ file đó, không chép vào log hay tài liệu) cho từng role (phụ thuộc T014). Kiểm tra được: cả ba role và `postgres` đều bị từ chối (AC-005, FR-007, BR-003).
- [ ] T022 [US2] (cần cho phép) Kiểm tra cách ly mạng: chạy `bash restart.sh postgres` để áp `networkpolicy.yaml` (phụ thuộc T017, T013); từ pod thử không nhãn kết nối `postgres:5432` (kỳ vọng bị chặn), từ pod có nhãn (kỳ vọng được); người dùng thử kết nối cổng 5432 của IP server từ một máy ngoài mạng (kỳ vọng không mở). Nếu pod không nhãn vẫn kết nối được thì ghi nhận CNI không enforce NetworkPolicy là rủi ro còn lại của plan. Kiểm tra được: khớp AC-006, SC-002, SEC-001, FR-008.

**Definition of Done (US2)**: T017–T022 hoàn tất, Independent Test pass, không còn secret trong diff.

---

## Phase 5: User Story 3 - Biết database còn sống hay không (Priority: P2)

**Goal**: Người vận hành thấy trạng thái khỏe hoặc không khỏe của PostgreSQL.  
**Independent Test**: Dừng tiến trình PostgreSQL có chủ đích và thấy trạng thái chuyển không khỏe trong vòng 1 phút.

### Implementation cho User Story 3

- [x] T023 [US3] Sửa `flex-k8s/manifests/postgres/deployment.yaml`: thêm vào container `postgres` ba probe dùng `exec` `pg_isready -U postgres` — `startupProbe` (cho phép khởi động tối đa khoảng 120 giây), `readinessProbe` (lỗi liên tục khoảng 15 giây thì rút khỏi Service), `livenessProbe` (lỗi liên tục khoảng 30 giây thì khởi động lại container), ngưỡng riêng cho từng probe theo `flex-devops-engineering` (phụ thuộc T009).

### Tests / Validation cho User Story 3

- [ ] T024 [US3] (cần cho phép) Chạy `kubectl apply --dry-run=client -f manifests/postgres/deployment.yaml` rồi `bash restart.sh postgres`; xác nhận pod Ready và `kubectl describe pod -l app=postgres` hiển thị đủ ba probe; sau đó dừng tiến trình có chủ đích bằng `kubectl exec deployment/postgres -- pg_ctl stop -m fast` và theo dõi `kubectl get pods -l app=postgres -w` (phụ thuộc T023, T013). Kiểm tra được: pod chuyển `NotReady` hoặc tăng `RESTARTS` trong vòng 1 phút rồi tự Ready lại; dữ liệu ở `\l` còn nguyên (AC-008, AC-009, FR-009).

**Definition of Done (US3)**: T023–T024 hoàn tất, Independent Test pass.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [x] T025 [P] Thêm vào `flex-k8s/README.md` mục `## PostgreSQL`: thứ tự triển khai (secret OpenBao → `set-secret.sh` → `restart.sh postgres` → `scripts/postgres-bootstrap.sh`), truy cập bằng `kubectl port-forward svc/postgres`, nhãn `postgres-access: "true"` cho pod client, rollback `kubectl rollout undo deployment/postgres`, và cảnh báo không xóa PVC `postgres-data` hay chạy lệnh xóa dữ liệu khi chưa xác nhận (BR-004). Cập nhật câu "chưa triển khai workload dữ liệu" nếu còn trong README.
- [x] T026 [P] Cập nhật `flex-environment/SETUP_SERVER.md` mục `### OpenBao (secret manager)`: thêm bảng ánh xạ bốn khóa snake_case của secret `postgres` sang bốn key của Secret K8s `postgres-secret` (như T006) và ghi chú PostgreSQL của server mới chạy trong k3s, không nằm trong `docker-compose.infra.yml` (vẫn là file chờ migrate); không sửa `temp/` (ngoài phạm vi).
- [x] T027 [P] Cập nhật `docs/architecture/system-map.md` mục `## 5. Data Architecture`: thêm một hàng cho instance PostgreSQL chạy trong k3s của server mới (một bản, ba database trống `flex_exchange_hnx`, `aspnetidentity`, `agentdb`, không sao lưu, schema do feature khác đưa vào), dẫn chứng `specs/000044-postgres-database-deployment`. Kiểm tra được: `git diff` chỉ thêm hàng đó.
- [x] T028 Đối chiếu `specs/000044-postgres-database-deployment/contracts/connection-contract.md` với manifest và script thật: tên Service `postgres`, cổng `5432`, nhãn `postgres-access`, tên ba database và role, tên bốn key Secret (phụ thuộc T009, T010, T017). Kiểm tra được: `grep` từng giá trị khớp; chỗ nào lệch thì sửa hợp đồng hoặc manifest cho nhất quán.
- [ ] T029 (cần cho phép) Kiểm tra tài nguyên và hồi quy: `kubectl top pod -l app=postgres`, `free -m` trên server, và `kubectl get pods -A` xác nhận nginx, flex-api-gateway, Argo CD vẫn `Running` (phụ thuộc T024). Kiểm tra được: PostgreSQL dưới 1 GiB RAM và không workload nào khác bị OOMKilled hay restart do thiếu RAM (NFR-001). Nếu chưa đo được thì ghi rõ chưa xác minh.
- [ ] T030 (cần cho phép, chỉ khi người dùng đồng ý khởi động lại server) Đo thời gian PostgreSQL sẵn sàng sau khi khởi động lại server: ghi thời điểm server lên và thời điểm `pg_isready` thành công, xác nhận dữ liệu thử còn (phụ thuộc T029). Kiểm tra được: dưới 5 phút không cần thao tác tay (NFR-002, SC-005). Nếu không được phép khởi động lại thì ghi rõ chưa xác minh, không suy diễn từ T016.
- [ ] T031 Rà log không lộ mật khẩu: `kubectl logs deployment/postgres` và đầu ra của `scripts/postgres-bootstrap.sh` ở các lần chạy T014, T015, T020 không chứa giá trị mật khẩu (`Observability & Debug` của `plan.md`) và có dòng nhật ký `<thời điểm> <bước> <kết quả>` ở mọi lần chạy (phụ thuộc T014, T015, T020). Kiểm tra được: `grep` các giá trị đã nhập không khớp; số dòng nhật ký khớp số bước đã chạy.

---

## Validation Commands

- **Build**: Không áp dụng — không có mã biên dịch.
- **Tests**: `kubectl apply --dry-run=client -R -f manifests/postgres/`; `bash -n scripts/postgres-bootstrap.sh`; `node scripts/speckit-cli.js validate --feature specs/000044-postgres-database-deployment --stage tasks` (chạy từ root workstation).
- **Quickstart / Smoke check**: Các bước trong `specs/000044-postgres-database-deployment/quickstart.md` (T013–T016, T020–T022, T024, T029).

---

## Traceability Matrix

| Nguồn (`MVP` / `US` / `FR` / `AC` / `BR` / `SEC` / `NFR`) | Covered by Task IDs |
|---|---|
| MVP-001 | T007, T009, T013, T016 |
| MVP-002 | T010, T014 |
| MVP-003 | T004, T005, T006, T018, T019 |
| MVP-004 | T023, T024 |
| MT-001 | T013, T014 |
| MT-002 | T019, T021, T022 |
| MT-003 | T029 |
| US1 / AC-001 | T013, T014 |
| US1 / AC-002 | T014 |
| US1 / AC-003 | T014 |
| US1 / AC-004 | T016 |
| US2 / AC-005 | T021 |
| US2 / AC-006 | T022 |
| US2 / AC-007 | T018, T020 |
| US3 / AC-008 | T023, T024 |
| US3 / AC-009 | T023, T024 |
| FR-001 | T009, T013, T016 |
| FR-002 | T009, T013 |
| FR-003 | T007, T009, T016 |
| FR-004 | T010, T014 |
| FR-005 | T010, T014 |
| FR-006 | T006, T009, T018, T019 |
| FR-007 | T009, T018, T019, T021 |
| FR-008 | T008, T017, T022 |
| FR-009 | T023, T024 |
| FR-010 | T010, T015 |
| BR-001 | T010, T014 |
| BR-002 | T010, T014 |
| BR-003 | T006, T019, T021 |
| BR-004 | T016, T025 |
| SEC-001 | T014, T017, T022 |
| NFR-001 | T009, T029 |
| NFR-002 | T023, T030 |
| SC-001 | T014 |
| SC-002 | T021, T022 |
| SC-003 | T013 |
| SC-004 | T015 |
| SC-005 | T030 |

---

## Dependencies & Parallel Opportunities

- **Thứ tự Phase**: `Setup` (T001 → T002 → T003) → `Foundational` (T004 → T005 → T006) → `US1` (T007–T011, rồi T012 → T013 → T014 → T015/T016) → `US2` (T017, T018, rồi T019–T022) → `US3` (T023 → T024) → `Polish`. US2 và US3 chỉ sửa thêm file của US1 (`postgres-bootstrap.sh`, `deployment.yaml`) nên triển khai sau US1, không song song.
- **Cơ hội chạy song song (`[P]`)**: T007, T008, T010 (khác file, cùng phase US1); T017 và T018 (khác file, T018 chỉ cần T010 đã xong); T025, T026, T027 ở Final Phase (ba repo/file khác nhau). Task `(cần cho phép)` chạy tuần tự vì cùng thao tác trên một cụm.
- **File dùng chung**: `postgres-bootstrap.sh` (T010 → T018) và `deployment.yaml` (T009 → T023) được sửa tuần tự, không đánh `[P]`; `research.md` (T002 → T003) cũng tuần tự.

---

## Checklist chất lượng trước khi implement

- [x] Không còn placeholder (`[FeatureName]`, `[Entity]`, `TXXX`) hay story giả định ngoài `spec.md`.
- [x] Mọi task có ID tuần tự từ `T001`, có file path cụ thể (kèm key/mục khi sửa file cũ) hoặc command cụ thể.
- [x] Không có hai task `[P]` cùng phase sửa chung một file; các phụ thuộc đã ghi rõ `(phụ thuộc T###)`.
- [x] Mỗi User Story có `Independent Test`, `Definition of Done`, và test/validation task phủ rủi ro trong `plan.md`.
- [x] `Traceability Matrix` đã phủ đủ `MVP`/`US`/`FR`/`BR`/`SEC`/`NFR` (kể cả từng vế của FR đa điều kiện).
