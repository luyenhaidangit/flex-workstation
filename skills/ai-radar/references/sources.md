# Nguồn AI để radar quét

Danh sách nguồn chất lượng nhóm theo chủ đề. Skill đọc file này để biết cần fetch ở đâu khi chạy.

## Coding agent & Claude Code
- **Anthropic Engineering blog** — https://www.anthropic.com/engineering — bài sâu về agent design, context, eval.
- **addyosmani/agent-skills** (GitHub) — https://github.com/addyosmani/agent-skills — bộ skill đóng gói kỷ luật cho coding agent.
- **Awesome Claude Code** (GitHub, search `awesome-claude-code`) — tổng hợp tool & skill cộng đồng.

## Agent design & patterns
- **Anthropic "Building effective agents"** — https://www.anthropic.com/research/building-effective-agents — pattern thiết kế agent (chaining, routing, orchestrator).
- **LangChain blog** — https://blog.langchain.dev — pattern RAG, tool use, memory (đọc có chọn lọc).

Ghi chú: nguồn evergreen như tài liệu nền tảng hoặc bài pattern chỉ dùng làm bối cảnh/đối chiếu; không tính là item "mới" trừ khi có ngày cập nhật mới hoặc thay đổi đáng chú ý được xác minh.

## Prompting & LLM fundamentals
- **Anthropic prompt engineering docs** — https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering
- **Prompt engineering guide** — https://www.promptingguide.ai

## Tin tức & xu hướng
- **GitHub Trending** — https://github.com/trending — lọc theo ngày/tuần; nơi repo AI nổi lên sớm nhất.
- **Hacker News** — https://news.ycombinator.com — thảo luận kỹ thuật (đọc comment hơn tiêu đề).
- **Simon Willison's blog** — https://simonwillison.net — ghi chú thực dụng về LLM/tooling, cập nhật dày.

## MCP & tooling
- **Model Context Protocol docs** — https://modelcontextprotocol.io
- **MCP servers registry** — https://github.com/modelcontextprotocol/servers — server mẫu để tích hợp.

## Mapping tag → nhóm nguồn ưu tiên
- `claude-code`, `coding-agent` → Coding agent & Claude Code
- `agent-design`, `RAG` → Agent design & patterns
- `prompting`, `llm-fundamentals` → Prompting & LLM fundamentals
- `mcp`, `tooling` → MCP & tooling
- (không có tag / tổng quát) → Tin tức & xu hướng + tất cả nhóm
