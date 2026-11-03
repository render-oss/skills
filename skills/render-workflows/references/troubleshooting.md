# Troubleshooting

Use this reference for common Render Workflows setup, registration, execution, and client failures. Check the current [Workflows documentation](https://render.com/docs/workflows) and installed SDK version before relying on an implementation detail.

## CLI and Local Server

### `render workflows` or a subcommand is unavailable

Run `render --version` and upgrade the CLI. Different workflow features arrived in different versions; this skill uses 2.16.0 or later for scaffolding, local development, and CLI deployment.

On macOS with Homebrew:

```bash
brew upgrade render
```

For other platforms, follow the current [CLI installation guide](https://render.com/docs/cli#installation).

### Local task server does not start

| Cause | Resolution |
|---|---|
| Start command is wrong | Run the same entrypoint used by the workflow service, such as `python main.py` or `npm start`. |
| Python dependencies are in a virtual environment | Use its interpreter, such as `.venv/bin/python main.py`. |
| Python entrypoint does not call `app.start()` | Add the call to the executed entrypoint. |
| Port is occupied | Start with `--port <port>` and pass the same port to every local CLI or SDK call. |
| Docker-based workflow | Use a native local entrypoint or test after deployment; Docker workflows do not currently support the local task server. |

Do not run a Python workflow entrypoint directly when it expects Render runtime variables. Start it through:

```bash
render workflows dev -- python main.py
```

### Environment variables are missing locally

The CLI loads `.env` from its current directory. Run from the intended workflow root, or pass one or more explicit files:

```bash
render workflows dev --env-file .env --env-file .env.local -- python main.py
```

Later files override earlier ones. Confirm that secrets are ignored by Git and do not print their values during diagnosis.

## SDK 1.x Migration Failures

### Python cannot import `render_sdk`

The current Python distribution and import module are named `render`:

```bash
python -m pip install 'render>=1.0.1'
python -c 'import render; print(render.__file__)'
```

Update imports such as:

```python
from render import Render, Retry, TaskContext, Workflows
```

### Task registration rejects the function signature

Every task must accept `TaskContext` as its first positional parameter, including tasks that do not use it:

```python
@app.task
def ping(_ctx: TaskContext) -> str:
    return "pong"
```

```typescript
task({ name: "ping" }, (_ctx: TaskContext) => "pong");
```

The context is supplied by Render and is not included in CLI, SDK, or API task input.

### A registered task is “not callable”

SDK 1.x returns a task definition, not a callable wrapper.

- From another task, use `await ctx.run(task_definition, ...args)`.
- In a unit test, call `task_definition.func(fake_context, ...args)` explicitly.
- From an application or script, use `Render().workflows.start_task()` or `run_task()` and the task slug.

Do not restore direct calls as a workaround; direct calls would bypass distributed execution and task-run observability.

## Task Registration

When tasks work locally but not remotely, explain that `--local` queries the local dev server; remote listing reads a deployed workflow version. Check the released version, its registration logs, synchronous entrypoint imports, the exact `{workflow-slug}/{task-name}` identifier, and credentials on the calling service. Read the deployed task identifier from the Dashboard, CLI task list for the ready workflow version, or API response, and compare it with the caller’s string. A syntactically valid slug can still identify the wrong workflow or task.

### Local task list is empty or missing tasks

| Cause | Resolution |
|---|---|
| Missing `--local` | Use `render workflows tasks list --local`. |
| Server is not running | Start `render workflows dev` in another terminal first. |
| Python module is not incorporated | Import its `Workflows` object and combine apps with `Workflows.from_workflows(...)`. |
| TypeScript module is not imported | Add a synchronous module import to the entrypoint. |
| TypeScript task registered after auto-start | Define and import tasks synchronously at module scope; avoid dynamic imports for registration. |
| Duplicate task name | Give every task a unique registered name. |

TypeScript's registry can replace a previous task with the same name, so detect duplicates during review rather than relying on a runtime error.

### TypeScript exits during auto-start

The TypeScript SDK auto-starts task registration when `RENDER_SDK_SOCKET_PATH` is present. Use the Render CLI locally. Only set `RENDER_SDK_AUTO_START=false` when deliberately taking manual control of startup.

## Task Execution

### Chained run hangs or never starts

Check that:

- The parent task is `async`.
- The child is registered in the same workflow service.
- The call is `await ctx.run(child, ...)`.
- Parallel calls are collected with `asyncio.gather`, `asyncio.TaskGroup`, `Promise.all`, or a deliberate equivalent.

Awaiting each independent child one at a time makes the chain serial rather than parallel.

### Python rejects mixed task arguments

`ctx.run` accepts positional arguments or named arguments, not both in the same call:

```python
await ctx.run(task, first, second)
await ctx.run(task, left=first, right=second)
```

The same distinction applies when triggering a Python task through the SDK: send a list for positional input or a dictionary for named input.

### Input or result is not JSON-serializable

Convert values to JSON-compatible objects before passing or returning them. In particular, encode dates, byte strings, sets, class instances, and TypeScript `BigInt` values explicitly.

For current payload-size limits, consult [Limits and Pricing for Render Workflows](https://render.com/docs/workflows-limits).

### Retried task duplicates a side effect

Retries rerun task logic. Use idempotency keys, upserts, transactional guards, or downstream deduplication for writes, payments, messages, and other mutations. Do not enable retries on unsafe operations without a repeat-safety strategy.

### Timeout or compute plan is rejected

Verify the task option name first:

- Python task: `timeout_seconds=` and `plan=`
- Python workflow default: `default_timeout=` and `default_plan=`
- TypeScript task: `timeoutSeconds` and `plan`

Then resolve current timeout bounds and compute-plan IDs from [Limits and Pricing for Render Workflows](https://render.com/docs/workflows-limits). Do not substitute a remembered legacy plan name.

## Flows

### Flow run fails with a `DeterminismError`

A replay made different `ctx` calls than the recorded history: a step was added, removed, reordered, renamed, or given different arguments. Common causes are reading the clock, random values, or external state in flow code outside a step, iterating an unordered collection. Move non-deterministic work into steps. Catching the error does not help, because the run still fails. See [flows.md](flows.md#rules-for-flow-code).

### Flow fails even though it catches an error

Catch only `StepError`. A determinism error, a `ctx` call from inside a step, or a canceled run stops the run even when flow code catches the error. Python SDK 1.7.0 keeps an exhausted step fatal even if caught. A catch-and-fallback pattern requires a newer SDK with verified catchable recorded step failures; check exports and behavior before suggesting it.

### Flow rejects a call or registration

- A Python flow or step function is `async`: Python flows and steps must be sync.
- A flow has a retry policy: set `retry` on its steps instead.
- A flow calls `ctx.invoke`, or a task passes a flow to `ctx.run`: neither is supported yet.
- A step's function makes a `ctx` call, or a TypeScript flow runs `ctx` calls concurrently: make `ctx` calls one at a time from the flow function.
- A step has no name: pass the step name as the first argument to `ctx.step`.

## API Client

### `await Render()` fails in Python

`Render` is synchronous. Use `RenderAsync` in an async context:

```python
from render import RenderAsync

render = RenderAsync()
result = await render.workflows.run_task("my-workflow/task", [42])
```

Use `Render` without `await` in synchronous code.

### Unauthorized or API key missing

The SDK uses `RENDER_API_KEY` unless a token is passed to the constructor. Verify it is actually set on the calling web service, not only in your terminal or the workflow service. Confirm that the key belongs to a user with access to the workflow's workspace. Never log or commit the key.

### Client wait was aborted but the run continues

Canceling a TypeScript `AbortSignal`, closing an SSE stream, or interrupting a local wait does not cancel the remote run. Call the explicit cancellation method with the root task run ID:

```typescript
await render.workflows.cancelTaskRun(taskRunId);
```

Canceling a root run cancels its active chained runs. A child run is not an independent cancellation target.

### Run listing shape is unexpected

Current list methods return cursor-bearing wrappers:

- Python: access `.task_run` on each item.
- TypeScript: access `.taskRun` on each item.

Use the returned cursor for pagination instead of assuming one call returns all runs.

### Rate limiting or queued runs

API-triggered runs and chained runs have different limits and queueing behavior. Consult [Limits and Pricing for Render Workflows](https://render.com/docs/workflows-limits) for current API rate, compute, and queueing rules. Back off on rate-limit responses; do not assume those requests were queued.

## Deployment

### `render workflows create` fails

Confirm the active workspace, backing Git remote, repository access, runtime, root directory, and exact build/run commands. For non-interactive creation, required fields must be passed as flags.

If `--repo .` cannot resolve the repository, inspect the local Git remote and pass the supported Git provider URL explicitly.

### Tasks do not appear after deployment

Check the workflow's build and release logs. Confirm that the deployed start command executes the same entrypoint verified locally and that all task modules are imported during registration.

To release a new version explicitly and wait for the outcome:

```bash
render workflows versions release <workflow-id> --wait
```

### Blueprint sync fails or the workflow is missing from a preview

Workflows are valid Blueprint services (`type: workflow`). Common failures:

| Symptom | Cause | Fix |
|---------|-------|-----|
| Schema / validate error on `plan` | Service-level `plan` is not allowed on workflows | Remove `plan`. Set compute on the task in code. |
| Workflow deploys but behaves unexpectedly with `runtime: docker` | Workflow runtimes are `python` and `node` only. `render blueprints validate` currently accepts `runtime: docker` on a workflow even though the published schema rejects it, so a passing validate is not proof the runtime is supported | Use `runtime: python` or `runtime: node`. Validate against `https://render.com/schema/render.yaml.json` rather than trusting the CLI result alone |
| Preview stack has no workflow | Preview environments skip workflows | Expected. Other services still replicate. Trigger tasks against the non-preview workflow or deploy the workflow separately. |
| Blueprint rejected for duplicate name | A Blueprint-managed workflow with that `name` already exists in the workspace | Rename the service, or adopt the existing resource instead of creating a second one |

Do not copy the stale Workflows FAQ bullet that says Blueprints cannot manage workflows. Confirm against the [changelog](https://render.com/changelog/added-blueprint-support-for-render-workflows) and `https://render.com/schema/render.yaml.json`.

## Durable Workflow Failures


Read [flows.md](flows.md) for the execution contract and [durability.md](durability.md) for replay diagnosis and recovery checks.

| Symptom | Investigation and action |
| --- | --- |
| Missing `workflow` / `step`, or unsupported-method error | Check the installed SDK revision and backend feature availability; an older release or a stub cannot execute durable work |
| Async Python definition rejected | Use synchronous Python workflow definitions and step functions; verify the installed SDK signature |
| Registered task passed to `ctx.step` | Extract a plain helper for inline work; `ctx.invoke` is a separate capability requiring availability verification |
| Parallel or nested context calls rejected | Sequence durable steps and keep context calls outside step bodies |
| Replay mismatch | Inspect the identified step, inputs, name, and call order; move nondeterminism into steps and preserve stable input ordering |
| External effect happened twice | Check for a crash after the effect but before the completion record; use business-level idempotency |
| Interrupted step fails after recovery | Inspect persisted attempt counts and retry budget; infrastructure interruptions consume it |
| OOM in inline work | The workflow process shares the memory limit; reduce memory use or resize before starting a new run; OOM is terminal |
| Failure caught but run still fails | Determinism and other terminal runtime errors are not business errors to swallow; inspect the actual error type/reason |
| Local helpers pass but recovery is unknown | Run against a supported durable backend; ordinary local task execution does not prove history persistence or replay |

Never repair a replay mismatch by discarding recorded history automatically. Use a fresh development run with corrected code to validate the fix. Existing runs are intended to retain their original code version.
