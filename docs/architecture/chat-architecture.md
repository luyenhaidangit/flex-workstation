# Chat Architecture

## 1. Tổng quan

Base chat tối thiểu chỉ cần 2 bảng cốt lõi:

```
conversation  1 ──── N  message
```

- **`conversation`** — phiên hội thoại.
- **`message`** — mọi message trong phiên, bất kể do user, AI, human agent, system hay tool tạo ra.

Khi database có nhiều module, dùng PostgreSQL schema riêng:

```
chat.conversation
chat.message
```

---

## 2. Schema

### 2.1 `chat.conversation`

```sql
CREATE SCHEMA IF NOT EXISTS chat;

CREATE TABLE chat.conversation
(
    id                  UUID            NOT NULL,
    tenant_id           UUID            NOT NULL,
    created_by          UUID            NOT NULL,

    title               VARCHAR(500),
    status              VARCHAR(30)     NOT NULL DEFAULT 'active',

    last_sequence_no    BIGINT          NOT NULL DEFAULT 0,
    last_message_id     UUID,
    last_message_at     TIMESTAMPTZ,

    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_conversation
        PRIMARY KEY (id),

    CONSTRAINT uq_conversation_tenant
        UNIQUE (tenant_id, id)
);
```

`last_sequence_no` trên `conversation` là synchronization point để cấp thứ tự message mà không cần `SELECT MAX(sequence_no)` mỗi lần gửi.

### 2.2 `chat.message`

```sql
CREATE TABLE chat.message
(
    id                  UUID            NOT NULL,
    tenant_id           UUID            NOT NULL,
    conversation_id     UUID            NOT NULL,

    sequence_no         BIGINT          NOT NULL,

    role                VARCHAR(20)     NOT NULL,
    actor_type          VARCHAR(30)     NOT NULL,
    actor_id            UUID,

    content_type        VARCHAR(30)     NOT NULL DEFAULT 'text',
    content             TEXT,

    status              VARCHAR(30)     NOT NULL DEFAULT 'completed',

    parent_message_id   UUID,

    metadata            JSONB           NOT NULL DEFAULT '{}'::jsonb,

    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_message
        PRIMARY KEY (id),

    CONSTRAINT fk_message_conversation
        FOREIGN KEY (tenant_id, conversation_id)
        REFERENCES chat.conversation(tenant_id, id),

    CONSTRAINT uq_message_sequence
        UNIQUE (tenant_id, conversation_id, sequence_no),

    CONSTRAINT ck_message_role
        CHECK (role IN ('system', 'user', 'assistant', 'tool'))
);
```

FK composite `(tenant_id, conversation_id)` thay vì chỉ `conversation_id` để database enforce: message của tenant A không thể trỏ nhầm conversation của tenant B.

---

## 3. `role` vs `actor_type`

Hai trường này khác nhau về ngữ nghĩa và không được dùng thay thế cho nhau.

| Trường | Mục đích | Giá trị |
|--------|----------|---------|
| `role` | Nói cho LLM biết message đóng vai trò gì trong context | `system`, `user`, `assistant`, `tool` |
| `actor_type` | Nói ai thực sự tạo ra message | `end_user`, `ai_agent`, `human_agent`, `system`, `tool`, `automation` |

Ví dụ history sạch:

```
sequence | role       | actor_type
──────────────────────────────────
1        | system     | system
2        | user       | end_user
3        | assistant  | ai_agent
4        | user       | end_user
5        | assistant  | ai_agent
6        | assistant  | human_agent
```

Human agent trả lời thay AI:

```
role       = assistant
actor_type = human_agent
actor_id   = <userId>
```

---

## 4. `metadata JSONB`

Không tạo column riêng cho từng provider/channel-specific field trên bảng `message`. Core business fields để column; phần còn lại để `metadata`:

```json
{
  "ai": {
    "provider": "ollama",
    "model": "qwen3"
  },
  "channel": {
    "type": "facebook",
    "external_message_id": "..."
  }
}
```

Nguyên tắc: `Relational core + JSONB extension`.

---

## 5. Index

### Hot query: load message trong conversation

```sql
CREATE INDEX ix_message_conversation_sequence
ON chat.message
(
    tenant_id,
    conversation_id,
    sequence_no DESC
);
```

Query tương ứng:

```sql
SELECT *
FROM chat.message
WHERE tenant_id = @tenantId
  AND conversation_id = @conversationId
ORDER BY sequence_no DESC
LIMIT 50;
```

### Conversation list theo hoạt động gần nhất

```sql
CREATE INDEX ix_conversation_user_updated
ON chat.conversation
(
    tenant_id,
    created_by,
    updated_at DESC
);
```

---

## 6. Thứ tự message: `sequence_no`, không phải `created_at`

Không dùng `ORDER BY created_at` làm thứ tự chính vì:
- Distributed system hoặc retry có thể làm message đến lệch thứ tự.
- Timestamp resolution không đảm bảo thứ tự khi hai message có cùng millisecond.

| Trường | Trả lời câu hỏi |
|--------|----------------|
| `sequence_no` | Message đứng thứ mấy trong conversation? |
| `created_at` | Message xảy ra lúc nào? |

---

## 7. Flow tạo message mới (atomic)

Không dùng `SELECT MAX(sequence_no) + 1` vì hai request concurrent có thể cùng lấy cùng một MAX rồi cả hai insert cùng sequence.

Dùng `conversation` làm synchronization point:

```
BEGIN

  Lock conversation row (SELECT ... FOR UPDATE)

  next_sequence = last_sequence_no + 1

  INSERT chat.message (sequence_no = next_sequence, ...)

  UPDATE chat.conversation
    SET last_sequence_no = next_sequence,
        last_message_id  = @messageId,
        last_message_at  = NOW(),
        updated_at       = NOW()

COMMIT
```

SQL:

```sql
BEGIN;

SELECT last_sequence_no
FROM chat.conversation
WHERE tenant_id = @tenantId
  AND id = @conversationId
FOR UPDATE;

-- Application: next_sequence = last_sequence_no + 1

INSERT INTO chat.message
(
    id, tenant_id, conversation_id,
    sequence_no, role, actor_type, actor_id,
    content, status
)
VALUES
(
    @messageId, @tenantId, @conversationId,
    @nextSequence, @role, @actorType, @actorId,
    @content, 'completed'
);

UPDATE chat.conversation
SET
    last_sequence_no = @nextSequence,
    last_message_id  = @messageId,
    last_message_at  = NOW(),
    updated_at       = NOW()
WHERE tenant_id = @tenantId
  AND id = @conversationId;

COMMIT;
```

---

## 8. Luồng User gửi message

```
User
 │ "Hello"
 ▼
ChatService
 │
 ▼
BEGIN TRANSACTION
 ├── Lock conversation
 ├── sequence = last_sequence_no + 1
 ├── INSERT chat.message (role=user, actor_type=end_user)
 └── UPDATE chat.conversation
 │
COMMIT
 │
 ▼
MessageCreated event
 ├── Realtime (SignalR)
 ├── AI pipeline
 ├── Analytics
 └── Search index
```

---

## 9. AI trả lời dùng cùng bảng `message`

Không tạo bảng `ai_message` riêng. AI response insert vào `chat.message` với:

```
role       = assistant
actor_type = ai_agent
actor_id   = <agentId>
```

Luồng AI:

```
User Message
      ↓
ChatContextBuilder
  ├── System prompt từ agent config
  ├── Messages từ DB
  └── RAG context
      ↓
IChatClient → Ollama / Qwen / ...
      ↓
Assistant Response
      ↓
ChatService → INSERT chat.message
```

---

## 10. System Prompt

Không bắt buộc insert system prompt thành message trong DB. `ChatContextBuilder` có thể compose:

```
System prompt từ agent config
+ Messages từ DB
+ RAG context
→ gửi IChatClient
```

Chỉ lưu `role=system` vào `message` nếu system event đó cần audit trail trong conversation.

---

## 11. `status` message

| Giá trị | Ý nghĩa |
|---------|---------|
| `pending` | Đang chờ xử lý |
| `generating` | AI đang stream response |
| `completed` | Hoàn thành |
| `failed` | Thất bại |
| `cancelled` | Đã huỷ |

V1 đơn giản: chỉ insert assistant message sau khi generation hoàn tất, chưa cần `generating`.

---

## 12. `last_message_id` không phải source of truth

Source of truth là `chat.message`. Các trường trên `conversation`:

```
last_message_id
last_message_at
last_sequence_no
```

là **denormalized state** phục vụ performance cho conversation list — tránh query message table mỗi lần render preview.

---

## 13. Multi-tenant

### Shared DB (khuyến nghị ban đầu)

```
PostgreSQL
└── chat
     ├── conversation  (có tenant_id trên từng row)
     └── message       (có tenant_id trên từng row)
```

FK composite `(tenant_id, conversation_id)` enforce cross-tenant isolation ở tầng database. Có thể bổ sung Row Level Security nếu cần.

### Database-per-tenant

Nếu dùng database-per-tenant (MISA-style), bỏ `tenant_id` khỏi các bảng vì dữ liệu đã physical isolate.

Không vừa database-per-tenant vừa giữ `tenant_id` trên mọi bảng nếu không có lý do.

---

## 14. Cấu trúc đầy đủ V1

```
PostgreSQL
└── chat
     │
     ├── conversation
     │    ├── id
     │    ├── tenant_id
     │    ├── created_by
     │    ├── title
     │    ├── status
     │    ├── last_sequence_no
     │    ├── last_message_id
     │    ├── last_message_at
     │    ├── created_at
     │    └── updated_at
     │
     └── message
          ├── id
          ├── tenant_id
          ├── conversation_id
          ├── sequence_no
          ├── role
          ├── actor_type
          ├── actor_id
          ├── content_type
          ├── content
          ├── status
          ├── parent_message_id
          ├── metadata (JSONB)
          ├── created_at
          └── updated_at
```

Quan hệ:

```
conversation  1 ──── N  message

UNIQUE:   (tenant_id, conversation_id, sequence_no)
HOT INDEX: (tenant_id, conversation_id, sequence_no DESC)
```

---

## 15. Mở rộng sau V1

Chỉ thêm khi nghiệp vụ thực sự xuất hiện:

| Bảng | Khi nào thêm |
|------|-------------|
| `message_generation` | Cần lưu model, tokens, latency, finish reason |
| `tool_execution` | Có tool calling, cần audit từng tool call |
| `feedback` | Có thumbs up/down hoặc rating từ user |
| `citation` | RAG cần trả về nguồn tài liệu |
| `attachment` | Hỗ trợ file/image trong message |
| `outbox_event` | Cần transactional outbox cho event publishing |
