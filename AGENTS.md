# AGENTS.md

`flex-workstation` là workspace điều phối cho nhóm project Flex: tài liệu, bootstrap, skill source và cấu hình AI tooling. Các repo project được clone vào trong project root này dưới dạng Git repo độc lập (xem `workstation.json`).

## Ngôn ngữ

- Dùng tiếng Việt có dấu trong trả lời, tài liệu và ghi chú.
- Giữ nguyên tên file, thư mục, command, package, API, framework và thuật ngữ kỹ thuật bằng English khi đó là định danh kỹ thuật.

## Hành vi làm việc cho Codex

### Nghĩ trước khi thực hiện
- Nêu rõ giả định trước khi bắt đầu. Nếu không chắc, hỏi — đừng tự suy đoán im lặng.
- Nếu có nhiều cách hiểu, trình bày các lựa chọn; không tự chọn mà không thông báo.
- Nếu có cách đơn giản hơn, nói ra. Phản biện khi có lý.

### Đơn giản là ưu tiên
- Chỉ viết code đủ giải quyết yêu cầu. Không thêm tính năng suy đoán.
- Không tạo abstraction cho code chỉ dùng một lần.
- Không viết error handling cho tình huống không thể xảy ra.

### Thay đổi phẫu thuật
- Chỉ sửa những gì cần. Không "cải thiện" code, comment, hay format không liên quan.
- Giữ nguyên style hiện có dù có thể làm khác.
- Nếu phát hiện dead code không liên quan, nhắc — không tự xóa.
- Xóa import/biến/hàm mà **chính thay đổi của mình** làm thừa, không xóa dead code từ trước.

### Thực thi hướng mục tiêu
- Với task nhiều bước, nêu plan ngắn trước khi làm: `1. [Bước] → kiểm tra: [cách]`
- Định nghĩa tiêu chí thành công rõ ràng trước khi bắt đầu thực hiện.

## Speckit Workflow (Spec-Before-Code)

Mọi tính năng bắt đầu bằng spec nghiệp vụ trước khi có bất kỳ implementation nào.

### Setup (chạy một lần cho project)

Thiết lập nguyên tắc: `$speckit-constitution`

### Mỗi feature (lặp lại)

| Bước | Lệnh Codex | Ghi chú |
|------|------------|---------|
| 1 | `$speckit-specify <mô tả nghiệp vụ>` | Chỉ WHAT + WHY — không có tech stack |
| 2 | `$speckit-clarify` | **Optional** — tối đa 5 câu làm rõ; chạy trước plan để giảm rework |
| 3 | `$speckit-checklist [domain]` | **Optional** — tạo checklist domain (ux, security, api) |
| 4 | `$speckit-plan <tech stack + architecture>` | Tech stack và architecture được truyền vào đây |
| 5 | `$speckit-tasks` | Sinh task list theo dependency order |
| 6 | `$speckit-taskstoissues` | **Optional** — chuyển tasks.md thành GitHub Issues |
| 7 | `$speckit-analyze` | **Optional** — cross-artifact quality gate trước implement |
| 8 | `$speckit-implement` | Thực thi tasks; tự dừng nếu checklist còn item chưa tick |
| 9 | `$speckit-converge` | Nếu còn gap: append task bổ sung vào tasks.md → quay lại bước 8 |

Skills speckit nằm tại `.agents/skills/` — source of truth dùng chung cho cả Codex và Claude Code.

## Tooling Codex

| Tool | Mục đích |
| --- | --- |
| `codex` | Codex CLI — chạy tại workstation root qua `OPEN_CODEX.cmd` |
| `rtk` | Proxy shell command để giảm token output; dùng khi chạy shell command nếu có |
| `SYNC_WORKSPACE.cmd` | Bootstrap: clone/pull repos, cài tool, sync flex-agents, sync skill junctions |
| `.codex/config.toml` | Cấu hình model, approval policy và sandbox cho Codex CLI |

Khi thay đổi quy tắc hành vi chung cho Claude trong `CLAUDE.md`, rà lại `AGENTS.md` để Codex nhận cùng tiêu chuẩn ở dạng phù hợp với Codex.

## Cấu trúc project

```text
flex-workstation/
├── docs/            # Tài liệu workspace (system-map, onboarding, tasks)
├── scripts/         # Bootstrap và tooling scripts
├── .agents/         # Cấu hình Codex agent; skill source tại .agents/skills/
├── .claude/         # Cấu hình Claude Code (settings.json, hooks, commands)
├── .codex/          # Cấu hình Codex CLI
├── workstation.json # Manifest repo được clone khi bootstrap
├── CLAUDE.md        # Context cho Claude Code
├── AGENTS.md        # File này — context cho Codex agent
└── <repo-con>/      # Repo con độc lập, ignore bởi Git của workstation
```

## Quy tắc làm việc

- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repo.
- Không tạo submodule/subtree hoặc liên kết version giữa repo nếu người dùng chưa yêu cầu rõ.
- Không sửa mã nguồn project con khi yêu cầu chỉ thuộc workstation.
- Không xóa hoặc revert thay đổi hiện có nếu không chắc đó là thay đổi do mình tạo.
- Khi thay đổi hành vi, cấu trúc hoặc onboarding, cập nhật `docs/tasks.md` và file tài liệu tương ứng.

## Source-of-truth

| Loại | Vị trí |
| --- | --- |
| Tài liệu workstation | `docs/` |
| Skill dùng chung | `.agents/skills/<skill-name>/SKILL.md` |
| Runtime config | `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/`, `.codex/` |

## Tài liệu

```text
README.md
docs/onboarding.md
docs/system-map.md
docs/tasks.md
```
