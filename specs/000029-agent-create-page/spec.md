# Đặc tả tính năng: Trang tạo Agent mới (Full-page Stepper Wizard)

**Branch**: `000029-agent-create-page`  
**Ngày tạo**: 2026-08-06  
**Trạng thái**: Bản nháp  
**Người phụ trách**: Admin  
**Stakeholder xác nhận**: Admin  
**Đầu vào**: Chuyển đổi luồng Tạo Agent mới từ dạng popup/modal thành trang riêng biệt (Full-page Wizard với thanh điều hướng các bước dạng stepper), phù hợp với giao diện mẫu.

---

## Nguyên tắc phạm vi

Spec này chỉ mô tả WHY và WHAT. Các chi tiết HOW sẽ được xử lý trong plan kỹ thuật.

---

## 1. Bối cảnh & vấn đề

**Vấn đề cần giải quyết**:
Hiện tại, khi người dùng bấm vào nút "+ Thêm mới" trong Danh mục Agent, hệ thống mở một popup/modal nhỏ để nhập thông tin Agent. Việc này giới hạn không gian hiển thị khi cấu hình nhiều thuộc tính phức tạp (các bước như thiết lập thủ tục, thông tin cơ quan, tải văn bản, chỉ dẫn Agent, cấu hình kỹ năng và kiểm thử Agent). Người dùng cảm thấy chật chẹp, khó theo dõi tiến trình cấu hình nhiều bước và trải nghiệm không tương xứng với quy trình tạo Nhân viên AI chuyên nghiệp.

**Tổng quan tính năng**:
Chuyển đổi giao diện tạo mới Agent từ modal popup thành một trang độc lập (Full-page Stepper Wizard). Trang mới này có thanh sidebar bên trái điều hướng các bước (1. Thiết lập thông tin chung, 2. Thêm thủ tục hành chính, 3. Thêm thông tin Cơ quan, 4. Thêm văn bản khác, 5. Thiết lập kỹ năng, 6. Kiểm tra nhân viên AI, 7. Phát hành), phần thông tin Agent tổng quan ở góc trên bên trái, nội dung chi tiết của bước ở giữa, và thanh thao tác cố định ở góc dưới bên phải (nút "Hủy", nút "Tiếp tục" / "Lưu").

---

## 2. Mục tiêu

- **MT-001**: Cung cấp không gian làm việc rộng rãi, chuyên nghiệp cho việc khởi tạo và cấu hình Agent chi tiết.
- **MT-002**: Giúp người dùng theo dõi trực quan vị trí bước hiện tại và lộ trình cấu hình Agent qua thanh Stepper dạng vertical navigation.
- **MT-003**: Cho phép người dùng chuyển đổi qua lại giữa các bước cấu hình mà không bị mất dữ liệu tạm thời trước khi lưu/phát hành.

---

## 3. Phạm vi MVP

Trong phiên bản đầu tiên, tính năng PHẢI bao gồm:

- **MVP-001**: Nút "+ Thêm mới" tại trang Danh mục Agent (`/agents`) sẽ điều hướng người dùng sang trang mới (`/agents/create` hoặc `/agents/create-wizard`).
- **MVP-002**: Trang tạo Agent được thiết kế chuẩn theo giao diện mẫu: Thanh Stepper 7 bước bên trái, Header thông tin Agent tóm tắt, vùng nội dung từng bước ở chính giữa, thanh footer chứa nút Hủy và Tiếp tục.
- **MVP-003**: Hỗ trợ nhập và lưu thông tin Bước 1 (Thiết lập thông tin chung - Hình đại diện, Tên, Vai trò, Cấp thực hiện, Cơ quan thực hiện, Chỉ dẫn cho Agent) và chuyển tiếp qua các bước tiếp theo.

---

## 4. Người dùng & Bối cảnh

**Người dùng chính**: Quản trị viên hệ thống, Chuyên viên quản lý Agent / Nhân viên AI.

**Bối cảnh sử dụng**: Khi người dùng cần tạo mới một Nhân viên AI / Agent phục vụ nghiệp vụ (ví dụ: Agent xác thực OTP, Agent tư vấn cơ quan 公安, Agent phê duyệt lệnh, v.v.).

**Mức độ am hiểu hệ thống/nghiệp vụ**: Người dùng nghiệp vụ / Quản trị viên.

---

## 5. Kịch bản người dùng *(bắt buộc)*

### US-001 — Mở trang tạo Agent mới từ danh sách (Ưu tiên: P1)

Là một Quản trị viên Agent, tôi muốn bấm nút "+ Thêm mới" ở trang Danh mục Agent để chuyển sang trang full-page Tạo Agent mới thay vì hiển thị popup modal.

**Lý do ưu tiên**: Luồng truy cập chính để bắt đầu quá trình tạo Agent.

**Liên quan yêu cầu**: FR-001, FR-002

**Test độc lập**: Đăng nhập hệ thống, điều hướng tới `/agents`, bấm vào nút "+ Thêm mới" và kiểm tra URL trình duyệt đổi sang trang tạo Agent mới với đầy đủ layout Stepper Wizard.

**Acceptance Criteria**:

1. **AC-001**: **Cho trước** người dùng đang ở trang Danh mục Agent (`/agents`), **Khi** người dùng nhấp vào nút "+ Thêm mới", **Thì** trình duyệt chuyển hướng đến trang tạo Agent riêng biệt (ví dụ `/agents/create`).
2. **AC-002**: **Cho trước** người dùng ở trang tạo Agent, **Khi** trang vừa tải thành công, **Thì** hiển thị bố cục chuẩn: Header trên cùng ("Tạo nhân viên AI"), Sidebar Stepper 7 bước bên trái với bước 1 "Thiết lập thông tin chung" được active, Form cấu hình ở phần nội dung chính, và nút "Hủy", "Tiếp tục" ở dưới cùng bên phải.

---

### US-002 — Cấu hình bước 1 "Thiết lập thông tin chung" (Ưu tiên: P1)

Là một người tạo Agent, tôi muốn thiết lập hình đại diện, tên agent, vai trò, cấp thực hiện, cơ quan thực hiện và chỉ dẫn cho Agent ở bước 1.

**Lý do ưu tiên**: Thông tin cơ bản bắt buộc để định danh và định hình cách tương tác cho Agent.

**Liên quan yêu cầu**: FR-003, FR-004

**Test độc lập**: Điền các thông tin bắt buộc tại bước 1, bấm "Tiếp tục" và xác nhận hệ thống chuyển sang bước 2 "Thêm thủ tục hành chính...".

**Acceptance Criteria**:

1. **AC-003**: **Cho trước** người dùng đang ở Bước 1 của trang tạo Agent, **Khi** người dùng tải/chọn avatar, nhập Tên*, Vai trò*, Cấp thực hiện (Cấp tỉnh/Cấp xã), Cơ quan thực hiện* và Chỉ dẫn cho Agent*, **Thì** giao diện cập nhật thời gian thực tên và vai trò ở thẻ thông tin tóm tắt góc trên bên trái.
2. **AC-004**: **Cho trước** người dùng chưa nhập các trường bắt buộc (*), **Khi** người dùng bấm nút "Tiếp tục", **Thì** hệ thống hiển thị thông báo lỗi/validation và giữ người dùng ở lại bước hiện tại.
3. **AC-005**: **Cho trước** thông tin bước 1 hợp lệ, **Khi** người dùng bấm "Tiếp tục", **Thì** chuyển trạng thái active sang Bước 2 trên thanh Stepper.

---

### US-003 — Hủy thao tác tạo Agent (Ưu tiên: P2)

Là một người dùng, tôi muốn bấm nút "Hủy" hoặc nút đóng (X) để quay về trang Danh mục Agent mà không lưu dữ liệu dở dang.

**Lý do ưu tiên**: Cho phép người dùng thoát khỏi tiến trình tạo bất cứ lúc nào.

**Liên quan yêu cầu**: FR-005

**Test độc lập**: Bấm nút "Hủy" hoặc biểu tượng (X) trên góc trên bên phải trang tạo agent, hệ thống quay lại trang danh sách `/agents`.

**Acceptance Criteria**:

1. **AC-006**: **Cho trước** người dùng đang ở bất kỳ bước nào trong trang tạo Agent, **Khi** người dùng bấm nút "Hủy" hoặc biểu tượng (X) góc phải trên, **Thì** trình duyệt quay trở lại trang Danh mục Agent (`/agents`).

---

## 6. Trạng thái dữ liệu, lỗi & thao tác lặp

- **Không có dữ liệu**: Khi tạo mới, các ô nhập liệu sẽ ở trạng thái trống hoặc giá trị mặc định.
- **Dữ liệu không hợp lệ**: Hiển thị thông báo lỗi dưới các trường thông tin bắt buộc khi bấm "Tiếp tục".
- **Không có quyền**: Người dùng không có quyền tạo Agent sẽ không thấy nút "+ Thêm mới" hoặc bị chặn khi vào route `/agents/create`.
- **Lỗi hệ thống**: Hiển thị toast notification thông báo lỗi khi không thể tải dữ liệu danh mục hoặc lưu agent.
- **Timeout**: Hiển thị thông báo kết nối thất bại và nút thử lại.
- **Dữ liệu bị thay đổi bởi người khác**: Không áp dụng đối với luồng tạo mới.
- **Người dùng thao tác lặp lại**: Vô hiệu hóa nút "Tiếp tục" / "Lưu" trong khi đang gửi request để tránh submit trùng lặp.
- **Trường hợp biên khác**: Nếu người dùng bấm F5 reload trang, hiển thị cảnh báo xác nhận trước khi làm mới nếu có dữ liệu đã thay đổi chưa lưu.

---

## 7. Yêu cầu chức năng *(bắt buộc)*

- **FR-001** `[P1]`: Hệ thống PHẢI chuyển đổi hành động tạo Agent từ hiển thị popup modal sang điều hướng tới trang mới (`/agents/create`).  
  **Liên quan**: US-001, AC-001
- **FR-002** `[P1]`: Trang mới PHẢI hiển thị giao diện dạng Stepper Wizard full-page gồm 7 bước:
  1. Thiết lập thông tin chung
  2. Thêm thủ tục hành chính Công an
  3. Thêm thông tin Cơ quan Công an
  4. Thêm văn bản khác
  5. Thiết lập kỹ năng
  6. Kiểm tra nhân viên AI
  7. Phát hành  
  **Liên quan**: US-001, AC-002
- **FR-003** `[P1]`: Hệ thống PHẢI cung cấp form "Thiết lập thông tin chung" cho phép nhập: Hình đại diện (chọn từ mẫu hoặc tải lên), Tên agent, Vai trò, Cấp thực hiện (Cấp tỉnh / Cấp xã), Cơ quan thực hiện, và Chỉ dẫn cho Agent (Prompt/Instructions).  
  **Liên quan**: US-002, AC-003
- **FR-004** `[P1]`: Hệ thống PHẢI validate các trường dữ liệu bắt buộc trước khi chuyển sang bước tiếp theo.  
  **Liên quan**: US-002, AC-004, AC-005
- **FR-005** `[P2]`: Hệ thống PHẢI cung cấp nút "Hủy" và nút đóng (X) ở header để người dùng hủy tiến trình và quay lại trang `/agents`.  
  **Liên quan**: US-003, AC-006
- **FR-006** `[P2]`: Hệ thống PHẢI cho phép người dùng nhấp trực tiếp vào danh sách các bước trên sidebar Stepper để chuyển nhanh đến các bước đã đi qua hoặc các bước hợp lệ.  
  **Liên quan**: US-001, AC-002
- **FR-007** `[P2]`: Hệ thống PHẢI hiển thị popup modal cảnh báo xác nhận khi người dùng chọn "Hủy" hoặc thoát trang khi form đang ở trạng thái đã thay đổi dữ liệu chưa lưu (dirty form).  
  **Liên quan**: US-003, AC-006

---

## 8. Quy tắc nghiệp vụ

- **BR-001**: Tên Agent và Vai trò là thông tin bắt buộc, không được để trống.
- **BR-002**: Người dùng phải hoàn thành hợp lệ các thông tin bắt buộc của bước hiện tại mới được phép bấm "Tiếp tục" để sang bước sau.
- **BR-003**: Trạng thái hiển thị mặc định của Agent khi mới khởi tạo là "Chưa phát hành" cho đến khi hoàn thành bước 7 (Phát hành).

---

## 9. Thực thể dữ liệu

- **Agent**: Đại diện cho một Nhân viên AI trong hệ thống, bao gồm các thuộc tính: Avatar, Name, Role, ExecutionLevel, Organization, Instructions, Status (Draft/Published), Skills, KnowledgeDocs.

---

## 10. Phân quyền & Bảo mật

**Ai được xem**: Quản trị viên, Chuyên viên quản lý Agent có quyền xem danh sách và truy cập trang tạo.
**Ai được thao tác**: Người dùng có role `AGENT_ADMIN` hoặc `AGENT_CREATE`.
**Ai không được phép**: Người dùng chỉ có quyền xem (Viewer) hoặc không được cấp quyền quản lý Agent.

- **SEC-001**: Hệ thống PHẢI kiểm tra quyền tạo Agent trước khi cho phép truy cập route `/agents/create`.

---

## 11. Audit & Lịch sử thay đổi

**Có cần audit không**: Có
Hệ thống PHẢI ghi nhận: Người tạo, Thời điểm tạo, Trạng thái khởi tạo của Agent.

---

## 12. Yêu cầu phi chức năng

- **NFR-001**: Trang tạo Agent mới phải phản hồi thao tác chuyển bước mượt mà (dưới 300ms).
- **NFR-002**: Thiết kế responsive, đáp ứng hiển thị chuẩn trên màn hình desktop độ phân giải từ 1280px trở lên.

---

## 13. Tiêu chí thành công *(bắt buộc)*

- **SC-001**: 100% lượt bấm "+ Thêm mới" từ trang Quản lý Agent mở trang tạo mới độc lập thay vì mở popup.
- **SC-002**: Giao diện trang tạo Agent khớp thiết kế mẫu với thanh Stepper 7 bước và form thông tin chung.

---

## 14. Giả định & Ràng buộc

**Giả định**:
- Tái sử dụng các API service Agent hiện có cho việc khởi tạo và lưu thông tin Agent.

**Ràng buộc**:
- Phải tuân thủ theme Skote hiện tại của ứng dụng Frontend (`flex-microfrontend`).

---

## 15. Ngoài phạm vi

- Thay đổi logic backend API xử lý lưu agent (chỉ thay đổi UI/UX luồng frontend).

---

## 16. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Người dùng lỡ tay bấm Hủy mất dữ liệu đã nhập | Trung bình | Trung bình | Thêm hộp thoại xác nhận khi bấm Hủy nếu form đã dirty |

---

## 17. Phụ thuộc

- Trái tim routing của ứng dụng Angular (`flex-microfrontend` router).

---

## 18. Câu hỏi mở

- Không có.

---

## Clarifications

### Session 2026-08-06

- Q: Khi thao tác trên Stepper Wizard 7 bước ở sidebar bên trái, người dùng có thể nhấp chuột trực tiếp vào biểu tượng các bước để chuyển trang không? → A: Cho phép nhấp chọn chuyển lại các bước đã đi qua (hoặc các bước đã hợp lệ) trên sidebar Stepper.
- Q: Khi người dùng bấm nút "Hủy" hoặc biểu tượng (X) trên góc phải trang Tạo Agent trong khi form đang có dữ liệu chưa lưu, hệ thống sẽ xử lý thế nào? → A: Hiển thị hộp thoại xác nhận cảnh báo "Bạn có chắc chắn muốn rời khỏi trang? Dữ liệu vừa nhập chưa được lưu."

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
