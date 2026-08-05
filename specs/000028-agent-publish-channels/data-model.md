# Data Model: Tab Thiết lập thông tin chung & Phát hành đa kênh cho Agent

**Feature**: `specs/000028-agent-publish-channels` | **Ngày**: 2026-08-05

---

## Entity: `AgentPublishLocation` (bảng `agent_publish_locations`)

Đại diện cho cấu hình bật/tắt một kênh phát hành cụ thể của một agent. Xem quyết định mô hình dữ liệu ở [research.md](research.md) (TQ-002).

| Cột | Kiểu | Ràng buộc | Ghi chú |
|-----|------|-----------|---------|
| `id` | UUID | PK, `DEFAULT gen_random_uuid()` | |
| `agent_id` | UUID | NOT NULL, FK → `agents(id)` | Kênh luôn gắn với 1 agent (BR-001) |
| `location_code` | VARCHAR(50) | NOT NULL | Mã kênh, ví dụ `website`. Danh sách mã hợp lệ được validate ở tầng ứng dụng (xem dưới), không dùng CHECK constraint cứng để không phải sửa DB khi thêm kênh sau này |
| `location_name` | VARCHAR(255) | NOT NULL | Tên hiển thị snapshot tại thời điểm lưu (ví dụ "Tạo trang web") |
| `is_enabled` | BOOLEAN | NOT NULL, `DEFAULT false` | Trạng thái bật/tắt đã lưu (FR-005) |
| `configuration` | JSONB | NULL | Dự phòng cấu hình riêng từng kênh cho các feature sau (domain whitelist Website, page id Facebook, ...); MVP luôn `NULL` — không có UI nhập liệu (§15 Ngoài phạm vi) |
| `created_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, `DEFAULT now()` | Cập nhật mỗi lần upsert |

**Ràng buộc**:
- `UNIQUE(agent_id, location_code)` — mỗi agent chỉ có tối đa 1 row cho mỗi loại kênh (tránh trạng thái mơ hồ khi có 2 row cùng kênh).
- `INDEX(agent_id)` — phục vụ truy vấn danh sách kênh của 1 agent khi mở tab Phát hành hoặc trả về trong `GET /api/v1/agents/{id}`.

**Vòng đời dữ liệu (MVP)**:
- Row chỉ được tạo/cập nhật khi `location_code = 'website'` được lưu qua tab "Phát hành" (US-002/US-003). Hệ thống ứng dụng PHẢI từ chối (400) mọi `location_code` khác trong request ghi (FR-009) — xem [contracts/](contracts/).
- Agent chưa từng lưu kênh nào → không có row nào trong bảng cho agent đó → Frontend hiển thị Website mặc định tắt (AC-006), khớp "Không có dữ liệu" ở spec §6.
- Bật rồi tắt lại nhiều lần trước khi bấm "Lưu" chỉ tạo/cập nhật đúng 1 row cuối cùng (upsert theo `UNIQUE(agent_id, location_code)`), không tạo row trùng (AC "Người dùng thao tác lặp lại").

**Danh sách `location_code` được ứng dụng công nhận** (tham chiếu, không phải CHECK constraint DB — xem TQ-004 ở research.md):

| `location_code` | Tên hiển thị | Ghi được ở MVP này? |
|---|---|---|
| `website` | Tạo trang web | Có |
| `facebook_fanpage` | Fanpage Facebook | Không — chỉ hiển thị tĩnh Frontend, chưa khả dụng |
| `zalo_oa` | Zalo OA (Doanh nghiệp) | Không — chỉ hiển thị tĩnh Frontend, chưa khả dụng |
| `chatbot` | Chatbot | Không — chỉ hiển thị tĩnh Frontend, chưa khả dụng |
| `zalo_personal` | Zalo Cá nhân | Không — chỉ hiển thị tĩnh Frontend, chưa khả dụng |

---

## Quan hệ với `Agent` (bảng `agents`, đã có từ `specs/000026-agent-catalog`)

- 1 `Agent` → N `AgentPublishLocation` (tối đa 1 row cho mỗi `location_code` nhờ UNIQUE constraint).
- Không đổi schema hay dữ liệu hiện có của bảng `agents` (đúng phạm vi FR-002/BR-002 — không đụng logic/nghiệp vụ đã có).
- Xóa `Agent` (nếu có trong tương lai — hiện `specs/000026-agent-catalog` đã hỗ trợ xóa agent) nên cascade xóa `agent_publish_locations` tương ứng để tránh row mồ côi — `ON DELETE CASCADE` trên FK `agent_id`.

---

## Migration

Xem chi tiết SQL tại `flex-database/agentdb/migrations/V1.2__create_table_agent_publish_locations.sql` (mô tả trong [plan.md](plan.md) §Dữ liệu & Migration).
