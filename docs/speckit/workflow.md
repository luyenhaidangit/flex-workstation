# Speckit Workflow

Luồng làm việc chuẩn với bộ speckit cho `flex-workstation`.

Ghi chú cú pháp: trong Codex, invoke skill bằng `$speckit-*`; trong runtime hỗ trợ
slash command, dùng `/speckit-*`. Hai dạng trỏ tới cùng một bước workflow.

Mọi tác vụ đều bắt đầu từ workflow Speckit đầy đủ, với `$speckit-specify` hoặc
`/speckit-specify` làm bước mô tả nghiệp vụ đầu tiên.

## Sơ đồ luồng

```mermaid
flowchart TD
    START(["Bắt đầu"])

    %% ── SETUP ──────────────────────────────────────
    subgraph SETUP ["⚙️  Setup — chạy một lần cho project"]
        constitution["$speckit-constitution hoặc /speckit-constitution\nThiết lập nguyên tắc dự án"]
    end

    %% ── PER FEATURE ─────────────────────────────────
    subgraph FEATURE ["🔁  Mỗi feature"]
        specify["$speckit-specify hoặc /speckit-specify\n&lt;mô tả nghiệp vụ — chỉ WHAT + WHY&gt;"]
        docbiz["$speckit-docbiz hoặc /speckit-docbiz\nOptional hook: đồng bộ tài liệu BA"]

        clarify_gate{Còn mơ hồ?}
        clarify["$speckit-clarify hoặc /speckit-clarify\nTối đa 5 câu làm rõ spec"]

        checklist_gate{Cần validate\nrequirements?}
        checklist["$speckit-checklist hoặc /speckit-checklist domain\nTạo checklist ux / security / api"]

        plan["$speckit-plan hoặc /speckit-plan\n&lt;tech stack + architecture&gt;"]

        tasks["$speckit-tasks hoặc /speckit-tasks\nSinh task list theo dependency"]

        issues_gate{Dùng\nGitHub Issues?}
        taskstoissues["$speckit-taskstoissues hoặc /speckit-taskstoissues\nChuyển tasks → GitHub Issues"]

        analyze_gate{Cần quality\ngate?}
        analyze["$speckit-analyze hoặc /speckit-analyze\nCross-artifact consistency check"]

        implement["$speckit-implement hoặc /speckit-implement\nThực thi tasks từng phase"]

        gap_check{Còn gap\ngiữa code và spec?}
        converge["$speckit-converge hoặc /speckit-converge\nAppend task còn thiếu vào tasks.md"]

        specialist_review["Final specialist review\nRoute bằng flex-using-agent-skills\n→ áp dụng skill Flex phù hợp"]

        done(["✅ Feature hoàn thành"])
    end

    %% ── EDGES ───────────────────────────────────────
    START --> constitution
    constitution --> specify

    specify -. after_specify .-> docbiz
    specify --> clarify_gate
    clarify_gate -->|Có| clarify
    clarify_gate -->|Không| checklist_gate
    clarify -. after_clarify .-> docbiz
    clarify --> checklist_gate

    checklist_gate -->|Có| checklist
    checklist_gate -->|Không| plan
    checklist --> plan

    plan --> tasks

    tasks --> issues_gate
    issues_gate -->|Có| taskstoissues
    issues_gate -->|Không| analyze_gate
    taskstoissues --> analyze_gate

    analyze_gate -->|Có| analyze
    analyze_gate -->|Không| implement
    analyze --> implement

    implement --> gap_check
    gap_check -->|Có| converge
    gap_check -->|Không| specialist_review
    converge --> implement
    specialist_review --> done
```

## Bảng commands

| # | Command | Loại | Input | Output |
|---|---------|------|-------|--------|
| 0 | `$speckit-constitution` / `/speckit-constitution` | Core · Setup | Nguyên tắc dự án | `.specify/memory/constitution.md` |
| 1 | `$speckit-specify` / `/speckit-specify` | Core | Mô tả nghiệp vụ (WHAT + WHY) | `specs/<id>/spec.md`, `checklists/requirements.md` |
| 2 | `$speckit-clarify` / `/speckit-clarify` | **Optional** | — | `spec.md` cập nhật (tối đa 5 câu hỏi) |
| 2a | `$speckit-docbiz` / `/speckit-docbiz` | **Optional hook** sau specify/clarify | `spec.md` hiện hành | `docs/business/` cập nhật cho BA/stakeholder |
| 3 | `$speckit-checklist [domain]` / `/speckit-checklist [domain]` | **Optional** | `ux` / `security` / `api` / ... | `checklists/<domain>.md` |
| 4 | `$speckit-plan` / `/speckit-plan` | Core | Tech stack + architecture | `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md` |
| 5 | `$speckit-tasks` / `/speckit-tasks` | Core | — | `tasks.md` |
| 6 | `$speckit-taskstoissues` / `/speckit-taskstoissues` | **Optional** | — | GitHub Issues từ `tasks.md` |
| 7 | `$speckit-analyze` / `/speckit-analyze` | **Optional** | — | Report cross-artifact (read-only) |
| 8 | `$speckit-implement` / `/speckit-implement` | Core | — | Code, mark tasks `[X]` |
| 9 | `$speckit-converge` / `/speckit-converge` | Core | — | Append task còn thiếu vào `tasks.md` |

## Ghi chú quan trọng

**`/speckit-specify` vs `/speckit-plan`**
- `specify` = mô tả **nghiệp vụ** — không có tên framework, ngôn ngữ, database.
- `plan` = quyết định **kỹ thuật** — tech stack, architecture đưa vào đây.

**Tránh tạo trùng short-name khi chạy lại `/speckit-specify`**
- Trước khi tạo feature, `specify` dò các thư mục `specs/*-<short-name>`.
- Nếu đã có một thư mục trùng, command hỏi chọn **cập nhật spec hiện có** hoặc **tạo feature mới**; không tự tăng số thứ tự để tạo bản sao.
- Nếu có nhiều thư mục trùng, command liệt kê các thư mục và yêu cầu chọn một thư mục để cập nhật hoặc xác nhận tạo feature mới.
- Guard này hoàn tất trước khi dispatch bất kỳ `before_specify` hook nào, nên hook tạo branch không thể chạy nhầm feature. Khi chọn cập nhật, `requirements.md` hiện có được giữ lại để re-validate thay vì bị copy đè.

**Chuyển feature đang làm việc**
`feature.json` chỉ lưu một feature mặc định. Khi làm nhiều feature, đặt
`SPECIFY_FEATURE_DIRECTORY` trong từng PowerShell session trước khi gọi command;
biến môi trường này có ưu tiên cao hơn `feature.json`:

```powershell
$env:SPECIFY_FEATURE_DIRECTORY = 'specs/000015-single-broker-pretrade'
```

Sau đó chạy `$speckit-plan`, `$speckit-tasks`, `$speckit-analyze` hoặc command
cần thiết trong cùng session. Các Completion Report luôn bắt đầu bằng
`ACTIVE_FEATURE_DIRECTORY` để xác nhận feature thực tế đã được dùng. Khi muốn trở
lại feature mặc định trong `feature.json`, chạy `Remove-Item Env:SPECIFY_FEATURE_DIRECTORY`.

**`/speckit-clarify` nên chạy trước `/speckit-plan`**
Clarify sửa `spec.md` (chi phí thấp). Nếu chạy sau plan, phát hiện assumption sai
sẽ phải làm lại toàn bộ `plan.md`, `data-model.md`, `contracts/`.

**Đồng bộ tài liệu nghiệp vụ**
`speckit-docbiz` được gợi ý qua optional hook sau `speckit-specify` và
`speckit-clarify` để cập nhật tài liệu BA theo `spec.md` mới nhất. Không gắn hook
sau `speckit-converge` vì command đó chỉ append `tasks.md`, không thay đổi scope
hay `spec.md`.

**Workflow engine legacy**
`.specify/workflows/speckit/workflow.yml` là shortcut legacy, không phải luồng canonical
và không được dùng để thay thế các gate do người dùng chủ động gọi trong tài liệu này.
Nó không đại diện cho các bước optional/hook như clarify, checklist, analyze, converge và
docbiz.

**`/speckit-checklist` là gate cứng của `/speckit-implement`**
Implement tự dừng và hỏi user nếu còn checklist item `[ ]` chưa được tick. Với
`checklists/requirements.md`, item `Status: Không áp dụng` vẫn phải dùng `[x]`:
checkbox xác nhận item đã được review, còn status ghi nhận tiêu chí không áp dụng;
do đó item này không chặn gate. Một `Status: Fail (ngoại lệ đã phê duyệt)` cũng dùng
`[x]`, nhưng phải có fail evidence cùng ngoại lệ được phê duyệt (owner, hạn xử lý,
người phê duyệt và hạn xem lại); chỉ `Status: Fail` chưa phê duyệt dùng `[ ]` và chặn gate.

**"Checklist sẵn sàng cho `/speckit-tasks`" là gate mềm của `/speckit-tasks`**
Trước khi sinh task, `/speckit-tasks` đếm item chưa tick trong mục "Checklist sẵn
sàng cho `/speckit-tasks`" ở `plan.md`. Nếu còn item chưa tick, command dừng và hỏi
user có muốn tiếp tục sinh tasks hay quay lại `/speckit-plan`; nếu mục này không tồn
tại hoặc đã tick hết thì tự động tiếp tục. Đây là gate mềm (hỏi rồi cho phép bỏ qua),
khác với gate cứng của `/speckit-implement` ở trên.

**Traceability Gate của `/speckit-analyze` và `/speckit-converge`**
Hai command phải inventory và kiểm coverage cho `US`/`AC`, `FR`, `BR`, `SEC`,
`NFR` và `SC` có work cần build. `MT` cũng được inventory để kiểm tra trace về
requirement hoặc validation, nhưng KPI nghiệp vụ thuần túy không bắt buộc có code task.

Artifact mới sinh bởi các lệnh Speckit dùng template canonical trong
`.specify/templates/`. Trong `flex-workstation`, toàn bộ template Speckit được
custom để phần người dùng đọc/review dùng tiếng Việt có dấu, còn các định danh
kỹ thuật như command, file path, API, framework, placeholder, `[P]`, `[Story]`,
`CHK###`, `[Gap]`, `[Spec §X]` vẫn giữ nguyên. Không sửa trực tiếp skill gốc
trong `.agents/skills/**` chỉ để đổi ngôn ngữ artifact.

**`/speckit-converge` lặp với `/speckit-implement`**
Converge chỉ **append** task bổ sung vào `tasks.md`, không sửa gì khác.
Sau converge → chạy lại implement → converge cho đến khi báo "✅ Converged".

**Final specialist review sau khi converged**

`✅ Converged` chỉ xác nhận code đã đáp ứng `spec.md`, `plan.md` và `tasks.md`.
Nó không thay thế review theo chuẩn kỹ thuật. Trước khi feature được xem là hoàn
thành hoặc mở PR, tạo một task review cuối; quy tắc workspace sẽ bắt đầu task đó
bằng `flex-using-agent-skills`. Áp dụng mọi skill Flex mà router chọn cho artifact
đã thay đổi. Ví dụ: C# dùng `flex-dotnet-engineering`, migration dùng
`flex-database-engineering`, Angular UI dùng `flex-frontend-engineering`, và thay
đổi tên/backend contract dùng `flex-naming-convention`.

## Artifacts sinh ra theo từng feature

```
specs/
└── 000001-ten-feature/
    ├── spec.md              ← /speckit-specify
    ├── plan.md              ← /speckit-plan
    ├── research.md          ← /speckit-plan (phase 0)
    ├── data-model.md        ← /speckit-plan (phase 1)
    ├── quickstart.md        ← /speckit-plan (phase 1)
    ├── contracts/           ← /speckit-plan (phase 1)
    ├── tasks.md             ← /speckit-tasks  (+converge appends)
    └── checklists/
        ├── requirements.md  ← /speckit-specify (auto)
        ├── ux.md            ← /speckit-checklist ux
        └── security.md      ← /speckit-checklist security

.specify/
└── memory/
    └── constitution.md      ← /speckit-constitution
```
