# API Contracts hiện có — không đổi (FR-004, FR-007)

**Có thay đổi contract không**: Không. Danh sách dưới đây liệt kê các endpoint hiện có để làm baseline kiểm thử tương thích (regression) sau khi tái cấu trúc — route, verb, request/response giữ nguyên 100%.

## `Flex.Agent` — `InstagramChannelController` (`api/channels/instagram`)

| Verb | Route | Mục đích |
|------|-------|----------|
| POST | `api/channels/instagram/connect` | Bắt đầu luồng kết nối Meta/Instagram (OAuth) |
| GET | `api/channels/instagram/callback` | OAuth callback từ Meta |
| GET | `api/channels/instagram/connect/result` | Trả kết quả kết nối cho frontend |
| POST | `api/channels/instagram/pages/confirm` | Xác nhận Facebook Page/Instagram Business Account được chọn |
| GET | `api/channels/instagram/connections` | Liệt kê kết nối hiện có |
| DELETE | `api/channels/instagram/connections/{connectionId:guid}` | Ngắt kết nối |

## `Flex.Agent` — `InstagramWebhookController` (`api/webhooks/instagram`)

| Verb | Route | Mục đích |
|------|-------|----------|
| GET | `api/webhooks/instagram` | Xác thực webhook với Meta (hub.challenge) |
| POST | `api/webhooks/instagram` | Nhận sự kiện webhook (tin nhắn, comment...) |

## Backward compatibility

Không có breaking change. Không có consumer nào (Meta Platform, frontend nội bộ) cần cập nhật. Cách kiểm tra: gọi lại từng endpoint trên sau khi tái cấu trúc, đối chiếu response/status code với baseline trước khi refactor (xem [quickstart.md](../quickstart.md)).
