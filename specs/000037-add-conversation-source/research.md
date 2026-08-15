# Research: Phân loại nguồn hội thoại

## TQ-001 — Ownership của database và migration

**Decision**: Dữ liệu thuộc PostgreSQL database `agentdb`, schema mặc định `public`; migration đặt tại `flex-database/agentdb`.

**Rationale**: `docs/architecture/system-map.md` xác nhận `agentdb` là database chuyên biệt của Agent Platform và `flex-database` là repo migration dùng chung. Migration V1.3 của conversation hiện có nằm tại repo này.

**Alternatives considered**: EF Core migration trong service bị loại vì trái ownership và tạo hai nguồn sự thật schema.

## TQ-002 — Trusted source assignment

**Decision**: Source do trusted ingress gán qua application/domain context; không nhận source tùy ý từ request body hoặc header client. Endpoint browser hiện tại map `Production`; ingress Preview/Playground/Api dùng context tương ứng khi được tích hợp.

**Rationale**: `POST /api/v1/conversations` hiện được FE chat gọi. HTTP transport không đủ suy ra business origin; client tự khai sẽ cho phép gắn nhãn sai.

**Alternatives considered**: Request field/header làm authority bị loại; suy luận từ `actor_type` bị loại vì source và actor là hai khái niệm khác nhau.

## TQ-003 — Compatibility và legacy data

**Decision**: Column nullable; row cũ không có evidence giữ `NULL`; response thêm field additive.

**Rationale**: Không có dữ liệu chứng minh nguồn từng row, nên default `Production` sẽ làm sai phân tích. Consumer cũ bỏ qua field mới vẫn hoạt động.

**Alternatives considered**: Backfill Production bị loại; thêm `Unknown=0` bị loại vì yêu cầu chốt bốn mã.

## Specialist review notes

- `flex-dotnet-engineering`: giữ Domain invariant, EF mapping ngoài Domain, tenant authorization và persistence/contract tests.
- `flex-database-engineering`: changeset additive, constraint rõ, không backfill suy đoán, migration ownership tại `flex-database`.
- `flex-frontend-engineering`: chỉ cập nhật typed model/API consumer, không thêm UI ngoài scope.
- `flex-naming-convention`: `ConversationSource` là domain enum; `conversationSource` là transport field; không đổi tên public symbol hiện có.
