# Đặc tả tính năng: Database, clearing, settlement và đối chiếu — MVP 08

**Branch**: `000017-database-clearing-settlement`  
**Ngày tạo**: 2026-07-19  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Triển khai MVP 08 để đưa ledger, clearing, settlement và đối chiếu vào vận hành với dữ liệu bất biến, có thể phục hồi và cách ly tenant.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Các quy tắc ledger của MVP 07 chưa có nơi lưu trữ và vận hành tin cậy. Giao dịch đã khớp cần được ghi nhận một lần, tạo nghĩa vụ trước khi hoàn tất thanh toán, và được đối chiếu với sao kê cuối ngày. Nếu không có luồng này, số dư có thể bị ghi trùng, không truy vết được nguồn giao dịch, không phân biệt tiền/chứng khoán đang chờ thanh toán với số dư khả dụng, và không phát hiện được chênh lệch vận hành.

**Tổng quan tính năng**:

MVP 08 cung cấp nền dữ liệu vận hành cho ledger theo từng tenant, tiếp nhận sự kiện giao dịch một cách idempotent, tạo nghĩa vụ thanh toán và mô phỏng vòng đời T+. Người vận hành có thể truy vết giao dịch, xử lý điều chỉnh hợp lệ, theo dõi hàng đợi, chạy đối chiếu sao kê cuối ngày và nhận cảnh báo chênh lệch mà không sửa lịch sử gốc.

---

## 2. Mục tiêu

- **MT-001**: Mọi nghiệp vụ ledger được chấp nhận đều có lịch sử cân bằng, bất biến và truy vết được về sự kiện nguồn.
- **MT-002**: Giao dịch đã khớp tạo nghĩa vụ rõ ràng ở T và chỉ chuyển thành khả dụng khi hoàn tất chu kỳ T+.
- **MT-003**: Người vận hành phát hiện, cô lập và xử lý được sự kiện lỗi hoặc chênh lệch mà không làm sai số liệu gốc.
- **MT-004**: Không có dữ liệu hoặc số dư của một tenant xuất hiện trong thao tác hay kết quả của tenant khác.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Khởi tạo dữ liệu ledger và số dư opening lặp lại an toàn cho tenant Alpha/Beta; dữ liệu phải có phiên bản và sẵn sàng trước khi dịch vụ vận hành.
- **MVP-002**: Ghi nhận opening, reserve, fill, fee và cancel thành journal/entry cân bằng; nhận diện sự kiện lặp để không làm phát sinh số dư, journal hoặc nghĩa vụ trùng.
- **MVP-003**: Tạo nghĩa vụ settlement từ giao dịch đã khớp, mô phỏng chu kỳ T+, và chuyển đúng tiền/chứng khoán từ bucket phải thu/phải trả sang khả dụng khi hoàn tất.
- **MVP-004**: Cung cấp truy vết tài khoản và giao dịch, điều chỉnh hoặc đảo bút toán có lý do, replay an toàn, retry/dead-letter và chỉ báo tình trạng vận hành.
- **MVP-005**: Nạp sao kê EOD giả lập, đối chiếu tổng/chi tiết/số lượng/giá trị, và tạo cảnh báo bất biến có tham chiếu nguồn khi có chênh lệch.
- **MVP-006**: Chỉ mô phỏng clearing/settlement nội bộ; không kết nối tổ chức thanh toán hay lưu ký thật.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**:

- Nhân viên vận hành broker: theo dõi số dư, nghĩa vụ, settlement và xử lý ngoại lệ.
- Quản trị viên nền tảng: quản lý tenant, theo dõi tình trạng pipeline và thực hiện recovery được cấp quyền.
- Hệ thống Broker/Exchange: gửi sự kiện nghiệp vụ cho ledger.

**Bối cảnh sử dụng**: Sau khi lệnh được khớp, sự kiện đi vào ledger; nhân viên vận hành kiểm tra kết quả, chạy chu kỳ T+ và đối chiếu cuối ngày trong môi trường demo/staging.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Nhân viên vận hành am hiểu clearing/settlement; quản trị viên có kiến thức kỹ thuật.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Khởi tạo ledger tenant và ghi nhận giao dịch (Ưu tiên: P1)

Quản trị viên chuẩn bị tenant mới; hệ thống tạo dữ liệu nền và số dư opening. Broker/Exchange gửi sự kiện reserve, fill, fee hoặc cancel; nhân viên vận hành tra được lịch sử cân bằng và số dư theo tài khoản/tài sản.

**Lý do ưu tiên**: Đây là nền tảng cho mọi nghĩa vụ, settlement và đối chiếu sau đó.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004

**Test độc lập**: Khởi tạo Alpha/Beta, gửi từng loại sự kiện hợp lệ và xác minh mỗi journal cân bằng, số dư chỉ thuộc tenant nhận sự kiện.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** tenant mới chưa có dữ liệu ledger, **Khi** khởi tạo dữ liệu nền, **Thì** số dư opening và trạng thái dữ liệu sẵn sàng được tạo một lần an toàn.
2. **AC-002**: **Cho trước** một sự kiện nghiệp vụ hợp lệ, **Khi** hệ thống ghi nhận, **Thì** tạo lịch sử cân bằng, cập nhật số dư liên quan và cho phép truy vết tới tham chiếu nguồn.
3. **AC-003**: **Cho trước** cùng một sự kiện được gửi lại, **Khi** hệ thống xử lý, **Thì** trả về kết quả đã có và không thay đổi số dư, journal hay nghĩa vụ.

---

### US-002 — Thanh toán nghĩa vụ theo chu kỳ T+ (Ưu tiên: P1)

Sau một giao dịch đã khớp, nhân viên vận hành thấy nghĩa vụ tiền/chứng khoán ở trạng thái chờ. Khi chạy tới ngày T+ trong demo, nghĩa vụ hoàn tất và số dư khả dụng phản ánh đúng kết quả thanh toán.

**Lý do ưu tiên**: Tách nghĩa vụ sau khớp khỏi số dư khả dụng là giá trị cốt lõi của clearing/settlement.

**Liên quan yêu cầu**: FR-005, FR-006, FR-007

**Test độc lập**: Tạo trade, xác minh bucket phải thu/phải trả trước T+, chạy chu kỳ T+ và xác minh trạng thái cùng số dư sau thanh toán.

**Acceptance Criteria**:

1. **AC-004**: **Cho trước** trade đã khớp ở T, **Khi** trade được ghi nhận, **Thì** nghĩa vụ settlement có liên kết tới trade nguồn và tiền/chứng khoán chưa trở thành khả dụng.
2. **AC-005**: **Cho trước** nghĩa vụ đến hạn T+, **Khi** nhân viên chạy chu kỳ thanh toán demo, **Thì** nghĩa vụ được hoàn tất, số dư được chuyển đúng bucket và có lịch sử truy vết.

---

### US-003 — Recovery và xử lý điều chỉnh có kiểm soát (Ưu tiên: P2)

Khi một sự kiện lỗi hoặc bị tạm dừng, quản trị viên xem được trạng thái, recovery bằng replay và tiếp tục xử lý mà không ghi trùng. Khi cần sửa sai nghiệp vụ, nhân viên được cấp quyền tạo adjustment/reversal kèm lý do thay vì sửa journal cũ.

**Lý do ưu tiên**: Ledger vận hành chỉ đáng tin khi phục hồi được và không mất tính bất biến.

**Liên quan yêu cầu**: FR-008, FR-009, FR-010

**Test độc lập**: Làm lỗi một sự kiện, xác minh được cô lập; replay nó và xác minh chỉ có một kết quả nghiệp vụ. Tạo reversal và xác minh journal gốc không đổi.

**Acceptance Criteria**:

1. **AC-006**: **Cho trước** sự kiện xử lý thất bại quá giới hạn, **Khi** quản trị viên kiểm tra, **Thì** sự kiện có trạng thái cần xử lý cùng thông tin truy vết, không bị mất im lặng.
2. **AC-007**: **Cho trước** sự kiện cần recovery, **Khi** người có quyền replay, **Thì** hệ thống xử lý an toàn mà không tạo journal hoặc delta trùng.
3. **AC-008**: **Cho trước** bút toán cần điều chỉnh, **Khi** người có quyền tạo reversal/adjustment có lý do, **Thì** bút toán gốc vẫn bất biến và lịch sử mới liên kết được tới nó.

---

### US-004 — Đối chiếu EOD và xử lý chênh lệch (Ưu tiên: P1)

Nhân viên vận hành nạp sao kê EOD giả lập và chạy đối chiếu. Nếu sao kê khớp, kết quả được ghi nhận; nếu có sai lệch được tiêm, hệ thống tạo cảnh báo có tham chiếu trade nguồn để nhân viên điều tra, nhưng không tự sửa ledger.

**Lý do ưu tiên**: Đối chiếu xác thực độ tin cậy số liệu sau settlement và tạo bằng chứng vận hành.

**Liên quan yêu cầu**: FR-011, FR-012, FR-013

**Test độc lập**: Chạy với sao kê đúng và sao kê có một chênh lệch xác định trước; xác minh kết quả matched/alert tương ứng.

**Acceptance Criteria**:

1. **AC-009**: **Cho trước** sao kê EOD khớp dữ liệu nội bộ, **Khi** chạy đối chiếu, **Thì** kết quả xác nhận khớp ở cấp tổng và chi tiết.
2. **AC-010**: **Cho trước** sao kê có sai lệch về số lượng hoặc giá trị, **Khi** chạy đối chiếu, **Thì** tạo cảnh báo bất biến với tham chiếu nguồn và trạng thái cần xử lý.
3. **AC-011**: **Cho trước** cảnh báo đối chiếu, **Khi** nhân viên xem kết quả, **Thì** ledger gốc không bị tự động sửa đổi.

---

### US-005 — Bảo vệ dữ liệu tenant và khả năng vận hành (Ưu tiên: P1)

Nhân viên và quản trị viên theo dõi tình trạng dữ liệu, hàng đợi và backlog. Khi cố truy vấn dữ liệu tenant khác, hệ thống từ chối mà không tiết lộ thông tin.

**Lý do ưu tiên**: Cách ly tenant và phát hiện sớm sự cố là điều kiện để vận hành an toàn.

**Liên quan yêu cầu**: FR-014, FR-015, FR-016

**Test độc lập**: Thử truy vấn chéo tenant và tạo backlog/đầu việc lỗi; xác minh bị chặn và chỉ báo hiển thị đúng phạm vi.

**Acceptance Criteria**:

1. **AC-012**: **Cho trước** người dùng thuộc tenant A, **Khi** truy vấn dữ liệu tenant B, **Thì** hệ thống từ chối và không tiết lộ balance, journal, obligation hoặc reconciliation của tenant B.
2. **AC-013**: **Cho trước** pipeline có backlog, dead-letter hoặc projection chậm, **Khi** người vận hành kiểm tra tình trạng, **Thì** thấy được chỉ báo để xác định và xử lý sự cố.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Tenant chưa khởi tạo không được nhận sự kiện nghiệp vụ; người vận hành thấy trạng thái cần khởi tạo.
- **Dữ liệu không hợp lệ**: Sự kiện thiếu định danh, sai tenant, sai tham chiếu hoặc không cân bằng bị từ chối/cô lập kèm lý do truy vết.
- **Không có quyền**: Người dùng không đủ quyền không được xem hoặc replay/điều chỉnh dữ liệu; phản hồi không tiết lộ dữ liệu ngoài phạm vi.
- **Lỗi hệ thống**: Sự kiện chưa hoàn tất được giữ để xử lý lại; không báo thành công khi journal, số dư và thông báo liên quan chưa nhất quán.
- **Timeout**: Thao tác chưa có kết quả xác định phải trả trạng thái có thể kiểm tra lại, không cho phép người dùng suy diễn đã ghi nhận thành công.
- **Dữ liệu bị thay đổi bởi người khác**: Kết quả settlement/reconciliation dùng trạng thái hiện hành có truy vết thời điểm; thao tác cạnh tranh không được làm phát sinh lịch sử mâu thuẫn.
- **Người dùng thao tác lặp lại**: Gửi lại cùng sự kiện, chạy lại seed hoặc replay không tạo kết quả nghiệp vụ trùng.
- **Trường hợp biên khác**: Sự kiện thất bại quá số lần cho phép chuyển sang danh sách cần xử lý; reconciliation được phép phát hiện sai lệch nhưng không tự sửa ledger gốc.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI chuẩn bị dữ liệu ledger và số dư opening cho từng tenant một cách lặp lại an toàn, kèm trạng thái sẵn sàng.  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Hệ thống PHẢI ghi nhận opening, reserve, fill, fee và cancel thành lịch sử ledger cân bằng, bất biến và truy vết được tới sự kiện nguồn.  
  **Liên quan**: US-001, AC-002
- **FR-003** `[P1]`: Hệ thống PHẢI chỉ cập nhật số dư đọc từ lịch sử ledger hợp lệ và thể hiện được available, reserved, receivable và payable khi áp dụng.  
  **Liên quan**: US-001, US-002, AC-002, AC-004
- **FR-004** `[P1]`: Hệ thống KHÔNG ĐƯỢC ghi nhận lần hai cùng một sự kiện nghiệp vụ trong một tenant.  
  **Liên quan**: US-001, AC-003
- **FR-005** `[P1]`: Hệ thống PHẢI tạo nghĩa vụ settlement cho trade đã khớp, có liên kết tới trade nguồn và trạng thái vòng đời rõ ràng.  
  **Liên quan**: US-002, AC-004
- **FR-006** `[P1]`: Hệ thống PHẢI chỉ chuyển tiền/chứng khoán sang khả dụng khi nghĩa vụ đến hạn T+ và được hoàn tất.  
  **Liên quan**: US-002, AC-005
- **FR-007** `[P1]`: Hệ thống PHẢI cung cấp truy vết từ account hoặc source reference tới lịch sử ledger và nghĩa vụ liên quan trong đúng tenant.  
  **Liên quan**: US-001, US-002, AC-002, AC-005
- **FR-008** `[P2]`: Hệ thống PHẢI cho người được cấp quyền xem và recovery các sự kiện lỗi; sự kiện vượt giới hạn retry phải có trạng thái cần xử lý.  
  **Liên quan**: US-003, AC-006, AC-007
- **FR-009** `[P2]`: Hệ thống PHẢI cho phép replay sự kiện theo tham chiếu, với kết quả không tạo journal, nghĩa vụ hoặc số dư trùng.  
  **Liên quan**: US-003, AC-007
- **FR-010** `[P2]`: Hệ thống PHẢI cho phép adjustment hoặc reversal có người thực hiện và lý do; KHÔNG ĐƯỢC sửa hay xóa journal/entry gốc.  
  **Liên quan**: US-003, AC-008
- **FR-011** `[P1]`: Hệ thống PHẢI tiếp nhận sao kê EOD giả lập và đối chiếu với ledger ở cấp tổng, chi tiết, số lượng và giá trị.  
  **Liên quan**: US-004, AC-009
- **FR-012** `[P1]`: Hệ thống PHẢI tạo cảnh báo bất biến cho mọi sai lệch được phát hiện, kèm source reference và correlation khi có.  
  **Liên quan**: US-004, AC-010
- **FR-013** `[P1]`: Hệ thống KHÔNG ĐƯỢC tự sửa journal gốc để giải quyết sai lệch đối chiếu.  
  **Liên quan**: US-004, AC-011
- **FR-014** `[P1]`: Hệ thống PHẢI kiểm tra tenant scope trước mọi truy vấn và thao tác ledger, settlement, recovery và reconciliation.  
  **Liên quan**: US-005, AC-012
- **FR-015** `[P1]`: Hệ thống PHẢI cung cấp tình trạng sẵn sàng dữ liệu, độ trễ xử lý, số sự kiện cần xử lý và backlog đối chiếu cho người vận hành được cấp quyền.  
  **Liên quan**: US-005, AC-013
- **FR-016** `[P2]`: Hệ thống PHẢI ghi audit cho khởi tạo dữ liệu, replay, adjustment/reversal, chạy settlement, chạy reconciliation và cảnh báo chênh lệch.  
  **Liên quan**: US-003, US-004, US-005

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Mỗi journal được chấp nhận phải cân bằng; journal/entry là append-only.
- **BR-002**: Sai sót chỉ được xử lý qua adjustment hoặc reversal có lý do và liên kết tới lịch sử gốc.
- **BR-003**: Cùng tenant, một nguồn sự kiện nghiệp vụ chỉ tạo một kết quả ledger; gửi lặp trả kết quả đã có.
- **BR-004**: Trade đã khớp tạo nghĩa vụ tại T; số dư thuộc nghĩa vụ phải thu/phải trả chưa là khả dụng trước khi hoàn tất T+.
- **BR-005**: Mọi dữ liệu ledger, obligation, balance, statement và reconciliation phải thuộc đúng một tenant; truy vấn chéo tenant bị chặn.
- **BR-006**: Cảnh báo đối chiếu là bằng chứng bất biến; không phải lệnh tự động sửa số liệu.
- **BR-007**: Recovery chỉ được thực hiện bởi người được cấp quyền và phải giữ lại toàn bộ truy vết thao tác.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Sự kiện mới | Ghi nhận hợp lệ | Đã ghi nhận | Không trùng, cân bằng và đúng tenant |
| Sự kiện mới | Xử lý lỗi lặp lại | Cần xử lý | Vượt giới hạn retry |
| Cần xử lý | Replay thành công | Đã ghi nhận | Người thực hiện có quyền; không trùng |
| Nghĩa vụ tại T | Đến hạn và hoàn tất | Đã settlement | Chu kỳ T+ hoàn tất |
| Sao kê EOD | Đối chiếu không lệch | Matched | Tổng và chi tiết đều khớp |
| Sao kê EOD | Phát hiện chênh lệch | Alert cần xử lý | Có sai lệch tổng, chi tiết, số lượng hoặc giá trị |

---

## 9. Thực thể dữ liệu

- **Tài khoản ledger**: Tài khoản tiền hoặc chứng khoán trong phạm vi một tenant, có các bucket số dư nghiệp vụ.
- **Journal và entry**: Lịch sử bút toán cân bằng, bất biến cho một chuyển dịch nghiệp vụ.
- **Sự kiện nghiệp vụ**: Yêu cầu ghi nhận có định danh, tenant, nguồn, thời điểm và correlation để chống trùng và truy vết.
- **Số dư**: Góc nhìn đọc được dựng từ lịch sử ledger, thể hiện available, reserved, receivable và payable.
- **Nghĩa vụ settlement**: Cam kết tiền/chứng khoán phát sinh từ trade đã khớp, có vòng đời T+ và tham chiếu trade nguồn.
- **Sao kê EOD và kết quả reconciliation**: Số liệu đối chiếu giả lập, kết quả matched hoặc alert có nguồn tham chiếu.
- **Bản ghi audit**: Bằng chứng bất biến về thao tác vận hành và thay đổi trạng thái.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Nhân viên vận hành chỉ xem ledger, balance, obligation, statement và reconciliation của tenant được cấp.
- Quản trị viên nền tảng xem trạng thái điều phối và thực hiện recovery trong phạm vi được ủy quyền.

**Ai được thao tác**:
- Nhân viên vận hành được phân quyền chạy settlement/reconciliation và tạo adjustment/reversal có lý do.
- Quản trị viên được phân quyền khởi tạo dữ liệu, recovery và replay.
- Hệ thống Broker/Exchange chỉ gửi sự kiện vào phạm vi tenant được xác thực.

**Ai không được phép**:
- Người dùng tenant A không được xem hoặc thao tác dữ liệu tenant B.
- Người không có quyền không được replay, settlement, adjustment/reversal hoặc xử lý alert.

**Dữ liệu nhạy cảm**:
- Có. Số dư, nghĩa vụ, giao dịch, sao kê và audit vận hành của từng tenant là dữ liệu nghiệp vụ nhạy cảm.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền và tenant scope trước mọi thao tác.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC tiết lộ dữ liệu tenant khác qua dữ liệu trả về, lỗi hoặc truy vết.
- **SEC-003**: Hệ thống PHẢI ghi nhận audit cho mọi recovery và điều chỉnh có tác động tới số liệu.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có

Hệ thống PHẢI ghi nhận bất biến:

- Ai thực hiện, vai trò và tenant/phạm vi được ủy quyền.
- Thao tác khởi tạo dữ liệu, replay, adjustment/reversal, chạy settlement, chạy reconciliation và xử lý alert.
- Thời điểm, tham chiếu nguồn, correlation và kết quả thao tác.
- Lý do của adjustment/reversal và liên kết tới journal gốc.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: 100% journal được chấp nhận phải cân bằng trước khi có hiệu lực nghiệp vụ.
- **NFR-002**: 100% sự kiện gửi lặp trong kịch bản kiểm thử không được tạo journal, obligation hoặc balance delta trùng.
- **NFR-003**: Dựng lại số dư từ lịch sử ledger phải cho kết quả trùng với góc nhìn số dư của cùng tenant trong các dữ liệu kiểm thử.
- **NFR-004**: Sự kiện lỗi được retry tối đa 5 lần trước khi chuyển sang trạng thái cần xử lý.
- **NFR-005**: Tình trạng migration, backlog xử lý, dead-letter, độ trễ projection và backlog reconciliation phải kiểm tra được bởi người vận hành được cấp quyền.
- **NFR-006**: Backup/restore của một tenant phải được kiểm chứng ở staging trước khi feature được chấp nhận hoàn tất.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: Một tenant mới hoàn tất khởi tạo dữ liệu và có số dư opening sẵn sàng trong một lần vận hành, không tạo số dư opening trùng khi chạy lại.
- **SC-002**: 100% journal trong bộ kịch bản demo được chấp nhận đều cân bằng và truy được về sự kiện nguồn.
- **SC-003**: 100% lần gửi lặp `TradeExecuted` trong kịch bản demo trả kết quả trùng lặp mà không làm tăng số dư hoặc nghĩa vụ lần hai.
- **SC-004**: 100% nghĩa vụ demo đến T+ được chuyển đúng sang trạng thái settlement hoàn tất và số dư khả dụng có thể truy vết về trade nguồn.
- **SC-005**: Đối chiếu phát hiện được 100% sai lệch tổng và chi tiết được tiêm trong kịch bản demo, đồng thời không tự sửa ledger gốc.
- **SC-006**: 100% bài kiểm tra truy vấn chéo tenant ở staging bị từ chối mà không lộ dữ liệu.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- MVP 07 đã xác định các quy tắc transition ledger cho opening, reserve, fill, fee và cancel.
- Alpha/Beta là tenant demo đại diện cho bộ kịch bản chấp nhận.
- Chu kỳ T+ và sao kê EOD được mô phỏng, có thể tua nhanh trong môi trường demo.
- Người vận hành được cấp quyền đã có danh tính xác thực từ hệ thống hiện có.

**Ràng buộc**:
- Dữ liệu vận hành ledger và settlement phải được tách theo tenant; control plane chỉ giữ thông tin điều phối cần thiết, không thay thế lịch sử tenant.
- Tiền, giá trị và khối lượng phải được biểu diễn chính xác, không làm tròn sai lệch do số thực nhị phân.
- Feature chỉ thay đổi artifact workstation và code sau này phải nằm trong repository con đúng phạm vi.

---

## 15. Ngoài phạm vi

- Kết nối VSDC, ngân hàng, clearing house hoặc file statement thật.
- Margin, collateral, phái sinh, corporate action và nghiệp vụ sau giao dịch mở rộng.
- Ledger kế toán tổng hợp production, báo cáo pháp định hoặc thanh toán thật.
- AI tự phân loại, tự quyết định hoặc tự xử lý chênh lệch.
- Tự động xóa/sửa lịch sử ledger để khắc phục lỗi.

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|---|---|---|---|
| Sự kiện trùng làm sai số dư hoặc nghĩa vụ | Trung | Cao | Chống trùng là điều kiện chấp nhận bắt buộc; kiểm thử gửi lại sự kiện và replay |
| Sai chuyển bucket trước/sau T+ | Trung | Cao | Trace từ trade tới obligation và journal; kiểm thử chu kỳ T+ độc lập |
| Rò rỉ số liệu xuyên tenant | Thấp | Cao | Kiểm tra quyền/tenant scope cho mọi luồng và permission test ở staging |
| Sự kiện lỗi bị bỏ sót | Trung | Cao | Retry hữu hạn, trạng thái cần xử lý, chỉ báo backlog và audit recovery |
| Chênh lệch bị che giấu bằng cách sửa lịch sử | Thấp | Cao | Journal append-only; alert và adjustment/reversal có lý do, audit |

---

## 17. Phụ thuộc

- Quy tắc ledger từ MVP 07 và luồng sự kiện hợp lệ từ Broker/Exchange.
- Hạ tầng tenant registry/routing và database-per-tenant đã được xác lập trong workspace.
- Môi trường staging có khả năng sao lưu/khôi phục tenant để xác nhận điều kiện NFR-006.

---

## 18. Câu hỏi mở

Không còn câu hỏi mở chặn plan kỹ thuật. MVP dùng cycle T+ và statement EOD giả lập; kết nối hạ tầng thanh toán thật nằm ngoài phạm vi.

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
