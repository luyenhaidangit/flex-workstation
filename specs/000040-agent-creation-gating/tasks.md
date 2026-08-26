# Task list: Phân tách trạng thái tạo và cấu hình Agent

**Feature**: `000040-agent-creation-gating`  
**Nguồn**: `spec.md`, `plan.md`, `data-model.md`, `quickstart.md`  
**Phạm vi**: Angular UI, routing và unit/manual validation trong `flex-microfrontend`.

## Phase 1: Setup

**Mục đích**: Chuẩn bị test harness feature-local để kiểm chứng state transition và side effect của wizard.

- [x] T001 [P] Tạo TestBed harness cho `AgentEditorWizardComponent`, gồm mock `AgentService`, `AgentChatService`, `Router`, `ActivatedRoute` và cơ chế kiểm tra toast, trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.spec.ts`, đồng thời đăng ký spec trong `flex-microfrontend/src/test.ts`.

## Phase 2: Foundational

**Mục đích**: Hoàn thiện state model, route alias và copy nền tảng trước khi triển khai từng user story.

**Dependency**: T001 phải hoàn tất trước phase này; mọi user story phụ thuộc phase này.

- [x] T002 [P] Thêm route `/agents/:id/settings` trỏ tới wizard ở chế độ chỉnh sửa, giữ nguyên `/agents/create`, `/agents/:id/edit`, `/agents/:id` và `AuthGuard` hiện có trong `flex-microfrontend/src/app/app-routing.module.ts`.
- [x] T003 Xây dựng helper/state derivation trong `AgentEditorWizardComponent` để phân biệt `create` khi chưa có `agentId`, `draft` khi `status === 'inactive'`, `published` khi `status === 'active'`, đồng thời tính trạng thái khóa step, trạng thái đang submit và thời điểm cập nhật từ server trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.ts`.
- [x] T004 [P] Điều chỉnh `AgentStepGeneralComponent` để nhận biết màn tạo mới và dùng copy “Tạo Agent mới” cùng mô tả hướng dẫn tương ứng trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/steps/agent-step-general/agent-step-general.component.ts`.
- [x] T005 [P] Cập nhật template thông tin chung cho tiêu đề “Tạo Agent mới”, mô tả nhập thông tin cơ bản và ẩn dòng cập nhật khi chưa có bản ghi trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/steps/agent-step-general/agent-step-general.component.html`.

## Phase 3: User Story 1 — Tạo Agent chủ động từ thông tin chung (P1)

**Goal**: Người dùng chủ động tạo Agent bằng nút có ngữ nghĩa rõ ràng, nhận `AgentId`, chuyển sang settings và nhìn thấy trạng thái “Bản nháp”.

**Independent Test**:

1. Mở `/agents/create` và bấm “Tạo Agent và tiếp tục” khi form chưa hợp lệ; validation hiển thị và `AgentService.createAgent` không được gọi.
2. Nhập dữ liệu bắt buộc hợp lệ và bấm lại; xác nhận chỉ có một lệnh create với `status: inactive`.
3. Mock response có `id`; xác nhận điều hướng tới `/agents/{id}/settings`, hiển thị “Bản nháp” và step 2–5 được mở khóa.

### Tests for User Story 1

- [x] T006 [US1] Viết unit test cho validation create, create hợp lệ với payload `inactive`, chống submit lặp, nhận `id`, điều hướng tới settings và chuyển state sang draft trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.spec.ts` (viết test trước khi hoàn thiện implementation tương ứng).

### Implementation for User Story 1

- [x] T007 [US1] Tách handler “Tạo Agent và tiếp tục” trong `AgentEditorWizardComponent`: validate form, gọi `AgentService.createAgent` đúng payload hiện có với `status: inactive`, chặn submit lặp, nhận `AgentId`, cập nhật trạng thái draft và điều hướng tới `/agents/{id}/settings` trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.ts` (phụ thuộc T006).
- [x] T008 [US1] Cập nhật template wizard để hiển thị tiêu đề/trạng thái create và draft, step 1 hoàn tất sau khi có `AgentId`, step 2–5 mở khóa sau create thành công, dùng nút chính “Tạo Agent và tiếp tục” ở create và không hiển thị thời điểm cập nhật khi chưa có Agent trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.html` (phụ thuộc T007).
- [x] T009 [P] [US1] Bổ sung style Bootstrap/Skote hiện có cho badge “Bản chưa tạo”/“Bản nháp”, footer action và layout tối giản của màn tạo mới trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.scss` (phụ thuộc T007).

**Definition of Done**:

- Form invalid không gọi create; form hợp lệ chỉ tạo một Agent.
- Response có `AgentId` đưa wizard tới settings, hiển thị “Bản nháp” và mở khóa các bước.
- Nút chính ở create nêu rõ hành động tạo Agent; route cũ vẫn được giữ.
- Independent Test của US1 đạt.

## Phase 4: User Story 2 — Nhận biết và xử lý bước bị khóa (P1)

**Goal**: Người dùng nhận biết rõ step 2–5 bị khóa bằng icon, chữ và thông báo; tương tác với step khóa không tạo Agent.

**Dependency**: Phụ thuộc T003 và T007 để có state `create`/`draft`; các task sửa cùng wizard file chạy tuần tự.

**Independent Test**:

1. Mở `/agents/create` và xác nhận step 1 active, step 2–5 có lock icon và trạng thái không khả dụng.
2. Hover, focus và click từng step 2–5; xác nhận thông báo chính xác `Vui lòng tạo Agent trước để tiếp tục cấu hình.`.
3. Kiểm tra spy/network; không có lệnh create hoặc request API phát sinh từ thao tác step khóa.

### Tests for User Story 2

- [x] T010 [US2] Viết unit test cho trạng thái stepper create, lock icon/`aria-disabled`, thông báo khi hover/focus/click và xác nhận `AgentService.createAgent` không được gọi khi tương tác step khóa trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.spec.ts` (phụ thuộc T006; viết test trước implementation tương ứng).

### Implementation for User Story 2

- [x] T011 [US2] Sửa `onStepClick` và handler tương tác khóa trong `AgentEditorWizardComponent` để chỉ hiển thị `Vui lòng tạo Agent trước để tiếp tục cấu hình.`, giữ nguyên `currentStep` và tuyệt đối không gọi create/update/API khi chưa có `agentId` trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.ts` (phụ thuộc T010).
- [x] T012 [US2] Thay markup step khóa bằng button semantics có lock icon, trạng thái trực quan, `aria-disabled="true"`, keyboard/focus support và binding notice cho step 2–5 trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.html` (phụ thuộc T011).
- [x] T013 [US2] Bổ sung style trạng thái locked, icon lock, focus-visible và notice theo Bootstrap/Skote để trạng thái khóa không chỉ phụ thuộc vào màu chữ trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.scss` (phụ thuộc T012).

**Definition of Done**:

- Step 2–5 luôn có biểu tượng khóa và trạng thái không khả dụng trước khi có `AgentId`.
- Hover/focus/click đều giải thích lý do bị khóa; click không tạo Agent và không chuyển bước.
- Hành vi keyboard/accessibility được kiểm tra.
- Independent Test của US2 đạt.

## Phase 5: User Story 3 — Lưu và tiếp tục cấu hình Agent đã tạo (P1)

**Goal**: Agent draft có thể lưu thay đổi thông tin chung rồi chuyển sang bước cấu hình tiếp theo; không mở rộng backend draft riêng.

**Dependency**: Phụ thuộc T007 để có state draft và T011–T012 để stepper phản ánh đúng trạng thái.

**Independent Test**:

1. Mở Agent đã tồn tại ở trạng thái draft, thay đổi thông tin chung và bấm “Lưu và tiếp tục”.
2. Với dữ liệu hợp lệ, xác nhận một lệnh update tới Agent hiện tại với `status: inactive` và chuyển sang bước tiếp theo.
3. Với dữ liệu không hợp lệ, xác nhận vẫn ở bước hiện tại; nút “Lưu nháp” vẫn chỉ là UI/toast, không phát sinh persistence backend mới.

### Tests for User Story 3

- [x] T014 [US3] Viết unit test cho validation save, `updateAgent` với Agent draft, chuyển bước sau update thành công, giữ nguyên bước khi invalid, chống submit lặp, và không gọi API riêng cho “Lưu nháp” trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.spec.ts` (phụ thuộc T007; viết test trước implementation tương ứng).

### Implementation for User Story 3

- [x] T015 [US3] Tách handler “Lưu và tiếp tục” cho Agent đã có `agentId`: validate, gọi update hiện có với `status: inactive`, chuyển sang bước cấu hình tiếp theo khi thành công, giữ “Lưu nháp” ở dạng UI/toast và không thêm persistence backend trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.ts` (phụ thuộc T014).
- [x] T016 [US3] Cập nhật footer action theo state: create dùng “Tạo Agent và tiếp tục”, draft dùng “Lưu và tiếp tục” với nút phụ “Hủy”, published giữ “Lưu và phát hành lại”; giữ hành vi published hiện có trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.html` (phụ thuộc T015).

**Definition of Done**:

- Draft dùng “Lưu và tiếp tục”, lưu thay đổi hợp lệ trước khi chuyển bước.
- Invalid form giữ nguyên bước và hiển thị validation.
- “Lưu nháp” không được hiểu là persistence backend mới.
- Flow published “Lưu và phát hành lại” không bị thay đổi.
- Independent Test của US3 đạt.

## Phase 6: User Story 4 — Không kiểm thử Agent trước khi Agent tồn tại (P2)

**Goal**: Màn tạo mới không tạo kỳ vọng có thể chat/test khi Agent chưa tồn tại; sau khi có Agent, khu vực hiện lại theo behavior hiện có.

**Dependency**: Phụ thuộc T008 và T016 để template có state create/draft/published đúng trước khi gating top navigation và chat.

**Independent Test**:

1. Mở `/agents/create`; xác nhận `Hội thoại`, `Báo cáo hoạt động` bị ẩn hoặc khóa, input chat không thể gửi.
2. Xác nhận panel phải hiển thị “Chưa thể kiểm thử Agent” và hướng dẫn tạo/cấu hình trước khi trò chuyện.
3. Sau khi có `AgentId`, xác nhận khu vực hiện theo behavior hiện có và `onSendMessage` chỉ gửi khi có id.

### Tests for User Story 4

- [x] T017 [US4] Viết unit test cho visibility của top navigation, nội dung panel hướng dẫn trước create, guard `onSendMessage` khi thiếu `agentId` và behavior chat hiện có sau khi Agent tồn tại trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.spec.ts` (phụ thuộc T016; viết test trước implementation tương ứng).

### Implementation for User Story 4

- [x] T018 [US4] Bổ sung guard trong `AgentEditorWizardComponent` để `onSendMessage` không gọi `AgentChatService` khi chưa có `agentId`, đồng thời cung cấp state hiển thị/ẩn top navigation theo lifecycle Agent trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.ts` (phụ thuộc T017).
- [x] T019 [US4] Cập nhật template wizard để ở create chỉ hiển thị khu vực Thiết lập Agent, ẩn/khóa Hội thoại và Báo cáo hoạt động, thay khung chat bằng “Chưa thể kiểm thử Agent” cùng hướng dẫn; sau create giữ chat/top navigation hiện có trong `flex-microfrontend/src/app/features/agent-catalog/components/agent-editor-wizard/agent-editor-wizard.component.html` (phụ thuộc T018).

**Definition of Done**:

- Trước `AgentId`, không có input chat có thể gửi và không có request chat.
- Panel phải hiển thị đúng hướng dẫn “Chưa thể kiểm thử Agent”.
- Top navigation không cho truy cập Hội thoại/Báo cáo trước khi Agent tồn tại.
- Independent Test của US4 đạt.

## Final Phase: Polish & Cross-Cutting Validation

**Mục đích**: Kiểm tra hồi quy route, quyền truy cập, luồng hiện có và chất lượng build trước khi handoff.

- [ ] T020 Kiểm tra manual smoke theo toàn bộ kịch bản trong `specs/000040-agent-creation-gating/quickstart.md`, gồm create/lock/notice, route `/agents/{id}/settings`, draft save-and-continue, chat gating, dirty cancel, toggle channel và regression route edit/view/publish; xác nhận `AuthGuard` trong `flex-microfrontend/src/app/app-routing.module.ts` vẫn áp dụng.
- [ ] T021 Chạy `npm run lint`, `npm run test -- --watch=false --browsers=ChromeHeadless` và `npm run build` trong project `flex-microfrontend` theo scripts tại `flex-microfrontend/package.json`; xác nhận không có lỗi compile, test hoặc lint và không có duplicate toast/API ngoài hành vi dự kiến.

Không có task backend, database/migration, contract test, feature flag, observability mới hoặc cập nhật tài liệu nghiệp vụ còn lại: `plan.md` xác nhận các phạm vi này không áp dụng hoặc đã hoàn tất ở documentation impact gate.

## Validation Commands

- Lint: `npm run lint` tại `flex-microfrontend`.
- Unit test: `npm run test -- --watch=false --browsers=ChromeHeadless` tại `flex-microfrontend`.
- Build: `npm run build` tại `flex-microfrontend`.
- API contract test: Không áp dụng; sử dụng POST/PUT `AgentService` hiện có.
- Migration/smoke backend: Không áp dụng; chạy manual smoke UI theo `specs/000040-agent-creation-gating/quickstart.md`.

## Traceability Matrix

| Source | Covered by tasks |
|--------|------------------|
| US-001 / AC-001 | T006, T007, T008 |
| US-001 / AC-002 | T006, T007 |
| US-002 / AC-003 | T010, T012, T013 |
| US-002 / AC-004 | T010, T011, T012 |
| US-003 / AC-005 | T014, T015, T016 |
| US-003 / AC-006 | T014, T015 |
| US-004 / AC-007 | T017, T018, T019 |
| FR-001 | T003, T007 |
| FR-002 | T008 |
| FR-003 | T006, T007, T011 |
| FR-004 | T010, T012, T013 |
| FR-005 | T010, T011 |
| FR-006 | T014, T015, T016 |
| FR-007 | T017, T018, T019 |
| FR-008 | T014, T015, T016 |
| BR-001 | T003, T008, T012 |
| BR-002 | T011, T012 |
| BR-003 | T007, T008 |
| BR-004 | T014, T015 |
| BR-005 | T015 |
| SEC-001 | T002, T020 |
| SEC-002 | T003, T011, T018 |
| NFR-001 | T012, T013 |
| NFR-002 | T012, T013, T020 |
| NFR-003 | T020, T021 |
| SC-001 | T010, T011, T020 |
| SC-002 | T006, T017, T019 |
| SC-003 | T007, T008, T020 |
| Agent / status / updatedAt | T003, T007, T008, T015 |
| Wizard UI state / step state | T003, T008, T011, T012 |
| Validation rules | T006, T014 |

## Dependencies & Execution Order

### Phase Dependencies

- **Setup**: T001 không phụ thuộc task khác.
- **Foundational**: T002–T005 phụ thuộc T001; phải hoàn tất trước user story.
- **US1**: T006–T009 phụ thuộc foundation; T007 phụ thuộc T006, T008–T009 phụ thuộc T007.
- **US2**: T010–T013 phụ thuộc foundation và T007; T011 phụ thuộc T010, T012 phụ thuộc T011, T013 phụ thuộc T012.
- **US3**: T014–T016 phụ thuộc T007 và T011–T012; T015 phụ thuộc T014, T016 phụ thuộc T015.
- **US4**: T017–T019 phụ thuộc T008 và T016; T018 phụ thuộc T017, T019 phụ thuộc T018.
- **Polish**: T020–T021 chỉ chạy sau khi các user story đã hoàn tất.

### Parallel Opportunities

- T002 có thể chạy song song với T003 sau T001 vì sửa hai file khác nhau.
- T004 và T005 có thể chạy song song sau T003 vì lần lượt sửa TypeScript và template của `AgentStepGeneralComponent`.
- T009 có thể chạy song song với T008 vì sửa SCSS và HTML khác nhau; khi tích hợp cần kiểm tra cùng state class.
- Các task cùng sửa `agent-editor-wizard.component.ts`, `.html`, hoặc `.spec.ts` không được chạy song song với nhau.
- US2, US3 và US4 có thể phân công theo story sau foundation, nhưng do cùng sửa wizard tổng hợp nên cần thực thi tuần tự hoặc có integration owner; dependency hiện tại chọn thứ tự an toàn.

## Implementation Strategy

### MVP First

1. Hoàn tất T001–T005 để có test harness, route và state foundation.
2. Hoàn tất T006–T009 để deliver US1: tạo Agent chủ động, nhận id, chuyển settings và hiển thị draft.
3. Hoàn tất T010–T013 ngay sau US1 vì lock/notice là safety requirement cốt lõi của luồng tạo mới.
4. Dừng và validate độc lập bằng test US1/US2 cùng manual smoke tương ứng trước khi mở rộng US3/US4.

MVP tối thiểu theo spec là US1; MVP khuyến nghị gồm US1 + US2 để không còn đường tạo Agent ngoài ý muốn qua step khóa.

### Incremental Delivery

1. Foundation → US1 (create và route) → validate.
2. US2 (locked step và no-side-effect) → validate.
3. US3 (draft save-and-continue) → validate.
4. US4 (chat/top navigation gating) → validate.
5. T020–T021 để kiểm tra hồi quy và build handoff.

## Checklist chất lượng trước khi implement

- [x] Không còn task ví dụ hoặc placeholder trong output.
- [x] Task được đánh số tuần tự từ T001 đến T021.
- [x] Mỗi task implementation/test có path cụ thể hoặc command cụ thể.
- [x] Task đã nêu rõ class, handler, state hoặc section cần sửa.
- [x] Dependency và thứ tự thực thi đã ghi rõ.
- [x] Mỗi user story có Independent Test và Definition of Done.
- [x] US/FR P1/P2, business rule, security, NFR và success criteria đều có traceability.
- [x] Không có task database/migration/contract vì plan xác nhận không áp dụng.
- [x] Không có task tài liệu vì tài liệu nghiệp vụ đã cập nhật trước plan và không còn cập nhật sau implementation.
- [x] Task `[P]` chỉ áp dụng cho task khác file và không có dependency chéo.
