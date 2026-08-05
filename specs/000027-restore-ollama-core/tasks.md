# Tasks: Khôi phục hạ tầng lõi AI (Ollama)

**Đầu vào**: Design documents từ [/specs/000027-restore-ollama-core/](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/)

**Điều kiện tiên quyết**: [plan.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/plan.md), [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/spec.md), [research.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/research.md), [data-model.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/data-model.md), [contracts/ollama-api-contract.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/contracts/ollama-api-contract.md), [quickstart.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/quickstart.md)

**Tests**: Kiểm thử được thực hiện thông qua kịch bản command validation & manual integration test theo [quickstart.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/quickstart.md) (Do đây là tính năng khôi phục cấu hình hạ tầng container, không có mã nguồn unit test).

**Tổ chức**: Task được nhóm theo user story để mỗi story có thể được implement và kiểm tra độc lập.

---

## Format: `[ID] [P?] [Story?] Description with path`

- **[ID]**: ID duy nhất từ `T001` tới `T009`.
- **[P]**: Parallelizable (có thể làm song song nếu khác file/không phụ thuộc).
- **[Story]**: `[US1]`, `[US2]` tương ứng các User Story trong [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/spec.md).
- **Description**: Mô tả rõ hành động và file path cụ thể.

---

## Phase 1: Setup (Shared Infrastructure)

**Mục đích**: Kiểm tra và chuẩn bị file cấu hình hạ tầng chung.

- [x] T001 Rà soát cấu hình tổng thể stack hạ tầng trong `flex-environment/docker-compose.infra.yml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Tạo volume lưu trữ persistent mô hình AI trước khi kích hoạt các container.

- [x] T002 [P] Khôi phục khai báo Docker volume persistent `ollama_data:` dưới mục `volumes:` trong `flex-environment/docker-compose.infra.yml`

**Checkpoint**: Hạ tầng lưu trữ volume đã sẵn sàng.

---

## Phase 3: User Story 1 - Khởi động môi trường dev có sẵn dịch vụ AI cục bộ (Priority: P1) MVP

**Goal**: Dịch vụ `ollama` và `ollama-init` tự động nạp mô hình `qwen2.5:1.5b` khi khởi động `flex-environment`, dữ liệu model được lưu persistent tại Docker volume `ollama_data`.

**Independent Test**:
1. Khởi động stack hạ tầng: `cd flex-environment && docker compose up -d`
2. Kiểm tra log tự động nạp model: `docker compose logs -f ollama-init` (kỳ vọng exit code 0)
3. Xác minh API danh sách model: `curl http://localhost:11434/api/tags` (kỳ vọng JSON chứa `"qwen2.5:1.5b"`)
4. Kiểm tra restart giữ nguyên model (không pull lại): `docker compose restart ollama` và gọi lại `curl http://localhost:11434/api/tags`

### Implementation for User Story 1

- [x] T003 [US1] Khôi phục block cấu hình service `ollama` (image `ollama/ollama:0.6.2`, port `11434:11434`, healthcheck `CMD ollama list`, volume mount `ollama_data:/root/.ollama`, command `serve`) trong `flex-environment/docker-compose.infra.yml`
- [x] T004 [US1] Khôi phục block cấu hình service `ollama-init` (chỉ pull model `qwen2.5:1.5b`, `depends_on: ollama: condition: service_healthy`) trong `flex-environment/docker-compose.infra.yml` (phụ thuộc T002, T003)
- [x] T005 [US1] Thực thi command validation cho Kịch bản 1 & 3 theo hướng dẫn [quickstart.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/quickstart.md) (phụ thuộc T004)

**Definition of Done**:
- Container `ollama` & `ollama-init` khởi động thành công.
- Model `qwen2.5:1.5b` khả dụng trong Ollama runtime mà không cần thao tác thủ công.
- Model không bị tải lại khi restart container.

**Checkpoint**: User Story 1 (MVP) hoàn tất và có thể test độc lập.

---

## Phase 4: User Story 2 - Dịch vụ nội bộ khác gọi tới AI cục bộ qua cấu hình sẵn có (Priority: P1)

**Goal**: Khôi phục HAProxy reverse proxy routing cho domain `ollama.local` và endpoint `/api/chat` để các dịch vụ nội bộ (như `flex-ai-gateway`) gửi câu hỏi suy luận thành công.

**Independent Test**:
1. Gửi request suy luận Chat Completion tới API Ollama:
   `curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{"model": "qwen2.5:1.5b", "messages": [{"role": "user", "content": "Hello"}], "stream": false}'`
2. Phản hồi HTTP `200 OK` chứa câu trả lời từ model `qwen2.5:1.5b` với `"done": true`.

### Implementation for User Story 2

- [x] T006 [US2] Khôi phục khai báo ACL `host_ollama hdr(host) -i ollama.local` và rule `use_backend ollama_backend if host_ollama` trong `flex-environment/mounts/haproxy/haproxy.cfg`
- [x] T007 [US2] Khôi phục block `backend ollama_backend` chỉ tới `server ollama ollama:11434 check` trong `flex-environment/mounts/haproxy/haproxy.cfg` (phụ thuộc T006)
- [x] T008 [US2] Thực thi command validation cho Kịch bản 2 theo [quickstart.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/quickstart.md) đối chiếu hợp đồng API [contracts/ollama-api-contract.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/contracts/ollama-api-contract.md) (phụ thuộc T007)

**Definition of Done**:
- Đường định tuyến HAProxy `ollama.local` hoạt động.
- Yêu cầu suy luận chat `POST /api/chat` trả kết quả hợp lệ.

**Checkpoint**: User Story 1 và User Story 2 đều hoàn tất và hoạt động độc lập.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Mục đích**: Kiểm tra tổng thể tính ổn định của stack hạ tầng sau khi khôi phục.

- [x] T009 [P] Chạy smoke test toàn bộ stack `docker compose up -d` trong `flex-environment` và xác minh không làm gián đoạn các dịch vụ khác (PostgreSQL, HAProxy, RabbitMQ...)

---

## Validation Commands

- Khởi động stack hạ tầng: `cd flex-environment && docker compose up -d`
- Kiểm tra log tự động nạp model: `docker compose logs -f ollama-init`
- Verify danh sách model: `curl http://localhost:11434/api/tags`
- Verify inference chat: `curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d "{\"model\": \"qwen2.5:1.5b\", \"messages\": [{\"role\": \"user\", \"content\": \"Hello\"}], \"stream\": false}"`

---

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US-001 | T002, T003, T004, T005 |
| US-002 | T006, T007, T008 |
| FR-001 | T003 |
| FR-002 | T004 |
| FR-003 | T006, T007 |
| FR-004 | T002, T005 |
| FR-005 | T003, T005 |
| AC-001 | T004, T005 |
| AC-002 | T002, T005 |
| AC-003 | T006, T007, T008 |
| BR-001 | T004 |
| BR-002 | T004 |
| SEC-001 | T003, T006 |
| NFR-001 | T003, T005 |
| NFR-002 | T009 |
| NFR-003 | T001, T009 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không có dependency.
- **Foundational (Phase 2)**: Phụ thuộc Setup (T001).
- **User Story 1 (Phase 3)**: Phụ thuộc Foundational (T002).
- **User Story 2 (Phase 4)**: Phụ thuộc Foundational (T002). Có thể chạy song song với US1 do sửa file khác (`haproxy.cfg` vs `docker-compose.infra.yml`).
- **Polish (Final Phase)**: Phụ thuộc Phase 3 và Phase 4.

### Parallel Opportunities

- T002 (`docker-compose.infra.yml` volume) có thể tạo song song trong Phase 2.
- User Story 1 (sửa `docker-compose.infra.yml`) và User Story 2 (sửa `haproxy.cfg`) chạm vào 2 file hoàn toàn khác nhau, có thể thực hiện song song sau Phase 2.
- T009 (`Polish`) chạy sau khi cả 2 User Stories đã complete.

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Phase 1 & Phase 2.
2. Complete Phase 3 (US1 - `ollama` + `ollama-init` + `qwen2.5:1.5b`).
3. **STOP and VALIDATE**: Kiểm tra `curl http://localhost:11434/api/tags`.
4. Sẵn sàng sử dụng làm MVP AI local runtime.

### Incremental Delivery

1. MVP (US1): Hạ tầng Ollama tự nạp model sẵn sàng.
2. Step 2 (US2): Khôi phục HAProxy reverse proxy `ollama.local` cho `flex-ai-gateway`.
3. Step 3 (Polish): Verify toàn bộ stack.
