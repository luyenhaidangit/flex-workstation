# Research — Tích hợp chat AI tại màn Agent

## DEC-001 — Dùng HTTP preview API, không dùng SignalR direct message

**Decision**: FE gọi `POST /api/v1/ai/chat/preview` qua API Gateway; không gọi hub `SendMessage` cho khung xem trước.

**Rationale**: Hub hiện hữu chỉ chuyển tin giữa hai tài khoản và event `message.created` không mang danh tính Agent hay correlation để lọc phiên preview. Endpoint HTTP phù hợp với một yêu cầu–một phản hồi, có thể trả lỗi rõ ràng và tái sử dụng xác thực JWT hiện có.

**Alternatives considered**:

- Giữ `SendMessage`: loại vì không gọi AI, gây nhầm tin của người dùng khác thành tin Agent và không hỗ trợ Agent bản nháp.
- Thêm command/event SignalR riêng: loại vì streaming và cập nhật realtime không thuộc MVP; làm phức tạp correlation, retry và timeout mà không tăng giá trị hiện tại.

## DEC-002 — Gửi cấu hình Agent bản nháp cùng lịch sử phiên

**Decision**: Mỗi request preview mang `name`, `role`, `instructions` của Agent đang hiển thị trên form cùng danh sách tin nhắn văn bản của phiên hiện tại; lịch sử chỉ tồn tại ở FE.

**Rationale**: Wizard hiện chỉ gửi `name`, `description` và `status` khi phát hành; `instructions` không được lưu ở BE. Gửi cấu hình bản nháp cho phép kết quả phản ánh các chỉnh sửa chưa phát hành, đồng thời giữ MVP không có persistence/migration.

**Alternatives considered**:

- Chỉ gửi tin nhắn cuối: loại vì Agent không nhận được chỉ dẫn và không thể hiểu ngữ cảnh nhiều lượt.
- Bắt buộc lưu Agent trước khi thử: loại vì làm đứt luồng kiểm tra trước phát hành và mở rộng phạm vi save/draft.
- Lưu server-side preview session: loại vì phát sinh retention, audit, quyền truy cập và migration ngoài MVP.

## DEC-003 — Người gửi thử nghiệm là caller đã xác thực

**Decision**: Bỏ dropdown “Người nhận” của direct chat. Người gửi thử nghiệm là người dùng đăng nhập, được xác định từ JWT/profile hiện tại.

**Rationale**: Dropdown hiện hard-code `admin`/`admin2` và cho phép UI mô phỏng người khác mà không có contract phân quyền tương ứng. Người dùng đăng nhập vẫn đáp ứng luồng “người hỏi → Agent trả lời”, đồng thời loại bỏ rủi ro mạo danh và khái niệm người nhận không còn đúng.

**Alternatives considered**:

- Giữ dropdown và gửi `testUserId`: loại vì không có nguồn quyền/contract kiểm chứng danh tính được chọn.
- Dùng identity từ hub direct-message: loại vì đó là channel người–người, không phải phiên preview AI.

## DEC-004 — Tái sử dụng AI port và deadline riêng 15 giây

**Decision**: `AgentPreviewChatService` dùng `IChatModelClient` hiện có, tạo system prompt từ cấu hình bản nháp, truyền cancellation từ HTTP request và áp deadline preview 15 giây. Không sửa timeout mặc định 30 giây của use case tóm tắt.

**Rationale**: Port, adapter Ollama và mapping lỗi provider đã tồn tại trong `flex-agent-service`. Deadline riêng khớp NFR-001 và không làm thay đổi hành vi endpoint tóm tắt hiện có.

**Alternatives considered**:

- Gọi Ollama trực tiếp từ controller: loại vì lặp lại adapter, error mapping và logging hiện hữu.
- Đổi global `OllamaOptions` về 15 giây: loại vì ảnh hưởng `chat/summarize` ngoài scope.
- Tự retry trong request: loại vì dễ tạo phản hồi khác nhau, kéo dài thời gian chờ và không cần cho MVP.

## DEC-005 — Đưa route AI qua API Gateway

**Decision**: Bổ sung route `/api/v1/ai/**` đến `agent-service` vào gateway development/runtime configurations; FE dùng `environment.apiBaseUrl` như `AgentService` hiện tại.

**Rationale**: HTTP interceptor FE chỉ tự gắn JWT cho URL thuộc `apiBaseUrl`. Gọi trực tiếp `agentApiBaseUrl` có thể mất token; route mới là additive và giữ boundary gateway.

**Alternatives considered**:

- FE gọi thẳng Agent Service: loại vì bypass gateway và không nhất quán cơ chế token hiện tại.
- Dùng endpoint `chat/summarize`: loại vì contract và mục tiêu tóm tắt không phản ánh Agent đang cấu hình.

## DEC-006 — Success DTO trực tiếp, error DTO hiện hữu

**Decision**: Endpoint preview trả DTO trực tiếp `{ reply, model? }`, errors giữ `{ message, code }` như `AIController` hiện tại.

**Rationale**: Đây là controller AI hiện có; giữ format trực tiếp tránh đưa `Result<T>` của CRUD Agent vào một contract AI mới không tương thích.

**Alternatives considered**:

- Bọc success bằng `Result.Success`: loại vì tạo hai kiểu response trong cùng controller và không mang thêm giá trị cho endpoint mới.
