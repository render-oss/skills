# Local Development

Use the task server and client configuration below to validate task registration and execution locally.

Use the Render CLI's local task server to register and run tasks without deploying. Read the current [local development documentation](https://render.com/docs/workflows-local-development) when behavior differs from this reference.

## Prerequisites

- Render CLI 2.12.0 or later for local development; this skill recommends 2.16.0 or later for the complete scaffolding and deployment flow
- A Python or TypeScript workflow project with its dependencies installed
- A non-Docker workflow start command; Docker-based workflows do not currently support the local task server

## Start the Local Task Server

Run from the workflow project's root directory:

```bash
# Python
render workflows dev -- python main.py

# TypeScript starter
render workflows dev -- npm start
```

The default port is `8120`. Use the same custom port on every related CLI command:

```bash
render workflows dev --port 8121 -- python main.py
render workflows tasks list --local --port 8121
```

The CLI loads `.env` from the current directory automatically. To load explicit files, pass `--env-file` more than once if needed; later files override earlier files:

```bash
render workflows dev \
  --env-file .env \
  --env-file .env.local \
  -- python main.py
```

Use `--debug` when task execution events are needed for diagnosis.

## Run and Inspect Tasks

Interactive task browser:

```bash
render workflows tasks list --local
```

Non-interactive flow:

```bash
render workflows tasks list --local -o text
render workflows start calculate_square --local --input='[5]' -o text
render workflows tasks runs list calculate_square --local -o text
render workflows tasks runs show <task-run-id> --local -o json
render workflows cancel <task-run-id> --local
```

Use `-o text`, `-o json`, or `-o yaml` to disable menu navigation. The canonical long form of `render workflows start` is `render workflows tasks runs start`; the canonical long form of `cancel` is `render workflows tasks runs cancel`.

Non-interactive `workflows start` can return while the run is still queued or running. Copy its task run ID and poll `tasks runs show` for a bounded period until the status is completed, failed, or canceled. Confirm the result or error rather than treating run creation as successful execution.

Inputs:

- Use a JSON array for positional arguments: `[5]`, `["left", "right"]`, or `[]`.
- A Python task can use a JSON object for named arguments: `{"value": 5}`.
- Do not include the `TaskContext` parameter in either input form.

## Trigger Local Runs from Application Code

For complete Python and TypeScript client scripts with a verified `ping` result, follow [Try It Locally with the SDK](manual-scaffolding.md#try-it-locally-with-the-sdk).

Local SDK calls do not require a Render API key or a deployed workflow. Set local mode in the **calling application's** environment (setting it only on the task server does not configure a separately running client):

```bash
export RENDER_USE_LOCAL_DEV=true
```

For a custom server URL, also set:

```bash
export RENDER_LOCAL_DEV_URL=http://localhost:8121
```

Python `Render()` and `RenderAsync()` clients detect these variables. TypeScript supports the same variables or explicit configuration:

```typescript
import { Render } from "@renderinc/sdk";

const render = new Render({
  useLocalDev: true,
  localDevUrl: "http://localhost:8121",
});
```

For direct Render API code, use the local task server as the base URL for task endpoints only. Other Render API endpoints are not simulated.

## Local-Only Behavior

- Logs and results are held in memory and disappear when the server stops.
- Stored run history can increase memory usage; restart the server during high-volume testing.
- Local task and run identifiers are generated for each server session and do not correspond to deployed identifiers.
- The server reloads task definitions when it starts subprocesses, so source changes are picked up without deploying.
- Local execution simulates task orchestration but does not reproduce production container isolation, networking, or compute characteristics.

Stop the local task server after verification when an agent started it for the user.
