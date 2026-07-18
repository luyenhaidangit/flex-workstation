# Đặc tả tính năng: Exchange API và nhật ký sự kiện (FlexSim MVP 02)

**Branch**: `000011-exchange-api-events`  
**Ngày tạo**: 2026-07-18  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Đưa matching engine của MVP 01 thành dịch vụ có thể gọi, quan sát và replay ở mức cơ bản thông qua API và nhật ký sự kiện có thứ tự.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

MVP 01 đã có lõi khớp lệnh và order book xác định, nhưng Gateway hoặc người vận hành chưa có một hợp đồng dịch vụ hoàn chỉnh để gửi lệnh, theo dõi trạng thái cuối của từng lệnh và đối chiếu các giao dịch đã sinh ra. Khi một lệnh bị từ chối hoặc khớp một phần, việc chẩn đoán kết quả theo từng lệnh còn khó và không có đủ dấu vết để replay một luồng yêu cầu.

**Tổng quan tính năng**:

MVP 02 cung cấp bề mặt dịch vụ cho Gateway gửi lệnh, hủy lệnh, xem trạng thái lệnh, order book, trade tape và lịch sử sự kiện. Mỗi yêu cầu mang `BrokerId`; hệ thống trả kết quả nghiệp vụ rõ ràng và ghi các sự kiện có thứ tự, có thể truy về lệnh và yêu cầu đã tạo ra chúng. Tính năng phục vụ Gateway demo và người vận hành kỹ thuật, chưa phục vụ khách hàng hoặc tiền/chứng khoán thật.

---

## 2. Mục tiêu

- **MT-001**: Gateway hoàn thành được luồng gửi hai lệnh đối ứng, nhận định danh lệnh, xem kết quả khớp và trạng thái cuối của từng lệnh mà không cần truy cập nội bộ của Exchange.
- **MT-002**: Người vận hành có thể đối chiếu một lệnh hoặc giao dịch với chuỗi sự kiện đúng thứ tự và yêu cầu đã khởi tạo nó.
- **MT-003**: Yêu cầu lỗi hoặc bị từ chối không làm thay đổi order book hay tạo giao dịch ngoài sự kiện từ chối tương ứng.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Gateway gửi được yêu cầu đặt lệnh và hủy lệnh, mỗi yêu cầu bắt buộc có `BrokerId`, và nhận kết quả chấp nhận hoặc từ chối có lý do.
- **MVP-002**: Gateway xem được trạng thái theo `OrderId`, snapshot order book, trade tape và lịch sử sự kiện liên quan tới lệnh.
- **MVP-003**: Mọi sự kiện lệnh/giao dịch có định danh, thứ tự, thời điểm, `OrderId` khi có, `BrokerId` và correlation id để đối chiếu/replay yêu cầu.
- **MVP-004**: Giữ nguyên các quy tắc khớp, ưu tiên giá-thời gian và tính xác định đã chốt ở MVP 01.
- **MVP-005**: Giới hạn MVP: chỉ một `DemoBroker`, dữ liệu giả lập trong phiên chạy; không xác thực người dùng, database nghiệp vụ, UI, realtime push, kiểm tra số dư tiền/chứng khoán hay giao dịch thật.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**:

- **Gateway demo**: thành phần gửi lệnh và đọc kết quả từ Exchange.
- **Người vận hành kỹ thuật**: kiểm tra order book, trạng thái lệnh, trade tape và lịch sử sự kiện khi demo hoặc xử lý lỗi.

**Bối cảnh sử dụng**: Gateway gửi yêu cầu giao dịch trong luồng demo; người vận hành tra cứu kết quả ngay sau đó để xác nhận hành vi Exchange và tái dựng thứ tự xử lý khi cần.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng kỹ thuật, hiểu nghiệp vụ lệnh chứng khoán mô phỏng.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Gửi lệnh và nhận kết quả nghiệp vụ (Ưu tiên: P1)

Gateway gửi một lệnh mua hoặc bán kèm `BrokerId`. Exchange áp dụng toàn bộ quy tắc MVP 01, trả định danh lệnh khi được chấp nhận hoặc lý do khi bị từ chối; nếu có đối ứng, Gateway nhận được thông tin giao dịch sinh ra.

**Lý do ưu tiên**: Đây là cửa vào cần thiết để matching engine tạo giá trị cho thành phần bên ngoài.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004

**Test độc lập**: Gửi một lệnh hợp lệ và một lệnh sai quy tắc; xác nhận lệnh hợp lệ có `OrderId`, lệnh sai có lý do từ chối, và order book chỉ đổi theo lệnh hợp lệ.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** một yêu cầu đặt lệnh hợp lệ có `BrokerId`, **Khi** Gateway gửi lệnh, **Thì** Gateway nhận được kết quả chấp nhận với `OrderId` và trạng thái hiện tại của lệnh.
2. **AC-002**: **Cho trước** một yêu cầu vi phạm quy tắc giao dịch, **Khi** Gateway gửi lệnh, **Thì** Gateway nhận được lý do từ chối cụ thể và order book không thay đổi.
3. **AC-003**: **Cho trước** một lệnh đối ứng đang chờ, **Khi** Gateway gửi lệnh thỏa điều kiện khớp, **Thì** kết quả cho biết các giao dịch được sinh ra và trạng thái của lệnh phản ánh phần đã khớp.

---

### US-002 — Hủy và tra cứu trạng thái lệnh (Ưu tiên: P1)

Gateway hủy một lệnh còn chờ bằng `OrderId` và `BrokerId`, rồi tra cứu lại để biết lệnh đã hủy hay không. Người vận hành cũng có thể xem trạng thái của lệnh đã khớp, bị từ chối hoặc không tồn tại.

**Lý do ưu tiên**: Gateway cần kết thúc hoặc kiểm tra vòng đời của một lệnh mà không suy đoán từ order book tổng hợp.

**Liên quan yêu cầu**: FR-005, FR-006, FR-007

**Test độc lập**: Đặt một lệnh chưa khớp, hủy bằng đúng `BrokerId`, tra cứu `OrderId`; sau đó hủy lại và xác nhận hệ thống từ chối mà không đổi trạng thái.

**Acceptance Criteria**:

1. **AC-004**: **Cho trước** một lệnh còn chờ thuộc `BrokerId`, **Khi** Gateway yêu cầu hủy, **Thì** trạng thái lệnh chuyển thành đã hủy và lệnh không còn xuất hiện trong order book.
2. **AC-005**: **Cho trước** `OrderId` đã hủy, đã hoàn tất hoặc không tồn tại, **Khi** Gateway yêu cầu hủy, **Thì** hệ thống từ chối với lý do rõ ràng và không tạo giao dịch mới.
3. **AC-006**: **Cho trước** một `OrderId` hợp lệ, **Khi** Gateway hoặc người vận hành tra cứu, **Thì** nhận được trạng thái hiện tại và thông tin nhận diện của đúng lệnh đó.

---

### US-003 — Đối chiếu order book, trade tape và sự kiện (Ưu tiên: P1)

Sau khi gửi lệnh, người vận hành xem snapshot order book, các giao dịch đã thực hiện và lịch sử sự kiện của từng lệnh. Các bản ghi thể hiện thứ tự xử lý và liên kết về `BrokerId` cùng correlation id của yêu cầu đã khởi tạo.

**Lý do ưu tiên**: Khả năng quan sát và replay cơ bản là mục tiêu trung tâm của MVP 02; không có nó, Gateway không thể đối chiếu kết quả một cách đáng tin cậy.

**Liên quan yêu cầu**: FR-008, FR-009, FR-010, FR-011

**Test độc lập**: Gửi hai lệnh đối ứng, ghi lại hai `OrderId`, rồi xem trade tape và lịch sử từng lệnh; xác nhận có sự kiện chấp nhận và giao dịch đúng thứ tự, liên kết được với hai lệnh và yêu cầu ban đầu.

**Acceptance Criteria**:

1. **AC-007**: **Cho trước** các lệnh đã được xử lý, **Khi** người vận hành xem order book, **Thì** snapshot chỉ chứa các lệnh còn chờ và phản ánh đúng khối lượng còn lại.
2. **AC-008**: **Cho trước** một hoặc nhiều giao dịch đã khớp, **Khi** người vận hành xem trade tape, **Thì** từng giao dịch cho biết hai lệnh liên quan, giá, khối lượng và thứ tự thực hiện.
3. **AC-009**: **Cho trước** một `OrderId` đã được Exchange xử lý, **Khi** người vận hành xem lịch sử sự kiện của lệnh, **Thì** các sự kiện có thứ tự tăng dần, định danh duy nhất, thời điểm, `BrokerId` và correlation id tương ứng.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Khi chưa có lệnh hoặc giao dịch, order book, trade tape và lịch sử tra cứu trả trạng thái trống rõ ràng.
- **Dữ liệu không hợp lệ**: Thiếu `BrokerId`, dữ liệu lệnh sai quy tắc MVP 01 hoặc định danh lệnh không hợp lệ bị từ chối kèm lý do; không có thay đổi order book.
- **Không có quyền**: Không áp dụng trong MVP này vì chỉ có `DemoBroker` và chưa có xác thực; service không được triển khai công khai trước khi có mô hình quyền.
- **Lỗi hệ thống**: Gateway nhận thông báo lỗi an toàn, có correlation id để người vận hành tra cứu; không khẳng định lệnh đã được xử lý thành công khi kết quả chưa xác định.
- **Timeout**: Gateway có thể dùng correlation id để đối chiếu lịch sử trước khi gửi lại; hành vi chống gửi trùng đầy đủ không thuộc MVP này.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng; MVP chỉ có một `DemoBroker` và Exchange xử lý lệnh theo thứ tự nhận.
- **Người dùng thao tác lặp lại**: Hủy lại lệnh không còn chờ bị từ chối, không đổi trạng thái; gửi lại yêu cầu đặt lệnh được coi là lệnh mới độc lập.
- **Trường hợp biên khác**: Lệnh bị từ chối vẫn có lịch sử sự kiện từ chối để đối chiếu nhưng không có `OrderId` nếu lệnh chưa được nhận vào Exchange.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI cho Gateway đặt lệnh mua/bán với `BrokerId` và trả kết quả chấp nhận hoặc từ chối theo các quy tắc MVP 01.  
  **Liên quan**: US-001, AC-001, AC-002
- **FR-002** `[P1]`: Kết quả chấp nhận PHẢI chứa `OrderId` và trạng thái lệnh; kết quả từ chối PHẢI chứa lý do nghiệp vụ cụ thể.  
  **Liên quan**: US-001, AC-001, AC-002
- **FR-003** `[P1]`: Khi một lệnh tạo giao dịch, hệ thống PHẢI trả hoặc cho phép tra cứu các giao dịch sinh ra cùng trạng thái khớp của lệnh.  
  **Liên quan**: US-001, AC-003
- **FR-004** `[P1]`: Hệ thống KHÔNG ĐƯỢC thay đổi order book hoặc tạo giao dịch từ yêu cầu đặt lệnh bị từ chối.  
  **Liên quan**: US-001, AC-002
- **FR-005** `[P1]`: Hệ thống PHẢI cho Gateway hủy lệnh còn chờ bằng `OrderId` và `BrokerId`.  
  **Liên quan**: US-002, AC-004
- **FR-006** `[P1]`: Hệ thống PHẢI từ chối yêu cầu hủy lệnh đã hoàn tất, đã hủy, không tồn tại hoặc không thuộc `BrokerId` cung cấp, và không được làm thay đổi trạng thái lệnh.  
  **Liên quan**: US-002, AC-005
- **FR-007** `[P1]`: Hệ thống PHẢI cho phép tra cứu trạng thái và thông tin nhận diện của một lệnh theo `OrderId`.  
  **Liên quan**: US-002, AC-006
- **FR-008** `[P1]`: Hệ thống PHẢI cung cấp snapshot order book chỉ gồm các lệnh còn chờ, phản ánh giá, khối lượng còn lại và thứ tự ưu tiên.  
  **Liên quan**: US-003, AC-007
- **FR-009** `[P1]`: Hệ thống PHẢI cung cấp trade tape có thể đối chiếu từng giao dịch với hai lệnh, giá, khối lượng và thứ tự thực hiện.  
  **Liên quan**: US-003, AC-008
- **FR-010** `[P1]`: Hệ thống PHẢI ghi và cho phép tra cứu lịch sử sự kiện theo lệnh; mọi sự kiện PHẢI có định danh duy nhất, thứ tự, thời điểm, `BrokerId`, correlation id và `OrderId` khi áp dụng.  
  **Liên quan**: US-003, AC-009
- **FR-011** `[P1]`: Với cùng chuỗi yêu cầu theo cùng thứ tự, hệ thống PHẢI tạo cùng thứ tự sự kiện, trạng thái lệnh, order book và trade tape qua các lần chạy.  
  **Liên quan**: US-003, AC-007, AC-008, AC-009

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Mọi yêu cầu đặt/hủy lệnh bắt buộc có `BrokerId`; `BrokerId` là thông tin truy vết của lệnh và sự kiện, không phải cơ chế xác thực trong MVP này.
- **BR-002**: Quy tắc kiểm tra lệnh, khớp, ưu tiên giá-thời gian và vòng đời lệnh của MVP 01 tiếp tục là nguồn sự thật; MVP 02 không được thay đổi chúng.
- **BR-003**: Sự kiện được ghi theo thứ tự xử lý thực tế; giao dịch chỉ được xuất hiện sau khi các lệnh liên quan được chấp nhận.
- **BR-004**: Một yêu cầu bị từ chối chỉ tạo dấu vết từ chối; không tạo lệnh đang chờ, không tạo giao dịch và không sửa snapshot order book.
- **BR-005**: Correlation id liên kết tất cả sự kiện phát sinh từ cùng một yêu cầu; nếu Gateway không cung cấp, Exchange phải có một định danh để đối chiếu yêu cầu đó.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Mới gửi | Đặt lệnh không hợp lệ | Bị từ chối | Vi phạm quy tắc MVP 01 hoặc thiếu `BrokerId` |
| Mới gửi | Đặt lệnh hợp lệ | Đang chờ / Khớp một phần / Hoàn tất | Có hoặc không có lệnh đối ứng |
| Đang chờ / Khớp một phần | Hủy đúng `BrokerId` | Đã hủy | Lệnh còn khối lượng chờ |
| Đang chờ / Khớp một phần | Khớp phần còn lại | Khớp một phần / Hoàn tất | Có lệnh đối ứng thỏa điều kiện |
| Hoàn tất / Đã hủy / Bị từ chối | Yêu cầu hủy | Không đổi | Lệnh không còn có thể hủy |

---

## 9. Thực thể dữ liệu

- **Lệnh (Order)**: Đơn mua/bán do `BrokerId` gửi, có `OrderId`, thông tin giao dịch, trạng thái, khối lượng còn lại và lịch sử sự kiện liên quan.
- **Giao dịch (Trade)**: Kết quả khớp giữa hai lệnh, ghi nhận giá, khối lượng và thứ tự thực hiện để tạo trade tape.
- **Sự kiện Exchange**: Dấu vết bất biến của việc chấp nhận, từ chối, khớp hoặc hủy lệnh; liên kết tới lệnh khi áp dụng, `BrokerId` và correlation id của yêu cầu.
- **Snapshot order book**: Ảnh chụp các lệnh còn chờ theo hai phía và mức giá tại thời điểm truy vấn.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- `DemoBroker` và người vận hành kỹ thuật trong môi trường demo cục bộ xem được order book, trade tape, trạng thái lệnh và sự kiện.

**Ai được thao tác**:
- `DemoBroker` được đặt và hủy lệnh mang `BrokerId` của mình.

**Ai không được phép**:
- Không có người dùng hoặc broker ngoài phạm vi demo. Service không được đưa ra môi trường công khai trước khi có xác thực và phân quyền ở MVP sau.

**Dữ liệu nhạy cảm**:
- Không áp dụng; chỉ dùng dữ liệu mô phỏng và không chứa tiền, chứng khoán thật hoặc dữ liệu cá nhân.

- **SEC-001**: Mọi yêu cầu đặt/hủy và sự kiện liên quan PHẢI gắn `BrokerId` để có thể đối chiếu nguồn gửi.
- **SEC-002**: Correlation id và dữ liệu chẩn đoán không được chứa token, khóa truy cập hoặc dữ liệu nhạy cảm.
- **SEC-003**: API chưa xác thực chỉ được sử dụng trong môi trường demo cục bộ.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có, ở mức nhật ký nghiệp vụ Exchange cho MVP này.

Hệ thống PHẢI ghi nhận:

- `BrokerId` đã gửi yêu cầu
- Thao tác đặt hoặc hủy lệnh và kết quả chấp nhận/từ chối
- Thời điểm và thứ tự xử lý
- `OrderId` và giao dịch liên quan khi áp dụng
- Correlation id để đối chiếu yêu cầu

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trong kịch bản demo hai lệnh đối ứng, Gateway có thể hoàn tất gửi lệnh và tra cứu trạng thái, trade tape cùng lịch sử sự kiện trong không quá 5 giây, không tính thời gian khởi động service.
- **NFR-002**: Chạy lại cùng một kịch bản lệnh ít nhất hai lần sau khi khởi động lại service phải cho kết quả nghiệp vụ và thứ tự sự kiện giống nhau 100%.
- **NFR-003**: Mọi lỗi bất ngờ trả về cho Gateway phải có correlation id để người vận hành đối chiếu, đồng thời không lộ thông tin nhạy cảm hoặc chi tiết nội bộ.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% kịch bản demo gửi hai lệnh đối ứng có thể truy được hai `OrderId`, ít nhất một giao dịch và trạng thái cuối của cả hai lệnh trong một lần chạy.
- **SC-002**: 100% yêu cầu đặt lệnh không hợp lệ trong bộ kịch bản chuẩn bị từ chối với lý do và không thay đổi order book hay trade tape.
- **SC-003**: Người vận hành đối chiếu được 100% sự kiện của một lệnh demo với `BrokerId`, correlation id và thứ tự xử lý trong tối đa 1 phút.
- **SC-004**: Chạy lại cùng một bộ kịch bản hai lần liên tiếp cho kết quả trạng thái, trade tape và chuỗi sự kiện giống nhau 100%.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Matching engine và các quy tắc MVP 01 đã hoàn thành, là nền tảng không thay đổi cho MVP 02.
- Gateway demo có thể lưu `OrderId` và correlation id để thực hiện các truy vấn đối chiếu.
- Mỗi lần chạy service dùng dữ liệu mô phỏng mới; lưu trữ bền vững không thuộc phạm vi.

**Ràng buộc**:
- Repo triển khai là `flex-exchange-service`, được khai báo trong `workstation.json`.
- Chỉ có một mã mô phỏng và `DemoBroker`; không hỗ trợ nhiều broker, đa tenant hoặc tài khoản khách hàng.
- Hợp đồng hiện có của MVP 01 không được phá vỡ khi bổ sung khả năng MVP 02.

---

## 15. Ngoài phạm vi

- UI/bảng điện, WebSocket hoặc cơ chế đẩy sự kiện realtime.
- Database nghiệp vụ, lưu/khôi phục trạng thái hay event store bền vững.
- Xác thực, phân quyền, quản lý khách hàng, nhiều broker hoặc đa tenant.
- Kiểm tra số dư tiền/chứng khoán, margin, settlement và kết nối với sàn thật.
- Chống gửi trùng/idempotency đầy đủ cho yêu cầu đặt lệnh sau timeout.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Hợp đồng mới làm sai lệch quy tắc hoặc tính xác định của MVP 01 | Trung | Cao | Dùng kịch bản lệnh chuẩn để so sánh trạng thái, trade tape và sự kiện qua nhiều lần chạy. |
| Correlation id thiếu hoặc không nhất quán làm không thể đối chiếu lỗi | Trung | Trung | Xác định rõ quy tắc liên kết yêu cầu-sự kiện và kiểm thử luồng thành công/lỗi. |
| API demo chưa có xác thực bị sử dụng ngoài môi trường an toàn | Thấp | Cao | Ràng buộc chỉ chạy local; xác thực/phân quyền là điều kiện bắt buộc trước khi công khai. |
| Tra cứu theo lệnh thiếu dữ liệu cần thiết cho Gateway | Trung | Trung | Kịch bản demo bắt buộc đối chiếu đủ trạng thái lệnh, trade và lịch sử sự kiện. |

---

## 17. Phụ thuộc

- Spec và implementation MVP 01 tại `specs/000010-matching-engine-core/` và repo `flex-exchange-service`.
- Tài liệu nguồn `docs/mvp/02-exchange-api-events.md` và roadmap `docs/mvp/flexsim-roadmap.md`.
- Không phụ thuộc service, database hoặc broker bên ngoài trong MVP này.

---

## 18. Câu hỏi mở

- Không còn câu hỏi mở chặn lập plan kỹ thuật.

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ hoặc được đánh dấu là câu hỏi mở.
- [x] Ngoài phạm vi đã rõ.
- [x] Các câu hỏi mở quan trọng đã được trả lời hoặc được chấp nhận là rủi ro.
