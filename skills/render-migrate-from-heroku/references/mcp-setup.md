# MCP Server Setup for Heroku → Render Migration

The Render MCP server is required. The Heroku MCP server is optional but recommended — it enables automatic discovery of config vars, add-on plans, and dyno sizes.

## Configuration

### Claude Desktop / Cursor / Claude Code

Add servers to your MCP config (Heroku server is optional):

```json
{
  "mcpServers": {
    "heroku": {
      "command": "heroku",
      "args": ["mcp:start"]
    },
    "render": {
      "url": "https://mcp.render.com/sse",
      "headers": {
        "Authorization": "Bearer <YOUR_RENDER_API_KEY>"
      }
    }
  }
}
```

### Heroku MCP Server

- Requires Heroku CLI v10.8.1+ installed globally
- `heroku mcp:start` uses existing CLI auth (no API key needed)
- Alternative: `npx -y @heroku/mcp-server` with `HEROKU_API_KEY` env var
- Source: [heroku-mcp-server](https://github.com/heroku/heroku-mcp-server)

### Render MCP Server

- Hosted at `https://mcp.render.com/sse` (recommended, auto-updates)
- Requires Render API key from Account Settings
- Alternative: run locally via Docker or binary (see [Render MCP docs](https://render.com/docs/mcp-server))
- Source: [render-mcp-server](https://github.com/render-oss/render-mcp-server)

## Verification

After configuring, test your connections:
- Ask: "List my Render services" — should return services via Render MCP (required)
- Ask: "List my Heroku apps" — should return apps via Heroku MCP (optional)

If Render MCP fails, check your API key and restart your MCP client. If Heroku MCP is not configured, the migration skill still works — it reads local project files and asks you to provide config var values manually.
