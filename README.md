# Render Skills for AI Agents

A catalog of 21 skills that teach AI coding tools how to deploy, operate, and debug apps on Render. Each skill is a self-contained `SKILL.md` plus references that any compatible agent can use.

Use this repo to:

- Install Render skills into your AI tool (Claude Code, Codex, Cursor, OpenCode)
- Browse what each skill does and link straight to its docs
- Contribute new skills or improve existing ones

## Compatibility

| Feature | Claude Code | Codex | OpenCode | Cursor |
| --- | --- | --- | --- | --- |
| Skill prompts (`SKILL.md`) | ✅ | ✅ | ✅ | ✅ |
| Render CLI commands | ✅ | ✅ | ✅ | ✅ |
| Render MCP tools | ✅ | ✅ | ✅ | ✅ |
| Auto-approval hooks | ✅ | ❌ | ❌ | ❌ |

## Installation

The recommended way to install Render skills is the Render CLI:

```bash
render skills install
```

Other useful commands:

```bash
render skills          # interactive management
render skills list     # show installed skills
render skills update   # update installed skills
```

### Other ways to install

- Skills CLI: `npx skills add render-oss/skills`
- Claude Code plugin: `/plugin marketplace add render-oss/skills` then `/plugin install render@skills`
- Manual: copy any directory from `skills/` into your tool's skills path (`~/.claude/skills/`, `~/.codex/skills/`, `~/.config/opencode/skills/`, or `~/.cursor/skills/`)

### Prerequisites

- A Render account with the [Render MCP server](skills/render-mcp/SKILL.md) configured, or the [Render CLI](skills/render-cli/SKILL.md) installed
- A `RENDER_API_KEY` environment variable
- A Git repository on GitHub, GitLab, or Bitbucket for any deploy-related skill

## Skills catalog

### Get started

| Skill | What it helps with |
| --- | --- |
| [`render-mcp`](skills/render-mcp/SKILL.md) | Set up and troubleshoot the Render MCP server |
| [`render-cli`](skills/render-cli/SKILL.md) | Install and use the Render CLI for deploys, logs, SSH, and automation |
| [`render-deploy`](skills/render-deploy/SKILL.md) | Deploy applications to Render |
| [`render-blueprints`](skills/render-blueprints/SKILL.md) | Author and validate `render.yaml` Blueprints |

### Service types

| Skill | What it helps with |
| --- | --- |
| [`render-web-services`](skills/render-web-services/SKILL.md) | Configure public web services, health checks, and TLS |
| [`render-private-services`](skills/render-private-services/SKILL.md) | Design internal-only services on Render's private network |
| [`render-static-sites`](skills/render-static-sites/SKILL.md) | Deploy static sites, SPAs, redirects, and custom headers |
| [`render-background-workers`](skills/render-background-workers/SKILL.md) | Set up queue-based background workers and graceful shutdown |
| [`render-cron-jobs`](skills/render-cron-jobs/SKILL.md) | Configure scheduled jobs and cron expressions |
| [`render-workflows`](skills/render-workflows/SKILL.md) | Set up and develop Render Workflows |

### Build and runtime

| Skill | What it helps with |
| --- | --- |
| [`render-docker`](skills/render-docker/SKILL.md) | Build and deploy Docker-based services |
| [`render-env-vars`](skills/render-env-vars/SKILL.md) | Manage env vars, secrets, and env groups |
| [`render-disks`](skills/render-disks/SKILL.md) | Attach and manage persistent disks |

### Networking and access

| Skill | What it helps with |
| --- | --- |
| [`render-domains`](skills/render-domains/SKILL.md) | Configure custom domains and troubleshoot TLS |
| [`render-networking`](skills/render-networking/SKILL.md) | Connect services over Render's private network |

### Data services

| Skill | What it helps with |
| --- | --- |
| [`render-postgres`](skills/render-postgres/SKILL.md) | Operate Managed PostgreSQL, backups, replicas, and connections |
| [`render-keyvalue`](skills/render-keyvalue/SKILL.md) | Provision and tune Render Key Value |

### Operate and scale

| Skill | What it helps with |
| --- | --- |
| [`render-monitor`](skills/render-monitor/SKILL.md) | Check service health, metrics, and logs |
| [`render-debug`](skills/render-debug/SKILL.md) | Diagnose failed deploys, startup issues, and runtime errors |
| [`render-scaling`](skills/render-scaling/SKILL.md) | Configure autoscaling, instance sizing, and cost tradeoffs |
| [`render-migrate-from-heroku`](skills/render-migrate-from-heroku/SKILL.md) | Migrate Heroku apps to Render |

## Trying it out

Once installed, ask your agent things like:

- "Deploy my application to Render."
- "Debug why my Render service won't start."
- "Is my Render service healthy?"
- "Set up a private service for this internal API."
- "Add a cron job that runs every night."
- "Configure custom domains for this web service."
- "Migrate my Heroku app to Render."

## Auto-approval hooks (Claude Code)

The repo ships hook configuration that lets Claude Code auto-approve safe, read-only Render CLI operations:

- Listing services: `render services list`, `render services -o json`
- Reading logs: `render logs -r`, `render logs --raw`
- Checking workspaces: `render workspace current`, `render workspace list`

Anything that changes infrastructure still requires explicit approval, including deploys, restarts, service creation and deletion, configuration changes, and workspace changes.

## Contributing

### Add a new skill

1. Create `skills/your-skill-name/` with a `SKILL.md`.
2. Add supporting files as needed: `references/`, `assets/`, and `evals.json`.
3. Add frontmatter at the top of `SKILL.md`:

   ```yaml
   ---
   name: your-skill-name
   description: One sentence describing when an agent should use this skill.
   license: MIT
   compatibility: Prerequisites and requirements
   metadata:
     author: Render
     version: "1.0.0"
     category: deployment
   ---
   ```

4. Keep `SKILL.md` short and action-oriented. Move depth into `references/`.
5. Test locally with your target tool.

For reference, look at [`render-deploy`](skills/render-deploy/), [`render-debug`](skills/render-debug/), [`render-monitor`](skills/render-monitor/), or [`render-workflows`](skills/render-workflows/).

## Repository structure

```text
skills/
├── .github/workflows/   # CI
├── hooks/               # Auto-approval hook config for Claude Code
├── scripts/             # Install and helper scripts
├── skills/              # 21 skill directories
├── README.md
└── LICENSE
```

## Support

- Documentation: <https://render.com/docs>
- Issues: <https://github.com/render-oss/skills/issues>
- Render Support: <mailto:support@render.com>

## License

MIT License. See [LICENSE](LICENSE).
