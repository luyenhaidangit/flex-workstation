# AGENTS.md

Workspace root: `<WORKSPACE_ROOT>`.

`flex-workstation` là source-of-truth cho tài liệu, bootstrap, template, skill source và cấu hình workspace.

## Ngôn ngữ

- Dùng tiếng Việt có dấu trong trả lời, tài liệu và ghi chú. Giữ nguyên tên file, thư mục, command, package, API, framework và thuật ngữ kỹ thuật bằng tiếng Anh.

## Quy tắc workspace

Không tạo source file trực tiếp tại workspace root, trừ runtime config được copy từ template trong `.claude`, `.agents` và `.codex`; source-of-truth nằm ở `flex-workstation`.

Khi người dùng yêu cầu tạo hoặc sửa skill dùng chung:

- Tạo source tại `flex-workstation/skills/<skill-name>/SKILL.md`.
- `SYNC_WORKSPACE.cmd` không sync skill; chỉ sync runtime config từ template ra workspace root.

## Đồng bộ config với template

`flex-workstation/workspaces/templates/` là source-of-truth cho runtime config dùng chung. Khi sửa config dùng chung — `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`, `.codex/config.toml` — sửa trong template rồi chạy `SYNC_WORKSPACE.cmd` để cập nhật workspace root.

- Chỉ đưa config ổn định, dùng chung vào template (vd `model`, quy ước ngôn ngữ, workflow). KHÔNG đưa giá trị đặc thù máy/cá nhân vào template: path tuyệt đối, permission tạm cho từng máy. `.claude/settings.local.json` được giữ nguyên nếu đã tồn tại khi sync.

Tài liệu chi tiết nằm trong:

```text
flex-workstation\README.md
```
