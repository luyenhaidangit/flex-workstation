# Quickstart: Kiểm tra luồng Instagram Business

**Feature**: `000022-instagram-business`  
**Ngày**: 2026-07-29  
**Mục đích**: Hướng dẫn kiểm tra end-to-end để xác nhận tính năng hoạt động đúng sau khi implement.

---

## Điều kiện tiên quyết

| Điều kiện | Kiểm tra |
|-----------|---------|
| Tài khoản Instagram Business hoặc Creator thật | Tài khoản phải liên kết với ít nhất 1 Facebook Page |
| Meta Developer App đã có quyền `instagram_manage_messages` + `pages_messaging` | Đã xác nhận trong clarifications |
| Webhook URL đã được đăng ký trong Meta App Dashboard và verify thành công | `GET /api/webhooks/instagram?hub.mode=subscribe&...` trả về `hub.challenge` |
| Migration đã chạy | Bảng `meta_account_connections` và `instagram_page_connections` tồn tại trong DB |
| Tài khoản test Instagram cá nhân (để gửi DM tới trang Business) | Tài khoản Instagram bất kỳ |

---

## Kiểm tra 1: Webhook verification

**Mục đích**: Xác nhận Meta có thể verify webhook endpoint.

```bash
# Gọi thủ công như Meta sẽ gọi
curl "https://{your-domain}/api/webhooks/instagram?hub.mode=subscribe&hub.verify_token={configured_verify_token}&hub.challenge=123456789"

# Expected response: HTTP 200, body = "123456789"
```

---

## Kiểm tra 2: Luồng kết nối Instagram (US-001)

**Mục đích**: Xác nhận luồng OAuth end-to-end và popup kết quả hoạt động đúng.

**Bước thực hiện**:

1. Đăng nhập Customer Studio với tài khoản có quyền owner/admin của agent.
2. Chọn agent → Tab "Phát hành".
3. Xác nhận kênh "Instagram Business" hiển thị trong danh sách với 3 bước hướng dẫn (FR-001).
4. Bấm "Kết nối ngay".
5. Hoàn thành đăng nhập Facebook → cấp quyền cho app.
6. Popup "Kết quả kết nối" xuất hiện.

**Kết quả mong đợi**:
- Tab "Hợp lệ": hiển thị các page có Instagram Business/Creator liên kết, có checkbox chọn.
- Tab "Không hợp lệ" (nếu có): hiển thị page đã bị agent khác kết nối, có tên agent.
- Chọn ít nhất 1 page → bấm "Xác nhận".
- Connected-state UI xuất hiện với page đã chọn nhóm theo tài khoản Meta.
- Label "Đã phát hành" màu xanh hiển thị trên channel card.

**Kiểm tra DB**:
```sql
SELECT mac.meta_user_name, ipc.facebook_page_name, ipc.status, ipc.connected_at
FROM meta_account_connections mac
JOIN instagram_page_connections ipc ON ipc.meta_account_connection_id = mac.id
WHERE mac.agent_id = '{agent-uuid}';
```
→ Phải có ít nhất 1 row với `status = 'active'`.

---

## Kiểm tra 3: Điều kiện tài khoản (AC-004, FR-004)

**Mục đích**: Xác nhận hệ thống từ chối tài khoản cá nhân.

**Bước thực hiện**:

1. Thực hiện luồng kết nối với tài khoản Facebook quản lý page KHÔNG có Instagram Business Account.
2. Popup "Kết quả kết nối" mở ra.

**Kết quả mong đợi**:
- Tab "Hợp lệ": rỗng hoặc không có page đủ điều kiện.
- Tab "Không hợp lệ" (nếu page bị agent khác giữ) hoặc không có gì để chọn.
- User không thể xác nhận và hoàn thành kết nối.

---

## Kiểm tra 4: Conflict giữa agents (BR-005, FR-010)

**Mục đích**: Xác nhận 1 page không thể kết nối với 2 agent đồng thời.

**Bước thực hiện**:

1. Kết nối page A với Agent 1 (thành công).
2. Đăng nhập với tài khoản khác, truy cập Agent 2.
3. Thực hiện luồng kết nối với cùng Facebook account có page A.

**Kết quả mong đợi**:
- Popup "Kết quả kết nối": page A xuất hiện trong tab "Không hợp lệ".
- Cột "Agent đã kết nối" hiển thị tên Agent 1.
- Không thể chọn page A cho Agent 2.

---

## Kiểm tra 5: AI Agent trả lời DM (US-002, AC-005)

**Mục đích**: Xác nhận agent nhận và trả lời DM trong cửa sổ 24h.

**Bước thực hiện**:

1. Đảm bảo agent đã phát hành thành công (Kiểm tra 2 đã pass).
2. Dùng tài khoản Instagram cá nhân gửi DM đến trang Instagram Business đã kết nối.
3. Chờ tối đa 60 giây.

**Kết quả mong đợi**:
- Agent trả lời DM trong vòng 60 giây (AC-005).
- Kiểm tra log: `instagram.webhook.dm_routed {withinWindow: true}` và `instagram.send.success`.

**Kiểm tra DB**:
```sql
SELECT last_customer_dm_at, status
FROM instagram_page_connections
WHERE facebook_page_id = '{page-id}';
```
→ `last_customer_dm_at` được cập nhật thành thời điểm gửi DM.

---

## Kiểm tra 6: 24-hour window (BR-006)

**Mục đích**: Xác nhận agent không gửi tin ngoài cửa sổ 24h.

**Bước thực hiện** (manual, cần can thiệp DB):

1. Cập nhật `last_customer_dm_at` trong DB về 25 giờ trước:
```sql
UPDATE instagram_page_connections
SET last_customer_dm_at = now() - INTERVAL '25 hours'
WHERE facebook_page_id = '{page-id}';
```
2. Gửi DM mới đến trang Instagram.
3. Chờ 60 giây.

**Kết quả mong đợi**:
- Agent KHÔNG trả lời.
- Log: `instagram.webhook.dm_skipped {reason: "outside_window"}`.
- `last_customer_dm_at` được cập nhật về thời điểm DM mới (vẫn cập nhật dù không reply).

---

## Kiểm tra 7: Ngắt kết nối (US-003, FR-007)

**Bước thực hiện**:

1. Trong connected-state UI, bấm "Ngắt kết nối" cho 1 page.
2. Gửi DM từ tài khoản test.

**Kết quả mong đợi**:
- Page biến mất khỏi danh sách kết nối (hoặc hiển thị trạng thái "Chưa kết nối").
- Agent không trả lời DM sau khi ngắt kết nối.
- DB: `status = 'disconnected'`, `disconnected_at` có giá trị.

---

## Kiểm tra 8: Permission (SEC-001, SEC-002)

```bash
# Viewer role gọi connect endpoint → expect 403
curl -X POST /api/channels/instagram/connect \
  -H "Authorization: Bearer {viewer-token}" \
  -d '{"agentId": "uuid"}'
# Expected: 403

# Owner của Agent 1 gọi list connections của Agent 2 → expect 403 hoặc 404
curl /api/channels/instagram/connections?agentId={agent-2-uuid} \
  -H "Authorization: Bearer {agent-1-owner-token}"
# Expected: 403 hoặc rỗng (không thấy connections của agent khác)
```

---

## Smoke check sau deploy

| Check | Lệnh/Hành động | Expected |
|-------|----------------|----------|
| Webhook verify | curl GET với hub.challenge | Trả về challenge number |
| DB migration | SELECT table_name FROM information_schema.tables WHERE table_name IN ('meta_account_connections','instagram_page_connections') | 2 rows |
| Channel card hiển thị | Vào màn hình Phát hành | Card "Instagram Business" hiển thị |
| Kết nối cơ bản | Hoàn thành OAuth với test account | Connected-state UI xuất hiện |
| DM cơ bản | Gửi DM test | Agent trả lời trong 60s |

---

## Tham chiếu

- Data model: [data-model.md](./data-model.md)
- API contracts: [contracts/instagram-api.md](./contracts/instagram-api.md)
- Research: [research.md](./research.md) — §2 webhook format, §5 Send API format
