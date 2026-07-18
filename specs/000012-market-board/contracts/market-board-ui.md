# Contract UI — Bảng điện thị trường demo

## Phạm vi contract

Đây là contract giữa Angular feature và `flex-exchange-service`. MVP 3 không thay đổi public endpoint của Exchange; client phải dùng đúng JSON hiện có và tolerant với field nullable.

## Endpoint được tiêu thụ

| Method | Path | Mục đích | Thành công |
|---|---|---|---|
| GET | `/api/orderbook` | Snapshot FXS | `200 OrderBookSnapshot` |
| GET | `/api/trades` | Trade tape | `200 TradeTapeEntry[]` |
| POST | `/api/orders` | Đặt lệnh demo | `200 PlaceOrderResponse` |
| GET | `/api/orders/{orderId}?brokerId={id}` | Đọc trạng thái order | `200 OrderStatusView`, `404` nếu không thấy |
| DELETE | `/api/orders/{orderId}?brokerId={id}` | Hủy order demo | `200 CancelOrderResponse` |

Request đặt lệnh:

```json
{
  "brokerId": "demo-broker-a",
  "symbol": "FXS",
  "side": "Buy",
  "price": 20000,
  "quantity": 100
}
```

Response đặt lệnh tối thiểu:

```json
{
  "accepted": true,
  "orderId": 1,
  "reason": null,
  "events": []
}
```

Response từ chối vẫn là HTTP success theo contract hiện tại nhưng `accepted = false` và `reason` có giá trị; UI không được coi mọi HTTP 200 là thành công nghiệp vụ.

## Headers và correlation

- Client tạo `X-Correlation-Id` cho mỗi command place/cancel.
- Các query polling có thể dùng correlation id riêng theo phiên refresh hoặc bỏ trống để backend fallback.
- Không tự gửi `Authorization` từ feature; interceptor hiện có chỉ thêm bearer khi có token và URL thuộc API base.

## Mapping lỗi

| Tình huống | Cách hiển thị |
|---|---|
| HTTP 400 | Lỗi dữ liệu nhập; giữ form và chỉ rõ trường nếu có |
| HTTP 404 khi đọc/hủy | Order không còn tồn tại hoặc không thuộc broker; refresh lại trạng thái |
| HTTP 429 | Thông báo tạm thời bị giới hạn; giữ dữ liệu cuối cùng |
| HTTP 5xx / network / timeout | Thông báo không thể cập nhật; đánh dấu bảng điện stale, không xóa snapshot cuối |
| `accepted=false` hoặc `cancelled=false` | Hiển thị `reason` nghiệp vụ, không phát toast thành công |

## Compatibility

Contract là additive đối với frontend mới và không yêu cầu migration/backward change ở Exchange. Contract test phải bảo đảm tên field, enum và nullable fields không bị đổi ngoài ý muốn.
