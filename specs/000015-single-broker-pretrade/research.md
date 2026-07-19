# Research: Một CTCK và kiểm tra trước giao dịch

Research đối chiếu spec MVP 5 với layout và artifact MVP 1-4 của `flex-exchange-service`. Không dùng web vì quyết định phụ thuộc codebase nội bộ.

## TQ-001 — Lưu account/reservation ở đâu?

**Decision**: `DemoAccountState`, `BrokerOrderState` và `Reservation` ở Application in-memory.

**Rationale**: README và các plan trước xác nhận Exchange local demo, state in-memory, chưa có database nghiệp vụ; spec loại trừ ledger/settlement/persistence.

**Alternatives**: PostgreSQL/MySQL ledger — loại vì vượt MVP và tạo migration/accounting scope.

## TQ-002 — Broker gọi Exchange qua boundary nào?

**Decision**: `DemoBrokerService` gọi `IExchangeService`, không tham chiếu `MatchingEngine` trực tiếp.

**Rationale**: Giữ Domain thuần và tái sử dụng Application event/order flow.

**Alternatives**: Gọi `MatchingEngine` trực tiếp — bypass Application contract và audit.

## TQ-003 — Bảo đảm reserve trước route thế nào?

**Decision**: Lock bao quanh validate, tính available, reserve và tạo Broker state; sau đó mới gọi Exchange.

**Rationale**: Đáp ứng FR-005/BR-003; reject path không thể tạo Exchange order.

**Alternatives**: Route trước rồi compensate — tạo exposure và vi phạm pre-trade.

## TQ-004 — Retry/timeout và link lệnh?

**Decision**: `clientOrderId` là idempotency key trong account/session; mapping giữ client, exchange, reservation và status. Timeout là `PendingExchangeConfirmation`, retry cùng payload trả state hiện có.

**Rationale**: Không tạo route trùng khi không biết Exchange đã nhận request hay chưa.

**Alternatives**: Retry tự động không key — không phân biệt retry với lệnh mới.

## TQ-005 — Seed account demo thế nào?

**Decision**: Hai account seed deterministic từ `DemoBroker:Accounts` trong Development; không có account-provisioning API.

**Rationale**: Tái lập demo/test và không mở rộng account lifecycle.

**Alternatives**: Seed ngẫu nhiên/API tạo account — khó kiểm chứng và vượt scope.

## TQ-006 — Giữ compatibility API ra sao?

**Decision**: Thêm `/api/broker/*`, giữ nguyên `/api/orders`, `/api/orderbook`, `/api/events` và SignalR contracts MVP trước.

**Rationale**: Broker là boundary mới; additive contract giảm regression.

**Alternatives**: Đổi `/api/orders` thành Broker endpoint — phá consumer và làm mơ hồ ownership.
