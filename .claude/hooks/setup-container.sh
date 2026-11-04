#!/bin/bash
# Tạo .claude/skills -> ../.agents/skills (junction trên Windows không nằm trong git)
set -e
ROOT="${CLAUDE_PROJECT_DIR:-/home/user/flex-workstation}"
if [ -d "$ROOT/.agents/skills" ]; then
  mkdir -p "$ROOT/.claude"
  ln -sfn ../.agents/skills "$ROOT/.claude/skills"
  grep -qxF '.claude/skills' "$ROOT/.git/info/exclude" 2>/dev/null \
    || echo '.claude/skills' >> "$ROOT/.git/info/exclude"
fi
