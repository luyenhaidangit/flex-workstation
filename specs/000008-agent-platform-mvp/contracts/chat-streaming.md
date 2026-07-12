# Contract: Chat Streaming (SignalR)

**Feature**: `000008-agent-platform-mvp` | Hub: `/hubs/chat`

Một hub phục vụ hai chế độ (DEC-006):
- **Test chat (US-004)**: kết nối bằng JWT admin (role ≥ editor), `mode=test` — chạy trên **draft** + tri thức ready.
- **Widget chat (US-005)**: kết nối bằng `sessionToken` (đổi từ widget key qua REST) truyền qua query `access_token`, `mode=public` — chạy trên **snapshot active_version** (FR-014).

## Client → Server

| Method | Tham số | Ghi chú |
|--------|---------|---------|
| `StartConversation` | `{agentId, mode}` | mode=test yêu cầu JWT + agent thuộc tenant claim; mode=public lấy agent từ sessionToken. Trả `conversationId` |
| `SendMessage` | `{conversationId, content}` | content ≤ 4000 ký tự; server validate conversation thuộc đúng principal |

## Server → Client

| Event | Payload | Ghi chú |
|-------|---------|---------|
| `MessageChunk` | `{conversationId, messageId, delta}` | Từng đoạn token streaming (NFR-001) |
| `MessageCompleted` | `{conversationId, messageId, tokens}` | Kết thúc một câu trả lời; usage chỉ tính khi completed (spec §5 Timeout) |
| `MessageFailed` | `{conversationId, code, message}` | `model_unavailable`, `timeout`, `rate_limited` — message lịch sự tiếng Việt (spec §5 Lỗi hệ thống) |
| `ConversationClosed` | `{conversationId, reason}` | `agent_unpublished`, `session_expired` |

## Trình tự chuẩn

```text
[widget]  POST /api/public/chat/sessions {widgetKey}       → {sessionToken, greeting}
[widget]  connect /hubs/chat?access_token={sessionToken}
[client]  StartConversation {agentId, mode}                → {conversationId}
[client]  SendMessage {conversationId, "..."}
[server]  MessageChunk × N → MessageCompleted
```

## Quy tắc bắt buộc

- Server xác định tenant từ principal (JWT claim hoặc sessionToken) — KHÔNG từ tham số client (BR-004).
- RAG trong mọi mode: Qdrant filter `tenant_id` + `agent_id` bắt buộc (FR-020); mode=public giới hạn thêm theo `source_ids_json` của snapshot.
- Prompt build 3 phần tách biệt: system (persona+instructions) / retrieved context (bọc delimiter, đánh dấu là dữ liệu) / user message (SEC-003).
- Hội thoại mode=test ghi `is_test=true`, không tính usage (FR-010).
- Timeout model: 120s; quá hạn → `MessageFailed{timeout}`, không ghi message agent dở dang vào `messages`.
- Reconnect: SignalR tự reconnect; `conversationId` dùng lại được trong TTL session (30 phút không hoạt động).

## Kiểm thử contract

- Trình tự event đúng thứ tự chunk→completed; failed không kèm completed.
- Token tenant A + agentId tenant B → hub từ chối StartConversation.
- SessionToken hết hạn → `ConversationClosed{session_expired}`.
