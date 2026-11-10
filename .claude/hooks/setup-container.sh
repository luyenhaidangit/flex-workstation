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

# In danh sách repo con cần nạp sẵn (cloudEnabled != false, chưa có thư mục) để agent tự add_repo + clone.
# Hook không clone được repo private nên chỉ liệt kê; stdout SessionStart được đưa vào context.
if command -v node >/dev/null 2>&1 && [ -f "$ROOT/workstation.json" ]; then
  node -e '
    const fs = require("fs"), path = require("path");
    const root = process.argv[1];
    const items = JSON.parse(fs.readFileSync(path.join(root, "workstation.json"), "utf8")).repositories.items || [];
    const todo = items.filter(i => i.cloudEnabled !== false && !fs.existsSync(path.join(root, i.name)));
    if (!todo.length) process.exit(0);
    console.log("[flex-workstation] Preload repo cloud: các repo sau còn thiếu và đang bật (cloudEnabled != false).");
    console.log("Ở đầu session, thực hiện theo flex-repo-scope (mục Preload) cho các repo:");
    for (const i of todo) {
      const m = /github\.com[/:]([^/]+)\/([^/]+?)(?:\.git)?\/?$/.exec(i.url || "");
      console.log("- " + i.name + " (" + (m ? m[1] + "/" + m[2] : i.url) + ")");
    }
  ' "$ROOT" || true
fi
