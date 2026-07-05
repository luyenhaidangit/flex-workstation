# Đặc tả tính năng: Hệ thống Giao tiếp Thời gian Thực

**Branch**: `001-realtime-communication`

**Ngày tạo**: 2026-07-05

**Trạng thái**: Bản nháp

**Đầu vào**: Mô tả người dùng: "Xây dựng chức năng liên quan đến realtime"

---

## 0. Tổng quan

Hệ thống cần cung cấp khả năng giao tiếp thời gian thực đa kênh cho nền tảng AI. Có 4 luồng giao tiếp riêng biệt: chat bot qua Socket.IO với Redis Stream bridge, chat trực tiếp qua API (SSE), gọi voice AI qua WebSocket thuần, và gọi voice/video chất lượng cao qua LiveKit (WebRTC). Ngoài ra có luồng GOV (màn hình gọi số) dùng Socket.IO namespace riêng với Kafka làm bridge. Mục tiêu là đảm bảo mỗi luồng hoạt động ổn định, độc lập, và người dùng nhận được phản hồi tức thời không bị delay cảm nhận.

---

## 1. Mục tiêu

- **MĐ-01**: Người dùng nhận được tin nhắn bot ngay khi AI phát sinh response, không phải chờ toàn bộ phản hồi hoàn tất.
- **MĐ-02**: Cuộc gọi voice AI kết nối thành công và tự động phục hồi khi mạng gián đoạn mà không yêu cầu người dùng thao tác thủ công.
- **MĐ-03**: Nhân viên tổng đài (GOV) nhìn thấy số hàng đợi gọi cập nhật tức thì trên màn hình chờ khi có cuộc gọi mới.
- **MĐ-04**: Các luồng realtime hoạt động độc lập — lỗi ở một luồng không ảnh hưởng đến luồng khác.

---

## 2. Người dùng & Bối cảnh

**Người dùng chính**:
- **Khách hàng / End User**: Người chat với AI bot hoặc gọi voice AI qua giao diện web/mobile.
- **Nhân viên tổng đài (Agent)**: Nhân viên sử dụng màn hình GOV TV để theo dõi hàng đợi gọi số.
- **Agent voice/video**: Nhân viên tham gia cuộc gọi voice/video chất lượng cao với khách hàng.

**Bối cảnh sử dụng**:
- Khách hàng chat bot trong giờ hành chính hoặc ngoài giờ qua kênh web, FB, Zalo, TikTok, HNW.
- Nhân viên tổng đài theo dõi màn hình GOV TV liên tục trong ca làm việc.
- Cuộc gọi voice AI xảy ra bất cứ lúc nào khách hàng khởi tạo từ giao diện chat.

**Trình độ kỹ thuật**: Người dùng cuối không có kỹ thuật; nhân viên tổng đài quen dùng phần mềm nghiệp vụ cơ bản.

---

## 3. Kịch bản người dùng *(bắt buộc)*

### Kịch bản 1 — Chat bot nhận phản hồi streaming (Ưu tiên: P1)

Khách hàng gửi tin nhắn cho AI bot. Ngay lập tức, từng phần nội dung phản hồi của AI hiển thị dần trên màn hình (streaming), không phải chờ bot hoàn thành toàn bộ câu trả lời mới hiện ra. Khi bot xong, tin nhắn đầy đủ được lưu vào lịch sử.

**Lý do ưu tiên**: Đây là luồng chính với lượng sử dụng cao nhất. Trải nghiệm streaming giảm đáng kể cảm giác chờ đợi của khách hàng.

**Test độc lập**: Gửi tin nhắn chat → quan sát text xuất hiện từng phần → xác nhận tin nhắn hoàn chỉnh sau khi bot xong.

**Acceptance Scenarios**:

1. **Cho trước** khách hàng đã đăng nhập và mở chat, **Khi** gửi tin nhắn, **Thì** text phản hồi của bot xuất hiện từng phần trong vòng 1-2 giây sau khi gửi.
2. **Cho trước** bot đang streaming response, **Khi** mạng gián đoạn ngắn (< 5 giây), **Thì** kết nối tự phục hồi và response tiếp tục hoặc được gửi lại đầy đủ.
3. **Cho trước** tin nhắn đến từ kênh webhook (FB/Zalo/TikTok), **Khi** bot xử lý xong, **Thì** response xuất hiện trên giao diện web trong vòng 3 giây.

---

### Kịch bản 2 — Gọi voice AI tự động phục hồi kết nối (Ưu tiên: P1)

Khách hàng khởi tạo cuộc gọi voice AI. Hệ thống kết nối và duy trì luồng âm thanh hai chiều. Nếu kết nối bị đứt, hệ thống tự động thử kết nối lại với độ trễ tăng dần (exponential backoff), không hiện thông báo lỗi liên tục làm phiền người dùng.

**Lý do ưu tiên**: Mất kết nối voice trong cuộc gọi là trải nghiệm tệ nhất — tự phục hồi là yêu cầu tối thiểu.

**Test độc lập**: Khởi tạo voice call → ngắt mạng giả lập → quan sát hành vi reconnect → xác nhận cuộc gọi phục hồi.

**Acceptance Scenarios**:

1. **Cho trước** khách hàng đang trong cuộc gọi voice AI, **Khi** kết nối bị đứt, **Thì** hệ thống tự động thử kết nối lại mà không yêu cầu người dùng bấm nút.
2. **Cho trước** hệ thống đang reconnect, **Khi** kết nối phục hồi, **Thì** cuộc gọi tiếp tục từ trạng thái trước đó hoặc bắt đầu lại một cách graceful.
3. **Cho trước** kết nối thất bại liên tục quá ngưỡng cho phép, **Khi** hết retry, **Thì** hiển thị thông báo lỗi rõ ràng và tùy chọn gọi lại.

---

### Kịch bản 3 — Màn hình GOV nhận thông báo gọi số tức thì (Ưu tiên: P2)

Nhân viên tổng đài nhìn vào màn hình GOV TV đang hiển thị hàng đợi. Khi hệ thống tiếp nhận cuộc gọi mới, màn hình cập nhật ngay số hàng đợi mà không cần F5.

**Lý do ưu tiên**: Màn hình gọi số là công cụ nghiệp vụ thiết yếu của tổng đài — delay ở đây ảnh hưởng trực tiếp đến quy trình phục vụ khách hàng.

**Test độc lập**: Nhân viên mở GOV TV → giả lập cuộc gọi mới vào → quan sát màn hình cập nhật trong vòng 2 giây.

**Acceptance Scenarios**:

1. **Cho trước** nhân viên đang xem màn hình GOV TV, **Khi** có cuộc gọi mới vào hàng đợi, **Thì** màn hình hiển thị thông tin cuộc gọi trong vòng 2 giây mà không cần tải lại trang.
2. **Cho trước** nhiều nhân viên đang xem GOV TV của cùng một agent, **Khi** có sự kiện gọi số, **Thì** tất cả màn hình cập nhật đồng thời.

---

### Trường hợp biên

- Điều gì xảy ra khi server realtime tạm thời không phản hồi? → Hiển thị trạng thái "đang kết nối lại" thay vì màn hình trắng.
- Hệ thống xử lý thế nào khi khách hàng mở nhiều tab cùng lúc? → Mỗi tab duy trì kết nối độc lập; không có xung đột session.
- Điều gì xảy ra khi message đến nhưng người dùng đã đóng tab? → Message được lưu vào lịch sử; hiển thị khi mở lại.
- Hệ thống xử lý thế nào khi token JWT hết hạn trong lúc đang kết nối? → Thông báo yêu cầu đăng nhập lại, không drop silent.

---

## 4. Yêu cầu chức năng *(bắt buộc)*

- **YC-001**: Hệ thống PHẢI cho phép người dùng nhận phản hồi AI dạng streaming (từng phần) trong khi AI đang tạo nội dung.
- **YC-002**: Hệ thống PHẢI duy trì kết nối thời gian thực liên tục với mỗi người dùng trong suốt phiên làm việc, tương ứng với loại tương tác (chat / voice / màn hình gọi số).
- **YC-003**: Hệ thống PHẢI tự động thử kết nối lại khi kết nối bị gián đoạn, không yêu cầu người dùng thao tác thủ công.
- **YC-004**: Hệ thống PHẢI xác thực danh tính người dùng trước khi thiết lập bất kỳ kết nối thời gian thực nào.
- **YC-005**: Hệ thống PHẢI đảm bảo tin nhắn từ kênh bên ngoài (FB, Zalo, TikTok, HNW) được chuyển tiếp đến giao diện web người dùng.
- **YC-006**: Hệ thống PHẢI hỗ trợ cuộc gọi voice AI hai chiều với khả năng truyền âm thanh liên tục theo thời gian thực.
- **YC-007**: Hệ thống PHẢI phát sóng sự kiện gọi số GOV đến đúng màn hình của agent được chỉ định.
- **YC-008**: Hệ thống KHÔNG ĐƯỢC để lỗi ở một luồng giao tiếp (chat/voice/GOV) làm ảnh hưởng đến luồng khác.
- **YC-009**: Hệ thống PHẢI lưu lịch sử tin nhắn để người dùng có thể xem lại khi mở lại ứng dụng.
- **YC-010**: Người dùng PHẢI có thể tham gia cuộc gọi voice/video chất lượng cao qua một luồng riêng biệt, hoàn toàn tách với kênh chat text thông thường.

---

## 5. Yêu cầu phi chức năng

- **YCPCK-001**: Tin nhắn streaming PHẢI bắt đầu xuất hiện trên màn hình người dùng trong vòng 2 giây sau khi gửi, trong điều kiện mạng bình thường.
- **YCPCK-002**: Sự kiện GOV gọi số PHẢI hiển thị trên màn hình trong vòng 2 giây sau khi hệ thống tiếp nhận cuộc gọi.
- **YCPCK-003**: Hệ thống PHẢI hỗ trợ ít nhất 500 kết nối realtime đồng thời mà không suy giảm đáng kể trải nghiệm người dùng.
- **YCPCK-004**: Kết nối thời gian thực PHẢI được bảo mật — KHÔNG cho phép nghe lén hoặc chèn tin nhắn giả mạo từ bên ngoài.
- **YCPCK-005**: Tính năng realtime PHẢI hoạt động trên Chrome, Edge, Firefox phiên bản mới nhất (desktop và mobile web).
- **YCPCK-006**: Thời gian phục hồi kết nối sau gián đoạn PHẢI dưới 10 giây trong 90% trường hợp.

---

## 6. Thực thể dữ liệu

- **Phiên kết nối (Connection Session)**: Đại diện cho một kết nối realtime của người dùng; liên kết với danh tính người dùng, loại kết nối (chat/voice/GOV), và trạng thái (active/disconnected).
- **Tin nhắn Chat**: Nội dung trao đổi giữa người dùng và AI bot; có trạng thái (đang stream / hoàn chỉnh), nguồn gốc (web trực tiếp / kênh ngoài), và timestamp.
- **Sự kiện GOV**: Thông báo cuộc gọi mới vào hàng đợi; chứa thông tin agent được chỉ định, số hàng đợi, thời gian phát sinh.
- **Phiên gọi Voice**: Thông tin một cuộc gọi voice AI; liên kết với người dùng, trạng thái kết nối WebSocket, và lịch sử turn (init/audio/text/turn_complete).

---

## 7. Tiêu chí thành công *(bắt buộc)*

- **TC-001**: Ít nhất 95% tin nhắn chat streaming bắt đầu hiển thị trên màn hình người dùng trong vòng 2 giây sau khi gửi.
- **TC-002**: Hệ thống tự động phục hồi kết nối thành công trong ít nhất 90% trường hợp gián đoạn ngắn (< 30 giây).
- **TC-003**: Sự kiện GOV gọi số hiển thị trên màn hình tổng đài trong vòng 2 giây trong ít nhất 98% trường hợp.
- **TC-004**: Zero incident nào ở một luồng (chat/voice/GOV) gây crash hoặc ngừng hoạt động luồng khác trong vòng 30 ngày vận hành.
- **TC-005**: 100% kết nối realtime yêu cầu xác thực thành công trước khi nhận/gửi dữ liệu — không có kết nối ẩn danh.

---

## 8. Giả định & Ràng buộc

**Giả định**:
- Người dùng có kết nối internet ổn định (3G trở lên) trong điều kiện thông thường.
- Hệ thống xác thực (JWT) hiện tại tiếp tục được tái sử dụng cho realtime connections.
- Các kênh bên ngoài (FB, Zalo, TikTok, HNW) đã có webhook integration sẵn.
- Redis và Kafka đã được triển khai và hoạt động ổn định trong môi trường production.

**Ràng buộc**:
- Kiến trúc realtime KHÔNG dùng SignalR — hệ thống tự build bridge .NET ↔ Node.js qua Redis Stream.
- Mỗi luồng giao tiếp (chat/voice AI/LiveKit/GOV) PHẢI độc lập về transport và không chia sẻ connection pool.
- Broker Node.js là điểm trung gian bắt buộc giữa Backend .NET và Socket.IO client — không nối trực tiếp.
- LiveKit chỉ dùng cho voice/video chất lượng cao của agent — KHÔNG dùng cho chat text thường.

---

## 9. Ngoài phạm vi

- Tích hợp SignalR hoặc bất kỳ thư viện realtime thay thế nào khác ngoài kiến trúc đã xác định.
- Push notification mobile (FCM/APNs) — đây là kênh khác, không phải realtime connection.
- Analytics và monitoring dashboard cho realtime traffic (thuộc phạm vi observability riêng).
- Ghi âm/lưu trữ cuộc gọi voice (thuộc phạm vi compliance riêng).
- Hỗ trợ realtime cho ứng dụng mobile native (iOS/Android app riêng).

---

## 10. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Redis Stream bị tắc nghẽn khi lưu lượng chat cao | Trung | Cao | Thiết lập giới hạn message retention và monitor độ trễ stream |
| Kết nối WebSocket voice bị block bởi corporate firewall | Trung | Cao | Hỗ trợ fallback sang polling hoặc hướng dẫn cấu hình mạng |
| JWT token hết hạn trong lúc đang kết nối gây mất session | Thấp | Trung | Implement silent token refresh hoặc reconnect với token mới |
| Nhiều consumer Kafka GOV cùng đọc gây duplicate event | Thấp | Trung | Đảm bảo consumer group configuration đúng, idempotent processing |
| LiveKit server không khả dụng làm gián đoạn voice/video agent | Thấp | Cao | Cơ chế fallback và thông báo rõ ràng khi service không khả dụng |

---

## 11. Phụ thuộc

- Redis (StackExchange.Redis) phải hoạt động ổn định — là bridge chính giữa .NET Backend và Node.js Broker.
- Kafka cluster phải available — GOV module và một số pipeline nội bộ phụ thuộc vào Kafka.
- LiveKit server (self-hosted hoặc cloud) phải có endpoint và token service trước khi implement voice/video agent.
- Broker Node.js (`@socket.io/redis-streams-adapter`) phải được deploy song song với Backend .NET.
- Quyết định về ngưỡng retry và backoff strategy cần được thống nhất với team trước khi implement voice WebSocket.

---

## 12. Câu hỏi mở

- [CẦN LÀM RÕ: Khi kết nối voice AI bị đứt và không tự phục hồi được, luồng xử lý phía server (tài nguyên AI session) được giải phóng thế nào và sau bao lâu?]
- [CẦN LÀM RÕ: Màn hình GOV TV có cần xác thực riêng hay dùng chung session với giao diện agent chính? Điều này ảnh hưởng đến cách join room Socket.IO.]
