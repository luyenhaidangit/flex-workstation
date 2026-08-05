# Nghiên cứu kỹ thuật: Khôi phục hạ tầng lõi AI (Ollama)

**Branch**: `000027-restore-ollama-core` | **Ngày**: 2026-08-05 | **Đặc tả**: [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/spec.md)

---

## 1. Tóm tắt nghiên cứu

Nghiên cứu này rà soát pattern hạ tầng hiện có trong repo `flex-environment` để khôi phục dịch vụ chạy mô hình AI cục bộ (Ollama) cùng luồng tự động nạp mô hình `qwen2.5:1.5b` và định tuyến reverse proxy HAProxy. Tất cả câu hỏi kỹ thuật đã được làm rõ dựa trên khảo sát codebase và đặc tả tính năng.

---

## 2. Quyết định kỹ thuật & Phương án đánh giá

### DEC-001: Khôi phục dịch vụ Ollama & Ollama Init trong `docker-compose.infra.yml`

- **Quyết định**: Bật lại 2 services `ollama` và `ollama-init` cùng volume `ollama_data` trong `flex-environment/docker-compose.infra.yml`.
  - Service `ollama`: Image `ollama/ollama:0.6.2`, port `11434:11434`, healthcheck `CMD ollama list`, mount volume `ollama_data:/root/.ollama`.
  - Service `ollama-init`: Image `ollama/ollama:0.6.2`, `depends_on: ollama (condition: service_healthy)`, thực thi script `ollama pull qwen2.5:1.5b` để tự động nạp mô hình khi khởi động lần đầu.
- **Lý do chọn**: Tận dụng 100% pattern triển khai đã được thiết kế và lưu trữ sẵn trong `docker-compose.infra.yml`, đảm bảo tính đồng bộ với cấu trúc hạ tầng dev hiện tại của `flex-environment`.
- **Phương án đã loại**:
  1. Build Docker image custom đóng gói sẵn model weights vào container: Bỏ vì khiến image size tăng nhiều GB, khó cập nhật phiên bản model độc lập và vi phạm nguyên tắc tách biệt giữa runtime & data volume.
  2. Yêu cầu developer tự chạy lệnh `docker exec -it ollama ollama pull qwen2.5:1.5b` thủ công: Bỏ vì vi phạm yêu cầu tự động hóa (FR-002, US-001, SC-001).

---

### DEC-002: Scope mô hình nạp tự động khi khởi động (`ollama-init`)

- **Quyết định**: Trong script của `ollama-init`, chỉ thực hiện nạp mô hình `qwen2.5:1.5b` (`ollama pull qwen2.5:1.5b`) và kiểm tra sự tồn tại (`ollama list | grep -q "qwen2.5:1.5b"`). Không pull các model embedding như `mxbai-embed-large:v1` hay `nomic-embed-text-v2-moe`.
- **Lý do chọn**: Tuân thủ quy định BR-002, MVP-004 và quyết định trong Clarifications Session 2026-08-05. Phần embedding model và Vector DB (Qdrant) thuộc về phạm vi RAG/Agent platform sẽ được xử lý ở spec khác.
- **Phương án đã loại**:
  1. Giữ nguyên script cũ trong `docker-compose.infra.yml` (pull cả `mxbai-embed-large:v1`): Bỏ vì kéo dài thời gian init không cần thiết và nằm ngoài phạm vi MVP-004 đã chốt với stakeholder.

---

### DEC-003: Khôi phục định tuyến HAProxy (`haproxy.cfg`)

- **Quyết định**: Kích hoạt lại các dòng cấu hình HAProxy đã bị comment trong `flex-environment/mounts/haproxy/haproxy.cfg`:
  - Front-end rule: `acl host_ollama hdr(host) -i ollama.local` và `use_backend ollama_backend if host_ollama`.
  - Back-end declaration: `backend ollama_backend` chỉ tới `server ollama ollama:11434 check`.
- **Lý do chọn**: Đáp ứng FR-003 và AC-003. Cho phép các công cụ dev trên host machine truy cập Ollama API qua `http://ollama.local` (hoặc `http://localhost:11434`), đồng thời các container nội bộ gọi qua hostname `http://ollama:11434`.
- **Phương án đã loại**:
  1. Chỉ mở port 11434 ra host mà không bật HAProxy: Bỏ vì thiếu thống nhất với cơ chế reverse proxy chung cho toàn hệ thống dev (`api.flex.internal`, `jenkins.local`, `portainer.local`).

---

## 3. Tổng kết rủi ro & Biện pháp giảm thiểu

| Rủi ro | Mức độ | Biện pháp |
|--------|--------|-----------|
| Thời gian tải mô hình `qwen2.5:1.5b` lần đầu phụ thuộc tốc độ mạng | Trung bình | `ollama-init` chạy không blocking các app service khác, log tiến trình hiển thị rõ ràng qua `docker compose logs -f ollama-init`. Dữ liệu model lưu tại volume `ollama_data` nên lần khởi động sau sẽ dùng lại ngay (FR-004). |
| Xung đột port 11434 nếu máy host đã có Ollama native đang chạy | Thấp | Khuyến nghị developer dừng service Ollama local trên host (nếu có) trước khi `docker compose up`. |
