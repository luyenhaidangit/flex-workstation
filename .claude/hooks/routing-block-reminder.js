#!/usr/bin/env node
// routing-block-reminder.js
// PostToolUse hook cho tool Skill (xem .claude/settings.json).
// Ngay sau khi agent nạp flex-using-agent-skills hoặc flex-repo-scope, chèn lời nhắc
// in đúng khối mẫu vào ngữ cảnh, vì agent hay diễn đạt lại khối thành văn xuôi.
//
// Contract: đọc JSON PostToolUse từ stdin; in JSON additionalContext ra stdout, exit 0.
// Không chặn tool call; skill khác thì không in gì.

'use strict';

const fs = require('fs');

const REMINDERS = {
  'flex-using-agent-skills': [
    'NHẮC BẮT BUỘC: ngay lúc này, trước mọi tool call khác, in đúng khối 5 dòng riêng biệt này (điền giá trị, giữ nguyên nhãn):',
    'Kết quả định tuyến',
    '- Primary: <skill hoặc none>',
    '- Additional: <danh sách skill hoặc none>',
    '- Lý do: <một câu>',
    '- Cần định tuyến lại: <có chỉ khi phạm vi đã đổi; ngược lại không>',
    'Không viết văn xuôi một câu thay cho khối này, không đổi nhãn, không gọi skill là "repo".',
  ],
  'flex-repo-scope': [
    'NHẮC BẮT BUỘC: trước add_repo đầu tiên, in đúng khối này (điền giá trị, giữ nguyên nhãn và 5 dòng):',
    'Kế hoạch repo',
    '- Edit: <repos hoặc none>',
    '- Read: <repos hoặc none>',
    '- Skip: <repos, một mệnh đề lý do>',
    '- Giả định: <suy luận người dùng cần sửa>',
    'Repo trong danh sách Preload chỉ cần một dòng; các repo khác vẫn dùng đủ khối.',
  ],
};

function main() {
  let payload;
  try {
    payload = JSON.parse(fs.readFileSync(0, 'utf8'));
  } catch {
    return;
  }
  if (!payload || payload.tool_name !== 'Skill') return;
  const skill = String((payload.tool_input && payload.tool_input.skill) || '').replace(/^\//, '');
  const lines = REMINDERS[skill];
  if (!lines) return;
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PostToolUse',
      additionalContext: lines.join('\n'),
    },
  }));
}

main();
