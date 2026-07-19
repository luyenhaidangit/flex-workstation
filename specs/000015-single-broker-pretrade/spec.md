# Đặc tả tính năng: Một CTCK và kiểm tra trước giao dịch

**Branch**: `000015-single-broker-pretrade`  
**Ngày tạo**: 2026-07-19  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Cho phép nhà đầu tư đặt lệnh thông qua một `DemoBroker`, được kiểm tra sức mua hoặc CK bán trước khi route lên Exchange và theo dõi liên kết giữa lệnh khách hàng với lệnh Exchange.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Luồng giao dịch hiện tại chưa thể hiện ranh giới nghiệp vụ giữa nhà đầu tư, CTCK và Exchange. Vì vậy, một lệnh vượt sức mua hoặc vượt số CK khả dụng có thể đi quá xa trong quy trình trước khi bị phát hiện, đồng thời khó truy vết lệnh khách hàng với lệnh được gửi lên Exchange.

**Tổng quan tính năng**:

Tính năng bổ sung một `DemoBroker` làm điểm tiếp nhận duy nhất của nhà đầu tư. Broker kiểm tra tài khoản và phiên giao dịch trước khi phong tỏa tài sản, route lệnh hợp lệ lên Exchange, nhận kết quả khớp/hủy và giải phóng phần phong tỏa phù hợp. Tính năng phục vụ demo end-to-end của luồng pre-trade với hai khách hàng và tài khoản demo.

---

## 2. Mục tiêu

- **MT-001**: Ngăn 100% lệnh mua vượt sức mua và lệnh bán vượt CK khả dụng trước khi lệnh xuất hiện trên sổ lệnh Exchange.
- **MT-002**: Hoàn tất được luồng đặt lệnh hợp lệ từ khách hàng qua Broker đến Exchange và nhận kết quả khớp/hủy.
- **MT-003**: Có thể truy vết hai chiều giữa lệnh khách hàng và lệnh Exchange trong toàn bộ luồng demo.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Một `DemoBroker`, hai khách hàng demo và tài khoản giao dịch demo tương ứng.
- **MVP-002**: Kiểm tra phiên giao dịch, sức mua dự kiến cho lệnh mua và CK bán khả dụng cho lệnh bán.
- **MVP-003**: Phong tỏa tiền/CK dự kiến trước khi route lệnh hợp lệ và giải phóng phong tỏa theo kết quả khớp/hủy.
- **MVP-004**: Liên kết audit từ lệnh khách hàng đến `ExchangeOrderId` và ngược lại.
- **MVP-005**: Trạng thái số dư đơn giản gồm khả dụng và đang phong tỏa; chỉ phục vụ demo, không đại diện cho ledger kế toán.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Nhà đầu tư demo đặt lệnh; người vận hành hoặc người kiểm thử theo dõi kết quả route và liên kết lệnh.

**Bối cảnh sử dụng**: Trong phiên giao dịch của thị trường mô phỏng, nhà đầu tư gửi lệnh mua/bán thông qua Broker thay vì gửi trực tiếp đến Exchange.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ và người kiểm thử có hiểu biết cơ bản về lệnh, tiền và chứng khoán.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Từ chối lệnh không đủ tài sản tại Broker (Ưu tiên: P1)

Nhà đầu tư gửi lệnh mua vượt sức mua hoặc lệnh bán vượt số CK khả dụng. Broker thông báo lý do từ chối và không route lệnh lên Exchange.

**Lý do ưu tiên**: Đây là giá trị kiểm soát rủi ro cốt lõi của CTCK trước khi lệnh vào thị trường.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-006

**Test độc lập**: Khởi tạo tài khoản với số dư xác định, gửi một lệnh vượt số dư và kiểm tra kết quả Broker cùng sổ lệnh Exchange.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** tài khoản không đủ sức mua, **Khi** khách hàng gửi lệnh mua, **Thì** Broker từ chối với lý do thiếu sức mua và không tạo liên kết tới lệnh Exchange.
2. **AC-002**: **Cho trước** tài khoản không đủ CK khả dụng, **Khi** khách hàng gửi lệnh bán, **Thì** Broker từ chối với lý do thiếu CK và lệnh không xuất hiện trên sổ lệnh Exchange.

### US-002 — Route lệnh hợp lệ qua Broker (Ưu tiên: P1)

Nhà đầu tư gửi lệnh hợp lệ trong phiên. Broker kiểm tra, phong tỏa tài sản dự kiến, route lệnh lên Exchange và hiển thị trạng thái cùng mã liên kết của lệnh.

**Lý do ưu tiên**: Hoàn thiện luồng giao dịch chính từ khách hàng đến Exchange.

**Liên quan yêu cầu**: FR-001, FR-004, FR-005, FR-007

**Test độc lập**: Khởi tạo tài khoản đủ tài sản, gửi lệnh trong phiên hợp lệ và xác nhận lệnh được Exchange tiếp nhận.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** lệnh hợp lệ và phiên cho phép giao dịch, **Khi** Broker tiếp nhận lệnh, **Thì** tài sản dự kiến bị phong tỏa trước khi lệnh được route lên Exchange.
2. **AC-004**: **Cho trước** Exchange tiếp nhận lệnh, **Khi** Broker nhận kết quả, **Thì** người dùng xem được trạng thái lệnh và liên kết giữa lệnh khách hàng với `ExchangeOrderId`.

### US-003 — Cập nhật phong tỏa sau khớp hoặc hủy (Ưu tiên: P1)

Nhà đầu tư theo dõi lệnh đã route. Khi lệnh được khớp hoặc hủy, phần tài sản không còn cần phong tỏa được giải phóng và số dư khả dụng phản ánh trạng thái mới.

**Lý do ưu tiên**: Tránh giữ sai tài sản và bảo đảm trạng thái tài khoản nhất quán trong demo.

**Liên quan yêu cầu**: FR-008, FR-009

**Test độc lập**: Gửi lệnh hợp lệ, mô phỏng kết quả khớp/hủy từ Exchange và đối chiếu số dư khả dụng, phong tỏa.

**Acceptance Criteria**:

1. **AC-005**: **Cho trước** lệnh đang phong tỏa tài sản, **Khi** lệnh được khớp một phần hoặc toàn bộ, **Thì** Broker giữ phần cần thiết cho phần chưa hoàn tất và giải phóng phần đã không còn cần.
2. **AC-006**: **Cho trước** lệnh đang phong tỏa tài sản, **Khi** lệnh bị hủy, **Thì** toàn bộ phần phong tỏa còn lại được giải phóng.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Tài khoản không tồn tại hoặc chưa có số dư thì lệnh bị từ chối và nêu rõ không thể xác định tài sản.
- **Dữ liệu không hợp lệ**: Lệnh thiếu thông tin bắt buộc, khối lượng hoặc giá không hợp lệ bị từ chối trước khi kiểm tra tài sản.
- **Không có quyền**: Khách hàng chỉ được đặt lệnh cho tài khoản của mình; yêu cầu ngoài phạm vi bị từ chối.
- **Lỗi hệ thống**: Nếu Broker hoặc Exchange không thể xử lý, lệnh không được coi là đã route thành công; trạng thái và phong tỏa phải được thể hiện rõ để xử lý lại an toàn.
- **Timeout**: Nếu chưa xác định được Exchange đã nhận lệnh hay chưa, Broker không tạo thêm lệnh trùng khi khách hàng thao tác lại và phải giữ liên kết/trạng thái đang chờ xác nhận.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng trong mô hình hai khách hàng demo; số dư phải được kiểm tra tại thời điểm tiếp nhận lệnh.
- **Người dùng thao tác lặp lại**: Cùng một yêu cầu đặt lệnh không được tạo nhiều lệnh Exchange hoặc phong tỏa trùng.
- **Trường hợp biên khác**: Lệnh gửi ngoài phiên giao dịch bị từ chối và không làm thay đổi số dư hay sổ lệnh Exchange.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Broker PHẢI tiếp nhận lệnh của khách hàng và xác định tài khoản giao dịch tương ứng trước khi xử lý.
- **FR-002** `[P1]`: Broker PHẢI kiểm tra phiên giao dịch trước khi chấp nhận route lệnh.
- **FR-003** `[P1]`: Broker PHẢI từ chối lệnh mua khi giá trị mua dự kiến vượt sức mua của tài khoản.
- **FR-004** `[P1]`: Broker PHẢI từ chối lệnh bán khi khối lượng bán vượt CK khả dụng của tài khoản.
- **FR-005** `[P1]`: Broker PHẢI phong tỏa tiền hoặc CK dự kiến trước khi route lệnh hợp lệ lên Exchange.
- **FR-006** `[P1]`: Broker KHÔNG ĐƯỢC route lệnh bị từ chối lên Exchange hoặc để lệnh đó xuất hiện trên sổ lệnh Exchange.
- **FR-007** `[P1]`: Broker PHẢI lưu và cung cấp liên kết giữa mã lệnh khách hàng và `ExchangeOrderId` khi Exchange tiếp nhận lệnh.
- **FR-008** `[P1]`: Broker PHẢI cập nhật trạng thái lệnh và số tài sản đang phong tỏa theo kết quả khớp từ Exchange.
- **FR-009** `[P1]`: Broker PHẢI giải phóng phần phong tỏa còn lại khi lệnh bị hủy hoặc hoàn tất.
- **FR-010** `[P2]`: Broker PHẢI cung cấp lý do nghiệp vụ khi từ chối lệnh hoặc không thể hoàn tất route.

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Nhà đầu tư chỉ gửi lệnh thông qua `DemoBroker`; không có luồng nhà đầu tư gửi trực tiếp lên Exchange trong phạm vi MVP.
- **BR-002**: Lệnh mua dùng sức mua dự kiến; lệnh bán dùng CK khả dụng tại thời điểm kiểm tra.
- **BR-003**: Tài sản được phong tỏa trước khi route và không được tính lại là khả dụng cho lệnh mới.
- **BR-004**: Kết quả khớp/hủy từ Exchange là căn cứ để giải phóng hoặc duy trì phần phong tỏa tương ứng.
- **BR-005**: Số dư chỉ là trạng thái đơn giản phục vụ demo; không áp dụng double-entry ledger, margin hoặc settlement T+.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Mới tạo | Kiểm tra tại Broker | Bị từ chối | Sai phiên, sai dữ liệu hoặc không đủ tài sản |
| Mới tạo | Kiểm tra tại Broker | Đã phong tỏa | Lệnh hợp lệ |
| Đã phong tỏa | Route lên Exchange | Đã route | Exchange tiếp nhận |
| Đã route | Nhận kết quả khớp | Khớp một phần/hoàn tất | Có giao dịch |
| Đã route | Nhận kết quả hủy | Đã hủy | Lệnh bị hủy hoặc phần còn lại bị hủy |

---

## 9. Thực thể dữ liệu

- **DemoBroker**: CTCK mô phỏng tiếp nhận, kiểm tra, route và theo dõi lệnh của khách hàng.
- **Khách hàng**: Nhà đầu tư demo được gắn với một tài khoản giao dịch.
- **Tài khoản giao dịch**: Trạng thái tiền khả dụng, CK khả dụng và phần đang phong tỏa.
- **Lệnh khách hàng**: Yêu cầu mua/bán do nhà đầu tư gửi tại Broker.
- **Lệnh Exchange**: Lệnh tương ứng được Exchange tiếp nhận, có `ExchangeOrderId`.
- **Liên kết lệnh**: Quan hệ truy vết giữa lệnh khách hàng và lệnh Exchange.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Chủ tài khoản được xem lệnh và số dư của mình.
- Người vận hành/kiểm thử demo được xem trạng thái vận hành và liên kết lệnh trong phạm vi được cấp.

**Ai được thao tác**:
- Khách hàng được đặt lệnh cho tài khoản của mình.
- Người vận hành demo được khởi tạo dữ liệu demo và theo dõi kết quả.

**Ai không được phép**:
- Khách hàng không được đặt lệnh thay cho tài khoản khác.
- Không người dùng nào được route trực tiếp lên Exchange ngoài Broker.

**Dữ liệu nhạy cảm**:
- Có: số dư tiền, số dư CK và lịch sử lệnh phải chỉ hiển thị trong phạm vi tài khoản/người vận hành được cấp quyền.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền sở hữu tài khoản trước khi cho phép đặt lệnh.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho người dùng truy cập số dư hoặc lệnh ngoài phạm vi được cấp quyền.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có.

Hệ thống PHẢI ghi nhận:

- Khách hàng/tài khoản tạo lệnh.
- Kết quả kiểm tra pre-trade và lý do từ chối nếu có.
- Thời điểm phong tỏa, route, khớp và hủy.
- Mã lệnh khách hàng, `ExchangeOrderId` và quan hệ liên kết.
- Thay đổi trạng thái phong tỏa do kết quả Exchange.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trong điều kiện tải demo thông thường, người dùng nhận được kết quả kiểm tra và lý do chấp nhận/từ chối trong vòng 3 giây.
- **NFR-002**: 100% lệnh bị Broker từ chối phải có lý do nghiệp vụ có thể đọc được trong kết quả hiển thị.
- **NFR-003**: Tính năng không làm mất khả năng quan sát trạng thái phiên, sổ lệnh và kết quả giao dịch hiện có.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% kịch bản mua vượt sức mua và bán vượt CK khả dụng bị từ chối tại Broker và không xuất hiện trên sổ lệnh Exchange.
- **SC-002**: 100% lệnh hợp lệ trong kịch bản demo được liên kết với `ExchangeOrderId` sau khi Exchange tiếp nhận.
- **SC-003**: Người kiểm thử hoàn thành luồng đặt lệnh hợp lệ, kiểm tra trạng thái và đối chiếu phong tỏa trong dưới 5 phút.
- **SC-004**: 100% kịch bản khớp/hủy được phản ánh đúng ở trạng thái khả dụng và phong tỏa của tài khoản.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Exchange và phiên giao dịch đã có sẵn luồng tiếp nhận lệnh, khớp/hủy và cung cấp kết quả.
- Có hai khách hàng demo và mỗi khách hàng có một tài khoản giao dịch được nạp dữ liệu ban đầu.
- Chỉ xử lý một mã chứng khoán và các loại lệnh tối thiểu cần cho kịch bản demo.

**Ràng buộc**:
- PHẢI giữ ranh giới nhà đầu tư → Broker → Exchange.
- Số dư chỉ là trạng thái đơn giản; chưa có ledger double-entry, margin, clearing, settlement T+ hoặc custody.
- Spec thuộc workstation; implementation chỉ được thực hiện ở repo con phù hợp sau khi có plan và tasks.

---

## 15. Ngoài phạm vi

- Multi-tenant broker hoặc nhiều CTCK.
- Double-entry ledger, margin, buying power nâng cao và quản lý tài sản phái sinh.
- Clearing, settlement T+, custody, reconciliation và corporate actions.
- Tài khoản thật, onboarding/KYC và phân quyền sản phẩm đầy đủ.
- Nhiều mã chứng khoán, nhiều thị trường hoặc các loại lệnh nâng cao.
- Tối ưu hiệu năng tải production và mô hình giám sát rủi ro production.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|--------|-----------|
| Kết quả Exchange đến trễ hoặc không rõ trạng thái | Trung | Cao | Duy trì trạng thái chờ xác nhận và liên kết lệnh, không tạo route trùng |
| Phong tỏa không được giải phóng đúng sau khớp/hủy | Trung | Cao | Kiểm thử độc lập từng trạng thái khớp một phần, khớp toàn bộ và hủy |
| Phạm vi demo bị hiểu thành ledger/settlement đầy đủ | Trung | Trung | Giữ rõ ngoài phạm vi và giới hạn số dư đơn giản trong plan/tasks |

---

## 17. Phụ thuộc

- Exchange phải cung cấp khả năng tiếp nhận lệnh và trả kết quả khớp/hủy.
- Phiên giao dịch và sổ lệnh của MVP trước phải xác định được trạng thái nhận lệnh.
- Dữ liệu demo phải có hai khách hàng, tài khoản, tiền khả dụng và CK khả dụng.

---

## 18. Câu hỏi mở

- Không có câu hỏi mở chặn phạm vi MVP; các quyết định chi tiết về contract và mô hình trạng thái sẽ được xác định trong plan kỹ thuật.

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
