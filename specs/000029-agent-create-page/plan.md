# Kế hoạch triển khai: Trang tạo Agent mới (Full-page Stepper Wizard)

**Branch**: `000029-agent-create-page` | **Ngày**: 2026-08-06 | **Đặc tả**: [`specs/000029-agent-create-page/spec.md`](file:///c:/Workspace/Project/flex-workstation/specs/000029-agent-create-page/spec.md)

**Đầu vào**: Đặc tả tính năng từ `/specs/000029-agent-create-page/spec.md`

---

## Tóm tắt

**Yêu cầu chính từ spec**:
- Nút "+ Thêm mới" tại trang Danh mục Agent (`/agents`) chuyển hướng người dùng sang trang mới (`/agents/create`) thay vì hiển thị popup modal.
- Trang mới hiển thị dưới dạng Full-page Stepper Wizard với 7 bước cấu hình Agent (1. Thiết lập thông tin chung, 2. Thêm thủ tục hành chính, 3. Thêm thông tin Cơ quan, 4. Thêm văn bản khác, 5. Thiết lập kỹ năng, 6. Kiểm tra nhân viên AI, 7. Phát hành).
- Form Bước 1 "Thiết lập thông tin chung" cho phép nhập Hình đại diện (chọn từ preset/tải lên), Tên*, Vai trò*, Cấp thực hiện (Cấp tỉnh/Cấp xã), Cơ quan thực hiện*, và Chỉ dẫn cho Agent*.
- Header thẻ thông tin Agent ở sidebar bên trái cập nhật tên và vai trò theo thời gian thực (real-time).
- Cung cấp nút Hủy (có cảnh báo unsaved changes khi form dirty) và nút Tiếp tục để chuyển bước.

**Hướng tiếp cận kỹ thuật dự kiến**:
- Tạo `AgentCreateWizardComponent` trong Angular app `flex-microfrontend`.
- Cấu hình route `/agents/create` trong `AgentCatalogRoutingModule`.
- Sử dụng Angular `ReactiveForms` và `FormBuilder` quản lý state tập trung cho các bước.
- Inject `CanDeactivateGuard` để xử lý cảnh báo khi thoát trang chưa lưu.

**Kết quả sau research**: Đã hoàn thành `research.md`. Không còn thắc mắc kỹ thuật.

---

## Phạm vi kỹ thuật

**Trong phạm vi**:
- Thêm route `create` vào `agent-catalog-routing.module.ts`.
- Tạo mới `AgentCreateWizardComponent` (HTML, SCSS, TS) trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-create-wizard/`.
- Chỉnh sửa `AgentListComponent` (`agent-list.component.ts` & `agent-list.component.html`) để nút "+ Thêm mới" thực hiện `this.router.navigate(['/agents/create'])`.
- Implement layout 7 bước wizard, Stepper vertical navigation, real-time live preview tóm tắt thông tin agent ở sidebar, validation từng bước, và dialog cảnh báo thoát.

**Ngoài phạm vi kỹ thuật**:
- Không sửa đổi schema backend DB hoặc API endpoint (tái sử dụng `AgentService.createAgent`).

---

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: TypeScript 4.x / Angular 12+ (Frontend app `flex-microfrontend`)  
**Service/App liên quan**: `flex-microfrontend`  
**Convention skill áp dụng**: `flex-frontend-engineering`  
**Phụ thuộc chính**: Angular Router, ReactiveFormsModule, Bootstrap 5 / Skote Theme CSS, NgbModal / SweetAlert2 (cho confirm dialog)  
**Lưu trữ**: Local Component State (Reactive Form)  
**Kiểm thử**: Angular Component Unit Test (`ng test`), Manual Verification  
**Nền tảng chạy**: Browser  
**Đơn vị deploy**: `flex-microfrontend` SPA  
**Loại project**: Frontend Web Application  
**Mục tiêu hiệu năng**: Phản hồi chuyển bước < 100ms  
**Ràng buộc**: Giữ nguyên Theme & CSS utility của Skote Admin Template  

---

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Tách biệt nghiệp vụ & Kỹ thuật | Pass | Pass | Spec chỉ mô tả WHAT, Plan giải quyết HOW |
| Đơn giản là ưu tiên | Pass | Pass | Dùng Reactive Forms trong 1 component chính với step state |
| Thay đổi phẫu thuật | Pass | Pass | Chỉ thêm component wizard mới và chỉnh nhẹ `AgentListComponent` |

---

## Câu hỏi kỹ thuật cần research

- Tất cả đã được xử lý trong `research.md`.

---

## Thiết kế tổng quan

**Luồng chính**:
1. Người dùng ở `/agents`, nhấp nút "+ Thêm mới".
2. Angular Router chuyển hướng sang `/agents/create`, khởi tạo `AgentCreateWizardComponent`.
3. `AgentCreateWizardComponent` hiển thị Stepper 7 bước với bước 1 active.
4. Người dùng điền thông tin bước 1, card xem trước ở sidebar cập nhật ngay lập tức.
5. Người dùng nhấp "Tiếp tục" -> Validate form bước 1 -> Chuyển sang bước 2.
6. Khi hoàn thành toàn bộ các bước, người dùng nhấp "Phát hành" -> Gọi `AgentService.createAgent()` -> Chuyển hướng quay về `/agents`.

**Component/module tham gia**:
- `AgentCatalogModule`: Module quản lý feature Agent Catalog.
- `AgentCatalogRoutingModule`: Khai báo route `/agents/create`.
- `AgentListComponent`: Màn hình danh sách Agent, chứa nút "+ Thêm mới" điều hướng.
- `AgentCreateWizardComponent`: Component mới quản lý trang Wizard tạo Agent.
- `AgentService`: Service gọi API lưu Agent.

---

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Trạng thái | Hướng xử lý kỹ thuật | Module/Path dự kiến | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|------------|----------------------|---------------------|--------------|-------------|----------|
| US-001 / FR-001 | P1 | Đủ rõ | Nút "+ Thêm mới" gọi `router.navigate(['/agents/create'])` | `src/app/features/agent-catalog/components/agent-list/` | N/A | N/A | Manual / E2E |
| US-001 / FR-002 | P1 | Đủ rõ | Tạo `AgentCreateWizardComponent` với layout 7 bước | `src/app/features/agent-catalog/components/agent-create-wizard/` | UI Contract | `WizardStep[]` | Manual / Unit test |
| US-002 / FR-003 | P1 | Đủ rõ | FormBước 1 gồm Avatar, Name, Role, ExecutionLevel, Org, Instructions | `src/app/features/agent-catalog/components/agent-create-wizard/` | N/A | `CreateAgentFormState` | Unit test |
| US-002 / FR-004 | P1 | Đủ rõ | Validation Reactive Form trước khi sang bước tiếp theo | `src/app/features/agent-catalog/components/agent-create-wizard/` | N/A | N/A | Unit test |
| US-003 / FR-005 | P2 | Đủ rõ | Nút Hủy / X gọi `router.navigate(['/agents'])` | `src/app/features/agent-catalog/components/agent-create-wizard/` | N/A | N/A | Manual test |
| US-001 / FR-006 | P2 | Đủ rõ | Xử lý click sự kiện trên danh sách Stepper sidebar | `src/app/features/agent-catalog/components/agent-create-wizard/` | N/A | N/A | Manual test |
| US-003 / FR-007 | P2 | Đủ rõ | Popup cảnh báo xác nhận khi Form dirty và thoát trang | `src/app/features/agent-catalog/components/agent-create-wizard/` | N/A | N/A | Manual test |

---

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không áp dụng | Không áp dụng | N/A |
| API/Contract | Không áp dụng | Tái sử dụng `AgentService` hiện có | Smoke test API |
| Permission/Security | Kiểm tra quyền truy cập route `/agents/create` | Không ảnh hưởng | Manual test |
| Logging/Audit | Không áp dụng | N/A | N/A |
| UI/UX | Nút "+ Thêm mới" mở trang mới thay vì popup | Không còn dùng modal cho tạo mới | Manual test |
| Job/Worker/Integration | Không áp dụng | N/A | N/A |

---

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| [DEC-001] Component cho Wizard | Tạo `AgentCreateWizardComponent` riêng | Độc lập, dễ bảo trì, đúng thiết kế full-page | Bọc modal hiện tại | Modal bị giới hạn khung hình và không thể mở rộng 7 bước mượt mà |
| [DEC-002] Quản lý State | Single ReactiveFormGroup | Dữ liệu đồng bộ, dễ validate và không mất data giữa các bước | Angular Sub-routes cho mỗi step | Gây phức tạp luồng và giật trang khi chuyển bước |

---

## Chiến lược kiểm thử

**Unit test**:
- Test component `AgentCreateWizardComponent` khởi tạo đúng 7 bước.
- Test form validation bước 1 khi dữ liệu hợp lệ và không hợp lệ.

**E2E/manual test**:
- Bấm "+ Thêm mới" từ `/agents` -> chuyển hướng `/agents/create`.
- Nhập thông tin bước 1, kiểm tra live preview card tóm tắt trên sidebar.
- Chuyển bước và thử bấm "Hủy" để xem dialog xác nhận cảnh báo.

---

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000029-agent-create-page/
├── spec.md              # File đặc tả (input)
├── plan.md              # File này (output /speckit-plan)
├── research.md          # Output Phase 0
├── data-model.md        # Output Phase 1
├── quickstart.md        # Output Phase 1
└── contracts/           # Output Phase 1
    └── agent-wizard-contract.md
```

### Source code (repository root)

```text
flex-microfrontend/src/app/features/agent-catalog/
├── agent-catalog-routing.module.ts                         # Cấu hình route /agents/create
├── agent-catalog.module.ts                                 # Đăng ký AgentCreateWizardComponent
├── components/
│   ├── agent-list/                                         # Chỉnh sửa nút + Thêm mới để navigate
│   │   ├── agent-list.component.ts
│   │   └── agent-list.component.html
│   └── agent-create-wizard/                                # [NEW] Component trang wizard tạo agent 7 bước
│       ├── agent-create-wizard.component.ts
│       ├── agent-create-wizard.component.html
│       └── agent-create-wizard.component.scss
```

**Quyết định cấu trúc**: Thêm `AgentCreateWizardComponent` vào thư mục `src/app/features/agent-catalog/components/agent-create-wizard/` của dự án `flex-microfrontend`.

---

## Rollout & Rollback

**Kế hoạch rollout**: Build và deploy frontend bundle `flex-microfrontend`.  
**Tương thích ngược**: 100% tương thích ngược với dữ liệu và backend API hiện tại.  
**Rollback code/config**: Revert commit git nếu phát sinh sự cố giao diện.  

---

## Observability & Debug

**Log cần có**: Log console hoặc analytics event khi người dùng vào trang tạo Agent và hoàn tất từng bước.  
**Cách kiểm tra sau release**: Kiểm tra màn hình `/agents` -> bấm "+ Thêm mới" -> kiểm tra giao diện trang wizard tạo agent.  

---

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn thiết kế/task generation đã được resolve trong research.
- [x] Thiết kế tổng quan đã mô tả luồng chính và component tham gia.
- [x] Tác động tới database, API contract, UI/UX đã được đánh giá.
- [x] Quyết định kỹ thuật chính đã có lý do chọn.
- [x] Cấu trúc project chỉ chứa đường dẫn file thật trong repository.
- [x] Sẵn sàng chuyển sang bước sinh task `/speckit-tasks`.
