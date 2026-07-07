# Đặc tả tính năng: Mở Nhanh Các Project Code

**Branch**: `000002-cmd-open-projects`

**Ngày tạo**: 2026-07-07

**Trạng thái**: Bản nháp

**Đầu vào**: Mô tả người dùng: "Muốn tạo nhanh một command cmd mà khi click vào mở nhanh luôn các project code như api gateway, be, fe,..."

---

## 0. Tổng quan

Tính năng này cung cấp một file lệnh (.cmd) có thể click đúp để mở đồng thời tất cả các project code trong workspace (API Gateway, Auth Service, Microfrontend, v.v.) bằng một thao tác duy nhất. Mục tiêu là giúp developer tiết kiệm thời gian setup môi trường làm việc vào đầu mỗi buổi làm việc, thay vì phải mở từng project thủ công.

---

## 1. Mục tiêu

- **MĐ-01**: Developer mở được toàn bộ project code trong vòng dưới 10 giây chỉ bằng một thao tác click
- **MĐ-02**: Giảm thiểu thao tác lặp lại khi bắt đầu làm việc với workspace Flex
- **MĐ-03**: Danh sách project được tự động lấy từ cấu hình workspace, không cần cập nhật thủ công khi thêm/bớt repo

---

## 2. Người dùng & Bối cảnh

**Người dùng chính**: Developer làm việc trong flex-workstation (người quản lý và phát triển các sub-repo của Flex)

**Bối cảnh sử dụng**: Đầu buổi làm việc hoặc khi cần mở lại toàn bộ môi trường code sau khi đóng máy/khởi động lại; người dùng đang ở thư mục gốc của workspace

**Trình độ kỹ thuật**: Developer có kinh nghiệm, quen thuộc với VS Code và Windows; không cần hướng dẫn sử dụng

---

## 3. Kịch bản người dùng *(bắt buộc)*

### Kịch bản 1 — Mở toàn bộ project bằng một click (Ưu tiên: P1)

Developer vào buổi sáng, muốn mở ngay tất cả project để làm việc. Họ vào thư mục workspace, tìm file `OPEN_CODE.cmd`, click đúp vào đó. Tất cả các project (flex-api-gateway, flex-auth-service, flex-microfrontend, flex-agents, flex-environment) được mở trong một cửa sổ VS Code duy nhất dưới dạng multi-root workspace.

**Lý do ưu tiên**: Đây là luồng chính — giải quyết trực tiếp nhu cầu cốt lõi của tính năng

**Test độc lập**: Click đúp file trên máy có workspace đã bootstrap xong, kiểm tra một cửa sổ VS Code mở với tất cả repos hiển thị trong Explorer panel

**Acceptance Scenarios**:

1. **Cho trước** workspace đã bootstrap và tất cả sub-repo đã được clone, **Khi** người dùng click đúp vào `OPEN_CODE.cmd`, **Thì** một cửa sổ VS Code duy nhất mở ra với tất cả project hiển thị trong Explorer panel dưới dạng multi-root workspace
2. **Cho trước** người dùng thêm repo mới vào `workstation.json` và clone repo đó, **Khi** chạy `OPEN_CODE.cmd`, **Thì** repo mới xuất hiện trong cùng cửa sổ VS Code mà không cần sửa file launcher

---

### Kịch bản 2 — Chạy từ command line (Ưu tiên: P2)

Developer đang trong terminal tại thư mục workspace muốn kích hoạt launcher mà không cần dùng chuột.

**Lý do ưu tiên**: Tiện ích bổ sung cho developer quen làm việc qua terminal

**Test độc lập**: Gõ `OPEN_CODE.cmd` trong terminal tại workspace root, kiểm tra kết quả tương tự kịch bản 1

**Acceptance Scenarios**:

1. **Cho trước** terminal đang ở workspace root, **Khi** gõ lệnh `OPEN_CODE.cmd` và Enter, **Thì** tất cả project được mở giống như khi click đúp

---

### Trường hợp biên

- Điều gì xảy ra khi một sub-repo chưa được clone (thư mục chưa tồn tại)? → File launcher bỏ qua repo đó và tiếp tục mở các repo còn lại; thông báo ngắn cho người dùng biết repo nào bị bỏ qua
- Hệ thống xử lý thế nào khi editor chưa được cài? → Hiển thị thông báo lỗi rõ ràng thay vì im lặng thất bại

---

## 4. Yêu cầu chức năng *(bắt buộc)*

- **YC-001**: Hệ thống PHẢI đọc danh sách repo từ `workstation.json` để xác định project cần mở
- **YC-002**: Người dùng PHẢI có thể kích hoạt bằng cách click đúp vào file `.cmd` từ File Explorer
- **YC-003**: Hệ thống PHẢI mở tất cả project trong một cửa sổ VS Code duy nhất dưới dạng multi-root workspace
- **YC-004**: Hệ thống PHẢI bỏ qua project có thư mục chưa tồn tại thay vì dừng toàn bộ quá trình
- **YC-005**: Hệ thống PHẢI hiển thị thông báo khi project bị bỏ qua do thư mục không tồn tại
- **YC-006**: File launcher KHÔNG ĐƯỢC yêu cầu cài đặt thêm phần mềm ngoài những gì đã có trong bootstrap
- **YC-007**: Người dùng PHẢI có thể chạy launcher từ cả File Explorer lẫn terminal

---

## 5. Yêu cầu phi chức năng

- **YCPCK-001**: Toàn bộ quá trình mở tất cả project hoàn tất trong vòng 10 giây trên máy phổ thông
- **YCPCK-002**: File launcher hoạt động được trên Windows 10 và Windows 11

---

## 7. Tiêu chí thành công *(bắt buộc)*

- **TC-001**: Tất cả project trong `workstation.json` được mở chỉ trong một thao tác click, không cần thêm bước nào
- **TC-002**: Toàn bộ project mở xong trong vòng 10 giây
- **TC-003**: Developer không cần nhớ tên hay đường dẫn của từng project để mở chúng
- **TC-004**: Khi thêm repo mới vào `workstation.json`, launcher tự động nhận diện mà không cần chỉnh sửa file launcher

---

## 8. Giả định & Ràng buộc

**Giả định**:
- Developer đang dùng VS Code làm editor chính (đây là editor đã được dùng trong workspace setup)
- Workspace đã được bootstrap thành công ít nhất một lần trước khi dùng launcher
- File launcher nằm trong workspace root cùng cấp với `workstation.json`
- Hệ điều hành là Windows (phù hợp với định dạng `.cmd`)

**Ràng buộc**:
- File PHẢI là định dạng `.cmd` để có thể click đúp từ File Explorer trên Windows
- PHẢI tương thích với cơ chế bootstrap hiện có — không thay đổi cấu trúc workspace

---

## 9. Ngoài phạm vi

- Hỗ trợ macOS hoặc Linux (không dùng .cmd)
- Cho phép chọn subset project để mở (chọn lọc từng project)
- Giao diện đồ họa (GUI) để chọn project
- Tự động cài đặt VS Code nếu chưa có
- Mở terminal hoặc run server của từng project (chỉ mở code editor)

---

## 10. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Editor không phải VS Code hoặc chưa được thêm vào PATH | Trung | Trung | Kiểm tra và thông báo lỗi rõ ràng thay vì im lặng thất bại |
| workstation.json thay đổi cấu trúc trong tương lai | Thấp | Thấp | Launcher đọc trực tiếp từ file JSON — nếu cấu trúc thay đổi cần cập nhật launcher |

---

## 11. Phụ thuộc

- Phụ thuộc vào `workstation.json` làm nguồn danh sách repo — cần tồn tại và đúng cấu trúc
- Phụ thuộc vào VS Code được cài và có thể gọi từ command line
- Bootstrap (`SYNC_WORKSPACE.cmd`) cần chạy trước để các sub-repo tồn tại

---

## 12. Câu hỏi mở

Không còn câu hỏi mở. Tất cả đã được làm rõ:

- **Vị trí file launcher**: Đặt tại workspace root, cùng cấp với `SYNC_WORKSPACE.cmd` và `OPEN_CLAUDE.cmd` — nhất quán với convention hiện có của workspace.
