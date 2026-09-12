# AGENTS.md

`flex-workstation` là workspace điều phối cho nhóm project Flex: tài liệu, bootstrap, skill source và cấu hình AI tooling. Các repo project được clone vào trong project root này dưới dạng Git repo độc lập (xem `workstation.json`).

## Ngôn ngữ

- Dùng tiếng Việt có dấu trong trả lời, tài liệu và ghi chú.
- Giữ nguyên tên file, thư mục, command, package, API, framework và thuật ngữ kỹ thuật bằng English khi đó là định danh kỹ thuật.

## Nguyên tắc làm việc

### Nghĩ trước khi thực hiện
- Nêu rõ giả định trước khi bắt đầu. Nếu không chắc, hỏi — đừng tự suy đoán im lặng.
- Nếu có điều chưa rõ, dừng lại, nêu tên cụ thể điểm mù đó, rồi mới hỏi.
- Nếu có nhiều cách hiểu, trình bày các lựa chọn; không tự chọn mà không thông báo.
- Nếu có cách đơn giản hơn, nói ra. Phản biện khi có lý.

### Đơn giản là ưu tiên
- Chỉ viết code đủ giải quyết yêu cầu. Không thêm tính năng suy đoán.
- Không tạo abstraction cho code chỉ dùng một lần.
- Không thêm flexibility hay configurability chưa được yêu cầu.
- Không viết error handling cho tình huống không thể xảy ra.
- Nếu nhận ra output của mình có thể rút gọn đáng kể, viết lại — không để lại code thừa.

### Thay đổi phẫu thuật
- Chỉ sửa những gì cần. Không "cải thiện" code, comment, hay format không liên quan.
- Khi sửa prompt, skill hoặc template, chỉ thay đổi phần cần thiết; tránh lặp/mâu thuẫn và kiểm tra trực tiếp phần đã sửa.
- Giữ nguyên style hiện có dù có thể làm khác.
- Nếu phát hiện dead code không liên quan, nhắc — không tự xóa.
- Xóa import/biến/hàm mà **chính thay đổi của mình** làm thừa, không xóa dead code từ trước.
- Kiểm tra: mỗi dòng thay đổi phải trace trực tiếp đến yêu cầu của người dùng.

### Thực thi hướng mục tiêu
- Với task nhiều bước, nêu plan ngắn trước khi làm: `1. [Bước] → kiểm tra: [cách]`
- Định nghĩa tiêu chí thành công rõ ràng trước khi bắt đầu thực hiện.
- Biến yêu cầu mơ hồ thành goal có thể verify: "thêm validation" → "test case X phải pass". Tiêu chí yếu ("làm cho nó chạy") cần hỏi lại trước khi bắt đầu.

## Skill routing bắt buộc

Trước mọi task liên quan đến file trong workspace, Agent phải:
1. Đọc và làm theo `flex-using-agent-skills`
2. Xác định tất cả skill áp dụng
3. Đọc và áp dụng từng skill trước khi bắt đầu

Các quy tắc bổ sung:
- Không chọn trực tiếp domain skill, bỏ qua router — trừ khi `flex-using-agent-skills` chính nó hướng dẫn khác.
- Nếu không có skill phù hợp, thông báo cho người dùng rồi tiếp tục theo instruction chung.
- Không gọi router đệ quy khi task chính là `flex-using-agent-skills`.
- Trong cùng một workflow, tái sử dụng skill đã chọn nếu phạm vi task không thay đổi.
- Có thể chọn nhiều skill nếu task giao nhau giữa nhiều domain.

## Speckit Workflow (Spec-Before-Code)

Mọi tính năng bắt đầu bằng spec nghiệp vụ trước khi có bất kỳ implementation nào.

### Cú pháp theo runtime

| Runtime | Cú pháp gọi skill Speckit |
| --- | --- |
| Codex | `$speckit-<command>` |
| Antigravity IDE/CLI và Claude Code | `/speckit-<command>` |

`/skills` trong Antigravity phải liệt kê các skill từ `.agents/skills/`. Không tạo workflow `/speckit` tự chạy toàn bộ vòng đời vì mỗi gate bên dưới cần người dùng gọi tường minh.

### Setup (chạy một lần cho project)

Thiết lập nguyên tắc: `$speckit-constitution` hoặc `/speckit-constitution`

### Mỗi feature (lặp lại)

| Bước | Codex | Antigravity / Claude | Ghi chú |
| --- | --- | --- | --- |
| 1 | `$speckit-specify <mô tả nghiệp vụ>` | `/speckit-specify <mô tả nghiệp vụ>` | Chỉ WHAT + WHY — không có tech stack |
| 2 | `$speckit-clarify` | `/speckit-clarify` | **Optional** — tối đa 5 câu làm rõ; chạy trước plan để giảm rework |
| 2a | `$speckit-docbiz` | `/speckit-docbiz` | **Documentation Impact Gate bắt buộc** sau lần cập nhật cuối của `spec.md`, trước plan |
| 3 | `$speckit-checklist [domain]` | `/speckit-checklist [domain]` | **Optional** — tạo checklist domain (ux, security, api) |
| 4 | `$speckit-plan <tech stack + architecture>` | `/speckit-plan <tech stack + architecture>` | Tech stack và architecture được truyền vào đây |
| 5 | `$speckit-tasks` | `/speckit-tasks` | Sinh task list theo dependency order |
| 6 | `$speckit-taskstoissues` | `/speckit-taskstoissues` | **Optional** — chuyển tasks → GitHub Issues |
| 7 | `$speckit-analyze` | `/speckit-analyze` | **Optional** — cross-artifact quality gate trước implement |
| 8 | `$speckit-implement` | `/speckit-implement` | Thực thi tasks; tự dừng nếu checklist còn item chưa tick |
| 9 | `$speckit-converge` | `/speckit-converge` | Nếu còn gap: append task bổ sung vào `tasks.md` → quay lại bước 8 |

Skills Speckit nằm tại `.agents/skills/` — source of truth dùng chung cho Codex, Antigravity và Claude Code.

### Gate bắt buộc giữa các bước

**Mỗi lệnh Speckit là một bước riêng biệt do người dùng chủ động gọi.**

- Không tự chuyển sang bước tiếp theo sau khi hoàn thành một lệnh.
- "Suggested next step" trong completion report chỉ là thông tin — không được tự thực thi.
- Sau khi mỗi lệnh hoàn thành, DỪNG và chờ người dùng gọi lệnh tiếp theo tường minh.
- `speckit-implement` chỉ chạy khi người dùng gọi trực tiếp — không bao giờ tự chạy.
- Lệnh cấp cao như "thực hiện X" hay "implement X" chỉ tương đương với bước 1 (`speckit-specify`) — không phải toàn bộ pipeline.
- Trước `speckit-plan`, PHẢI gọi `speckit-docbiz` sau lần cập nhật cuối của `spec.md`. Skill này luôn đánh giá tác động tài liệu; chỉ cập nhật khi thay đổi làm đổi luồng nghiệp vụ, vai trò, quy tắc, thực thể hoặc phạm vi mà BA/stakeholder cần biết. Khi cần cập nhật, ưu tiên chỉnh đúng phần của tài liệu hiện hữu; chỉ tạo tài liệu mới khi không có tài liệu phù hợp.

## Tooling

| Tool | Mục đích | Ghi chú |
| --- | --- | --- |
| `codex` | Codex CLI — chạy tại workstation root qua `OPEN_CODEX.cmd` | |
| `rtk` | Proxy CLI giảm 60–99% token output; xem `tooling/RTK.md` | **Golden Rule:** luôn prefix mọi command. Cấm bọc trong `powershell -Command` hoặc gọi PowerShell cmdlet. |
| `SYNC_WORKSPACE.cmd` | Bootstrap: clone/pull repos trong manifest, cài tool, sync skill junctions | |

## Cấu trúc project

```text
flex-workstation/
├── docs/            # Tài liệu workspace (system-map, onboarding, speckit)
├── tooling/         # Tài liệu công cụ workspace (RTK.md, ...)
├── scripts/         # Bootstrap và tooling scripts
├── .agents/         # Skill source chung cho Codex, Antigravity và Claude Code
├── .claude/         # Cấu hình Claude Code (settings.json, hooks, commands)
├── .codex/          # Cấu hình Codex CLI
├── workstation.json # Manifest repo được clone khi bootstrap
├── CLAUDE.md        # Context cho Claude Code
├── AGENTS.md        # Context chung cho Codex, Antigravity và Claude Code
└── <repo-con>/      # Repo con độc lập, ignore bởi Git của workstation
```

## Quy tắc làm việc

- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repo.
- Không tạo submodule/subtree hoặc liên kết version giữa repo nếu người dùng chưa yêu cầu rõ.
- Không sửa mã nguồn project con khi yêu cầu chỉ thuộc workstation.
- Không xóa hoặc revert thay đổi hiện có nếu không chắc đó là thay đổi do mình tạo.
- Khi thay đổi hành vi Speckit/template/runtime, cập nhật tài liệu tương ứng trong `docs/speckit/`.
- Khi thay đổi onboarding hoặc cấu trúc workspace, cập nhật `docs/setup/onboarding.md` hoặc `docs/architecture/system-map.md`.
- Với API service, `postman/` là nơi duy trì collection và luồng gọi API; chỉ cập nhật Swashbuckle/OpenAPI source khi phạm vi yêu cầu là Swagger UI hoặc OpenAPI document.

## Source-of-truth

| Loại | Vị trí |
| --- | --- |
| Tài liệu workstation | `docs/` |
| Skill dùng chung | `.agents/skills/<skill-name>/SKILL.md` (`.claude/skills` là junction) |
| Runtime config | `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.agents/`, `.codex/` |

## Tài liệu

```text
README.md
docs/setup/onboarding.md
docs/architecture/system-map.md
docs/speckit/workflow.md
docs/speckit/template-guidelines.md
docs/speckit/maintenance.md
```
