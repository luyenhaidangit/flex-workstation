#!/usr/bin/env node
// validate-skills.js
// Checks flex-* skills under .agents/skills/ against the house style documented
// in .agents/skills/flex-skill-creator/references/flex-workspace-spec.md.
//
// Usage:
//   node scripts/validate-skills.js              # validate every skill
//   node scripts/validate-skills.js <skill-name> # validate one skill
//
// Exit code: 1 if any skill has an ERROR-level issue, 0 otherwise (warnings
// never fail the run — this mirrors the "observed house style, not a rigid
// spec" stance in flex-workspace-spec.md).

'use strict';

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const SKILLS_DIR = path.join(REPO_ROOT, '.agents', 'skills');
const ROUTING_TABLE_FILE = path.join(SKILLS_DIR, 'flex-using-agent-skills', 'SKILL.md');

// Meta/routing skills whose real shape doesn't fit the house section set —
// documented exemptions, not silent ones. Add an entry here (with a reason)
// the same way a skill's own SKILL.md would call out a deviation.
const SECTION_EXEMPT_SKILLS = {
  'flex-skill-creator': 'meta-skill for creating other skills; uses its own lifecycle-shaped sections',
  'flex-using-agent-skills': 'routing skill; uses a routing-table shape instead of the engineering-skill sections',
};

const REQUIRED_SECTIONS = ['## Overview', '## When to Use', '## Common Rationalizations', '## Red Flags', '## Verification'];
const USE_WHEN_PATTERN = /\buse (when|during|before|after)\b/i;
const DESCRIPTION_SOFT_LIMIT = 1024;

function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return null;
  const fm = match[1];
  const nameMatch = fm.match(/^name:\s*(.*)$/m);
  const descMatch = fm.match(/^description:\s*(.*)$/m);
  // description may be a plain one-liner or start a folded/quoted block —
  // for the length/content checks we only need the raw remainder of fm
  // after "description:", which covers both cases well enough to check for
  // a "Use when" clause and to measure rough length.
  const descRestMatch = fm.match(/^description:\s*([\s\S]*)$/m);
  return {
    name: nameMatch ? nameMatch[1].trim().replace(/^["']|["']$/g, '') : null,
    descriptionFirstLine: descMatch ? descMatch[1].trim() : null,
    descriptionFull: descRestMatch ? descRestMatch[1].trim() : null,
  };
}

/**
 * Validate one skill's SKILL.md content against the house style.
 * @param {string} dirName - the skill's directory name (source of truth for `name:`)
 * @param {string} content - the full SKILL.md text (current or proposed)
 * @param {string} [routingTableText] - flex-using-agent-skills/SKILL.md content, for the routing check
 * @returns {{errors: string[], warnings: string[]}}
 */
function checkSkill(dirName, content, routingTableText) {
  const errors = [];
  const warnings = [];
  const isHouseStyle = dirName.startsWith('flex-');

  const fm = parseFrontmatter(content);
  if (!fm) {
    errors.push('Missing or malformed YAML frontmatter (expected a --- name/description block at the top of the file).');
    return { errors, warnings };
  }

  if (!fm.name) {
    errors.push('Frontmatter is missing a `name:` field.');
  } else if (fm.name !== dirName) {
    errors.push(`\`name:\` frontmatter ("${fm.name}") does not match the directory name ("${dirName}").`);
  }

  if (!fm.descriptionFull) {
    errors.push('Frontmatter is missing a `description:` field.');
  } else {
    if (isHouseStyle && !USE_WHEN_PATTERN.test(fm.descriptionFull)) {
      warnings.push('`description:` has no literal "Use when/during/before/after ..." clause (house style for flex-* skills).');
    }
    if (fm.descriptionFull.length > DESCRIPTION_SOFT_LIMIT) {
      warnings.push(`\`description:\` is ${fm.descriptionFull.length} characters, above the ${DESCRIPTION_SOFT_LIMIT}-character range observed across this repo's flex-* skills.`);
    }
  }

  if (isHouseStyle && !SECTION_EXEMPT_SKILLS[dirName]) {
    const missing = REQUIRED_SECTIONS.filter((h) => !content.includes(h));
    if (missing.length > 0) {
      warnings.push(`Missing house section(s): ${missing.join(', ')} (or an equivalent heading serving the same purpose — see flex-workspace-spec.md).`);
    }
  }

  if (isHouseStyle && dirName !== 'flex-using-agent-skills' && routingTableText) {
    const inRoutingTable = routingTableText.includes(`\`${dirName}\``);
    if (!inRoutingTable) {
      warnings.push(`Not found in flex-using-agent-skills's routing table — the skill may be invisible under this workspace's mandatory routing rule.`);
    }
  }

  return { errors, warnings };
}

function listSkillDirs() {
  return fs
    .readdirSync(SKILLS_DIR, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();
}

function main() {
  const only = process.argv[2];
  const dirs = only ? [only] : listSkillDirs();
  const routingTableText = fs.existsSync(ROUTING_TABLE_FILE) ? fs.readFileSync(ROUTING_TABLE_FILE, 'utf8') : null;

  let hadError = false;
  let hadWarning = false;

  for (const dirName of dirs) {
    const skillFile = path.join(SKILLS_DIR, dirName, 'SKILL.md');
    if (!fs.existsSync(skillFile)) {
      console.error(`[${dirName}] SKILL.md not found at ${skillFile}`);
      hadError = true;
      continue;
    }
    const content = fs.readFileSync(skillFile, 'utf8');
    const { errors, warnings } = checkSkill(dirName, content, routingTableText);

    if (errors.length === 0 && warnings.length === 0) {
      console.log(`[${dirName}] OK`);
      continue;
    }
    for (const e of errors) {
      console.error(`[${dirName}] ERROR: ${e}`);
      hadError = true;
    }
    for (const w of warnings) {
      console.warn(`[${dirName}] WARN: ${w}`);
      hadWarning = true;
    }
  }

  if (!hadError && !hadWarning) {
    console.log('\nAll skills pass.');
  } else {
    console.log(`\n${hadError ? 'FAILED' : 'Passed with warnings'} — errors block, warnings are advisory (see flex-workspace-spec.md).`);
  }

  process.exit(hadError ? 1 : 0);
}

if (require.main === module) {
  main();
}

module.exports = { checkSkill, parseFrontmatter, listSkillDirs, SECTION_EXEMPT_SKILLS, SKILLS_DIR, ROUTING_TABLE_FILE };
