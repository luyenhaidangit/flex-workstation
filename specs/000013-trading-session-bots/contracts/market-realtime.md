# Contract realtime market board

## Hub

- URL: `/hubs/market`.
- Transport: WebSocket; client không gửi command nghiệp vụ.
- Server method: `marketEvent`.

## Snapshot

```json
{"type":"MARKET_SNAPSHOT","sessionId":"...","sessionState":"continuous","symbol":"FXS","orderBook":{"symbol":"FXS","bids":[],"asks":[]},"trades":[],"eventSequence":12,"occurredAt":"2026-07-18T12:00:00Z"}
```

## Incremental

`SESSION_STATE_CHANGED` có state/timestamps; `ORDER_BOOK_CHANGED` có order book mới; `TRADE_EXECUTED` có trade entry. Mọi message có sequence/timestamp; client bỏ qua sequence cũ khi reconnect.

## HTTP

- `POST /api/trading-session/start`: `201` khi tạo, `409` nếu session đang chạy.
- `GET /api/trading-session`: state hiện tại hoặc `204` khi chưa start.
- Order placement/cancel tiếp tục đi qua HTTP API hiện có.
