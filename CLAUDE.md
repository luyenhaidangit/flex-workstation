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

### Skill routing bắt buộc

Với mọi task đọc, phân tích, review, tạo, sửa, refactor, fix hoặc xóa source code
trong repository, Claude bắt buộc dùng `flex-using-agent-skills` làm điểm vào để
xác định đầy đủ các skill chuyên môn phù hợp và thứ tự áp dụng.

- Trước khi sửa source code, Claude phải: (1) đọc và làm theo
  `flex-using-agent-skills`; (2) xác định tất cả skill áp dụng; và (3) đọc, áp dụng
  các skill bắt buộc.
- Không được bỏ qua `flex-using-agent-skills` bằng cách chọn trực tiếp domain skill,
  trừ khi chính skill đó hướng dẫn khác.
- Có thể chọn nhiều skill nếu task giao nhau giữa nhiều domain.
- Nếu không có skill phù hợp, ghi nhận kết quả và tiếp tục theo instruction chung.
- Không gọi router đệ quy khi task chính là `flex-using-agent-skills`.
- Trong cùng một workflow, tái sử dụng skill đã chọn nếu phạm vi task không thay đổi.

## Quy tắc làm việc

- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repo.
- Không tạo submodule/subtree hoặc liên kết version giữa repo nếu người dùng chưa yêu cầu rõ.
- Không sửa mã nguồn project con khi yêu cầu chỉ thuộc workstation.
- Không xóa hoặc revert thay đổi hiện có nếu không chắc đó là thay đổi do mình tạo.
- Khi thay đổi hành vi Speckit/template/runtime, cập nhật tài liệu tương ứng trong `docs/speckit/`.
- Khi thay đổi onboarding hoặc cấu trúc workspace, cập nhật `docs/setup/onboarding.md` hoặc `docs/architecture/system-map.md`.
- Với API service, `postman/` là nơi duy trì collection và luồng gọi API; chỉ cập nhật Swashbuckle/OpenAPI source khi phạm vi yêu cầu là Swagger UI hoặc OpenAPI document.
- Khi sửa nội dung skill (SKILL.md, template, script...): luôn tìm bản có git trước — `.agents/skills/<skill-name>/` (skill dùng chung của workstation) hoặc `<repo-con>/skills/<skill-name>/` nếu skill đó thuộc về một repo con cụ thể (vd. `dotnet-conventions` thuộc `flex-agents/skills/dotnet-conventions/`). KHÔNG sửa trực tiếp bản cài local tại `~/.claude/skills/` hay `~/.codex/skills/` — các thư mục này không được git track, thay đổi sẽ không review/commit được và biến mất khi resync. Nếu không chắc skill đó có nguồn ở repo nào, dùng Glob/Grep tìm trong toàn bộ `flex-workstation/` trước khi kết luận chỉ có bản local.

## Skills

Trước khi bắt đầu bất kỳ task mới nào, bắt buộc sử dụng `flex-using-agent-skills` để định tuyến và xác định skill phù hợp. Skill chuyên môn phải được đọc và áp dụng trước khi thực thi task:

| Context | Skill |
| --- | --- |
| Viết, review hoặc generate C#/.NET code | `flex-dotnet-engineering` |
| Viết/sửa giao diện Angular trong flex-microfrontend (component, template, modal, form) | `flex-frontend-engineering` |
| Tính năng mới chưa có spec | `spec-driven-development` |
| Có spec, cần breakdown task | `planning-and-task-breakdown` |
| Viết code / implement (có hoặc không có plan) | `incremental-implementation` |
| Fix bug, lỗi runtime, test thất bại | `debugging-and-error-recovery` |
| Nghiên cứu phương pháp kiếm tiền online (MMO) | `mmo-research` |

Xem quy tắc định tuyến và cách phối hợp nhiều skill: `flex-using-agent-skills`.

## Speckit Workflow (Spec-Before-Code)

Mọi tính năng bắt đầu bằng spec nghiệp vụ trước khi có bất kỳ implementation nào.

**Gate bắt buộc giữa các bước**: Mỗi lệnh `/speckit-*` là bước người dùng gọi tường minh. Sau khi hoàn thành, DỪNG và chờ — không tự chuyển sang bước tiếp theo. "Suggested next step" chỉ là thông tin, không phải lệnh. `/speckit-implement` chỉ chạy khi được gọi trực tiếp. Lệnh cấp cao như "implement X" chỉ tương đương với `/speckit-specify`, không phải toàn bộ pipeline.

## Cấu trúc project

```text
flex-workstation/
├── docs/            # Tài liệu workspace (system-map, onboarding, speckit)
├── scripts/         # Bootstrap và tooling scripts
├── .claude/         # Cấu hình Claude Code (settings.json, hooks, commands); .claude/skills junction tới .agents/skills
├── .agents/         # Cấu hình Codex agent; skill source dùng chung tại .agents/skills/
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
| Skill dùng chung | `.agents/skills/<skill-name>/SKILL.md` (`.claude/skills` là junction) |
| Skill thuộc repo con (vd. `flex-dotnet-engineering`) | `<repo-con>/skills/<skill-name>/` (vd. `flex-agents/skills/flex-dotnet-engineering/`) — không sửa `~/.claude/skills/` hay `~/.codex/skills/` |
| Runtime config | `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/`, `.codex/` |

## Tài liệu

- Index đầy đủ: `README.md`
- Bài học/quyết định tích lũy qua các phiên (chia sẻ cả team, khác `MEMORY.md` cá nhân của từng agent): `MEMORY.md`
- Theo dõi spec Speckit đang chạy song song: `TASKS.md`
- Onboarding/bootstrap: `docs/setup/onboarding.md`
- Bản đồ hệ thống & kiến trúc: `docs/architecture/system-map.md`
- Workflow Speckit: `docs/speckit/workflow.md`
- Quy ước template Speckit: `docs/speckit/template-guidelines.md`
- Bảo trì Speckit/runtime: `docs/speckit/maintenance.md`
