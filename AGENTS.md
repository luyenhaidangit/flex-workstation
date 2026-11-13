# AGENTS.md

`flex-workstation` là workspace điều phối cho nhóm project Flex: tài liệu, bootstrap, skill source và cấu hình AI tooling. Các repo project được clone vào trong project root này dưới dạng Git repo độc lập (xem `workstation.json`).

## Ngôn ngữ

- Dùng tiếng Việt có dấu trong trả lời, tài liệu và ghi chú.
- Mọi văn bản hiển thị cho người dùng đều bằng tiếng Việt có dấu, kể cả thông báo routing và lời dẫn giữa các lần gọi tool. Tên skill và định danh kỹ thuật giữ nguyên.
- Giữ nguyên tên file, thư mục, command, package, API, framework và thuật ngữ kỹ thuật bằng English khi đó là định danh kỹ thuật.

## Nguyên tắc làm việc

### Nghĩ trước khi thực hiện
- Nêu rõ giả định trước khi bắt đầu. Nếu không chắc, hỏi — đừng tự suy đoán im lặng.
- Nếu có điều chưa rõ, dừng lại, nêu tên cụ thể điểm mù đó, rồi mới hỏi.
- Nếu có nhiều cách hiểu, trình bày các lựa chọn; không tự chọn mà không thông báo.
- Nếu có cách đơn giản hơn, nói ra. Phản biện khi có lý.
- Hiện trạng hệ thống Flex (Nginx, Docker Compose, TLS, deploy...) phải lấy từ repo/config thực tế theo `scope` trong `workstation.json`, không suy ra từ mô tả skill hay kiến thức chung. Chưa đọc được thì nói rõ là chưa xác minh và đi đọc, không đoán rồi hỏi ngược người dùng.
- Tin nhắn chỉ trỏ bằng đại từ hoặc vị trí ("như sau", "bên dưới", "file này") mà không đính kèm nội dung: hỏi lại một dòng trước khi dựng phương án. Nếu chủ đề gọi tên được và thuộc hệ thống Flex (WAF, Nginx, Compose...), đọc repo thực tế, nêu giả định rồi làm, không hỏi lại.
- Yêu cầu "review", "xem có cần cải tiến gì không" hoặc tương tự chỉ là phân tích: trình bày findings/đề xuất rồi dừng, kết thúc bằng câu hỏi "Bạn muốn áp dụng những điểm nào?"; không tự sửa file.
- Luôn hỏi trước khi: thêm/xóa/đổi `branch` hoặc `url` trong `workstation.json`, sửa `hooks`/`permissions` trong `.claude/settings.json`, hoặc sửa một skill dùng chung ảnh hưởng nhiều repo con — vì tác động vượt ra ngoài phạm vi 1 file đang sửa.

### Đơn giản là ưu tiên
- Chỉ viết code đủ giải quyết yêu cầu. Không thêm tính năng suy đoán.
- Không tạo abstraction cho code chỉ dùng một lần.
- Không thêm flexibility hay configurability chưa được yêu cầu.
- Không viết error handling cho tình huống không thể xảy ra.
- Người dùng đã chọn hoặc từ chối một biện pháp (ví dụ qua `AskUserQuestion`) thì không đưa lại biện pháp đó vào code, comment hay tài liệu dưới dạng bước bắt buộc; chỉ nêu rủi ro còn lại một lần.
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
3. In khối `Kết quả định tuyến` (mẫu ở mục `Routing result` của `flex-using-agent-skills`) ngay sau khi chọn skill, trước mọi tool call khác; lời dẫn giữa các tool call không thay thế khối này
4. Đọc và áp dụng từng skill trước khi bắt đầu

Các quy tắc bổ sung:
- Không chọn trực tiếp domain skill, bỏ qua router — trừ khi `flex-using-agent-skills` chính nó hướng dẫn khác.
- Tool đọc đầu tiên (`Read`/`Grep`/`Glob`) trong workspace cũng phải đi sau bước route, kể cả khi định hỏi lại người dùng.
- Nếu không có skill phù hợp, thông báo cho người dùng rồi tiếp tục theo instruction chung.
- Không gọi router đệ quy khi task chính là `flex-using-agent-skills`.
- Trong cùng một workflow, tái sử dụng skill đã chọn nếu phạm vi task không thay đổi.
- Có thể chọn nhiều skill nếu task giao nhau giữa nhiều domain.

## Speckit Workflow (Spec-Before-Code)

Mọi tính năng bắt đầu bằng spec nghiệp vụ trước khi có bất kỳ implementation nào.

### Phân loại task (trước bước 1)

- **Light Track** — bug nhỏ đã có test, hoặc refactor không đổi hành vi: làm trực tiếp kèm test (bug: viết test tái hiện trước; refactor: giữ test hiện có xanh), không cần Speckit. Nếu trong lúc làm phát hiện phải đổi hành vi nghiệp vụ, dừng lại và chuyển sang Spec Track.
- **Spec Track** — feature mới, thay đổi nhiều repo, hoặc thay đổi domain quan trọng: đi Speckit đầy đủ bên dưới.
- Chưa rõ thuộc track nào: hỏi người dùng, không tự chọn.

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
| 2a | `$speckit-docbiz` | `/speckit-docbiz` | **⚠️ Gate bắt buộc trước bước 4** — chạy sau lần cập nhật cuối `spec.md`; chỉ cập nhật doc khi thay đổi ảnh hưởng luồng nghiệp vụ, vai trò, thực thể hoặc phạm vi |
| 3 | `$speckit-checklist [domain]` | `/speckit-checklist [domain]` | **Optional** — tạo checklist domain (ux, security, api) |
| 4 | `$speckit-plan <tech stack + architecture>` | `/speckit-plan <tech stack + architecture>` | Tech stack và architecture được truyền vào đây |
| 5 | `$speckit-tasks` | `/speckit-tasks` | Sinh task list theo dependency order |
| 6 | `$speckit-taskstoissues` | `/speckit-taskstoissues` | **Optional** — chuyển tasks → GitHub Issues |
| 7 | `$speckit-analyze` | `/speckit-analyze` | **Optional** — cross-artifact quality gate trước implement |
| 8 | `$speckit-implement` | `/speckit-implement` | Thực thi tasks; tự dừng nếu checklist còn item chưa tick |
| 9 | `$speckit-converge` | `/speckit-converge` | Nếu còn gap: append task bổ sung vào `tasks.md` → quay lại bước 8 |
| 10 | Spec reconciliation (không có lệnh riêng; người dùng yêu cầu sau khi converged) | Cùng yêu cầu | So hành vi thực tế với `spec.md`: khác thì cập nhật `spec.md` (và `speckit-docbiz` nếu có tác động nghiệp vụ), không khác thì ghi "không đổi"; cả hai đều ghi `Ngày reconcile cuối` |

Skills Speckit nằm tại `.agents/skills/` — source of truth dùng chung cho Codex, Antigravity và Claude Code.

### Gate bắt buộc giữa các bước

**Mỗi lệnh Speckit là một bước riêng biệt do người dùng chủ động gọi.**

- Không tự chuyển sang bước tiếp theo — "Suggested next step" chỉ là thông tin, không tự thực thi.
- `speckit-implement` chỉ chạy khi được gọi trực tiếp.
- "Implement X" hay "thực hiện X" thuộc Spec Track chỉ tương đương bước 1 (`speckit-specify`), không phải toàn pipeline.
- Spec của feature đã `Hoàn thành` là lịch sử; nguồn sự thật là code, test và `docs/business`. Khi spec mâu thuẫn với chúng, tin code/test/docs và báo lệch, không làm theo spec.

## Tooling

| Tool | Mục đích |
| --- | --- |
| `codex` | Codex CLI — chạy tại workstation root qua `OPEN_CODEX.cmd` |
| `rtk` | Proxy CLI giảm 60–90% token output; chi tiết và native-tool-priority xem `tooling/RTK.md` |
| `SYNC_WORKSPACE.cmd` | Bootstrap: clone/pull repos trong manifest, cài tool, sync skill junctions |

`rtk` chỉ dùng cho `git` và shell ops không có native tool thay thế; cấm bọc trong `powershell -Command` hoặc gọi PowerShell cmdlet — chi tiết đầy đủ nằm ở `tooling/RTK.md`, không lặp lại ở đây.

## Quy tắc làm việc

- Không đưa token, mật khẩu, khóa API, connection string hoặc thông tin nhạy cảm vào repo (chặn tự động qua `.claude/hooks/secret-guard.js` trên Write/Edit và `git commit`).
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
