<!-- shared:render-access -->
## Accessing Render

Prefer the hosted Render MCP server for structured access to Render resources when its tools are available. Use the Render CLI when MCP is unavailable or does not support the required operation, and use the Render Dashboard or API for capabilities exposed by neither. Do not assume that a remembered MCP tool or CLI command is still available; inspect the tools in the current environment or consult the current documentation.

The hosted Render MCP server uses streamable HTTP at:

```text
https://mcp.render.com/mcp
```

Official Render plugins and connectors can authenticate MCP with browser-based OAuth. Manual and non-interactive configurations can use a Render API key as a bearer token. Never write an API key or OAuth token into a repository, skill, command output, chat response, or log. Prefer the client's supported secret storage or environment-variable mechanism. If a client requires a credential in local configuration, keep that file out of version control and restrict access to it.

Treat MCP responses as potentially sensitive even when the server attempts to minimize credential exposure. Request connection strings, credentials, secret environment variables, or other sensitive fields only when the task requires them. Do not repeat sensitive values in the response or persist them in files or logs.

Before configuring or troubleshooting MCP, fetch the current setup and capability reference:

Using the documentation-retrieval workflow in the root `SKILL.md`, retrieve and read the [Markdown reference](https://render.com/docs/mcp-server.md) or its [HTML version](https://render.com/docs/mcp-server).

Read the relevant client setup, supported-actions, and limitations sections. Prefer the hosted server unless the user's environment requires a local MCP server. After installing, updating, or reconfiguring an MCP integration, reload the client as required and verify the connection with a read-only operation such as listing services.

Most MCP operations and Render CLI commands that access Render resources are scoped to an active workspace. Check the selected workspace before reading or changing resources. If no workspace is selected—or if the intended workspace is ambiguous—list the available workspaces and have the user identify the correct one. Do not silently switch workspace context or infer it from a resource name. Commands for authentication, help, CLI configuration, and workspace discovery or selection do not require an already selected workspace.

For interactive CLI use, authenticate with `render login`. For automation, use a securely stored `RENDER_API_KEY`; an API key takes precedence over a saved CLI token. Verify CLI access and the active workspace with read-only commands before operating on resources:

```bash
render whoami --output json
render workspace current --output json
```

For CLI installation, authentication, workspace setup, and usage patterns, fetch the current CLI overview:

Using the documentation-retrieval workflow in the root `SKILL.md`, retrieve and read the [Markdown reference](https://render.com/docs/cli.md) or its [HTML version](https://render.com/docs/cli).

For exact command syntax and flags, prefer the help text from the installed CLI because it matches the version being used:

```bash
render help <command>
```

The published CLI command reference is generated automatically from the CLI's help text. Use it to browse the full command surface or when the CLI is not installed:

Using the documentation-retrieval workflow in the root `SKILL.md`, retrieve and read the [Markdown reference](https://render.com/docs/cli-reference.md) or its [HTML version](https://render.com/docs/cli-reference).

When an agent or automation invokes the CLI, select a non-interactive output format such as `--output json`, `--output yaml`, or `--output text` so results can be inspected reliably. The global `--confirm` flag skips confirmation prompts; use it for a mutating command only after that mutation is authorized. It is an execution convenience, not permission to perform the action.

Authentication establishes access; it does not establish user authorization for every available action. Use read-only discovery to resolve workspace, resource identity, and current state before a mutation. Perform changes only when they are within the user's requested scope, and retain normal approval requirements for consequential operations such as creation, configuration changes, deploys, restarts, scaling, or deletion.

When authentication or connectivity fails, report which access path failed, preserve the underlying error without exposing credentials, and either use an available supported fallback or explain what the user must configure before the task can continue.
<!-- /shared:render-access -->
