# Tasks: Trang tạo Agent mới (Full-page Stepper Wizard)

**Đầu vào**: Design documents từ `/specs/000029-agent-create-page/`

**Điều kiện tiên quyết**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/agent-wizard-contract.md`, `quickstart.md`

**Tests**: Kiểm thử giao diện Angular Component Unit Test và Manual Verification Scenario theo `quickstart.md`.

---

## Format: `[ID] [P?] [Story?] Description with path`

- **[ID]**: ID duy nhất, tăng tuần tự `T001`, `T002`, `T003`...
- **[P]**: Parallelizable (có thể thực hiện song song do sửa khác file và không có phụ thuộc).
- **[Story]**: [US1], [US2], [US3] tương ứng với User Story trong `spec.md`.

---

## Phase 1: Setup (Shared Infrastructure)

**Mục đích**: Khởi tạo cấu trúc file cho component mới trong dự án `flex-microfrontend`.

- [X] T001 Tạo thư mục component `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Mục đích**: Khởi tạo Component, Module và Routing làm nền tảng cho các User Stories.

- [X] T002 Tạo component file `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts` với khai báo class cơ bản.
- [X] T003 [P] Tạo template file `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.html` với khung layout cơ bản.
- [X] T004 [P] Tạo style file `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.scss` cho wizard component.
- [X] T005 Khai báo và import `AgentCreateWizardComponent` trong `flex-microfrontend/src/app/features/agent-catalog/agent-catalog.module.ts`.
- [X] T006 Cấu hình route `{ path: 'create', component: AgentCreateWizardComponent }` trong `flex-microfrontend/src/app/features/agent-catalog/agent-catalog-routing.module.ts`.

---

## Phase 3: User Story 1 - Mở trang Tạo Agent & Hiển thị Layout Stepper Wizard (Priority: P1) MVP

**Goal**: Cho phép người dùng nhấp nút "+ Thêm mới" tại trang Danh mục Agent (`/agents`) để chuyển sang trang độc lập `/agents/create` hiển thị layout Stepper 7 bước bên trái và header tiêu đề.

**Independent Test**: Bấm vào nút "+ Thêm mới" tại `/agents`, trình duyệt chuyển hướng đến `/agents/create`. Trang hiển thị đầy đủ Header ("Tạo nhân viên AI"), Sidebar Stepper 7 bước bên trái với bước 1 được active và khu vực nội dung chính.

### Implementation for User Story 1

- [X] T007 [US1] Chỉnh sửa phương thức `openCreateModal()` trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-list/agent-list.component.ts` để thực hiện `this.router.navigate(['/agents/create'])`.
- [X] T008 [US1] Cấu hình layout Stepper 7 bước dạng chuỗi vertical navigation và header tóm tắt thông tin Agent ở sidebar bên trái trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.html`.
- [X] T009 [US1] Thêm logic quản lý bước hiện tại (`currentStep: number`) và sự kiện nhấp trực tiếp vào thanh Stepper sidebar (`onStepClick(stepId)`) trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts`.
- [X] T010 [US1] Bổ sung SCSS styling cho thanh Stepper, các icon số thứ tự tròn (active/completed) và layout 2 cột (sidebar + main content) trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.scss`.

**Definition of Done**: Nút "+ Thêm mới" chuyển hướng thành công đến trang `/agents/create`. Giao diện Stepper 7 bước hiển thị chuẩn responsive.

---

## Phase 4: User Story 2 - Form Cấu hình Bước 1 & Live Preview Sidebar (Priority: P1) MVP

**Goal**: Xây dựng form "Thiết lập thông tin chung" cho Bước 1 (chọn Avatar mẫu, nhập Tên*, Vai trò*, Cấp thực hiện, Cơ quan thực hiện*, Chỉ dẫn cho Agent*), cập nhật real-time thẻ preview thông tin trên sidebar và validate dữ liệu khi bấm nút "Tiếp tục".

**Independent Test**: Điền các thông tin Tên, Vai trò ở Bước 1, thẻ tóm tắt Agent góc trên bên trái cập nhật thông tin ngay lập tức. Để trống trường bắt buộc và bấm "Tiếp tục" sẽ xuất hiện thông báo lỗi validation; điền hợp lệ bấm "Tiếp tục" sẽ chuyển mốc active sang Bước 2.

### Implementation for User Story 2

- [X] T011 [US2] Khởi tạo `FormGroup` với các FormControl (`avatarUrl`, `name`, `role`, `executionLevel`, `organization`, `instructions`) và quy định validators bắt buộc trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts`.
- [X] T012 [US2] Xây dựng form nhập liệu "Thiết lập thông tin chung" ở khu vực main content, danh sách lựa chọn Avatar mẫu, radio chọn Cấp thực hiện (Cấp tỉnh/Cấp xã), dropdown chọn Cơ quan thực hiện và textarea Chỉ dẫn cho Agent trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.html`.
- [X] T013 [US2] Thêm binding dữ liệu real-time từ Form sang thẻ Card xem trước tóm tắt Agent ở góc trên sidebar bên trái trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.html`.
- [X] T014 [US2] Implement phương thức `onNextStep()` validate dữ liệu Bước 1 và chuyển active sang Bước 2 khi hợp lệ trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts`.
- [X] T015 [US2] Styling cho các ô input, avatar picker chips, radio buttons và tin nhắn lỗi validation trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.scss`.

**Definition of Done**: Form Bước 1 hoạt động mượt mà, validate chính xác các trường bắt buộc, card thông tin ở sidebar cập nhật real-time.

---

## Phase 5: User Story 3 - Xử lý Hủy & Cảnh báo Dữ liệu Chưa lưu (Priority: P2)

**Goal**: Cung cấp nút "Hủy" và nút đóng (X). Nếu form đang có dữ liệu chưa lưu (dirty), hiển thị hộp thoại xác nhận trước khi rời trang về `/agents`.

**Independent Test**: Nhập dữ liệu dở dang vào form, nhấp nút "Hủy" hoặc nút (X). Popup cảnh báo xuất hiện. Chọn đồng ý thoát -> điều hướng về trang `/agents`.

### Implementation for User Story 3

- [X] T016 [US3] Implement phương thức `onCancel()` trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.ts` kiểm tra trạng thái `form.dirty`. Nếu `dirty`, hiển thị confirm dialog cảnh báo "Bạn có chắc chắn muốn rời khỏi trang? Dữ liệu vừa nhập chưa được lưu.".
- [X] T017 [US3] Thêm sự kiện click `(click)="onCancel()"` cho nút "Hủy" ở thanh footer cố định góc dưới bên phải và biểu tượng (X) ở góc trên bên phải trang trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/agent-create-wizard.component.html`.

**Definition of Done**: Nút Hủy và nút đóng (X) hoạt động chính xác, bảo vệ dữ liệu người dùng khỏi bị lỡ tay thoát.

---

## Final Phase: Polish & Validation

**Mục đích**: Kiểm tra tổng thể UI/UX, responsive và chạy các kịch bản thử nghiệm theo `quickstart.md`.

- [X] T018 Thực thi kịch bản kiểm thử theo hướng dẫn trong `specs/000029-agent-create-page/quickstart.md` trên ứng dụng `http://localhost:4200`.
- [X] T019 [P] Rà soát và tinh chỉnh giao diện CSS đảm bảo hiển thị đồng bộ với theme Skote Admin trên các độ phân giải màn hình desktop.

---

## Validation Commands

- **Khởi động ứng dụng**: `cd flex-microfrontend && npm run start`
- **Địa chỉ truy cập kiểm thử**: `http://localhost:4200/agents` -> Bấm **+ Thêm mới** -> `http://localhost:4200/agents/create`

---

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US-001 | T007, T008, T009, T010 |
| US-002 | T011, T012, T013, T014, T015 |
| US-003 | T016, T017 |
| FR-001 | T006, T007 |
| FR-002 | T008, T010 |
| FR-003 | T011, T012 |
| FR-004 | T011, T014 |
| FR-005 | T017 |
| FR-006 | T009 |
| FR-007 | T016 |
| AC-001 | T007 |
| AC-002 | T008 |
| AC-003 | T012, T013 |
| AC-004 | T014 |
| AC-005 | T014 |
| AC-006 | T016, T017 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không có phụ thuộc, chạy đầu tiên.
- **Foundational (Phase 2)**: Phụ thuộc Phase 1.
- **User Story 1 (Phase 3)**: Phụ thuộc Phase 2 completion.
- **User Story 2 (Phase 4)**: Phụ thuộc Phase 3 completion.
- **User Story 3 (Phase 5)**: Phụ thuộc Phase 3 completion.
- **Polish (Final Phase)**: Phụ thuộc hoàn tất tất cả User Stories.

### Parallel Opportunities

- Tasks `T003`, `T004` trong Phase 2 có thể thực hiện song song (sửa file HTML, SCSS độc lập).
- Task `T019` trong Final Phase có thể thực hiện song song.
