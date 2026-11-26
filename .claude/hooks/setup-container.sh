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

# Repo con do add_repo clone vào /home/user/<name> (cạnh workstation): nối symlink vào root và
# đưa vào .git/info/exclude để git status của workstation không báo untracked.
if command -v node >/dev/null 2>&1 && [ -f "$ROOT/workstation.json" ]; then
  PARENT="$(dirname "$ROOT")"
  for name in $(node -e 'for (const i of JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).repositories.items || []) console.log(i.name)' "$ROOT/workstation.json"); do
    [ -e "$ROOT/$name" ] || { [ -d "$PARENT/$name/.git" ] && ln -sfn "$PARENT/$name" "$ROOT/$name"; }
    grep -qxF "/$name" "$ROOT/.git/info/exclude" 2>/dev/null || echo "/$name" >> "$ROOT/.git/info/exclude"
  done

  # In danh sách repo lõi cần nạp sẵn (preload=true, cloudEnabled != false, chưa clone) để agent tự add_repo + clone.
  # Hook không clone được repo private nên chỉ liệt kê; stdout SessionStart được đưa vào context.
  node -e '
    const fs = require("fs"), path = require("path");
    const root = process.argv[1];
    const items = JSON.parse(fs.readFileSync(path.join(root, "workstation.json"), "utf8")).repositories.items || [];
    const todo = items.filter(i => i.preload === true && i.cloudEnabled !== false && !fs.existsSync(path.join(root, i.name)));
    if (!todo.length) process.exit(0);
    console.log("[flex-workstation] Preload repo cloud: các repo lõi (preload=true) còn thiếu.");
    console.log("Khi yêu cầu cần đọc hoặc sửa code repo con, hoặc hỏi về hiện trạng hệ thống Flex (hạ tầng, service, mức độ sẵn sàng): theo flex-repo-scope (mục Preload), nạp sẵn các repo sau mà không hỏi lại, rồi trả lời luôn câu hỏi gốc. Chỉ bỏ qua khi yêu cầu không liên quan repo con:");
    for (const i of todo) {
      const m = /github\.com[/:]([^/]+)\/([^/]+?)(?:\.git)?\/?$/.exec(i.url || "");
      console.log("- " + i.name + " (" + (m ? m[1] + "/" + m[2] : i.url) + ")");
    }
  ' "$ROOT" || true
fi

# MCP DB trong .mcp.json cần biến FLEX_*_DB_URL; cloud không có thì server luôn lỗi kết nối.
# Tắt riêng các server đó qua settings.local.json (gitignore, chỉ container này); có hiệu lực từ lần nạp MCP kế tiếp.
if command -v node >/dev/null 2>&1 && [ -f "$ROOT/.mcp.json" ]; then
  node -e '
    const fs = require("fs"), path = require("path");
    const root = process.argv[1];
    const servers = JSON.parse(fs.readFileSync(path.join(root, ".mcp.json"), "utf8")).mcpServers || {};
    const off = Object.entries(servers).filter(([, s]) => (JSON.stringify(s.args || []).match(/\$\{(\w+)\}/g) || []).some(v => !process.env[v.slice(2, -1)])).map(([n]) => n);
    if (!off.length) process.exit(0);
    const file = path.join(root, ".claude", "settings.local.json");
    let cfg = {};
    try { cfg = JSON.parse(fs.readFileSync(file, "utf8")); } catch {}
    cfg.disabledMcpjsonServers = [...new Set([...(cfg.disabledMcpjsonServers || []), ...off])];
    fs.writeFileSync(file, JSON.stringify(cfg, null, 2) + "\n");
  ' "$ROOT" || true
fi
