# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Hook-Based Usage

Các lệnh shell/git được tự động rewrite bởi hook — không cần prefix thủ công.
Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)

## Mapping lệnh

| Thay vì | Dùng | Shell |
| --- | --- | --- |
| `Get-Content <file>` / `cat` / `type` | `rtk read <file>` | Bash hoặc PowerShell |
| `rg <pattern> <path>` / `Select-String` | `rtk grep <pattern> <path>` | **Bash tool** |
| `Get-ChildItem` / `ls` / `dir` | `rtk ls <path>` | **Bash tool** |
| `git <args>` | `rtk git <args>` | Bash hoặc PowerShell |
| `tree` | `rtk tree <path>` | **Bash tool** |

> **Lưu ý shell**: `rtk ls`, `rtk grep`, `rtk tree` phụ thuộc vào Unix binary (`ls`, `grep`).
> Chỉ hoạt động qua **Bash tool** (Git Bash) — không chạy được từ PowerShell.

## Anti-pattern (cấm)

- `rtk powershell -Command "..."` — rtk không filter được lệnh bọc trong PowerShell, tiết kiệm 0 token.
- `rtk <PowerShell cmdlet>` (ví dụ `rtk Test-Path ...`) — fail vì cmdlet không phải executable.
- `rtk ls` / `rtk grep` / `rtk tree` từ PowerShell shell — fail vì binary Unix không có trên Windows PATH.
- Nếu buộc phải chạy wrapper `powershell -Command` (logic nhiều bước), chạy thẳng không có `rtk`.

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary (run in Bash tool)
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.
