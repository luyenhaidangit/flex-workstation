'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const REPO_ROOT = path.resolve(__dirname, '..');
const secretGuard = require(path.join(REPO_ROOT, '.claude', 'hooks', 'secret-guard.js'));
const validateSkills = require(path.join(REPO_ROOT, 'scripts', 'validate-skills.js'));
const validateSpeckit = require(path.join(REPO_ROOT, 'scripts', 'validate-speckit-artifact.js'));

function runHook(relPath, payload) {
  const scriptPath = path.join(REPO_ROOT, relPath);
  return spawnSync(process.execPath, [scriptPath], {
    input: JSON.stringify(payload),
    encoding: 'utf8',
    env: { ...process.env, CLAUDE_PROJECT_DIR: REPO_ROOT },
  });
}

// ---------------------------------------------------------------------------
// 1. secret-guard.js
// ---------------------------------------------------------------------------
test('secret-guard detects real-looking secrets across supported patterns', () => {
  // Construct test fixtures dynamically so this test file itself never trips secret-guard on commit.
  const samples = [
    ['AWS access key', 'AKIA' + '1234567890ABCDEF'],
    ['private key block', '-----BEGIN ' + 'OPENSSH PRIVATE KEY-----'],
    ['GitHub token', 'ghp_' + 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6'],
    ['AI provider API key', 'sk-ant-' + 'api03-1234567890abcdefghij'],
    ['Google API key', 'AIza' + 'SyA1234567890abcdefghijklmnopqrstuv'],
    ['database URI with password', 'postgresql://' + 'appuser:S3cr3tPass@db.internal:5432/flex'],
    ['connection string password', 'Server=db.local;Database=flex;' + 'Password=Sup3rSecret!;'],
  ];

  for (const [expectedName, sample] of samples) {
    const hit = secretGuard.findSecret(sample);
    assert.ok(hit, `Expected detection for ${expectedName}`);
    assert.equal(hit.name, expectedName);
  }
});

test('secret-guard allows safe placeholders and normal prose', () => {
  const safe = [
    'postgresql://user:<PASSWORD>@localhost:5432/flex',
    'api_key = "YOUR_API_KEY_HERE_1234567890"',
    'Server=localhost;Password=changeme;',
    'Bearer EXAMPLE_TOKEN_12345678901234567890',
    'Regular markdown documentation without credentials.',
  ];
  for (const sample of safe) {
    assert.equal(secretGuard.findSecret(sample), null, `False positive on: ${sample}`);
  }
});

test('secret-guard parses git commit targets including -C and -a flags', () => {
  assert.equal(secretGuard.parseGitCommitCommand('git status', REPO_ROOT), null);

  const plain = secretGuard.parseGitCommitCommand('git commit -m "feat: add test"', REPO_ROOT);
  assert.equal(plain.targetDir, REPO_ROOT);
  assert.equal(plain.includesAll, false);

  const subRepo = secretGuard.parseGitCommitCommand('git -C flex-auth-service commit -am "fix: auth"', REPO_ROOT);
  assert.equal(subRepo.targetDir, path.resolve(REPO_ROOT, 'flex-auth-service'));
  assert.equal(subRepo.includesAll, true);
});

test('secret-guard CLI exits 2 on Write with secret and 0 on clean Write', () => {
  const blocked = runHook('.claude/hooks/secret-guard.js', {
    tool_name: 'Write',
    tool_input: {
      file_path: 'tmp.env',
      content: 'DATABASE_URL=postgres://' + 'admin:RealPass99@10.0.0.5:5432/prod',
    },
  });
  assert.equal(blocked.status, 2);
  assert.match(blocked.stderr, /secret-guard: blocking/);

  const clean = runHook('.claude/hooks/secret-guard.js', {
    tool_name: 'Write',
    tool_input: {
      file_path: 'tmp.md',
      content: 'Hello world',
    },
  });
  assert.equal(clean.status, 0);
});

// ---------------------------------------------------------------------------
// 2. prod-ssh-guard.js
// ---------------------------------------------------------------------------
test('prod-ssh-guard classifies non-prod, read-only, restart, chaining, and destructive commands', () => {
  const nonProd = runHook('.claude/hooks/prod-ssh-guard.js', {
    tool_name: 'Bash',
    tool_input: { command: 'git status' },
  });
  assert.equal(nonProd.status, 0);
  assert.equal(nonProd.stdout.trim(), '');

  const cases = [
    ["wsl -d Ubuntu -- ssh -o BatchMode=yes flex-prod-api 'docker ps'", 'allow'],
    ["wsl -d Ubuntu -- ssh flex-prod-api 'docker restart gateway'", 'ask'],
    ["wsl -d Ubuntu -- ssh flex-prod-api 'docker ps && uptime'", 'ask'],
    ["wsl -d Ubuntu -- ssh flex-prod-api 'rm -rf /tmp/foo'", 'deny'],
    ["ssh flex-prod-api 'docker ps'", 'deny'],
  ];

  for (const [command, expectedDecision] of cases) {
    const res = runHook('.claude/hooks/prod-ssh-guard.js', {
      tool_name: 'Bash',
      tool_input: { command },
    });
    assert.equal(res.status, 0, `Hook should exit 0 with JSON decision for: ${command}`);
    const out = JSON.parse(res.stdout);
    assert.equal(out.hookSpecificOutput.permissionDecision, expectedDecision, `Command: ${command}`);
  }
});

// ---------------------------------------------------------------------------
// 3. skill-format-guard.js & validate-skills.js
// ---------------------------------------------------------------------------
test('skill-format-guard blocks mismatched skill name and allows valid SKILL.md', () => {
  const bad = runHook('.claude/hooks/skill-format-guard.js', {
    tool_name: 'Write',
    tool_input: {
      file_path: path.join(REPO_ROOT, '.agents', 'skills', 'flex-demo', 'SKILL.md'),
      content: '---\nname: wrong-name\ndescription: Use when testing.\n---\n# Demo\n',
    },
  });
  assert.equal(bad.status, 2);
  assert.match(bad.stderr, /does not match the directory name/);

  const good = runHook('.claude/hooks/skill-format-guard.js', {
    tool_name: 'Write',
    tool_input: {
      file_path: path.join(REPO_ROOT, '.agents', 'skills', 'flex-demo', 'SKILL.md'),
      content: '---\nname: flex-demo\ndescription: Demo skill. Use when testing.\n---\n# Demo\n',
    },
  });
  assert.equal(good.status, 0);
});

test('validate-skills enforces line soft limit on flex-* and detects routing table drift', () => {
  const longBody = '---\nname: flex-long\ndescription: Use when testing.\n---\n' + 'line\n'.repeat(405);
  const res = validateSkills.checkSkill('flex-long', longBody, '`flex-long`');
  assert.equal(res.errors.length, 0);
  assert.ok(res.warnings.some((w) => w.includes('400-line')));

  const drift = validateSkills.checkRoutingTableDrift('| Task | `flex-ghost-skill` |\n', ['flex-context-engineering']);
  assert.equal(drift.length, 1);
  assert.match(drift[0], /flex-ghost-skill/);
});

test('routing-block-guard blocks a tool-using turn until the routing block was printed once', () => {
  const os = require('node:os');
  const user = (text) => ({ type: 'user', message: { role: 'user', content: text } });
  const toolUse = { type: 'assistant', message: { role: 'assistant', content: [{ type: 'tool_use', name: 'Read', input: {} }] } };
  const text = (t) => ({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'text', text: t }] } });
  const run = (entries, extra = {}) => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'routing-guard-'));
    const file = path.join(dir, 'transcript.jsonl');
    fs.writeFileSync(file, entries.map((e) => JSON.stringify(e)).join('\n'));
    try {
      return runHook('.claude/hooks/routing-block-guard.js', { transcript_path: file, ...extra });
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  };

  const blocked = run([user('xem file'), toolUse]);
  assert.equal(blocked.status, 2);
  assert.match(blocked.stderr, /Kết quả định tuyến/);

  assert.equal(run([user('xem file'), toolUse], { stop_hook_active: true }).status, 0);
  assert.equal(run([user('hỏi đáp'), text('trả lời thẳng')]).status, 0);
  assert.equal(run([user('xem file'), text('Kết quả định tuyến\n- Primary: none'), toolUse]).status, 0);
  assert.equal(run([user('việc cũ'), text('Kết quả định tuyến'), user('việc mới'), toolUse]).status, 0);
});

// ---------------------------------------------------------------------------
// 4. validate-speckit-artifact.js
// ---------------------------------------------------------------------------
test('validate-speckit-artifact parses checkboxes (ignoring code fences) and docBiz status', () => {
  const md = [
    '- [x] Done item',
    '- [ ] Open item',
    '```markdown',
    '- [ ] Ignored inside fence',
    '```',
  ].join('\n');
  const counts = validateSpeckit.countCheckboxes(md);
  assert.deepEqual({ total: counts.total, completed: counts.completed, incomplete: counts.incomplete }, { total: 2, completed: 1, incomplete: 1 });

  const spec = '## 20. Đánh giá tác động tài liệu nghiệp vụ\n- **Trạng thái**: CHƯA ĐÁNH GIÁ\n';
  assert.equal(validateSpeckit.getDocBizStatus(spec), 'CHƯA ĐÁNH GIÁ');
  assert.equal(validateSpeckit.isDocBizPending('CHƯA ĐÁNH GIÁ'), true);
  assert.equal(validateSpeckit.isDocBizPending('KHÔNG CẦN CẬP NHẬT'), false);
});

// ---------------------------------------------------------------------------
// 5. Repository JSON & hook wiring integrity
// ---------------------------------------------------------------------------
test('shared JSON configs are valid and all referenced Claude hooks exist on disk', () => {
  for (const rel of ['workstation.json', '.claude/settings.json', '.mcp.json']) {
    const raw = fs.readFileSync(path.join(REPO_ROOT, rel), 'utf8');
    assert.doesNotThrow(() => JSON.parse(raw), `${rel} must be valid JSON`);
  }

  const settings = JSON.parse(fs.readFileSync(path.join(REPO_ROOT, '.claude', 'settings.json'), 'utf8'));
  const commands = [];
  for (const groups of Object.values(settings.hooks || {})) {
    for (const group of groups) {
      for (const hook of group.hooks || []) {
        if (hook.command) commands.push(hook.command);
      }
    }
  }

  const referencedHookFiles = commands
    .map((cmd) => cmd.match(/\$\{CLAUDE_PROJECT_DIR\}\/([^\s"']+)/))
    .filter(Boolean)
    .map((m) => m[1]);

  assert.ok(referencedHookFiles.includes('.claude/hooks/prod-ssh-guard.js'), 'prod-ssh-guard.js must be wired in settings.json');
  assert.ok(referencedHookFiles.includes('.claude/hooks/secret-guard.js'), 'secret-guard.js must be wired in settings.json');
  assert.ok(referencedHookFiles.includes('.claude/hooks/skill-format-guard.js'), 'skill-format-guard.js must be wired in settings.json');
  assert.ok(referencedHookFiles.includes('.claude/hooks/routing-block-guard.js'), 'routing-block-guard.js must be wired in settings.json');

  for (const rel of referencedHookFiles) {
    assert.ok(fs.existsSync(path.join(REPO_ROOT, rel)), `Referenced hook missing: ${rel}`);
  }
});
