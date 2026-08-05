# Hợp đồng giao tiếp API (Contract): Dịch vụ AI cục bộ (Ollama)

**Branch**: `000027-restore-ollama-core` | **Ngày**: 2026-08-05 | **Đặc tả**: [spec.md](file:///C:/Workspace/Project/flex-workstation/specs/000027-restore-ollama-core/spec.md)

---

## 1. Tổng quan Hợp đồng Giao tiếp

Dịch vụ Ollama cung cấp chuẩn API tương thích HTTP RESTful cho các dịch vụ nội bộ (như `flex-ai-gateway`) và các công cụ phát triển.

- **Base URL nội bộ (Docker Network)**: `http://ollama:11434`
- **Base URL qua HAProxy (Host)**: `http://ollama.local` (hoặc `http://localhost:11434`)
- **Format**: `application/json`

---

## 2. Các Endpoint chính được tiêu thụ

### 2.1. Kiểm tra danh sách mô hình đã nạp (`GET /api/tags`)

- **Mục đích**: Xác minh mô hình `qwen2.5:1.5b` đã sẵn sàng trong Ollama runtime (FR-005).
- **Method**: `GET`
- **Path**: `/api/tags`
- **Response `200 OK`**:
  ```json
  {
    "models": [
      {
        "name": "qwen2.5:1.5b",
        "model": "qwen2.5:1.5b",
        "modified_at": "2026-08-05T21:00:00Z",
        "size": 986000000,
        "digest": "sha256:..."
      }
    ]
  }
  ```

---

### 2.2. Gửi yêu cầu suy luận Chat Completion (`POST /api/chat`)

- **Mục đích**: Được tiêu thụ bởi `flex-ai-gateway` để gửi prompt và nhận phản hồi từ mô hình.
- **Method**: `POST`
- **Path**: `/api/chat`
- **Request Payload Example**:
  ```json
  {
    "model": "qwen2.5:1.5b",
    "messages": [
      {
        "role": "user",
        "content": "Xin chào"
      }
    ],
    "stream": false
  }
  ```
- **Response `200 OK` Example**:
  ```json
  {
    "model": "qwen2.5:1.5b",
    "created_at": "2026-08-05T21:01:00Z",
    "message": {
      "role": "assistant",
      "content": "Xin chào! Tôi có thể giúp gì cho bạn hôm nay?"
    },
    "done": true
  }
  ```

---

## 3. Tương thích ngược & Ràng buộc

- **Backward compatibility**: Không thay đổi API contract tiêu chuẩn của Ollama v0.6.2.
- **Consumer bị ảnh hưởng**: Dịch vụ `flex-ai-gateway` (sử dụng `OLLAMA_BASE_URL=http://ollama:11434` và `OLLAMA_MODEL_NAME=qwen2.5:1.5b`).
