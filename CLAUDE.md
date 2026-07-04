# CLAUDE.md

Project root: `C:\Workspace\Project\flex-workstation`.

Repo `flex-workstation` là workspace điều phối cho nhóm project Flex: tài liệu, bootstrap, template, skill source và cấu hình AI tooling. Theo `workstation.json`, các repo project có thể được clone vào trong project root này dưới dạng Git repo độc lập và được ignore bởi Git của workstation.

## Ngôn ngữ

- Dùng tiếng Việt có dấu trong trả lời, tài liệu và ghi chú.
- Giữ nguyên tên file, thư mục, command, package, API, framework và thuật ngữ kỹ thuật bằng English khi đó là định danh kỹ thuật.

## Quy tắc làm việc

- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repo.
- Không tạo submodule/subtree hoặc liên kết version giữa repo nếu người dùng chưa yêu cầu rõ.
- Không sửa mã nguồn project con khi yêu cầu chỉ thuộc workstation.
- Không xóa hoặc revert thay đổi hiện có nếu không chắc đó là thay đổi do mình tạo.
- Khi thay đổi hành vi, cấu trúc hoặc onboarding, cập nhật `docs/tasks.md` và file tài liệu tương ứng.

## Vị trí source-of-truth

- Tài liệu workstation: `docs/`.
- Skill dùng chung: `skills/<skill-name>/SKILL.md`.
- Template runtime config: `workspaces/templates/`.
- Runtime config sau sync: `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/`, `.codex/` ngay trong project root này.

## Đồng bộ config

Khi sửa config dùng chung — `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`, `.codex/config.toml` — sửa trong `workspaces/templates/`, rồi chạy:

```powershell
.\SYNC_WORKSPACE.cmd
```

`SYNC_WORKSPACE.cmd` không sync skill source. `.claude/settings.local.json` được giữ nguyên nếu đã tồn tại vì đây là cấu hình local theo máy/người dùng.

## Entrypoint Windows

- `OPEN_WORKSTATION.cmd`: mở `C:\Workspace\Project\flex-workstation` trong VS Code.
- `OPEN_WORKSPACE.cmd`: alias tương thích, gọi `OPEN_WORKSTATION.cmd`.
- `OPEN_CLAUDE.cmd`: mở Claude Code tại `C:\Workspace\Project\flex-workstation` với `--dangerously-skip-permissions`; chỉ dùng trong workstation tin cậy.
- `OPEN_CODEX.cmd`: mở Codex tại `C:\Workspace\Project\flex-workstation`.
- `SYNC_WORKSPACE.cmd`: sync template cấu hình Claude/Codex và chuẩn bị local tooling.

## Tài liệu

- Index đầy đủ: `README.md`.
- Onboarding/bootstrap: `docs/onboarding.md`.
- Bản đồ hệ thống: `docs/system-map.md`.
- Task hiện tại: `docs/tasks.md`.
