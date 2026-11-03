# Task Patterns

Use these patterns for task chaining, parallel fan-out, and per-task retries.

These examples use the Render SDK 1.x task model. Every task accepts `TaskContext` first, and chained runs go through `ctx.run`.

For Python snippets, assume:

```python
from render import Retry, TaskContext, Workflows

app = Workflows()
```

For TypeScript snippets, assume:

```typescript
import { task, type TaskContext } from "@renderinc/sdk/workflows";
```

## Fan-Out and Fan-In

Use concurrent chaining when independent work benefits from separate compute and retry boundaries. For binary processing, upload the intermediate artifact within the producing task and return its storage key or URL; the next task fetches it. Never pass Python bytes or TypeScript buffers through ctx.run.

Python:

```python
import asyncio

@app.task
def process_image(_ctx: TaskContext, url: str) -> dict:
    return {"url": url, "success": True}

@app.task
async def process_batch(ctx: TaskContext, image_urls: list[str]) -> dict:
    results = await asyncio.gather(
        *(ctx.run(process_image, url) for url in image_urls)
    )
    successful = sum(1 for result in results if result["success"])
    return {
        "total": len(image_urls),
        "processed": successful,
        "failed": len(image_urls) - successful,
        "results": list(results),
    }
```

TypeScript:

```typescript
const processImage = task(
  { name: "processImage" },
  function processImage(_ctx: TaskContext, url: string) {
    return { url, success: true };
  },
);

task(
  { name: "processBatch" },
  async function processBatch(ctx: TaskContext, imageUrls: string[]) {
    const results = await Promise.all(
      imageUrls.map((url) => ctx.run(processImage, url)),
    );
    const successful = results.filter((result) => result.success).length;
    return {
      total: imageUrls.length,
      processed: successful,
      failed: imageUrls.length - successful,
      results,
    };
  },
);
```

Avoid unbounded fan-out when the input can be arbitrarily large. Batch inputs or add application-level concurrency control when downstream systems, rate limits, or cost require it.

## Sequential Pipeline

Use sequential chaining when each stage depends on the prior stage's result.

Python:

```python
@app.task
def extract(_ctx: TaskContext, source: str) -> dict:
    return {"source": source, "records": []}

@app.task
def transform(_ctx: TaskContext, data: dict) -> dict:
    return {"records": data["records"]}

@app.task
def load(_ctx: TaskContext, destination: str, data: dict) -> dict:
    return {"destination": destination, "loaded": len(data["records"])}

@app.task
async def etl_pipeline(
    ctx: TaskContext,
    source: str,
    destination: str,
) -> dict:
    raw_data = await ctx.run(extract, source)
    transformed = await ctx.run(transform, raw_data)
    return await ctx.run(load, destination, transformed)
```

TypeScript:

```typescript
const extract = task(
  { name: "extract" },
  (_ctx: TaskContext, source: string) => ({ source, records: [] as object[] }),
);

const transform = task(
  { name: "transform" },
  (_ctx: TaskContext, data: { records: object[] }) => ({ records: data.records }),
);

const load = task(
  { name: "load" },
  (_ctx: TaskContext, destination: string, data: { records: object[] }) => ({
    destination,
    loaded: data.records.length,
  }),
);

task(
  { name: "etlPipeline" },
  async function etlPipeline(
    ctx: TaskContext,
    source: string,
    destination: string,
  ) {
    const rawData = await ctx.run(extract, source);
    const transformed = await ctx.run(transform, rawData);
    return ctx.run(load, destination, transformed);
  },
);
```

## Retries and Idempotency

Tasks retry automatically by default. Before running tasks that send emails, charge payments, or modify external state, use idempotency keys or another deduplication mechanism to prevent duplicate effects.

Two kinds of idempotency apply. The SDK's `idempotency_key` (Python) or `idempotencyKey` (TypeScript) on `start_task()` and `startTask()` stops a retried client call from starting a second run. It does not stop a task retry from repeating the task's side effects. For those, pass a stable key, such as one derived from the order ID, to the downstream API.

If a multi-step task must not repeat its finished steps when it fails partway, consider a durable flow instead. See [flows.md](flows.md).

Python:

```python
@app.task(
    retry=Retry(
        max_retries=5,
        wait_duration_ms=2000,
        backoff_scaling=2.0,
    )
)
def fetch_document(_ctx: TaskContext, url: str) -> str:
    import urllib.request

    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read().decode()
```

TypeScript:

```typescript
task(
  {
    name: "fetchDocument",
    retry: {
      maxRetries: 5,
      waitDurationMs: 2000,
      backoffScaling: 2,
    },
  },
  async function fetchDocument(_ctx: TaskContext, url: string): Promise<string> {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.text();
  },
);
```

Do not retry every error indiscriminately in task code. Let the configured task policy handle run retries, and distinguish permanent validation failures from transient upstream failures when the task itself implements request-level retry logic. For common execution issues and fixes, see [troubleshooting.md](troubleshooting.md).

## Testing Task Logic In Process

SDK 1.x returns task definitions rather than callable task wrappers. Invoke `.func` with a test context for unit tests:

Python:

```python
class NoSubtasks:
    async def run(self, task, *args, **kwargs):
        raise AssertionError("unexpected chained run")

assert process_image.func(NoSubtasks(), "https://example.com/a.png")["success"]
```

TypeScript:

```typescript
const noSubtasks = {
  metadata: {},
  run: async () => {
    throw new Error("unexpected chained run");
  },
};

const result = processImage.func(noSubtasks, "https://example.com/a.png");
```

For orchestration tests, supply a fake `TaskContext.run` that records task definitions and returns controlled results.

## Scheduled Trigger

Render Workflows does not currently provide native scheduling. A Render cron job can trigger a deployed task with the SDK client.

Python sync client:

```python
from render import Render

def main() -> None:
    render = Render()
    result = render.workflows.run_task("my-workflow/daily-cleanup", [])
    print(result.status)

if __name__ == "__main__":
    main()
```

TypeScript:

```typescript
import { Render } from "@renderinc/sdk";

const render = new Render();
const result = await render.workflows.runTask("my-workflow/daily-cleanup", []);
console.log(result.status);
```

Store `RENDER_API_KEY` as a secret on the triggering service.

## Cross-Workflow Call

`ctx.run` only chains tasks in the same workflow service. To call a different workflow, use the API client. This creates an independent run rather than a parent-child relationship in the workflow graph.

Python:

```python
from render import RenderAsync

@app.task
async def orchestrate(_ctx: TaskContext, data: dict) -> object:
    render = RenderAsync()
    result = await render.workflows.run_task(
        "other-workflow/process",
        [data],
    )
    return result.results
```

TypeScript:

```typescript
import { Render } from "@renderinc/sdk";

task(
  { name: "orchestrate" },
  async function orchestrate(_ctx: TaskContext, data: object): Promise<unknown> {
    const render = new Render();
    const result = await render.workflows.runTask(
      "other-workflow/process",
      [data],
    );
    return result.results;
  },
);
```

Cross-workflow calls require an API key and are subject to Render API behavior. Prefer same-workflow chaining when the tasks form one logical execution graph.
