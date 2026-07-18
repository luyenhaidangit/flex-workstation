# Kế hoạch triển khai: Phiên giao dịch, realtime và market-maker bot

**Branch**: `000013-trading-session-bots` | **Ngày**: 2026-07-18 | **Đặc tả**: `spec.md`

## Tóm tắt

MVP 04 bổ sung vòng đời `open → continuous → close`, chặn lệnh ngoài `continuous`, phát snapshot/incremental market data realtime và một market-maker bot đặt lệnh qua `DemoBroker` cho mã FXS.

**Hướng tiếp cận**: Mở rộng `flex-exchange-service` theo Clean Architecture; domain giữ state/matching rules, application điều phối session/bot, API host SignalR hub và `BackgroundService`, Angular thay polling bằng SignalR client nhưng vẫn đặt/hủy qua HTTP.

## Phạm vi kỹ thuật

**Trong phạm vi**: `Flex.Exchange.Domain` session state/transition/close cleanup; `Flex.Exchange.Application` session service, bot abstraction, market event contract; `Flex.Exchange.Api` SignalR hub `/hubs/market`, hosted worker, start/status endpoints, DI/config; `flex-microfrontend/src/app/exchange` realtime/reconnect/session UI; unit/integration/contract/manual tests.

**Ngoài phạm vi**: database/migration/persistence, clearing, settlement, ATO/ATC, JWT/Keycloak, nhiều symbol/bot và lệnh qua WebSocket.

## Bối cảnh kỹ thuật

| Mục | Quyết định |
|---|---|
| Ngôn ngữ | C#/.NET 9, Angular/TypeScript hiện có |
| Service | `flex-exchange-service`, trang `/exchange` |
| Phụ thuộc | ASP.NET Core SignalR trong shared framework, `BackgroundService`, frontend `@microsoft/signalr` |
| Lưu trữ | In-memory; ngày ảo mới reset book/trades |
| Kiểm thử | xUnit, `WebApplicationFactory`, SignalR/WebSocket integration, Angular unit, manual browser |
| Mục tiêu | Mọi transition/market update tới client trong tối đa 3 giây |
| Ràng buộc | Một FXS, một session, một bot; thread-safe giữa HTTP/worker |

## Kiểm tra constitution

| Gate | Ban đầu | Sau design | Ghi chú |
|---|---|---|---|
| Spec-before-code/traceability | Pass | Pass | Có spec, plan và mapping P1 |
| Clean Architecture/boundary | Pass | Pass | Domain không phụ thuộc API/SignalR |
| Security/no secret | Pass | Pass | Demo-only, hub read-only |
| Testability/quality | Pass | Pass | Unit, integration, contract, manual |
| Observability/rollback | Pass | Pass | Log transition/bot/correlation; config rollback |
| Simplicity/scope | Pass | Pass | Không DB/process ngoài scope |

## Câu hỏi kỹ thuật đã resolve

- **TQ-001**: Chọn SignalR với WebSocket transport thay raw WebSocket để có lifecycle, broadcast, reconnect và `IHubContext`.
- **TQ-002**: Bot gọi application service/`DemoBroker`, không gọi `MatchingEngine` trực tiếp.
- **TQ-003**: Client mới nhận một snapshot nguyên tử gồm session, order book và N trades trước incremental events.
- **TQ-004**: Không persistence/migration; state reset theo ngày ảo.

## Thiết kế tổng quan

1. `POST /api/trading-session/start` atomically tạo session `open`, từ chối `409` nếu session đang chạy.
2. `TradingSessionWorker` chờ duration, chuyển `open → continuous`, chạy bot cycle, rồi `continuous → close`.
3. Order/trade/transition tạo `MarketEvent`; publisher broadcast qua `IHubContext<MarketHub>`.
4. Hub gửi `MARKET_SNAPSHOT` khi connect; sau đó gửi `SESSION_STATE_CHANGED`, `ORDER_BOOK_CHANGED`, `TRADE_EXECUTED`.
5. Frontend reducer cập nhật board/reconnect; HTTP order API giữ nguyên.
6. Close: bot graceful-cancel, Exchange backstop-cancel toàn bộ lệnh còn lại.

**Module**: `Domain/TradingSession`; `Application/TradingSession`, `Application/MarketData`; `Api/Hubs/MarketHub`; `Api/HostedServices/TradingSessionWorker`; `flex-microfrontend/src/app/exchange`.

**Concurrency/error**: lock/`SemaphoreSlim` bảo vệ transition và mutation; không await broadcast khi giữ lock; start trùng trả `409`; place ngoài continuous bị reject; reconnect dùng exponential backoff và snapshot lại; bot timeout bỏ qua cycle hiện tại.

## Traceability

| Spec | Thiết kế/module | Contract/data | Kiểm thử |
|---|---|---|---|
| US-001/FR-001..003 | State machine + worker + hub | Session API, `SESSION_STATE_CHANGED` | Domain/API/WebSocket |
| US-002/FR-004..005 | Snapshot + incremental SignalR | `MARKET_SNAPSHOT`, book/trade events | Contract/browser |
| US-003/FR-006..007 | Bot qua application/DemoBroker | Existing order/events | Domain/integration |
| US-004/FR-008..009 | Close cleanup, single active session | Reject reason, status API | Integration |
| FR-010..011 | BrokerId, event sequence, initial snapshot | Event DTO | Contract test |

## Phân tích tác động

| Khu vực | Tác động/rủi ro | Cách kiểm tra |
|---|---|---|
| Database | Không đổi; mất state khi restart là giới hạn MVP | Không có migration |
| API | Thêm session API/hub; order API backward compatible | OpenAPI/integration |
| Security | Hub read-only, demo local | Không có hub command/token |
| Logging | Session/bot/event/connection/correlation | Structured log review |
| UI | Polling → realtime, thêm session/reconnect | Angular/manual |
| Worker | Clock + bot loop; rủi ro duplicate/race | Hosted-service tests |

## API/Contract Detail

| Contract | Thay đổi | Compatibility |
|---|---|---|
| `POST /api/trading-session/start` | Start ngày ảo; `409` khi đang chạy | Additive |
| `GET /api/trading-session` | State/timestamps/config summary | Additive |
| `/hubs/market` | WebSocket SignalR, snapshot rồi incremental | Additive |
| `MARKET_SNAPSHOT`, `SESSION_STATE_CHANGED`, `ORDER_BOOK_CHANGED`, `TRADE_EXECUTED` | JSON camelCase, sequence/timestamp/symbol | Consumer bỏ qua field mới |

## Permission Matrix

| Scope | Xem | Tạo/Hủy lệnh | Start session |
|---|---:|---:|---:|
| Demo observer | Có | Không | Không |
| Demo broker/user | Có | Có | Không |
| Demo operator | Có | Theo scope demo | Có |

## Dữ liệu & migration

Không đổi schema, không migration/backfill. `TradingSession` giữ `SessionId`, `Symbol`, `State`, phase timestamps/durations. `MarketMakerOptions` giữ reference price, spread ticks, quantity, cycle interval, broker id. `MarketEvent` giữ type, sequence, occurredAt, sessionId, symbol, payload, correlationId. Close phải không còn remaining order; session mới bắt đầu book/trades trống.

## Quyết định kỹ thuật

| ID | Chọn | Lý do | Loại |
|---|---|---|---|
| DEC-001 | SignalR ép WebSocket | Lifecycle/broadcast/reconnect có sẵn trong ASP.NET Core | Raw WebSocket quá nhiều plumbing |
| DEC-002 | Một `BackgroundService` | Host cancellation và lifecycle đồng bộ | Timer/process riêng khó kiểm soát |
| DEC-003 | Bot qua application/DemoBroker | Tuân thủ BR-003, giữ validation/event | Gọi engine trực tiếp bypass boundary |
| DEC-004 | In-memory | Đúng giới hạn demo, không migration | DB/event store ngoài scope |

## Chiến lược kiểm thử

- **Unit**: transition, duration, invalid start, close cleanup, quote/cancel, order gate.
- **Integration**: start/phase/order reject/bot match/close/restart.
- **Contract**: SignalR snapshot/event JSON, sequence, BrokerId, HTTP/OpenAPI.
- **Security**: hub không có command; không phát token/secret.
- **E2E/manual**: hai tab, realtime, reconnect, match, close reject.
- **Regression**: Exchange domain/API và Angular Exchange tests.

## Cấu trúc project

```text
specs/000013-trading-session-bots/{plan.md,research.md,data-model.md,quickstart.md,contracts/market-realtime.md,tasks.md}
flex-exchange-service/src/Flex.Exchange.Domain/TradingSession/
flex-exchange-service/src/Flex.Exchange.Application/{TradingSession,MarketData}/
flex-exchange-service/src/Flex.Exchange.Api/{Hubs,HostedServices}/
flex-microfrontend/src/app/exchange/
```

## Rollout & rollback

Config: `TradingSession:Enabled`, `OpenDurationSeconds`, `ContinuousDurationSeconds`, `Bot:Enabled`, `CycleSeconds`, `SpreadTicks`, `Quantity`. Deploy Exchange/frontend đồng thời hoặc Exchange trước; rollback bằng tắt feature/bot và quay frontend về polling MVP 03. Không có data rollback. Kích hoạt rollback khi duplicate session, event sequence lệch, order tồn tại sau close hoặc reconnect không khôi phục trong 3 giây.

## Observability & debug

Log `sessionId`, `state`, timestamps, `brokerId`, `orderId`, `eventSequence`, `eventType`, `connectionId`, `correlationId`, `result`; không log token/secret. Theo dõi transition/bot/match/reconnect/broadcast latency/cleanup metrics. Kiểm tra `/health`, status API, hai client SignalR và structured logs.

## Theo dõi độ phức tạp

Không có ngoại lệ constitution.

## Checklist sẵn sàng cho `/speckit-tasks`

- [x] Phạm vi, boundary, concurrency và API/event contract đã rõ.
- [x] Mọi US/FR P1 đã mapping module, data và test.
- [x] Migration, rollout, rollback, observability và security đã đánh giá.
- [x] Không còn clarification chặn task generation hoặc path generic.
