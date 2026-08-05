# Kế hoạch triển khai: Khôi phục hạ tầng lõi AI (Ollama)

**Branch**: `000027-restore-ollama-core` | **Ngày**: 2026-08-05 | **Đặc tả**: [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/spec.md)

**Đầu vào**: Đặc tả tính năng từ [/specs/000027-restore-ollama-core/spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/spec.md)

---

## Tóm tắt

**Yêu cầu chính từ spec**:
Khôi phục dịch vụ chạy mô hình AI cục bộ (Ollama) trong môi trường phát triển `flex-environment`, tự động nạp mô hình `qwen2.5:1.5b` khi khởi động lần đầu, và khôi phục định tuyến HAProxy để các dịch vụ như `flex-ai-gateway` kết nối thành công qua cấu hình sẵn có mà không cần can thiệp thủ công.

**Hướng tiếp cận kỹ thuật**:
Bật lại các block cấu hình dịch vụ `ollama`, `ollama-init` và volume `ollama_data` đã bị comment trước đó trong `flex-environment/docker-compose.infra.yml`. Đồng thời kích hoạt lại các luật ACL và backend định tuyến trong `flex-environment/mounts/haproxy/haproxy.cfg`.

**Kết quả sau research**:
Đã hoàn thành rà soát và ghi nhận tại [research.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/research.md). Đã làm rõ phạm vi mô hình (chỉ nạp `qwen2.5:1.5b`), cách thức khởi tạo và cơ chế persistence qua Docker volume.

---

## Phạm vi kỹ thuật

**Trong phạm vi**:
- File cấu hình Docker Compose: `flex-environment/docker-compose.infra.yml` (bật dịch vụ `ollama`, `ollama-init`, volume `ollama_data`).
- File cấu hình Reverse Proxy: `flex-environment/mounts/haproxy/haproxy.cfg` (bật ACL `host_ollama` và `ollama_backend`).
- Kịch bản kiểm thử & xác minh: `specs/000027-restore-ollama-core/quickstart.md`.

**Ngoài phạm vi kỹ thuật**:
- Không bật lại dịch vụ Vector Database (Qdrant) hoặc các embedding model.
- Không chỉnh sửa nguồn hoặc cấu hình của `flex-ai-gateway` hay bất kỳ dịch vụ tiêu thụ AI nào khác.
- Không tạo/thay đổi bảng dữ liệu hay migration script nào.

---

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: Docker Compose v2, HAProxy 2.x, Ollama 0.6.2, Model `qwen2.5:1.5b`.

**Service/App liên quan**: `flex-environment` (stack hạ tầng dev), `flex-ai-gateway` (dịch vụ tiêu thụ AI).

**Convention skill áp dụng**: Không áp dụng (chỉ sửa file cấu hình hạ tầng trong `flex-environment`).

**Phụ thuộc chính**: Docker Engine / Docker Desktop, Image `ollama/ollama:0.6.2`.

**Lưu trữ**: Docker Volume `ollama_data` (mount tại `/root/.ollama`).

**Kiểm thử**: Manual integration verification (`curl`, `docker compose logs`, Docker healthcheck).

**Nền tảng chạy**: Linux container (chạy qua Docker Compose trên máy phát triển).

**Đơn vị deploy**: Môi trường hạ tầng phát triển `flex-environment`.

**Loại project**: Local Infrastructure Stack.

**Mục tiêu hiệu năng**: Dịch vụ sẵn sàng phục vụ yêu cầu suy luận ngay sau khi `ollama-init` tải xong mô hình. Phản hồi các yêu cầu prompt trong thời gian ngắn phù hợp môi trường CPU dev.

**Ràng buộc**: Mô hình PHẢI là `qwen2.5:1.5b`. Chạy ổn định trên CPU máy dev không yêu cầu GPU rời.

**Quy mô/Phạm vi**: Môi trường phát triển local/dev của đội ngũ kỹ thuật.

---

## Kiểm tra constitution

*GATE: Phải đạt trước Phase 0 research. Kiểm tra lại sau Phase 1 design.*

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Scope Gate | Pass | Pass | Đúng phạm vi hạ tầng lõi MVP, không phình phạm vi sang RAG/Qdrant. |
| Traceability Gate | Pass | Pass | 100% yêu cầu FR-001..FR-005 & US-001..US-002 được map sang thay đổi file config cụ thể. |
| Test Gate | Pass | Pass | Đã xây dựng [quickstart.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/quickstart.md) với 3 kịch bản xác minh đầy đủ. |
| Security Gate | Pass | Pass | Dịch vụ chỉ mở trong mạng nội bộ Docker container (`flex_net`) và HAProxy dev host (`ollama.local`), tuân thủ SEC-001. |
| Compatibility Gate | Pass | Pass | Giữ nguyên API contract chuẩn của Ollama v0.6.2, sẵn sàng cho `flex-ai-gateway`. |
| Observability Gate | Pass | Pass | Quan sát qua `docker compose logs` và `healthcheck` của Docker container. |
| Complexity Gate | Pass | Pass | Tận dụng 100% pattern hạ tầng cũ đã lưu sẵn trong repo, không viết thêm code hay script phức tạp. |
| Database / Migration (Constitution VI) | Không áp dụng | Không áp dụng | Tính năng hạ tầng thuần túy, không chạm vào database hay schema. |

---

## Câu hỏi kỹ thuật cần research

- **TQ-001**: [ĐÃ GIẢI QUYẾT trong research.md] Scope mô hình nạp tự động? -> Chỉ pull `qwen2.5:1.5b`, không pull embedding model.
- **TQ-002**: [ĐÃ GIẢI QUYẾT trong research.md] Cơ chế persistence? -> Dùng Docker Volume `ollama_data:/root/.ollama`.
- **TQ-003**: [ĐÃ GIẢI QUYẾT trong research.md] Định tuyến HAProxy? -> Bật lại ACL `host_ollama` và `ollama_backend` trong `haproxy.cfg`.

---

## Thiết kế tổng quan

**Luồng chính**:
1. Developer chạy `docker compose up -d` trong `flex-environment`.
2. Container `ollama` khởi động với lệnh `serve`, mount volume `ollama_data` và chạy healthcheck `ollama list`.
3. Khi container `ollama` báo trạng thái `healthy`, container `ollama-init` khởi chạy (`depends_on: ollama: condition: service_healthy`), thực hiện `ollama pull qwen2.5:1.5b`.
4. Sau khi pull xong, `ollama-init` kiểm tra sự tồn tại của model (`ollama list | grep -q "qwen2.5:1.5b"`) rồi thoát với exit code 0.
5. Các dịch vụ như `flex-ai-gateway` gửi yêu cầu API suy luận tới `http://ollama:11434` hoặc qua HAProxy `http://ollama.local`.

**Component/module tham gia**:
- `ollama` (Docker Service): Runtime phục vụ inference AI.
- `ollama-init` (Docker Service): One-shot job tự động tải weights mô hình `qwen2.5:1.5b`.
- `ollama_data` (Docker Volume): Nơi lưu trữ persistent cho mô hình AI.
- `haproxy` (Reverse Proxy): Định tuyến tên miền `ollama.local` tới `ollama:11434`.

**Điểm mở rộng/thay đổi chính**:
- Bật lại block `ollama` và `ollama-init` trong `flex-environment/docker-compose.infra.yml`.
- Bật lại block `ollama` trong `flex-environment/mounts/haproxy/haproxy.cfg`.

**Luồng thay thế/lỗi chính**:
- Nếu `ollama-init` thất bại do mất mạng trong lần chạy đầu: container dừng ở trạng thái error, developer có thể chạy lại bằng `docker compose restart ollama-init`.

**Idempotency/Concurrency**:
- Lệnh `ollama pull qwen2.5:1.5b` trong Ollama có tính năng idempotency: nếu model đã tồn tại đầy đủ trong `ollama_data`, Ollama chỉ kiểm tra manifest và hoàn thành ngay lập tức mà không tải lại dữ liệu.

---

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Bật lại service `ollama` trong Compose | [docker-compose.infra.yml](file:///C:/Workspace/Project/flex-workstation/flex-environment/docker-compose.infra.yml) | `GET /api/tags` | Docker volume `ollama_data` | Quickstart Kịch bản 1 |
| US-001 / FR-002 | P1 | Đủ rõ | Bật service `ollama-init` để pull `qwen2.5:1.5b` | [docker-compose.infra.yml](file:///C:/Workspace/Project/flex-workstation/flex-environment/docker-compose.infra.yml) | N/A (Internal CLI) | Docker volume `ollama_data` | Quickstart Kịch bản 1 |
| US-002 / FR-003 | P1 | Đủ rõ | Bật lại ACL & Backend trong HAProxy | [haproxy.cfg](file:///C:/Workspace/Project/flex-workstation/flex-environment/mounts/haproxy/haproxy.cfg) | `POST /api/chat` | N/A | Quickstart Kịch bản 2 |
| US-001 / FR-004 | P2 | Đủ rõ | Mount volume `ollama_data:/root/.ollama` | [docker-compose.infra.yml](file:///C:/Workspace/Project/flex-workstation/flex-environment/docker-compose.infra.yml) | N/A | Docker volume `ollama_data` | Quickstart Kịch bản 3 |
| US-001 / FR-005 | P3 | Đủ rõ | Dùng Docker healthcheck & API `/api/tags` | [docker-compose.infra.yml](file:///C:/Workspace/Project/flex-workstation/flex-environment/docker-compose.infra.yml) | `GET /api/tags` | N/A | Quickstart Kịch bản 1 |

---

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không áp dụng | Không áp dụng | N/A |
| API/Contract | Giữ nguyên API tiêu chuẩn của Ollama | Tương thích 100% với `flex-ai-gateway` | Quickstart Kịch bản 2 |
| Permission/Security | Chỉ cho phép truy cập từ Docker net & HAProxy dev | Không lộ dịch vụ ra ngoài Internet | Kiểm tra port binding 11434 |
| Logging/Audit | Log container `ollama` và `ollama-init` | Không có | `docker compose logs -f ollama` |
| UI/UX | Không áp dụng | Không áp dụng | N/A |
| Job/Worker/Integration | `ollama-init` chạy một lần khi start stack | Không ảnh hưởng các container khác | `docker compose ps` |

---

## API/Contract Detail

**Có thay đổi contract không**: Không (Sử dụng chuẩn REST API công khai của Ollama). Chi tiết xem tại [contracts/ollama-api-contract.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/contracts/ollama-api-contract.md).

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `/api/chat`, `/api/tags` | REST API | Khôi phục endpoint | Có | `flex-ai-gateway` |

---

## Permission Matrix

**Không áp dụng** (Dịch vụ hạ tầng nội bộ trong môi trường dev).

---

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng.

**Database đích**: Không áp dụng.

**Repo chứa migration**: Không áp dụng.

---

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Bật lại `ollama` & `ollama-init` service cũ | Khớp 100% pattern hạ tầng `flex-environment` | Build custom image đóng gói sẵn model weights | Image dung lượng quá lớn, khó update model |
| DEC-002 | Chỉ nạp model `qwen2.5:1.5b` trong `ollama-init` | Đúng phạm vi MVP-004 & BR-002 | Pull cả embedding model `mxbai-embed-large:v1` | Nằm ngoài phạm vi MVP-004, kéo dài thời gian init |
| DEC-003 | Kích hoạt HAProxy routing (`ollama.local`) | Phù hợp chuẩn đặt tên domain dev hệ thống | Chỉ dùng port 11434 direct binding | Thiếu thống nhất với reverse proxy chung |

---

## Chiến lược kiểm thử

**Unit test**: Không áp dụng (thay đổi cấu hình infrastructure).

**Integration test**: Kiểm tra `ollama-init` nạp model thành công và trả lời qua `curl /api/chat`.

**Contract test**: Kiểm tra schema JSON trả về từ `/api/tags` và `/api/chat` khớp với [contracts/ollama-api-contract.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/contracts/ollama-api-contract.md).

**Permission/security test**: Không áp dụng.

**E2E/manual test**: Thực hiện 3 kịch bản theo [quickstart.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/quickstart.md).

**Regression test**: Đảm bảo các service khác trong `docker-compose.infra.yml` (PostgreSQL, HAProxy, RabbitMQ...) khởi động bình thường không bị lỗi syntax yaml/cfg.

---

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000027-restore-ollama-core/
├── spec.md              # Đặc tả tính năng
├── plan.md              # File này (kế hoạch triển khai)
├── research.md          # Phân tích & quyết định kỹ thuật
├── data-model.md        # Mô hình lưu trữ Docker Volume
├── quickstart.md        # Hướng dẫn kiểm thử & xác minh
└── contracts/
    └── ollama-api-contract.md # Hợp đồng API Ollama
```

### Source code (repository root)

```text
flex-environment/
├── docker-compose.infra.yml             # [MODIFY] Bật service ollama, ollama-init, volume ollama_data
└── mounts/
    └── haproxy/
        └── haproxy.cfg                  # [MODIFY] Bật ACL host_ollama & backend ollama_backend
```

---

## Rollout & Rollback

**Kế hoạch rollout**:
1. Checkout branch `000027-restore-ollama-core` tại repo `flex-environment`.
2. Thực thi `docker compose up -d` để khởi động lại các container.

**Tương thích ngược**: Tương thích hoàn toàn với cấu hình biến môi trường sẵn có của `flex-ai-gateway`.

**Feature flag/config**: Không áp dụng.

**Thực thi migration/backfill khi rollout**: Không áp dụng.

**Rollback code/config**:
- Chạy `git checkout main` tại repo `flex-environment` và `docker compose up -d`.

**Rollback dữ liệu/migration**: Không áp dụng.

**Điều kiện kích hoạt rollback**: Syntax error trong `docker-compose.infra.yml` hoặc `haproxy.cfg` làm gián đoạn hạ tầng hiện có.

---

## Observability & Debug

**Log cần có**:
- Log container init: `docker compose logs -f ollama-init`
- Log container runtime: `docker compose logs -f ollama`

**Dữ liệu không được log**: Không áp dụng (không xử lý dữ liệu nhạy cảm).

**Metric cần theo dõi**: Trạng thái container (`docker compose ps`).

**Trace/Correlation**: Không áp dụng.

**Cách kiểm tra sau release**:
- Chạy `curl http://localhost:11434/api/tags` xác nhận `"qwen2.5:1.5b"` tồn tại.

---

## Theo dõi độ phức tạp

*Không áp dụng (Không có vi phạm constitution nào cần biện minh).*

---

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research hoặc ghi rủi ro rõ ràng.
- [x] Thiết kế tổng quan đã mô tả luồng chính, component/module tham gia, điểm thay đổi và boundary nếu có.
- [x] Các tình huống idempotency/concurrency/retry đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Mỗi `US`/`FR` P1/P2 hoặc FR ảnh hưởng code/data/API/permission có mapping sang module/path, API/contract, data/entity và kiểm thử.
- [x] Tác động tới database, API contract, permission, logging/audit và integration đã được đánh giá hoặc ghi `Không áp dụng`.
- [x] Các contract/API/event thay đổi đã có consumer bị ảnh hưởng và cách kiểm tra compatibility.
- [x] Dữ liệu/migration/backfill/compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Database đích và repo chứa migration đã được xác định, đối chiếu `docs/architecture/system-map.md`, hoặc ghi `Không áp dụng` (Constitution VI).
- [x] Quyết định kỹ thuật chính đã có lý do chọn và phương án bị loại.
- [x] Chiến lược kiểm thử đã bao phủ unit, integration, contract, permission/security, E2E/manual và regression khi liên quan.
- [x] Rollout, rollback code/config, rollback dữ liệu/migration, feature flag/config và backward compatibility đã rõ hoặc ghi `Không áp dụng`.
- [x] Observability/debug plan có log field, dữ liệu không được log, metric/trace và cách kiểm tra sau release.
- [x] Không còn cây thư mục mẫu/generic; toàn bộ path trong cấu trúc source code là path thật trong repository.
- [x] Constitution gate không còn blocker trước khi chuyển sang `/speckit-tasks`.
