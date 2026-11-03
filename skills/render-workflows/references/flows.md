# Flows

Define flow orchestration with `@app.flow` in Python or `flow()` in TypeScript, and put work inside sequential `ctx.step` calls. Completed steps return their recorded results when the flow recovers.

## Availability

Python and TypeScript SDK 1.7.0 expose durable flows and named inline steps. SDK 1.5.0 does not expose these entry points, and CLI 2.32.0 does not add local durability support. The examples require SDK 1.7.0 or a compatible development SDK plus a compatible backend. An SDK upgrade alone does not establish backend availability.

Check Python and TypeScript independently. SDK 1.7.0 uses Python `@app.flow` and exports TypeScript `flow` from `@renderinc/sdk/workflows`. Confirm these exports before generating code; do not infer the TypeScript import from the Python decorator or product terminology.

| Capability | Behavior |
| --- | --- |
| TypeScript `flow()` / Python `@app.flow` | Durable entry point |
| `ctx.step` | Sequential inline execution of plain or anonymous functions, with recorded results and per-step retries |
| Recovery and replay | Resume after infrastructure failure using recorded history |
| Child or detached tasks (`ctx.invoke`) | Unsupported in SDK 1.7.0; verify newer SDK and backend support independently |
| `ctx.sleep` | Unsupported in SDK 1.7.0; verify newer SDK and backend support before use |
| Full local CLI durability development | Verify support separately from task local development |
| Signal waits | Verify an explicit signal API and backend support before use |
| Parallel durable steps | Unsupported by the sequential implementation described here; verify separately if targeting a different implementation |

Verify signatures against the installed SDK and the current SDK reference before adapting these examples to an existing project. For a multi-capability design, report supported, unsupported, or unverified for each requested operation: inline steps, child-task invocation, timers, signals, and parallel durable calls. Check SDK exports and backend support independently; record the evidence or the missing check for each. A working flow entry point establishes none of the other capabilities. A request to fan out to child tasks needs two separate checks: whether the flow can invoke registered tasks at all (`ctx.invoke`), and whether it can make those calls concurrently. Ordinary-task `ctx.run` support establishes neither.

```bash
python -c 'from render import FlowContext, Workflows; print(hasattr(Workflows, "flow"))'
node -e 'import("@renderinc/sdk/workflows").then((m) => console.log(typeof m.flow))'
```

The Python check prints `True` and the TypeScript check prints `function` when flows are supported. If the import fails, or the checks print `False` or `undefined`, the installed SDK predates flows. Do not upgrade the SDK unless the user asks. Read the SDK changelog first, and verify signatures against the installed package, because the flow API is still changing.

## Adopt Flows from Task Orchestration

Extract work into plain helpers, place external reads and side effects inside those helpers, and call them sequentially with named `ctx.step` calls and explicit step retries. Keep inputs and results JSON-serializable and pass stable operation identities into external writes. Retain task fan-out where parallel independent execution is required.

Verify flow registration and triggering with the selected SDK before switching callers, then follow [recovery verification](durability.md#recovery-verification). This changes execution behavior; replacing a decorator alone is insufficient. Existing runs keep their starting version and history.

## Inline functions versus registered tasks

`ctx.step` takes a plain or anonymous function, not a registered task. Every step needs an explicit, stable name as its first argument. Inline functions receive their own arguments, not a task context.

For shared logic, define a plain helper and wrap it in a registered task when task execution is needed. A flow can use the helper inline. Calling the registered task from a flow via `ctx.invoke` requires that feature to be supported; do not emulate it with an unrecorded SDK client call.

## Python

Use synchronous workflow definitions and synchronous step functions in Python. `ctx.step` returns the result directly.

Define plain functions, then call them as steps with an explicit retry policy:

```python
from render import Retry, Workflows

app = Workflows()


def normalize(text: str) -> str:
    return " ".join(text.split())


def count_words(text: str) -> int:
    return len(text.split())


def summarize(text: str, count: int) -> dict:
    return {"text": text, "word_count": count}


@app.flow
def summarize_text(ctx, text: str) -> dict:
    retry = Retry(max_retries=3, wait_duration_ms=1000, backoff_scaling=2.0)
    normalized = ctx.step("normalize", normalize, text, retry=retry)
    count = ctx.step("count_words", count_words, normalized, retry=retry)
    return ctx.step("summarize", summarize, normalized, count, retry=retry)


if __name__ == "__main__":
    app.start()
```

Pass the stable step name first, then the function and its positional arguments; `retry` is a keyword option. Use a named wrapper for helpers requiring keyword arguments. Keep explicit inputs visible rather than hiding changing data in a closure.

## TypeScript

SDK 1.7.0 exports `flow`; SDK 1.5.0 exports neither this durable entry point nor `workflow`. TypeScript steps return promises. Pass the stable step name first, then the function and its arguments in an array, put step options last, and await each step:

```typescript
import { flow } from "@renderinc/sdk/workflows";

function normalize(text: string): string {
  return text.trim().split(/\s+/).filter(Boolean).join(" ");
}

function countWords(text: string): number {
  return text ? text.split(" ").length : 0;
}

function summarize(text: string, count: number) {
  return { text, word_count: count };
}

flow({ name: "summarizeText" }, async (ctx, text: string) => {
  const retry = { maxRetries: 3, waitDurationMs: 1000, backoffScaling: 2.0 };
  const normalized = await ctx.step("normalize", normalize, [text], { retry });
  const count = await ctx.step("countWords", countWords, [normalized], { retry });
  return await ctx.step("summarize", summarize, [normalized, count], { retry });
});
```

For an anonymous step, use `await ctx.step("stableName", () => value, { retry })`. Capture nondeterministic results in a step once; include inputs explicitly when they determine the result.

## API Reference

| Concept | Python | TypeScript |
|---|---|---|
| Imports | `from render import FlowContext, Retry, Workflows` | `import { flow } from "@renderinc/sdk/workflows"` |
| Register | `@app.flow` or `@app.flow(name=..., timeout_seconds=..., plan=...)` | `flow({ name, timeoutSeconds?, plan? }, fn)` |
| Flow function | Sync only | Sync or async |
| Run a step | `ctx.step(name, fn, *args, retry=None)` | `await ctx.step(name, fn, [args], { retry })` |
| Step name | Required first argument | Required first argument |
| Step function | Sync only | Sync or async |
| Catch a failed step | Not supported after exhaustion in SDK 1.7.0; verify a newer SDK before using `StepError` | `catch (error)` with `error instanceof StepError` |
| Run ID | `ctx.metadata.flow_run_id` | `ctx.metadata.flowRunId` |
| Start the server | `app.start()` | Automatic in the workflow environment |

Python `ctx.step` reserves its keyword arguments for `retry`. Pass the step function's arguments positionally, or bind keyword arguments with `functools.partial`.

Flows and tasks can be registered in the same workflow service. Python registers both on the same `Workflows` app.

## Rules for Flow Code

A new workflow attempt runs the orchestration function from the top. Completed steps return their saved result. Code outside steps executes again, so it must make the same durable calls in the same order with the same inputs.

Put clock reads, UUID generation, randomness, external reads, model calls, and side effects inside steps when they affect subsequent execution. Use stable ordering when iterating over inputs. Keep arguments and results JSON-serializable; do not rely on object identity, shared mutations, files, or memory surviving a restart.

### Sequential calls

Only one durable context call can be active at a time. Await TypeScript steps sequentially; follow the verified Python contract. `Promise.all` or `asyncio.gather` over durable steps is not supported by the sequential execution model. A step function cannot make nested durable context calls. When correcting parallel durable code, explain the alternative explicitly: tasks can fan out with concurrent `ctx.run` calls on separate compute; durable flows use sequential inline `ctx.step` calls and recorded replay. Choose based on whether the caller needs parallel independent tasks or durable orchestration.

Step arguments and results are recorded as JSON, and `ctx.step` returns the decoded value on the first run as well as on replays. A TypeScript `Date` comes back as a string. A step whose arguments or result cannot be encoded fails without retrying.

For a divergent replay, follow [replay diagnosis](durability.md#diagnose-a-replay-mismatch).

## Retries, recovery, and side effects

For duplicate external effects, first reconcile step/attempt history with the provider’s transaction records. Explain the possible write-before-recording window as a hypothesis until those records establish the cause.

Recovery and step retries are separate mechanisms: infrastructure recovery replays the orchestration and reuses recorded results; a step retry policy controls whether an unfinished or failed step body can execute again. Flows do not accept a retry policy, and Python's `default_retry` does not apply to them. A step without `retry` runs once. An infrastructure interruption during a step consumes that step's retry budget. Exhausted steps fail, and OOM kills are terminal, including an OOM inside an inline step.

### Failed Steps

In TypeScript, an exhausted step throws `StepError`, which the flow can catch before running a fallback step. Import it from `@renderinc/sdk/workflows`, catch only that error, and rethrow other errors.

Python SDK 1.7.0 differs: an exhausted step remains fatal even if caught, and the context fails at the next step or on exit. Do not generate a Python fallback step after exhaustion for that version. A newer SDK must explicitly support catchable recorded step failures before using `from render.workflows import StepError` for this pattern; verify its exports and behavior first.

A determinism error, a context call from inside a step, or a canceled run stops the run even when flow code catches the error.

### External side effects

Steps have at-least-once execution semantics. An external write can succeed before its result is recorded, so recovery may repeat it. Use an idempotency key derived from the business operation, or a database uniqueness constraint/transaction that deduplicates it. Show that identity flowing into the actual write (for example, document_id into an upsert); a comment saying “make this idempotent” or a save helper that only returns a dictionary does not implement persistence. Reuse that identifier across retries and replay; generating a new key for each attempt defeats deduplication. Recorded outputs do not guarantee exactly-once business effects.

## Current Limitations

A task cannot run a flow through `ctx.run`. Start flows with the SDK client, CLI, or API. For child-task invocation, timers, signals, and parallel durable calls, use the capability checks under [Availability](#availability); do not infer support from task APIs or invent context methods.

## Start Flow Runs

Flow slugs use `{workflow-slug}/{flow-name}`. Append `:version` to run a specific version; otherwise the latest version runs.

Python:

```python
from render import Render

render = Render()
flow_run = render.workflows.start_flow(
    "my-workflow/summarize_text",
    ["hello world"],
    idempotency_key="summarize-document-123",
)
details = render.workflows.get_flow_run(flow_run.id)
print(details.status, details.results)
```

TypeScript:

```typescript
import { Render } from "@renderinc/sdk";

const render = new Render();
const details = await render.workflows.runFlow(
  "my-workflow/summarizeText",
  ["hello world"],
  { idempotencyKey: "summarize-document-123" },
);
console.log(details.status, details.results);
```

| Operation | Python `Render` / `RenderAsync` | TypeScript `Render` |
|---|---|---|
| Start without waiting | `start_flow()` | `startFlow()` |
| Start and wait | Poll `get_flow_run()` | `runFlow()` |
| Get details | `get_flow_run()` | `getFlowRun()` |
| List runs | `list_flow_runs()` | `listFlowRuns()` |
| Cancel a run | `cancel_flow_run()` | `cancelFlowRun()` |

A flow run finishes as `succeeded`, `failed`, or `canceled`. Use a JSON array for positional input. Python flows also accept a JSON object for named input.

## Inspect Deployed Flows with the CLI

Recent CLI versions include flow commands, which are hidden from `render workflows --help` until flows are generally available. Run `render workflows flows --help` to confirm the installed CLI has them.

```bash
render workflows flows list
render workflows flows runs start my-workflow/summarize_text --input='["hello world"]' -o json
render workflows flows runs show <flow-run-id> -o json
render workflows flows runs steps list <flow-run-id>
render workflows flows runs steps show <flow-run-id> <step-seq>
render workflows flows runs cancel <flow-run-id>
```

`flows runs start` accepts `--idempotency-key`. Use the step commands to see each recorded step, its attempts, and its error when a run fails.

## Local Development

CLI 2.32.0's local task server does not establish flow support. Check newer CLI capabilities independently; listing tasks with `--local` is not flow validation. Test plain helpers locally, then validate a deployed flow with a safe run and recorded step history. Follow [recovery verification](durability.md#recovery-verification) to distinguish a successful run from replay and infrastructure recovery tests.

## API sources

- [Python SDK 1.7.0 release](https://github.com/render-oss/sdk/releases/tag/python/v1.7.0)
- [TypeScript SDK 1.7.0 release](https://github.com/render-oss/sdk/releases/tag/typescript/v1.7.0)
- [CLI 2.32.0 release](https://github.com/render-oss/cli/releases/tag/v2.32.0)
- Development SDK contract: [Python context](https://github.com/renderinc/sdk/blob/28f7dbaebe064c3d2bfb5443cb641b801fdbe8ac/python/render/workflows/durable_context.py) and [TypeScript exports](https://github.com/renderinc/sdk/blob/28f7dbaebe064c3d2bfb5443cb641b801fdbe8ac/typescript/src/workflows/index.ts). These sources require internal repository access.
