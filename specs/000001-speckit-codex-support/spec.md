# Đặc tả tính năng: Speckit hỗ trợ Codex

**Branch**: `000001-speckit-codex-support`

**Ngày tạo**: 2026-07-07

**Trạng thái**: Bản nháp

**Đầu vào**: Mô tả người dùng: "Mong muốn cập nhật workspace để bộ speckit hỗ trợ cả codex, cập nhật vào 000001"

---

## 0. Tổng quan

Hiện tại, bộ công cụ speckit (quy trình spec-before-code) chỉ hoạt động với Claude Code — toàn bộ skills nằm trong `.claude/skills/` và không được khai báo cho Codex. Khi người dùng làm việc qua Codex CLI, họ không thể chạy luồng speckit thống nhất, vi phạm nguyên tắc Agent-Agnostic Tooling của workspace. Tính năng này cập nhật workspace để Codex cũng có thể sử dụng đầy đủ quy trình speckit — từ specify đến implement — giúp mọi agent đều làm việc theo cùng một tiêu chuẩn.

---

## 1. Mục tiêu

- **MĐ-01**: Người dùng Codex có thể chạy toàn bộ luồng speckit (specify → clarify → plan → tasks → implement) mà không cần chuyển sang Claude Code.
- **MĐ-02**: Workspace thực sự agent-agnostic — cùng một skill source được dùng cho cả Claude Code lẫn Codex, không bị hardcode vào config của một agent.
- **MĐ-03**: Tài liệu hướng dẫn sử dụng speckit cho Codex được cập nhật đầy đủ, đồng bộ với hướng dẫn dành cho Claude Code.

---

## 2. Người dùng & Bối cảnh

**Người dùng chính**: Developer hoặc AI agent (Codex) làm việc trong flex-workstation qua Codex CLI.

**Bối cảnh sử dụng**: Người dùng mở workspace qua `OPEN_CODEX.cmd` và muốn bắt đầu một tính năng mới theo quy trình spec-before-code, hoặc tiếp tục một feature đang dang dở.

**Trình độ kỹ thuật**: Quen thuộc với CLI và quy trình phát triển có cấu trúc (spec → plan → implement).

---

## 3. Kịch bản người dùng *(bắt buộc)*

### Kịch bản 1 — Chạy speckit từ Codex (Ưu tiên: P1)

Developer mở workspace qua Codex CLI, nhập mô tả tính năng mới, và hệ thống dẫn dắt họ qua toàn bộ luồng speckit — từ tạo spec, làm rõ yêu cầu, lập kế hoạch kỹ thuật, đến sinh task list — giống hệt cách Claude Code làm.

**Lý do ưu tiên**: Đây là use-case cốt lõi. Nếu Codex không thể chạy speckit, nguyên tắc Agent-Agnostic Tooling bị vi phạm và workspace không nhất quán.

**Test độc lập**: Mở workspace qua Codex, chạy speckit-specify với một mô tả tính năng bất kỳ, xác nhận spec.md được tạo đúng cấu trúc template.

**Acceptance Scenarios**:

1. **Cho trước** Codex CLI đã mở trong workspace, **Khi** người dùng gọi lệnh speckit-specify với mô tả tính năng, **Thì** hệ thống tạo `specs/<id>/spec.md` với cấu trúc đúng template (## 0 → ## 12 tiếng Việt).
2. **Cho trước** spec.md đã được tạo, **Khi** người dùng tiếp tục với speckit-plan và speckit-tasks, **Thì** plan.md và tasks.md được sinh ra đúng cấu trúc tại cùng feature directory.
3. **Cho trước** Codex đang làm việc, **Khi** người dùng gọi bất kỳ lệnh speckit nào, **Thì** lệnh đó dùng cùng skill source với Claude Code, không có phiên bản song song.

---

### Kịch bản 2 — Tham chiếu tài liệu speckit từ AGENTS.md (Ưu tiên: P2)

Developer Codex cần tham khảo quy trình speckit nhưng hiện tại `AGENTS.md` không có thông tin này. Sau tính năng, `AGENTS.md` có đầy đủ hướng dẫn Development Workflow cho speckit, tương đương với phần đã có trong `CLAUDE.md`.

**Lý do ưu tiên**: Tài liệu là điều kiện để agent chạy đúng quy trình, nhưng chỉ cần thiết khi P1 đã hoàn thành.

**Test độc lập**: Đọc `AGENTS.md`, xác nhận có bảng Development Workflow liệt kê đủ 9 bước speckit.

**Acceptance Scenarios**:

1. **Cho trước** `AGENTS.md` đã được cập nhật, **Khi** đọc file, **Thì** thấy bảng Development Workflow với đầy đủ 9 bước speckit và chú thích tương đương `CLAUDE.md`.

---

### Trường hợp biên

- Điều gì xảy ra khi cùng một skill được cập nhật — thay đổi có áp dụng cho cả Claude Code và Codex không?
- Hệ thống xử lý thế nào khi Codex CLI chưa được cài đặt hoặc không nhận ra cú pháp skill?

---

## 4. Yêu cầu chức năng *(bắt buộc)*

- **YC-001**: Skill source của speckit PHẢI nằm ở vị trí dùng chung, không chỉ trong thư mục riêng của một agent.
- **YC-002**: Codex PHẢI có thể gọi tất cả 9 lệnh speckit: specify, clarify, checklist, plan, tasks, taskstoissues, analyze, implement, converge.
- **YC-003**: Người dùng PHẢI có thể thực hiện toàn bộ luồng specify → implement từ Codex mà không cần chuyển agent.
- **YC-004**: Cấu hình speckit cho Codex KHÔNG ĐƯỢC tạo bản sao nội dung skill — PHẢI tham chiếu đến cùng nguồn với Claude Code.
- **YC-005**: `AGENTS.md` PHẢI có section Development Workflow mô tả 9 bước speckit tương đương nội dung trong constitution.
- **YC-006**: Hệ thống PHẢI đảm bảo khi skill source thay đổi, thay đổi đó tự động có hiệu lực với cả hai agent mà không cần cập nhật thủ công ở hai nơi.

---

## 5. Yêu cầu phi chức năng

- **YCPCK-001**: Thêm Codex support KHÔNG ĐƯỢC làm thay đổi cách Claude Code đang hoạt động — không có regression.
- **YCPCK-002**: Cấu trúc workspace sau thay đổi PHẢI còn rõ ràng — developer mới có thể hiểu luồng trong vòng 5 phút đọc tài liệu.

---

## 7. Tiêu chí thành công *(bắt buộc)*

- **TC-001**: Developer có thể hoàn thành toàn bộ luồng speckit (từ specify đến tasks) từ Codex CLI mà không cần mở Claude Code — đo bằng demo thực tế.
- **TC-002**: Một skill source duy nhất phục vụ cả hai agent — không có nội dung skill bị nhân đôi trong repo.
- **TC-003**: `AGENTS.md` và `CLAUDE.md` đều mô tả đầy đủ 9 bước speckit với thông tin tương đương nhau.

---

## 8. Giả định & Ràng buộc

**Giả định**:
- Codex CLI scans `.agents/skills/` và nhận diện `SKILL.md` — đã xác nhận qua research.
- Người dùng đã có Codex CLI được cài và có thể chạy từ workspace root.
- Skill source hiện tại trong `.claude/skills/` là đúng và đầy đủ — không cần viết lại nội dung skill.
- Workstation chạy trên Windows; Directory Junctions (`mklink /J`) hoạt động không cần quyền admin.

**Ràng buộc**:
- PHẢI tuân thủ Principle III (Agent-Agnostic Tooling): skill source dùng chung tại `skills/`, không hardcode vào config của một agent.
- KHÔNG ĐƯỢC tạo submodule hoặc version link giữa repo.
- KHÔNG ĐƯỢC làm thay đổi hành vi hiện tại của speckit trên Claude Code.

---

## 9. Ngoài phạm vi

- Thêm skill mới hoặc cải tiến nội dung skill hiện có — chỉ làm speckit accessible từ Codex, không thay đổi logic skill.
- Hỗ trợ agent khác ngoài Claude Code và Codex (Copilot, Cursor, v.v.) trong lần này.
- Tự động hóa việc đồng bộ skill khi có cập nhật (CI/CD cho skills).

---

## 10. Rủi ro

| Rủi ro | Khả năng | Tác động | Biện pháp |
|--------|----------|----------|-----------|
| Codex CLI không hỗ trợ cơ chế skill tương đương Claude Code | Trung | Cao | Cần research cơ chế Codex trước khi plan kỹ thuật |
| Thay đổi vị trí skill gây regression cho Claude Code | Thấp | Cao | Chạy smoke test trên Claude Code sau thay đổi |
| Nội dung skill và tài liệu lệch nhau sau khi tách nguồn | Trung | Trung | Xác định rõ single source of truth trong plan |

---

## 11. Phụ thuộc

- Phụ thuộc vào `bootstrap.ps1` — junctions được tạo khi chạy `SYNC_WORKSPACE.cmd`.
- Phụ thuộc vào Codex CLI hỗ trợ `.agents/skills/` (đã xác nhận qua research).

---

## 12. Câu hỏi mở

Đã được làm rõ qua research (2026-07-07):

- **Codex CLI có cơ chế skill riêng**: Codex scans `.agents/skills/` — cùng định dạng `SKILL.md` với Claude Code. Đây là cross-agent standard, không chỉ dùng `AGENTS.md`.
- **Chiến lược tham chiếu**: Claude Code chưa hỗ trợ custom skill path. Giải pháp: dùng Windows Directory Junctions để `.claude/skills/<name>` trỏ về `.agents/skills/<name>`. Bootstrap tự tạo/refresh junctions mỗi lần chạy.
