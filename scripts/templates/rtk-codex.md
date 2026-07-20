# RTK - Rust Token Killer (Codex CLI)

Proxy CLI giảm token output khi chạy shell command. Quy tắc bắt buộc: thay lệnh đọc/tìm/liệt kê/git bằng lệnh `rtk` tương ứng — KHÔNG bọc PowerShell wrapper trong `rtk`.

## Mapping bắt buộc

| Thay vì | Dùng |
| --- | --- |
| `Get-Content <file>` / `cat` / `type` | `rtk read <file>` |
| `rg <pattern> <path>` / `Select-String` | `rtk grep <pattern> <path>` |
| `Get-ChildItem` / `ls` / `dir` | `rtk ls <path>` |
| `git <args>` | `rtk git <args>` |
| `tree` | `rtk tree <path>` |

`rtk read` xuất UTF-8 đúng — không cần wrapper `[Console]::OutputEncoding` để đọc file tiếng Việt.

## Anti-pattern (cấm)

- `rtk powershell -Command "..."` — rtk không filter được lệnh bọc trong PowerShell, tiết kiệm 0 token.
- `rtk <PowerShell cmdlet>` (ví dụ `rtk Test-Path ...`) — fail vì cmdlet không phải executable.
- `rtk ls` / `rtk grep` / `rtk tree` từ PowerShell shell — fail vì binary Unix (`ls`, `grep`) không có trên Windows PATH; chỉ chạy được từ Bash/Git Bash context.
- Nếu buộc phải chạy wrapper `powershell -Command` (logic nhiều bước), chạy thẳng không có `rtk`.

## Meta commands

```bash
rtk gain            # Analytics token tiết kiệm được
rtk gain --history  # Lịch sử lệnh gần đây
rtk proxy <cmd>     # Chạy raw không filter (debug)
```
