# AGENTS.md

Workspace root: `<WORKSPACE_ROOT>`.

`flex-workstation` là source-of-truth cho tài liệu, bootstrap, template, skill source và cấu hình workspace.

## Ngôn ngữ

- Dùng tiếng Việt có dấu trong trả lời, tài liệu và ghi chú. Giữ nguyên tên file, thư mục, command, package, API, framework và thuật ngữ kỹ thuật bằng tiếng Anh.

## Quy tắc workspace

Không tạo source file trực tiếp tại workspace root, trừ runtime generated config trong `.claude` và `.agents` — vì các thư mục này là target được generate khi bootstrap/sync; source-of-truth nằm ở `flex-workstation`.

Khi người dùng yêu cầu tạo hoặc sửa skill dùng chung:

- Tạo source tại `flex-workstation/.claude/skills/<skill-name>/SKILL.md` hoặc thư mục source đã khai báo trong `workspace-skills.json`.
- Khai báo skill trong `flex-workstation/config/workspace-skills.json`.
- Chạy `flex-workstation/SYNC_WORKSPACE_SKILLS.cmd`.
- Nếu Codex/Claude đang mở, mở session mới hoặc reload skill theo cơ chế của tool đang dùng.

## Đồng bộ config với template

Workspace root là bản "sống"; `flex-workstation/templates/project-root/` là bản scaffold mẫu dùng khi bootstrap setup mới. Khi sửa config dùng chung ở root — `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`, `.claude/settings.local.json` — mirror thay đổi tương ứng sang `flex-workstation/templates/project-root/` để setup mới kế thừa.

- Chỉ mirror config ổn định, dùng chung (vd `model`, quy ước ngôn ngữ, workflow). KHÔNG mirror giá trị đặc thù máy/cá nhân: path tuyệt đối, permission tạm cho từng máy.

Tài liệu chi tiết nằm trong:

```text
flex-workstation\README.md
```
