# MEMORY.md

Ghi chú làm việc tích lũy qua các phiên AI agent trong `flex-workstation`. Khác với `CLAUDE.md` (quy tắc/convention chuẩn hóa), file này là nhật ký các bài học/quyết định cụ thể đã xảy ra — giữ để không lặp lại lỗi hoặc mất context giữa các phiên/người dùng khác nhau. Cập nhật file này khi rút ra bài học mới đáng chia sẻ cho cả team.

## Quy tắc rút ra từ feedback

### Review trước, apply sau
Khi user nói "review xem có cần cải tiến gì không" hoặc tương tự, chỉ trình bày danh sách findings/đề xuất rồi DỪNG lại chờ quyết định — không tự áp dụng.

**Why:** Có lần user hỏi review speckit flow, agent tự áp dụng HARD STOP vào 4 skill file mà không hỏi; user phải nhắc lại họ chỉ muốn review.

**How to apply:** Phân biệt rõ "review/phân tích" vs "implement/áp dụng". Sau khi trình bày findings, kết thúc bằng câu hỏi "Bạn muốn áp dụng những điểm nào?" thay vì tự làm.

### Sửa skill đúng chỗ — không sửa bản cài local
Khi sửa nội dung skill (SKILL.md, template, script), luôn tìm và sửa bản có git trong repo trước: `.agents/skills/<skill-name>/` (skill dùng chung của workstation) hoặc `<repo-con>/skills/<skill-name>/` nếu skill thuộc một repo con cụ thể (vd. `dotnet-conventions` thuộc `flex-agents/skills/dotnet-conventions/`, không phải workstation tự sở hữu). KHÔNG sửa trực tiếp bản cài local tại `~/.claude/skills/<skill-name>/` hay `~/.codex/skills/<skill-name>/` — các thư mục này không git-track, thay đổi sẽ không review/commit được và biến mất khi resync.

**Why:** Agent từng sửa thẳng `~/.claude/skills/dotnet-conventions/...` khi được yêu cầu thêm Response Envelope vào scaffold template; user phải chỉ lại đường dẫn đúng (`flex-agents/skills/dotnet-conventions/...`) và xác nhận đây là lỗi lặp lại nhiều lần.

**How to apply:** Trước khi Write/Edit bất kỳ file nào dưới `~/.claude/skills/` hoặc `~/.codex/skills/`, dừng lại và Glob/Grep toàn bộ `flex-workstation/` (kể cả các repo con) để tìm bản gốc có git trước. Chỉ chấp nhận sửa ở thư mục local nếu đã xác nhận qua tìm kiếm — không suy đoán — rằng không có bản repo tương ứng.

### RTK docs sync từ repo
RTK documentation có source-of-truth trong repo (`scripts/templates/rtk-codex.md` → `~/.codex/RTK.md`, `scripts/templates/rtk-claude.md` → `~/.claude/RTK.md`), sync qua `scripts/bootstrap.ps1` hoặc `scripts/ensure-rtk.ps1`.

**Why:** File local là artifact được generate — sửa trực tiếp sẽ bị overwrite lần bootstrap tiếp theo.

**How to apply:** Khi user yêu cầu sửa RTK docs (anti-pattern, mapping, hướng dẫn shell...), luôn sửa file template trong repo, không sửa `~/.claude/RTK.md` hay `~/.codex/RTK.md` trực tiếp.

## Kiến thức project

### Vị trí repo con
Các repo con nằm **bên trong** `C:\Workspace\Project\flex-workstation\`, không phải song song tại `C:\Workspace\Project\`. Ví dụ: `flex-environment` đúng là `C:\Workspace\Project\flex-workstation\flex-environment`, không phải `C:\Workspace\Project\flex-environment` (repo standalone cũ, dễ nhầm).

**How to apply:** Trước khi edit bất kỳ file nào trong repo con, luôn xác nhận path bắt đầu bằng `C:\Workspace\Project\flex-workstation\<repo-con>`.

### Oracle đang được loại bỏ dần
Từ 2026-07-12, hệ thống Flex **không dùng Oracle nữa** và đang refactor dần các repo phụ thuộc Oracle (vd. `flex-auth-service` hiện dùng `UseOracle` + Oracle Wallet trong `EntityFrameworkCoreExtensions.cs`) sang MySQL (tenant) / PostgreSQL (shared, control-plane). Repo `flex-database` chứa migration/schema script dùng chung cho các DB mới — vai trò kho script, không phải service chạy được.

**Why:** User xác nhận trực tiếp: "dùng để migrate script data các db... trước đây dùng oracle nhưng từ này sẽ không dùng nữa, sẽ refactor lại toàn bộ code repos này migrate dần dần."

**How to apply:** Khi làm việc trong `flex-auth-service` hoặc repo còn tham chiếu Oracle, không giả định Oracle là hướng đi lâu dài — hỏi lại nếu task liên quan đến mở rộng phụ thuộc Oracle. Migration script mới nên đặt vào `flex-database`. Việc refactor là "dần dần" — không giả định đã hoàn tất trừ khi xác nhận.
