# Data Model: Mở Nhanh Các Project Code

**Date**: 2026-07-07 | **Feature**: 000002-cmd-open-projects

## Input Data

Script này đọc từ `workstation.json` — không tạo hay lưu state mới.

### Cấu trúc `workstation.json` (đã tồn tại)

```
WorkstationConfig
├── version: number           — phiên bản manifest (hiện tại: 1)
└── repositories
    └── items[]: Repository[]
        ├── name: string      — tên thư mục tương ứng trong workspace root
        └── url: string       — Git remote URL (không dùng bởi launcher)
```

### Các repo hiện tại

| name | Thư mục tại workspace root |
|------|---------------------------|
| flex-agents | `./flex-agents/` |
| flex-auth-service | `./flex-auth-service/` |
| flex-api-gateway | `./flex-api-gateway/` |
| flex-microfrontend | `./flex-microfrontend/` |
| flex-environment | `./flex-environment/` |

## Runtime State

Script không lưu state. Tại mỗi lần chạy:

| Input | Source | Dùng để |
|-------|--------|---------|
| Danh sách repo | `workstation.json` | Xác định folder cần mở |
| Sự tồn tại folder | File system check | Quyết định mở hay skip |
| `$PSScriptRoot` | PowerShell runtime | Xác định workspace root |

## Không có

- Không có database hay persistent state
- Không có user input tại runtime
- `url` trong workstation.json không được dùng bởi launcher (chỉ dùng bởi bootstrap)
