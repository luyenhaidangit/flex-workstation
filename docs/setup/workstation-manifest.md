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
| `preload` | Không | `false` | hook `SessionStart`, `flex-repo-scope` | `true` = repo lõi được nạp sẵn ở cloud khi yêu cầu cần repo con; repo khác clone theo nhu cầu. |

## `cloudEnabled`

- Chỉ ảnh hưởng cloud session (`CLAUDE_CODE_REMOTE=true`). Local sync và bootstrap bỏ qua trường này.
- Không khai báo nghĩa là `true`; chỉ thêm trường khi muốn tắt.
- Khi một yêu cầu cần repo đang tắt, agent báo cho người dùng thay vì tự bật lại. Muốn bật lại, xóa trường hoặc đặt `true`.

## Nạp sẵn repo ở cloud (Preload)

Hook `SessionStart` (`.claude/hooks/setup-container.sh`, chỉ chạy khi `CLAUDE_CODE_REMOTE=true`) đọc manifest và in ra các repo có `preload: true`, `cloudEnabled` khác `false` mà thư mục chưa tồn tại. Hook cũng nối symlink `/home/user/<name>` vào workstation root và thêm repo con vào `.git/info/exclude`, và tắt các MCP server trong `.mcp.json` thiếu biến môi trường (ghi vào `.claude/settings.local.json`, gitignore). Hook chỉ chạy khi session `startup` hoặc `resume`, không chạy lại sau compact. Danh sách này vào context của Claude; theo `flex-repo-scope` (mục Preload), sau bước route Claude chạy song song `add_repo` (read) cho các repo đó → clone bằng lệnh mà `add_repo` trả về vào đường dẫn `workspace` (`/home/user/<name>`) → symlink vào workstation root → `register_repo_root`, rồi báo kết quả một dòng. Yêu cầu không cần repo con thì bỏ qua preload.

- Hook chỉ liệt kê, không clone: repo private cần quyền của tài khoản qua `add_repo`, token trong container không đủ.
- Mỗi repo có thể kéo theo một lần duyệt quyền `add_repo` tùy giao diện.
- Muốn bỏ một repo khỏi danh sách nạp sẵn, xóa `"preload": true` (vẫn clone theo nhu cầu) hoặc đặt `"cloudEnabled": false` (tắt hẳn ở cloud).

## Thêm repo mới

Dùng `scripts/add-repo.ps1` hoặc skill `flex-repo-onboarding`; hai cách này cũng lo phần ignore rule. Sau khi thêm, xác minh `url` khớp origin của repo thật.
