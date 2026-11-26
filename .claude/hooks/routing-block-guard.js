#!/usr/bin/env node
// routing-block-guard.js
// PreToolUse hook. Chặn tool đọc/sửa file đầu tiên nếu agent chưa in khối `Kết quả định tuyến`
// (xem AGENTS.md, mục Skill routing bắt buộc). Tool `Skill` không bị chặn vì cần đọc router trước khi in khối.
// Lượt hỏi đáp thuần không gọi tool thì không bị ảnh hưởng. Subagent bỏ qua vì transcript của chúng tách riêng.

'use strict';

const fs = require('fs');

const MARKER = 'Kết quả định tuyến';

function contentOf(entry) {
  const content = entry && entry.message && entry.message.content;
  if (typeof content === 'string') return [{ type: 'text', text: content }];
  return Array.isArray(content) ? content : [];
}

function hasPrintedBlock(entries) {
  return entries.some((entry) => (
    entry.type === 'assistant' && contentOf(entry).some((b) => b.type === 'text' && String(b.text).includes(MARKER))
  ));
}

function main() {
  let payload;
  try {
    payload = JSON.parse(fs.readFileSync(0, 'utf8'));
  } catch {
    process.exit(0);
  }
  if (payload.agent_id || !payload.transcript_path) process.exit(0);

  let entries;
  try {
    entries = fs.readFileSync(payload.transcript_path, 'utf8')
      .split('\n')
      .filter(Boolean)
      .map((line) => JSON.parse(line));
  } catch {
    process.exit(0);
  }

  if (!hasPrintedBlock(entries)) {
    process.stderr.write(
      `routing-block-guard: chưa thấy khối \`${MARKER}\` trước tool này. ` +
      'Đọc router bằng Skill `flex-using-agent-skills`, in khối đúng mẫu ở mục `Routing result` ' +
      '(nêu skill đã chọn) ngay trong văn bản của lượt này, rồi mới gọi lại tool.\n'
    );
    process.exit(2);
  }
}

main();
