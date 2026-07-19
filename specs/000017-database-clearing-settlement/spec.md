# Đặc tả tính năng: Nền dữ liệu bền vững từ MVP 01 đến MVP 08

**Branch**: `000017-database-clearing-settlement`  
**Ngày tạo**: 2026-07-19  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Xây dựng nền dữ liệu nghiệp vụ có thể phục hồi theo lộ trình MVP 01–08, bắt đầu từ order/trade của MVP 01 và mở rộng tuần tự đến broker, ledger, clearing, settlement và đối chiếu.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

MVP 01–07 hiện tạo dữ liệu nghiệp vụ trong bộ nhớ, nên order, trade, số dư, reservation và trạng thái vận hành bị mất khi service dừng. Nếu MVP 08 chỉ tạo dữ liệu ledger/settlement riêng lẻ, dữ liệu đó không có nguồn order/trade bền vững của các MVP trước, không thể truy vết xuyên vòng đời và tạo ra ranh giới dữ liệu sai theo timeline sản phẩm.

**Tổng quan tính năng**:

Tính năng cung cấp nền dữ liệu bền vững cho các dữ liệu nghiệp vụ đã xuất hiện từ MVP 01 đến MVP 08. Nhân viên vận hành và các service có thể khởi tạo dữ liệu demo, khôi phục trạng thái nghiệp vụ, truy vết từ lệnh tới giao dịch, tài khoản, ledger và settlement; dữ liệu của bước sau luôn tham chiếu dữ liệu của bước trước.

---

## 2. Mục tiêu

- **MT-001**: Các order và trade được tạo từ MVP 01 có thể được lưu, khôi phục và truy vết nhất quán trước khi dùng cho nghiệp vụ sau giao dịch.
- **MT-002**: Dữ liệu broker, account, reservation, ledger, settlement và reconciliation nối tiếp đúng vòng đời nghiệp vụ đã được xác định ở MVP 01–08.
- **MT-003**: Người vận hành có thể xác nhận dữ liệu demo được khởi tạo, di chuyển và khôi phục an toàn mà không làm phát sinh bản ghi nghiệp vụ trùng.
- **MT-004**: Dữ liệu nghiệp vụ nhạy cảm được giới hạn trong phạm vi tenant/broker được cấp quyền.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Lưu được dữ liệu tham chiếu giao dịch, order, lịch sử thay đổi order và trade của MVP 01–04; trạng thái khôi phục được phải phản ánh đúng thứ tự nghiệp vụ.
- **MVP-002**: Lưu được broker, khách hàng, tài khoản giao dịch, số dư nghiệp vụ và reservation của MVP 05–06; các dữ liệu này liên kết được tới order/trade nguồn.
- **MVP-003**: Lưu được journal/entry/balance, inbox/outbox/audit và các dữ liệu clearing, settlement, statement, reconciliation của MVP 07–08; chúng tham chiếu được order, trade và account trước đó.
- **MVP-004**: Khởi tạo dữ liệu demo Alpha/Beta lặp lại an toàn, kiểm tra được trạng thái dữ liệu và khôi phục một tenant trong staging.
- **MVP-005**: Cung cấp khả năng truy vết nghiệp vụ từ order hoặc trade tới account, ledger, nghĩa vụ settlement và kết quả đối chiếu trong đúng phạm vi được cấp quyền.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**:

- Nhân viên vận hành broker kiểm tra order, trade, account, settlement và chênh lệch cuối ngày.
- Quản trị viên nền tảng khởi tạo, kiểm tra và khôi phục dữ liệu tenant được ủy quyền.
- Các service Exchange/Broker sử dụng dữ liệu bền vững trong các luồng MVP 01–08.

**Bối cảnh sử dụng**: Khi service được khởi động lại, khi cần chạy demo nhiều bước theo lộ trình MVP, khi vận hành settlement/reconciliation hoặc điều tra dữ liệu chênh lệch.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Nhân viên vận hành nghiệp vụ và quản trị viên kỹ thuật.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Khôi phục lõi giao dịch MVP 01–04 (Ưu tiên: P1)

Sau khi service khởi động lại, nhân viên vận hành có thể xem lại dữ liệu tham chiếu, order, trade và trạng thái phiên/snapshot cần thiết để tiếp tục hoặc kiểm tra luồng giao dịch demo mà không mất thứ tự nghiệp vụ.

**Lý do ưu tiên**: Order/trade là nguồn của broker, reservation, ledger và settlement; không có chúng thì dữ liệu MVP sau không thể truy vết đúng.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Tạo order/trade theo kịch bản MVP 01, khởi động lại service và xác nhận order/trade được khôi phục cùng thứ tự, tham chiếu và trạng thái nghiệp vụ.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** một chuỗi order hợp lệ có trade, **Khi** trạng thái được khôi phục, **Thì** order, trade và thứ tự nghiệp vụ vẫn truy được như trước khi dừng service.
2. **AC-002**: **Cho trước** một order bị hủy hoặc hoàn tất, **Khi** trạng thái được khôi phục, **Thì** order đó không xuất hiện như một order đang chờ.

---

### US-002 — Vận hành broker và kiểm soát trước lệnh bền vững (Ưu tiên: P1)

Nhân viên vận hành có thể tra tài khoản, số dư và reservation của broker/khách hàng sau khi khởi động lại; một reservation gắn được với order nguồn và không bị tạo trùng khi yêu cầu được xử lý lại.

**Lý do ưu tiên**: Dữ liệu tài khoản và reservation là cầu nối giữa trade và ledger.

**Liên quan yêu cầu**: FR-004, FR-005, FR-006

**Test độc lập**: Tạo account và reservation từ order demo, khởi động lại, truy vấn account/reservation và gửi lại cùng yêu cầu để xác nhận không có reservation trùng.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** account có tiền/chứng khoán và order hợp lệ, **Khi** reservation được tạo, **Thì** reservation liên kết được tới account và order nguồn.
2. **AC-004**: **Cho trước** cùng yêu cầu reservation được xử lý lại, **Khi** người vận hành kiểm tra account, **Thì** không có khoản giữ chỗ hoặc số dư nghiệp vụ trùng.

---

### US-003 — Ghi nhận ledger và settlement theo nguồn giao dịch (Ưu tiên: P1)

Khi trade đã khớp, hệ thống ghi ledger cân bằng, tạo nghĩa vụ thanh toán và chỉ chuyển sang khả dụng khi hoàn tất chu kỳ T+. Nhân viên vận hành truy vết được chuỗi order/trade/account/ledger/obligation trong đúng tenant.

**Lý do ưu tiên**: Đây là giá trị liên kết giữa dữ liệu giao dịch nền và MVP 07–08.

**Liên quan yêu cầu**: FR-007, FR-008, FR-009, FR-010

**Test độc lập**: Tạo trade từ dữ liệu MVP 01, ghi ledger, chạy cycle T+ và xác nhận journal, balance, obligation cùng tham chiếu nguồn.

**Acceptance Criteria**:

1. **AC-005**: **Cho trước** trade đã khớp và account hợp lệ, **Khi** ledger ghi nhận, **Thì** journal cân bằng và truy vết được tới trade/order/account nguồn.
2. **AC-006**: **Cho trước** nghĩa vụ từ trade đến hạn T+, **Khi** cycle hoàn tất, **Thì** obligation, journal và số dư phản ánh đúng một kết quả nghiệp vụ.

---

### US-004 — Đối chiếu và phục hồi dữ liệu tenant (Ưu tiên: P1)

Nhân viên vận hành nạp statement demo để đối chiếu; quản trị viên khôi phục một tenant staging và xác nhận dữ liệu khôi phục vẫn nhất quán. Sai lệch tạo cảnh báo nhưng không sửa lịch sử gốc.

**Lý do ưu tiên**: Dữ liệu bền vững chỉ có giá trị khi đối chiếu và khôi phục được.

**Liên quan yêu cầu**: FR-011, FR-012, FR-013, FR-014

**Test độc lập**: Đối chiếu statement khớp và lệch; khôi phục tenant staging; xác nhận kết quả, cảnh báo và dữ liệu nguồn không bị thay đổi.

**Acceptance Criteria**:

1. **AC-007**: **Cho trước** statement demo khớp hoặc có chênh lệch, **Khi** đối chiếu, **Thì** kết quả là matched hoặc alert có tham chiếu nguồn và không tự sửa dữ liệu nghiệp vụ.
2. **AC-008**: **Cho trước** backup tenant staging, **Khi** tenant được khôi phục, **Thì** dữ liệu nghiệp vụ liên quan vẫn truy vấn được và đối chiếu được.

---

### US-005 — Bảo vệ và kiểm tra phạm vi dữ liệu (Ưu tiên: P1)

Người vận hành chỉ xem/thao tác dữ liệu tenant/broker được cấp; quản trị viên xem được trạng thái dữ liệu, backlog và dữ liệu cần xử lý trong phạm vi được ủy quyền.

**Lý do ưu tiên**: Persistence làm tăng rủi ro lộ dữ liệu nếu không có phạm vi truy cập và audit rõ.

**Liên quan yêu cầu**: FR-015, FR-016, FR-017

**Test độc lập**: Thử truy vấn chéo tenant/broker và xác nhận bị từ chối không lộ dữ liệu; kiểm tra trạng thái dữ liệu cùng tenant.

**Acceptance Criteria**:

1. **AC-009**: **Cho trước** người dùng thuộc tenant/broker A, **Khi** truy vấn dữ liệu của B, **Thì** thao tác bị từ chối hoặc không tìm thấy mà không lộ chi tiết dữ liệu B.
2. **AC-010**: **Cho trước** có backlog, dead-letter hoặc lỗi khôi phục, **Khi** quản trị viên kiểm tra, **Thì** thấy được trạng thái và tham chiếu xử lý trong đúng phạm vi.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Tenant chưa được khởi tạo không nhận luồng nghiệp vụ cần dữ liệu bền vững; người vận hành thấy trạng thái cần khởi tạo.
- **Dữ liệu không hợp lệ**: Record thiếu tham chiếu nguồn, sai trạng thái vòng đời hoặc sai phạm vi bị từ chối/cô lập kèm lý do truy vết.
- **Không có quyền**: Người dùng không được xem, khôi phục hoặc vận hành dữ liệu ngoài tenant/broker được cấp.
- **Lỗi hệ thống**: Thay đổi nghiệp vụ chưa hoàn tất không được hiển thị là thành công; thông tin xử lý lại được giữ để vận hành.
- **Timeout**: Thao tác chưa có kết quả xác định trả trạng thái có thể kiểm tra lại theo tham chiếu nguồn/correlation.
- **Dữ liệu bị thay đổi bởi người khác**: Thao tác cạnh tranh không được tạo order, reservation, journal hoặc obligation mâu thuẫn/trùng.
- **Người dùng thao tác lặp lại**: Khởi tạo, xử lý event, reservation, ledger, cycle và replay lặp lại không tạo kết quả nghiệp vụ trùng.
- **Trường hợp biên khác**: Record lịch sử đã hủy/hoàn tất không được khôi phục thành trạng thái đang hoạt động; reconciliation chỉ phát hiện và cảnh báo sai lệch.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI lưu và khôi phục dữ liệu tham chiếu giao dịch, order, lịch sử thay đổi order và trade theo đúng thứ tự nghiệp vụ.  
  **Liên quan**: US-001, AC-001, AC-002
- **FR-002** `[P1]`: Hệ thống PHẢI giữ được trạng thái order đang chờ, khớp một phần, hoàn tất, hủy và bị từ chối khi khôi phục dữ liệu.  
  **Liên quan**: US-001, AC-001, AC-002
- **FR-003** `[P1]`: Hệ thống PHẢI truy vết được mỗi trade về hai order và broker nguồn.  
  **Liên quan**: US-001, AC-001
- **FR-004** `[P1]`: Hệ thống PHẢI lưu broker, khách hàng và account giao dịch trong phạm vi tenant/broker phù hợp.  
  **Liên quan**: US-002, AC-003
- **FR-005** `[P1]`: Hệ thống PHẢI lưu số dư nghiệp vụ và reservation liên kết tới account và order/trade nguồn.  
  **Liên quan**: US-002, AC-003
- **FR-006** `[P1]`: Hệ thống KHÔNG ĐƯỢC tạo reservation hoặc thay đổi số dư nghiệp vụ trùng khi cùng yêu cầu được xử lý lại.  
  **Liên quan**: US-002, AC-004
- **FR-007** `[P1]`: Hệ thống PHẢI ghi nhận trade nguồn thành lịch sử ledger cân bằng, bất biến và truy vết được.  
  **Liên quan**: US-003, AC-005
- **FR-008** `[P1]`: Hệ thống PHẢI chỉ cập nhật projection số dư từ lịch sử ledger hợp lệ và phân biệt available, reserved, receivable và payable khi áp dụng.  
  **Liên quan**: US-002, US-003, AC-004, AC-005
- **FR-009** `[P1]`: Hệ thống PHẢI tạo nghĩa vụ settlement từ trade đã khớp và liên kết được nghĩa vụ tới trade, order, account và ledger nguồn.  
  **Liên quan**: US-003, AC-005, AC-006
- **FR-010** `[P1]`: Hệ thống PHẢI chỉ chuyển tiền/chứng khoán sang khả dụng khi nghĩa vụ đến hạn và hoàn tất theo chu kỳ nghiệp vụ.  
  **Liên quan**: US-003, AC-006
- **FR-011** `[P1]`: Hệ thống PHẢI tiếp nhận statement demo và đối chiếu tổng, chi tiết, số lượng và giá trị với dữ liệu nội bộ.  
  **Liên quan**: US-004, AC-007
- **FR-012** `[P1]`: Hệ thống PHẢI tạo cảnh báo bất biến cho sai lệch, kèm tham chiếu nguồn và correlation khi có.  
  **Liên quan**: US-004, AC-007
- **FR-013** `[P1]`: Hệ thống KHÔNG ĐƯỢC tự sửa order, trade, journal hoặc balance nguồn để giải quyết chênh lệch đối chiếu.  
  **Liên quan**: US-004, AC-007
- **FR-014** `[P1]`: Hệ thống PHẢI khởi tạo và khôi phục dữ liệu một tenant staging theo cách không tạo record nghiệp vụ trùng.  
  **Liên quan**: US-004, AC-008
- **FR-015** `[P1]`: Hệ thống PHẢI kiểm tra tenant/broker scope trước mọi truy vấn và thao tác dữ liệu nghiệp vụ.  
  **Liên quan**: US-005, AC-009
- **FR-016** `[P1]`: Hệ thống KHÔNG ĐƯỢC tiết lộ dữ liệu ngoài phạm vi qua kết quả, lỗi hoặc truy vết.  
  **Liên quan**: US-005, AC-009
- **FR-017** `[P2]`: Hệ thống PHẢI cung cấp trạng thái khởi tạo, backlog, dead-letter, độ trễ xử lý và kết quả khôi phục cho người vận hành được cấp quyền.  
  **Liên quan**: US-005, AC-010
- **FR-018** `[P2]`: Hệ thống PHẢI ghi audit bất biến cho khởi tạo, khôi phục, replay, reservation, settlement, reconciliation và cảnh báo.  
  **Liên quan**: US-003, US-004, US-005

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Order và trade là nguồn nghiệp vụ trước khi phát sinh reservation, ledger hoặc settlement.
- **BR-002**: Mỗi trade phải giữ liên kết tới hai order và broker nguồn trong toàn bộ vòng đời sau giao dịch.
- **BR-003**: Cùng một tham chiếu nghiệp vụ trong cùng phạm vi chỉ tạo một reservation, journal, obligation hoặc kết quả xử lý tương ứng.
- **BR-004**: Journal/entry, audit và reconciliation alert là lịch sử append-only; sai sót xử lý bằng record điều chỉnh có liên kết nguồn.
- **BR-005**: Nghĩa vụ settlement phát sinh tại trade, chưa là số dư khả dụng trước khi hoàn tất chu kỳ nghiệp vụ.
- **BR-006**: Alert đối chiếu là bằng chứng, không phải lệnh tự động sửa dữ liệu.
- **BR-007**: Mọi dữ liệu nghiệp vụ và truy vết phải thuộc đúng tenant/broker; truy vấn chéo phạm vi bị chặn.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Order mới | Ghi nhận hợp lệ | Đang chờ/khớp một phần/hoàn tất | Thỏa quy tắc MVP 01 |
| Order đang chờ | Hủy | Đã hủy | Còn khối lượng chờ |
| Trade đã khớp | Ghi ledger | Đã ghi nhận | Không trùng, liên kết nguồn hợp lệ |
| Nghĩa vụ tại T | Đến hạn và hoàn tất | Đã settlement | Chu kỳ nghiệp vụ hoàn tất |
| Statement demo | Đối chiếu | Matched/Alert cần xử lý | Tổng và chi tiết khớp/không khớp |

---

## 9. Thực thể dữ liệu

- **Dữ liệu tham chiếu giao dịch**: Thông tin mã, quy tắc giao dịch và phiên cần để diễn giải order/trade MVP 01–04.
- **Order và lịch sử order**: Lệnh, trạng thái, khối lượng còn lại và thay đổi vòng đời theo quy tắc MVP 01.
- **Trade**: Kết quả khớp có hai order, broker, giá, khối lượng và thứ tự nghiệp vụ.
- **Broker, khách hàng và account giao dịch**: Chủ thể sở hữu giao dịch, tiền/chứng khoán và phạm vi dữ liệu.
- **Reservation và số dư nghiệp vụ**: Khoản giữ chỗ và góc nhìn số dư liên kết account/order/trade.
- **Journal, entry và balance**: Lịch sử sổ cái bất biến và projection số dư theo bucket.
- **Nghĩa vụ settlement**: Cam kết phát sinh từ trade, có vòng đời đến hạn và tham chiếu nguồn.
- **Statement, reconciliation result và alert**: Dữ liệu đối chiếu demo, kết quả và bằng chứng sai lệch.
- **Inbox/outbox/audit**: Dấu vết tiếp nhận, phát hành, xử lý lại và thao tác vận hành.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Nhân viên vận hành xem dữ liệu nghiệp vụ của tenant/broker được cấp.
- Quản trị viên nền tảng xem trạng thái và dữ liệu cần khôi phục trong phạm vi được ủy quyền.

**Ai được thao tác**:
- Nhân viên vận hành được phân quyền vận hành đối chiếu và settlement.
- Quản trị viên được phân quyền khởi tạo, khôi phục và replay dữ liệu.
- Service Exchange/Broker chỉ tạo và truy vấn dữ liệu trong phạm vi xác thực.

**Ai không được phép**:
- Người dùng tenant/broker A không được xem hoặc thao tác dữ liệu tenant/broker B.
- Người không có quyền không được khôi phục, replay, adjustment, settlement hoặc xem audit chi tiết.

**Dữ liệu nhạy cảm**:
- Có. Order, trade, số dư, reservation, statement và audit vận hành là dữ liệu nghiệp vụ nhạy cảm.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền và tenant/broker scope trước mọi thao tác.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC tiết lộ dữ liệu ngoài phạm vi qua response, lỗi hoặc trace.
- **SEC-003**: Hệ thống PHẢI audit các thao tác có tác động tới dữ liệu hoặc trạng thái vận hành.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có

Hệ thống PHẢI ghi nhận bất biến:

- Ai thực hiện, vai trò và tenant/broker scope được ủy quyền.
- Khởi tạo, khôi phục, replay, reservation, adjustment, settlement, reconciliation và cảnh báo.
- Thời điểm, source reference, correlation và kết quả thao tác.
- Lý do và liên kết lịch sử gốc khi điều chỉnh dữ liệu nghiệp vụ.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: 100% trade được lưu trong kịch bản kiểm thử phải truy được về hai order và broker nguồn sau khi khôi phục dữ liệu.
- **NFR-002**: 100% xử lý lặp trong kịch bản kiểm thử không được tạo order history, reservation, journal hoặc obligation trùng.
- **NFR-003**: Dựng lại trạng thái order/account/balance từ lịch sử hợp lệ phải cho kết quả trùng với góc nhìn vận hành trong dữ liệu kiểm thử.
- **NFR-004**: 100% journal được chấp nhận phải cân bằng trước khi có hiệu lực nghiệp vụ.
- **NFR-005**: Trạng thái khởi tạo, backlog, dead-letter, độ trễ xử lý và kết quả khôi phục phải kiểm tra được bởi người vận hành được cấp quyền.
- **NFR-006**: Backup/restore một tenant phải được kiểm chứng ở staging trước khi feature được chấp nhận hoàn tất.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% kịch bản order/trade demo MVP 01 được khôi phục với trạng thái và liên kết nguồn chính xác sau một lần khởi động lại.
- **SC-002**: 100% kịch bản broker/account/reservation demo được khôi phục mà không tạo reservation hoặc số dư nghiệp vụ trùng.
- **SC-003**: 100% journal demo được chấp nhận cân bằng và truy được từ trade về hai order nguồn.
- **SC-004**: 100% nghĩa vụ demo đến hạn được settlement đúng một lần và chuyển số dư khả dụng có truy vết nguồn.
- **SC-005**: 100% sai lệch demo được tiêm trong reconciliation tạo matched/alert đúng, không tự sửa dữ liệu gốc.
- **SC-006**: 100% thử nghiệm truy vấn chéo tenant/broker ở staging bị từ chối mà không lộ dữ liệu.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Quy tắc nghiệp vụ MVP 01–08 hiện có là nguồn sự thật cho vòng đời order, trade, broker, reservation, ledger và settlement.
- Alpha/Beta là tenant demo đại diện cho các kịch bản chấp nhận.
- Dữ liệu identity, credential và authorization master vẫn thuộc boundary hiện có, không được sao chép vào dữ liệu nghiệp vụ feature này.
- Statement, cycle T+ và dữ liệu thị trường chỉ được mô phỏng trong phạm vi demo/staging.

**Ràng buộc**:
- Dữ liệu được bổ sung theo thứ tự nghiệp vụ từ MVP 01 tới MVP 08; không tạo ledger/settlement độc lập với order/trade/account nguồn.
- Lịch sử nghiệp vụ nhạy cảm phải được tách theo tenant/broker và giữ được truy vết xuyên vòng đời.
- Feature chỉ thay đổi artifact workstation; code sau này phải nằm trong repository con đúng phạm vi.

---

## 15. Ngoài phạm vi

- Thay đổi quy tắc khớp lệnh, pricing, session hoặc pre-trade đã được chốt ở các MVP trước.
- Xây dựng lại identity, credential, user directory hoặc authorization master.
- Kết nối tổ chức thanh toán/lưu ký thật, statement thật, thanh toán thật hoặc báo cáo pháp định.
- Margin, collateral, phái sinh, corporate action và nghiệp vụ sau giao dịch mở rộng.
- Tự động sửa/xóa dữ liệu lịch sử để xử lý sai lệch.
- Migration dữ liệu production thật từ hệ thống bên ngoài.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|---|---|---|---|
| Thiết kế bắt đầu từ ledger, thiếu order/trade nguồn | Trung | Cao | Bắt buộc trace theo thứ tự MVP 01–08 và kiểm thử liên kết nguồn. |
| Trùng record do restart/retry | Trung | Cao | Idempotency và kịch bản xử lý lặp bắt buộc. |
| Trạng thái khôi phục sai vòng đời order hoặc settlement | Trung | Cao | Kiểm thử restore theo kịch bản order, reservation, ledger và T+. |
| Lộ dữ liệu giữa tenant/broker | Thấp | Cao | Scope check, permission test và response không lộ dữ liệu. |
| Khôi phục staging làm sai dữ liệu vận hành | Thấp | Cao | Backup/restore drill và đối chiếu sau khôi phục. |

---

## 17. Phụ thuộc

- Artifact/spec và quy tắc nghiệp vụ MVP 01–08 tại `specs/000010` đến `specs/000016` là nguồn tham chiếu nghiệp vụ.
- Repo `flex-exchange-service` là nơi chứa code Exchange/Broker; `flex-database` là nơi duy trì script dữ liệu khi plan được phê duyệt.
- Hạ tầng staging có khả năng backup/restore tenant để xác nhận NFR-006.

---

## 18. Câu hỏi mở

Không còn câu hỏi mở chặn spec. Ownership identity và credential được giữ ngoài phạm vi; feature chỉ lưu dữ liệu nghiệp vụ Exchange/Broker theo các capability MVP 01–08.

---

## Clarifications

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
