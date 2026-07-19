# Đặc tả tính năng: Ledger tiền và chứng khoán

**Branch**: `000016-cash-securities-ledger`  
**Ngày tạo**: 2026-07-19  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: MVP 07 — Ledger tiền và chứng khoán

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

MVP 06 đang biểu diễn số dư và phong tỏa bằng trạng thái có thể cập nhật trực tiếp, khó kiểm toán và khó chứng minh rằng các thay đổi tiền/chứng khoán luôn cân bằng. Khi Alpha mua và Beta bán, hệ thống cần một lịch sử bất biến để truy vết từ lệnh, giao dịch và phí đến từng biến động tài sản.

**Tổng quan tính năng**:

Ledger ghi nhận mọi biến động tiền và chứng khoán bằng các bút toán double-entry trong phạm vi từng tenant. Người vận hành có thể xem số dư theo trạng thái và truy vết từ giao dịch nguồn đến các dòng ledger, trong khi bút toán cũ không bị sửa hoặc xóa.

## 2. Mục tiêu

- **MT-001**: Mọi biến động tài sản trong phạm vi MVP đều có bút toán cân bằng và tham chiếu nguồn.
- **MT-002**: Người vận hành truy vết được một lệnh hoặc giao dịch đến toàn bộ dòng ledger liên quan.
- **MT-003**: Số dư theo `available`, `reserved`, `receivable`, `payable` phản ánh đúng trạng thái nghiệp vụ mà không cần sửa lịch sử.

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Ledger double-entry rút gọn cho tiền và chứng khoán, tách biệt theo tenant.
- **MVP-002**: Theo dõi bốn trạng thái tài sản: `available`, `reserved`, `receivable`, `payable`.
- **MVP-003**: Ghi nhận nạp số dư demo, phong tỏa lệnh, khớp lệnh, phí và hủy lệnh.
- **MVP-004**: Kiểm tra tổng debit bằng tổng credit, tham chiếu giao dịch nguồn và chống ghi nhận trùng event khớp.

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Người vận hành CTCK, người kiểm thử nghiệp vụ và hệ thống Broker/Exchange phát sinh giao dịch.

**Bối cảnh sử dụng**: Sau khi lệnh qua Broker được chấp nhận hoặc khớp, hệ thống ghi nhận biến động tài sản và người vận hành kiểm tra số dư, lịch sử và tính cân bằng.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ có hiểu biết về lệnh, giao dịch, tiền và chứng khoán.

## 5. Kịch bản người dùng

### US-001 — Ghi nhận biến động tài sản bằng bút toán cân bằng (Ưu tiên: P1)

Người vận hành hoặc luồng nghiệp vụ tạo các biến động nạp tiền, phong tỏa, khớp, phí và hủy. Mỗi biến động tạo một nhóm bút toán bất biến có tổng debit bằng tổng credit và tham chiếu được nguồn phát sinh.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004

**Test độc lập**: Tạo từng loại biến động trên tài khoản demo, kiểm tra nhóm bút toán, tổng debit/credit và tham chiếu nguồn.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** một biến động tài sản hợp lệ, **Khi** hệ thống ghi nhận, **Thì** tạo được nhóm bút toán có ít nhất một debit, một credit và tổng hai phía bằng nhau.
2. **AC-002**: **Cho trước** một bút toán đã ghi nhận, **Khi** có yêu cầu sửa hoặc xóa, **Thì** hệ thống từ chối thay đổi lịch sử và yêu cầu bút toán điều chỉnh/đảo.
3. **AC-003**: **Cho trước** một event khớp được gửi lại, **Khi** hệ thống nhận lần thứ hai, **Thì** không tạo thêm bút toán hoặc thay đổi số dư.

### US-002 — Theo dõi trạng thái tiền và chứng khoán (Ưu tiên: P1)

Người vận hành xem được số dư tiền và chứng khoán theo `available`, `reserved`, `receivable`, `payable` của đúng tenant và tài khoản.

**Liên quan yêu cầu**: FR-005, FR-006, SEC-001

**Test độc lập**: Nạp tài sản, phong tỏa một lệnh và ghi nhận khớp; đối chiếu số dư từng trạng thái trước và sau mỗi bước.

**Acceptance Criteria**:

1. **AC-004**: **Cho trước** tài khoản có các biến động tiền và chứng khoán, **Khi** xem số dư, **Thì** hệ thống hiển thị bốn trạng thái riêng biệt và tổng có thể đối chiếu với ledger.
2. **AC-005**: **Cho trước** giao dịch mua đã khớp, **Khi** cập nhật trạng thái tài sản, **Thì** tài sản được chuyển sang phải thu/phải trả theo quy tắc nghiệp vụ và chưa trở thành số dư khả dụng.
3. **AC-006**: **Cho trước** yêu cầu xem tài khoản của tenant khác, **Khi** truy vấn, **Thì** hệ thống từ chối và không tiết lộ số dư hoặc dòng ledger.

### US-003 — Truy vết từ lệnh đến ledger (Ưu tiên: P2)

Người vận hành chọn một lệnh hoặc giao dịch và xem được các dòng ledger, lý do nghiệp vụ, thời điểm và số dư liên quan.

**Liên quan yêu cầu**: FR-007, FR-008

**Test độc lập**: Tạo giao dịch Alpha mua/Beta bán có phí, sau đó truy vấn trace ở cả hai phía và xác nhận không lẫn tenant.

**Acceptance Criteria**:

1. **AC-007**: **Cho trước** một giao dịch đã tạo bút toán, **Khi** truy vấn trace, **Thì** kết quả trả về đầy đủ nhóm bút toán và tham chiếu giao dịch nguồn.
2. **AC-008**: **Cho trước** một giao dịch có phí, **Khi** xem trace, **Thì** dòng phí được phân biệt với dòng chuyển giao tài sản, được ghi nhận vào tài khoản của bên phát sinh giao dịch và vẫn nằm trong nhóm cân bằng.

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Hiển thị số dư bằng không và lịch sử rỗng, không coi là lỗi.
- **Dữ liệu không hợp lệ**: Từ chối bút toán thiếu nguồn, thiếu phía đối ứng, sai tenant hoặc làm mất cân bằng.
- **Không có quyền**: Từ chối truy cập tài khoản/dòng ledger ngoài tenant hoặc vai trò được cấp.
- **Lỗi hệ thống**: Không ghi dở một nhóm bút toán; cho phép thử lại an toàn.
- **Timeout**: Event chưa xác nhận không được ghi nhận lần hai khi retry.
- **Dữ liệu bị thay đổi bởi người khác**: Ledger đã ghi nhận không bị ghi đè; truy vấn sau phản ánh lịch sử bất biến.
- **Người dùng thao tác lặp lại**: Cùng `source reference` và loại event chỉ tạo một nhóm bút toán.
- **Trường hợp biên khác**: Bút toán điều chỉnh phải liên kết bút toán gốc và nêu lý do.

## 7. Yêu cầu chức năng

- **FR-001** `[P1]`: Hệ thống PHẢI ghi nhận biến động tiền và chứng khoán bằng nhóm bút toán double-entry cân bằng.
- **FR-002** `[P1]`: Mỗi nhóm bút toán PHẢI có tham chiếu giao dịch nguồn, tenant, tài khoản và thời điểm phát sinh.
- **FR-003** `[P1]`: Hệ thống PHẢI ghi nhận nạp demo, phong tỏa, khớp, phí do bên phát sinh giao dịch chịu và hủy lệnh.
- **FR-004** `[P1]`: Hệ thống KHÔNG ĐƯỢC sửa hoặc xóa bút toán đã ghi nhận; điều chỉnh PHẢI dùng bút toán đảo/điều chỉnh có liên kết.
- **FR-005** `[P1]`: Hệ thống PHẢI cung cấp số dư tiền và chứng khoán theo `available`, `reserved`, `receivable`, `payable`.
- **FR-006** `[P1]`: Sau khớp, tài sản PHẢI chuyển sang trạng thái phải thu/phải trả theo quy tắc và chưa được coi là khả dụng.
- **FR-007** `[P2]`: Hệ thống PHẢI cho phép truy vết từ lệnh/giao dịch đến toàn bộ dòng ledger liên quan.
- **FR-008** `[P2]`: Hệ thống PHẢI xử lý idempotency khi nhận lại cùng event nguồn.

## 8. Quy tắc nghiệp vụ

- **BR-001**: Mỗi nhóm bút toán phải có tổng debit bằng tổng credit.
- **BR-002**: Bút toán đã ghi nhận là bất biến; mọi sửa sai dùng bút toán đảo hoặc điều chỉnh.
- **BR-003**: Khớp lệnh chỉ chuyển tài sản sang `receivable`/`payable`, chưa hoàn tất thanh toán.
- **BR-004**: Ledger của tenant này không được dùng để truy vấn hoặc thay đổi tài sản của tenant khác.
- **BR-005**: Cùng một event nguồn không được tạo nhiều nhóm bút toán.
- **BR-006**: Phí giao dịch được ghi nhận vào tài khoản của bên phát sinh giao dịch và phải có tham chiếu tới giao dịch nguồn.

## 9. Thực thể dữ liệu

- **Ledger Account**: Tài khoản tiền hoặc chứng khoán thuộc một tenant và một trạng thái tài sản.
- **Ledger Entry**: Một dòng debit hoặc credit bất biến trong nhóm bút toán.
- **Journal**: Nhóm các dòng ledger cân bằng, gắn với nguồn nghiệp vụ.
- **Source Transaction**: Lệnh, giao dịch, phí, nạp demo hoặc hủy làm phát sinh journal.

## 10. Phân quyền & Bảo mật

**Ai được xem**: Chủ/nhân sự được cấp quyền trong tenant xem tài khoản và trace thuộc tenant mình; người vận hành nền tảng chỉ xem theo phạm vi vận hành được cấp.

**Ai được thao tác**: Luồng nghiệp vụ được ủy quyền ghi nhận event; người vận hành được tạo nạp demo và bút toán điều chỉnh theo quyền.

**Ai không được phép**: Người dùng tenant không được xem/sửa ledger tenant khác hoặc sửa/xóa journal đã ghi.

**Dữ liệu nhạy cảm**: Số dư tiền, chứng khoán và lịch sử giao dịch là dữ liệu nhạy cảm theo tenant.

- **SEC-001**: Hệ thống PHẢI kiểm tra tenant và quyền trước khi đọc hoặc ghi ledger.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC làm lộ số dư hoặc dòng ledger ngoài phạm vi được cấp.

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có. Ledger tự là lịch sử bất biến; mọi bút toán điều chỉnh PHẢI ghi người thực hiện, lý do, thời điểm và journal gốc liên quan.

## 12. Yêu cầu phi chức năng

- **NFR-001**: 100% journal được chấp nhận phải vượt kiểm tra cân bằng trước khi hiển thị là đã ghi nhận.
- **NFR-002**: Mỗi API truy vấn balance hoặc trace phải phản hồi trong vòng 3 giây ở tải demo thông thường.
- **NFR-003**: Tính năng không làm mất khả năng truy vết các lệnh và giao dịch đã có từ MVP trước.

## 13. Tiêu chí thành công

- **SC-001**: 100% giao dịch demo Alpha mua/Beta bán tạo journal cân bằng cho cả hai phía và các dòng phí liên quan.
- **SC-002**: 100% event khớp gửi lặp không tạo journal hoặc biến động số dư trùng.
- **SC-003**: Người kiểm thử hoàn tất quy trình truy vết từ một lệnh đến journal và số dư trong dưới 3 phút; đây là thời gian workflow, không phải latency của một API.
- **SC-004**: Không có truy vấn chéo tenant nào trả về số dư hoặc dòng ledger.

## 14. Giả định & Ràng buộc

**Giả định**:
- MVP 06 đã cung cấp tenant, Broker, tài khoản và luồng giao dịch Alpha/Beta.
- Event lệnh/khớp/phí/hủy có tham chiếu ổn định để làm nguồn ledger.
- Số lượng tài sản và giao dịch ở mức demo, chưa yêu cầu hiệu năng production.

**Ràng buộc**:
- PHẢI dùng mô hình bất biến và double-entry trong phạm vi MVP.
- Chưa thực hiện settlement T+, reconciliation, margin hoặc kết nối VSDC/ngân hàng.

## 15. Ngoài phạm vi

- Clearing và settlement T+.
- Đối chiếu EOD hoặc xử lý sai lệch tự động.
- Margin, collateral, phái sinh và quản trị rủi ro nâng cao.
- Kết nối ngân hàng, VSDC hoặc ledger kế toán production.

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|---|---|---|---|
| Mapping event sang journal sai | Trung | Cao | Kiểm tra contract nguồn và test từng loại event |
| Ghi trùng event khớp | Trung | Cao | Idempotency theo source reference và kiểm thử retry |
| Lộ dữ liệu chéo tenant | Thấp | Cao | Permission test và kiểm tra tenant trên mọi truy vấn |

## 17. Phụ thuộc

- Tenant/Broker và event giao dịch từ MVP 06.
- Luồng matching và phí hiện có của Exchange.
- Quy tắc nghiệp vụ xác định bên mua, bên bán và trạng thái phải thu/phải trả.

## 18. Câu hỏi mở

Không có câu hỏi mở chặn phạm vi MVP; chi tiết contract event và cách lưu trữ thuộc plan kỹ thuật.

## Clarifications

### Session 2026-07-19

- Q: Phí giao dịch được ghi nhận cho bên nào? → A: Người mua/người bán chịu phí tương ứng với giao dịch của mình.

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [x] Phân quyền/bảo mật đã rõ.
- [x] Ngoài phạm vi đã rõ.
- [x] Câu hỏi mở quan trọng không chặn scope.
