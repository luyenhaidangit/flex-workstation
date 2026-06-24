# AGENTS.md

Workspace root: `<WORKSPACE_ROOT>`.

`flex-workstation` là source-of-truth cho tài liệu, bootstrap, template, skill source và cấu hình workspace.

## Ngôn ngữ

- Dùng tiếng Việt có dấu trong trả lời, tài liệu và ghi chú. Giữ nguyên tên file, thư mục, command, package, API, framework và thuật ngữ kỹ thuật bằng tiếng Anh.

## Quy tắc workspace

Không tạo source file trực tiếp tại workspace root, trừ runtime config được copy từ template trong `.claude`, `.agents` và `.codex`; source-of-truth nằm ở `flex-workstation`.

Khi người dùng yêu cầu tạo hoặc sửa skill dùng chung:

- Tạo source tại `flex-workstation/skills/<skill-name>/SKILL.md`.
- `SYNC_WORKSPACE.cmd` không sync skill; chỉ copy các file template còn thiếu ra workspace root.

## Đồng bộ config với template

Workspace root là bản "sống"; `flex-workstation/workspaces/templates/` là bản scaffold mẫu dùng khi bootstrap setup mới. Khi sửa config dùng chung ở root — `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`, `.claude/settings.local.json`, `.codex/config.toml` — mirror thay đổi tương ứng sang template để setup mới kế thừa.

- Chỉ mirror config ổn định, dùng chung (vd `model`, quy ước ngôn ngữ, workflow). KHÔNG mirror giá trị đặc thù máy/cá nhân: path tuyệt đối, permission tạm cho từng máy.

Tài liệu chi tiết nằm trong:

```text
flex-workstation\README.md
```
