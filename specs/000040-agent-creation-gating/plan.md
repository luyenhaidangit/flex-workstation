# Kế hoạch triển khai: Phân tách trạng thái tạo và cấu hình Agent

**Branch**: `000040-agent-creation-gating` | **Ngày**: 2026-08-26 | **Đặc tả**: [spec.md](spec.md)

**Đầu vào**: `specs/000040-agent-creation-gating/spec.md`

## Tóm tắt

**Yêu cầu chính từ spec**: Tách state chưa có `AgentId` khỏi Agent đã tạo; không tự tạo khi click bước khóa; đổi action thành “Tạo Agent và tiếp tục” hoặc “Lưu và tiếp tục”; khóa chat/top navigation trước khi Agent tồn tại.

**Hướng tiếp cận kỹ thuật dự kiến**: Điều chỉnh wizard Angular hiện có, thêm route `/agents/:id/settings`, dùng lại `AgentService.createAgent()`/`updateAgent()` và không thêm backend draft/versioning.

**Kết quả sau research**: Route editor nằm ở root `app-routing.module.ts`; wizard và API hiện có đủ nền tảng; test stack là Karma/Jasmine; không còn câu hỏi kỹ thuật chặn tasks.

## Phạm vi kỹ thuật

**Trong phạm vi**:
- `flex-microfrontend/src/app/app-routing.module.ts`: thêm route settings và giữ route cũ.
- `features/agent-catalog/components/agent-editor-wizard/`: state, stepper, header, chat placeholder, footer và action handlers.
- `steps/agent-step-general/`: copy riêng cho màn tạo mới.
- Unit/manual regression test cho state/action chính.

**Ngoài phạm vi kỹ thuật**:
- Backend draft/versioning, database/schema/migration và API contract mới.
- Nội dung mới cho Tri thức, Kỹ năng, Đào tạo, Phát hành, Hội thoại hoặc Báo cáo.
- Thay đổi chat contract; chỉ gating UI và guard client.

## Bối cảnh kỹ thuật

**Ngôn ngữ/Phiên bản**: Angular 16.1.4, TypeScript, RxJS, Bootstrap 5/Skote.

**Service/App liên quan**: `flex-microfrontend`, `AgentEditorWizardComponent`, `AgentStepGeneralComponent`, `AgentService`, `AgentChatService`, `AppRoutingModule`.

**Convention skill áp dụng**: `flex-frontend-engineering`.

**Phụ thuộc chính**: Angular Router, Reactive Forms, `angular-toastify`, API POST/PUT hiện có.

**Lưu trữ**: Không thay đổi; dùng Agent/API hiện có.

**Kiểm thử**: Karma/Jasmine (`npm run test`), Angular build/lint và manual smoke.

**Nền tảng chạy**: Browser desktop.

**Đơn vị deploy**: Frontend app `flex-microfrontend`.

**Loại project**: Angular admin web application.

**Mục tiêu hiệu năng**: Local step/state change phản hồi tức thời; API action có loading state.

**Ràng buộc**: Bootstrap utility/icon convention hiện có; không tạo abstraction dùng một lần.

**Quy mô/Phạm vi**: Một wizard, một route alias, một component spec mới và các test/helper liên quan.

## Kiểm tra constitution

| Gate | Trạng thái ban đầu | Trạng thái sau design | Ghi chú |
|------|--------------------|------------------------|---------|
| Spec trước code | Pass | Pass | Spec, docbiz, plan trước implementation |
| Boundary repo | Pass | Pass | Source ở `flex-microfrontend`, user đã nêu rõ |
| Thay đổi phẫu thuật | Pass | Pass | Tái sử dụng wizard/API, không thêm backend draft |
| Specialist Skill Gate | Pass | Pass | Đã route `flex-frontend-engineering` |
| Database/migration | Không áp dụng | Không áp dụng | Không thay đổi dữ liệu/schema |
| API compatibility | Pass | Pass | Giữ POST/PUT contract hiện có |

## Câu hỏi kỹ thuật cần research

- Không còn câu hỏi chặn. Các quyết định đã ghi trong [research.md](research.md).

## Thiết kế tổng quan

**Luồng chính**:
1. `/agents/create` mở wizard không có `agentId`; chỉ step 1 hoạt động, chat/report bị ẩn và cột phải hiện hướng dẫn.
2. “Tạo Agent và tiếp tục” validate rồi gọi create với status `inactive`.
3. Nhận `Agent.id`, hiển thị “Bản nháp”, điều hướng `/agents/{id}/settings`; route dùng wizard mode `edit`.
4. Agent đã có id mở khóa stepper; draft dùng “Lưu và tiếp tục”; published giữ “Lưu và phát hành lại”.
5. “Lưu nháp” giữ UI/toast hiện có, không thêm persistence.

**Component/module tham gia**:
- `AppRoutingModule`: route settings.
- `AgentEditorWizardComponent`: state, actions, lock notice, header, chat gating.
- wizard HTML/SCSS: render UI state/accessibility.
- `AgentStepGeneralComponent`: title/description create state.
- `AgentService`: không đổi contract.

**Điểm mở rộng/thay đổi chính**:
- `onStepClick()` không gọi create khi step bị khóa.
- Tách `onCreateAndContinue()`, `onSaveAndContinue()` và publish handler.
- Thêm `hasAgent`, `isDraft`, `isPublished`, `isStepLocked()`; cập nhật completed/active.
- Dùng `agent.updatedAt`; ẩn update time ở create.
- Chat preview chỉ render input khi có id; `onSendMessage()` có guard id.

**Luồng thay thế/lỗi chính**: Form invalid không gọi API; create/update lỗi giữ màn hình và dùng interceptor toast; action đang request bị khóa; load lỗi quay về `/agents`; lock interaction chỉ hiện notice.

**Thay đổi boundary giữa service/module**: Không áp dụng.

**Idempotency/Concurrency**: Dùng `isSavingAgent`/`isSubmitting` ngăn submit lặp; không thêm backend concurrency.

## Traceability từ spec sang thiết kế kỹ thuật

| Spec ID | Ưu tiên | Hướng xử lý | Module/Path | API/Contract | Data/Entity | Kiểm thử |
|---------|---------|-------------|-------------|--------------|-------------|----------|
| US-001/FR-001 | P1 | State theo `agentId` + `status`, route settings | `app-routing.module.ts`, wizard TS | POST hiện có | Agent id/status | Unit/manual |
| US-001/FR-002 | P1 | Label create động theo state | wizard HTML | Không áp dụng | Không áp dụng | Template/manual |
| US-001/FR-003 | P1 | Create riêng sau validation | wizard TS | POST hiện có | Agent | Unit spy |
| US-002/FR-004 | P1 | Button lock icon, `aria-disabled`, notice | wizard HTML/SCSS/TS | Không áp dụng | UI state | Unit/manual |
| US-002/FR-005 | P1 | Locked step return, không gọi service | wizard TS | Không áp dụng | Không áp dụng | Unit spy |
| US-003/FR-006 | P1 | PUT inactive rồi chuyển bước | wizard TS | PUT hiện có | Agent status | Unit/manual |
| US-004/FR-007 | P2 | Hide tabs, placeholder chat, guard send | wizard HTML/TS | Không đổi | Không áp dụng | Template/manual |
| FR-008/MVP-004 | P2 | Giữ `Lưu nháp` UI-only | wizard HTML/TS | Không áp dụng | Không áp dụng | Regression |

## Phân tích tác động

| Khu vực | Tác động dự kiến | Tương thích ngược/Rủi ro | Cách kiểm tra |
|---------|------------------|--------------------------|---------------|
| Database/Migration | Không đổi | Không áp dụng | Kiểm tra diff |
| API/Contract | Dùng POST/PUT hiện có | Không đổi payload | Spy/HTTP mock |
| Permission/Security | Giữ AuthGuard/quyền hiện có | Route settings phải được guard | Route/manual check |
| Logging/Audit | Không thêm log | Giữ interceptor/audit hiện có | Kiểm tra toast không trùng |
| UI/UX | Đổi header, stepper, chat, footer, route sau create | Regression edit/view/publish | Unit/manual |
| Job/Worker/Integration | Không áp dụng | Không có integration mới | Không áp dụng |

## API/Contract Detail

**Có thay đổi contract không**: Không.

| Contract | Loại | Thay đổi | Backward compatible | Consumer bị ảnh hưởng |
|----------|------|----------|---------------------|------------------------|
| `POST /api/v1/agents` | API | Reuse với `status: inactive` | Có | `AgentService` |
| `PUT /api/v1/agents/{id}` | API | Reuse cho save/publish | Có | `AgentService` |

## Permission Matrix

| Vai trò/Scope | Xem | Tạo | Sửa | Xóa | Duyệt/Xử lý | Ghi chú |
|---------------|-----|-----|-----|-----|-------------|---------|
| User có quyền Agent | Có | Có | Có | Theo quyền hiện có | Theo quyền hiện có | Không thay đổi quyền |
| User chỉ xem/không quyền | Theo quyền hiện có | Không | Không | Không | Không | AuthGuard hiện có |

## Dữ liệu & Migration

**Có thay đổi dữ liệu/schema không**: Không áp dụng.

**Database đích**: Không áp dụng; chỉ thay đổi client UI/route.

**Repo chứa migration**: Không áp dụng.

**Migration**: Không áp dụng.

**Backfill/Cleanup**: Không áp dụng.

**Tương thích dữ liệu cũ**: Agent hiện có tiếp tục load theo id và status.

**Rủi ro dữ liệu**: Không phát sinh schema/data risk mới.

**Cách xác minh**: Unit spy/HTTP mock và manual create/edit với response id/status.

## Quyết định kỹ thuật

| Quyết định | Lựa chọn | Lý do chọn | Phương án đã loại | Lý do loại |
|------------|----------|------------|-------------------|------------|
| DEC-001 | Thêm `/agents/:id/settings` alias | Đúng URL nghiệp vụ, giữ route cũ | Thay route cũ | Scope/risk lớn |
| DEC-002 | Dùng `agentId` + `Agent.status` | Không thêm backend draft/state store | State store hoặc status mới | Vượt scope |
| DEC-003 | Button `aria-disabled` | Hỗ trợ focus/click notice và accessibility | Native disabled/div | Thiếu interaction semantics |
| DEC-004 | Tách create/save/publish | Side effect khớp label/state | Một `onPublish()` | Dễ create/publish sai |
| DEC-005 | Giữ `Lưu nháp` UI-only | Theo quyết định stakeholder | Xóa hoặc làm backend draft | Đổi scope |

## Chiến lược kiểm thử

**Unit test**:
- Invalid create không gọi service; valid create gọi `createAgent`; locked step không gọi create; save-and-continue gọi update draft; chat send bị chặn khi thiếu id.

**Integration test**: Không áp dụng integration mới; mock API hiện có.

**Contract test**: Không áp dụng; không đổi contract.

**Permission/security test**: Regression manual AuthGuard trên create/settings/edit/view.

**E2E/manual test**: Create lock/notice/chat, create navigation/draft, settings save-and-continue, published publish flow.

**Regression test**: Agent list navigation, channel toggle, dirty cancel, build/lint.

## Tác động tài liệu nghiệp vụ

- **Kết quả Documentation Impact Gate**: CÓ CẬP NHẬT.
- **Tham chiếu đánh giá**: `spec.md` §20.
- **Tài liệu hiện hữu đã cập nhật**: `docs/business/12-agent-creation-and-configuration.md`, `docs/business/11-ai-chat-integration.md`, `docs/business/business-docs-index.md`.
- **Cập nhật còn lại sau implementation**: Không áp dụng.

## Cấu trúc project

### Tài liệu cho feature này

```text
specs/000040-agent-creation-gating/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── checklists/requirements.md
```

Không tạo `contracts/` vì không đổi API/event/public contract.

### Source code (repository root)

```text
flex-microfrontend/src/app/
├── app-routing.module.ts
└── features/agent-catalog/components/agent-editor-wizard/
    ├── agent-editor-wizard.component.ts
    ├── agent-editor-wizard.component.html
    ├── agent-editor-wizard.component.scss
    ├── agent-editor-wizard.component.spec.ts
    └── steps/agent-step-general/
        ├── agent-step-general.component.ts
        └── agent-step-general.component.html
```

`agent-catalog-routing.module.ts` không đổi vì editor route đang ở root app routing.

**Quyết định cấu trúc**: Giữ wizard hiện có, chỉ sửa state/template/helper/route và thêm feature-local test; không tạo shared abstraction.

## Rollout & Rollback

**Kế hoạch rollout**: Deploy frontend sau build/lint/unit/manual smoke; không migration/feature flag.

**Tương thích ngược**: Giữ `/agents/create`, `/agents/:id/edit`, `/agents/:id`; thêm `/agents/:id/settings`.

**Feature flag/config**: Không áp dụng.

**Thực thi migration/backfill khi rollout**: Không áp dụng.

**Rollback code/config**: Revert frontend build; route cũ vẫn tồn tại.

**Rollback dữ liệu/migration**: Không áp dụng.

**Điều kiện kích hoạt rollback**: Route create/edit lỗi, create sai, hoặc publish flow regression.

## Observability & Debug

**Log cần có**: Không thêm client log; dùng interceptor/network trace hiện có.

**Dữ liệu không được log**: Prompt, nội dung chat, token, secret và dữ liệu form nhạy cảm.

**Metric cần theo dõi**: Không thêm metric trong MVP.

**Trace/Correlation**: Giữ correlation/request handling hiện có.

**Cách kiểm tra sau release**: Kiểm tra click lock không có POST; create có POST và settings navigation; save có PUT.

**Tình huống debug chính**: State id/status, route settings, submit lặp, chat thiếu id, duplicate toast.

## Theo dõi độ phức tạp

Không có vi phạm constitution cần biện minh.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi kỹ thuật trong/ngoài phase này đã rõ.
- [x] Câu hỏi kỹ thuật chặn đã được resolve trong research.
- [x] Thiết kế tổng quan đã mô tả flow, module, boundary và lỗi chính.
- [x] Idempotency/concurrency/retry đã được đánh giá.
- [x] US/FR P1/P2 đã mapping sang path, API, data và test.
- [x] Database, API, permission, logging và integration impact đã được đánh giá.
- [x] Contract compatibility và consumer đã rõ.
- [x] Dữ liệu/migration/backfill đã ghi rõ không áp dụng.
- [x] Database đích/repo migration đã ghi rõ không áp dụng.
- [x] Quyết định kỹ thuật có lý do và phương án loại.
- [x] Chiến lược test đã bao phủ các lớp liên quan.
- [x] Rollout/rollback/flag/backward compatibility đã rõ.
- [x] Observability/debug và smoke check đã rõ.
- [x] Source tree dùng path thật, không còn placeholder.
- [x] Constitution gate không còn blocker.
