# Durable Flows

A flow is a durable function registered in a workflow service. Each `ctx` call in a flow is a **step**, and Render records the step's result. If a flow attempt crashes, a later attempt reruns the flow from the top, and steps that already finished return their recorded results instead of running again. A task, in contrast, reruns all of its code when it retries.

Use a flow when a multi-step process must survive crashes without repeating finished work, for example charging a card and then sending a receipt. Use tasks for independent units of work, parallel fan-out, or anything a flow does not support yet (see [Current limitations](#current-limitations)).

## Check SDK Support First

Flows are newer than the rest of SDK 1.x. Before writing flow code, confirm the installed SDK exports them:

```bash
python -c 'from render import FlowContext; from render.workflows import StepError; print("flows supported")'
node -e 'import("@renderinc/sdk/workflows").then((m) => console.log(typeof m.flow))'
```

The TypeScript check prints `function` when flows are supported. If the import fails or prints `undefined`, the installed SDK predates flows. Do not upgrade the SDK unless the user asks. Read the SDK changelog first, and verify signatures against the installed package, because the flow API is still changing.

## Define a Flow

Python flows are sync functions registered with `@app.flow`. They take a `FlowContext` as their first parameter. `ctx.step(name, fn, *args)` runs `fn` as the step `name` and returns its result, so there is nothing to await.

```python
import uuid

from render import FlowContext, Retry, Workflows

app = Workflows()


def charge_card(order_id: str, total: int) -> dict:
    return payments.charge(order_id, total)


def send_receipt(email: str, charge_id: str) -> None:
    mailer.send(email, charge_id)


@app.flow
def fulfill_order(ctx: FlowContext, order_id: str, email: str, total: int) -> dict:
    charge = ctx.step(
        "charge_card",
        charge_card,
        order_id,
        total,
        retry=Retry(max_retries=3, wait_duration_ms=1000, backoff_scaling=2.0),
    )
    receipt_id = ctx.step("receipt_id", lambda: str(uuid.uuid4()))
    ctx.step("send_receipt", send_receipt, email, charge["id"])
    return {"charge": charge["id"], "receipt": receipt_id}


if __name__ == "__main__":
    app.start()
```

TypeScript flows are registered with `flow(options, fn)` and may be async. TypeScript passes step arguments as an array: `ctx.step(name, fn, [args], { retry })`. Omit the args array for a zero-argument function: `ctx.step(name, fn, { retry })`.

```typescript
import { flow, StepError } from "@renderinc/sdk/workflows";

function chargeCard(orderId: string, total: number) {
  return payments.charge(orderId, total);
}

flow({ name: "fulfillOrder" }, async (ctx, order: { id: string; email: string; total: number }) => {
  const charge = await ctx.step("chargeCard", chargeCard, [order.id, order.total], {
    retry: { maxRetries: 3, waitDurationMs: 1000, backoffScaling: 2 },
  });
  const receiptId = await ctx.step("receiptId", () => crypto.randomUUID());

  try {
    await ctx.step("sendReceipt", sendReceipt, [order.email, charge.id]);
  } catch (error) {
    if (!(error instanceof StepError)) throw error;
    await ctx.step("notifySupport", notifySupport, [order.id]);
  }
  return { charge: charge.id, receipt: receiptId };
});
```

| Concept | Python | TypeScript |
|---|---|---|
| Imports | `from render import FlowContext, Retry, Workflows` | `import { flow } from "@renderinc/sdk/workflows"` |
| Register | `@app.flow` or `@app.flow(name=..., timeout_seconds=..., plan=...)` | `flow({ name, timeoutSeconds?, plan? }, fn)` |
| Flow function | Sync only | Sync or async |
| Run a step | `ctx.step(name, fn, *args, retry=None)` | `await ctx.step(name, fn, [args], { retry })` |
| Step name | Required first argument | Required first argument |
| Step function | Sync only | Sync or async |
| Catch a failed step | `except StepError` (from `render.workflows`) | `catch (error)` with `error instanceof StepError` |
| Run ID | `ctx.metadata.flow_run_id` | `ctx.metadata.flowRunId` |
| Start the server | `app.start()` | Automatic in the workflow environment |

Python `ctx.step` reserves its keyword arguments for `retry`. Pass the step function's arguments positionally, or bind keyword arguments with `functools.partial`.

Flows and tasks can be registered in the same workflow service. Python registers both on the same `Workflows` app.

## Rules for Flow Code

Preserve these rules in generated flow code:

- **Be deterministic.** On every replay, the flow must make the same `ctx` calls in the same order, with the same step names and arguments. Put I/O, clocks, random values, environment reads, and anything else non-deterministic inside a step. Sort unordered collections before making one step per item. A replay that diverges fails the run with a `DeterminismError` naming the step and what changed. Catching that error does not help: the run still fails.
- **Run one step at a time.** Finish each `ctx` call before making the next one. Do not use `Promise.all` or `asyncio.gather` over `ctx` calls in a flow. For parallel work, use tasks with `ctx.run`.
- **Do not call `ctx` inside a step.** A step's function cannot make `ctx` calls. Doing so fails the run, even if the step catches the error.
- **Steps see JSON.** Step arguments and results are recorded as JSON, and `ctx.step` returns the decoded value on the first run as well as on replays. A TypeScript `Date` comes back as a string. Return plain JSON-serializable values. A step whose arguments or result cannot be encoded fails without retrying.
- **Retries go on steps, not flows.** A flow does not accept a retry policy, and Python's `default_retry` does not apply to flows. Set `retry` on the steps that call flaky dependencies. A step without `retry` runs once.
- **Steps can still repeat.** A crash in the middle of a step reruns that step's current attempt on replay. A step that mutates external state still needs an idempotency key or another deduplication strategy.

## Failed Steps

If a step fails after its last retry, `ctx.step` raises a `StepError`. Flow code can catch it and run a fallback step. On replay, `ctx.step` raises the same recorded error, so the flow takes the same branch.

```python
from render.workflows import StepError

@app.flow
def notify(ctx: FlowContext, phone: str, email: str) -> str:
    try:
        return ctx.step("send_sms", send_sms, phone, retry=Retry(max_retries=2, wait_duration_ms=1000))
    except StepError:
        return ctx.step("send_email", send_email, email)
```

In TypeScript, import `StepError` from `@renderinc/sdk/workflows`. Catch only `StepError` and rethrow other errors. A determinism error, a `ctx` call from inside a step, or a canceled run stops the run even when flow code catches the error.

## Current Limitations

- `ctx.invoke` is not supported yet. Calling it raises an error. A flow cannot run a registered task or another flow. Run plain functions with `ctx.step`.
- A task cannot run a flow through `ctx.run`. Start flows from application code with the SDK client, the CLI, or the API.
- Python step functions cannot be async.
- No durable sleep or wait step is available in the current SDK. Do not invent `ctx.sleep` or similar calls. Check the installed SDK's `FlowContext` for the methods it actually exposes.

## Start Flow Runs

Flow slugs use `{workflow-slug}/{flow-name}`. Append `:version` to run a specific version; otherwise the latest version runs.

Python:

```python
from render import Render

render = Render()
flow_run = render.workflows.start_flow(
    "my-workflow/fulfill_order",
    ["ord_123", "ada@example.com", 4200],
    idempotency_key="fulfill-ord_123",
)
details = render.workflows.get_flow_run(flow_run.id)
print(details.status, details.results)
```

TypeScript:

```typescript
import { Render } from "@renderinc/sdk";

const render = new Render();
const details = await render.workflows.runFlow(
  "my-workflow/fulfillOrder",
  [{ id: "ord_123", email: "ada@example.com", total: 4200 }],
  { idempotencyKey: "fulfill-ord_123" },
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
render workflows flows runs start my-workflow/fulfill_order --input='["ord_123", "ada@example.com", 4200]' -o json
render workflows flows runs show <flow-run-id> -o json
render workflows flows runs steps list <flow-run-id>
render workflows flows runs steps show <flow-run-id> <step-seq>
render workflows flows runs cancel <flow-run-id>
```

`flows runs start` accepts `--idempotency-key`. Use the step commands to see each recorded step, its attempts, and its error when a run fails.

## Local Development

Check whether the installed CLI's local task server runs flows before relying on it: run `render workflows dev` with the workflow's start command, then confirm the flow appears with `render workflows tasks list --local`. If the local server does not support flows yet, say so. Test step functions as plain functions in unit tests, and validate the flow itself after deploying it, with one safe run checked through `flows runs show` and `flows runs steps list`.
