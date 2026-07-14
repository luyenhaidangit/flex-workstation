# Đặc tả tính năng: Lõi khớp lệnh và order book (FlexSim MVP 01)

**Branch**: `000010-matching-engine-core`  
**Ngày tạo**: 2026-07-14  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Mô tả người dùng: "Review và lên kế hoạch thực hiện cho tôi mvp 1 C:\Workspace\Project\flex-workstation\docs\mvp\01-matching-rules.md"

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 0. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

FlexSim là roadmap 12 MVP mô phỏng hệ sinh thái chứng khoán (sàn ảo → CTCK → giám sát → research). Hiện chưa có bất kỳ thành phần nào của sàn ảo tồn tại. Mọi MVP sau (Exchange API, bảng điện, phiên giao dịch, CTCK) đều phụ thuộc vào một lõi khớp lệnh hoạt động đúng và cho kết quả xác định được. Nếu lõi khớp lệnh không xác định (cùng đầu vào cho ra kết quả khác nhau giữa các lần chạy), toàn bộ test, đối chiếu và demo của các MVP sau sẽ không tin cậy được.

**Tổng quan tính năng**:

Xây dựng lõi Exchange khớp lệnh limit mua/bán cho một mã cổ phiếu giả lập trong phiên khớp lệnh liên tục, với quy tắc ưu tiên giá — thời gian chuẩn. Cùng một tập lệnh đầu vào luôn cho cùng order book và danh sách giao dịch đầu ra. Người hưởng lợi là nhóm phát triển FlexSim: có nền tảng tin cậy để xây MVP 02 trở đi.

---

## 1. Mục tiêu

- **MT-001**: Lõi khớp lệnh cho kết quả xác định: cùng chuỗi lệnh đầu vào luôn sinh ra cùng chuỗi sự kiện và cùng trạng thái order book cuối cùng.
- **MT-002**: Quy tắc khớp lệnh giá — thời gian được kiểm chứng bằng bộ test bao phủ đủ các tình huống: không khớp, khớp toàn phần, khớp một phần, ưu tiên giá, ưu tiên thời gian, hủy lệnh.
- **MT-003**: Kết quả của MVP 01 cung cấp đủ hợp đồng nghiệp vụ (lệnh vào, sự kiện ra, snapshot order book) để MVP 02 xây Exchange API mà không phải sửa lại quy tắc khớp.

---

## 2. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Nhận lệnh limit mua/bán (`PlaceOrder`) và lệnh hủy (`CancelOrder`) từ một `DemoBroker` duy nhất cho một mã cổ phiếu giả lập duy nhất.
- **MVP-002**: Kiểm tra hợp lệ lệnh theo bước giá, biên độ giá và lô chẵn được cấu hình; chấp nhận (`OrderAccepted`) hoặc từ chối (`OrderRejected`) kèm lý do.
- **MVP-003**: Khớp lệnh liên tục theo ưu tiên giá — thời gian, hỗ trợ khớp một phần, phát sự kiện `TradeExecuted`, `OrderCancelled` và cung cấp snapshot order book.
- **MVP-004**: Giới hạn rõ: chỉ một mã, một phiên `continuous`, chỉ limit order; không API, không database, không UI, không WebSocket, không bot, không kiểm tra số dư.

---

## 3. Người dùng & Bối cảnh

**Người dùng chính**: Nhà phát triển FlexSim, đóng vai `DemoBroker` — thành phần giả lập gửi lệnh vào lõi Exchange.

**Bối cảnh sử dụng**: Chạy demo và test cục bộ trong quá trình phát triển; chưa có người dùng cuối hay CTCK thật. Lệnh được đưa vào theo trình tự có kiểm soát để quan sát hành vi khớp.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Kỹ thuật.

---

## 4. Kịch bản người dùng *(bắt buộc)*

### US-001 — Khớp toàn phần hai lệnh đối ứng (Ưu tiên: P1)

`DemoBroker` đặt lệnh bán 100 FXS giá 20.000, sau đó đặt lệnh mua 100 FXS giá 20.000. Hệ thống khớp hai lệnh với nhau, sinh một giao dịch và order book trở về rỗng.

**Lý do ưu tiên**: Đây là luồng khớp cơ bản nhất; nếu không chạy đúng thì không có gì để demo hay xây tiếp.

**Liên quan yêu cầu**: FR-002, FR-005, FR-007, FR-008

**Test độc lập**: Đưa vào đúng hai lệnh trên từ trạng thái order book rỗng và kiểm tra sự kiện, trạng thái lệnh, trạng thái order book.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** order book rỗng, **Khi** đặt bán 100 FXS giá 20.000 rồi đặt mua 100 FXS giá 20.000, **Thì** hệ thống phát đúng một `TradeExecuted` với khối lượng 100 và giá 20.000.
2. **AC-002**: **Cho trước** kịch bản AC-001 đã thực hiện, **Khi** truy vấn snapshot order book, **Thì** order book rỗng và cả hai lệnh ở trạng thái hoàn tất.

---

### US-002 — Khớp một phần và phần còn lại nằm trong sổ (Ưu tiên: P1)

`DemoBroker` đặt bán 100 FXS giá 20.000, sau đó đặt mua 200 FXS giá 20.000. Lệnh bán khớp hết, lệnh mua khớp 100 và 100 còn lại tiếp tục chờ trong order book.

**Lý do ưu tiên**: Khớp một phần là hành vi cốt lõi của khớp lệnh liên tục; các MVP sau (bảng điện, bot) đều dựa vào phần dư nằm sổ.

**Liên quan yêu cầu**: FR-004, FR-005, FR-007, FR-008

**Test độc lập**: Đưa vào hai lệnh trên từ order book rỗng và kiểm tra khối lượng khớp, khối lượng còn lại và snapshot order book.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** order book rỗng, **Khi** đặt bán 100 FXS giá 20.000 rồi đặt mua 200 FXS giá 20.000, **Thì** hệ thống phát một `TradeExecuted` khối lượng 100 giá 20.000; lệnh bán hoàn tất, lệnh mua còn 100 chờ khớp.
2. **AC-004**: **Cho trước** kịch bản AC-003 đã thực hiện, **Khi** truy vấn snapshot order book, **Thì** bên mua có đúng một mức giá 20.000 với khối lượng chờ 100 và bên bán rỗng.

---

### US-003 — Ưu tiên giá và ưu tiên thời gian (Ưu tiên: P1)

`DemoBroker` đặt nhiều lệnh chờ ở các mức giá khác nhau và cùng mức giá ở thời điểm khác nhau. Khi có lệnh đối ứng vào, hệ thống khớp đúng thứ tự: giá tốt hơn trước, cùng giá thì lệnh đến trước khớp trước.

**Lý do ưu tiên**: Ưu tiên giá — thời gian là quy tắc nghiệp vụ trung tâm của MVP này; sai thứ tự khớp là sai nghiệp vụ.

**Liên quan yêu cầu**: FR-002, FR-003, FR-005

**Test độc lập**: Dựng order book có nhiều lệnh chờ với giá/thời điểm khác nhau, đưa một lệnh đối ứng vào và kiểm tra thứ tự các giao dịch sinh ra.

**Acceptance Criteria**:

1. **AC-005**: **Cho trước** hai lệnh bán chờ giá 19.900 và 20.000, **Khi** đặt mua với giá 20.000 đủ khớp một lệnh, **Thì** lệnh bán giá 19.900 được khớp trước với giá khớp 19.900.
2. **AC-006**: **Cho trước** hai lệnh bán chờ cùng giá 20.000 đặt tại hai thời điểm khác nhau, **Khi** đặt mua giá 20.000 đủ khớp một lệnh, **Thì** lệnh bán đặt trước được khớp trước.

---

### US-004 — Hủy lệnh đang chờ (Ưu tiên: P1)

`DemoBroker` hủy một lệnh đang chờ trong order book (bao gồm lệnh đã khớp một phần). Phần khối lượng chưa khớp bị gỡ khỏi sổ và không bao giờ được khớp nữa.

**Lý do ưu tiên**: Hủy lệnh nằm trong điều kiện hoàn thành của MVP và là đầu ra bắt buộc (`OrderCancelled`) cho MVP 02.

**Liên quan yêu cầu**: FR-006, FR-008

**Test độc lập**: Đặt lệnh chờ, hủy nó, rồi đưa lệnh đối ứng vào và xác nhận không có giao dịch nào sinh ra.

**Acceptance Criteria**:

1. **AC-007**: **Cho trước** một lệnh đang chờ trong order book, **Khi** gửi `CancelOrder` cho lệnh đó, **Thì** hệ thống phát `OrderCancelled`, lệnh bị gỡ khỏi snapshot và lệnh đối ứng vào sau không khớp với nó.
2. **AC-008**: **Cho trước** một lệnh đã khớp hết hoặc mã lệnh không tồn tại, **Khi** gửi `CancelOrder`, **Thì** hệ thống từ chối yêu cầu hủy kèm lý do và order book không thay đổi.

---

### US-005 — Từ chối lệnh không hợp lệ (Ưu tiên: P2)

`DemoBroker` gửi lệnh vi phạm bước giá, biên độ giá hoặc lô chẵn. Hệ thống từ chối lệnh kèm lý do rõ ràng và không đưa lệnh vào order book.

**Lý do ưu tiên**: Kiểm tra hợp lệ bảo vệ tính đúng của order book, nhưng có thể test sau khi luồng khớp chính chạy.

**Liên quan yêu cầu**: FR-001

**Test độc lập**: Gửi từng loại lệnh vi phạm từng ràng buộc và kiểm tra phản hồi từ chối cùng trạng thái order book không đổi.

**Acceptance Criteria**:

1. **AC-009**: **Cho trước** cấu hình bước giá, biên độ và lô chẵn của mã FXS, **Khi** gửi lệnh vi phạm bất kỳ ràng buộc nào, **Thì** hệ thống phát `OrderRejected` kèm lý do vi phạm cụ thể và order book không thay đổi.

---

## 5. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Order book rỗng — lệnh mới vào không khớp với ai thì nằm chờ trong sổ; snapshot trả về sổ rỗng, không phải lỗi.
- **Dữ liệu không hợp lệ**: Lệnh sai bước giá/biên độ/lô chẵn, khối lượng ≤ 0, giá ≤ 0, sai mã cổ phiếu hoặc thiếu trường bắt buộc → `OrderRejected` kèm lý do; order book không đổi.
- **Không có quyền**: Không áp dụng — chỉ có một `DemoBroker` giả lập, chưa có mô hình quyền.
- **Lỗi hệ thống**: Nếu xử lý một lệnh thất bại bất thường, lệnh đó không được ghi nhận một phần (không có giao dịch "nửa chừng"); trạng thái order book vẫn nhất quán.
- **Timeout**: Không áp dụng — xử lý trong tiến trình, không có gọi mạng.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng — một nguồn gửi lệnh duy nhất, lệnh được xử lý tuần tự theo thứ tự vào.
- **Người dùng thao tác lặp lại**: Hủy lặp lại cùng một lệnh: lần hủy sau bị từ chối vì lệnh không còn trong sổ (AC-008). Gửi lại lệnh giống hệt: được coi là lệnh mới độc lập.
- **Trường hợp biên khác**: Lệnh mua/bán đối ứng đều thuộc cùng `DemoBroker` vẫn khớp bình thường (chưa có quy tắc chống tự khớp — xem Giả định).

---

## 6. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P2]`: Hệ thống PHẢI kiểm tra lệnh theo bước giá, biên độ giá và lô chẵn cấu hình cho mã; lệnh hợp lệ nhận `OrderAccepted`, lệnh vi phạm nhận `OrderRejected` kèm lý do cụ thể.
  **Liên quan**: US-005, AC-009
- **FR-002** `[P1]`: Hệ thống PHẢI khớp theo ưu tiên giá: bên mua ưu tiên giá đặt cao hơn, bên bán ưu tiên giá đặt thấp hơn.
  **Liên quan**: US-001, US-003, AC-001, AC-005
- **FR-003** `[P1]`: Với các lệnh cùng giá, hệ thống PHẢI ưu tiên lệnh đến trước khớp trước.
  **Liên quan**: US-003, AC-006
- **FR-004** `[P1]`: Hệ thống PHẢI hỗ trợ khớp một phần; phần khối lượng chưa khớp PHẢI nằm lại trong order book cho tới khi được khớp tiếp, bị hủy hoặc hết phiên.
  **Liên quan**: US-002, AC-003, AC-004
- **FR-005** `[P1]`: Giá khớp PHẢI là giá của lệnh đang chờ trong sổ (lệnh đến trước), không phải giá của lệnh mới vào.
  **Liên quan**: US-001, US-002, US-003, AC-001, AC-003, AC-005
- **FR-006** `[P1]`: Hệ thống PHẢI cho phép hủy lệnh còn khối lượng chờ trong sổ và phát `OrderCancelled`; yêu cầu hủy lệnh không tồn tại hoặc đã hoàn tất PHẢI bị từ chối kèm lý do.
  **Liên quan**: US-004, AC-007, AC-008
- **FR-007** `[P1]`: Mỗi lần khớp, hệ thống PHẢI phát sự kiện `TradeExecuted` chứa đủ thông tin đối chiếu: hai lệnh liên quan, giá khớp, khối lượng khớp và thứ tự khớp.
  **Liên quan**: US-001, US-002, AC-001, AC-003
- **FR-008** `[P1]`: Hệ thống PHẢI cung cấp snapshot order book tại bất kỳ thời điểm nào, phản ánh đúng các lệnh đang chờ theo mức giá và thứ tự ưu tiên.
  **Liên quan**: US-001, US-002, US-004, AC-002, AC-004, AC-007
- **FR-009** `[P1]`: Hệ thống PHẢI cho kết quả xác định: cùng một chuỗi lệnh đầu vào (cùng nội dung, cùng thứ tự) PHẢI luôn sinh ra cùng chuỗi sự kiện và cùng trạng thái order book cuối cùng qua mọi lần chạy.
  **Liên quan**: MT-001, SC-002
- **FR-010** `[P1]`: Hệ thống KHÔNG ĐƯỢC phụ thuộc vào API, database, UI, WebSocket, bot hay kiểm tra số dư để thực hiện khớp lệnh trong MVP này.
  **Liên quan**: MVP-004

---

## 7. Quy tắc nghiệp vụ

- **BR-001**: Lệnh chỉ được vào sổ hoặc khớp khi đã qua kiểm tra hợp lệ (bước giá, biên độ, lô chẵn, trường bắt buộc).
- **BR-002**: Thứ tự khớp tuân thủ tuyệt đối ưu tiên giá trước, thời gian sau; không có ngoại lệ trong phiên `continuous`.
- **BR-003**: Giá khớp luôn là giá của lệnh chờ (bên bị động); lệnh mới vào nhận giá của đối phương đang chờ.
- **BR-004**: Lệnh đã hủy hoặc đã hoàn tất không bao giờ được khớp thêm.
- **BR-005**: Mỗi lệnh vào được xử lý trọn vẹn (khớp hết mức có thể rồi phần dư vào sổ) trước khi xử lý lệnh kế tiếp.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| (Mới gửi) | Kiểm tra hợp lệ thất bại | Bị từ chối | Vi phạm bước giá/biên độ/lô chẵn/trường bắt buộc |
| (Mới gửi) | Kiểm tra hợp lệ thành công | Đang chờ hoặc khớp ngay | Có/không có lệnh đối ứng thỏa giá |
| Đang chờ | Khớp một phần | Khớp một phần (vẫn chờ) | Khối lượng đối ứng nhỏ hơn khối lượng chờ |
| Đang chờ / Khớp một phần | Khớp đủ khối lượng còn lại | Hoàn tất | Có lệnh đối ứng đủ khối lượng |
| Đang chờ / Khớp một phần | `CancelOrder` | Đã hủy | Lệnh còn khối lượng chờ trong sổ |
| Hoàn tất / Đã hủy / Bị từ chối | `CancelOrder` | (Không đổi — từ chối hủy) | Lệnh không còn trong sổ |

---

## 8. Thực thể dữ liệu

- **Lệnh (Order)**: Yêu cầu mua/bán gồm mã cổ phiếu, chiều mua/bán, giá, khối lượng, thời điểm gửi và `BrokerId`; có trạng thái vòng đời (chờ, khớp một phần, hoàn tất, đã hủy, bị từ chối) và khối lượng còn lại.
- **Sổ lệnh (Order book)**: Tập lệnh đang chờ của một mã, tổ chức theo hai bên mua/bán, sắp theo ưu tiên giá — thời gian; có thể chụp snapshot.
- **Giao dịch (Trade)**: Kết quả một lần khớp giữa hai lệnh: tham chiếu hai lệnh, giá khớp, khối lượng khớp, thời điểm/thứ tự khớp.
- **Sự kiện lệnh**: `OrderAccepted`, `OrderRejected`, `TradeExecuted`, `OrderCancelled` — dòng đầu ra có thứ tự xác định, là hợp đồng cho MVP 02.
- **Cấu hình mã (Instrument config)**: Bước giá, biên độ giá (trần/sàn), đơn vị lô chẵn của mã cổ phiếu giả lập.

---

## 9. Phân quyền & Bảo mật

**Ai được xem**:
- `DemoBroker` (thành phần giả lập duy nhất) xem được snapshot order book và toàn bộ sự kiện.

**Ai được thao tác**:
- `DemoBroker` được đặt và hủy lệnh. Chưa có phân biệt nhiều broker hay người dùng.

**Ai không được phép**:
- Không áp dụng — MVP chạy cục bộ, không có bề mặt truy cập từ bên ngoài (không API/UI/mạng).

**Dữ liệu nhạy cảm**:
- Không. Toàn bộ dữ liệu là giả lập (mã FXS, tiền ảo); không có dữ liệu cá nhân hay tiền thật.

- **SEC-001**: Mọi lệnh và yêu cầu hủy PHẢI mang `BrokerId`; sự kiện đầu ra PHẢI gắn được về `BrokerId` gửi lệnh, làm nền cho mô hình đa broker ở MVP sau.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC mở bất kỳ bề mặt truy cập mạng nào trong MVP này.

---

## 10. Audit & Lịch sử thay đổi

**Có cần audit không**: Không áp dụng ở mức audit người dùng — chưa có người dùng thật hay thao tác quản trị. Tuy nhiên dòng sự kiện có thứ tự (`OrderAccepted`, `OrderRejected`, `TradeExecuted`, `OrderCancelled`) chính là lịch sử đầy đủ của mọi thay đổi order book và là yêu cầu chức năng (FR-007, FR-009).

---

## 11. Yêu cầu phi chức năng

- **NFR-001**: Tính tái lập: chạy lại cùng một kịch bản lệnh bất kỳ số lần nào PHẢI cho kết quả (sự kiện + order book) giống nhau hoàn toàn, kể cả trên máy khác.
- **NFR-002**: Bộ kịch bản demo trong tài liệu MVP (mục Kịch bản demo) chạy hoàn tất trong vài giây trên máy phát triển thông thường — đủ nhanh để dùng trong vòng lặp test.
- **NFR-003**: Các tham số bước giá, biên độ, lô chẵn PHẢI là cấu hình thay đổi được mà không sửa quy tắc khớp.

---

## 12. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% ba kịch bản demo trong tài liệu MVP 01 chạy đúng như mô tả (một `TradeExecuted`, order book rỗng; khớp một phần với phần dư 100 nằm sổ).
- **SC-002**: Chạy lại cùng một tập lệnh đầu vào 10 lần liên tiếp cho kết quả giống nhau 100% (cùng danh sách giao dịch, cùng order book cuối).
- **SC-003**: Bộ test bao phủ đủ 6 nhóm hành vi bắt buộc — không khớp, khớp toàn phần, khớp một phần, ưu tiên giá, ưu tiên thời gian, hủy lệnh — và toàn bộ đều đạt.
- **SC-004**: MVP 02 có thể bắt đầu chỉ dựa trên các đầu ra đã định nghĩa (`PlaceOrder`, `CancelOrder`, 4 sự kiện, snapshot order book) mà không cần sửa quy tắc khớp của MVP 01.

---

## 13. Giả định & Ràng buộc

**Giả định**:
- Giá trị cụ thể của bước giá, biên độ và lô chẵn cho mã FXS do plan kỹ thuật chọn (ví dụ tham khảo quy tắc HOSE), miễn là cấu hình được (NFR-003).
- Chưa áp dụng quy tắc chống tự khớp (self-match): hai lệnh đối ứng cùng `DemoBroker` vẫn khớp bình thường, vì MVP chỉ có một broker giả lập.
- "Hết phiên" ở MVP này chỉ có nghĩa là kết thúc một lần chạy demo/test; vòng đời phiên giao dịch đầy đủ thuộc MVP 04.
- Thứ tự thời gian của lệnh xác định theo thứ tự lệnh được đưa vào hệ thống (trình tự vào), không phụ thuộc đồng hồ hệ thống.
- Code sản phẩm của MVP 01 nằm trong sub-repo `flex-exchange-service` được khai báo trong `workstation.json` (đã chốt — xem Phụ thuộc).

**Ràng buộc**:
- PHẢI giữ đúng ranh giới scope: không API, database, UI, WebSocket, bot, kiểm tra số dư (FR-010) — các phần này thuộc MVP 02–07.
- Đầu ra PHẢI gồm đủ: `PlaceOrder`, `CancelOrder`, `OrderAccepted`, `OrderRejected`, `TradeExecuted`, `OrderCancelled` và snapshot order book — đây là hợp đồng bắt buộc cho MVP 02.
- Theo constitution workstation, code sản phẩm KHÔNG ĐƯỢC nằm trong `flex-workstation` root.

---

## 14. Ngoài phạm vi

- Exchange API, sự kiện đẩy qua mạng, WebSocket (MVP 02).
- Bảng điện, UI hiển thị (MVP 03).
- Vòng đời phiên (mở/đóng cửa, ATO/ATC), bot tạo thanh khoản (MVP 04).
- Kiểm tra số dư tiền/chứng khoán, kiểm soát trước lệnh (MVP 05+).
- Nhiều broker, đa tenant (MVP 06).
- Loại lệnh khác limit (market, ATO/ATC, stop...).
- Nhiều mã cổ phiếu, nhiều phiên đồng thời.
- Lưu trữ bền vững (database), khôi phục trạng thái sau khi tắt.
- Quy tắc chống tự khớp, sửa lệnh (amend).

---

## 15. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Quy tắc khớp có kẽ hở ở trường hợp biên (khớp xuyên nhiều mức giá, dư khối lượng lẻ) khiến MVP sau phải sửa lõi | Trung | Cao | Bộ test bắt buộc 6 nhóm hành vi (SC-003) + kịch bản khớp xuyên nhiều lệnh chờ trong US-003 |
| Tính không xác định lọt vào (phụ thuộc đồng hồ, thứ tự không ổn định) làm test chập chờn | Trung | Cao | FR-009 và SC-002 là điều kiện hoàn thành; thứ tự thời gian dựa trên trình tự vào |
| Hợp đồng đầu ra thiếu thông tin khiến MVP 02 phải phá vỡ tương thích | Thấp | Trung | SC-004; sự kiện `TradeExecuted` yêu cầu đủ trường đối chiếu (FR-007) |
| Chưa chốt repo đích làm chậm bước plan | Trung | Thấp | Đã xử lý: repo đích `flex-exchange-service` đã được chốt (xem Phụ thuộc) |

---

## 16. Phụ thuộc

- Repo đích chứa code MVP 01: **đã chốt** (2026-07-14) là `flex-exchange-service` (https://github.com/luyenhaidangit/flex-exchange-service), đã khai báo trong `workstation.json`; service dựng theo pattern của `flex-auth-service`.
- Tài liệu nguồn: `docs/mvp/01-matching-rules.md` và `docs/mvp/flexsim-roadmap.md` — spec này bám theo phạm vi đã định ở đó.
- Không phụ thuộc hệ thống/hạ tầng nào khác (chạy cục bộ, không mạng, không database).

---

## 17. Câu hỏi mở

- Không còn câu hỏi mở chặn plan kỹ thuật. Repo đích cho code đã được stakeholder chốt là `flex-exchange-service` (xem Phụ thuộc).

---

## 18. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ hoặc được đánh dấu là câu hỏi mở.
- [x] Ngoài phạm vi đã rõ.
- [x] Các câu hỏi mở quan trọng đã được trả lời hoặc được chấp nhận là rủi ro (repo đích: chốt ở đầu bước plan).
