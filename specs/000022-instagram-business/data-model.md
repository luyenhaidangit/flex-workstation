# Data Model: Phát hành AI Agent trên Instagram Business

**Feature**: `000022-instagram-business`  
**Ngày**: 2026-07-29  
**Phục vụ**: `plan.md` — thiết kế entity và quan hệ dữ liệu

---

## Tổng quan quan hệ

```
Agent (existing)
  └──< MetaAccountConnection (new)   [1 agent ←→ nhiều tài khoản Meta]
         └──< InstagramPageConnection (new)  [1 account ←→ nhiều pages]
```

- `MetaAccountConnection`: 1 tài khoản Meta (Facebook user) đã OAuth với 1 agent.
- `InstagramPageConnection`: 1 Facebook Page (liên kết IG Business) đã được kích hoạt kết nối với agent.
- UNIQUE constraint trên `facebook_page_id` toàn bảng → enforce BR-005 (1 page = 1 agent).

---

## MetaAccountConnection

Đại diện cho phiên OAuth thành công của 1 tài khoản Meta (người dùng Facebook Business) với 1 AI Agent.

| Column | Type | Nullable | Ghi chú |
|--------|------|----------|---------|
| `id` | UUID | NOT NULL | PK |
| `agent_id` | UUID | NOT NULL | FK → Agent.id |
| `meta_user_id` | VARCHAR(64) | NOT NULL | Facebook User ID của tài khoản Meta |
| `meta_user_name` | VARCHAR(255) | NOT NULL | Tên hiển thị (Minh Tâm, Yến Nhi...) |
| `meta_user_avatar_url` | TEXT | NULL | Avatar URL hiển thị trong UI |
| `encrypted_access_token` | TEXT | NOT NULL | Long-lived user access token, mã hoá AES (SEC-003) |
| `token_type` | VARCHAR(32) | NOT NULL | Mặc định "long_lived_user_token" |
| `created_at` | TIMESTAMPTZ | NOT NULL | |
| `updated_at` | TIMESTAMPTZ | NOT NULL | |

**Indexes**: `(agent_id)`, `(meta_user_id, agent_id)` UNIQUE.

**Quan hệ**:
- 1 MetaAccountConnection → nhiều InstagramPageConnection.
- Nếu xoá MetaAccountConnection → cascade xoá InstagramPageConnection liên quan.

**Vòng đời**:
- Tạo khi user hoàn thành OAuth flow và confirm ít nhất 1 page.
- Xoá khi user ngắt kết nối tất cả pages thuộc account này (hoặc revoke toàn bộ quyền).

---

## InstagramPageConnection

Đại diện cho 1 Facebook Page (có liên kết Instagram Business Account) đã được kích hoạt kết nối với agent. Đây là unit chính của channel Instagram.

| Column | Type | Nullable | Ghi chú |
|--------|------|----------|---------|
| `id` | UUID | NOT NULL | PK |
| `meta_account_connection_id` | UUID | NOT NULL | FK → MetaAccountConnection.id |
| `agent_id` | UUID | NOT NULL | Denormalized FK → Agent.id (cho query nhanh) |
| `facebook_page_id` | VARCHAR(64) | NOT NULL | Facebook Page ID — UNIQUE toàn bảng (BR-005) |
| `facebook_page_name` | VARCHAR(255) | NOT NULL | Tên page (The Coffee House...) |
| `facebook_page_avatar_url` | TEXT | NULL | Avatar page hiển thị trong UI |
| `instagram_business_account_id` | VARCHAR(64) | NOT NULL | IG Business Account ID — dùng cho webhook + Send API |
| `instagram_account_type` | VARCHAR(32) | NOT NULL | "BUSINESS" hoặc "CREATOR" |
| `encrypted_page_access_token` | TEXT | NOT NULL | Page access token, mã hoá AES (SEC-003) |
| `status` | VARCHAR(32) | NOT NULL | "active" \| "disconnected" \| "error" |
| `active_hours_config` | JSONB | NULL | `{mode: "always"|"custom", start: "HH:MM", end: "HH:MM"}` |
| `last_customer_dm_at` | TIMESTAMPTZ | NULL | Thời điểm cuối cùng nhận DM từ khách — dùng cho 24h window check (BR-006) |
| `connected_at` | TIMESTAMPTZ | NULL | Lúc kích hoạt kết nối lần gần nhất |
| `disconnected_at` | TIMESTAMPTZ | NULL | Lúc ngắt kết nối |
| `created_at` | TIMESTAMPTZ | NOT NULL | |
| `updated_at` | TIMESTAMPTZ | NOT NULL | |

**Indexes**:
- `UNIQUE (facebook_page_id)` — enforce BR-005.
- `INDEX (agent_id)` — query kết nối theo agent.
- `INDEX (instagram_business_account_id)` — lookup khi xử lý webhook.

**Quan hệ**: Nhiều InstagramPageConnection → 1 MetaAccountConnection.

**Vòng đời trạng thái**:

```
[Chưa tồn tại] → active      : User confirm chọn page trong popup (FR-008a/b)
active          → disconnected : User ngắt kết nối (FR-007)
active          → error        : Token bị thu hồi / page unlinked (webhook deauthorize)
error           → active       : User kết nối lại (OAuth lại)
disconnected    → active       : User kết nối lại
```

---

## Không thay đổi

- Bảng `Agent` — không thay đổi.
- Bảng `ChannelMessage` / `ConversationSession` — tái sử dụng để lưu DM; không thay schema.
- Registry `ChannelType` — chỉ thêm enum value `InstagramBusiness`; không thay đổi các channel hiện có.

---

## Ràng buộc nghiệp vụ trong data model

| Ràng buộc | Loại | Spec ref |
|-----------|------|---------|
| `instagram_page_connections.facebook_page_id` phải UNIQUE toàn bảng | DB UNIQUE constraint | BR-005 |
| `instagram_account_type` chỉ nhận "BUSINESS" hoặc "CREATOR" | CHECK constraint hoặc application enum | BR-001 |
| `encrypted_page_access_token` không được NULL khi `status = "active"` | Application validation | SEC-003 |
| `last_customer_dm_at` được cập nhật mỗi khi nhận DM từ khách | Application logic | BR-006 |

---

## Migration script (outline)

```sql
-- Migration: AddInstagramChannelTables
-- Direction: Up

CREATE TABLE meta_account_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
  meta_user_id VARCHAR(64) NOT NULL,
  meta_user_name VARCHAR(255) NOT NULL,
  meta_user_avatar_url TEXT,
  encrypted_access_token TEXT NOT NULL,
  token_type VARCHAR(32) NOT NULL DEFAULT 'long_lived_user_token',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_meta_account_connections_user_agent
  ON meta_account_connections(meta_user_id, agent_id);

CREATE INDEX idx_meta_account_connections_agent
  ON meta_account_connections(agent_id);

CREATE TABLE instagram_page_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meta_account_connection_id UUID NOT NULL
    REFERENCES meta_account_connections(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
  facebook_page_id VARCHAR(64) NOT NULL,
  facebook_page_name VARCHAR(255) NOT NULL,
  facebook_page_avatar_url TEXT,
  instagram_business_account_id VARCHAR(64) NOT NULL,
  instagram_account_type VARCHAR(32) NOT NULL,
  encrypted_page_access_token TEXT NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'disconnected', 'error')),
  active_hours_config JSONB,
  last_customer_dm_at TIMESTAMPTZ,
  connected_at TIMESTAMPTZ,
  disconnected_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_instagram_page_connections_page
  ON instagram_page_connections(facebook_page_id);

CREATE INDEX idx_instagram_page_connections_agent
  ON instagram_page_connections(agent_id);

CREATE INDEX idx_instagram_page_connections_ig_account
  ON instagram_page_connections(instagram_business_account_id);

-- Direction: Down (nếu cần rollback)
-- DROP TABLE instagram_page_connections;
-- DROP TABLE meta_account_connections;
```
