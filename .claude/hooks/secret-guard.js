#!/usr/bin/env node
// secret-guard.js
// PreToolUse hook enforcing the AGENTS.md NEVER-boundary: "Không đưa token, mật khẩu,
// khóa API, connection string hoặc thông tin nhạy cảm vào repo." Runs on Write/Edit
// (scans the content about to be written) and on Bash/PowerShell `git commit`
// (scans the staged diff), since prose alone does not stop a secret from landing.
//
// Contract: reads the PreToolUse JSON payload from stdin. Exit 2 + a message on
// stderr blocks the tool call; exit 0 allows it. A placeholder-looking match
// (YOUR_, <...>, EXAMPLE, xxx, changeme) is not blocked.

'use strict';

const fs = require('fs');
const { execSync } = require('child_process');

const PATTERNS = [
  { name: 'AWS access key', re: /AKIA[0-9A-Z]{16}/ },
  { name: 'private key block', re: /-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----/ },
  { name: 'Slack token', re: /xox[baprs]-[0-9A-Za-z-]{10,}/ },
  { name: 'GitHub token', re: /gh[pousr]_[A-Za-z0-9]{30,}/ },
  { name: 'bearer token', re: /Bearer\s+[A-Za-z0-9\-_.]{20,}/ },
  { name: 'api/secret key assignment', re: /(api[_-]?key|secret[_-]?key|access[_-]?token|client[_-]?secret)\s*[:=]\s*['"][A-Za-z0-9\-_.=]{16,}['"]/i },
  { name: 'connection string password', re: /(Server|Data Source)=[^;]*;.*?(Password|Pwd)=[^;'"\s]{4,}/i },
];

const PLACEHOLDER_RE = /YOUR_|<[^>]+>|EXAMPLE|PLACEHOLDER|xxxx|changeme/i;

function readStdin() {
  try {
    return fs.readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function findSecret(text) {
  if (typeof text !== 'string' || !text) return null;
  for (const { name, re } of PATTERNS) {
    const match = text.match(re);
    if (match && !PLACEHOLDER_RE.test(match[0])) {
      return { name, snippet: match[0].slice(0, 12) + '…' };
    }
  }
  return null;
}

function repoRoot() {
  return process.env.CLAUDE_PROJECT_DIR || process.cwd();
}

function main() {
  const raw = readStdin();
  let payload;
  try {
    payload = JSON.parse(raw);
  } catch {
    process.exit(0);
  }

  const toolName = payload.tool_name;
  const toolInput = payload.tool_input || {};
  let hit = null;
  let context = '';

  if (toolName === 'Write') {
    hit = findSecret(toolInput.content);
    context = toolInput.file_path || '(write)';
  } else if (toolName === 'Edit') {
    hit = findSecret(toolInput.new_string);
    context = toolInput.file_path || '(edit)';
  } else if (toolName === 'Bash' || toolName === 'PowerShell') {
    const command = toolInput.command || '';
    if (/git\s+commit/.test(command)) {
      let diff = '';
      try {
        diff = execSync('git diff --cached', { cwd: repoRoot(), encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 });
      } catch {
        process.exit(0); // not a git repo, or diff failed — don't block on that
      }
      hit = findSecret(diff);
      context = 'staged changes (git diff --cached)';
    }
  }

  if (hit) {
    console.error(`secret-guard: blocking — looks like a ${hit.name} in ${context} (${hit.snippet}).`);
    console.error('Remove the secret (or use a placeholder like YOUR_API_KEY) before retrying.');
    process.exit(2);
  }

  process.exit(0);
}

main();
