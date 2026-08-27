# Mô hình dữ liệu: Kết nối kênh Instagram và Facebook qua Meta

## Nguyên tắc

- Dữ liệu completed connection thuộc PostgreSQL `agentdb`; migration thuộc `flex-database/agentdb`.
- Session kết nối là dữ liệu tạm, TTL 10 phút, không phải business history; không persist vào database.
- Credential không thuộc public DTO. Access token nếu cần cho runtime phải nằm trong trường encrypted internal hiện hữu, được tham chiếu qua connection record và không được log.
- Không drop/rename bảng Instagram hiện hữu trong MVP.

## Thực thể

### `Agent`

Thực thể hiện hữu nhận connection. `agent_id` là scope bắt buộc của mọi query/command; permission được kiểm tra từ principal và agent ownership, không tin giá trị client gửi độc lập.

### `IntegrationConnectionSession` — temporary

Lưu trong `IIntegrationSessionStore`/`IMemoryCache`:

| Trường | Kiểu logic | Bắt buộc | Ý nghĩa |
|---|---|---:|---|
| `sessionId` | opaque UUID/string | Có | ID frontend dùng để lấy discovery; không phải credential. |
| `stateHash` | internal key | Có | CSRF/replay binding; raw state không trả vào log. |
| `agentId` | UUID | Có | Agent khởi tạo flow. |
| `channel` | `instagram`/`facebook` | Có | Channel của flow. |
| `method` | `meta` | Có | Method đã chọn và dùng để dispatch callback. |
| `status` | `pending`/`discovered`/`failed`/`completed`/`expired` | Có | State machine của một lần kết nối. |
| `candidates` | metadata collection | Có sau callback | Resource id/name/avatar/page relation; không chứa token public. |
| `encryptedCredentialData` | internal encrypted value | Có sau discovery nếu cần | Token tạm dùng cho complete; không serialize ra API. |
| `expiresAt` | timestamp | Có | TTL và cleanup. |

State transition: `pending → discovered → completed`, hoặc `pending/discovered → failed/expired`. `completed/failed/expired` không được callback/complete lại.

### `MetaAccountConnection` — hiện hữu

Đại diện Meta user connection theo agent. Giữ các trường hiện hữu: `id`, `agent_id`, Meta user identity/display metadata, encrypted user access token, token type, timestamps. Unique `(meta_user_id, agent_id)` và index `agent_id` tiếp tục được dùng. Một Meta account có thể có nhiều channel resource trong cùng agent.

### `InstagramPageConnection` — hiện hữu

Đại diện linked Instagram Professional account qua Facebook Page. Giữ bảng/field hiện hữu để tránh regression: page identity, Instagram business account id/type, encrypted page token, status, timestamps và relation tới `MetaAccountConnection`. Unique `facebook_page_id` tiếp tục bảo vệ invariant resource không bị claim đồng thời.

### `FacebookPageConnection` — mới

Đại diện Facebook Page đã hoàn tất liên kết với agent:

| Trường | Kiểu PostgreSQL dự kiến | Ý nghĩa |
|---|---|---|
| `id` | UUID PK | Connection identity. |
| `meta_account_connection_id` | UUID NOT NULL | Meta account đã cấp quyền. |
| `agent_id` | UUID NOT NULL | Scope agent. |
| `facebook_page_id` | VARCHAR(64) NOT NULL | External resource identity. |
| `facebook_page_name` | VARCHAR(255) NOT NULL | Display metadata. |
| `facebook_page_avatar_url` | TEXT NULL | Display metadata. |
| `encrypted_page_access_token` | TEXT NOT NULL | Internal encrypted credential; không public. |
| `status` | VARCHAR(32) NOT NULL | `active`, `disconnected`, `error`. |
| `connected_at`/`disconnected_at` | TIMESTAMPTZ | Lifecycle timestamps. |
| `created_at`/`updated_at` | TIMESTAMPTZ | Audit/maintenance timestamps. |

Indexes: `agent_id`, `facebook_page_id`, `status`; unique `facebook_page_id`. Không thêm field Instagram-specific.

### `Channel Connection` và `External Account`

Đây là khái niệm nghiệp vụ trong spec, được hiện thực bằng các connection aggregate theo channel trong MVP:

- Instagram → `InstagramPageConnection` + linked Instagram metadata.
- Facebook → `FacebookPageConnection`.
- `MetaAccountConnection` là credential/provider parent dùng chung, không phải public channel card.

Không tạo generic table chỉ để khớp tên khái niệm khi chưa có channel thứ ba.

## Quan hệ và invariant

```text
Agent 1 ── n MetaAccountConnection 1 ── n InstagramPageConnection
                                      └─ n FacebookPageConnection

IntegrationConnectionSession (temporary, cache only)
  └─ candidate + credential reference → one complete operation
```

- Session chỉ complete resource thuộc chính session, agent, channel và method.
- Provider ownership/permission phải được xác nhận ở discovery và revalidate ở complete.
- Một Page không được có nhiều active Facebook connection; một Page holder trong Instagram flow vẫn giữ unique invariant hiện hữu.
- Disconnect chỉ thay đổi connection mục tiêu và credential reference của nó; không cascade xóa Meta account nếu resource khác còn dùng.
- Lỗi session mới không sửa các completed connection cũ.

## Migration và tương thích

1. `flex-database/agentdb` tạo release/changelog mới và `V1.4__create_meta_channel_connections.sql`.
2. Preflight kiểm tra các bảng Meta/Instagram legacy; schema không tương thích phải fail-fast để xử lý riêng, không âm thầm bỏ qua bằng `IF NOT EXISTS` cho index/constraint.
3. Tạo `facebook_page_connections` additive cùng index/unique resource index.
4. Không backfill runtime session; không seed connection/credential.
5. Deploy migration trước service. Sau khi service chạy, integration test kiểm tra EF mapping, list, complete, conflict và disconnect repeat.

## Data exposure rules

- Public response chỉ có id, channel, external resource id đã được phép, display metadata, status và timestamps.
- Không trả encrypted value, plaintext token, OAuth code/state, `Meta:AppSecret` hoặc credential reference.
- Audit chỉ lưu actor, agent, channel, resource/connection id, outcome, reason và timestamp.
