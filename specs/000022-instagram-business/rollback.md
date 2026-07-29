# Rollback: 000022-instagram-business

## Migration rollback (nếu cần undeploy)

Chạy theo thứ tự ngược lại — xóa bảng con trước, bảng cha sau:

```sql
DROP TABLE IF EXISTS instagram_page_connections;
DROP TABLE IF EXISTS meta_account_connections;
```

**Điều kiện kích hoạt**: Webhook verification thất bại liên tục sau deploy; OAuth callback không hoàn thành; DM không được xử lý sau 15 phút test (plan.md — Rollout & Rollback).

**Tương thích ngược**: Migration là additive — rollback chỉ xóa 2 bảng mới, không ảnh hưởng schema hiện có.
