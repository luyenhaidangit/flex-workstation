# Research: Exchange API và nhật ký sự kiện

## RQ-001 — Giữ tương thích với matching engine MVP 01

**Decision**: Giữ `MatchingEngine` là nguồn sự thật cho validation, matching, order book và event ordering; mở rộng các read model/lookup cần thiết thông qua application boundary thay vì đưa HTTP vào Domain.

**Rationale**: Code hiện tại đã tách `Domain → Application → Api`, có lock tại `ExchangeService` và có các event/order model đang được domain tests bảo vệ. Chỉ mở rộng engine cho metadata và truy vấn cần thiết để giảm nguy cơ làm lệch price-time priority và determinism.

**Alternatives considered**:

- Đọc trực tiếp state từ controller: loại vì phá vỡ boundary.
- Tạo repository/database: loại vì database nghiệp vụ nằm ngoài MVP 02.

## RQ-002 — Trạng thái, trade tape và lịch sử theo lệnh

**Decision**: Engine giữ collection in-memory có thứ tự cho `Order` và `Trade`; application tạo immutable read models cho trạng thái lệnh, trade tape, snapshot và event history.

**Rationale**: Đủ cho một `DemoBroker`, deterministic khi khởi động lại và không thêm persistence ngoài scope. Query không được làm thay đổi engine state.

**Alternatives considered**:

- Suy ra trạng thái chỉ từ order book: loại vì filled/cancelled orders đã rời book.
- Event store bền vững: loại vì thuộc MVP sau.

## RQ-003 — Event metadata, thời điểm và correlation

**Decision**: Event có `EventId` ổn định theo event sequence, `OccurredAt` là logical timestamp dựa trên sequence để replay deterministic, và `CorrelationId` lấy từ request context nếu có hoặc fallback deterministic theo command/event sequence. W3C `Activity` chỉ dùng cho diagnostics/logging, không làm canonical replay id.

**Rationale**: Spec đồng thời yêu cầu thời điểm/correlation và kết quả replay giống nhau. Logical timestamp cùng fallback deterministic giải quyết xung đột này.

**Alternatives considered**:

- `DateTimeOffset.UtcNow` và random `Guid`: loại vì làm canonical stream không deterministic.
- Custom correlation middleware: loại vì ASP.NET Core đã có W3C Activity; không nhân đôi pipeline.

## RQ-004 — Hợp đồng HTTP và compatibility

**Decision**: Giữ các route/response hiện có; bổ sung truy vấn theo order, trade tape và event history. Các field mới additive, không đổi semantics hiện tại.

**Rationale**: `MvpAcceptanceTests` và Gateway demo đang dùng contract hiện tại. Additive change giúp rollback đơn giản.

**Alternatives considered**:

- Đổi toàn bộ response sang envelope version mới: loại vì tạo breaking change không cần thiết.
- Xóa `/api/events`: loại vì đây là contract hiện có.

## RQ-005 — Concurrency, retry và lỗi

**Decision**: Tiếp tục serialize command/read state bằng lock hiện có của `ExchangeService`; không thêm idempotency cho retry `PlaceOrder` trong MVP. Hủy lặp lại trả business rejection. Unexpected failure dùng Problem Details và correlation field an toàn.

**Rationale**: MVP chỉ có một process/in-memory engine; lock bảo toàn thứ tự nhận. Idempotency đầy đủ nằm ngoài scope.

**Alternatives considered**:

- Concurrent mutation không khóa: loại vì phá sequence determinism.
- Tự động deduplicate mọi `PlaceOrder`: loại vì cần durable idempotency semantics.

## RQ-006 — Validation và kiểm thử

**Decision**: Bổ sung domain unit tests cho metadata/state lookup và API integration/contract tests cho command, query, rejection, correlation, event ordering và deterministic replay; giữ manual `.http` smoke flow.

**Rationale**: Unit test bảo vệ invariant; integration test chứng minh routing/serialization/middleware; manual flow giữ khả năng demo.

**Alternatives considered**:

- Chỉ unit test: không chứng minh HTTP contract.
- Chỉ manual: không bảo vệ regression tự động.
