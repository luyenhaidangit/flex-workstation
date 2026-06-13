---
title: agent-skills (Addy Osmani) — 24 skill kỷ luật cho coding agent
source: https://github.com/addyosmani/agent-skills
type: repo
author: Addy Osmani
date_added: 2026-06-13
tags: [coding-agent, claude-code, workflow, eval]
---

# agent-skills (Addy Osmani) — 24 skill kỷ luật cho coding agent

## Đây là gì
Bộ 24 skill đóng gói quy trình làm việc của senior engineer thành hướng dẫn cho coding agent (Claude Code, Cursor, Gemini CLI, Windsurf...). Mỗi skill là một *workflow agent phải đi theo*, không phải tài liệu tham khảo. Repo đang rất nổi (~57k sao).

## Tại sao đáng chú ý
Coding agent mặc định đi đường ngắn nhất — hay bỏ qua spec, test, security review. Bộ skill này ép kỷ luật bằng **quality gate** và **evidence requirement**: mỗi skill kết thúc bằng yêu cầu bằng chứng (test pass, metric, output) trước khi coi task là xong. "Seems right" không bao giờ đủ.

## Điểm cốt lõi
- **Phủ trọn vòng đời phát triển**, chia theo phase: Define (interview-me, spec-driven) → Plan → Build (TDD, incremental, context-engineering) → Verify → Review (code review, simplification, security, performance) → Ship.
- **Mỗi skill có cấu trúc nhất quán**: overview → process có checkpoint → bảng "rationalizations" (các lý do hay viện ra để bỏ bước + phản biện) → red flags → verification requirements.
- **Verification là bắt buộc**: yêu cầu bằng chứng khách quan, không chấp nhận cảm tính. Có chuẩn giới hạn thay đổi (~100 dòng/lần review).
- **Dựa trên best practice thật**: tham chiếu *Software Engineering at Google* (Hyrum's Law, Beyoncé Rule, Chesterton's Fence, trunk-based development).
- **7 slash command map theo lifecycle**: `/spec`, `/plan`, `/build`, `/test`, `/review`, `/code-simplify`, `/ship`. Có `/build auto` để duyệt plan một lần rồi chạy tự động nhưng vẫn test-driven.

## Cách áp dụng vào công việc
- **Đừng bật cả 24 skill cùng lúc.** Chọn 2-3 skill xử lý đúng điểm yếu hiện tại của bạn (vd hay quên test → `test-driven-development`; PR quá to → `code-review-and-quality` với chuẩn ~100 dòng), đo hiệu quả rồi mới mở rộng.
- **Mượn pattern "evidence requirement"** cho chính các skill nội bộ của bạn: thêm một mục "bằng chứng cần có" ở cuối mỗi quy trình để agent không tự nhận đã xong.
- **Tham khảo bảng "rationalizations"** như một cách viết skill hay: liệt kê lý do hay bị bỏ bước + phản biện, thay vì chỉ ra lệnh cứng nhắc.

## Trích dẫn / đoạn đáng nhớ
> "Verification is non-negotiable. Every skill ends with evidence requirements."

## Liên quan
- Cài cho Claude Code: `/plugin marketplace add addyosmani/agent-skills`
- Xem thêm nguồn coding-agent trong `references/sources.md` của skill ai-insights-curator.
