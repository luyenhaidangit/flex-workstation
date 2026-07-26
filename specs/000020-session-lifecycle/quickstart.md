# Quickstart: Xác thực Vòng đời & Ràng buộc Trạng thái Phiên Giao dịch

**Input**: [spec.md](./spec.md) US-001, US-002; [contracts/session-lifecycle.md](./contracts/session-lifecycle.md)

## Chuẩn bị

```bash
cd flex-exchange-service
dotnet run --project src/Flex.Exchange.Api
```

Đặt thời lượng phase ngắn trong `appsettings.Development.json` (vd. vài giây mỗi phase, xem [data-model.md § 6](./data-model.md)) để không phải chờ lâu khi test thủ công.

Dùng `src/Flex.Exchange.Api/Flex.Exchange.http` hoặc `curl` cho các bước dưới.

## Kịch bản 1 — US-002: Chuyển phiên đúng lịch trình từng sàn (AC-003, AC-004)

1. Khởi động phiên cho `HNX-Derivatives` (có ATO): `POST /api/session/start?market=HNX-Derivatives`
2. Gọi `GET /api/session?market=HNX-Derivatives` ngay sau đó — kỳ vọng `state = "preopen"`.
3. Chờ hết `PreOpenSeconds` — gọi lại `GET` — kỳ vọng `state = "ato"` (AC-003).
4. Khởi động phiên cho `UPCoM` (không ATO): `POST /api/session/start?market=UPCoM`
5. Chờ hết `PreOpenSeconds` — gọi `GET` — kỳ vọng `state = "continuous"` ngay, **không** qua `ato` (AC-004).

## Kịch bản 2 — US-001: Chặn hủy lệnh và sai loại lệnh trong ATO/ATC (AC-001, AC-002, AC-005)

1. Với phiên `HNX-Derivatives` đang ở `ato` (từ kịch bản 1):
   - `POST /api/orders` với `orderType: "LO"` — kỳ vọng `accepted = true` (BR-001 cho phép `LO` trong ATO).
   - `POST /api/orders` với `orderType: "ATC"` — kỳ vọng bị từ chối, `reason = "OrderTypeNotAllowedInCurrentSession"` (AC-005).
   - `DELETE /api/orders/{orderId}` với `orderId` của lệnh `LO` vừa đặt — kỳ vọng bị từ chối, `reason = "CancelNotAllowedInCurrentSession"` (AC-001).
2. Chờ chuyển sang `continuous` (hết `AtoSeconds`):
   - `DELETE /api/orders/{orderId}` cùng `orderId` — kỳ vọng `cancelled = true` (AC-002).

## Kịch bản 3 — BR-005/BR-006: Từ chối lệnh trong `PreOpen`/`PLO`

1. Ngay sau `POST /api/session/start?market=HNX` (có PLO, không ATO): `state = "preopen"`.
2. `POST /api/orders` bất kỳ — kỳ vọng bị từ chối `reason = "SessionNotOpen"`.
3. Chờ chu trình đầy đủ đến khi `state = "plo"` (sau `atc`).
4. `POST /api/orders` — kỳ vọng bị từ chối `reason = "SessionClosed"`.

## Kịch bản 4 — BR-004: Hủy toàn bộ lệnh còn lại khi vào `Close`

1. Đặt một lệnh `LO` trong `continuous` không có đối ứng để nó nằm chờ trong order book.
2. Chờ phiên đi hết vòng đời đến `close` (qua `atc`, `plo`/không tùy market).
3. `GET /api/orders/{orderId}` — kỳ vọng `status = "Cancelled"`.

## Kịch bản 5 — BR-007/NFR-002: Ghi CSDL trước khi transition (manual/log check)

1. Dừng PostgreSQL tạm thời (hoặc chặn kết nối) trước một lần chuyển phase.
2. Quan sát log — kỳ vọng thấy log mức `Critical` lặp lại theo từng lần retry thất bại (NFR-002), và `GET /api/session` **vẫn giữ nguyên** `state` cũ (chưa chuyển) cho đến khi CSDL ghi được.
3. Khôi phục kết nối PostgreSQL — kỳ vọng transition tiếp tục và `state` cập nhật đúng phase kế tiếp.

## Test tự động tương ứng

- `Flex.Exchange.Domain.Tests/TradingSessionStateTests.cs` — mở rộng cho lifecycle 7-phase và market không có ATO/PLO.
- `Flex.Exchange.Api.Tests` — thêm test cho `SessionController`, `OrdersController` (order type + cancel gate).
