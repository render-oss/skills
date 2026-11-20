---
name: render-cli
description: >-
  Installs and uses the Render CLI for deploys, logs, SSH, psql, Blueprint
  planning, approval, validation, and automation. Use when the user needs to run Render CLI
  commands, script deploys in CI/CD, authenticate with an API key, query
  services non-interactively, or troubleshoot CLI auth issues.
  Trigger terms: render CLI, render login, render deploys, render logs,
  render ssh, render psql, render blueprints validate, render ea blueprints, render skills,
  RENDER_API_KEY, non-interactive, CI/CD deploy.
license: MIT
compatibility: Render CLI v2.7.0+ for validation; v2.35.0+ for public-alpha Blueprint operations. Inspect installed help for current capabilities.
metadata:
  author: Render
  version: "1.1.0"
  category: operations
---

# Render CLI

The Render CLI manages services, databases, and deployments from the terminal. Supports interactive use, non-interactive scripting, and CI/CD automation.

Before installing, authenticating, selecting a workspace, or running commands, read `references/render-access.md` for the current access and command-discovery workflow.

## When to Use

- **Deploying** a service from the terminal or CI/CD
- **Tailing logs** in real time
- **Opening psql** to a Render Postgres database
- **SSHing** into a running service or launching an ephemeral shell
- **Validating, planning, and approving** a Blueprint
- **Scripting** Render operations in CI/CD pipelines
- **Installing** agent skills for AI coding tools

## Command Reference

Use the installed CLI help or generated command reference as directed by `references/render-access.md` for the exact command surface and flags. The patterns below cover common operational workflows.

### Deploy patterns

```bash
# Deploy and wait for completion (exits non-zero on failure)
render deploys create srv-xxx --wait --confirm -o json

# Deploy a specific commit
render deploys create srv-xxx --commit abc123 --wait --confirm

# Deploy a specific Docker image
render deploys create srv-xxx --image ghcr.io/org/app:v1.2.3 --wait --confirm
```

### Database queries

```bash
# Single query, JSON output
render psql db-xxx -c "SELECT NOW();" -o json

# CSV output via psql passthrough
render psql db-xxx -c "SELECT id, email FROM users;" -o text -- --csv
```

### Blueprint deployment

Use **render-deploy** for the full remote-source, plan-review, approval, and workload-verification flow. Inspect `render ea blueprints --help` for public-alpha create/plan/approve/update commands; if unavailable, upgrade the CLI or use available MCP Blueprint tools. Local validation remains `render blueprints validate <file>`. Creation and planning do not apply resource changes, and approval does not wait for deployments to finish. Never chain approval after planning without inspecting its outcome and obtaining authorization for the reviewed plan.

## CI/CD Example (GitHub Actions)

```yaml
name: Deploy to Render
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Install Render CLI
        run: |
          curl --fail-with-body --silent --show-error --location \
            https://raw.githubusercontent.com/render-oss/cli/refs/heads/main/bin/install.sh \
            --output /tmp/install-render-cli.sh
          sudo sh /tmp/install-render-cli.sh
          render --version
      - name: Deploy
        env:
          RENDER_API_KEY: ${{ secrets.RENDER_API_KEY }}
        run: render deploys create ${{ secrets.RENDER_SERVICE_ID }} --wait --confirm -o json
```

If reproducible builds require a pinned CLI, select a currently supported release and verify its asset name in the current release documentation instead of copying a version from this skill.

## Local Config

Config file: `~/.render/cli.yaml`

Override the configuration directory with `RENDER_CLI_CONFIG_DIR`. `RENDER_CLI_CONFIG_PATH` is a legacy file-level override retained for compatibility and is scheduled for deprecation.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Deploying without `--wait` in CI | Add `--wait` so the job fails on deploy failure |

## References

| Document | Contents |
|----------|----------|
| `references/render-access.md` | Current CLI authentication, workspace, documentation, output, and authorization workflow |
| `references/command-cheatsheet.md` | Common operational command examples and scripting patterns |

## Related Skills

- **render-deploy** — End-to-end deployments, Blueprint planning and approval through MCP or CLI
- **render-blueprints** — `render.yaml` authoring and validation
- **render-postgres** — Database connections, `render psql` usage
- **render-debug** — Using `render logs` and `render ssh` for troubleshooting

<!-- shared:documentation-retrieval -->
## Current documentation retrieval

Whenever this skill directs you to consult current Render documentation:

1. Retrieve the linked Markdown document directly with an available URL-fetching tool or HTTP client, such as `curl`. Do not substitute web-search summaries for the document.
2. Confirm that retrieval succeeded and returned the expected document, then read its contents. Saving a file or printing its path is not sufficient.
3. If the request fails or your tool cannot read the Markdown response, open and read the linked HTML version instead.
4. If neither version can be retrieved, disclose that the current reference is unavailable and follow any topic-specific fallback in the skill. Use bundled guidance only for stable constraints, and do not guess at changeable platform details.

When a task requires multiple references, apply this workflow to each one and distinguish the documents you verified from those that remain unavailable.
<!-- /shared:documentation-retrieval -->
