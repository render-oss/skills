# Render Skills for AI Agents

Skills to deploy, debug, and monitor Render services.

## Table of Contents

- [Compatibility](#compatibility)
- [Installation](#installation)
- [Skills](#skills)
  - [render-deploy](#render-deploy)
  - [render-debug](#render-debug)
  - [render-monitor](#render-monitor)
- [Auto-Approval Hooks](#auto-approval-hooks)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Contributing](#contributing)
- [Repository Structure](#repository-structure)
- [Support](#support)
- [License](#license)

## Compatibility

| Feature | Claude Code | Codex | OpenCode | Cursor |
|---------|-------------|-------|----------|--------|
| Skill prompts (SKILL.md) | ✅ | ✅ | ✅ | ✅ |
| Render CLI commands | ✅ | ✅ | ✅ | ✅ |
| Render MCP tools | ✅ | ✅ | ✅ | ✅ |
| Auto-approval hooks | ✅ | ❌ | ❌ | ❌ |

## Installation

### Quick Install (Recommended)

Install to all detected tools:

```bash
curl -fsSL https://raw.githubusercontent.com/render-oss/skills/main/scripts/install.sh | bash
```

Targets: Claude Code, Codex, OpenCode, and Cursor.

### Claude Code 

```bash
/plugin marketplace add render-oss/skills
/plugin install render@skills
```

### OpenAI Codex (coming soon)

```bash
$skill-installer render-deploy
$skill-installer render-debug
$skill-installer render-monitor
```

### Manual Installation

Copy each skill directory from `skills/` into your tool's skills directory:

- **Claude Code (skills mode):** `~/.claude/skills/<skill-name>/`
- **Codex:** `~/.codex/skills/<skill-name>/`
- **OpenCode:** `~/.config/opencode/skills/<skill-name>/`
- **Cursor:** `~/.cursor/skills/<skill-name>/`

Example (Codex):
```bash
cp -R skills/render-deploy ~/.codex/skills/render-deploy
cp -R skills/render-debug ~/.codex/skills/render-debug
cp -R skills/render-monitor ~/.codex/skills/render-monitor
```

---

## Skills

### render-deploy

Deploy via Blueprint (`render.yaml`) or direct MCP creation.

- Detects common stacks and configures build/start
- Creates services, cron jobs, and databases via MCP
- Verifies deploys with basic health/metrics checks

[Full Documentation](skills/render-deploy/SKILL.md)

### render-debug

Find root causes using logs, metrics, and (when needed) database queries.

- Structured log queries via MCP
- CPU/memory/latency diagnostics
- Fix suggestions for common deploy failures

[Full Documentation](skills/render-debug/SKILL.md)

### render-monitor

Check service health, performance metrics, and recent logs.

- Health checks and deploy status
- CPU/memory/latency/bandwidth
- Log filtering and summaries

[Full Documentation](skills/render-monitor/SKILL.md)

---

## Auto-Approval Hooks

Auto-approves safe, read-only CLI operations:

- **Listing services**: `render services list`, `render services -o json`
- **Reading logs**: `render logs -r`, `render logs --raw`
- **Checking workspaces**: `render workspace current`, `render workspace list`

Operations that modify infrastructure still require permission:

- Deployments (`render deploy`)
- Service restarts (`render services restart`)
- Service creation/deletion (`render services create`, `render services delete`)
- Configuration changes (`render services update`)
- Workspace changes (`render workspace set`)

---

## Prerequisites

- Render MCP tools configured with an API key
- `RENDER_API_KEY` environment variable
- Git repository pushed to GitHub, GitLab, or Bitbucket (for deploys)
- Optional: Render CLI for streaming logs/SSH

## Quick Start

Deploy: "Deploy my application to Render"  
Debug: "Debug my Render deployment"  
Monitor: "Is my Render service healthy?"

---

## Contributing

### Adding a New Skill

1. Create `skills/your-skill-name/` with `SKILL.md` (optional `references/`, `assets/`).
2. Add frontmatter in `SKILL.md`:
   ```yaml
   ---
   name: your-skill-name
   description: Brief description
   license: MIT
   compatibility: Prerequisites and requirements
   metadata:
     author: Render
     version: "1.0.0"
     category: category-name
   ---
   ```
3. Keep `SKILL.md` concise; move details to `references/`.
4. Test locally:
   ```bash
   claude plugin add /path/to/skills
   ```

Examples: [deploy](skills/render-deploy/), [debug](skills/render-debug/), [monitor](skills/render-monitor/).

---

## Repository Structure

```
render-skill/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest
│   └── marketplace.json         # Marketplace metadata
├── skills/
│   ├── render-deploy/           # Deployment skill
│   ├── render-debug/            # Debugging skill
│   └── render-monitor/          # Monitoring skill
├── hooks/
│   ├── hooks.json               # Hook configuration
│   └── auto-approve-render.sh   # Auto-approval script
├── scripts/
│   └── install.sh               # Multi-tool installer
├── .mcp.json                    # MCP server configuration
├── README.md                    # This file
├── .gitignore
└── LICENSE
```

---

## Support

- **Documentation:** https://render.com/docs
- **Issues:** https://github.com/render-oss/skills/issues
- **Render Support:** support@render.com

---

## License

MIT License - see [LICENSE](LICENSE) file for details.
