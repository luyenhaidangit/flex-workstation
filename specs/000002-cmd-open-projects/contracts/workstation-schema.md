# Contract: workstation.json Input Schema

**Feature**: 000002-cmd-open-projects | **Type**: Input dependency contract

## Mô tả

`open-code.ps1` phụ thuộc vào `workstation.json` tại workspace root. File này là nguồn sự thật cho danh sách repo cần mở.

## Schema yêu cầu

Script chỉ đọc các trường sau — các trường khác trong file được bỏ qua:

```json
{
  "repositories": {
    "items": [
      {
        "name": "<string>"
      }
    ]
  }
}
```

### Ràng buộc

| Field | Type | Required | Constraint |
|-------|------|----------|------------|
| `repositories` | object | Yes | Phải tồn tại |
| `repositories.items` | array | Yes | Có thể rỗng (script sẽ không mở gì) |
| `repositories.items[].name` | string | Yes | Phải là tên thư mục hợp lệ trên Windows |

## Behavior khi vi phạm

| Tình huống | Hành vi script |
|------------|----------------|
| `workstation.json` không tồn tại | Lỗi rõ ràng, dừng ngay |
| `repositories.items` rỗng | Thông báo "Không có repo nào được cấu hình", thoát bình thường |
| Repo `name` không có thư mục tương ứng | Skip với thông báo, tiếp tục repo tiếp theo |

## Ví dụ hợp lệ

```json
{
  "version": 1,
  "repositories": {
    "items": [
      { "name": "flex-api-gateway", "url": "..." },
      { "name": "flex-auth-service", "url": "..." }
    ]
  }
}
```

## CLI Contract: OPEN_CODE.cmd

| Invocation | Result |
|------------|--------|
| Double-click từ File Explorer | Mở tất cả repo được clone |
| `OPEN_CODE.cmd` trong terminal | Giống double-click |
| Không có argument | Không cần và không nhận argument |
