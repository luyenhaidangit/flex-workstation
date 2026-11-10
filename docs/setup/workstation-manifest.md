# Manifest `workstation.json`

`workstation.json` khai báo các repo con mà workstation quản lý. Hai nơi đọc nó:

- `scripts/sync-repositories.ps1` (local): clone/pull repo vào workstation root khi chạy `SYNC_WORKSPACE.cmd`.
- Skill `flex-repo-scope` (agent, cả local lẫn cloud): chọn repo cần đọc/sửa dựa trên `scope`; ở cloud còn attach và clone repo đó.

## Cấu trúc

```json
{
  "version": 1,
  "repositories": {
    "destinationRoot": ".",
    "items": [
      {
        "name": "flex-microfrontend",
        "url": "https://github.com/org/flex-microfrontend",
        "branch": "main",
        "scope": "Frontend client (Angular): ...",
        "cloudEnabled": false
      }
    ]
  }
}
```

## Trường cấp `repositories`

| Trường | Bắt buộc | Ý nghĩa |
| --- | --- | --- |
| `destinationRoot` | Không | Thư mục đích để clone, tính từ workstation root. Mặc định `.`. |
| `items` | Có | Danh sách repo con. |

## Trường của mỗi entry trong `items`

| Trường | Bắt buộc | Mặc định | Ai đọc | Ý nghĩa |
| --- | --- | --- | --- | --- |
| `name` | Có | — | sync, `flex-repo-scope` | Tên thư mục local. |
| `url` | Có | — | sync, `flex-repo-scope` | Git remote URL. Không đưa token hoặc credential vào URL. |
| `branch` | Không | nhánh mặc định của remote | sync | Nhánh cần clone. |
| `scope` | Nên có | — | `flex-repo-scope` | Mô tả repo sở hữu gì, dùng để chọn repo cho từng yêu cầu. |
| `cloudEnabled` | Không | `true` | `flex-repo-scope` | `false` = repo bị tắt trong cloud session: không attach, không clone, không đọc qua GitHub MCP. |

## `cloudEnabled`

- Chỉ ảnh hưởng cloud session (`CLAUDE_CODE_REMOTE=true`). Local sync và bootstrap bỏ qua trường này.
- Không khai báo nghĩa là `true`; chỉ thêm trường khi muốn tắt.
- Khi một yêu cầu cần repo đang tắt, agent báo cho người dùng thay vì tự bật lại. Muốn bật lại, xóa trường hoặc đặt `true`.

## Thêm repo mới

Dùng `scripts/add-repo.ps1` hoặc skill `flex-repo-onboarding`; hai cách này cũng lo phần ignore rule. Sau khi thêm, xác minh `url` khớp origin của repo thật.
