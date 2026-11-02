---
name: render-workflows
description: >-
  Build, validate locally, deploy, and troubleshoot Render Workflows with the
  current Python or TypeScript SDK. Use for defining or chaining tasks,
  writing durable flows with steps, integrating the SDK into an existing
  project, running tasks with the local development server, optionally
  scaffolding a starter, authoring "type: workflow" in render.yaml, triggering
  task or flow runs from application code, and releasing workflows.
license: MIT
compatibility: >-
  Requires Render SDK 1.x. Idempotency keys and ctx.metadata require SDK
  1.2.0+; flows require an SDK release that exports them. Local validation
  requires Render CLI 2.12.0+;
  optional scaffolding and CLI deployment require Render CLI 2.16.0+.
  Blueprints support "type: workflow" (no service-level plan).
metadata:
  author: Render
  version: "1.3.0"
  category: workflows
---

# Render Workflows

Render Workflows is an SDK-based product for orchestrating long-running distributed tasks. A workflow service registers Python or TypeScript functions as tasks; each task run executes independently and can chain additional runs. A workflow service can also register durable flows, whose steps are recorded so that a crashed flow resumes without repeating finished steps.

When choosing between a Workflow, cron job, and background worker, read [references/service-types.md](references/service-types.md).

Use Render SDK 1.x APIs (`render>=1.0.1` for Python or `@renderinc/sdk` version 1.x for TypeScript). Local validation requires Render CLI 2.12.0 or later. Use CLI 2.16.0 or later when using the complete optional scaffolding and CLI deployment flow. Prefer the latest compatible releases.

Render Workflows and its SDKs can introduce breaking changes. Treat the installed SDK version as authoritative for an existing project. For new projects, use the current official documentation and starter templates.

## Check Current Sources

Before generating or changing SDK code, identify the installed versions:

```bash
render --version
python -m pip show render
npm ls @renderinc/sdk
```

If the Render CLI is not installed:

- macOS: `brew install render`
- Linux/macOS: `curl -fsSL https://raw.githubusercontent.com/render-oss/cli/main/bin/install.sh | sh`
- Windows: download the executable from the [CLI releases page](https://github.com/render-oss/cli/releases/)

Use the source that matches the question:

- [Python SDK reference](https://render.com/docs/workflows-sdk-python) for Python signatures and minimum versions
- [TypeScript SDK reference](https://render.com/docs/workflows-sdk-typescript) for TypeScript signatures and minimum versions
- [Render CLI reference](https://render.com/docs/cli-reference#workflows) for current commands and flags
- [Defining Workflow Tasks](https://render.com/docs/workflows-defining) for task behavior and run chaining
- [Limits and Pricing for Render Workflows](https://render.com/docs/workflows-limits) for compute plans, quotas, retention, and pricing
- [Python examples](https://github.com/render-examples/render-workflows-examples-python) and [TypeScript examples](https://github.com/render-examples/render-workflows-examples-ts) for current scaffolding patterns
- [Render SDK repository](https://github.com/render-oss/sdk) for the implementation and changelogs

Before generating task or client code, fetch the relevant SDK example to verify current API patterns:

| What | Python | TypeScript |
|------|--------|------------|
| Task definitions (subtasks, retry, fan-out) | [example/task/main.py](https://raw.githubusercontent.com/render-oss/sdk/main/python/example/task/main.py) | [examples/task/](https://github.com/render-oss/sdk/tree/main/typescript/examples/task) |
| Client (run, start, cancel, stream, list runs) | [example/client/main.py](https://raw.githubusercontent.com/render-oss/sdk/main/python/example/client/main.py) | [examples/client/](https://github.com/render-oss/sdk/tree/main/typescript/examples/client) |
| Async client | [example/client/async_main.py](https://raw.githubusercontent.com/render-oss/sdk/main/python/example/client/async_main.py) | — |

Do not silently upgrade an existing project's SDK major version. If an upgrade is part of the request, read the relevant SDK changelog and migrate all task definitions and callers together.

## SDK 1.x Invariants

Preserve these rules in generated code:

- Python installs and imports the `render` package, not `render_sdk`.
- Every task function accepts a `TaskContext` as its first positional parameter. Render supplies it; callers do not include it in task input.
- Chain a task run with `await ctx.run(task_definition, ...args)`. A task definition is not directly callable.
- All tasks in a `ctx.run` chain belong to the same workflow service. Trigger another workflow through the SDK client or Render API.
- Python calls `app.start()` from its workflow entrypoint. TypeScript task registration auto-starts in the workflow environment.
- Task arguments and return values must be JSON-serializable.
- A task reads its run IDs from `ctx.metadata` (`task_run_id`, `root_task_run_id`, `parent_task_run_id` in Python; `taskRunId`, `rootTaskRunId`, `parentTaskRunId` in TypeScript). Reading them makes no network request.

Read [references/quick-reference.md](references/quick-reference.md) when writing SDK code. Read [references/task-patterns.md](references/task-patterns.md) for chaining, fan-out, retries, scheduled triggers, or cross-workflow calls.

## Tasks or Flows

Use **tasks** for independent units of work and parallel fan-out. A retried task reruns all of its code. Use a **flow** when a sequence of steps must survive a crash without repeating the steps that already finished, for example charging a card and then sending a receipt.

Flows are newer than the rest of SDK 1.x, and their API is still changing. Before writing flow code, read [references/flows.md](references/flows.md) and confirm the installed SDK exports flows. Preserve these rules in flow code:

- Register with `@app.flow` (Python, sync functions only) or `flow({ name }, fn)` (TypeScript). The first parameter is a `FlowContext`.
- Run each unit of work as a step: `ctx.step(name, fn, *args, retry=...)` in Python, `await ctx.step(name, fn, [args], { retry })` in TypeScript.
- Keep flow code deterministic. Put I/O, clocks, and random values inside steps.
- Run one step at a time. Do not use `asyncio.gather` or `Promise.all` over `ctx` calls in a flow.
- Set retries on steps. Flows do not accept a retry policy.
- If a step fails after its last retry, `ctx.step` raises a `StepError`. Flow code can catch it and run a fallback step.
- `ctx.invoke` is not supported yet, so a flow cannot run a task or another flow.

## Choose a Starting Point

Do not require `render workflows init`. In an existing codebase, add the SDK and task definitions directly, preserve the project's dependency and build conventions, and validate them with the local development server. For a minimal project or direct integration guidance, read [references/manual-scaffolding.md](references/manual-scaffolding.md).

### Optional starter scaffolding

Use the CLI scaffolder when the user wants a quick example project or a new standalone workflow service:

```bash
render workflows init
```

For non-interactive setup, pass the language and destination explicitly:

```bash
render workflows init --confirm --language python --dir workflows --git=false
render workflows init --confirm --language node --dir workflows --git=false
```

Use `--git=false` when scaffolding inside an existing Git repository to avoid creating a nested repository. Other useful options include `--template`, `--install-deps`, and `--install-agent-skill`; verify current behavior in the CLI reference.

## Try It Locally with the SDK

For a first integration, follow the runnable Python or TypeScript [local SDK walkthrough](references/manual-scaffolding.md#try-it-locally-with-the-sdk): define `ping`, start the local task server, invoke it from a separate client script, and verify the returned `"pong"`. No `init`, deployment, or Render API key is needed for this local example. Set local mode in the calling application process, not only in the task server's environment.

After adding or changing SDK task definitions, use the local development server as the primary validation loop. Start it with the workflow's actual start command:

```bash
render workflows dev -- <workflow-start-command>
```

In another terminal, list and run tasks against the local server:

```bash
render workflows tasks list --local
render workflows start <task-name> --local --input='[]' -o json
render workflows tasks runs show <task-run-id> --local -o json
```

If a task doesn't appear in the local task list, see [Troubleshooting > Local task list is empty or missing tasks](references/troubleshooting.md#local-task-list-is-empty-or-missing-tasks).

Use a JSON array for positional input. Python tasks can also receive a JSON object for named input. Read [references/local-development.md](references/local-development.md) for environment files, custom ports, run inspection, cancellation, and application-client configuration.

In non-interactive mode, `workflows start` returns the new task run ID before the run necessarily finishes. Use that ID with `tasks runs show`, polling for a bounded period until the run completes, fails, or is canceled. Verify the result or error, not only that the run was created.

When safe and practical, run this verification yourself and stop the dev server afterward. Do not claim a task registers successfully based only on source inspection.

## Deploy After Local Validation

Creating or releasing a workflow changes the user's Render account. Only do it when deployment is part of the request and the tasks have been validated locally when local execution is supported.

Before deploying or interpreting deploy status, read [references/deployments.md](references/deployments.md), including its Workflow-specific task-registration behavior.

Before deploying, authenticate and confirm the target workspace:

```bash
render whoami
render workspace current
```

If authentication is missing, use `render login` for an interactive local session or provide `RENDER_API_KEY` through the environment for automation. Never print the key.

Confirm the intended branch and region, and ensure the exact code to deploy is committed and pushed to GitHub, GitLab, or Bitbucket. Neither path deploys uncommitted local changes.

Two creation paths. MCP supports neither.

| Path | Use when | Runtimes |
|------|----------|----------|
| Blueprint (`render.yaml`) | The repo uses IaC, or the workflow ships beside other Render services | `python`, `node` |
| `render workflows create` or Dashboard | Standalone workflow with no Blueprint | `python`, `node`, `go`, `ruby`, `elixir`, plus Docker in the Dashboard only |

### Deploy with a Blueprint (preferred)

Do **not** set `plan` on a workflow service. Task compute is configured in code (`plan` on the task), not on the service.

```yaml
services:
  - type: workflow
    name: my-workflow
    runtime: python
    region: oregon
    repo: https://github.com/render-examples/render-workflows-examples-python
    branch: main
    rootDir: hello-world
    buildCommand: pip install -r requirements.txt
    startCommand: python main.py
    envVars:
      - key: RENDER_API_KEY
        sync: false
```

TypeScript variant: `runtime: node`, `buildCommand: npm install`, and a `startCommand` that runs the project's workflow entrypoint. The TypeScript starter uses `npm start` (`tsx src/main.ts`); the manual setup in [references/manual-scaffolding.md](references/manual-scaffolding.md) uses `npm run workflows:start`. Match both commands to the scripts in `package.json`. Use `npm run build` and `node dist/main.js` only if the project defines a `build` script that emits `dist/main.js`.

Required: `type`, `name`, `runtime`, `region`, `startCommand`, plus `buildCommand` and `repo`. Optional: `branch`, `rootDir`, `buildFilter`, `autoDeployTrigger`, `envVars` (applied to every task run).

The schema's `required` array lists only the first five. Do not treat it as the complete set: the validator also rejects a workflow missing `buildCommand` or `repo`.

- `buildCommand is required for non-docker workflows`. Only Docker-based workflows omit a build command, and those cannot appear in a Blueprint, so a Blueprint workflow always needs one.
- `repo is required for git-based services`. This fires even when validating from inside that repository with an `origin` remote, which is not how `web` and other Git-based types behave.

Caveats:

- Preview environments skip workflow services. Other Blueprint resources still replicate.
- Render rejects a Blueprint that would create a workflow with the same name as an existing Blueprint-managed workflow in the workspace.
- The [Workflows intro FAQ](https://render.com/docs/workflows) may still say Blueprints cannot manage workflows. That is stale. Follow the [changelog](https://render.com/changelog/added-blueprint-support-for-render-workflows) and `https://render.com/schema/render.yaml.json`.

Validate before applying:

```bash
render blueprints validate
```

A passing validate is not proof a runtime is supported. `render blueprints validate` currently accepts `runtime: docker` on a workflow even though the schema rejects it.

Pair with **render-blueprints** for wiring and **render-deploy** for the apply/deeplink flow.

### Create with the CLI or Dashboard

Use this for a standalone workflow with no Blueprint. Interactive mode prompts for configuration:

```bash
render workflows create
```

Non-interactive, using the build and run commands from the starter template or the project's existing configuration:

```bash
render workflows create \
  --name my-workflow \
  --repo . \
  --branch <branch> \
  --region <region> \
  --runtime python \
  --build-command "pip install -r requirements.txt" \
  --run-command "python main.py"
```

`--repo .` resolves the repository's remote. For a workflow in a subdirectory, add `--root-directory`. Environment variables can be supplied with repeatable `--env-file` and `--env-var` flags. Never expose secrets in commands or output.

A workflow can build from a Dockerfile, but only through the Dashboard (**New > Workflow**): [the CLI and API cannot create one](https://render.com/docs/workflows-tutorial#docker-specific-limitations), and neither can a Blueprint. Docker-based workflows take no build command and cannot run against the local task server. No creation path can pull a prebuilt registry image.

For later explicit releases, use:

```bash
render workflows versions release <workflow-id> \
  --commit <pushed-commit-sha> \
  --wait
```

Do not report deployment success from command acceptance alone. Wait for the release, then verify that the expected tasks registered and that one safe task reaches a terminal state with the expected result:

```bash
render workflows versions list <workflow-id> -o text
render workflows tasks list <ready-workflow-version-id> -o text
render workflows start <workflow-slug>/<task-name> --input='[]' -o json
render workflows tasks runs show <task-run-id> -o json
```

Poll `tasks runs show` for a bounded period if the run is still queued or running. Stop and report the release or task error instead of retrying an external mutation indefinitely.

If deployment fails, read [references/troubleshooting.md](references/troubleshooting.md). Use the `render-debug` skill for broader Render deployment diagnosis when it is available.

## Trigger Deployed Tasks

Task slugs use `{workflow-slug}/{task-name}`.

Python, synchronous:

```python
from render import Render

render = Render()
result = render.workflows.run_task("my-workflow/hello", ["world"])
print(result.results)
```

Python, asynchronous:

```python
from render import RenderAsync

render = RenderAsync()
started = await render.workflows.start_task("my-workflow/hello", ["world"])
finished = await started
print(finished.results)
```

TypeScript:

```typescript
import { Render } from "@renderinc/sdk";

const render = new Render();
const started = await render.workflows.startTask("my-workflow/hello", ["world"]);
const finished = await started.get();
console.log(finished.results);
```

These clients use `RENDER_API_KEY` unless a token is passed explicitly. Prefer environment variables or a secret manager over hard-coded credentials.

When the caller may retry a start call, for example after a timeout, pass an idempotency key. Repeating a call with the same key within 24 hours returns the run that the first call started instead of starting another one. Keys are scoped to the workflow, so they hold across deploys.

```python
render.workflows.start_task("my-workflow/charge", [order_id], idempotency_key=f"charge-{order_id}")
```

```typescript
await render.workflows.startTask("my-workflow/charge", [orderId], { idempotencyKey: `charge-${orderId}` });
```

An idempotency key deduplicates starting a run. It does not make the task's own side effects safe to retry.

Flow runs start with `start_flow()` in Python and `startFlow()` or `runFlow()` in TypeScript, using a flow slug of `{workflow-slug}/{flow-name}`. See [references/flows.md](references/flows.md#start-flow-runs).

Workflows do not currently provide native scheduled triggers. Use a Render cron job that invokes the SDK client or API when scheduling is required.

## Limits, Compute Plans, and Pricing

Do not hard-code compute-plan IDs, resource specifications, quotas, retention periods, or prices in this skill or its references.

Before setting a task's `plan`, estimating cost, or advising on capacity, consult [references/compute-plans.md](references/compute-plans.md) and [Limits and Pricing for Render Workflows](https://render.com/docs/workflows-limits). Keep only API-shape constraints needed to write correct code in the skill.

## References

- [references/quick-reference.md](references/quick-reference.md): SDK 1.x task and client surface
- [references/compute-plans.md](references/compute-plans.md): current compute-plan guidance for task `plan` values
- [references/deployments.md](references/deployments.md): deploy lifecycle and Workflow task registration
- [references/service-types.md](references/service-types.md): choosing between Workflows and other service types
- [references/task-patterns.md](references/task-patterns.md): chaining, fan-out, retries, cron triggers, and cross-workflow calls
- [references/flows.md](references/flows.md): durable flows, steps, replay rules, and flow runs
- [references/local-development.md](references/local-development.md): local server, CLI runs, environment configuration, and limitations
- [references/troubleshooting.md](references/troubleshooting.md): common setup, registration, execution, and client failures
- [references/manual-scaffolding.md](references/manual-scaffolding.md): direct SDK project setup without `workflows init`

## Related Skills

- `render-blueprints`: `type: workflow` in `render.yaml`, previews, wiring
- `render-deploy`: Blueprint apply flow for multi-service apps that include a workflow
- `render-debug`: diagnose deployment and runtime failures
- `render-monitor`: inspect service health and performance

<!-- shared:documentation-retrieval -->
## Current documentation retrieval

Whenever this skill directs you to consult current Render documentation:

1. Retrieve the linked Markdown document directly with an available URL-fetching tool or HTTP client, such as `curl`. Do not substitute web-search summaries for the document.
2. Confirm that retrieval succeeded and returned the expected document, then read its contents. Saving a file or printing its path is not sufficient.
3. If the request fails or your tool cannot read the Markdown response, open and read the linked HTML version instead.
4. If neither version can be retrieved, disclose that the current reference is unavailable and follow any topic-specific fallback in the skill. Use bundled guidance only for stable constraints, and do not guess at changeable platform details.

When a task requires multiple references, apply this workflow to each one and distinguish the documents you verified from those that remain unavailable.
<!-- /shared:documentation-retrieval -->
