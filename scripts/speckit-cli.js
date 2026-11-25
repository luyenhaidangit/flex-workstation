#!/usr/bin/env node
// speckit-cli.js
// Cross-platform (Windows + Linux cloud container) CLI for Speckit feature path
// resolution, phase setup, and artifact validation delegation.
//
// Subcommands:
//   node scripts/speckit-cli.js paths [--feature <ref>] [--pin] [--update-shared] [--json]
//   node scripts/speckit-cli.js check-prereqs [--feature <ref>] [--require-tasks] [--include-tasks] [--paths-only] [--json]
//   node scripts/speckit-cli.js setup-plan [--feature <ref>] [--json]
//   node scripts/speckit-cli.js setup-tasks [--feature <ref>] [--json]
//   node scripts/speckit-cli.js validate [--feature <ref>] --stage <specify|plan|tasks|implement|converge> [--verify-closed] [--json]

'use strict';

const fs = require('fs');
const path = require('path');
const {
  countCheckboxes,
  scanChecklists,
  extractSection,
  getDocBizStatus,
  validateStage,
} = require('./validate-speckit-artifact');

const REPO_ROOT = path.resolve(__dirname, '..');
const SPECIFY_DIR = path.join(REPO_ROOT, '.specify');
const SPECS_DIR = path.join(REPO_ROOT, 'specs');
const LOCAL_FEATURE_FILE = path.join(SPECIFY_DIR, 'feature.local.json');
const SHARED_FEATURE_FILE = path.join(SPECIFY_DIR, 'feature.json');

function parseArgs(argv) {
  const args = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    if (token.startsWith('--')) {
      const key = token.slice(2);
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) {
        args[key] = next;
        i++;
      } else {
        args[key] = true;
      }
    } else {
      args._.push(token);
    }
  }
  return args;
}

function toPosixRelative(absPath) {
  return path.relative(REPO_ROOT, absPath).split(path.sep).join('/');
}

function readJsonSafe(filePath) {
  if (!fs.existsSync(filePath)) return null;
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return null;
  }
}

function saveFeaturePointer(targetFile, absFeatureDir) {
  fs.mkdirSync(SPECIFY_DIR, { recursive: true });
  const rel = toPosixRelative(absFeatureDir);
  const current = readJsonSafe(targetFile);
  if (current && current.feature_directory === rel) return;
  fs.writeFileSync(targetFile, JSON.stringify({ feature_directory: rel }, null, 2) + '\n', 'utf8');
}

function matchFeatureRef(ref) {
  const trimmed = String(ref).trim().replace(/^["']|["']$/g, '');
  if (!trimmed) return null;

  const directCandidate = path.isAbsolute(trimmed) ? trimmed : path.join(REPO_ROOT, trimmed);
  if (fs.existsSync(directCandidate) && fs.statSync(directCandidate).isDirectory()) {
    return path.resolve(directCandidate);
  }

  const inSpecsCandidate = path.join(SPECS_DIR, trimmed);
  if (fs.existsSync(inSpecsCandidate) && fs.statSync(inSpecsCandidate).isDirectory()) {
    return path.resolve(inSpecsCandidate);
  }

  if (!fs.existsSync(SPECS_DIR)) return null;
  const entries = fs
    .readdirSync(SPECS_DIR, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();

  if (/^\d+$/.test(trimmed)) {
    const num = parseInt(trimmed, 10);
    const matches = entries.filter((name) => {
      const m = name.match(/^(\d+)-/);
      return m && parseInt(m[1], 10) === num;
    });
    if (matches.length === 1) return path.join(SPECS_DIR, matches[0]);
  }

  const suffixMatches = entries.filter((name) => name === trimmed || name.endsWith(`-${trimmed}`));
  if (suffixMatches.length === 1) return path.join(SPECS_DIR, suffixMatches[0]);
  if (suffixMatches.length > 1) {
    throw new Error(`Ambiguous feature reference "${trimmed}": matches ${suffixMatches.join(', ')}. Pass full directory name.`);
  }

  return null;
}

function resolveFeaturePaths(options = {}) {
  let featureDir = null;
  let source = null;

  if (options.feature) {
    featureDir = matchFeatureRef(options.feature);
    if (!featureDir) {
      const candidate = path.isAbsolute(options.feature)
        ? options.feature
        : options.feature.startsWith('specs/') || options.feature.startsWith('specs\\')
          ? path.join(REPO_ROOT, options.feature)
          : path.join(SPECS_DIR, options.feature);
      featureDir = path.resolve(candidate);
    }
    source = 'arg';
  } else if (process.env.SPECIFY_FEATURE_DIRECTORY) {
    const raw = process.env.SPECIFY_FEATURE_DIRECTORY.trim();
    featureDir = path.isAbsolute(raw) ? path.resolve(raw) : path.resolve(REPO_ROOT, raw);
    source = 'env';
  } else {
    const localCfg = readJsonSafe(LOCAL_FEATURE_FILE);
    const sharedCfg = readJsonSafe(SHARED_FEATURE_FILE);
    const cfgDir = (localCfg && localCfg.feature_directory) || (sharedCfg && sharedCfg.feature_directory);
    if (cfgDir) {
      featureDir = path.isAbsolute(cfgDir) ? path.resolve(cfgDir) : path.resolve(REPO_ROOT, cfgDir);
      source = localCfg && localCfg.feature_directory ? 'feature.local.json' : 'feature.json';
    }
  }

  if (!featureDir) {
    throw new Error('Feature directory not found. Pass --feature <id>, set SPECIFY_FEATURE_DIRECTORY, or run /speckit-specify first.');
  }

  if (options.pin) saveFeaturePointer(LOCAL_FEATURE_FILE, featureDir);
  if (options.updateShared) saveFeaturePointer(SHARED_FEATURE_FILE, featureDir);

  const branch = process.env.SPECIFY_FEATURE || path.basename(featureDir);
  const contractsDir = path.join(featureDir, 'contracts');
  const checklistsDir = path.join(featureDir, 'checklists');
  const availableDocs = [];
  for (const docName of ['research.md', 'data-model.md', 'quickstart.md', 'repos.md']) {
    if (fs.existsSync(path.join(featureDir, docName))) availableDocs.push(docName);
  }
  if (fs.existsSync(contractsDir) && fs.readdirSync(contractsDir).length > 0) {
    availableDocs.push('contracts/');
  }
  if (options.includeTasks && fs.existsSync(path.join(featureDir, 'tasks.md'))) {
    availableDocs.push('tasks.md');
  }

  return {
    REPO_ROOT,
    BRANCH: branch,
    RESOLUTION_SOURCE: source,
    FEATURE_DIR: featureDir,
    FEATURE_REL: toPosixRelative(featureDir),
    FEATURE_SPEC: path.join(featureDir, 'spec.md'),
    IMPL_PLAN: path.join(featureDir, 'plan.md'),
    TASKS: path.join(featureDir, 'tasks.md'),
    REPOS_FILE: path.join(featureDir, 'repos.md'),
    CONTRACTS_DIR: contractsDir,
    CHECKLISTS_DIR: checklistsDir,
    AVAILABLE_DOCS: availableDocs,
  };
}

function resolveTemplate(templateName) {
  const candidates = [
    path.join(SPECIFY_DIR, 'templates', 'overrides', `${templateName}.md`),
    path.join(SPECIFY_DIR, 'templates', `${templateName}.md`),
  ];
  return candidates.find((c) => fs.existsSync(c)) || null;
}

function outputResult(data, asJson) {
  if (asJson) {
    process.stdout.write(JSON.stringify(data) + '\n');
  } else {
    for (const [k, v] of Object.entries(data)) {
      process.stdout.write(`${k}: ${typeof v === 'object' ? JSON.stringify(v) : v}\n`);
    }
  }
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const sub = args._[0];
  const asJson = Boolean(args.json);

  try {
    if (sub === 'paths') {
      const paths = resolveFeaturePaths({
        feature: args.feature,
        pin: Boolean(args.pin),
        updateShared: Boolean(args['update-shared']),
        includeTasks: true,
      });
      outputResult(paths, asJson);
      return;
    }

    if (sub === 'check-prereqs') {
      const paths = resolveFeaturePaths({
        feature: args.feature,
        pin: Boolean(args.pin),
        includeTasks: Boolean(args['include-tasks']),
      });
      if (args['paths-only']) {
        outputResult(
          {
            REPO_ROOT: paths.REPO_ROOT,
            BRANCH: paths.BRANCH,
            FEATURE_DIR: paths.FEATURE_DIR,
            FEATURE_REL: paths.FEATURE_REL,
            FEATURE_SPEC: paths.FEATURE_SPEC,
            IMPL_PLAN: paths.IMPL_PLAN,
            TASKS: paths.TASKS,
            REPOS_FILE: paths.REPOS_FILE,
          },
          asJson
        );
        return;
      }
      if (!fs.existsSync(paths.FEATURE_SPEC)) {
        throw new Error(`spec.md not found in ${paths.FEATURE_DIR}. Run /speckit-specify first.`);
      }
      if (!fs.existsSync(paths.IMPL_PLAN)) {
        throw new Error(`plan.md not found in ${paths.FEATURE_DIR}. Run /speckit-plan first.`);
      }
      if (args['require-tasks'] && !fs.existsSync(paths.TASKS)) {
        throw new Error(`tasks.md not found in ${paths.FEATURE_DIR}. Run /speckit-tasks first.`);
      }
      outputResult(
        {
          ACTIVE_FEATURE_DIRECTORY: paths.FEATURE_REL,
          FEATURE_DIR: paths.FEATURE_DIR,
          FEATURE_SPEC: paths.FEATURE_SPEC,
          IMPL_PLAN: paths.IMPL_PLAN,
          TASKS: paths.TASKS,
          REPOS_FILE: paths.REPOS_FILE,
          AVAILABLE_DOCS: paths.AVAILABLE_DOCS,
          CHECKLISTS: scanChecklists(paths.CHECKLISTS_DIR),
        },
        asJson
      );
      return;
    }

    if (sub === 'setup-plan') {
      const paths = resolveFeaturePaths({ feature: args.feature, pin: Boolean(args.pin) });
      if (!fs.existsSync(paths.FEATURE_SPEC)) {
        throw new Error(`spec.md not found in ${paths.FEATURE_DIR}. Run /speckit-specify first.`);
      }
      const specText = fs.readFileSync(paths.FEATURE_SPEC, 'utf8');
      const docBizStatus = getDocBizStatus(specText);
      if (docBizStatus === 'CHƯA ĐÁNH GIÁ' || docBizStatus === 'MISSING') {
        console.error(`ERROR: Documentation Impact Gate in spec.md §20 is "${docBizStatus}". Run /speckit-docbiz before /speckit-plan.`);
        process.exit(2);
      }
      fs.mkdirSync(paths.FEATURE_DIR, { recursive: true });
      let copiedTemplate = false;
      if (!fs.existsSync(paths.IMPL_PLAN)) {
        const tpl = resolveTemplate('plan-template');
        if (!tpl) throw new Error('plan-template.md not found under .specify/templates/.');
        fs.copyFileSync(tpl, paths.IMPL_PLAN);
        copiedTemplate = true;
      }
      const trackMatch = specText.match(/\*\*Chế độ Spec\*\*:\s*([^\r\n]+)/i);
      outputResult(
        {
          ACTIVE_FEATURE_DIRECTORY: paths.FEATURE_REL,
          FEATURE_SPEC: paths.FEATURE_SPEC,
          IMPL_PLAN: paths.IMPL_PLAN,
          SPECS_DIR: paths.FEATURE_DIR,
          REPOS_FILE: paths.REPOS_FILE,
          REPOS_EXISTS: fs.existsSync(paths.REPOS_FILE),
          SPEC_MODE: trackMatch ? trackMatch[1].trim() : 'Full',
          DOCBIZ_STATUS: docBizStatus,
          COPIED_TEMPLATE: copiedTemplate,
          BRANCH: paths.BRANCH,
        },
        asJson
      );
      return;
    }

    if (sub === 'setup-tasks') {
      const paths = resolveFeaturePaths({ feature: args.feature, pin: Boolean(args.pin) });
      if (!fs.existsSync(paths.FEATURE_SPEC)) {
        throw new Error(`spec.md not found in ${paths.FEATURE_DIR}. Run /speckit-specify first.`);
      }
      if (!fs.existsSync(paths.IMPL_PLAN)) {
        throw new Error(`plan.md not found in ${paths.FEATURE_DIR}. Run /speckit-plan first.`);
      }
      const tpl = resolveTemplate('tasks-template');
      if (!tpl) throw new Error('tasks-template.md not found under .specify/templates/.');
      const planText = fs.readFileSync(paths.IMPL_PLAN, 'utf8');
      const readinessSec = extractSection(planText, /^Checklist sẵn sàng cho/i);
      const readiness = readinessSec ? countCheckboxes(readinessSec) : { total: 0, completed: 0, incomplete: 0, incompleteItems: [] };
      outputResult(
        {
          ACTIVE_FEATURE_DIRECTORY: paths.FEATURE_REL,
          FEATURE_DIR: paths.FEATURE_DIR,
          TASKS_TEMPLATE: tpl,
          AVAILABLE_DOCS: paths.AVAILABLE_DOCS,
          PLAN_READINESS: readiness,
        },
        asJson
      );
      return;
    }

    if (sub === 'validate') {
      const stage = args.stage || 'specify';
      const paths = resolveFeaturePaths({ feature: args.feature });
      const res = validateStage(paths, stage, { verifyClosed: Boolean(args['verify-closed']) });
      if (asJson) {
        process.stdout.write(JSON.stringify(res) + '\n');
      } else {
        console.log(`[speckit-validate] Feature: ${res.info.ACTIVE_FEATURE_DIRECTORY} | Stage: ${stage} | Result: ${res.ok ? 'PASS' : 'FAIL'}`);
        for (const e of res.errors) console.error(`  ERROR: ${e}`);
        for (const w of res.warnings) console.warn(`  WARN: ${w}`);
      }
      process.exit(res.ok ? 0 : 1);
    }

    console.error('Usage: node scripts/speckit-cli.js <paths|check-prereqs|setup-plan|setup-tasks|validate> [options]');
    process.exit(1);
  } catch (err) {
    console.error(`ERROR: ${err.message}`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { resolveFeaturePaths, resolveTemplate, countCheckboxes, scanChecklists, validateStage };
