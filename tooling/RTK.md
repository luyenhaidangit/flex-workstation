# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Hook-Based Usage

Các lệnh shell/git được tự động rewrite bởi hook — không cần prefix thủ công.
Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)

## Native tool priority (Claude Code)

Khi native tool có sẵn, **luôn dùng native tool thay vì rtk + Bash**:

| Thao tác | Native tool | Không dùng |
| --- | --- | --- |
| Đọc file | **Read tool** | `rtk read` qua Bash |
| Tìm file | **Glob tool** | `rtk ls` qua Bash |
| Tìm nội dung | **Grep tool** (dùng `head_limit` thay `\| head -N`) | `rtk grep` qua Bash |

`rtk grep` / `rtk ls` / `rtk read` qua Bash chỉ dùng khi output cần pipe vào lệnh khác trong cùng shell command và không có native tool thay thế.

## Mapping lệnh

| Thay vì | Dùng | Shell |
| --- | --- | --- |
| `Get-Content <file>` / `cat` / `type` | `rtk read <file>` | Bash hoặc PowerShell |
| `rg <pattern> <path>` / `Select-String` | `rtk grep <pattern> <path>` | **Bash tool** (chỉ khi không có native Grep tool) |
| `Get-ChildItem` / `ls` / `dir` | `rtk ls <path>` | **Bash tool** (chỉ khi không có native Glob tool) |
| `git <args>` | `rtk git <args>` | Bash hoặc PowerShell |
| `tree` | `rtk tree <path>` | **Bash tool** |

> **Lưu ý shell**: `rtk ls`, `rtk grep`, `rtk tree` phụ thuộc vào Unix binary (`ls`, `grep`).
> Chỉ hoạt động qua **Bash tool** (Git Bash) — không chạy được từ PowerShell.

## Anti-pattern (cấm)

- `rtk powershell -Command "..."` — rtk không filter được lệnh bọc trong PowerShell, tiết kiệm 0 token.
- `rtk <PowerShell cmdlet>` (ví dụ `rtk Test-Path ...`) — fail vì cmdlet không phải executable.
- `rtk ls` / `rtk grep` / `rtk tree` từ PowerShell shell — fail vì binary Unix không có trên Windows PATH.
- Nếu buộc phải chạy wrapper `powershell -Command` (logic nhiều bước), chạy thẳng không có `rtk`.
- `rtk grep ... 2>/dev/null | head -N` qua Bash — dùng native **Grep tool** với `head_limit` thay thế; shell pipe gây timeout 120s trên codebase lớn.

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
