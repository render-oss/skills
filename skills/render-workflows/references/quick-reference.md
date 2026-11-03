# Task SDK Reference

Use this reference for the current SDK 1.x programming model. Verify exact signatures against the installed package and the official [Python](https://render.com/docs/workflows-sdk-python) or [TypeScript](https://render.com/docs/workflows-sdk-typescript) reference before changing an existing project.

## Version and Source Checks

```bash
# Python distribution and import location
python -m pip show render
python -c 'import render; print(render.__file__)'

# TypeScript package
npm ls @renderinc/sdk
```

Current source locations:

- Python: `render/__init__.py`, `render/workflows/`, and `render/client/`
- TypeScript: `@renderinc/sdk/workflows` for task definitions and `@renderinc/sdk` for the API client
- Upstream examples: [Python](https://github.com/render-oss/sdk/tree/main/python/example) and [TypeScript](https://github.com/render-oss/sdk/tree/main/typescript/examples)

## Upgrade Legacy Task Calls

For pasted code without project access, identify the target SDK API and state that the installed version is unverified. Preserve a pinned legacy version unless the user requests an upgrade; update definitions and callers together when upgrading.

Add the runtime context as each task's first parameter, then replace direct decorated calls such as `square(n)` with `await ctx.run(square, n)`. Keep `asyncio.gather` or `Promise.all` around independent task calls to preserve fan-out. External callers continue to use the SDK client and do not supply the context.

## Define Tasks

| Concept | Python | TypeScript |
|---|---|---|
| Imports | `from render import TaskContext, Workflows` | `import { task, type TaskContext } from "@renderinc/sdk/workflows"` |
| Register | `@app.task` | `task(options, fn)` |
| Required first parameter | `ctx: TaskContext` | `ctx: TaskContext` |
| Chain another run | `await ctx.run(task_def, *args)` | `await ctx.run(taskDef, ...args)` |
| Start task server | `app.start()` | Automatic in the workflow environment |
| Combine files | `Workflows.from_workflows(app1, app2)` | Import task modules synchronously from the entrypoint |
| In-process unit call | `task_def.func(fake_ctx, *args)` | `taskDef.func(fakeCtx, ...args)` |
| Run IDs | `ctx.metadata.task_run_id`, `.root_task_run_id`, `.parent_task_run_id` | `ctx.metadata.taskRunId`, `.rootTaskRunId`, `.parentTaskRunId` |

For a root run, the root run ID equals the task run ID and the parent run ID is `None` in Python or `undefined` in TypeScript. `ctx.metadata` requires SDK 1.2.0 or later.

For durable flows (`@app.flow`, `flow()`, and `ctx.step`), read [flows.md](flows.md).

Minimal Python definition:

```python
from render import TaskContext, Workflows

app = Workflows()

@app.task
def square(_ctx: TaskContext, value: int) -> int:
    return value * value

@app.task
async def sum_squares(ctx: TaskContext, left: int, right: int) -> int:
    first = await ctx.run(square, left)
    second = await ctx.run(square, right)
    return first + second

if __name__ == "__main__":
    app.start()
```

Minimal TypeScript definition:

```typescript
import { task, type TaskContext } from "@renderinc/sdk/workflows";

const square = task(
  { name: "square" },
  (_ctx: TaskContext, value: number): number => value * value,
);

task(
  { name: "sumSquares" },
  async (ctx: TaskContext, left: number, right: number): Promise<number> => {
    const [first, second] = await Promise.all([
      ctx.run(square, left),
      ctx.run(square, right),
    ]);
    return first + second;
  },
);
```

## Task Options

| Purpose | Python | TypeScript |
|---|---|---|
| Custom name | `name=` | `name` |
| Retry | `retry=Retry(...)` | `retry: {...}` |
| Timeout | `timeout_seconds=` | `timeoutSeconds` |
| Compute plan | `plan=` | `plan` |

Python task defaults on the registration container are `default_retry`, `default_timeout`, and `default_plan` on `Workflows(...)`.

Do not copy plan IDs, compute specifications, timeout bounds, or prices from this reference. Resolve current values from [compute-plans.md](compute-plans.md) and [Limits and Pricing for Render Workflows](https://render.com/docs/workflows-limits).

Retry fields:

| Python | TypeScript |
|---|---|
| `max_retries` | `maxRetries` |
| `wait_duration_ms` | `waitDurationMs` |
| `backoff_scaling` | `backoffScaling` |

Retries can repeat side effects. A retried task that writes data, charges a customer, sends a message, or calls a mutating API needs an idempotency or deduplication strategy.

## Trigger Runs with the Client

| Operation | Python sync `Render` | Python async `RenderAsync` | TypeScript `Render` |
|---|---|---|---|
| Start without waiting | `start_task()` | `await start_task()` | `await startTask()` |
| Start and wait | `run_task()` | `await run_task()` | `await runTask()` |
| Wait on started run | Poll `get_task_run()` | `await started` | `await started.get()` |
| Get details | `get_task_run()` | `await get_task_run()` | `await getTaskRun()` |
| List runs | `list_task_runs()` | `await list_task_runs()` | `await listTaskRuns()` |
| Cancel root run | `cancel_task_run()` | `await cancel_task_run()` | `await cancelTaskRun()` |
| Stream terminal events | `task_run_events()` | `task_run_events()` async iterator | `taskRunEvents()` async iterator |

Python input can be positional or named:

```python
render.workflows.run_task("my-workflow/add", [2, 3])
render.workflows.run_task("my-workflow/add", {"left": 2, "right": 3})
```

TypeScript input is positional:

```typescript
await render.workflows.runTask("my-workflow/add", [2, 3]);
```

Make a start call safe to retry with an idempotency key (SDK 1.2.0 or later). A repeated call with the same key within 24 hours returns the original run. Keys are scoped to the workflow.

```python
render.workflows.start_task("my-workflow/add", [2, 3], idempotency_key="add-2-3")
```

```typescript
await render.workflows.startTask("my-workflow/add", [2, 3], { idempotencyKey: "add-2-3" });
```

In TypeScript, the third argument of `startTask()` and `runTask()` is an `AbortSignal` or an options object with `signal` and `idempotencyKey`.

Use the term **task slug** for `{workflow-slug}/{task-name}`. Task run IDs have the `trn-...` form.

`list_task_runs()` and `listTaskRuns()` return cursor-bearing wrapper objects; access the task run through `.task_run` in Python and `.taskRun` in TypeScript.

## Error Types

| Python | TypeScript | Meaning |
|---|---|---|
| `RenderError` | `RenderError` | Base SDK error |
| `ClientError` | `ClientError` | Client or 4xx response |
| `RateLimitError` | `ClientError` with rate-limit status | Rate limited |
| `ServerError` | `ServerError` | Server, network, or 5xx failure |
| `TimeoutError` | — | Request timeout |
| `TaskRunError` | — | Task run failed or was canceled while waiting |
| — | `AbortError` | Client-side operation aborted |

Python error imports come from `render.client.errors`. TypeScript errors are exported from `@renderinc/sdk`.

Aborting an SDK request or wait does not cancel the remote task run. Call the explicit cancellation method with the root task run ID.

## Environment Variables

| Variable | Purpose |
|---|---|
| `RENDER_API_KEY` | Authenticate SDK calls to the Render API |
| `RENDER_SDK_SOCKET_PATH` | Internal task-runtime socket set by Render or the CLI |
| `RENDER_SDK_MODE` | Internal Python registration or run mode |
| `RENDER_SDK_AUTO_START` | Set to `false` to disable TypeScript auto-start |
| `RENDER_USE_LOCAL_DEV` | Set to `true` to use the local task server |
| `RENDER_LOCAL_DEV_URL` | Override the local task server URL |

Do not ask users to set internal runtime variables manually. Start local workflows through `render workflows dev`.
