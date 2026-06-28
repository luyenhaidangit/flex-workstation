# Ideal: 000001

## Source

- Input: `flex-workstation/requirements/000001/idea.md`
- Output: `flex-workstation/requirements/000001/ideal.md`

## Problem Statement

Người dùng đang mở web app không biết ngay khi có phiên đăng nhập mới vào tài khoản của họ. Không có tính năng thông báo realtime đăng nhập nào hiện tại, khiến người dùng không phát hiện được hoạt động đáng ngờ trong khi đang sử dụng app. Backend là .NET; thông báo chỉ cần hoạt động khi app đang mở (không cần background push).

## Recommended Direction

**SSE (Server-Sent Events) + Toast notification**

Auth service phát ra domain event sau mỗi login thành công → một SSE endpoint trên ASP.NET Core giữ kết nối mở với client đang đăng nhập → frontend lắng nghe SSE stream và hiển thị toast ngay khi nhận event.

**Lý do chọn SSE thay vì các phương án khác:**

| Tiêu chí | SSE | SignalR/WebSocket | Polling |
|---|---|---|---|
| Độ phức tạp triển khai | Thấp (native .NET) | Trung bình | Thấp |
| Realtime thực sự | Có | Có | Không (delay) |
| Phù hợp one-way push | Tốt nhất | Overkill | Không |
| Mở rộng sau này | Cần refactor nếu cần bidirectional | Sẵn sàng | Phải thay thế |
| Phù hợp constraint "chỉ khi app mở" | Có | Có | Có |

SSE phù hợp nhất vì luồng thông báo là một chiều (server → client) và ASP.NET Core hỗ trợ native — không cần thêm package.

**Luồng thực thi:**
1. User B đăng nhập vào tài khoản X → Auth service phát `LoginSucceededEvent`
2. Notification service (hoặc handler trong cùng service) nhận event, tìm SSE connection của tài khoản X (nếu đang mở)
3. Đẩy payload `{ "type": "new_login", "device": "...", "time": "..." }` qua SSE
4. Frontend nhận, hiển thị toast "Phiên đăng nhập mới vừa được tạo trên tài khoản của bạn"

**UI: Toast** (không phải banner hay badge) — xuất hiện vài giây rồi tự ẩn, không chặn thao tác. Nếu user có nhiều tab mở, chỉ hiển thị trên tab đang focus (BroadcastChannel API có thể dùng để đồng bộ nếu cần).

## Key Assumptions to Validate

- [ ] Auth service có thể emit event sau mỗi login thành công (domain event, EF Core interceptor, hoặc middleware hook).
- [ ] SSE endpoint và auth service chạy trong cùng process hoặc có thể truyền event nội bộ (in-process pub/sub như MediatR) — nếu khác process thì cần thêm message bus.
- [ ] Toast là đủ — không cần sticky banner hay badge đếm số.
- [ ] Không cần lưu lịch sử thông báo trong MVP (xem Open Questions).
- [ ] Số lượng concurrent users trong app đủ nhỏ để SSE không gây áp lực connection (< vài nghìn).
- [ ] User chấp nhận nhận thông báo cho **tất cả** login kể cả phiên của chính họ (như đã xác định trong idea.md).

## MVP Scope

### In Scope

- SSE endpoint trên ASP.NET Core: `GET /notifications/stream` — giữ kết nối, gửi event khi có login mới.
- Event trigger: mỗi login thành công emit `LoginSucceededEvent` → handler đẩy qua SSE.
- Frontend SSE client: `EventSource` API, kết nối sau khi user đăng nhập, tự reconnect nếu mất kết nối.
- Toast notification UI: hiển thị thông điệp đơn giản với thời gian xảy ra và (nếu có) thông tin thiết bị/IP.
- Kết nối SSE được xác thực (JWT hoặc cookie, nhất quán với auth scheme hiện tại).
- Tự ngắt kết nối SSE khi user logout.

### Out of Scope

- Push notification khi app đóng hoặc background (FCM/APNs).
- Admin dashboard giám sát toàn hệ thống.
- Event streaming sang service khác (message broker, Kafka, RabbitMQ).
- Phân biệt thiết bị lạ / IP mới (tất cả login đều trigger).
- Lịch sử thông báo (persistence — xem Open Questions).
- Mobile app notification.
- Notification cho các event khác ngoài login (password change, etc.).

## Not Doing (and Why)

- **SignalR/WebSocket**: Overkill cho use case một chiều; thêm dependency và độ phức tạp không cần thiết ở MVP.
- **Polling**: Không phải realtime thực sự; tốn tài nguyên; trải nghiệm xấu hơn.
- **Background push (FCM/APNs)**: Ngoài scope đã xác định; cần thêm infrastructure khác hẳn.
- **Phân biệt thiết bị lạ**: Thêm logic phức tạp (lưu device fingerprint, so sánh), không cần thiết để ship MVP.

## Open Questions

- **Lịch sử thông báo**: Có lưu vào DB không? Nếu có, user có thể xem lại danh sách login gần đây trong app — hữu ích cho bảo mật nhưng tăng scope đáng kể. Khuyến nghị: bỏ qua trong MVP, đưa vào iteration tiếp theo.
- **Nhiều tab**: Nếu user mở nhiều tab, thông báo hiển thị ở tất cả hay chỉ tab đang focus? (BroadcastChannel API giải quyết được nhưng thêm phức tạp.)
- **Delay chấp nhận được**: Toast cần xuất hiện trong vòng bao nhiêu giây sau khi login xảy ra? (SSE thường < 1 giây trong cùng datacenter.)
- **Thông tin trong toast**: Ngoài "có phiên mới", hiển thị thêm gì? IP, user-agent, thời gian, tên thiết bị? Cần quyết định trước khi implement payload.
- **Auth service architecture**: SSE handler và auth service có cùng process không? Nếu khác service (microservice), cần xác định cơ chế truyền event nội bộ trước khi bắt đầu.
