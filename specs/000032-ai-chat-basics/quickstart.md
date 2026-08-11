# Quickstart — Xác minh Chat AI cơ bản

## Điều kiện trước

1. Hạ tầng Ollama/Qwen từ feature `000027-restore-ollama-core` đang healthy và model `qwen2.5:1.5b` đã sẵn sàng.
2. `flex-agent-service` có configuration runtime cho endpoint Ollama, model và timeout; dùng secret/configuration store phù hợp, không commit credential.
3. Có Bearer JWT hợp lệ của môi trường test.

## Build và test

Tại repository `flex-agent-service`:

```powershell
dotnet build Flex.Agent.sln --configuration Release
dotnet test Flex.Agent.sln --configuration Release
```

## Kịch bản 1 — Tóm tắt thành công

Gửi request được xác thực tới `POST /api/v1/ai/chat/summarize` với `conversation` không rỗng.

Kỳ vọng:

- HTTP 200.
- JSON có `summary` không rỗng.
- Log/trace chỉ có metadata (`traceId`, provider, model, duration, outcome), không có conversation/summary.

## Kịch bản 2 — Input không hợp lệ

Gửi body có `conversation` rỗng hoặc khoảng trắng.

Kỳ vọng:

- HTTP 400.
- Code `AI_CONVERSATION_REQUIRED`.
- Không có downstream request tới Ollama.

## Kịch bản 3 — Provider không sẵn sàng

Tạm thời làm endpoint Ollama không truy cập được trong môi trường test hoặc dùng test handler trả failure.

Kỳ vọng:

- HTTP 503 hoặc 504 theo loại lỗi.
- Không có stack trace, credential, conversation hay provider response body trong response/log.
- Hủy request từ client phải hủy gọi downstream, không có retry ngầm.

## Smoke check sau deploy

1. Thực hiện Kịch bản 1 bằng JWT test.
2. Kiểm tra latency/error/timeout metric trong 30 phút đầu.
3. Kiểm tra log sample để bảo đảm payload nhạy cảm không xuất hiện.
