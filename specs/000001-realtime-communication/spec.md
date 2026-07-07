# Đặc tả tính năng: Hệ thống Giao tiếp Thời gian Thực

**Branch**: `000001-realtime-communication`

**Ngày tạo**: 2026-07-06

**Trạng thái**: Bản nháp

**Đầu vào**: Mô tả người dùng: "Xây dựng chức năng liên quan đến realtime"

---

## 0. Tổng quan

Hệ thống AI cần cung cấp khả năng giao tiếp thời gian thực đa kênh, đảm bảo người dùng nhận được phản hồi ngay lập tức trong các tình huống chat, gọi thoại và theo dõi hàng đợi. Có 4 luồng giao tiếp độc lập: chat bot với phản hồi xuất hiện dần theo thời gian thực, gọi thoại AI hai chiều với khả năng tự phục hồi, gọi voice/video chất lượng cao qua luồng riêng, và màn hình hiển thị hàng đợi gọi số cập nhật tức thì. Mỗi luồng phục vụ một nhóm người dùng và mục đích nghiệp vụ khác nhau, hoạt động độc lập để lỗi ở một luồng không ảnh hưởng đến luồng còn lại.

---

## Clarifications

### Session 2026-07-06

- Q: Khi cuộc gọi thoại AI không thể phục hồi, server giải phóng tài nguyên phiên gọi sau bao lâu? → A: Giải phóng sau 30 giây không phản hồi kể từ lần retry cuối.

---

## 1. Mục tiêu

- **MĐ-01**: Người dùng nhận được phản hồi của AI xuất hiện dần ngay trong khi AI đang xử lý, không phải chờ toàn bộ nội dung hoàn chỉnh mới hiển thị.
- **MĐ-02**: Cuộc gọi thoại AI duy trì kết nối ổn định và tự phục hồi khi mạng gián đoạn mà không cần người dùng thao tác.
- **MĐ-03**: Nhân viên tổng đài nhìn thấy thông tin hàng đợi gọi cập nhật tức thì trên màn hình chờ khi có cuộc gọi mới, không cần tải lại trang.
- **MĐ-04**: Mỗi luồng giao tiếp hoạt động độc lập — lỗi ở một luồng không làm ảnh hưởng đến các luồng khác.

---

## 2. Người dùng & Bối cảnh

**Người dùng chính**:
- **Khách hàng**: Người dùng cuối chat với AI bot hoặc thực hiện cuộc gọi thoại AI qua giao diện web.
- **Nhân viên tổng đài**: Nhân viên theo dõi màn hình hiển thị hàng đợi gọi số trong ca làm việc.
- **Nhân viên tư vấn**: Nhân viên tham gia cuộc gọi voice/video chất lượng cao với khách hàng.

**Bối cảnh sử dụng**:
- Khách hàng chat bot bất kỳ lúc nào, qua giao diện web hoặc các kênh nhắn tin bên ngoài (mạng xã hội, ứng dụng nhắn tin).
- Nhân viên tổng đài theo dõi màn hình hàng đợi liên tục trong toàn bộ ca làm việc — cần cập nhật tức thì.
- Cuộc gọi thoại AI xảy ra khi khách hàng chủ động khởi tạo từ giao diện chat.

**Trình độ kỹ thuật**: Người dùng cuối không có kỹ thuật; nhân viên tổng đài quen với phần mềm nghiệp vụ cơ bản.

---

## 3. Kịch bản người dùng *(bắt buộc)*

### Kịch bản 1 — Chat bot nhận phản hồi xuất hiện dần (Ưu tiên: P1)

Khách hàng gửi tin nhắn cho AI bot. Thay vì chờ đợi, từng phần nội dung phản hồi xuất hiện ngay trên màn hình trong khi AI vẫn đang tạo nội dung — tương tự trải nghiệm đánh máy trực tiếp. Tin nhắn đầy đủ được lưu vào lịch sử sau khi AI hoàn tất.

**Lý do ưu tiên**: Luồng có lưu lượng cao nhất; trải nghiệm phản hồi dần giảm rõ rệt cảm giác chờ đợi và tăng độ tin tưởng vào hệ thống AI.

**Test độc lập**: Gửi tin nhắn chat → quan sát nội dung xuất hiện từng phần → xác nhận tin nhắn hoàn chỉnh hiển thị sau khi AI xong.

**Acceptance Scenarios**:

1. **Cho trước** khách hàng đã đăng nhập và mở giao diện chat, **Khi** gửi một tin nhắn, **Thì** nội dung phản hồi bắt đầu xuất hiện trên màn hình trong vòng 2 giây, hiển thị dần từng phần.
2. **Cho trước** AI đang phản hồi dần, **Khi** kết nối bị gián đoạn ngắn dưới 10 giây, **Thì** kết nối tự phục hồi và phản hồi tiếp tục hoặc được gửi lại đầy đủ mà không cần người dùng thao tác.
3. **Cho trước** tin nhắn đến từ kênh bên ngoài (mạng xã hội, ứng dụng nhắn tin), **Khi** AI xử lý xong, **Thì** phản hồi xuất hiện trên giao diện web trong vòng 3 giây.
4. **Cho trước** AI đã hoàn thành phản hồi, **Khi** người dùng đóng tab rồi mở lại, **Thì** toàn bộ lịch sử tin nhắn hiển thị đầy đủ.

---

### Kịch bản 2 — Gọi thoại AI tự phục hồi kết nối (Ưu tiên: P1)

Khách hàng khởi tạo cuộc gọi thoại với AI. Hệ thống thiết lập luồng âm thanh hai chiều ngay lập tức. Nếu kết nối bị đứt, hệ thống âm thầm thử kết nối lại với khoảng dừng tăng dần giữa các lần thử — không hiển thị thông báo lỗi liên tục làm phiền người dùng. Chỉ thông báo khi thực sự không thể phục hồi.

**Lý do ưu tiên**: Mất kết nối giữa chừng trong cuộc gọi là trải nghiệm tệ nhất có thể xảy ra; tự phục hồi là yêu cầu tối thiểu để tính năng có thể dùng được trong thực tế.

**Test độc lập**: Khởi tạo cuộc gọi thoại → mô phỏng đứt mạng → quan sát hành vi tự kết nối lại → xác nhận cuộc gọi phục hồi.

**Acceptance Scenarios**:

1. **Cho trước** khách hàng đang trong cuộc gọi thoại AI, **Khi** kết nối bị đứt, **Thì** hệ thống tự động thử kết nối lại mà không hiện thông báo lỗi liên tục.
2. **Cho trước** hệ thống đang thử kết nối lại, **Khi** kết nối phục hồi, **Thì** cuộc gọi tiếp tục hoặc bắt đầu lại một cách mượt mà không cần người dùng bấm nút.
3. **Cho trước** đã thử kết nối lại nhiều lần không thành công, **Khi** vượt quá ngưỡng thử lại, **Thì** hiển thị thông báo lỗi rõ ràng kèm tùy chọn gọi lại.

---

### Kịch bản 3 — Màn hình hàng đợi cập nhật tức thì (Ưu tiên: P2)

Nhân viên tổng đài đang nhìn vào màn hình hiển thị danh sách hàng đợi gọi số. Khi hệ thống tiếp nhận một cuộc gọi mới, thông tin cuộc gọi xuất hiện ngay trên màn hình — không cần F5, không có độ trễ đáng kể.

**Lý do ưu tiên**: Màn hình hàng đợi là công cụ nghiệp vụ thiết yếu — độ trễ dù nhỏ cũng ảnh hưởng trực tiếp đến chất lượng phục vụ khách hàng.

**Test độc lập**: Mở màn hình hàng đợi → tạo cuộc gọi mới vào hệ thống → quan sát màn hình cập nhật tự động trong vòng 2 giây.

**Acceptance Scenarios**:

1. **Cho trước** nhân viên đang xem màn hình hàng đợi, **Khi** có cuộc gọi mới vào hàng đợi, **Thì** thông tin cuộc gọi xuất hiện trên màn hình trong vòng 2 giây mà không cần tải lại trang.
2. **Cho trước** nhiều nhân viên đang xem màn hình hàng đợi của cùng một phòng ban, **Khi** có sự kiện hàng đợi mới, **Thì** tất cả màn hình cập nhật đồng thời.
3. **Cho trước** nhân viên vừa mở màn hình hàng đợi, **Khi** trang tải xong, **Thì** trạng thái hàng đợi hiện tại hiển thị đúng và đầy đủ ngay lập tức.

---

### Trường hợp biên

- Điều gì xảy ra khi dịch vụ realtime tạm thời không phản hồi? → Màn hình hiển thị trạng thái "đang kết nối lại" thay vì trắng hoặc đóng băng.
- Hệ thống xử lý thế nào khi người dùng mở nhiều tab cùng lúc? → Mỗi tab duy trì kết nối độc lập; không có xung đột dữ liệu.
- Điều gì xảy ra khi tin nhắn đến nhưng người dùng đã đóng tab? → Tin nhắn được lưu vào lịch sử và hiển thị đầy đủ khi người dùng mở lại.
- Hệ thống xử lý thế nào khi phiên đăng nhập hết hạn trong lúc đang kết nối? → Thông báo yêu cầu đăng nhập lại, không mất dữ liệu đã nhập.
- Điều gì xảy ra khi 2 kênh realtime cùng lỗi đồng thời? → Mỗi kênh tự xử lý lỗi độc lập; người dùng nhận thông báo tương ứng cho từng kênh.

---

## 4. Yêu cầu chức năng *(bắt buộc)*

- **YC-001**: Hệ thống PHẢI cho phép nội dung phản hồi AI hiển thị dần từng phần trong khi AI đang tạo nội dung, không chờ phản hồi hoàn chỉnh.
- **YC-002**: Hệ thống PHẢI duy trì kết nối thời gian thực liên tục với người dùng trong suốt phiên làm việc, tương ứng với từng loại tương tác.
- **YC-003**: Hệ thống PHẢI tự động thử kết nối lại khi kết nối bị gián đoạn, không yêu cầu người dùng thao tác thủ công.
- **YC-004**: Hệ thống PHẢI xác thực danh tính người dùng trước khi thiết lập bất kỳ kết nối thời gian thực nào.
- **YC-005**: Hệ thống PHẢI chuyển tiếp tin nhắn từ các kênh bên ngoài (mạng xã hội, ứng dụng nhắn tin) đến giao diện web của người dùng trong thời gian thực.
- **YC-006**: Hệ thống PHẢI hỗ trợ cuộc gọi thoại AI hai chiều với luồng âm thanh liên tục theo thời gian thực.
- **YC-007**: Hệ thống PHẢI phát sóng sự kiện hàng đợi gọi số đến đúng màn hình của nhân viên tổng đài được chỉ định.
- **YC-008**: Hệ thống KHÔNG ĐƯỢC để lỗi ở một kênh giao tiếp (chat / thoại / hàng đợi) ảnh hưởng đến hoạt động của các kênh còn lại.
- **YC-009**: Hệ thống PHẢI lưu lịch sử toàn bộ tin nhắn để người dùng có thể xem lại khi quay lại.
- **YC-010**: Người dùng PHẢI có thể tham gia cuộc gọi voice/video chất lượng cao qua một kênh riêng biệt, hoàn toàn tách với kênh chat văn bản.

---

## 5. Yêu cầu phi chức năng

- **YCPCK-001**: Nội dung phản hồi streaming PHẢI bắt đầu xuất hiện trên màn hình trong vòng 2 giây sau khi người dùng gửi tin nhắn, trong điều kiện mạng bình thường.
- **YCPCK-002**: Sự kiện hàng đợi gọi số PHẢI hiển thị trên màn hình tổng đài trong vòng 2 giây sau khi hệ thống tiếp nhận cuộc gọi, trong ít nhất 98% trường hợp.
- **YCPCK-003**: Hệ thống PHẢI hỗ trợ ít nhất 500 kết nối thời gian thực đồng thời mà không suy giảm đáng kể trải nghiệm người dùng.
- **YCPCK-004**: Mọi kết nối thời gian thực PHẢI được bảo mật — không cho phép nghe lén hoặc chèn nội dung giả mạo từ bên ngoài.
- **YCPCK-005**: Tính năng realtime PHẢI hoạt động trên Chrome, Edge, Firefox phiên bản mới nhất (cả desktop và mobile web).
- **YCPCK-006**: Hệ thống PHẢI tự phục hồi kết nối trong vòng 10 giây trong ít nhất 90% trường hợp gián đoạn ngắn.
- **YCPCK-007**: Sau khi cuộc gọi thoại AI không thể phục hồi, hệ thống PHẢI giải phóng toàn bộ tài nguyên phiên gọi phía server trong vòng 30 giây kể từ lần thử kết nối lại cuối cùng thất bại.

---

## 6. Thực thể dữ liệu

- **Phiên kết nối**: Đại diện cho một kết nối thời gian thực của người dùng; liên kết với danh tính người dùng, loại kênh (chat / thoại / hàng đợi), và trạng thái hiện tại (đang kết nối / mất kết nối / đang phục hồi).
- **Tin nhắn chat**: Nội dung trao đổi giữa người dùng và AI; có trạng thái (đang stream / hoàn chỉnh), nguồn gốc (trực tiếp / kênh bên ngoài), và thời điểm gửi/nhận.
- **Sự kiện hàng đợi**: Thông báo về một cuộc gọi mới trong hàng đợi; chứa thông tin nhân viên tổng đài được chỉ định và thời điểm phát sinh.
- **Phiên gọi thoại**: Thông tin một cuộc gọi thoại AI; liên kết với người dùng, trạng thái kết nối, và chuỗi lượt hội thoại (khởi tạo / nhận âm thanh / phát âm thanh / kết thúc lượt). Tài nguyên phiên được giải phóng sau 30 giây không phản hồi kể từ lần retry cuối.

---

## 7. Tiêu chí thành công *(bắt buộc)*

- **TC-001**: Ít nhất 95% tin nhắn chat bắt đầu hiển thị phản hồi dần trong vòng 2 giây sau khi gửi.
- **TC-002**: Hệ thống tự phục hồi kết nối thành công trong ít nhất 90% trường hợp gián đoạn ngắn dưới 30 giây.
- **TC-003**: Sự kiện hàng đợi gọi số hiển thị trên màn hình tổng đài trong vòng 2 giây trong ít nhất 98% trường hợp.
- **TC-004**: Không có sự cố nào ở một kênh giao tiếp gây gián đoạn kênh khác trong vòng 30 ngày vận hành thực tế.
- **TC-005**: 100% kết nối thời gian thực yêu cầu xác thực thành công trước khi có thể nhận hoặc gửi dữ liệu.

---

## 8. Giả định & Ràng buộc

**Giả định**:
- Người dùng có kết nối internet ổn định (3G trở lên) trong điều kiện sử dụng thông thường.
- Hệ thống xác thực và quản lý phiên đăng nhập hiện tại sẽ được tái sử dụng cho các kết nối thời gian thực.
- Các kênh nhắn tin bên ngoài đã có cơ chế nhận tin nhắn và chuyển tiếp vào hệ thống.
- Cơ sở hạ tầng message broker và cache đã được triển khai và hoạt động ổn định.

**Ràng buộc**:
- Mỗi luồng giao tiếp (chat / thoại AI / voice/video chất lượng cao / hàng đợi) PHẢI độc lập hoàn toàn về kênh truyền tải — không chia sẻ connection pool.
- Luồng voice/video chất lượng cao CHỈ dùng cho cuộc gọi nhân viên tư vấn — KHÔNG dùng cho chat văn bản thông thường.
- Hệ thống trung gian (message broker) là thành phần bắt buộc giữa backend xử lý AI và giao diện người dùng — không nối trực tiếp.

---

## 9. Ngoài phạm vi

- Push notification trên ứng dụng mobile (iOS/Android native app).
- Ghi âm, lưu trữ hoặc phân tích nội dung cuộc gọi thoại.
- Dashboard theo dõi lưu lượng và hiệu năng các kênh realtime (thuộc phạm vi observability riêng).
- Hỗ trợ realtime cho ứng dụng mobile native — chỉ áp dụng cho web.
- Tính năng gọi video nhóm (nhiều hơn 2 người tham gia).

---

## 10. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Hệ thống message broker bị tắc nghẽn khi lưu lượng chat cao điểm | Trung | Cao | Giới hạn lưu lượng theo người dùng và thiết lập cảnh báo sớm khi độ trễ tăng |
| Kết nối thời gian thực bị chặn bởi firewall doanh nghiệp | Trung | Cao | Hỗ trợ phương án dự phòng và cung cấp hướng dẫn cấu hình mạng |
| Phiên đăng nhập hết hạn trong lúc đang kết nối gây mất dữ liệu chưa lưu | Thấp | Trung | Gia hạn phiên tự động hoặc lưu tạm nội dung trước khi yêu cầu đăng nhập lại |
| Hàng đợi sự kiện bị xử lý trùng lặp gây hiển thị sai trên màn hình tổng đài | Thấp | Trung | Đảm bảo mỗi sự kiện chỉ được xử lý đúng một lần ở phía nhận |
| Dịch vụ voice/video chất lượng cao không khả dụng làm gián đoạn tư vấn | Thấp | Cao | Thông báo rõ ràng khi dịch vụ không sẵn sàng; cung cấp phương án liên lạc thay thế |

---

## 11. Phụ thuộc

- Hệ thống message broker phải hoạt động ổn định — là cầu nối giữa backend AI và giao diện người dùng.
- Hệ thống hàng đợi sự kiện (event queue) phải sẵn sàng trước khi triển khai luồng hàng đợi gọi số.
- Dịch vụ voice/video chất lượng cao (bên thứ ba hoặc tự triển khai) phải có endpoint và cơ chế cấp quyền trước khi implement luồng này.
- Quyết định về ngưỡng thử lại và chiến lược backoff cần được thống nhất với nhóm kỹ thuật trước khi triển khai luồng gọi thoại.

---

## 12. Câu hỏi mở

- [CẦN LÀM RÕ: Màn hình hàng đợi gọi số có yêu cầu xác thực riêng hay dùng chung phiên đăng nhập với giao diện chính của nhân viên? Ảnh hưởng đến cách phân quyền và bảo mật kênh nhận sự kiện.]
