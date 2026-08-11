# Research — Chat AI cơ bản

## DEC-001 — Dùng port application và adapter provider

**Decision**: Đặt `IChatModelClient`, `ChatRequest`, `ChatResponse` và `ConversationSummaryService` trong `Flex.Agent.Application`; đặt `OllamaChatModelClient` trong `Flex.Agent.Infrastructures`.

**Rationale**: Use case tóm tắt là policy nghiệp vụ, còn HTTP/Ollama là integration biến động. Boundary này bảo vệ controller và business layer khỏi DTO/vendor SDK; test use case bằng fake port và thay provider qua DI.

**Alternatives considered**:

- Controller hoặc các service gọi Ollama trực tiếp: loại vì coupling bị rải và không đạt FR-004.
- Port trong Domain: loại vì gọi model là external integration, không phải domain invariant.
- Generic mediator/event bus: loại vì một synchronous use case không cần thêm dispatch layer.

## DEC-002 — Dùng OpenAI-compatible chat request của Ollama

**Decision**: Adapter đầu tiên gọi chat-completions compatible endpoint của Ollama; DTO của endpoint chỉ nằm trong infrastructure.

**Rationale**: Ollama công bố hỗ trợ một phần OpenAI API, gồm `/v1/chat/completions`, giúp adapter sử dụng payload chat phổ biến trong khi port nội bộ vẫn không phụ thuộc protocol đó. Xem [Ollama OpenAI compatibility](https://docs.ollama.com/api/openai-compatibility).

**Alternatives considered**:

- Ollama native `/api/chat`: loại ở MVP vì không tăng giá trị so với compatible contract và làm migration provider sau này tốn hơn.
- Thêm OpenAI SDK ngay: loại để tránh package/SDK abstraction không cần thiết; typed `HttpClient` là đủ cho một endpoint.

## DEC-003 — Typed HttpClient và configuration options

**Decision**: Register `OllamaChatModelClient` bằng typed `HttpClient`; bind endpoint/model/timeout từ `OllamaOptions`.

**Rationale**: Repository đã dùng `AddHttpClient`. `IHttpClientFactory` quản lý lifetime/lifecycle của handler và hỗ trợ named/typed clients; xem [Microsoft guidance](https://learn.microsoft.com/en-us/dotnet/core/extensions/httpclient-factory). Configuration cho phép đổi endpoint/model/timeout theo môi trường mà không đổi application code.

**Alternatives considered**:

- `new HttpClient()` hoặc static client trong controller: loại vì ownership/configuration khó kiểm soát và không khớp pattern hiện có.
- Endpoint/model hardcode: loại vì không an toàn và không hỗ trợ portability.

## DEC-004 — Failure, cancellation và retry

**Decision**: Propagate `CancellationToken`; áp deadline 30 giây tại typed client; không retry tự động. Chuẩn hóa timeout/unavailable/invalid-response thành lỗi application rõ ràng.

**Rationale**: Yêu cầu là synchronous, không có side effect bền và người dùng có thể gửi lại. Retry làm tăng latency/tải, có thể sinh summary khác và che giấu sự cố hạ tầng.

**Alternatives considered**:

- Retry nhiều lần trong request: loại vì không có yêu cầu availability đủ để biện minh.
- Trả raw upstream error: loại vì có thể lộ topology hoặc payload provider.

## DEC-005 — Không persistence

**Decision**: Không tạo entity, DbContext change, migration hay audit record trong MVP.

**Rationale**: MVP-003/BR-003 quy định mỗi request độc lập và không lưu hội thoại/kết quả. Việc thêm storage sẽ mở rộng đáng kể phạm vi dữ liệu nhạy cảm.

**Alternatives considered**:

- Lưu history tóm tắt: loại vì ngoài phạm vi; cần spec riêng về retention, quyền và audit.
