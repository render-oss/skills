# Python SDK Reference

Based on the [SDK repo](https://github.com/render-oss/sdk/tree/main/python) (`pip install render_sdk`). Python 3.10+.

## The Workflows Class

The `Workflows` class is the main entry point for defining tasks. It manages task registration, default configuration, and auto-starting the task server.

```python
from render_sdk import Retry, Workflows

app = Workflows(
    default_retry=Retry(max_retries=3, wait_duration_ms=1000, backoff_scaling=2.0),
    default_timeout=300,        # seconds (5 minutes)
    default_plan="standard",    # "starter", "standard", or "pro"
    auto_start=True,            # auto-start worker on exit
)
```

### Constructor Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `default_retry` | `Retry` | `Retry(max_retries=3, wait_duration_ms=1000, backoff_scaling=2.0)` | Default retry config for all tasks |
| `default_timeout` | `int` | `300` | Default timeout in seconds (30-86400) |
| `default_plan` | `str` | `"standard"` | Default resource plan |
| `auto_start` | `bool` | `False` | Auto-start task server when `RENDER_SDK_MODE` and `RENDER_SDK_SOCKET_PATH` are set |

### Resource Plans

| Plan | CPU | Memory |
|------|-----|--------|
| `"starter"` | 0.5 CPU | 512 MB |
| `"standard"` | 1 CPU | 2 GB |
| `"pro"` | 2 CPU | 4 GB |

> **Note:** During early access, all task instances have 1 CPU and 2 GB RAM regardless of plan setting.

## The @app.task Decorator

Register a function as a workflow task:

```python
# Minimal: use all defaults from Workflows()
@app.task
def calculate_square(a: int) -> int:
    return a * a

# With per-task overrides
@app.task(name="custom_square", retry=Retry(max_retries=5, wait_duration_ms=2000))
def my_square(a: int) -> int:
    return a * a
```

### Decorator Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `name` | `str` | Custom task name (defaults to function name). Affects the task slug. |
| `retry` | `Retry` | Per-task retry config, overrides the `Workflows` default |
| `timeout` | `int` | Per-task timeout in seconds, overrides the `Workflows` default |
| `plan` | `str` | Per-task resource plan, overrides the `Workflows` default |

### Retry Configuration

```python
from render_sdk import Retry

Retry(
    max_retries=3,          # max retries (total attempts = max_retries + 1)
    wait_duration_ms=1000,  # base delay before first retry (ms)
    backoff_scaling=2.0,    # multiply delay after each retry (exponential backoff)
)
```

## Async Tasks and Subtasks

Tasks that call other tasks must be `async`:

```python
@app.task
async def add_squares(a: int, b: int) -> int:
    result1 = await square(a)   # runs subtask in its own instance
    result2 = await square(b)
    return result1 + result2
```

### Parallel Subtasks

Use `asyncio.gather` to run subtasks in parallel:

```python
import asyncio

@app.task
async def fan_out(n: int) -> list[int]:
    squares = [square(i) for i in range(n)]
    results = await asyncio.gather(*squares)
    return list(results)
```

### Important Rules

- **Subtask calls return a `TaskInstance`**, not the function's return value. You must `await` to get the result.
- **Non-task functions** called inside a task run normally (no separate instance).
- **Arguments and return values must be JSON-serializable.**
- **All task arguments are positional and required.**

## Organizing Tasks Across Files

Tasks can be defined in multiple files inside the `workflows/` directory. Import all task modules from your entry point so they register:

```python
# workflows/main.py
from render_sdk import Workflows

app = Workflows(auto_start=True)

import math_tasks    # registers tasks in workflows/math_tasks.py
import data_tasks    # registers tasks in workflows/data_tasks.py
```

```python
# workflows/math_tasks.py
from main import app

@app.task
def square(a: int) -> int:
    return a * a
```

## The Render Client (Running Tasks)

Use the `Render` client to trigger tasks from other services (web apps, cron jobs, etc.):

```python
import asyncio
from render_sdk import Render

async def main():
    render = Render()  # uses RENDER_API_KEY from environment

    # Run a task
    started = await render.workflows.run_task(
        task_identifier="my-workflow/square",
        input_data=[5],
    )
    print(f"Task started: {started.id}, status: {started.status}")

    # Wait for completion (SSE streaming)
    finished = await started
    print(f"Result: {finished.results}")

asyncio.run(main())
```

### Client Constructor

```python
from render_sdk import Render

render = Render(
    token="rnd_abc123...",                 # defaults to RENDER_API_KEY env var
    base_url="https://api.render.com",     # defaults to Render API
)
```

For local development, set `RENDER_USE_LOCAL_DEV=true` in your environment, or pass `base_url="http://localhost:8120"`.

### Client Methods

| Method | Description |
|--------|-------------|
| `await render.workflows.run_task(task_identifier, input_data)` | Start a task run. Returns `AwaitableTaskRun`. |
| `await render.workflows.list_task_runs(params)` | List task runs with optional filters. |
| `await render.workflows.get_task_run(task_run_id)` | Get details of a specific task run. |
| `await render.workflows.cancel_task_run(task_run_id)` | Cancel a running task. |

### Task Identifier Format

```
{workflow-slug}/{task-name}
```

Example: `"my-workflow/calculate-square"`

The slug is visible on the task's page in the Render Dashboard.

### AwaitableTaskRun

Returned by `run_task()`. Provides `id` and `status` immediately. `await` it to get the full `TaskRunDetails`:

```python
started = await render.workflows.run_task("my-workflow/square", [5])
print(started.id)       # available immediately
print(started.status)   # "pending"

finished = await started  # waits for completion via SSE
print(finished.results)   # [25]
print(finished.status)    # "completed"
```

### TaskRunDetails Properties

| Property | Description |
|----------|-------------|
| `id` | Task run ID (`trn-abc123...`) |
| `task_id` | Associated task ID (`tsk-abc123...`) |
| `status` | `pending`, `running`, `completed`, `failed`, `canceled` |
| `results` | Return value (only when `completed`) |
| `input_` | Input arguments (note trailing underscore) |
| `retries` | Number of retries performed |
| `parent_task_run_id` | Parent task run ID (if subtask) |
| `root_task_run_id` | Root task run ID in execution chain |

### ListTaskRunsParams

```python
from render_sdk.client import ListTaskRunsParams

params = ListTaskRunsParams(
    limit=10,
    cursor="cfQ74cE2sDI=",
    owners=["tea-d3jm7ai4d50c73fale60"],
)
task_runs = await render.workflows.list_task_runs(params)
```

## Error Handling

```python
from render_sdk.client.errors import (
    RenderError,      # base class for all SDK exceptions
    ClientError,      # 400-level API errors (invalid key, bad args)
    ServerError,      # 500-level API errors
    TimeoutError,     # request timeout
    TaskRunError,     # raised when awaited task run fails
)

try:
    result = await render.workflows.run_task("my-workflow/task", [42])
    finished = await result
except TaskRunError as e:
    print(f"Task failed: {e}")
except ClientError as e:
    print(f"Bad request: {e}")
except ServerError as e:
    print(f"Server error: {e}")
```
