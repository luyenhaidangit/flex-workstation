#!/usr/bin/env node
// routing-block-guard.js
// Stop hook. Chặn kết thúc lượt khi agent đã dùng tool đọc/sửa file trong lượt này
// nhưng cả session chưa từng in khối `Kết quả định tuyến` (xem AGENTS.md, mục Skill routing bắt buộc).
// Lượt hỏi đáp thuần không gọi tool thì không bị chặn.

'use strict';

const fs = require('fs');

const MARKER = 'Kết quả định tuyến';
const FILE_TOOLS = new Set(['Read', 'Grep', 'Glob', 'Bash', 'Edit', 'Write', 'NotebookEdit']);

function contentOf(entry) {
  const content = entry && entry.message && entry.message.content;
  if (typeof content === 'string') return [{ type: 'text', text: content }];
  return Array.isArray(content) ? content : [];
}

function isRealUserPrompt(entry) {
  if (!entry || entry.type !== 'user' || entry.isMeta) return false;
  const blocks = contentOf(entry);
  const texts = blocks.filter((b) => b.type === 'text' && typeof b.text === 'string');
  if (!texts.length || blocks.some((b) => b.type === 'tool_result')) return false;
  return !texts.every((b) => /^\s*(Base directory for this skill|<system-reminder>)/.test(b.text));
}

function needsRoutingBlock(entries) {
  let lastPrompt = -1;
  entries.forEach((entry, i) => { if (isRealUserPrompt(entry)) lastPrompt = i; });

  const usedFileTool = entries.slice(lastPrompt + 1).some((entry) => (
    entry.type === 'assistant' && contentOf(entry).some((b) => b.type === 'tool_use' && FILE_TOOLS.has(b.name))
  ));
  if (!usedFileTool) return false;

  const printedBlock = entries.some((entry) => (
    entry.type === 'assistant' && contentOf(entry).some((b) => b.type === 'text' && String(b.text).includes(MARKER))
  ));
  return !printedBlock;
}

function main() {
  let payload;
  try {
    payload = JSON.parse(fs.readFileSync(0, 'utf8'));
  } catch {
    process.exit(0);
  }
  if (payload.stop_hook_active || !payload.transcript_path) process.exit(0);

  let entries;
  try {
    entries = fs.readFileSync(payload.transcript_path, 'utf8')
      .split('\n')
      .filter(Boolean)
      .map((line) => JSON.parse(line));
  } catch {
    process.exit(0);
  }

  if (needsRoutingBlock(entries)) {
    process.stderr.write(
      `routing-block-guard: chưa thấy khối \`${MARKER}\` trong session này dù đã dùng tool. ` +
      'In khối đúng mẫu ở mục `Routing result` của flex-using-agent-skills, nêu skill đã chọn cho phạm vi hiện tại, rồi mới kết thúc lượt.\n'
    );
    process.exit(2);
  }
}

main();
