# Research: Phân tách trạng thái tạo và cấu hình Agent

## Phạm vi research

Research tập trung vào các quyết định cần để lập tasks cho UI Angular hiện có. Không có câu hỏi database, migration, backend contract hoặc service boundary mới.

## Quyết định 1 — Route sau khi tạo Agent

**Decision**: Thêm route `/agents/:id/settings` trỏ tới `AgentEditorWizardComponent` ở mode `edit`, đồng thời giữ `/agents/:id/edit` và `/agents/:id`.

**Rationale**: Spec yêu cầu URL thể hiện khu vực settings sau khi nhận `AgentId`. Root `app-routing.module.ts` hiện đã khai báo trực tiếp các route Agent, nên alias ở cùng module là thay đổi nhỏ nhất. Giữ route cũ tránh làm hỏng link từ danh sách hoặc bookmark hiện có.

**Alternatives considered**:
- Thay toàn bộ route cũ bằng nested route: bị loại vì vượt scope và có rủi ro regression.
- Chỉ dùng `/agents/:id/edit`: bị loại vì không phản ánh URL settings đã thống nhất trong luồng nghiệp vụ.

## Quyết định 2 — Nguồn trạng thái

**Decision**: Dùng `agentId` để phân biệt `create` với Agent đã tồn tại; dùng `Agent.status` hiện có (`inactive`/`active`) để hiển thị bản nháp/đã phát hành.

**Rationale**: `AgentService.createAgent()` đã trả về `Agent` có `id`, và API hiện đã nhận status. Stakeholder chưa yêu cầu backend draft/versioning, nên không tạo enum hoặc state store mới.

**Alternatives considered**:
- Thêm status `draft` vào backend: bị loại vì ngoài phạm vi.
- Tạo state store riêng cho wizard: bị loại vì state chỉ thuộc một component và dùng một lần.

## Quyết định 3 — Hành vi step bị khóa

**Decision**: Render step bằng button có `aria-disabled="true"`, class khóa và lock icon; hover/focus/click gọi cùng helper hiển thị thông báo nhưng không gọi API.

**Rationale**: Native `disabled` không nhận focus/click, trong khi requirement yêu cầu giải thích khi người dùng tương tác. Button có semantics tốt hơn `<div>` clickable và đáp ứng keyboard accessibility.

**Alternatives considered**:
- Chỉ dùng `disabled`: bị loại vì không thể hiển thị thông báo theo click/focus.
- Giữ `<div>` hiện tại: bị loại vì thiếu semantics/accessibility cho stepper.

## Quyết định 4 — Tách action handler

**Decision**: Tách create, save-and-continue và publish thành các handler riêng; giữ `onSaveDraft()` là UI-only.

**Rationale**: Handler hiện tại `onPublish()` vừa create vừa update active, còn `onStepClick()` vừa điều hướng vừa create ngầm. Tách handler làm side effect khớp label và state.

**Alternatives considered**:
- Dùng một handler và đổi label động: bị loại vì dễ gửi sai status hoặc tạo Agent ngoài ý muốn.
- Xóa “Lưu nháp”: bị loại vì stakeholder yêu cầu giữ UI.

## Quyết định 5 — Chat và top navigation ở create state

**Decision**: Ẩn top tabs `Hội thoại`/`Báo cáo hoạt động`, render panel hướng dẫn thay cho chat input, và guard `onSendMessage()` bằng `agentId`.

**Rationale**: Spec yêu cầu không tạo affordance kiểm thử trước khi Agent tồn tại. Không xây route/chat feature mới vì phần này ngoài scope.

**Alternatives considered**:
- Chỉ làm mờ input: bị loại vì vẫn tạo cảm giác có thể dùng.
- Thay đổi chat API để truyền AgentId: bị loại vì là contract change ngoài MVP.

## Quyết định 6 — Kiểm thử

**Decision**: Bổ sung unit spec cho state/action helper và manual smoke cho route/API flow; chạy build/lint/test hiện có.

**Rationale**: Repository có Karma/Jasmine nhưng chưa có spec cho wizard. Logic create/lock/chat guard có side effect rõ và cần spy kiểm chứng; layout/route cần manual browser check.

**Alternatives considered**:
- Chỉ manual test: bị loại vì dễ bỏ sót lỗi create ngầm và service call.
- Thêm E2E framework mới: bị loại vì không cần cho thay đổi nhỏ và vượt scope.

