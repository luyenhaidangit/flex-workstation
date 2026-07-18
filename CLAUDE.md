# CLAUDE.md

`flex-workstation` là workspace điều phối cho nhóm project Flex: tài liệu, bootstrap, skill source và cấu hình AI tooling. Các repo project được clone vào trong project root này dưới dạng Git repo độc lập (xem `workstation.json`).

## Hành vi làm việc

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
- Khi sửa prompt, skill hoặc template, chỉ thay đổi phần cần thiết; tránh lặp/mâu thuẫn và kiểm tra trực tiếp phần đã sửa.
- Giữ nguyên style hiện có dù có thể làm khác.
- Nếu phát hiện dead code không liên quan, nhắc — không tự xóa.
- Xóa import/biến/hàm mà **chính thay đổi của mình** làm thừa, không xóa dead code từ trước.

### Thực thi hướng mục tiêu
- Với task nhiều bước, nêu plan ngắn trước khi làm: `1. [Bước] → kiểm tra: [cách]`
- Định nghĩa tiêu chí thành công rõ ràng trước khi bắt đầu thực hiện.

## Quy tắc làm việc

- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repo.
- Không tạo submodule/subtree hoặc liên kết version giữa repo nếu người dùng chưa yêu cầu rõ.
- Không sửa mã nguồn project con khi yêu cầu chỉ thuộc workstation.
- Không xóa hoặc revert thay đổi hiện có nếu không chắc đó là thay đổi do mình tạo.
- Khi thay đổi hành vi Speckit/template/runtime, cập nhật tài liệu tương ứng trong `docs/speckit/`.
- Khi thay đổi onboarding hoặc cấu trúc workspace, cập nhật `docs/setup/onboarding.md` hoặc `docs/architecture/system-map.md`.

## Quy ước API client/Swagger

- Trong workspace này, “cập nhật Swagger” đối với API service mặc định nghĩa là cập nhật collection/context tại `postman/`, đặc biệt `postman/flex.postman_collection.json`.
- Collection phải phản ánh route, payload, biến môi trường và luồng nghiệp vụ hiện tại; luôn parse/validate JSON sau khi sửa.
- Chỉ cập nhật Swashbuckle/OpenAPI trong source khi người dùng yêu cầu rõ Swagger UI/OpenAPI document hoặc cần đồng bộ contract kỹ thuật.

## Skills

Trước khi bắt đầu bất kỳ task nào, kiểm tra xem có skill nào phù hợp không. Skill được load tự động — chỉ cần áp dụng khi trigger khớp:

| Context | Skill |
| --- | --- |
| Viết, review hoặc generate C#/.NET code | `dotnet-conventions` |
| Tính năng mới chưa có spec | `spec-driven-development` |
| Có spec, cần breakdown task | `planning-and-task-breakdown` |
| Viết code / implement (có hoặc không có plan) | `incremental-implementation` |
| Fix bug, lỗi runtime, test thất bại | `debugging-and-error-recovery` |

Xem danh sách đầy đủ và cách phối hợp nhiều skill: `using-agent-skills`.

## Speckit Workflow (Spec-Before-Code)

Mọi tính năng bắt đầu bằng spec nghiệp vụ trước khi có bất kỳ implementation nào.

## Cấu trúc project

```text
flex-workstation/
├── docs/            # Tài liệu workspace (system-map, onboarding, speckit)
├── scripts/         # Bootstrap và tooling scripts
├── skills/          # Skill source dùng chung (mỗi skill một thư mục SKILL.md)
├── .claude/         # Cấu hình Claude Code (settings.json, hooks, commands)
├── .agents/         # Cấu hình Codex agent
├── .codex/          # Cấu hình Codex CLI
├── workstation.json # Manifest repo được clone khi bootstrap
├── CLAUDE.md        # File này — context cho Claude Code
├── AGENTS.md        # Context cho Codex agent
└── <repo-con>/      # Repo con độc lập, ignore bởi Git của workstation
```

## Source-of-truth

| Loại | Vị trí |
| --- | --- |
| Tài liệu workstation | `docs/` |
| Skill dùng chung | `skills/<skill-name>/SKILL.md` |
| Runtime config | `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/`, `.codex/` |

## Tài liệu

- Index đầy đủ: `README.md`
- Onboarding/bootstrap: `docs/setup/onboarding.md`
- Bản đồ hệ thống & kiến trúc: `docs/architecture/system-map.md`
- Workflow Speckit: `docs/speckit/workflow.md`
- Quy ước template Speckit: `docs/speckit/template-guidelines.md`
- Bảo trì Speckit/runtime: `docs/speckit/maintenance.md`
