# MCP Server Setup for Heroku to Render Migration

The Render MCP server is recommended for direct service creation and automated verification, but not required for the Blueprint path. The Heroku MCP server is optional — it enables automatic discovery of config vars, add-on plans, and dyno sizes.

## Render MCP Server (Recommended)

Hosted at `https://mcp.render.com/mcp` (recommended, auto-updates). The Render plugin (Cursor, Codex, Claude Code) connects to this server over OAuth with a pre-registered client id — no API key needed. Manual MCP clients can still use a Render API key from [Account Settings](https://dashboard.render.com/u/*/settings#api-keys).

Alternative: run locally via Docker or binary (see [Render MCP docs](https://render.com/docs/mcp-server)).
Source: [render-mcp-server](https://github.com/render-oss/render-mcp-server)

**Detecting the user's tool:** Infer the AI tool from this skill's install path (`~/.cursor/skills/` = Cursor, `~/.claude/skills/` = Claude Code, `~/.codex/skills/` = Codex). If the path doesn't match a known tool, ask the user which tool they're using, then follow the matching section below.

### Render plugin (recommended)

If the Render plugin is installed for your tool, it already declares this MCP server with a pre-registered OAuth client id. Reload the tool (restart Cursor or Claude Code, or start a new Codex thread), complete the Render OAuth prompt when asked, then retry `list_services()`. The manual, API-key setups below are for tools without the plugin.

### Cursor

1. Get a Render API key:
```
https://dashboard.render.com/u/*/settings#api-keys
```

2. Add this to `~/.cursor/mcp.json` (replace `<YOUR_API_KEY>`):
```json
{
  "mcpServers": {
    "render": {
      "url": "https://mcp.render.com/mcp",
      "headers": {
        "Authorization": "Bearer <YOUR_API_KEY>"
      }
    }
  }
}
```

3. Restart Cursor, then retry `list_services()`.

### Claude Code

1. Get a Render API key:
```
https://dashboard.render.com/u/*/settings#api-keys
```

2. Add the MCP server with Claude Code (replace `<YOUR_API_KEY>`):
```bash
claude mcp add --transport http render https://mcp.render.com/mcp --header "Authorization: Bearer <YOUR_API_KEY>"
```

3. Restart Claude Code, then retry `list_services()`.

### Codex

1. Get a Render API key:
```
https://dashboard.render.com/u/*/settings#api-keys
```

2. Set it in your shell:
```bash
export RENDER_API_KEY="<YOUR_API_KEY>"
```

3. Add the MCP server with the Codex CLI:
```bash
codex mcp add render --url https://mcp.render.com/mcp --bearer-token-env-var RENDER_API_KEY
```

4. Restart Codex, then retry `list_services()`.

### Other Tools

If using another AI tool, direct the user to the [Render MCP docs](https://render.com/docs/mcp-server) for that tool's setup steps and install method.

## Heroku MCP Server (Optional)

The Heroku MCP server enables automatic discovery of config vars, add-on plans, and dyno sizes. If it's not configured, the migration skill still works — it reads local project files and asks you to provide config var values manually.

- Requires Heroku CLI v10.8.1+ installed globally
- `heroku mcp:start` uses existing CLI auth (no API key needed)
- Alternative: `npx -y @heroku/mcp-server` with `HEROKU_API_KEY` env var
- Source: [heroku-mcp-server](https://github.com/heroku/heroku-mcp-server)

Add to your MCP config alongside the Render server:

```json
{
  "mcpServers": {
    "heroku": {
      "command": "heroku",
      "args": ["mcp:start"]
    }
  }
}
```

## Verification

After configuring, test your connections:
- Ask: "List my Render services" — should return services via Render MCP (required)
- Ask: "List my Heroku apps" — should return apps via Heroku MCP (optional)

If Render MCP fails, reinstall or update the Render plugin and reload the tool (plugin setup), or check your API key and restart your MCP client (manual setup). If Heroku MCP is not configured, the migration skill still works — it reads local project files and asks you to provide config var values manually.
