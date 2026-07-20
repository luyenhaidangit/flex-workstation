# Đặc tả tính năng: Migrate dữ liệu HNX khỏi in-memory

**Branch**: `000018-hnx-data-migration`  
**Ngày tạo**: 2026-07-20  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Rà soát FE, BE và `flex-database` để xác định dữ liệu thuộc HNX đang lưu in-memory, sau đó migrate dần sang nguồn dữ liệu HNX bền vững mà vẫn giữ hoạt động của các luồng hiện tại.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:

Một phần trạng thái và dữ liệu phục vụ HNX hiện chỉ tồn tại trong bộ nhớ của BE. Dữ liệu có thể mất khi service khởi động lại, không có lịch sử đáng tin cậy để đối chiếu, và FE có nguy cơ nhận dữ liệu khác nhau tùy vòng đời của process. Trong khi đó, `flex-database` đã có phạm vi database HNX và các migration nền tảng cho reference data, order, order history, trade và outbox.

Nếu migrate toàn bộ cùng lúc, rủi ro thay đổi hành vi giao dịch và khó xác định nguyên nhân khi có sai lệch sẽ cao. Cần một lộ trình từng phần, bắt đầu bằng việc inventory và xác định dữ liệu HNX, sau đó chuyển từng nhóm có tiêu chí đối chiếu, fallback và rollback rõ ràng.

**Tổng quan tính năng**:

Tính năng này rà soát xuyên FE, BE và database để lập danh mục dữ liệu HNX, xác định nhóm nào đang in-memory và nhóm nào đã có nguồn dữ liệu bền vững. Hệ thống sau đó hỗ trợ migrate từng nhóm dữ liệu HNX theo thứ tự ưu tiên, bảo đảm các màn hình và luồng nghiệp vụ hiện tại tiếp tục nhận dữ liệu đúng trong suốt quá trình chuyển đổi.

## 2. Mục tiêu

- **MT-001**: Có danh mục được xác nhận về nguồn, chủ sở hữu và vòng đời của toàn bộ dữ liệu HNX đang được FE/BE sử dụng.
- **MT-002**: Loại bỏ việc mất dữ liệu HNX do restart đối với từng nhóm đã migrate thành công.
- **MT-003**: Cho phép đối chiếu dữ liệu trước/sau migration và phát hiện sai lệch trước khi chuyển nhóm tiếp theo.

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Rà soát và phân loại các dữ liệu HNX hiện diện trong FE, BE và `flex-database`, bao gồm tối thiểu reference data, order, order history, trade, outbox và các state HNX đang in-memory.
- **MVP-002**: Xác định thứ tự migrate từng nhóm dữ liệu HNX, với tiêu chí hoàn thành, kiểm tra nhất quán và phương án quay lại cho mỗi nhóm.
- **MVP-003**: Migrate nhóm dữ liệu HNX được chọn đầu tiên mà không làm gián đoạn các luồng FE/BE đang hỗ trợ HNX.
- **MVP-004**: Ghi nhận trạng thái nguồn dữ liệu đang được sử dụng để có thể vận hành chuyển tiếp từng nhóm.

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Người vận hành hệ thống, developer/reviewer của FE/BE/DB và người dùng nghiệp vụ theo dõi thị trường HNX, đặt lệnh hoặc xem trạng thái giao dịch.

**Bối cảnh sử dụng**: Khi hệ thống cần restart, kiểm tra lịch sử giao dịch, đối chiếu dữ liệu hoặc triển khai từng đợt chuyển dữ liệu HNX từ in-memory sang nguồn bền vững.

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ và quản trị viên hệ thống.

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Rà soát phạm vi dữ liệu HNX (Ưu tiên: P1)

Người vận hành cần biết dữ liệu HNX nào đang được FE hiển thị, BE tạo/đọc/cập nhật, và database đã hỗ trợ đến đâu để quyết định phạm vi migrate an toàn.

**Lý do ưu tiên**: Nếu không có inventory, migration dễ bỏ sót state hoặc chuyển nhầm dữ liệu không thuộc HNX.

**Liên quan yêu cầu**: FR-001, FR-002, FR-003

**Test độc lập**: Review artifact inventory và đối chiếu với source FE, BE, DB mà không cần thay đổi runtime.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** source FE, BE và DB hiện tại, **Khi** thực hiện review, **Thì** mỗi nhóm dữ liệu HNX được ghi nhận nguồn hiện tại, consumer, quyền sở hữu và trạng thái migrate.
2. **AC-002**: **Cho trước** một dữ liệu không thuộc HNX, **Khi** inventory được review, **Thì** dữ liệu đó được đánh dấu ngoài phạm vi và không bị đưa vào đợt migrate MVP.

### US-002 — Chuyển từng nhóm dữ liệu HNX sang nguồn bền vững (Ưu tiên: P1)

Người vận hành cần chuyển một nhóm dữ liệu HNX theo từng đợt để dữ liệu vẫn dùng được trong luồng hiện tại và không mất sau restart.

**Lý do ưu tiên**: Đây là kết quả nghiệp vụ chính, giảm rủi ro mất trạng thái và cho phép rollout có kiểm soát.

**Liên quan yêu cầu**: FR-004, FR-005, FR-006, FR-007

**Test độc lập**: Chạy luồng HNX trước migration, migrate một nhóm, restart service và xác minh dữ liệu/luồng tương ứng vẫn nhất quán.

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** một nhóm dữ liệu HNX được chọn, **Khi** migration hoàn tất, **Thì** dữ liệu mới và dữ liệu cần giữ lại được đọc từ nguồn bền vững đã xác nhận.
2. **AC-004**: **Cho trước** service khởi động lại sau migration, **Khi** người dùng mở lại luồng HNX, **Thì** dữ liệu đã migrate không bị mất hoặc tự quay về trạng thái rỗng.
3. **AC-005**: **Cho trước** phát hiện sai lệch hoặc lỗi trong đợt migration, **Khi** kích hoạt phương án an toàn, **Thì** luồng HNX tiếp tục có thể phục vụ theo trạng thái đã xác nhận và dữ liệu lỗi được ghi nhận để xử lý.

### US-003 — Đối chiếu dữ liệu và theo dõi tiến độ (Ưu tiên: P2)

Reviewer cần xem kết quả đối chiếu, nhóm nào đã chuyển, nhóm nào còn in-memory và các sai lệch chưa xử lý trước khi phê duyệt đợt tiếp theo.

**Lý do ưu tiên**: Có thể triển khai nhiều đợt mà vẫn kiểm soát được tính đúng đắn và khả năng truy nguyên.

**Liên quan yêu cầu**: FR-008, FR-009

**Test độc lập**: Tạo một bộ dữ liệu kiểm thử có số lượng và trạng thái biết trước, chạy đối chiếu và kiểm tra báo cáo kết quả.

**Acceptance Criteria**:

1. **AC-006**: **Cho trước** dữ liệu nguồn và dữ liệu đích có cùng nội dung, **Khi** đối chiếu, **Thì** kết quả xác nhận khớp và cho biết nhóm đã sẵn sàng.
2. **AC-007**: **Cho trước** dữ liệu có khác biệt, **Khi** đối chiếu, **Thì** hệ thống nêu được nhóm, phạm vi sai lệch và trạng thái xử lý; không tự động đánh dấu thành công.

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Phân biệt rõ dữ liệu chưa phát sinh với dữ liệu bị mất; không tự tạo dữ liệu nghiệp vụ ngoài quy tắc hiện có.
- **Dữ liệu không hợp lệ**: Không migrate bản ghi không đạt quy tắc nghiệp vụ; ghi nhận lý do để review.
- **Không có quyền**: Chỉ vai trò được cấp quyền vận hành migration/đối chiếu mới được thực hiện thao tác; người dùng thường chỉ xem dữ liệu trong phạm vi được cấp.
- **Lỗi hệ thống**: Đợt migrate không được đánh dấu hoàn tất; giữ lại khả năng phục vụ an toàn và thông tin lỗi có thể truy nguyên.
- **Timeout**: Có thể tiếp tục hoặc chạy lại theo batch mà không tạo bản ghi trùng hoặc làm sai dữ liệu đã thành công.
- **Dữ liệu bị thay đổi bởi người khác**: Phát hiện xung đột và yêu cầu đối chiếu lại, không âm thầm ghi đè.
- **Người dùng thao tác lặp lại**: Thao tác migration/đối chiếu lặp lại phải idempotent hoặc trả về kết quả đã xử lý.
- **Trường hợp biên khác**: Dữ liệu chưa xác định thuộc HNX phải được đưa vào danh sách review, không tự đưa vào MVP.

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI lập inventory các nhóm dữ liệu HNX được FE, BE và DB sử dụng, gồm nguồn hiện tại và consumer. Liên quan: US-001, AC-001.
- **FR-002** `[P1]`: Hệ thống PHẢI phân biệt dữ liệu HNX với dữ liệu ngoài HNX trước khi migrate. Liên quan: US-001, AC-002.
- **FR-003** `[P1]`: Hệ thống PHẢI xác định nhóm dữ liệu đang in-memory, nhóm đã có nguồn bền vững và nhóm còn thiếu nguồn phù hợp. Liên quan: US-001, AC-001.
- **FR-004** `[P1]`: Hệ thống PHẢI cho phép migrate từng nhóm dữ liệu HNX theo đợt có trạng thái bắt đầu, đang xử lý, thành công hoặc thất bại. Liên quan: US-002, AC-003.
- **FR-005** `[P1]`: Hệ thống PHẢI duy trì tính nhất quán của dữ liệu HNX trong các luồng FE/BE hiện có khi một nhóm đang được chuyển đổi. Liên quan: US-002, AC-003, AC-004.
- **FR-006** `[P1]`: Hệ thống KHÔNG ĐƯỢC đánh dấu migration thành công nếu còn sai lệch chưa được chấp nhận. Liên quan: US-002, AC-005, US-003, AC-007.
- **FR-007** `[P1]`: Hệ thống PHẢI hỗ trợ chạy lại an toàn một đợt thất bại hoặc gián đoạn mà không tạo dữ liệu trùng. Liên quan: US-002, AC-005.
- **FR-008** `[P2]`: Hệ thống PHẢI cung cấp kết quả đối chiếu cho từng nhóm dữ liệu sau migration. Liên quan: US-003, AC-006, AC-007.
- **FR-009** `[P2]`: Hệ thống PHẢI cho biết nhóm HNX nào đã migrate, đang chuyển đổi, còn in-memory hoặc bị chặn bởi sai lệch. Liên quan: US-003, AC-006, AC-007.
- **FR-010** `[P1]`: Hệ thống KHÔNG ĐƯỢC mở rộng migration sang dữ liệu không thuộc HNX trong MVP. Liên quan: US-001, AC-002.

## 8. Quy tắc nghiệp vụ

- **BR-001**: Dữ liệu chỉ được migrate khi đã xác định thuộc phạm vi HNX và có owner chịu trách nhiệm đối chiếu.
- **BR-002**: Mỗi đợt migration phải có kết quả đối chiếu trước khi được xem là hoàn tất.
- **BR-003**: Sai lệch dữ liệu phải được giữ lại để điều tra; không được tự động xóa hoặc ghi đè dữ liệu nguồn chưa được xác nhận.
- **BR-004**: Migration theo từng nhóm không được làm thay đổi ý nghĩa nghiệp vụ của order, order history, trade, reference data hoặc outbox.

**Luồng trạng thái nếu có**:

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Chưa đánh giá | Inventory | Đã phân loại | Xác định nhóm và phạm vi HNX |
| Đã phân loại | Bắt đầu migrate | Đang migrate | Có owner và tiêu chí kiểm tra |
| Đang migrate | Đối chiếu đạt | Hoàn tất | Không còn sai lệch blocker |
| Đang migrate | Lỗi/sai lệch | Thất bại hoặc Chờ xử lý | Có log và khả năng chạy lại/an toàn |

## 9. Thực thể dữ liệu

- **HNX reference data**: Dữ liệu mô tả instrument và các thông tin tham chiếu phục vụ giao dịch HNX.
- **HNX order**: Lệnh giao dịch HNX và trạng thái nghiệp vụ của lệnh.
- **HNX order history**: Lịch sử thay đổi trạng thái hoặc sự kiện của lệnh.
- **HNX trade**: Kết quả khớp giao dịch HNX.
- **HNX outbox event**: Sự kiện cần phát hành hoặc xử lý tiếp cho các consumer liên quan.
- **HNX runtime state**: Các trạng thái HNX đang được giữ trong process, cần được inventory để quyết định migrate hoặc loại trừ có chủ đích.
- **Migration batch**: Một đợt chuyển đổi và đối chiếu của một nhóm dữ liệu HNX.

## 10. Phân quyền & Bảo mật

**Ai được xem**:
- Người dùng được cấp quyền xem dữ liệu HNX trong phạm vi nghiệp vụ.
- Reviewer và vận hành được cấp quyền xem tiến độ, kết quả đối chiếu và lỗi migration.

**Ai được thao tác**:
- Chỉ operator/admin được ủy quyền mới được bắt đầu, chạy lại hoặc xác nhận một đợt migration.

**Ai không được phép**:
- Người dùng thường không được tự sửa dữ liệu migration hoặc truy cập dữ liệu HNX ngoài phạm vi quyền.

**Dữ liệu nhạy cảm**:
- Có thể chứa thông tin lệnh, tài khoản hoặc audit; chỉ hiển thị theo phạm vi quyền và không ghi thông tin bí mật vào log/report.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền trước khi cho phép thao tác migration, đối chiếu hoặc xử lý sai lệch.
- **SEC-002**: Hệ thống KHÔNG ĐƯỢC cho người dùng truy cập dữ liệu ngoài phạm vi HNX và quyền được cấp.

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có.

Hệ thống PHẢI ghi nhận ai khởi tạo/chạy lại/xác nhận migration, nhóm dữ liệu, thời điểm, kết quả, số liệu đối chiếu, sai lệch và lý do xử lý thủ công nếu có.

## 12. Yêu cầu phi chức năng

- **NFR-001**: Migration theo đợt không được làm gián đoạn các luồng đọc/hiển thị HNX đã được xác định là đang phục vụ người dùng.
- **NFR-002**: Sau mỗi đợt, reviewer phải có thể xác định kết quả và sai lệch trong vòng 5 phút từ báo cáo vận hành.
- **NFR-003**: Chạy lại cùng một đợt với cùng dữ liệu đầu vào không được làm tăng bản ghi nghiệp vụ hợp lệ ngoài kết quả mong đợi.

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% nhóm dữ liệu HNX được FE/BE sử dụng trong phạm vi review có trạng thái inventory và owner rõ ràng trước khi migrate nhóm đầu tiên.
- **SC-002**: Nhóm dữ liệu MVP được migrate thành công qua restart và không mất dữ liệu đã xác nhận trong ít nhất 3 lần kiểm thử liên tiếp.
- **SC-003**: 100% đợt migration có kết quả đối chiếu; mọi sai lệch blocker đều ngăn trạng thái hoàn tất.
- **SC-004**: Không phát sinh bản ghi nghiệp vụ trùng trong 3 lần chạy lại trên bộ dữ liệu kiểm thử định trước.
- **SC-005**: Các luồng FE HNX chính vẫn hoàn thành được với tỷ lệ thành công tối thiểu 95% trong kiểm thử hồi quy sau mỗi đợt.

## 14. Giả định & Ràng buộc

**Giả định**:
- `flex-database` tiếp tục là nguồn quản lý migration và schema cho database HNX.
- Phạm vi MVP chỉ gồm dữ liệu thuộc HNX; dữ liệu broker/VSD và các market khác được xử lý ở feature riêng.
- Các contract FE/BE hiện có được giữ tương thích trong giai đoạn chuyển đổi trừ khi có spec riêng.

**Ràng buộc**:
- Changeset database đã phát hành phải được giữ bất biến; thay đổi mới phải đi qua release migration phù hợp.
- Không được commit secret hoặc thông tin kết nối thực tế.
- Không được chuyển nhóm dữ liệu tiếp theo khi nhóm trước còn blocker chưa được xử lý hoặc phê duyệt.

## 15. Ngoài phạm vi

- Migrate dữ liệu broker, VSD, HoSE hoặc market không thuộc HNX.
- Thiết kế lại toàn bộ matching engine hoặc thay đổi quy tắc khớp lệnh.
- Thay đổi UX ngoài những điều cần thiết để hiển thị trạng thái/dữ liệu HNX đúng.
- Xóa ngay các implementation in-memory không còn dùng; việc dọn dẹp chỉ thực hiện sau khi có bằng chứng và task riêng.
- Thiết kế chi tiết table, API, ORM, deployment hoặc công cụ migration.

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|---|---|---|---|
| Inventory bỏ sót state HNX đang giữ trong process | Trung | Cao | Review chéo FE/BE/DB, test restart và phê duyệt inventory trước migration |
| Dữ liệu nguồn và đích khác mô hình hoặc trạng thái | Trung | Cao | Mapping/đối chiếu theo nhóm, chặn hoàn tất khi có sai lệch |
| Migration làm thay đổi contract FE/BE hiện tại | Thấp | Cao | Regression contract và giữ tương thích trong từng đợt |
| Chạy lại tạo duplicate hoặc mất event | Trung | Cao | Yêu cầu idempotency, kiểm thử timeout/retry và audit batch |

## 17. Phụ thuộc

- `flex-database` phải có migration và dữ liệu HNX phù hợp với nhóm được chọn.
- FE và BE phải cung cấp đủ thông tin consumer/contract để đối chiếu sau migration.
- Cần owner nghiệp vụ xác nhận phạm vi HNX và xử lý các sai lệch không thể tự quyết định.

## 18. Câu hỏi mở

- [CẦN LÀM RÕ: Nhóm dữ liệu HNX nào được chọn làm đợt migrate đầu tiên sau inventory — reference data, order/order history, trade, outbox hay runtime state?]
- [CẦN LÀM RÕ: Trong giai đoạn chuyển tiếp, có cho phép đọc song song nguồn cũ và nguồn mới để đối chiếu hay phải chuyển hẳn từng nhóm tại thời điểm cutover?]

## Clarifications

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

- [x] Vấn đề cần giải quyết đã rõ.
- [x] MVP đã được xác định.
- [x] Luồng P1 có Acceptance Criteria đầy đủ.
- [x] Yêu cầu chức năng chính đã có ID.
- [x] Quy tắc nghiệp vụ quan trọng đã được ghi nhận.
- [ ] Phân quyền/bảo mật đã rõ hoặc được đánh dấu là câu hỏi mở.
- [x] Ngoài phạm vi đã rõ.
- [ ] Các câu hỏi mở quan trọng đã được trả lời hoặc được chấp nhận là rủi ro.
