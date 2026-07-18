# Đặc tả tính năng: Phiên giao dịch, realtime và market-maker bot (FlexSim MVP 04)

**Branch**: `000013-trading-session-bots`
**Ngày tạo**: 2026-07-18
**Trạng thái**: Bản nháp
**Người phụ trách**: Luyện Hải Đăng
**Stakeholder xác nhận**: Luyện Hải Đăng
**Đầu vào**: Thêm vòng đời phiên giao dịch ảo open→continuous→close, WebSocket phát cập nhật realtime và một market-maker bot cung cấp thanh khoản hai chiều qua DemoBroker để thị trường ảo có sức sống và quan sát được.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

MVP 03 đã cung cấp bảng điện cho phép đặt và hủy lệnh demo, nhưng thị trường ảo hiện vẫn "chết": không có chu kỳ phiên (giờ mở, giờ giao dịch, giờ đóng), dữ liệu chỉ cập nhật khi người dùng tự làm mới, và market book không có thanh khoản nền. Điều này khiến kịch bản demo thiếu thực tế: không thể quan sát giá diễn biến theo thời gian thực, không có đối tác mua/bán tự nhiên để lệnh được khớp, và người dùng không hiểu ý nghĩa của việc "phiên đóng — lệnh mới bị từ chối".

**Tổng quan tính năng**:

MVP 04 thêm ba khả năng phối hợp với nhau: (1) vòng đời phiên ảo `open → continuous → close` với thời lượng cấu hình được, (2) WebSocket phát realtime thay đổi order book, giao dịch và trạng thái phiên tới các client đang xem, và (3) một market-maker bot tự động gửi giá mua/bán hai chiều qua `DemoBroker` để duy trì thanh khoản nền trong phiên continuous. Kết quả là thị trường ảo có nhịp sống, giá thay đổi theo thời gian thực và người dùng có thể quan sát hành vi matching mà không cần tự tạo cả hai phía lệnh.

---

## 2. Mục tiêu

- **MT-001**: Người dùng quan sát được phiên giao dịch ảo chạy qua đủ ba trạng thái `open → continuous → close` mà không cần can thiệp thủ công vào hệ thống.
- **MT-002**: Người xem nhận cập nhật giá, order book và giao dịch theo thời gian thực trên bảng điện mà không cần tự làm mới trang.
- **MT-003**: Người dùng có thể đặt lệnh đối ứng với bot trong phiên continuous, quan sát khớp lệnh xảy ra và thấy lệnh mới bị từ chối khi phiên đóng — tất cả trên cùng màn hình bảng điện.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Vòng đời phiên ảo với ba trạng thái `open`, `continuous`, `close` theo thứ tự tuyến tính; thời lượng mỗi giai đoạn cấu hình được trước khi khởi động ngày ảo.
- **MVP-002**: WebSocket phát sự kiện realtime: thay đổi order book (từng mức giá), giao dịch mới và chuyển trạng thái phiên đến tất cả client đang kết nối; bảng điện MVP 03 nhận và hiển thị không cần làm mới trang.
- **MVP-003**: Một market-maker bot gửi giá mua/bán hai chiều qua `DemoBroker` trong trạng thái `continuous`, tạo thanh khoản nền để lệnh của người dùng có thể được khớp.
- **MVP-004**: Giới hạn MVP: chỉ một bot, chỉ một mã FXS, một phiên ảo mỗi lần chạy; không có ATO/ATC, không clearing, không settlement, không nhiều loại bot.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**:

- **Người quan sát demo**: mở bảng điện để xem thị trường ảo hoạt động; không cần đặt lệnh.
- **Người dùng demo**: đặt và hủy lệnh demo để quan sát hành vi matching với bot.
- **Người vận hành kỹ thuật**: khởi động ngày ảo, theo dõi trạng thái phiên, kiểm tra log bot.

**Bối cảnh sử dụng**: Môi trường local/demo. Người quan sát có thể mở bảng điện ở nhiều tab/trình duyệt cùng lúc. Người dùng demo tương tác trong phiên continuous. Người vận hành khởi động và giám sát phiên ảo.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Từ không chuyên kỹ thuật (người quan sát) đến kỹ thuật (người vận hành); người dùng demo không cần đọc log.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Khởi động ngày ảo và quan sát vòng đời phiên (Ưu tiên: P1)

Người vận hành khởi động ngày ảo với thời lượng đã cấu hình. Hệ thống lần lượt chuyển từ `open` sang `continuous` và cuối cùng sang `close`. Người quan sát trên bảng điện nhìn thấy trạng thái phiên cập nhật theo thời gian thực tại mỗi lần chuyển.

**Lý do ưu tiên**: Vòng đời phiên là nền tảng của toàn bộ MVP 04; không có nó thì bot và WebSocket không có ngữ cảnh để hoạt động đúng.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Khởi động ngày ảo với thời lượng ngắn, quan sát bảng điện chuyển qua đủ ba trạng thái và xác nhận bảng điện nhận cập nhật qua WebSocket mà không tự làm mới.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** cấu hình thời lượng phiên hợp lệ, **Khi** người vận hành khởi động ngày ảo, **Thì** phiên bắt đầu ở trạng thái `open`, chuyển sang `continuous` sau đúng thời lượng `open` và sang `close` sau đúng thời lượng `continuous`.
2. **AC-002**: **Cho trước** client WebSocket đang kết nối, **Khi** phiên chuyển trạng thái, **Thì** client nhận thông báo trạng thái mới trong vòng 3 giây mà không cần tự làm mới trang.
3. **AC-003**: **Cho trước** phiên đã đạt trạng thái `close`, **Khi** người dùng gửi lệnh mới, **Thì** hệ thống từ chối với lý do phiên đã đóng và không thay đổi order book.

---

### US-002 — Quan sát giá realtime qua WebSocket (Ưu tiên: P1)

Người quan sát mở bảng điện ở hai tab trình duyệt. Khi bot đặt lệnh hoặc có lệnh được khớp, cả hai tab thấy order book và trade tape cập nhật ngay lập tức mà không cần bấm làm mới.

**Lý do ưu tiên**: Realtime là điểm phân biệt cốt lõi của MVP 04 so với MVP 03 dùng polling; thiếu nó thì bot và phiên ảo không có giá trị quan sát rõ ràng.

**Liên quan yêu cầu**: FR-004, FR-005

**Test độc lập**: Mở bảng điện ở hai tab, để bot chạy trong `continuous`, quan sát cả hai tab nhận thay đổi order book và giao dịch mới mà không thao tác gì.

**Acceptance Criteria**:

1. **AC-004**: **Cho trước** hai tab bảng điện đang kết nối WebSocket, **Khi** bot đặt lệnh tạo thay đổi order book, **Thì** cả hai tab hiển thị order book mới trong vòng 3 giây.
2. **AC-005**: **Cho trước** lệnh của người dùng được khớp với bot, **Khi** giao dịch xảy ra, **Thì** trade tape trên bảng điện phản ánh giao dịch mới trong vòng 3 giây và giá gần nhất cập nhật đúng.

---

### US-003 — Đặt lệnh khớp với market-maker bot (Ưu tiên: P1)

Trong phiên `continuous`, bot duy trì giá mua/bán hai chiều trên order book. Người dùng chọn tài khoản demo, đặt lệnh đối ứng với một trong hai chiều bot, và quan sát lệnh được khớp, giao dịch xuất hiện trên trade tape.

**Lý do ưu tiên**: Đây là kịch bản demo cốt lõi — người dùng thấy matching hoạt động với một đối tác tự nhiên thay vì phải tự tạo cả hai chiều lệnh.

**Liên quan yêu cầu**: FR-006, FR-007

**Test độc lập**: Để bot chạy trong `continuous`, quan sát giá mua/bán của bot trên order book, đặt lệnh đối ứng và xác nhận khớp lệnh, giao dịch xuất hiện trên trade tape.

**Acceptance Criteria**:

1. **AC-006**: **Cho trước** bot đang duy trì giá mua/bán hai chiều trong `continuous`, **Khi** người dùng đặt lệnh đối ứng giá với bot, **Thì** khớp lệnh xảy ra và bảng điện phản ánh giao dịch và order book mới trong vòng 3 giây.
2. **AC-007**: **Cho trước** phiên đang ở `continuous`, **Khi** bot không có giá đối ứng tại mức người dùng đặt, **Thì** lệnh vào order book chờ và bảng điện hiển thị đúng trạng thái chờ.

---

### US-004 — Quan sát lệnh bị từ chối khi phiên đóng (Ưu tiên: P1)

Khi phiên chuyển sang `close`, người dùng cố đặt lệnh mới và nhận thông báo từ chối rõ ràng. Người quan sát trên bảng điện thấy trạng thái phiên đã đổi và hiểu tại sao lệnh bị chặn.

**Lý do ưu tiên**: Khả năng minh họa "lệnh bị từ chối khi phiên đóng" là một trong ba điều kiện hoàn thành của kịch bản demo MVP 04.

**Liên quan yêu cầu**: FR-003, FR-008

**Test độc lập**: Chờ phiên chuyển sang `close`, thử đặt lệnh mới, xác nhận từ chối với lý do rõ ràng và order book không thay đổi.

**Acceptance Criteria**:

1. **AC-008**: **Cho trước** phiên đang ở `close`, **Khi** người dùng gửi yêu cầu đặt lệnh mới, **Thì** hệ thống từ chối với lý do phiên đã đóng và không thay đổi order book.
2. **AC-009**: **Cho trước** phiên đang ở `open`, **Khi** người dùng gửi yêu cầu đặt lệnh mới, **Thì** hệ thống từ chối với lý do phiên chưa vào giai đoạn giao dịch.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Bảng điện mở trước khi ngày ảo bắt đầu hiển thị trạng thái trống và thông báo phiên chưa khởi động; bot chưa hoạt động.
- **Dữ liệu không hợp lệ**: Lệnh sai quy tắc MVP 01/02 bị từ chối bình thường; lệnh hợp lệ về nghiệp vụ nhưng gửi ngoài `continuous` bị từ chối với lý do phiên.
- **Không có quyền**: Không áp dụng xác thực trong MVP; chỉ hai tài khoản demo và `DemoBroker` được phép thao tác.
- **Lỗi hệ thống**: Nếu WebSocket bị mất, bảng điện hiển thị trạng thái mất kết nối và tự thử kết nối lại; bot không gửi lệnh mới cho đến khi kết nối khôi phục.
- **Timeout**: Lệnh bot timeout không được thử lại tự động trong cùng chu kỳ giá; bot chờ chu kỳ tiếp theo để gửi giá mới.
- **Dữ liệu bị thay đổi bởi người khác**: Client WebSocket nhận bản cập nhật tự động; không có xung đột giữa các client.
- **Người dùng thao tác lặp lại**: Khởi động ngày ảo khi phiên đang chạy bị từ chối; không tạo hai phiên song song. Khi khởi động ngày ảo mới sau phiên đã đóng, order book và trade tape reset về trống, bot về giá tham chiếu ban đầu — mỗi ngày ảo là một kịch bản độc lập.
- **Trường hợp biên khác**: Khi phiên chuyển sang `close`, bot tự hủy lệnh đang chờ của mình trước (graceful); Exchange hủy toàn bộ lệnh còn lại (bao gồm lệnh người dùng) làm backstop. Nếu bot không tự hủy kịp, Exchange vẫn hủy và không để lệnh nào tồn tại qua `close`.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI hỗ trợ vòng đời phiên ảo với ba trạng thái `open`, `continuous`, `close` theo thứ tự tuyến tính, với thời lượng mỗi giai đoạn cấu hình được.
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống PHẢI chỉ chấp nhận lệnh đặt mới trong trạng thái `continuous`; lệnh mới trong `open` và `close` PHẢI bị từ chối với lý do phiên.
  **Liên quan**: US-001, US-004, AC-003, AC-008, AC-009
- **FR-003** `[P1]`: Trạng thái phiên PHẢI được phát qua WebSocket đến tất cả client đang kết nối trong vòng 3 giây kể từ lúc chuyển trạng thái.
  **Liên quan**: US-001, AC-002
- **FR-004** `[P1]`: Hệ thống PHẢI phát qua WebSocket: từng thay đổi của order book (theo mức giá), giao dịch mới và trạng thái phiên đến tất cả client đang kết nối.
  **Liên quan**: US-002, AC-004, AC-005
- **FR-005** `[P1]`: Client WebSocket nhận cập nhật order book và giao dịch mới trong vòng 3 giây kể từ sự kiện và KHÔNG ĐƯỢC cần tải lại trang.
  **Liên quan**: US-002, AC-004, AC-005
- **FR-006** `[P1]`: Market-maker bot PHẢI tự động gửi giá mua và giá bán hai chiều theo chu kỳ trong trạng thái `continuous` bằng cách gửi lệnh qua `DemoBroker`, không gọi matching engine trực tiếp.
  **Liên quan**: US-003, AC-006
- **FR-007** `[P1]`: Lệnh của người dùng đặt đối ứng với bot ở giá thỏa điều kiện PHẢI được khớp theo quy tắc ưu tiên giá-thời gian của Exchange; kết quả phản ánh trên bảng điện realtime.
  **Liên quan**: US-003, AC-006, AC-007
- **FR-008** `[P1]`: Trạng thái `close` PHẢI dừng nhận lệnh mới, KHÔNG ĐƯỢC kích hoạt bất kỳ quy trình clearing hay settlement nào, và PHẢI kích hoạt cơ chế hủy lệnh theo BR-005: bot tự hủy lệnh của mình trước, Exchange hủy toàn bộ lệnh còn lại sau.
  **Liên quan**: US-004, AC-008
- **FR-009** `[P1]`: Hệ thống KHÔNG ĐƯỢC cho phép khởi động hai ngày ảo đồng thời; yêu cầu khởi động khi đã có phiên đang chạy PHẢI bị từ chối. Sau khi phiên kết thúc (`close` hoàn tất), người vận hành PHẢI có thể khởi động ngày ảo mới ngay lập tức mà không cần restart service; ngày ảo mới bắt đầu với order book trống, trade tape trống và bot về giá tham chiếu ban đầu.
  **Liên quan**: US-001
- **FR-010** `[P1]`: Mọi sự kiện từ bot (đặt lệnh, kết quả khớp) PHẢI gắn `BrokerId` của `DemoBroker` và tuân theo hợp đồng sự kiện của MVP 02.
  **Liên quan**: US-003, AC-006
- **FR-011** `[P1]`: Khi một client WebSocket kết nối mới (kể cả giữa phiên đang chạy), server PHẢI gửi ngay một snapshot gồm trạng thái phiên hiện tại, toàn bộ order book hiện tại và N giao dịch gần nhất; sau đó chỉ gửi incremental updates. Client KHÔNG ĐƯỢC phải chờ event tiếp theo mới thấy dữ liệu.
  **Liên quan**: US-002, AC-004

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Vòng đời phiên ảo là tuyến tính một chiều: `open → continuous → close`; không có chuyển ngược, không có vòng lặp trong cùng ngày ảo.
- **BR-002**: Chỉ trạng thái `continuous` chấp nhận lệnh đặt mới; `open` và `close` từ chối lệnh mới với lý do phiên.
- **BR-003**: Bot là nhà đầu tư mô phỏng — phải đi qua `DemoBroker` giống người dùng; không được gọi matching engine trực tiếp.
- **BR-004**: Trạng thái `close` chỉ đóng giao dịch; không kích hoạt clearing, settlement hoặc bất kỳ quy trình sau giao dịch nào.
- **BR-005**: Khi phiên chuyển sang `close`, bot PHẢI tự hủy các lệnh đang chờ của mình trước (graceful cancel); Exchange sau đó hủy toàn bộ lệnh còn lại trong order book — bao gồm lệnh người dùng và mọi lệnh bot chưa được tự hủy (backstop). Không có lệnh nào được tồn tại qua trạng thái `close`. Đây là chuẩn của HOSE/HNX (exchange hủy toàn bộ lệnh cuối ngày) kết hợp với thực hành market maker thật (graceful logout trước, exchange CoD làm lưới an toàn).
- **BR-006**: Bot dùng chiến lược **fixed reference price**: luôn quote bid/ask xung quanh một giá tham chiếu cố định (configurable, không phải last traded price), với spread và chu kỳ gửi là tham số cấu hình. Không hardcode giá tham chiếu, spread hoặc khoảng thời gian. Giá tham chiếu không tự động theo giá giao dịch gần nhất — đây là lựa chọn chủ động để demo dễ dự đoán và kiểm thử được.
- **BR-007**: WebSocket chỉ phát dữ liệu; client không được gửi lệnh qua WebSocket — lệnh vẫn đi qua Exchange API.

**Luồng trạng thái phiên ảo**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| (chưa có) | Khởi động ngày ảo | open | Không có phiên đang chạy |
| open | Hết thời lượng open | continuous | Tự động, theo cấu hình |
| continuous | Hết thời lượng continuous | close | Tự động, theo cấu hình |
| close | Phiên kết thúc | (chưa có) | Kết thúc ngày ảo |
| (chưa có) | Khởi động ngày ảo mới | open | Phiên trước đã kết thúc hoàn toàn |
| (đang chạy: open/continuous) | Yêu cầu khởi động mới | Từ chối | Đã có phiên đang chạy |

---

## 9. Thực thể dữ liệu

- **Phiên giao dịch ảo**: Đại diện cho một ngày ảo với trạng thái hiện tại (`open`, `continuous`, `close`), thời điểm bắt đầu từng giai đoạn và thời lượng cấu hình.
- **Cấu hình bot**: Tham số điều chỉnh hành vi market-maker bot: chu kỳ gửi giá, spread mua/bán và giới hạn khối lượng mỗi lần gửi. Không chứa credential hay token.
- **Sự kiện WebSocket**: Thông điệp phát cho client theo từng loại: `ORDER_BOOK_CHANGED`, `TRADE_EXECUTED`, `SESSION_STATE_CHANGED` — tuân theo hợp đồng sự kiện Exchange.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Người truy cập môi trường demo; không yêu cầu đăng nhập để kết nối WebSocket và xem bảng điện.

**Ai được thao tác**:
- Người dùng demo: đặt và hủy lệnh trong giới hạn hai tài khoản demo.
- Market-maker bot: đặt lệnh qua `DemoBroker` theo cấu hình.
- Người vận hành: khởi động ngày ảo và điều chỉnh cấu hình bot.

**Ai không được phép**:
- Client WebSocket KHÔNG ĐƯỢC gửi lệnh qua kết nối WebSocket.
- Không có vai trò hay tài khoản ngoài phạm vi demo trong MVP.

**Dữ liệu nhạy cảm**:
- Không có dữ liệu nhạy cảm; chỉ dữ liệu giá/lệnh mô phỏng. Bot không chứa credential thật trong cấu hình.

- **SEC-001**: Lệnh bot PHẢI gắn `BrokerId` của `DemoBroker` và không được mang định danh fake của tài khoản người dùng demo.
- **SEC-002**: WebSocket KHÔNG ĐƯỢC phát token, khóa truy cập hoặc thông tin cấu hình nội bộ đến client.
- **SEC-003**: API và WebSocket chỉ được sử dụng trong môi trường demo cục bộ; không được đưa ra môi trường công khai trong MVP này.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Không tạo audit nghiệp vụ riêng cho MVP 04. Lịch sử lệnh bot và giao dịch do Exchange API ghi theo cơ chế sự kiện của MVP 02 là đủ để đối chiếu. Trạng thái phiên được ghi trong log vận hành.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trong điều kiện demo bình thường với một bot và một người dùng, client WebSocket nhận cập nhật order book hoặc giao dịch trong tối đa 3 giây kể từ sự kiện.
- **NFR-002**: Ngày ảo với thời lượng ngắn nhất hợp lệ (ví dụ: 30 giây mỗi giai đoạn) PHẢI chuyển trạng thái đúng thời điểm, sai số không quá 2 giây.
- **NFR-003**: MVP 04 PHẢI vận hành được trên hạ tầng local hiện có mà không làm gián đoạn Exchange API và bảng điện MVP 03.
- **NFR-004**: Bot dừng hoạt động khi phiên chuyển sang `close` mà không làm crash hoặc để lại trạng thái lỗi trong Exchange.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: Demo độc lập Phase A hoàn thành: khởi động ngày ảo, mở bảng điện ở hai trình duyệt, quan sát giá thay đổi realtime mà không tự làm mới trang.
- **SC-002**: Người dùng đặt ít nhất một lệnh khớp với bot trong phiên `continuous` và thấy giao dịch phản ánh trên cả hai tab bảng điện trong vòng 5 giây.
- **SC-003**: 100% lệnh đặt mới trong phiên `close` và `open` bị từ chối với lý do phiên rõ ràng và không thay đổi order book.
- **SC-004**: Phiên ảo hoàn thành đủ chu kỳ `open → continuous → close` đúng cấu hình thời lượng, sai số tối đa 2 giây mỗi giai đoạn.
- **SC-005**: Bot duy trì giá hai chiều liên tục trong `continuous` mà không cần can thiệp thủ công; mọi chu kỳ không gửi được ghi trong log vận hành.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Exchange API (MVP 02) và bảng điện (MVP 03) đã sẵn sàng và hoạt động đúng trong môi trường demo local.
- Bảng điện MVP 03 có thể tích hợp WebSocket thay vì polling mà không cần viết lại toàn bộ UI.
- Người dùng truy cập môi trường local có kết nối ổn định tới Exchange và WebSocket server.
- Chỉ cần một mã FXS, một bot và hai tài khoản demo trong MVP.
- Rule hủy lệnh bot khi phiên đóng sẽ được chốt trước khi lập plan kỹ thuật (xem BR-005 và câu hỏi mở).

**Ràng buộc**:
- Bot PHẢI đi qua `DemoBroker` — không được gọi matching engine trực tiếp; đây là quy tắc thiết kế bất biến của MVP 04.
- Trạng thái `close` KHÔNG ĐƯỢC kích hoạt clearing hay settlement — đây là giới hạn phạm vi không thương lượng.
- Không có ATO/ATC, không có nhiều loại bot, không có CTCK tenant thật trong MVP này.
- Hợp đồng Exchange API và sự kiện của MVP 02 KHÔNG ĐƯỢC bị phá vỡ khi bổ sung WebSocket và phiên ảo.

---

## 15. Ngoài phạm vi

- ATO (đấu giá mở phiên) và ATC (đấu giá đóng phiên).
- Nhiều loại bot (ví dụ: trend-follower, noise trader, arbitrage bot).
- CTCK tenant thật, xác thực, phân quyền đa người dùng.
- Ledger, kiểm tra số dư tiền/chứng khoán, T+, clearing và settlement.
- Lưu trữ bền vững trạng thái phiên và sự kiện WebSocket qua restart.
- Mobile/responsive hoàn chỉnh cho bảng điện.
- Nhiều mã chứng khoán hay nhiều thị trường trong cùng phiên ảo.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|---|---|---|---|
| Độ trễ WebSocket vượt 3 giây trong demo khiến trải nghiệm realtime kém | Trung | Cao | Kiểm thử luồng bot + nhiều client cùng lúc trước khi chốt plan; đặt ngưỡng 3 giây là điều kiện chấp nhận |
| Bot gửi lệnh sai giá hoặc quá nhiều lệnh cùng lúc gây nhiễu order book | Trung | Trung | Cấu hình rõ chu kỳ và spread; test với các tham số biên trước khi demo |
| Bảng điện MVP 03 cần thay đổi lớn để nhận WebSocket thay vì polling | Trung | Trung | Xác nhận khả năng tích hợp với MVP 03 trong phase nghiên cứu trước khi lập plan |
| Phiên chuyển sai thời điểm do clock skew hoặc lỗi timer | Thấp | Cao | Kiểm thử chu kỳ phiên ngắn nhiều lần; so sánh thời điểm chuyển với cấu hình |
| Hành vi bot khi phiên đóng chưa được chốt, gây lệnh orphan | Cao | Trung | Chốt BR-005 trước khi implement; đây là câu hỏi mở bắt buộc giải quyết trước plan |

---

## 17. Phụ thuộc

- Exchange API và matching engine từ MVP 01 (`specs/000010-matching-engine-core/`) và MVP 02 (`specs/000011-exchange-api-events/`).
- Bảng điện từ MVP 03 (`specs/000012-market-board/`) để tích hợp WebSocket realtime.
- Tài liệu nguồn `docs/mvp/04-trading-session-bots.md` và roadmap `docs/mvp/flexsim-roadmap.md`.
- Quyết định về hành vi hủy lệnh bot khi phiên đóng: đã chốt tại BR-005 (xem mục Clarifications).

---

## 18. Câu hỏi mở

Không còn câu hỏi mở chặn plan kỹ thuật. BR-005 đã được chốt (xem mục Clarifications).

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ trong phạm vi demo.
- [x] Ngoài phạm vi đã rõ.
- [x] Câu hỏi BR-005 (hành vi lệnh bot khi đóng phiên) đã được chốt: bot tự hủy lệnh trước (graceful), Exchange hủy toàn bộ lệnh còn lại (backstop).

---

## Clarifications

### Session 2026-07-18

- Q: Khi phiên chuyển sang `close`, lệnh bot đang chờ trong order book xử lý thế nào? → A: Bot tự hủy lệnh của mình trước (graceful cancel); Exchange hủy toàn bộ lệnh còn lại trong order book làm backstop — áp dụng cho cả lệnh người dùng. Không có lệnh nào tồn tại qua trạng thái `close`. Chuẩn này phù hợp với HOSE/HNX (exchange hủy toàn bộ cuối ngày) và thực hành market maker thật (graceful logout + Cancel on Disconnect).
- Q: Bot dùng chiến lược giá nào để duy trì thanh khoản hai chiều? → A: Fixed reference price với spread cấu hình được — bot luôn quote xung quanh một giá tham chiếu cố định, không theo dõi last traded price. Chọn để demo dễ dự đoán và kiểm thử được; phù hợp với cách HOSE/HNX training demo và FIX test environment hoạt động.
- Q: Sau khi phiên kết thúc (`close`), operator có thể khởi động ngày ảo mới mà không cần restart service không? → A: Có — khởi động lại ngay, không cần restart service. FR-009 đã cập nhật để phản ánh điều này.
- Q: Khi khởi động ngày ảo mới, trade tape và order book từ phiên cũ xử lý thế nào? → A: Reset sạch — order book trống, trade tape trống, bot về giá tham chiếu ban đầu. Mỗi ngày ảo là kịch bản độc lập, không kế thừa dữ liệu phiên trước.
- Q: Khi client WebSocket kết nối vào giữa phiên đang chạy, nhận được gì ngay khi kết nối? → A: Server gửi ngay snapshot đầy đủ gồm trạng thái phiên + order book hiện tại + N giao dịch gần nhất; sau đó chỉ gửi delta. Client không phải chờ event tiếp theo. FR-011 mới bổ sung để phản ánh yêu cầu này.
