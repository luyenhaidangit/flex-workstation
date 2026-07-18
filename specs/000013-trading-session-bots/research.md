# Research: Phiên giao dịch, realtime và bot

## SignalR với WebSocket transport

**Decision**: Dùng ASP.NET Core SignalR Hub `/hubs/market`, client ép WebSocket transport; server dùng `IHubContext` để broadcast từ worker.

**Rationale**: ASP.NET Core có sẵn SignalR trong shared framework, hỗ trợ lifecycle, broadcast, reconnect và background-service integration.

**Alternatives**: Raw `System.Net.WebSockets` bị loại vì phải tự xử lý framing, connection registry, broadcast/reconnect. Polling không đáp ứng mục tiêu realtime.

**Nguồn**: [Host ASP.NET Core SignalR in background services](https://learn.microsoft.com/en-us/aspnet/core/signalr/background-services), [Overview of ASP.NET Core SignalR](https://learn.microsoft.com/en-us/aspnet/core/signalr/introduction).

## Hosted worker và bot boundary

Một `BackgroundService` điều phối clock/bot với cancellation của host. Bot tạo `PlaceOrderCommand`/`CancelOrderCommand` qua application/`DemoBroker`, không gọi matching engine trực tiếp, để giữ validation, correlation và event contract.

## State

Session và book/trades giữ in-memory theo giới hạn demo; restart mất state là hành vi chấp nhận được, không tạo migration.
