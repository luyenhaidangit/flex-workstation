# Hướng dẫn xác minh nhanh (Quickstart Guide): Khôi phục hạ tầng lõi AI (Ollama)

**Branch**: `000027-restore-ollama-core` | **Ngày**: 2026-08-05 | **Đặc tả**: [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/spec.md)

---

## 1. Tiền điều kiện (Prerequisites)

- Docker Desktop / Docker Engine đang chạy trên máy phát triển.
- Môi trường hạ tầng `flex-environment` đã được checkout ở branch `000027-restore-ollama-core`.

---

## 2. Kịch bản xác minh 1: Khởi động stack & Tự động nạp mô hình (US-001 / SC-001)

### Bước 1: Khởi động hạ tầng dev

Chạy lệnh khởi động hạ tầng trong thư mục `flex-environment`:

```bash
cd flex-environment
docker compose up -d
```

### Bước 2: Theo dõi quá trình tự động nạp mô hình

Kiểm tra log của container `ollama-init`:

```bash
docker compose logs -f ollama-init
```

**Kì vọng kết quả**:
Container `ollama-init` tải thành công `qwen2.5:1.5b`, log xuất ra thông báo hoàn thành và container kết thúc với exit code 0.

### Bước 3: Xác minh dịch vụ Ollama và mô hình đã nạp

Gửi HTTP GET tới API kiểm tra danh sách mô hình:

```bash
curl http://localhost:11434/api/tags
```

**Kì vọng kết quả**:
Phản hồi JSON chứa mô hình `"name": "qwen2.5:1.5b"`.

---

## 3. Kịch bản xác minh 2: Kiểm tra kết nối từ dịch vụ nội bộ (US-002 / SC-002)

### Bước 1: Gửi yêu cầu chat thử nghiệm tới Ollama qua API container/HAProxy

```bash
curl http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "qwen2.5:1.5b",
  "messages": [{"role": "user", "content": "Hello"}],
  "stream": false
}'
```

**Kì vọng kết quả**:
Nhận được phản hồi JSON có trạng thái `done: true` và nội dung câu trả lời từ mô hình `qwen2.5:1.5b`.

---

## 4. Kịch bản xác minh 3: Khởi động lại stack không tải lại mô hình (FR-004 / AC-002)

### Bước 1: Restart lại stack container

```bash
docker compose restart ollama
```

### Bước 2: Kiểm tra lại ngay danh sách mô hình

```bash
curl http://localhost:11434/api/tags
```

**Kì vọng kết quả**:
Mô hình `qwen2.5:1.5b` khả dụng ngay lập tức mà không phải chờ tải lại qua mạng.
