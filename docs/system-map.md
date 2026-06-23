# Bản đồ hệ thống workspace

Tài liệu này mô tả tổng quan hệ thống hiện tại ở cấp `C:\Workspace\Project`. Mục tiêu là giúp người mới và AI agent hiểu nhanh repo nào giữ vai trò gì, cấu hình runtime nằm ở đâu, và nên đọc tài liệu nào trước khi làm việc.

## Snapshot hiện tại

```text
C:\Workspace\Project\
|-- .agents\              # Runtime skills/agents/commands cho Codex
|-- .claude\              # Runtime settings/skills/agents/commands cho Claude Code
|-- flex-workstation\     # Source-of-truth điều phối workspace
|-- flex-auth-service\    # Service xác thực/ủy quyền
|-- flex-api-gateway\     # API Gateway
|-- flex-microfrontend\   # Frontend client
+-- flex-environment\     # Local/dev infrastructure stack
```

`flex-workstation` không chứa mã nguồn nghiệp vụ. Repo này quản lý bootstrap, tài liệu, template, skill source, entrypoint Windows và cấu hình dùng chung cho assistant.

## Vai trò các repo

| Repo / thư mục | Vai trò | Ghi chú |
| --- | --- | --- |
| `.claude` | Runtime Claude Code tại workspace root | Được bootstrap/sync từ `flex-workstation`; không sửa trực tiếp nếu thay đổi thuộc source dùng chung. |
| `.agents` | Runtime Codex tại workspace root | Được bootstrap/sync từ `flex-workstation`; chứa skills/agents/commands đã sync. |
| `flex-workstation` | Repository điều hướng toàn workspace | Source-of-truth cho docs, bootstrap, template, skills và config assistant. |
| `flex-auth-service` | Service xác thực/ủy quyền | Tài liệu/spec riêng nằm trong chính repo này. |
| `flex-api-gateway` | API Gateway cho nhóm service Flex | Repo riêng, có `.sln`, `Dockerfile`, `Jenkinsfile`. |
| `flex-microfrontend` | Frontend client | Angular/Node.js theo README và `package.json`. |
| `flex-environment` | Local/dev infrastructure stack | Docker Compose cho Redis, RabbitMQ, Jenkins, Portainer, MinIO, Elasticsearch, Kibana, Ollama và `flex-ai-gateway`. |

## Luồng bootstrap và sync

Entrypoint chuẩn:

```text
flex-workstation\SYNC_WORKSPACE.cmd
```

Luồng chính:

```text
SYNC_WORKSPACE.cmd
  -> scripts/bootstrap.ps1
     -> chuẩn bị root CLAUDE.md / AGENTS.md
     -> chuẩn bị .claude / .agents runtime folders
     -> scripts/sync-workspace-skills.ps1
     -> scripts/ensure-ccusage.ps1
     -> scripts/ensure-rtk.ps1
     -> kiểm tra/cài Claude Code nếu thiếu
```

Sau khi sync skills trong session đang mở:

- Claude Code: chạy `/reload-skills` hoặc mở session mới.
- Codex: mở session mới nếu danh sách skills chưa cập nhật.
- RTK: mở session Claude/Codex mới sau lần init đầu tiên để hook/global instruction được nạp.

## Runtime AI tooling

| Tooling | Source-of-truth | Runtime target | Mục đích |
| --- | --- | --- | --- |
| Claude Code root instruction | `templates/project-root/CLAUDE.md` | `C:\Workspace\Project\CLAUDE.md` | Chỉ dẫn bền vững cho Claude tại workspace root. |
| Codex root instruction | `templates/project-root/AGENTS.md` | `C:\Workspace\Project\AGENTS.md` | Chỉ dẫn bền vững cho Codex tại workspace root. |
| Skills/agents/commands | `config/workspace-assistants.json`, `skills/`, `C:\Workspace\Project\flex-agents` | `.claude/*`, `.agents/*` | Runtime capability cho Claude/Codex. |
| `ccusage` | `scripts/ensure-ccusage.ps1` | User global CLI | Theo dõi token/cost usage của coding AI CLI. |
| `rtk` | `scripts/ensure-rtk.ps1` | User global CLI + Claude/Codex global config | Giảm token từ shell output và cung cấp instruction/hook tối ưu. |

## Quy tắc source-of-truth

- Sửa tài liệu workspace trong `flex-workstation/docs`.
- Sửa template bootstrap trong `flex-workstation/templates`.
- Sửa skill source trong `flex-workstation/skills` hoặc nguồn đã khai báo trong `workspace-assistants.json`.
- Không sửa trực tiếp `.claude/skills`, `.agents/skills`, `.claude/commands`, `.agents/commands` vì đây là output sync.
- Không đặt mã nguồn nghiệp vụ trong `flex-workstation`; mỗi project nghiệp vụ là repo ngang hàng trong `C:\Workspace\Project`.

## Khi agent cần hiểu hệ thống

Đọc theo thứ tự:

1. `README.md` — index và entrypoint.
2. `docs/system-map.md` — bản đồ hệ thống hiện tại.
3. `docs/architecture/overview.md` — kiến trúc kỹ thuật chi tiết toàn platform (components, flows, security, deployment, risks).
4. `docs/projects.md` — danh sách repo được theo dõi.
5. `docs/onboarding.md` — bootstrap máy mới.
6. Tài liệu riêng trong repo nghiệp vụ liên quan.

## Việc còn mở

- Khi thêm repo mới, cập nhật file này và `docs/projects.md`.
- Nếu dùng GitNexus/GraphRAG cho codebase map, ghi rõ repo nào đã được index và lệnh refresh graph tương ứng.
