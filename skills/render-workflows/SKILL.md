---
name: render-workflows
description: Set up Render Workflows in Python or TypeScript projects. Installs the SDK, scaffolds task definitions, configures local development, and deploys workflow services. Use when the user wants to create workflows, define background tasks, add the Render SDK, or run distributed jobs on Render.
license: MIT
compatibility: Requires Render Workflows early access enabled for the workspace. Render CLI 2.4.2+ for local development. Python 3.10+ or Node.js 18+.
metadata:
  author: Render
  version: "1.0.0"
  category: workflows
---

# Set Up Render Workflows

Help developers define and deploy distributed background tasks using the Render Workflows SDK.

**Render Workflows are in limited early access.** The SDK and API may introduce breaking changes. [Request early access](https://render.com/workflows).

Supported languages:
- **Python** (GA in early access)
- **TypeScript** (nearing release)
- **Go** (planned)

## When to Use This Skill

Activate when users want to:
- Set up Render Workflows in their project
- Install the Render Workflows SDK (Python or TypeScript)
- Define background tasks with retries, subtasks, or fan-out patterns
- Run workflow tasks locally for development
- Deploy a workflow service to Render

## Prerequisites

**1. Early Access**

The user's Render workspace must have Workflows enabled. If not, direct them to [request early access](https://render.com/workflows).

**2. Check MCP Tools (optional but preferred)**

```
list_services()
```

If MCP tools are available, they can be used later for deployment verification.

**3. Render CLI (for local development)**

```bash
render --version
```

Requires version 2.4.2+. If not installed:
- macOS: `brew install render`
- Linux/macOS: `curl -fsSL https://raw.githubusercontent.com/render-oss/cli/main/bin/install.sh | sh`

## MCP Setup (Per Tool)

If `list_services()` fails because MCP isn't configured, ask whether they want to set up MCP (preferred) or continue with the CLI fallback. If they choose MCP, ask which AI tool they're using, then provide the matching instructions below. Always use their API key.

### Cursor

Walk the user through these steps:

1) Get a Render API key:
```
https://dashboard.render.com/u/*/settings#api-keys
```

2) Add this to `~/.cursor/mcp.json` (replace `<YOUR_API_KEY>`):
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

3) Restart Cursor, then retry `list_services()`.

### Claude Code

Walk the user through these steps:

1) Get a Render API key:
```
https://dashboard.render.com/u/*/settings#api-keys
```

2) Add the MCP server with Claude Code (replace `<YOUR_API_KEY>`):
```bash
claude mcp add --transport http render https://mcp.render.com/mcp --header "Authorization: Bearer <YOUR_API_KEY>"
```

3) Restart Claude Code, then retry `list_services()`.

### Codex

Walk the user through these steps:

1) Get a Render API key:
```
https://dashboard.render.com/u/*/settings#api-keys
```

2) Set it in their shell:
```bash
export RENDER_API_KEY="<YOUR_API_KEY>"
```

3) Add the MCP server with the Codex CLI:
```bash
codex mcp add render --url https://mcp.render.com/mcp --bearer-token-env-var RENDER_API_KEY
```

4) Restart Codex, then retry `list_services()`.

### Other Tools

Direct the user to the Render MCP docs for their tool's setup steps.

---

## Setup Workflow

### Step 1: Detect Language

Check the project for language indicators:

| Indicator | Language |
|-----------|----------|
| `requirements.txt`, `pyproject.toml`, `Pipfile`, `*.py` | Python |
| `package.json`, `tsconfig.json`, `*.ts` | TypeScript |

If both are present or neither is found, ask the user which language to use.

### Step 2: Install the SDK

**Python:**
```bash
pip install render_sdk
```
Add `render_sdk` to `requirements.txt` (or equivalent dependency file).

**TypeScript:**
```bash
npm install @renderinc/sdk
```

### Step 3: Scaffold Task Definitions

Create a `workflows/` directory in the project root and add an entry point file with sample tasks. Use the templates in [assets/](assets/) as a starting point, or generate directly.

**Always include at least one zero-argument task** (like `ping` below) so the user can immediately verify the setup works without providing any input.

**Python** -- create `workflows/main.py`:
```python
from render_sdk import Workflows

app = Workflows(auto_start=True)

@app.task
def ping() -> str:
    """Zero-arg task to verify the workflow is working."""
    return "pong"

@app.task
def hello(name: str) -> str:
    return f"Hello, {name}!"

```

If the project has a `requirements.txt`, add `render_sdk` there. Otherwise create `workflows/requirements.txt`.

**TypeScript** -- create `workflows/main.ts`:
```typescript
import { task } from "@renderinc/sdk/workflows";

/** Zero-arg task to verify the workflow is working. */
task(
  { name: "ping" },
  function ping(): string {
    return "pong";
  }
);

task(
  { name: "hello" },
  function hello(name: string): string {
    return `Hello, ${name}!`;
  }
);
```

If the project has a root `package.json`, add `@renderinc/sdk` there. Otherwise create `workflows/package.json` with the dependency.

Both SDKs auto-start the task server when running in a workflow environment. No explicit `start()` or `startTaskServer()` call is needed.

**After scaffolding, immediately guide the user to test it:**

1. Start the local task server:
   ```bash
   # Python
   render ea tasks dev -- python workflows/main.py

   # TypeScript
   render ea tasks dev -- npx ts-node workflows/main.ts
   ```

2. In a separate terminal, run the `ping` task:
   ```bash
   render ea tasks list --local
   ```
   Select `ping`, choose `run`, enter `[]` as input, and verify it returns `"pong"`.

3. Then try `hello` with input `["world"]` to confirm argument passing works.

For the full `Workflows` class options (default retries, timeouts, plans), see [references/python-sdk.md](references/python-sdk.md).
For the full `task()` options, see [references/typescript-sdk.md](references/typescript-sdk.md).

### Step 4: Help Define Tasks

Guide the user through defining their actual tasks. Key concepts:

**Retries** (automatic retry on failure):

Python:
```python
from render_sdk import Retry

@app.task(retry=Retry(max_retries=3, wait_duration_ms=1000, backoff_scaling=1.5))
def fetch_data(url: str) -> dict:
    ...
```

TypeScript:
```typescript
task(
  { name: "fetchData", retry: { maxRetries: 3, waitDurationMs: 1000, backoffScaling: 1.5 } },
  async function fetchData(url: string): Promise<object> { ... }
);
```

**Subtasks** (tasks calling other tasks):

Python:
```python
import asyncio

@app.task
async def process_batch(items: list[str]) -> list[str]:
    results = await asyncio.gather(*[process_item(item) for item in items])
    return list(results)

@app.task
def process_item(item: str) -> str:
    return item.upper()
```

TypeScript:
```typescript
const processItem = task(
  { name: "processItem" },
  function processItem(item: string): string { return item.toUpperCase(); }
);

task(
  { name: "processBatch" },
  async function processBatch(items: string[]): Promise<string[]> {
    const results = await Promise.all(items.map(item => processItem(item)));
    return results;
  }
);
```

For more patterns (ETL, fan-out, error handling), see [references/task-patterns.md](references/task-patterns.md).

### Step 5: Local Development

Start the local task server using the Render CLI:

```bash
# Python
render ea tasks dev -- python workflows/main.py

# TypeScript (from project root, or cd into workflows/)
render ea tasks dev -- npx ts-node workflows/main.ts
```

The local server runs on port 8120 (configurable with `--port`).

**Test tasks locally** using the CLI interactive menu:
```bash
render ea tasks list --local
```

Or configure your app to point to the local server:
```bash
# Set in your app's environment
RENDER_USE_LOCAL_DEV=true
```

For full local development details, see [references/local-development.md](references/local-development.md).

### Step 6: Deploy to Render

Workflows are deployed as a **Workflow** service type in the Render Dashboard. **Blueprints (render.yaml) are not yet compatible with Workflows.**

**Deploy via Dashboard:**

1. Push your code to GitHub, GitLab, or Bitbucket
2. In the [Render Dashboard](https://dashboard.render.com), click **New > Workflow**
3. Link your repository
4. Configure:

| Field | Python | TypeScript |
|-------|--------|------------|
| **Language** | Python 3 | Node |
| **Build Command** | `pip install -r requirements.txt` | `npm install && npm run build` |
| **Start Command** | `python workflows/main.py` | `node workflows/dist/main.js` |

5. Add environment variables (e.g., `RENDER_API_KEY` for tasks that call other workflows)
6. Click **Deploy Workflow**

**Running tasks from other services:**

After deployment, trigger tasks from your other Render services using the SDK client:

Python:
```python
from render_sdk import Render

render = Render()  # Uses RENDER_API_KEY from environment
result = await render.workflows.run_task("my-workflow/hello", ["world"])
finished = await result
print(finished.results)
```

TypeScript:
```typescript
import { Render } from "@renderinc/sdk";

const render = new Render();
const result = await render.workflows.runTask("my-workflow/hello", ["world"]);
console.log(result.results);
```

The task identifier format is `{workflow-slug}/{task-name}`, visible on the task's page in the Dashboard.

---

## Quick Reference

### SDK Installation

| Language | Package | Install |
|----------|---------|---------|
| Python | `render_sdk` | `pip install render_sdk` |
| TypeScript | `@renderinc/sdk` | `npm install @renderinc/sdk` |

### CLI Commands

```bash
# Local development
render ea tasks dev -- <start-command>
render ea tasks list --local

# Deployed tasks
render ea tasks list
```

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `RENDER_API_KEY` | API authentication for running tasks from client code |
| `RENDER_USE_LOCAL_DEV` | Set `true` to point SDK client at local task server |
| `RENDER_LOCAL_DEV_URL` | Custom local server URL (default: `http://localhost:8120`) |
| `RENDER_SDK_SOCKET_PATH` | Unix socket path (set automatically in workflow environment) |
| `RENDER_SDK_MODE` | Execution mode: `run` or `register` (set automatically) |

---

## References

- **Python SDK details:** [references/python-sdk.md](references/python-sdk.md)
- **TypeScript SDK details:** [references/typescript-sdk.md](references/typescript-sdk.md)
- **Task patterns:** [references/task-patterns.md](references/task-patterns.md)
- **Local development:** [references/local-development.md](references/local-development.md)
- **Official docs:** [render.com/docs/workflows](https://render.com/docs/workflows)
- **SDK repo:** [github.com/render-oss/sdk](https://github.com/render-oss/sdk)

## Related Skills

- **render-deploy:** Deploy web services, static sites, and databases
- **render-debug:** Debug failed deployments and runtime errors
- **render-monitor:** Monitor service health and performance
