# Ideal: 000001

## Source

- Input: `flex-workstation/requirements/000001/idea.md`
- Output: `flex-workstation/requirements/000001/ideal.md`

## Problem Statement

Người dùng đang mở web app không biết ngay khi có phiên đăng nhập mới vào tài khoản của họ. Không có tính năng thông báo realtime đăng nhập nào hiện tại, khiến người dùng không phát hiện được hoạt động đáng ngờ trong khi đang sử dụng app. Backend là .NET; thông báo chỉ cần hoạt động khi app đang mở (không cần background push). Lịch sử thông báo được lưu vào DB.

## Recommended Direction

**SSE (Server-Sent Events) + Toast + DB history + BroadcastChannel tab sync**

### Luồng thực thi

```
Login thành công
    → LoginSucceededEvent
    → LoginNotificationHandler
        → Lưu vào DB (notifications table)
        → Notify qua ILoginNotificationService (in-process Channel<T>)
            → SSE endpoint của user đang mở app nhận event
            → Gửi xuống 1 tab "leader"
            → BroadcastChannel phân phát sang các tab còn lại
            → Tất cả tab hiển thị toast
```

---

### Câu 2 — Xử lý nhiều tab

**Hướng khuyến nghị: Tab Leader Election + BroadcastChannel API**

Mỗi user chỉ giữ **1 SSE connection** dù mở bao nhiêu tab:

1. Tab đầu tiên mở → ghi `sse_leader = <tabId>` vào `localStorage` → mở SSE connection.
2. Tab mới mở → đọc `localStorage`, thấy đã có leader → **không** mở SSE, chỉ lắng nghe `BroadcastChannel("login-notify")`.
3. Khi tab leader đóng → `storage` event kích hoạt trên các tab còn lại → tab cũ nhất (hoặc random) nhận vai leader mới → mở SSE connection.
4. Khi SSE nhận event → leader broadcast qua `BroadcastChannel` → **tất cả tab** hiển thị toast đồng loạt.

**Lý do chọn cách này thay vì "mỗi tab 1 connection":**
- Server chỉ giữ 1 connection per user → tiết kiệm tài nguyên khi có nhiều tab.
- Toast không bị nhân bản (không cần dedup phức tạp).
- BroadcastChannel là API trình duyệt native, không cần thư viện.

**Điểm yếu cần biết:** Nếu tab leader bị treo (not responding), election có thể chậm vài giây. Chấp nhận được cho use case này.

---

### Câu 5 — Auth service architecture

**Phân tích:**

| Trường hợp | Cơ chế truyền event | Độ phức tạp |
|---|---|---|
| Monolith / Same process | `System.Threading.Channels` (in-process) | Thấp |
| Separate processes / Microservice | Redis Pub/Sub hoặc message broker | Cao |

**Hướng khuyến nghị: In-process `Channel<T>` với interface abstraction**

Dùng `System.Threading.Channels` — có sẵn trong .NET, không cần package ngoài:

```
ILoginNotificationService
├── Subscribe(userId) → IAsyncEnumerable<LoginEvent>   ← SSE endpoint dùng
└── Notify(userId, event)                              ← LoginHandler dùng

Impl: InProcessLoginNotificationService
├── _channels: ConcurrentDictionary<userId, Channel<LoginEvent>>
├── Subscribe: tạo / lấy channel, yield return từ reader
└── Notify: ghi vào channel tương ứng nếu tồn tại
```

**Vì sao thiết kế theo interface:**
- MVP chạy in-process — đơn giản, không dependency ngoài.
- Nếu sau này scale out (nhiều instance server, microservice), chỉ cần swap impl sang `RedisLoginNotificationService` mà không đụng SSE endpoint hay login handler.

**Lưu ý quan trọng cho SSE + in-process Channel:**
- Khi server có **nhiều instance** (load balancer), user A kết nối instance 1 nhưng login event được xử lý ở instance 2 → channel trên instance 1 không nhận được. Nếu hiện tại chạy **single instance** thì không có vấn đề. Nếu multi-instance thì cần Redis Pub/Sub ngay từ đầu.

---

## Key Assumptions to Validate

- [ ] Schema DB cho notifications table đã được thống nhất (xem MVP Scope).
- [ ] Browser hỗ trợ `BroadcastChannel` API — tất cả evergreen browser đều hỗ trợ; IE không (không quan trọng nếu không cần IE).

## Resolved Decisions

- **Single instance** → dùng `System.Threading.Channels` in-process. Không cần Redis Pub/Sub.

## MVP Scope

### In Scope

- **SSE endpoint** `GET /notifications/stream` — xác thực bằng JWT/cookie, giữ kết nối, stream event qua `ILoginNotificationService`.
- **LoginSucceededEvent handler** — sau login thành công: lưu DB + notify qua service.
- **DB notifications table** — lưu `(id, userId, type, payload, createdAt, isRead)`.
- **API lấy lịch sử** `GET /notifications` — phân trang, trả về danh sách thông báo của user.
- **API đánh dấu đã đọc** `PATCH /notifications/{id}/read` hoặc `PATCH /notifications/read-all`.
- **Frontend SSE client** — Tab leader election + BroadcastChannel, tự reconnect.
- **Toast UI** — xuất hiện khi nhận event, tự ẩn sau vài giây.
- **Notification history UI** — danh sách thông báo (có thể là dropdown hoặc trang riêng), badge đếm unread.
- **`ILoginNotificationService` interface** — in-process `Channel<T>` impl cho MVP.
- Ngắt kết nối SSE khi user logout.

### Out of Scope

- Push notification khi app đóng hoặc background (FCM/APNs).
- Admin dashboard giám sát toàn hệ thống.
- Event streaming sang service khác (Kafka, RabbitMQ).
- Phân biệt thiết bị lạ / IP mới.
- Mobile app notification.
- Notification cho event khác ngoài login.
- Multi-instance / Redis Pub/Sub (nếu hiện tại single instance).

## Not Doing (and Why)

- **SignalR/WebSocket**: Overkill cho one-way push; thêm dependency không cần thiết.
- **Polling**: Không phải realtime; tốn tài nguyên; UX kém hơn.
- **Background push (FCM/APNs)**: Ngoài scope đã xác định.
- **Phân biệt thiết bị lạ**: Tăng độ phức tạp (device fingerprint), không cần cho MVP.
- **"Mỗi tab 1 SSE connection"**: Tốn tài nguyên server, toast bị nhân bản mà không có dedup đơn giản.

## Open Questions

- **Notification history UI ở đâu?** Dropdown từ header icon (như Gmail) hay trang `/notifications` riêng? Ảnh hưởng đến frontend scope.
- **Retention policy cho notifications DB**: Lưu bao lâu? Có tự xóa record cũ không?
