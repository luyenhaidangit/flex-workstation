# Nghiên cứu giải pháp kỹ thuật (Research & Decisions)

## Tính năng: Trang tạo Agent mới (Full-page Stepper Wizard)

---

### Quyết định 1: Cấu trúc Route và Component cho Trang Tạo mới Agent

- **Decision**: Tạo component `AgentCreateWizardComponent` độc lập dưới `src/app/features/agent-catalog/components/agent-create-wizard/` và đăng ký route `/agents/create` trong `agent-catalog-routing.module.ts`.
- **Rationale**:
  - Tách bạch rõ ràng giữa màn hình danh sách agent (`/agents`) và màn hình wizard tạo mới (`/agents/create`).
  - Đảm bảo tính mở rộng khi cần thêm các sub-route hoặc các bước wizard phức tạp sau này mà không làm ảnh hưởng đến `AgentListComponent`.
- **Alternatives considered**:
  - *Option B*: Tái sử dụng `agent-form-modal.component.ts` bọc trong một container page. (Bị loại bỏ vì modal component có layout nhỏ gọn và logic đóng/mở modal khác với wizard trang full-page 7 bước).

---

### Quyết định 2: Quản lý Trạng thái các bước Wizard (Stepper State)

- **Decision**: Sử dụng `ReactiveForms` (`FormBuilder`, `FormGroup`) kết hợp với một thuộc tính điều hướng bước `currentStep: number` (từ 1 đến 7). Dữ liệu của tất cả 7 bước được duy trì đồng bộ trong một `FormGroup` tổng thể của wizard.
- **Rationale**:
  - Dữ liệu không bị mất khi người dùng nhấp qua lại giữa các bước trên thanh Stepper bên trái.
  - Dễ dàng thực hiện validation từng bước (`validateStep(stepNumber)`) trước khi cho phép bấm nút "Tiếp tục" hoặc nhấp bước tiếp theo.
- **Alternatives considered**:
  - *Option B*: Sử dụng Angular Router sub-routes cho từng bước (`/agents/create/step-1`, `/agents/create/step-2`, ...). (Bị loại vì tính chất wizard tạo mới tốt hơn khi giữ trong 1 component chính với state tập trung, giảm giật lag khi chuyển đổi giao diện).

---

### Quyết định 3: Thiết kế Giao diện UI/UX (Khớp thiết kế mẫu)

- **Decision**: Layout bao gồm 3 phần chính:
  1. **Header trên cùng**: Tiêu đề "Tạo nhân viên AI", biểu tượng hỗ trợ (Help), nút đóng (X).
  2. **Sidebar bên trái**:
     - Card hiển thị tóm tắt Avatar, Tên và Vai trò của Agent (cập nhật live theo form input).
     - Danh sách Stepper 7 bước dạng chuỗi với số thứ tự có vòng tròn xanh/xám, tiêu đề bước và trạng thái active/completed.
  3. **Main Content chính giữa**:
     - Tiêu đề & mô tả bước hiện tại (ví dụ: "Thiết lập thông tin chung").
     - Khối "Thông tin cơ bản": Chọn avatar mẫu/tải lên, Tên*, Vai trò*, Cấp thực hiện (Cấp tỉnh/Cấp xã), Cơ quan thực hiện*.
     - Khối "Chỉ dẫn cho Agent": Nhập prompt/chỉ dẫn cho Agent*.
  4. **Footer cố định góc dưới bên phải**: Nút "Hủy" (nút mềm viền) và nút "Tiếp tục" (nút màu xanh nổi bật).
- **Rationale**:
  - Khớp 100% với ảnh mockup người dùng cung cấp.
  - Sử dụng TailwindCSS / Bootstrap / Skote CSS utilities sẵn có trong `flex-microfrontend`.

---

### Quyết định 4: Xử lý Cảnh báo khi Thoát / Hủy (Unsaved Changes Guard)

- **Decision**: Sử dụng Angular `CanDeactivate` Route Guard kết hợp với Bootstrap/SweetAlert confirm modal khi form ở trạng thái `dirty` và người dùng cố gắng chuyển route hoặc bấm nút "Hủy".
- **Rationale**: Ngăn ngừa trường hợp người dùng lỡ tay thoát làm mất toàn bộ thông tin đã điền.
