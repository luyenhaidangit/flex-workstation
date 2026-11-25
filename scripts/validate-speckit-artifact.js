#!/usr/bin/env node
// validate-speckit-artifact.js
// Pure deterministic validation rules for Speckit feature artifacts
// (spec.md, plan.md, tasks.md, checklists/*.md, repos.md).

'use strict';

const fs = require('fs');
const path = require('path');

function stripCodeFences(markdown) {
  return markdown.replace(/```[\s\S]*?```/g, '');
}

function stripChecklistSection(markdown) {
  const lines = markdown.split(/\r?\n/);
  const out = [];
  let skipping = false;
  for (const line of lines) {
    if (/^##\s+Checklist chất lượng trước khi implement\b/i.test(line)) {
      skipping = true;
      continue;
    }
    if (skipping && /^##\s+/.test(line)) {
      skipping = false;
    }
    if (!skipping) out.push(line);
  }
  return out.join('\n');
}

function extractFilePaths(text) {
  const found = new Set();
  for (const m of text.matchAll(/`([^`\s]+\.[a-z0-9]{1,8})`/gi)) {
    found.add(m[1].replace(/\\/g, '/'));
  }
  const withoutBackticks = text.replace(/`[^`]*`/g, ' ');
  for (const m of withoutBackticks.matchAll(/(?:^|[\s(,])(?!(?:https?|ftp):\/\/)([A-Za-z0-9_.\-]+(?:\/[A-Za-z0-9_.\-]+)+\.[a-zA-Z0-9]{1,8})\b/g)) {
    found.add(m[1].replace(/\\/g, '/'));
  }
  return Array.from(found);
}

function countCheckboxes(markdown) {
  const cleaned = stripCodeFences(markdown);
  let total = 0;
  let completed = 0;
  let incomplete = 0;
  const incompleteItems = [];
  for (const line of cleaned.split(/\r?\n/)) {
    const m = line.match(/^\s*-\s*\[([ xX])\]\s*(.+)$/);
    if (!m) continue;
    total++;
    if (m[1].toLowerCase() === 'x') {
      completed++;
    } else {
      incomplete++;
      incompleteItems.push(m[2].trim());
    }
  }
  return { total, completed, incomplete, incompleteItems };
}

function scanChecklists(checklistsDir) {
  if (!fs.existsSync(checklistsDir)) return [];
  const files = fs.readdirSync(checklistsDir).filter((f) => f.endsWith('.md')).sort();
  return files.map((file) => {
    const content = fs.readFileSync(path.join(checklistsDir, file), 'utf8');
    const counts = countCheckboxes(content);
    const uninspectedCount = (stripCodeFences(content).match(/\[Status:\s*Chưa kiểm\]/gi) || []).length;
    return {
      file,
      total: counts.total,
      completed: counts.completed,
      incomplete: counts.incomplete,
      uninspectedCount,
      status: counts.incomplete === 0 && uninspectedCount === 0 ? 'PASS' : 'FAIL',
    };
  });
}

function extractSection(markdown, headingRegex) {
  const lines = markdown.split(/\r?\n/);
  let startIdx = -1;
  let level = 2;
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(/^(#{2,3})\s+(.+)$/);
    if (m && headingRegex.test(m[2].trim())) {
      startIdx = i + 1;
      level = m[1].length;
      break;
    }
  }
  if (startIdx < 0) return null;
  const collected = [];
  for (let i = startIdx; i < lines.length; i++) {
    const m = lines[i].match(/^(#{1,3})\s+/);
    if (m && m[1].length <= level) break;
    collected.push(lines[i]);
  }
  return collected.join('\n');
}

function getDocBizStatus(specText) {
  const sec20 = extractSection(specText, /^20\.\s*Đánh giá tác động tài liệu nghiệp vụ/i);
  if (!sec20) return 'MISSING';
  const m = sec20.match(/\*\*Trạng thái\*\*:\s*([^\r\n]+)/i);
  return m ? m[1].trim() : 'MISSING';
}

function isDocBizPending(status) {
  return /^(CHƯA ĐÁNH GIÁ|CẦN ĐÁNH GIÁ LẠI|MISSING)$/i.test(String(status || '').trim());
}

function getKnownChildRepos(repoRoot) {
  const wsFile = path.join(repoRoot, 'workstation.json');
  if (!fs.existsSync(wsFile)) return [];
  try {
    const ws = JSON.parse(fs.readFileSync(wsFile, 'utf8'));
    if (!ws || !ws.repositories || !Array.isArray(ws.repositories.items)) return [];
    return ws.repositories.items.map((item) => item.name).filter(Boolean);
  } catch {
    return [];
  }
}

function validateStage(paths, stage, options = {}) {
  const errors = [];
  const warnings = [];
  const info = { ACTIVE_FEATURE_DIRECTORY: paths.FEATURE_REL, stage };

  if (!fs.existsSync(paths.FEATURE_SPEC)) {
    errors.push(`spec.md not found at ${paths.FEATURE_SPEC}. Run /speckit-specify first.`);
    return { ok: false, errors, warnings, info };
  }

  const specText = fs.readFileSync(paths.FEATURE_SPEC, 'utf8');
  const cleanedSpec = stripCodeFences(specText);
  const docBizStatus = getDocBizStatus(specText);
  info.docBizStatus = docBizStatus;

  const trackMatch = specText.match(/\*\*Chế độ Spec\*\*:\s*([^\r\n]+)/i);
  info.specMode = trackMatch ? trackMatch[1].trim() : 'Full';

  if (stage === 'specify') {
    for (const token of [
      '[TÊN TÍNH NĂNG]',
      '[NNNNNN-ten-tinh-nang]',
      '[NGÀY]',
      '[Full / Compact]',
      '{{GIT_USER_NAME}}',
      '[Tóm tắt mong muốn người dùng trong 1-2 câu]',
    ]) {
      if (cleanedSpec.includes(token)) {
        errors.push(`spec.md still contains unfilled template token: ${token}`);
      }
    }
    if (!/^(Full|Compact)\b/i.test(info.specMode)) {
      warnings.push(`spec.md **Chế độ Spec** should be "Compact" or "Full" (found "${info.specMode}").`);
    }
    const clarifications = cleanedSpec.match(/\[(NEEDS CLARIFICATION|CẦN LÀM RÕ)[^\]]*\]/gi) || [];
    info.openClarifications = clarifications.length;
    if (clarifications.length > 3) {
      warnings.push(`spec.md has ${clarifications.length} clarification markers (limit is 3).`);
    }
    const reqChecklist = path.join(paths.CHECKLISTS_DIR, 'requirements.md');
    if (!fs.existsSync(reqChecklist)) {
      errors.push('Missing mandatory checklists/requirements.md.');
    } else {
      const reqContent = fs.readFileSync(reqChecklist, 'utf8');
      const uninspected = (stripCodeFences(reqContent).match(/\[Status:\s*Chưa kiểm\]/gi) || []).length;
      if (uninspected > 0) {
        errors.push(`checklists/requirements.md still has ${uninspected} item(s) with [Status: Chưa kiểm]. Evaluate every CHK### item.`);
      }
    }
    info.suggestedNextStep =
      clarifications.length > 0
        ? '/speckit-clarify'
        : isDocBizPending(docBizStatus)
          ? '/speckit-docbiz'
          : '/speckit-plan';
  }

  if (stage === 'plan' || stage === 'tasks' || stage === 'implement' || stage === 'converge') {
    if (isDocBizPending(docBizStatus)) {
      errors.push(`Documentation Impact Gate in spec.md §20 is "${docBizStatus}". Run /speckit-docbiz before planning or downstream steps.`);
    }
    if (!fs.existsSync(paths.IMPL_PLAN)) {
      errors.push(`plan.md not found at ${paths.IMPL_PLAN}. Run /speckit-plan first.`);
      return { ok: errors.length === 0, errors, warnings, info };
    }
    const planText = fs.readFileSync(paths.IMPL_PLAN, 'utf8');
    const cleanedPlan = stripCodeFences(planText);
    for (const token of ['[TÍNH NĂNG]', '[NNNNNN-ten-tinh-nang]', '[NGÀY]', '[Full / Compact]']) {
      if (cleanedPlan.includes(token)) {
        errors.push(`plan.md still contains unfilled placeholder: ${token}`);
      }
    }
    if (planText.includes('# [XÓA NẾU KHÔNG DÙNG]')) {
      errors.push('plan.md still contains sample directory tree marker "# [XÓA NẾU KHÔNG DÙNG]". Replace with real project paths.');
    }
    if (/^Full\b/i.test(info.specMode)) {
      const available = new Set(paths.AVAILABLE_DOCS || []);
      const missingFullDocs = ['research.md', 'quickstart.md'].filter((doc) => !available.has(doc));
      if (missingFullDocs.length > 0) {
        warnings.push(`Spec mode is "Full" but Phase 0/1 artifact(s) are missing: ${missingFullDocs.join(', ')}. Generate them or switch **Chế độ Spec** to "Compact" if single-repo/simple.`);
      }
    }
    const referencedRepos = getKnownChildRepos(paths.REPO_ROOT).filter((repo) => planText.includes(repo));
    if (referencedRepos.length > 0 && !fs.existsSync(paths.REPOS_FILE)) {
      warnings.push(`plan.md references child repo(s) (${referencedRepos.join(', ')}) but ${paths.FEATURE_REL}/repos.md is missing. Run flex-repo-scope to record Edit/Read/Skip scope.`);
    }
    const readinessSec = extractSection(planText, /^Checklist sẵn sàng cho/i);
    if (readinessSec) {
      info.planReadiness = countCheckboxes(readinessSec);
    }
  }

  if (stage === 'tasks' || stage === 'implement' || stage === 'converge') {
    if (!fs.existsSync(paths.TASKS)) {
      errors.push(`tasks.md not found at ${paths.TASKS}. Run /speckit-tasks first.`);
      return { ok: errors.length === 0, errors, warnings, info };
    }
    const tasksText = fs.readFileSync(paths.TASKS, 'utf8');
    const bodyWithoutQualityChecklist = stripChecklistSection(stripCodeFences(tasksText)).replace(/`[^`]*`/g, '');
    for (const token of ['## Example Phases Only', 'TXXX', '[FeatureName]', '[Entity]', '[UseCaseName]']) {
      if (bodyWithoutQualityChecklist.includes(token)) {
        errors.push(`tasks.md still contains template/example placeholder: ${token}`);
      }
    }

    const cleanedTasks = stripChecklistSection(stripCodeFences(tasksText));
    const taskLines = cleanedTasks.split(/\r?\n/).filter((l) => /^\s*-\s*\[[ xX]\]\s+T\d{3,}\b/.test(l));
    const seenIds = new Set();
    const parallelFilesByPhase = new Map();
    let currentPhase = 'root';
    for (const line of cleanedTasks.split(/\r?\n/)) {
      const phaseMatch = line.match(/^##\s+(.+)$/);
      if (phaseMatch) {
        currentPhase = phaseMatch[1].trim();
        continue;
      }
      const tm = line.match(/^\s*-\s*\[([ xX])\]\s+(T\d{3,})\b(.*)$/);
      if (!tm) continue;
      const id = tm[2];
      const rest = tm[3];
      if (seenIds.has(id)) {
        errors.push(`Duplicate task ID in tasks.md: ${id}`);
      }
      seenIds.add(id);

      if (/\[P\]/.test(rest)) {
        const pathMatches = extractFilePaths(rest);
        for (const cleanP of pathMatches) {
          const key = `${currentPhase}::${cleanP}`;
          if (parallelFilesByPhase.has(key)) {
            warnings.push(`Parallel [P] conflict in "${currentPhase}": ${parallelFilesByPhase.get(key)} and ${id} both touch ${cleanP}`);
          } else {
            parallelFilesByPhase.set(key, id);
          }
        }
      }
    }
    info.taskCounts = countCheckboxes(cleanedTasks);
    info.totalNumberedTasks = taskLines.length;
  }

  if (stage === 'implement' || stage === 'converge') {
    const checklists = scanChecklists(paths.CHECKLISTS_DIR);
    info.checklists = checklists;
    const failing = checklists.filter((c) => c.status !== 'PASS');
    if (stage === 'implement' && failing.length > 0) {
      warnings.push(`Incomplete checklists before implementation: ${failing.map((c) => `${c.file} (${c.incomplete} unchecked, ${c.uninspectedCount} uninspected)`).join(', ')}`);
    }
  }

  if (stage === 'converge' && options.verifyClosed) {
    if (info.taskCounts && info.taskCounts.incomplete > 0) {
      errors.push(`Cannot close feature: ${info.taskCounts.incomplete} task(s) remain unchecked in tasks.md.`);
    }
    const statusMatch = specText.match(/\*\*Trạng thái\*\*:\s*([^\r\n]+)/);
    const reconcileMatch = specText.match(/\*\*Ngày reconcile cuối\*\*:\s*([^\r\n]+)/);
    const statusVal = statusMatch ? statusMatch[1].trim() : '';
    const reconcileVal = reconcileMatch ? reconcileMatch[1].trim() : '';
    if (statusVal !== 'Hoàn thành') {
      errors.push(`spec.md **Trạng thái** must be "Hoàn thành" after convergence closeout (found "${statusVal || 'missing'}").`);
    }
    if (!reconcileVal || reconcileVal === 'Chưa reconcile') {
      errors.push(`spec.md **Ngày reconcile cuối** must record reconciliation date & result (found "${reconcileVal || 'missing'}").`);
    }
  }

  return { ok: errors.length === 0, errors, warnings, info };
}

module.exports = {
  stripCodeFences,
  stripChecklistSection,
  extractFilePaths,
  countCheckboxes,
  scanChecklists,
  extractSection,
  getDocBizStatus,
  isDocBizPending,
  validateStage,
};
