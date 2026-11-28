# Đặc tả tính năng: Triển khai database PostgreSQL

**Branch**: `000044-postgres-database-deployment`  
**Ngày tạo**: 2026-11-28  
**Chế độ Spec**: Full  
**Trạng thái**: Đang triển khai  
**Ngày reconcile cuối**: Chưa reconcile  
**Người phụ trách**: Luyện Hải Đăng  
**Stakeholder xác nhận**: Luyện Hải Đăng  
**Đầu vào**: Dựng một PostgreSQL duy nhất (không replica) trên cụm Kubernetes của server mới, chứa nhiều database riêng cho các service Flex, cấu hình vừa đủ cho tài nguyên server hiện có.

<!-- Lifecycle Trạng thái: Bản nháp (/speckit-specify) -> Đang triển khai (/speckit-implement) -> Hoàn thành (/speckit-converge sau khi 0 gap + Reconcile + Final Specialist Review pass; hoặc sửa tay: Đã thay thế bởi <feature-id>). Spec chỉ mô tả WHY + WHAT; HOW thuộc plan.md. Giữ đủ các đề mục §1–§20; mục không liên quan ghi "Không áp dụng — <lý do ngắn>". -->

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết kỹ thuật (HOW) thuộc về `plan.md`.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:
Flex đang bỏ Oracle dần và chuyển các service (xác thực, sàn giao dịch HNX, agent...) sang PostgreSQL. Server Ubuntu mới đang dựng, chạy cụm Kubernetes một node, nhưng chưa có database nào. Cấu hình PostgreSQL hiện chỉ có trong stack cũ lưu tạm (`flex-environment/temp/`) với mật khẩu mặc định ghi sẵn và cổng database mở trên mọi giao diện mạng — không phù hợp để mang sang server mới. Nếu không dựng, các service chuyển sang PostgreSQL không có nơi chạy trên server mới.

**Tổng quan tính năng**:
Dựng một PostgreSQL duy nhất, một bản chạy (không replica), trên Kubernetes của server mới. Một máy chủ này chứa nhiều database, mỗi service một database và một tài khoản riêng. Mật khẩu do người vận hành cấp, database chỉ truy cập được trong hạ tầng Flex. Các database ở trạng thái trống: v1 không áp schema hay dữ liệu cũ nào. Mức tài nguyên được chọn vừa đủ để cùng chạy với các thành phần khác trên server nhỏ.

---

## 2. Mục tiêu

- **MT-001**: Server mới có PostgreSQL hoạt động ổn định; mỗi service chuyển sang PostgreSQL kết nối được database riêng của mình.
- **MT-002**: Không còn mật khẩu mặc định và database không bị truy cập trực tiếp từ Internet công cộng.
- **MT-003**: PostgreSQL chạy vừa đủ tài nguyên, không làm các thành phần khác trên server bị thiếu RAM hoặc đĩa.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Một máy chủ PostgreSQL, một bản chạy duy nhất, trên cụm Kubernetes của server mới; tự chạy lại sau sự cố hoặc khi server khởi động lại; dữ liệu lưu bền vững.
- **MVP-002**: Nhiều database trên cùng máy chủ đó, mỗi service đã có trong cấu hình hiện hữu (sàn HNX, xác thực/identity, agent) một database và một tài khoản riêng.
- **MVP-003**: Thông tin đăng nhập do người vận hành cấp từ nơi lưu bí mật của Flex, không ghi trong mã nguồn hay cấu hình mặc định.
- **MVP-004**: Kiểm tra trạng thái sức khỏe để người vận hành biết PostgreSQL đang hoạt động hay không.

---

## 4. Người dùng & Bối cảnh

- **Người dùng chính**: Người vận hành hệ thống Flex (hiện là một người duy nhất, đồng thời là người phát triển).
- **Người dùng gián tiếp**: Các service Flex cần lưu dữ liệu (xác thực, sàn HNX, agent).
- **Bối cảnh sử dụng**: Khi dựng server mới và khi một service cần database mới trên máy chủ đang có.
- **Mức độ am hiểu hệ thống/nghiệp vụ**: Kỹ thuật.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Dựng một PostgreSQL chứa nhiều database riêng cho từng service (Ưu tiên: P1)

Người vận hành triển khai PostgreSQL lên Kubernetes của server mới. Sau khi hoàn tất, chỉ có một bản PostgreSQL chạy, trong đó mỗi service có database và tài khoản riêng, kết nối được và không đọc được dữ liệu của service khác.

- **Lý do ưu tiên**: Là nền tảng để các service chuyển khỏi Oracle chạy được trên server mới.
- **Liên quan yêu cầu**: FR-001, FR-002, FR-003, FR-004, FR-005
- **Test độc lập**: Dùng tài khoản từng service kết nối database của mình thành công; thử kết nối database của service khác bị từ chối; đếm số bản PostgreSQL đang chạy bằng 1.

**Acceptance Criteria**:
1. **AC-001**: **Cho trước** cụm Kubernetes chưa có PostgreSQL, **Khi** người vận hành chạy quy trình triển khai, **Thì** đúng một bản PostgreSQL ở trạng thái sẵn sàng nhận kết nối và có đủ database cho các service đã định nghĩa.
2. **AC-002**: **Cho trước** PostgreSQL đã chạy, **Khi** một service dùng tài khoản của mình kết nối database của mình, **Thì** kết nối thành công và service đọc/ghi được dữ liệu của mình.
3. **AC-003**: **Cho trước** PostgreSQL đã chạy, **Khi** tài khoản của service A thử truy cập database của service B, **Thì** truy cập bị từ chối.
4. **AC-004**: **Cho trước** server hoặc tiến trình PostgreSQL khởi động lại, **Khi** hệ thống lên lại, **Thì** PostgreSQL tự chạy lại và dữ liệu trước đó còn nguyên.

### US-002 — Bảo vệ thông tin đăng nhập và truy cập mạng (Ưu tiên: P1)

Người vận hành cấp mật khẩu từ nơi lưu bí mật của Flex; không có mật khẩu mặc định nào hoạt động và database không thể bị truy cập trực tiếp từ Internet công cộng.

- **Lý do ưu tiên**: Database chứa dữ liệu nghiệp vụ; lộ cổng hoặc mật khẩu mặc định là rủi ro lớn nhất.
- **Liên quan yêu cầu**: FR-006, FR-007, FR-008
- **Test độc lập**: Thử đăng nhập bằng mật khẩu mặc định cũ và thử kết nối từ máy ngoài hạ tầng; cả hai phải thất bại.

**Acceptance Criteria**:
1. **AC-005**: **Cho trước** PostgreSQL đã triển khai, **Khi** thử đăng nhập bằng mật khẩu mặc định từng có trong cấu hình cũ, **Thì** đăng nhập bị từ chối.
2. **AC-006**: **Cho trước** PostgreSQL đã triển khai, **Khi** một máy ngoài hạ tầng Flex kết nối trực tiếp tới database từ Internet, **Thì** kết nối không được thiết lập.
3. **AC-007**: **Cho trước** thiếu mật khẩu của một service trong nơi lưu bí mật, **Khi** chạy quy trình triển khai, **Thì** quy trình dừng và báo rõ thiếu mật khẩu nào, không tạo tài khoản với mật khẩu mặc định.

### US-003 — Biết database còn sống hay không (Ưu tiên: P2)

Người vận hành xem được trạng thái sức khỏe của PostgreSQL và biết khi nó ngừng hoạt động.

- **Lý do ưu tiên**: Giảm thời gian phát hiện sự cố; có thể bổ sung sau khi dựng xong.
- **Liên quan yêu cầu**: FR-009
- **Test độc lập**: Dừng PostgreSQL có chủ đích và kiểm tra trạng thái chuyển sang không khỏe.

**Acceptance Criteria**:
1. **AC-008**: **Cho trước** PostgreSQL đang chạy bình thường, **Khi** người vận hành kiểm tra trạng thái, **Thì** thấy trạng thái khỏe.
2. **AC-009**: **Cho trước** PostgreSQL ngừng nhận kết nối, **Khi** người vận hành kiểm tra trạng thái, **Thì** thấy trạng thái không khỏe trong vòng 1 phút.

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Database mới trống là trạng thái hợp lệ và là trạng thái bàn giao của v1; schema do từng service hoặc feature khác đưa vào sau.
- **Dữ liệu không hợp lệ**: Thiếu mật khẩu, tên database/tài khoản trùng nhau hoặc sai định dạng thì quy trình dừng, báo rõ nguyên nhân, không tạo dở dang.
- **Không có quyền**: Tài khoản service chỉ truy cập database của mình; tài khoản quản trị chỉ người vận hành dùng.
- **Lỗi hệ thống / Timeout**: Thiếu RAM hoặc đầy đĩa khiến PostgreSQL không chạy thì báo lỗi rõ và không làm hỏng dữ liệu hiện có.
- **Xung đột / Thao tác lặp lại**: Chạy lại quy trình triển khai nhiều lần PHẢI an toàn: không tạo trùng, không đặt lại mật khẩu ngoài ý muốn, không xóa dữ liệu, không sinh ra bản PostgreSQL thứ hai.
- **Trường hợp biên khác**: Server chỉ có 3,8 GiB RAM, không swap, đĩa 38 GB và còn chạy các thành phần khác; PostgreSQL không được làm các thành phần đó thiếu tài nguyên. Vì chỉ có một bản chạy, khi PostgreSQL khởi động lại các service tạm mất kết nối cho đến khi nó lên lại (chấp nhận được).

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI chạy PostgreSQL trên cụm Kubernetes của server mới và tự chạy lại sau sự cố hoặc khi server khởi động lại. *(Liên quan: US-001, AC-001, AC-004)*
- **FR-002** `[P1]`: Hệ thống PHẢI chỉ chạy một bản PostgreSQL duy nhất cho toàn bộ Flex, không có bản sao (replica) hay cụm nhiều bản. *(Liên quan: US-001, AC-001)*
- **FR-003** `[P1]`: Hệ thống PHẢI lưu dữ liệu bền vững, không mất khi tiến trình hoặc server khởi động lại. *(Liên quan: US-001, AC-004)*
- **FR-004** `[P1]`: Hệ thống PHẢI tạo trên máy chủ đó một database riêng và một tài khoản riêng cho từng service đã định nghĩa (sàn HNX, xác thực/identity, agent). *(Liên quan: US-001, AC-001, AC-002)*
- **FR-005** `[P1]`: Hệ thống KHÔNG ĐƯỢC cho tài khoản của service này truy cập database của service khác. *(Liên quan: US-001, AC-003)*
- **FR-006** `[P1]`: Hệ thống PHẢI lấy mật khẩu của mọi tài khoản từ nơi lưu bí mật của Flex do người vận hành quản lý. *(Liên quan: US-002, AC-005, AC-007)*
- **FR-007** `[P1]`: Hệ thống KHÔNG ĐƯỢC chứa mật khẩu mặc định hoạt động được trong mã nguồn, cấu hình hay log. *(Liên quan: US-002, AC-005)*
- **FR-008** `[P1]`: Hệ thống KHÔNG ĐƯỢC cho phép kết nối trực tiếp tới database từ Internet công cộng; chỉ các service Flex trong cùng hạ tầng và người vận hành qua kênh truy cập an toàn đã được phép. *(Liên quan: US-002, AC-006)*
- **FR-009** `[P2]`: Hệ thống PHẢI cho người vận hành xem trạng thái sức khỏe của PostgreSQL. *(Liên quan: US-003, AC-008, AC-009)*
- **FR-010** `[P1]`: Hệ thống PHẢI cho phép chạy lại quy trình triển khai mà không tạo trùng, không đặt lại mật khẩu ngoài ý muốn và không xóa dữ liệu. *(Liên quan: US-001, AC-001)*

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Mỗi service nghiệp vụ sở hữu đúng một database và một tài khoản; không có truy vấn, quan hệ hay giao dịch xuyên các database nghiệp vụ độc lập dù chúng nằm chung một máy chủ.
- **BR-002**: Tài khoản quản trị PostgreSQL chỉ dành cho người vận hành, không được cấp cho service.
- **BR-003**: Không dùng lại bất kỳ mật khẩu nào từ cấu hình dev/server cũ cho server mới.
- **BR-004**: Không chạy thao tác xóa dữ liệu lưu trữ khi chưa có xác nhận của người vận hành.

**Luồng trạng thái**: Không áp dụng — tính năng hạ tầng, không có máy trạng thái nghiệp vụ.

| Trạng thái hiện tại | Hành động | Trạng thái tiếp theo | Điều kiện |
|---|---|---|---|
| Không áp dụng | Không áp dụng | Không áp dụng | Không áp dụng |

---

## 9. Thực thể dữ liệu

- **Máy chủ PostgreSQL**: Một dịch vụ cơ sở dữ liệu dùng chung của Flex trên server mới; chứa nhiều database nghiệp vụ.
- **Database nghiệp vụ**: Kho dữ liệu riêng của một service (HNX, identity, agent); thuộc đúng một service.
- **Tài khoản service**: Danh tính một service dùng để truy cập database của mình; có mật khẩu lấy từ nơi lưu bí mật.
- **Tài khoản quản trị**: Danh tính của người vận hành để quản lý máy chủ và tạo database.

---

## 10. Phân quyền & Bảo mật

- **Ai được xem / thao tác**: Người vận hành (quản trị, triển khai); service chỉ truy cập database của mình.
- **Ai bị chặn**: Mọi máy ngoài hạ tầng Flex; service này với database của service khác.
- **Dữ liệu nhạy cảm**: Có — dữ liệu nghiệp vụ (tài khoản người dùng, thông tin đầu tư/giao dịch) và mật khẩu kết nối.
- **SEC-001**: Hệ thống PHẢI kiểm tra quyền và phạm vi dữ liệu trước khi thực hiện thao tác.

---

## 11. Audit & Lịch sử thay đổi

- **Có cần audit không**: Có, ở mức vận hành — ghi nhận Ai (người vận hành), Thao tác gì (triển khai, tạo database/tài khoản), Thời điểm và Kết quả; log không được chứa mật khẩu. Audit truy vấn dữ liệu chi tiết nằm ngoài phạm vi v1.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: PostgreSQL PHẢI chạy vừa đủ tài nguyên trên server 3,8 GiB RAM, không swap, đĩa 38 GB cùng các thành phần khác: mức đề xuất là dùng tối đa khoảng 1 GiB RAM và khoảng 10 GiB đĩa cho dữ liệu, không khiến thành phần nào khác bị dừng vì thiếu tài nguyên. Mức cụ thể được chốt ở `plan.md`.
- **NFR-002**: Sau khi server khởi động lại, PostgreSQL PHẢI sẵn sàng nhận kết nối trong vòng 5 phút mà không cần thao tác tay.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% service đã định nghĩa kết nối được database của mình trên server mới ngay sau lần triển khai đầu tiên.
- **SC-002**: 0 mật khẩu mặc định và 0 đường truy cập database từ Internet công cộng, xác nhận bằng kiểm tra từ máy ngoài.
- **SC-003**: Chỉ có đúng 1 bản PostgreSQL chạy trên toàn cụm, phục vụ toàn bộ database.
- **SC-004**: Chạy lại quy trình triển khai lần hai không thay đổi dữ liệu và không gây lỗi.
- **SC-005**: Sau khi khởi động lại server, database sẵn sàng trong vòng 5 phút và dữ liệu cũ còn nguyên.

---

## 14. Giả định & Ràng buộc

- **Giả định**: Phạm vi v1 là server Ubuntu mới đang dựng (không phải server production cũ `213.35.100.75`), chạy cụm Kubernetes một node; manifest nằm trong repo `flex-k8s`.
- **Giả định**: Danh sách database ban đầu là ba database có trong cấu hình hiện hữu (sàn HNX, identity, agent); service khác bổ sung sau trên cùng máy chủ.
- **Giả định**: Một bản chạy duy nhất, không replica, không failover tự động; chấp nhận gián đoạn ngắn khi bảo trì hoặc khi tiến trình khởi động lại.
- **Giả định**: v1 chỉ dựng PostgreSQL và các database trống; không áp schema, không có dữ liệu, không chuyển dữ liệu hay chuyển đổi (convert) từ Oracle hay hệ thống cũ.
- **Giả định**: Không sao lưu trong v1 (quyết định của người vận hành); dữ liệu trong v1 coi như có thể dựng lại.
- **Giả định**: Nơi lưu bí mật của Flex (OpenBao) là nguồn mật khẩu; người vận hành nhập giá trị thật. Cách chuyển mật khẩu vào cụm thuộc `plan.md`.
- **Giả định**: Cấu hình đủ dùng đề xuất cho server 3,8 GiB: một bản chạy, khoảng 256 MiB RAM đảm bảo và tối đa khoảng 1 GiB, khoảng 10 GiB đĩa dữ liệu; chốt chi tiết ở `plan.md`.
- **Ràng buộc**: Server chỉ 3,8 GiB RAM, không swap, đĩa 38 GB; đang đăng nhập bằng `root` (chưa theo nguyên tắc quyền tối thiểu).
- **Ràng buộc**: Không xóa dữ liệu lưu trữ khi chưa xác nhận; không thao tác trên server production cũ.
- **Ràng buộc**: Mật khẩu không ghi vào repo.

---

## 15. Ngoài phạm vi

- Sao lưu và khôi phục dữ liệu (không làm trong v1 theo quyết định của người vận hành).
- Áp dụng schema hoặc dữ liệu cho các database (kể cả changelog trong repo `flex-database`); các database bàn giao ở trạng thái trống.
- Chuyển đổi hay di chuyển dữ liệu từ Oracle, hoặc từ PostgreSQL trên server production cũ.
- Replica, dự phòng chuyển đổi tự động, cụm nhiều bản.
- Database MySQL theo tenant (đã có quy trình riêng).
- Giám sát chi tiết và cảnh báo nâng cao (dashboard, ngưỡng); v1 chỉ có kiểm tra sức khỏe.
- Thay đổi mã nguồn các service để đổi chuỗi kết nối (thuộc từng repo service).
- Tạo user deploy thay `root` trên server (vấn đề hạ tầng riêng).

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp giảm thiểu |
|--------|----------|----------|----------------------|
| Server 3,8 GiB RAM không swap thiếu tài nguyên khi chạy cùng Kubernetes và các thành phần khác | Trung | Cao | Đặt giới hạn RAM/CPU cho PostgreSQL, kiểm tra mức dùng sau triển khai |
| Mất dữ liệu không khôi phục được do không sao lưu | Trung | Cao | Người vận hành đã chấp nhận cho v1 (dữ liệu dựng lại được); phải bổ sung sao lưu trước khi chạy dữ liệu thật |
| Một bản chạy duy nhất: sự cố hoặc khởi động lại làm mọi service mất kết nối tạm thời | Trung | Trung | Chấp nhận trong v1; có kiểm tra sức khỏe để phát hiện sớm |
| Lộ mật khẩu hoặc cổng database ra Internet như cấu hình cũ | Thấp | Cao | FR-006/007/008 và kiểm tra từ máy ngoài (SC-002) |
| Nhiều database dùng chung một máy chủ nên một service ngốn tài nguyên ảnh hưởng service khác | Trung | Trung | Giới hạn tài nguyên chung; theo dõi mức dùng; tách máy chủ khi cần ở phiên bản sau |
| Đăng nhập `root` trên server làm tăng bề mặt rủi ro | Trung | Trung | Ghi nhận ngoài phạm vi; nhắc xử lý riêng |

---

## 17. Phụ thuộc

- Server Ubuntu mới đã có cụm Kubernetes một node và quyền quản trị (hạ tầng đang dựng, xem `flex-environment` và `flex-k8s`).
- OpenBao đã chạy, mở khóa và có mật khẩu thật cho từng service (`flex-environment`).
- Ba database và tài khoản đã định nghĩa trong cấu hình hiện hữu của `flex-environment` làm điểm xuất phát.

---

## 18. Câu hỏi mở

<!-- Tối đa 3 marker [CẦN LÀM RÕ: ...] cho các điểm chặn scope, bảo mật, dữ liệu hoặc UX chính. Ghi "Không có" nếu đã rõ. -->

- Không có — các điểm về phạm vi server, mô hình một bản chạy, sao lưu và chuyển đổi Oracle đã được người vận hành chốt (xem Clarifications).

---

## Clarifications

<!-- Do /speckit-clarify quản lý (`### Session YYYY-MM-DD` -> `- Q: ... → A: ...`). Khi trả lời xong mục ở §18, thay marker bằng `[ĐÃ LÀM RÕ → Clarifications / Session YYYY-MM-DD]`. -->

### Session 2026-11-28

- Q: Phạm vi server và mô hình triển khai? → A: Server mới, triển khai trong Kubernetes; đề xuất cấu hình đủ dùng cho server hiện có.
- Q: Nhiều database nhưng cần mấy bản PostgreSQL? → A: Nhiều database trên một máy chủ, chỉ một bản chạy, không replica.
- Q: Sao lưu và chuyển đổi Oracle? → A: Không sao lưu, không chuyển đổi Oracle; chỉ dựng PostgreSQL.
- Q: Có áp schema/dữ liệu cũ (kể cả database identity) trong v1 không? → A: Không; chỉ triển khai PostgreSQL, không liên quan dữ liệu cũ. Các database bàn giao ở trạng thái trống.

---

## 19. Điều kiện sẵn sàng để lập plan kỹ thuật

<!-- Chi tiết 16 tiêu chí chất lượng được chấm tại checklists/requirements.md (tránh lặp lại tại đây). -->

- [ ] Quality gate tại `checklists/requirements.md` đạt `Pass` hoặc `Pass có điều kiện`.
- [ ] Mọi câu hỏi mở chặn phạm vi/dữ liệu/bảo mật tại §18 đã được giải quyết hoặc ghi nhận ngoại lệ.
- [ ] Đánh giá tác động tài liệu nghiệp vụ (§20) đã hoàn tất (không còn `CHƯA ĐÁNH GIÁ`).

---

## 20. Đánh giá tác động tài liệu nghiệp vụ

<!-- Gate bắt buộc do /speckit-docbiz cập nhật sau lần sửa cuối của spec.md và trước /speckit-plan. -->

- **Trạng thái**: KHÔNG CẦN CẬP NHẬT
- **Căn cứ**: Tính năng chỉ là hạ tầng (§1, §3, §14): dựng một PostgreSQL trên K8s của server mới, không thêm hay đổi luồng nghiệp vụ, vai trò, quy tắc hay thực thể nghiệp vụ đã được tài liệu hóa. Các thực thể ở §9 là thực thể kỹ thuật vận hành (máy chủ, database, tài khoản). Sau khi thu hẹp phạm vi (bỏ áp schema), kết luận không đổi: v1 chỉ còn dựng hạ tầng với database trống. Quét `docs/business/` (00–14 và `business-docs-index.md`) không có tài liệu nghiệp vụ nào nói về PostgreSQL hay hạ tầng triển khai. Cập nhật `docs/architecture/system-map.md` (nếu cần) thuộc giai đoạn `/speckit-plan`, không thuộc tài liệu nghiệp vụ.
- **Tài liệu đã cập nhật**: Không áp dụng
