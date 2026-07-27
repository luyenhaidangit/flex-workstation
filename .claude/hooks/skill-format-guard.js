#!/usr/bin/env node
// skill-format-guard.js — PreToolUse hook for Write|Edit.
//
// Blocks direct hand-edits to flex-agents/skills/*/SKILL.md that would not
// pass flex-agents/scripts/validate-skills.js. Registered from
// flex-workstation/.claude/settings.json (the session's actual project
// root) rather than flex-agents/hooks/hooks.json, because that plugin-scoped
// config only fires when flex-agents is installed as a Claude Code plugin,
// not when it's a nested repo chatted into from the workstation root.
//
// Runs BEFORE the write lands, so it reconstructs the proposed file content
// from tool_input (Write: full content; Edit: old_string/new_string applied
// to the current file) and validates an isolated single-skill copy — the
// real file on disk is never touched by this hook.

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');

function readStdin() {
  try {
    return fs.readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function main() {
  let input;
  try {
    input = JSON.parse(readStdin() || '{}');
  } catch {
    return; // malformed hook input — never block on our own parsing failure
  }

  const toolName = input.tool_name;
  if (toolName !== 'Write' && toolName !== 'Edit') return;

  const toolInput = input.tool_input || {};
  const filePath = toolInput.file_path;
  if (!filePath) return;

  const normalized = filePath.replace(/\\/g, '/');
  const match = normalized.match(/flex-agents\/skills\/([^/]+)\/SKILL\.md$/);
  if (!match) return;
  const skillName = match[1];

  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const validatorPath = path.join(projectDir, 'flex-agents', 'scripts', 'validate-skills.js');
  if (!fs.existsSync(validatorPath)) return; // validator not present, nothing to enforce

  let newContent;
  if (toolName === 'Write') {
    if (typeof toolInput.content !== 'string') return;
    newContent = toolInput.content;
  } else {
    const oldString = toolInput.old_string;
    const newString = toolInput.new_string;
    if (typeof oldString !== 'string' || typeof newString !== 'string') return;

    let current;
    try {
      current = fs.readFileSync(filePath, 'utf8');
    } catch {
      return; // file doesn't exist yet — Edit will fail on its own, not our concern
    }

    if (toolInput.replace_all) {
      newContent = current.split(oldString).join(newString);
    } else {
      const idx = current.indexOf(oldString);
      if (idx === -1) return; // Edit tool itself will error on this
      newContent = current.slice(0, idx) + newString + current.slice(idx + oldString.length);
    }
  }

  const tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'skill-guard-'));
  const tmpSkillsDir = path.join(tmpRoot, 'skills');
  const tmpSkillDir = path.join(tmpSkillsDir, skillName);
  let output = '';
  let failed = false;

  try {
    fs.mkdirSync(tmpSkillDir, { recursive: true });
    fs.writeFileSync(path.join(tmpSkillDir, 'SKILL.md'), newContent, 'utf8');
    output = execFileSync('node', [validatorPath, tmpSkillsDir], { encoding: 'utf8' });
  } catch (err) {
    failed = true;
    output = ((err && err.stdout) || '') + ((err && err.stderr) || '') + ((err && !err.stdout && !err.stderr) ? String(err.message) : '');
  } finally {
    fs.rmSync(tmpRoot, { recursive: true, force: true });
  }

  if (failed) {
    process.stderr.write(
      `[skill-format-guard] "${skillName}/SKILL.md" would not pass flex-agents/scripts/validate-skills.js:\n\n` +
      output +
      `\nSkills under flex-agents/skills/ must follow flex-agents/docs/skill-anatomy.md. Use the ` +
      `flex-skill-creator skill (flex-agents/skills/flex-skill-creator/SKILL.md) to create or fix this ` +
      `skill instead of hand-editing it, or — if the deviation is intentional — add a documented entry ` +
      `to SECTION_EXEMPT_SKILLS in flex-agents/scripts/validate-skills.js first.\n`
    );
    process.exitCode = 2;
    return;
  }
}

main();
