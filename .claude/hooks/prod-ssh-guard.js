#!/usr/bin/env node
// prod-ssh-guard.js
// PreToolUse hook for Bash|PowerShell. Classifies commands that ssh into a
// `flex-prod-*` alias through WSL (see .agents/skills/flex-prod-troubleshooting).
//   read-only diagnostics -> allow, restart -> ask, destructive -> deny, anything else -> ask.
// Commands that do not target a flex-prod-* alias are left untouched (exit 0, no output).
// Defense in depth only: the real boundary must be a least-privilege user on the server.

'use strict';

const fs = require('fs');

const ALIAS = /\bflex-prod-[\w-]+/;
const LOCAL = /^\s*wsl(?:\.exe)?\s+(?:-d\s+\S+\s+)?--\s+ssh\s+(?:-o\s+\S+\s+)*(flex-prod-[\w-]+)\s+(.+?)\s*$/s;
const CHAINING = /[;&|`<>\n\r]|\$\(/;
const SENSITIVE = /\.env\b|\.pem\b|id_(?:rsa|ed25519)|\/etc\/(?:shadow|passwd)|secret|password|token/i;

const DENY = [
  /\brm\b|\bmkfs|\bdd\b|\bshutdown\b|\breboot\b|\bpoweroff\b|\bhalt\b|\bkill(?:all)?\b|\bchmod\b|\bchown\b|\bsudo\b/,
  /\bdocker\s+(?:compose\s+)?(?:down|rm|rmi|prune|kill|stop|volume|system)\b/,
  /\bsystemctl\s+(?:stop|disable|mask)\b/,
  /--vacuum|--follow|\s-f\b/,
];

const ALLOW = [
  /^docker\s+(?:ps|images|version|info|top\s+\S+|stats\s+--no-stream(?:\s+\S+)*)(?:\s+-{1,2}[\w-]+(?:[= ]\S+)?)*$/,
  /^docker\s+(?:compose\s+)?logs\s+(?:--tail[= ]\d+\s+|--since[= ]\S+\s+|-t\s+)*\S+$/,
  /^docker\s+compose\s+ps(?:\s+-a)?$/,
  /^systemctl\s+(?:status|is-active|is-enabled|show|list-units)(?:\s+--no-pager|\s+-n\s*\d+|\s+\S+)*$/,
  /^journalctl\s+(?:-u\s+\S+|-n\s*\d+|--since[= ]\S+|--until[= ]\S+|-p\s+\S+|--no-pager)(?:\s+(?:-u\s+\S+|-n\s*\d+|--since[= ]\S+|--until[= ]\S+|-p\s+\S+|--no-pager))*$/,
  /^(?:tail|head)\s+(?:-n\s*\d+\s+|-\d+\s+)?\/var\/log\/[\w./-]+$/,
  /^grep\s+(?:-[ivcE]+\s+)*(?:'[^']*'|"[^"]*"|\S+)\s+\/var\/log\/[\w./-]+$/,
  /^(?:df(?:\s+-h)?|free(?:\s+-m|\s+-h)?|uptime|hostname|date|uname(?:\s+-a)?|nproc|ss\s+-[tlnp]+|ps\s+aux|top\s+-bn1)$/,
];

const RESTART = [
  /^docker\s+restart\s+\S+$/,
  /^docker\s+compose\s+restart(?:\s+\S+)?$/,
  /^systemctl\s+restart\s+\S+$/,
];

function respond(decision, reason) {
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: decision,
      permissionDecisionReason: `prod-ssh-guard: ${reason}`,
    },
  }));
  process.exit(0);
}

function main() {
  let payload;
  try {
    payload = JSON.parse(fs.readFileSync(0, 'utf8'));
  } catch {
    process.exit(0);
  }

  const command = (payload.tool_input && payload.tool_input.command) || '';
  if (!/\bssh\b/.test(command) || !ALIAS.test(command)) process.exit(0);

  const match = LOCAL.exec(command);
  if (!match) {
    respond('deny', 'dùng đúng dạng `wsl -d <distro> -- ssh [-o opt] flex-prod-<alias> \'<lệnh>\'`.');
  }

  let remote = match[2];
  const quoted = /^(['"])(.*)\1$/s.exec(remote);
  if (quoted) remote = quoted[2];
  remote = remote.trim();

  if (CHAINING.test(remote)) respond('ask', 'lệnh remote chứa ký tự nối/redirect, cần người dùng xác nhận.');
  if (DENY.some((re) => re.test(remote))) respond('deny', `lệnh bị chặn trên prod: ${remote}`);
  if (SENSITIVE.test(remote)) respond('ask', 'lệnh có thể đọc secret, cần người dùng xác nhận.');
  if (RESTART.some((re) => re.test(remote))) respond('ask', `restart service trên prod: ${remote}`);
  if (ALLOW.some((re) => re.test(remote))) respond('allow', `lệnh chẩn đoán read-only: ${remote}`);
  respond('ask', `lệnh chưa nằm trong allowlist read-only: ${remote}`);
}

main();
