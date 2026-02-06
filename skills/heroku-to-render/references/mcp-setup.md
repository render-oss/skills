# MCP Server Setup for Heroku → Render Migration

Both MCP servers must be connected to the same client.

## Configuration

### Claude Desktop / Cursor / Claude Code

Add both servers to your MCP config:

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
- Source: https://github.com/heroku/heroku-mcp-server

### Render MCP Server

- Hosted at `https://mcp.render.com/sse` (recommended, auto-updates)
- Requires Render API key from Account Settings
- Alternative: run locally via Docker or binary (see https://render.com/docs/mcp-server)
- Source: https://github.com/render-oss/render-mcp-server

## Verification

After configuring, test both connections:
- Ask: "List my Heroku apps" — should return apps via Heroku MCP
- Ask: "List my Render services" — should return services via Render MCP

If either fails, check auth credentials and restart your MCP client.
