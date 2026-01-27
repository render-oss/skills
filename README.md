# Render Skills for AI Agents

AI agent skills for deploying, debugging, and monitoring applications on Render cloud platform.

## Compatibility

| Feature | Claude Code | Codex | OpenCode | Cursor |
|---------|-------------|-------|----------|--------|
| Skill prompts (SKILL.md) | ✅ | ✅ | ✅ | ✅ |
| Render CLI commands | ✅ | ✅ | ✅ | ✅ |
| Render MCP tools | ✅ | ✅ | ✅ | ✅ |
| Auto-approval hooks | ✅ | ❌ | ❌ | ❌ |

All tools support the Render MCP server for structured data access. Auto-approval hooks are Claude Code specific.

## Skills

### render-deploy

Deploy applications to Render using two methods:
1. **Blueprint Method** - Generate render.yaml for Infrastructure-as-Code deployments
2. **Direct Creation** - Create services instantly via MCP tools

**Features:**
- Automatic codebase analysis (Node.js, Python, Go, Ruby, Rust, Static, Docker)
- Direct service creation via MCP (web services, static sites, cron jobs, databases)
- Environment variable management
- Post-deployment verification with metrics
- Service discovery for existing resources

**Example:**
```
User: "Deploy my Next.js app to Render"
Agent: [Analyzes codebase, creates service via MCP or generates Blueprint, verifies deployment]
```

[Full Documentation](skills/render-deploy/SKILL.md)

### render-debug

Debug failed Render deployments using logs, metrics, and database queries. Identifies root causes and applies fixes.

**Features:**
- MCP-powered log analysis with structured queries
- Metrics-based debugging (CPU, memory, latency)
- Database debugging with direct SQL queries
- Automated error pattern detection
- Quick workflow templates for common issues

**Common Issues Detected:** Missing environment variables, port binding errors, missing dependencies, database connection failures, health check timeouts, out of memory errors, build failures.

**Example:**
```
User: "My Render deployment failed"
Agent: [Queries logs via MCP, checks metrics, identifies issue, fixes and redeploys]
```

[Full Documentation](skills/render-debug/SKILL.md)

### render-monitor

Real-time monitoring of Render services including health checks, performance metrics, logs, and resource usage.

**Features:**
- Service health monitoring
- Performance metrics (CPU, memory, latency, bandwidth)
- Database metrics and query analysis
- Log filtering and search
- Quick health check workflows

**Example:**
```
User: "Is my Render service healthy?"
Agent: [Checks deploy status, error logs, CPU/memory metrics, HTTP latency]
```

[Full Documentation](skills/render-monitor/SKILL.md)

---

## Installation

### Quick Install (Recommended)

One-liner that automatically detects and installs to all supported tools:

```bash
curl -fsSL https://raw.githubusercontent.com/render-oss/skills/main/scripts/install.sh | bash
```

This installs to all detected tools: Claude Code, Codex, OpenCode, and Cursor.

### Claude Code (Official Directory)

Once available in the official Claude Code Plugins Directory:

```bash
/plugin install render
```

### Claude Code (GitHub)

```bash
/plugin marketplace add render-oss/skills
/plugin install render@skills
```

### OpenAI Codex (Curated Directory)

Once available in the curated skills directory:

```bash
$skill-installer render-deploy
$skill-installer render-debug
$skill-installer render-monitor
```

### Manual Installation

Copy the plugin directory to your agent's skills directory:

- **Claude Code:** `~/.claude/skills/render/`
- **Codex:** `~/.codex/skills/render/`
- **OpenCode:** `~/.config/opencode/skills/render/`
- **Cursor:** `~/.cursor/skills/render/`

---

## Auto-Approval Hooks

This plugin includes hooks that automatically approve safe, read-only operations to reduce permission fatigue. You'll no longer be prompted for basic operations like listing services or viewing logs.

### Auto-Approved Operations

The following CLI operations are automatically approved without prompting:

- **Listing services**: `render services list`, `render services -o json`
- **Reading logs**: `render logs -r`, `render logs --raw`
- **Checking workspaces**: `render workspace current`, `render workspace list`

### Operations Requiring Permission

All modification operations still require explicit permission for safety:

- Deployments (`render deploy`)
- Service restarts (`render services restart`)
- Service creation/deletion (`render services create`, `render services delete`)
- Configuration changes (`render services update`)
- Workspace changes (`render workspace set`)

This ensures you maintain full control over any operations that modify your infrastructure while streamlining read-only workflows.

---

## Prerequisites

All skills work best with:
- Render MCP tools (automatically available with `RENDER_API_KEY`)
- Render API key (`RENDER_API_KEY` environment variable)

Required for deploying services:
- Git repository pushed to GitHub, GitLab, or Bitbucket

Optional:
- Render CLI (`brew install render`) - for streaming logs and SSH

## Quick Start

**Deploying:** Ask "Deploy my application to Render"

**Debugging:** Ask "Debug my Render deployment"

**Monitoring:** Ask "Is my Render service healthy?"

---

## Contributing

### Adding a New Skill

To add a new skill to this plugin:

1. **Create skill directory:**
   ```
   skills/
   └── your-skill-name/
       ├── SKILL.md              # Required: Main skill documentation
       ├── references/           # Optional: Detailed references
       └── assets/               # Optional: Templates, examples
   ```

2. **Write SKILL.md with frontmatter:**
   ```yaml
   ---
   name: your-skill-name
   description: Brief description of what this skill does
   license: MIT
   compatibility: Prerequisites and requirements
   metadata:
     author: Render
     version: "1.0.0"
     category: category-name
   ---
   ```

3. **Follow progressive disclosure pattern:**
   - SKILL.md: Concise workflow (~300-400 lines)
   - references/: Detailed specifications loaded on-demand
   - assets/: Templates and examples

4. **Structure for agents:**
   - Clear step-by-step instructions
   - CLI commands with expected outputs
   - Link to detailed references using relative paths
   - Include common issues and fixes

5. **Test locally:**
   ```bash
   claude plugin add /path/to/skills
   ```

6. **Submit pull request** with:
   - Skill documentation
   - Reference files (if applicable)
   - Testing evidence

See existing skills ([deploy](skills/render-deploy/), [debug](skills/render-debug/), [monitor](skills/render-monitor/)) as examples.

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
