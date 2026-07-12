# Contract: Widget Embed (public contract với website tenant)

**Feature**: `000008-agent-platform-mvp`

Đây là contract công khai duy nhất tenant nhúng vào website của họ — sau MVP PHẢI giữ ổn định (backward compatible), vì đổi snippet buộc mọi tenant sửa website.

## Snippet nhúng (trả về từ publish — FR-012)

```html
<script
  src="https://{PLATFORM_HOST}/widget/flex-agent-widget.js"
  data-widget-key="{WIDGET_KEY}"
  defer></script>
```

Thuộc tính tùy chọn (có default, không bắt buộc):

| Attribute | Default | Mô tả |
|-----------|---------|-------|
| `data-position` | `bottom-right` | `bottom-right` \| `bottom-left` |
| `data-title` | tên agent | Tiêu đề khung chat |

## Hành vi widget

1. Script tự tạo nút chat nổi + khung chat (Shadow DOM để không xung đột CSS website tenant).
2. Khi mở khung lần đầu: `POST /api/public/chat/sessions {widgetKey}` → nhận `sessionToken` + `greeting`; hiển thị lời chào.
3. Chat streaming theo [chat-streaming.md](./chat-streaming.md); hiển thị câu trả lời hiển thị dần (AC-012).
4. Session giữ trong `sessionStorage` — reload trang trong TTL vẫn tiếp tục hội thoại.
5. Lỗi:
   - 410 (agent gỡ phát hành/key revoked) → hiển thị "Trợ lý tạm ngưng hoạt động." và ẩn input.
   - 429 (rate limit) → "Bạn thao tác quá nhanh, vui lòng thử lại sau."
   - `MessageFailed` → "Trợ lý tạm thời không phản hồi được, vui lòng thử lại." — hội thoại không mất (spec §5).

## Ràng buộc bảo mật

- Widget key là định danh công khai (in trong HTML) — KHÔNG phải secret; mọi quyền chỉ giới hạn: tạo session chat với đúng agent đã publish. Không API nào khác nhận widget key.
- SessionToken ngắn hạn, scope 1 agent, không claim role/tenant admin.
- Rate limit theo widget key + IP tại `/api/public/*` (SEC-004).
- Widget không thu thập gì ngoài nội dung tin nhắn người dùng gõ.

## Versioning

- `flex-agent-widget.js` phục vụ kèm header cache + comment version (theo image tag của platform).
- Thay đổi breaking (đổi attribute, đổi endpoint) yêu cầu path mới (`/widget/v2/...`) — không sửa hành vi path cũ.

## Kiểm thử

- Nhúng vào trang HTML tĩnh bất kỳ (file local) → chat được end-to-end.
- Trang có CSS framework (bootstrap) → widget không vỡ style (Shadow DOM).
- Key revoked → thông báo tạm ngưng, không lỗi JS console.
