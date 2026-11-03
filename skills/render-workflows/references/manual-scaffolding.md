# Direct SDK Project Setup

The walkthroughs below register a task and invoke it from a separate client process.

Use this reference to add the Render Workflows SDK directly to an existing codebase or create a minimal workflow service without `render workflows init`. Preserve an existing project's dependency, module, and build conventions. For a new standalone service, prefer adapting the current official [Python examples](https://github.com/render-examples/render-workflows-examples-python) or [TypeScript examples](https://github.com/render-examples/render-workflows-examples-ts) over copying this minimal structure blindly.

## Choose the Language and Boundary

Use the language requested by the user. Otherwise infer it from the project:

| Indicators | Language |
|---|---|
| `pyproject.toml`, `requirements.txt`, `Pipfile`, or Python source | Python |
| `package.json`, `tsconfig.json`, or TypeScript source | TypeScript |

If both ecosystems are present, prefer the language already used by the component that will trigger or own the workflow. Ask only when the choice materially changes the integration.

Create a self-contained workflow service directory when the workflow has an independent build or deployment boundary. Do not overwrite unrelated root dependency files.

In an existing application, add a dedicated workflow entrypoint and run it separately from the web server. Keep task registration out of the client script and preserve the application's start command; add a script such as `workflows:start` for the workflow process.

## Python

Minimum files:

```text
workflows/
|-- main.py
`-- requirements.txt
```

`requirements.txt`:

```text
render>=1.0.1
```

`main.py`:

```python
from render import TaskContext, Workflows

app = Workflows()

@app.task
def ping(_ctx: TaskContext) -> str:
    return "pong"

if __name__ == "__main__":
    app.start()
```

Install dependencies in an isolated environment:

```bash
cd workflows
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

Use an equivalent activation command on Windows or non-POSIX shells.

## TypeScript

Minimum files:

```text
workflows/
|-- src/
|   `-- main.ts
|-- package.json
`-- tsconfig.json
```

`package.json`:

```json
{
  "name": "my-workflow",
  "private": true,
  "type": "module",
  "scripts": {
    "workflows:start": "tsx src/main.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@renderinc/sdk": "^1.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "tsx": "^4.20.2",
    "typescript": "^5.0.0"
  }
}
```

`src/main.ts`:

```typescript
import { task, type TaskContext } from "@renderinc/sdk/workflows";

task(
  { name: "ping" },
  function ping(_ctx: TaskContext): string {
    return "pong";
  },
);
```

For this standalone example, use Node.js 20 or later and this `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noEmit": true,
    "skipLibCheck": true,
    "types": ["node"]
  },
  "include": ["src/**/*.ts"]
}
```

Install dependencies and check the TypeScript source:

```bash
cd workflows
npm install
npm run typecheck
```

When integrating into an established service, preserve its TypeScript configuration and use Node type definitions compatible with its runtime. Adapt the dedicated workflow script to its existing tooling.

## Try It Locally with the SDK

Use the `ping` task and dependencies defined above for your chosen language. No deployment, Render API key, or `render workflows init` is needed. The task server and calling script run in separate processes.

Before starting the server, run `render --version` and confirm CLI 2.12.0 or later. If you cannot run it, state that requirement and leave version compatibility unverified.

### Python

Add `client.py` next to `main.py`:

```python
from render import Render

render = Render()
result = render.workflows.run_task("ping", [])
assert result.results == ["pong"], result
print(result.results[0])
```

In terminal 1, from the workflow directory, start the task server:

```bash
render workflows dev -- .venv/bin/python main.py
```

In terminal 2, from the same directory, enable local mode for the **client process** and invoke the task:

```bash
render workflows tasks list --local
RENDER_USE_LOCAL_DEV=true .venv/bin/python client.py
```

### TypeScript

Add `src/client.ts`:

```typescript
import assert from "node:assert/strict";
import { Render } from "@renderinc/sdk";

const render = new Render();
const result = await render.workflows.runTask("ping", []);
assert.deepEqual(result.results, ["pong"]);
console.log(result.results[0]);
```

In terminal 1, from the workflow directory:

```bash
npm run typecheck
render workflows dev -- npm run workflows:start
```

In terminal 2, from the same directory:

```bash
render workflows tasks list --local
RENDER_USE_LOCAL_DEV=true npx tsx src/client.ts
```

### Confirm the Result

Confirm `ping` appears in the local task list, then confirm the client prints `pong`. These check registration and execution separately. Each client waits for completion and checks the result. Local calls use the registered task name `ping`; deployed calls use `{workflow-slug}/ping`. The empty array supplies zero task arguments; do not pass `TaskContext`. The external client's `results` field is an array, so this task's returned string is at index `0`.

The commands above use POSIX environment syntax. On other shells, set `RENDER_USE_LOCAL_DEV=true` in the client environment before running the script. For custom ports, set the matching `RENDER_LOCAL_DEV_URL` there too; see [local-development.md](local-development.md#trigger-local-runs-from-application-code). Keep these local settings out of deployed application environments.

If the client fails or stays pending, inspect local runs instead of repeatedly starting new ones:

```bash
render workflows tasks list --local -o text
render workflows tasks runs list ping --local -o text
render workflows tasks runs show <task-run-id> --local -o json
```

For this smoke test, bound the client wait (for example, one minute), inspect errors if it does not complete, and stop the local task server after verification when an agent started it. Run creation alone is not successful validation.

For deployment, use the workflow directory as the service's root directory and preserve the build/start commands validated locally. The current CLI can generate a `render workflows create` command from `workflows init`; when scaffolding manually, construct that command from the project's actual configuration.
