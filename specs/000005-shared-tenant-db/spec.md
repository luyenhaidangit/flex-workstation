# Đặc tả tính năng: Shared và tenant database cho flex-environment

**Branch**: `[000005-shared-tenant-db]`

**Ngày tạo**: 2026-07-08

**Trạng thái**: Bản nháp

**Đầu vào**: Mô tả người dùng: "C:\Workspace\Project\flex-workstation\flex-environment triển khai thêm postgree cho db share, mysql cho db tenant giúp tôi"

---

## 0. Tổng quan

Tính năng này bổ sung năng lực môi trường để cung cấp riêng một shared database dùng chung và một tenant database phục vụ dữ liệu theo tenant cho `flex-environment`. Mục tiêu là giúp nhóm phát triển và vận hành có môi trường dữ liệu rõ ràng, tái lập được, giảm nhầm lẫn giữa dữ liệu dùng chung và dữ liệu theo tenant. Người hưởng lợi chính là developer, maintainer và người vận hành môi trường Flex.

---

## 1. Mục tiêu

- **MĐ-01**: Người dùng có thể chuẩn bị môi trường có đủ shared database và tenant database trong một lần thiết lập chuẩn.
- **MĐ-02**: Dữ liệu dùng chung và dữ liệu theo tenant được phân tách rõ ràng để giảm lỗi cấu hình và thao tác nhầm.
- **MĐ-03**: Tài liệu môi trường đủ rõ để người mới có thể kiểm tra trạng thái database mà không cần hỏi lại maintainer.

---

## 2. Người dùng & Bối cảnh

**Người dùng chính**: Developer và maintainer đang thiết lập hoặc kiểm tra `flex-environment`.

**Bối cảnh sử dụng**: Khi cần bootstrap môi trường local hoặc shared development cho hệ Flex, người dùng cần có sẵn hai loại database phục vụ các nhóm dữ liệu khác nhau.

**Trình độ kỹ thuật**: Có khả năng chạy command, đọc cấu hình môi trường và kiểm tra trạng thái service cơ bản.

---

## 3. Kịch bản người dùng *(bắt buộc)*

### Kịch bản 1 — Thiết lập đủ database môi trường (Ưu tiên: P1)

Developer chạy quy trình thiết lập môi trường và nhận được một môi trường có cả shared database lẫn tenant database, mỗi loại có định danh và mục đích sử dụng rõ ràng.

**Lý do ưu tiên**: Đây là giá trị cốt lõi của tính năng; nếu thiếu một trong hai database thì môi trường không đáp ứng nhu cầu phát triển đa tenant.

**Test độc lập**: Thực hiện quy trình thiết lập môi trường từ trạng thái chưa có database và xác nhận cả hai database xuất hiện với trạng thái sẵn sàng sử dụng.

**Acceptance Scenarios**:

1. **Cho trước** môi trường chưa có shared database và tenant database, **Khi** người dùng chạy quy trình thiết lập chuẩn, **Thì** môi trường có đủ hai database ở trạng thái sẵn sàng.
2. **Cho trước** môi trường đã được thiết lập, **Khi** người dùng kiểm tra danh sách database, **Thì** shared database và tenant database được nhận diện riêng biệt theo tên hoặc mô tả.

---

### Kịch bản 2 — Kiểm tra phân tách mục đích sử dụng (Ưu tiên: P2)

Maintainer rà soát môi trường và xác nhận cấu hình chỉ rõ database nào dành cho dữ liệu dùng chung và database nào dành cho dữ liệu theo tenant.

**Lý do ưu tiên**: Phân tách rõ mục đích giúp tránh thao tác nhầm và hỗ trợ các bước plan/implement tiếp theo.

**Test độc lập**: Đọc tài liệu hoặc cấu hình môi trường sau thiết lập và xác nhận có mô tả rõ vai trò của từng database.

**Acceptance Scenarios**:

1. **Cho trước** môi trường đã được thiết lập, **Khi** maintainer đọc tài liệu hoặc cấu hình công khai của môi trường, **Thì** họ xác định được database nào là shared và database nào là tenant trong dưới 2 phút.

---

### Kịch bản 3 — Thiết lập lại không làm mơ hồ trạng thái (Ưu tiên: P3)

Developer chạy lại quy trình thiết lập trên môi trường đã có database và nhận được kết quả nhất quán, không tạo thêm database trùng mục đích hoặc làm mất phân tách shared/tenant.

**Lý do ưu tiên**: Môi trường phát triển thường được bootstrap nhiều lần; hành vi tái chạy rõ ràng giúp giảm lỗi vận hành.

**Test độc lập**: Chạy quy trình thiết lập hai lần liên tiếp và so sánh danh sách database trước/sau lần chạy thứ hai.

**Acceptance Scenarios**:

1. **Cho trước** môi trường đã có shared database và tenant database hợp lệ, **Khi** người dùng chạy lại quy trình thiết lập chuẩn, **Thì** môi trường vẫn có đúng một shared database và đúng một tenant database theo phạm vi tính năng này.

---

### Trường hợp biên

- Khi một database đã tồn tại còn database còn lại chưa có, quy trình thiết lập PHẢI hoàn tất phần còn thiếu mà không làm hỏng phần đã có.
- Khi tên hoặc mục đích database bị cấu hình trùng nhau, hệ thống PHẢI báo lỗi rõ ràng để người dùng biết cần sửa cấu hình.
- Khi database không sẵn sàng sau thiết lập, người dùng PHẢI có cách kiểm tra trạng thái và nhận thông tin lỗi đủ để xử lý bước tiếp theo.

---

## 4. Yêu cầu chức năng *(bắt buộc)*

- **YC-001**: Môi trường PHẢI cung cấp một shared database dành cho dữ liệu dùng chung của hệ Flex.
- **YC-002**: Môi trường PHẢI cung cấp một tenant database dành cho dữ liệu theo tenant.
- **YC-003**: Shared database và tenant database PHẢI có định danh riêng, không được dùng chung cùng một tên hoặc cùng một vai trò mô tả.
- **YC-004**: Người dùng PHẢI có thể kiểm tra trạng thái sẵn sàng của từng database sau khi thiết lập.
- **YC-005**: Tài liệu hoặc cấu hình công khai của môi trường PHẢI mô tả mục đích sử dụng của từng database.
- **YC-006**: Quy trình thiết lập PHẢI xử lý được trường hợp chạy lại mà không tạo thêm database trùng mục đích trong cùng phạm vi môi trường.
- **YC-007**: Khi một database không thể sẵn sàng, hệ thống PHẢI cung cấp thông báo lỗi nêu rõ database bị ảnh hưởng và hành động kiểm tra tiếp theo.

---

## 5. Yêu cầu phi chức năng

- **YCPCK-001**: Người dùng có thể xác định trạng thái sẵn sàng của cả hai database trong dưới 2 phút sau khi quy trình thiết lập kết thúc.
- **YCPCK-002**: Quy trình thiết lập lại trên môi trường đã hợp lệ không được làm mất dữ liệu cấu hình nhận diện shared database và tenant database.
- **YCPCK-003**: Tên, mô tả và tài liệu liên quan đến database PHẢI nhất quán giữa cấu hình môi trường và hướng dẫn sử dụng.

---

## 6. Thực thể dữ liệu

- **Shared Database**: Đại diện cho vùng lưu trữ dữ liệu dùng chung giữa các thành phần hoặc tenant trong hệ Flex; có định danh, mục đích sử dụng và trạng thái sẵn sàng.
- **Tenant Database**: Đại diện cho vùng lưu trữ dữ liệu theo tenant; có định danh, mục đích sử dụng và trạng thái sẵn sàng.
- **Environment Configuration**: Tập thông tin mô tả database nào được môi trường cung cấp, vai trò của từng database và cách người dùng kiểm tra trạng thái.

---

## 7. Tiêu chí thành công *(bắt buộc)*

- **TC-001**: 100% lần thiết lập môi trường từ trạng thái sạch tạo ra đủ shared database và tenant database ở trạng thái sẵn sàng.
- **TC-002**: Người dùng có thể xác định đúng vai trò của từng database trong dưới 2 phút bằng tài liệu hoặc cấu hình được cung cấp.
- **TC-003**: Chạy lại quy trình thiết lập 3 lần liên tiếp không tạo database trùng mục đích và không làm mất khả năng nhận diện shared/tenant.
- **TC-004**: Khi một database không sẵn sàng, thông báo lỗi chỉ ra đúng database bị ảnh hưởng trong 100% tình huống kiểm thử lỗi có chủ đích.

---

## 8. Giả định & Ràng buộc

**Giả định**:
- `flex-environment` là sub-repo độc lập nằm trong workspace root và sẽ là nơi thực thi thay đổi implementation ở các bước sau.
- Phạm vi v1 chỉ yêu cầu một shared database và một tenant database cho mỗi môi trường.
- Người dùng có quyền chạy quy trình thiết lập môi trường và kiểm tra trạng thái service local hoặc development.

**Ràng buộc**:
- Spec này chỉ định nghĩa nhu cầu nghiệp vụ và tiêu chí chấp nhận; lựa chọn engine, cấu hình service, port, credential và file cụ thể thuộc pha plan.
- Không thay đổi dữ liệu hoặc schema nghiệp vụ của ứng dụng trong phạm vi tính năng này.
- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repo.

---

## 9. Ngoài phạm vi

- Thiết kế schema dữ liệu cho shared database hoặc tenant database.
- Migration dữ liệu từ database hiện có.
- Cấu hình production, backup, restore, replication hoặc high availability.
- Thay đổi logic ứng dụng tiêu thụ database.
- Quản lý nhiều tenant database động theo từng tenant cụ thể.

---

## 10. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Nhầm lẫn giữa database dùng chung và database theo tenant | Trung | Cao | Bắt buộc định danh, mô tả vai trò và tài liệu kiểm tra trạng thái rõ ràng |
| Quy trình thiết lập lại tạo tài nguyên trùng mục đích | Trung | Trung | Đưa yêu cầu tái chạy không tạo trùng vào acceptance criteria |
| Engine hoặc cấu hình kỹ thuật được quyết định quá sớm trong spec | Thấp | Trung | Chuyển quyết định kỹ thuật chi tiết sang pha plan theo constitution |

---

## 11. Phụ thuộc

- Cần truy cập và cập nhật `flex-environment` trong pha implementation sau khi plan và tasks được duyệt.
- Cần quyết định kỹ thuật trong pha plan về engine, cấu hình, health check và cách quản lý thông tin kết nối.
- Cần tài liệu môi trường hiện có để cập nhật hướng dẫn kiểm tra shared database và tenant database.
