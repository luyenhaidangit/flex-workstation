# Data model: Demo realtime cho Agent Service

## Kết luận lưu trữ

Feature không tạo hoặc thay đổi database/schema/migration. Các object dưới đây là DTO/event trong memory và structured log, không phải entity persistence.

## DemoChatMessage

| Trường | Ý nghĩa | Quy tắc |
|---|---|---|
| `message` | Nội dung người dùng gửi | Bắt buộc; trim; không rỗng |
| `occurredAt` | Thời điểm Agent Service nhận | Do BE gán khi nhận |
| `connectionId` | Phiên SignalR nhận sự kiện | Chỉ dùng cho log/debug, không expose secret |

## DemoNotification

| Trường | Ý nghĩa | Quy tắc |
|---|---|---|
| `type` | Loại thông báo | Giá trị cố định cho demo notification |
| `message` | Nội dung hiển thị cho người kiểm thử | Bắt buộc; do endpoint test cung cấp hoặc dùng default |
| `occurredAt` | Thời điểm phát | Do BE gán |

## Quan hệ và trạng thái

- Một `AgentRealtimeHub` connection có thể gửi nhiều `DemoChatMessage` trong một phiên.
- Một lần gọi endpoint tạo một `DemoNotification` và broadcast tới các connection đang hoạt động.
- Không có trạng thái bền vững, quan hệ database, backfill hay cleanup.
