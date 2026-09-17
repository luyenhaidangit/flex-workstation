#!/usr/bin/env node
// skill-format-guard.js
// PreToolUse hook for Write/Edit on .agents/skills/**/SKILL.md (see .claude/settings.json).
// Computes the content the tool call is about to produce and validates it with
// scripts/validate-skills.js before the write lands, so a name/directory
// mismatch or missing frontmatter is caught before it's committed.
//
// Contract: reads the PreToolUse JSON payload from stdin. Exit 2 + a message
// on stderr blocks the tool call (an ERROR-level issue); exit 0 allows it
// (including when there are only WARN-level issues, which are advisory).

'use strict';

const fs = require('fs');
const path = require('path');

function readStdin() {
  try {
    return fs.readFileSync(0, 'utf8');
  } catch {
    return '';
  }
}

function repoRoot() {
  return process.env.CLAUDE_PROJECT_DIR || path.resolve(__dirname, '..', '..');
}

function applyEditToContent(currentContent, toolInput) {
  const { old_string: oldString, new_string: newString, replace_all: replaceAll } = toolInput;
  if (typeof oldString !== 'string' || typeof newString !== 'string') return null;
  if (!currentContent.includes(oldString)) return null;
  return replaceAll ? currentContent.split(oldString).join(newString) : currentContent.replace(oldString, newString);
}

function main() {
  const raw = readStdin();
  let payload;
  try {
    payload = JSON.parse(raw);
  } catch {
    // Can't parse the hook payload — don't block on something we can't understand.
    process.exit(0);
  }

  const toolName = payload.tool_name;
  const toolInput = payload.tool_input || {};
  const filePath = toolInput.file_path;
  if (!filePath || !/[\\/]\.agents[\\/]skills[\\/][^\\/]+[\\/]SKILL\.md$/.test(filePath)) {
    process.exit(0);
  }

  const dirName = path.basename(path.dirname(filePath));

  let newContent;
  if (toolName === 'Write') {
    newContent = toolInput.content;
  } else if (toolName === 'Edit') {
    let currentContent;
    try {
      currentContent = fs.readFileSync(filePath, 'utf8');
    } catch {
      process.exit(0); // new file via Edit is unusual; don't guess
    }
    newContent = applyEditToContent(currentContent, toolInput);
    if (newContent === null) process.exit(0); // couldn't reconstruct the result — don't block on a guess
  } else {
    process.exit(0);
  }

  if (typeof newContent !== 'string') process.exit(0);

  let validator;
  try {
    validator = require(path.join(repoRoot(), 'scripts', 'validate-skills.js'));
  } catch {
    process.exit(0); // validator missing/broken shouldn't itself block edits
  }

  let routingTableText = null;
  try {
    routingTableText = fs.readFileSync(validator.ROUTING_TABLE_FILE, 'utf8');
  } catch {
    // fine — routing-table check just gets skipped
  }

  const { errors, warnings } = validator.checkSkill(dirName, newContent, routingTableText);

  if (errors.length > 0) {
    console.error(`skill-format-guard: blocking write to ${dirName}/SKILL.md:`);
    for (const e of errors) console.error(`  ERROR: ${e}`);
    for (const w of warnings) console.error(`  WARN: ${w}`);
    console.error('Fix the error(s) above, or see .agents/skills/flex-skill-creator/references/flex-workspace-spec.md.');
    process.exit(2);
  }

  if (warnings.length > 0) {
    console.error(`skill-format-guard: ${dirName}/SKILL.md has advisory warnings (not blocking):`);
    for (const w of warnings) console.error(`  WARN: ${w}`);
  }

  process.exit(0);
}

main();
