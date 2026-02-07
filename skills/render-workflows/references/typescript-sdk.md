# TypeScript SDK Reference

Based on the [SDK repo](https://github.com/render-oss/sdk/tree/main/typescript) (`npm install @renderinc/sdk`). Node.js 18+.

## Defining Tasks

Use the `task()` function from `@renderinc/sdk/workflows`:

```typescript
import { task } from "@renderinc/sdk/workflows";

// Simple task
const square = task(
  { name: "square" },
  function square(a: number): number {
    return a * a;
  },
);

// Task with retry and timeout
task(
  {
    name: "fetchData",
    retry: {
      maxRetries: 3,
      waitDurationMs: 1000,
      backoffScaling: 1.5,
    },
    timeoutSeconds: 300,
    plan: "standard",
  },
  async function fetchData(url: string): Promise<object> {
    // ...
  },
);
```

### RegisterTaskOptions

| Option | Type | Description |
|--------|------|-------------|
| `name` | `string` | **Required.** Task name. Affects the task slug. |
| `retry` | `RetryOptions` | Optional retry configuration |
| `timeoutSeconds` | `number` | Max execution time (30-86400 seconds) |
| `plan` | `string` | Resource plan: `"starter"`, `"standard"`, `"pro"` |

### RetryOptions

```typescript
{
  maxRetries: 3,       // max retries (total attempts = maxRetries + 1)
  waitDurationMs: 1000, // base delay before first retry (ms)
  backoffScaling: 1.5,  // backoff multiplier (default 1.5)
}
```

### Resource Plans

| Plan | CPU | Memory |
|------|-----|--------|
| `"starter"` | 0.5 CPU | 512 MB |
| `"standard"` | 1 CPU | 2 GB |
| `"pro"` | 2 CPU | 4 GB |

> **Note:** During early access, all task instances have 1 CPU and 2 GB RAM regardless of plan setting.

## Auto-Start Behavior

The task server starts automatically when `RENDER_SDK_SOCKET_PATH` is set (which Render sets in the workflow environment). No explicit `startTaskServer()` call is needed.

To disable auto-start, set `RENDER_SDK_AUTO_START=false`.

## Subtasks

Tasks can call other tasks. Each subtask runs in its own instance:

```typescript
const square = task(
  { name: "square" },
  function square(a: number): number {
    return a * a;
  },
);

task(
  { name: "addSquares" },
  async function addSquares(a: number, b: number): Promise<number> {
    const result1 = await square(a);   // runs as subtask
    const result2 = await square(b);
    return result1 + result2;
  },
);
```

### Parallel Subtasks

Use `Promise.all` for parallel execution:

```typescript
task(
  { name: "fanOut" },
  async function fanOut(items: number[]): Promise<number[]> {
    return Promise.all(items.map(item => square(item)));
  },
);
```

### Important Rules

- Subtask calls return a Promise, `await` to get the result.
- Non-task functions called inside a task run normally (no separate instance).
- Arguments and return values must be JSON-serializable.
- All task arguments are positional and required.

## The Render Client (Running Tasks)

Use the `Render` class to trigger tasks from other services:

```typescript
import { Render } from "@renderinc/sdk";

const render = new Render(); // uses RENDER_API_KEY from environment

// Run a task and wait for completion
const result = await render.workflows.runTask("my-workflow/square", [5]);
console.log("Status:", result.status);
console.log("Results:", result.results);

// List recent task runs
const runs = await render.workflows.listTaskRuns({ limit: 10 });

// Get specific task run
const details = await render.workflows.getTaskRun(result.id);
```

### Constructor Options

```typescript
import { Render } from "@renderinc/sdk";

const render = new Render({
  token: "rnd_abc123...",              // defaults to RENDER_API_KEY env var
  baseUrl: "https://api.render.com",   // defaults to Render API
  useLocalDev: false,                  // use local task server
  localDevUrl: "http://localhost:8120", // local server URL
});
```

### Alternative: Direct Workflows Client

```typescript
import { createWorkflowsClient } from "@renderinc/sdk/workflows";

const client = createWorkflowsClient({
  token: "rnd_abc123...",
  baseUrl: "https://api.render.com",
});
const result = await client.runTask("my-workflow/square", [5]);
```

### Client Methods

| Method | Description |
|--------|-------------|
| `render.workflows.runTask(taskId, inputData, signal?)` | Run a task. Returns `TaskRunDetails`. |
| `render.workflows.listTaskRuns(params)` | List task runs with optional filters. |
| `render.workflows.getTaskRun(taskRunId)` | Get details of a specific task run. |

### Task Identifier Format

```
{workflow-slug}/{task-name}
```

Example: `"my-workflow/square"`

The slug is visible on the task's page in the Render Dashboard.

### TaskRunDetails

```typescript
interface TaskRunDetails {
  id: string;                // "trn-abc123..."
  status: TaskRunStatus;     // "pending" | "running" | "completed" | "failed"
  created_at: string;
  updated_at: string;
  completed_at?: string;
  task_identifier: string;
  results?: any[];           // return value (when completed)
  error?: string;            // error message (when failed)
}
```

### AbortSignal Support

Cancel long-running task requests:

```typescript
import { Render, AbortError } from "@renderinc/sdk";

const render = new Render();
const controller = new AbortController();

setTimeout(() => controller.abort(), 5000);

try {
  const result = await render.workflows.runTask(
    "my-workflow/long-task",
    [42],
    controller.signal,
  );
} catch (error) {
  if (error instanceof AbortError) {
    console.log("Request cancelled");
  }
}
```

## Error Handling

```typescript
import {
  RenderError,   // base class for all SDK errors
  ClientError,   // 400-level API errors
  ServerError,   // 500-level API errors
  AbortError,    // request aborted via AbortSignal
} from "@renderinc/sdk";

try {
  const result = await render.workflows.runTask("my-workflow/task", [42]);
} catch (error) {
  if (error instanceof ClientError) {
    console.error("Bad request:", error.statusCode, error.cause);
  } else if (error instanceof ServerError) {
    console.error("Server error:", error.statusCode);
  } else if (error instanceof AbortError) {
    console.error("Aborted");
  } else if (error instanceof RenderError) {
    console.error("SDK error:", error.message);
  }
}
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `RENDER_API_KEY` | API authentication token |
| `RENDER_SDK_SOCKET_PATH` | Unix socket path (set automatically by Render) |
| `RENDER_SDK_MODE` | `"run"` or `"register"` (set automatically) |
| `RENDER_SDK_AUTO_START` | Set `"false"` to disable auto-start |
| `RENDER_USE_LOCAL_DEV` | Set `"true"` to use local task server |
| `RENDER_LOCAL_DEV_URL` | Custom local server URL (default: `http://localhost:8120`) |

## Package Exports

```typescript
// Main SDK (Render client, errors)
import { Render, RenderError, ClientError, ServerError, AbortError } from "@renderinc/sdk";

// Workflows task definition
import { task, startTaskServer } from "@renderinc/sdk/workflows";

// Workflows client (alternative to Render class)
import { createWorkflowsClient } from "@renderinc/sdk/workflows";
```
