# CLI operations

These examples target Render CLI 2.32.0, where commands are `render sandboxes` and `render sandbox-groups` (the `ea` prefix is removed). Check the installed version and `--help` before adapting them; newer documentation can describe commands or flags absent from that release. For current documentation, follow the root skill's retrieval workflow: [Markdown](https://render.com/docs/sandboxes-cli-reference.md), [HTML](https://render.com/docs/sandboxes-cli-reference). Installed help is authoritative for available flags when published docs lag.

## Establish access

Use the existing CLI login or `RENDER_API_KEY`, and check `render whoami --output json` and `render workspace current --output json`. The CLI's workspace is set separately from the SDK's `RENDER_WORKSPACE_ID`; automation can use `RENDER_WORKSPACE`. Don't switch workspaces silently. For setup, see [CLI docs](https://render.com/docs/cli.md) ([HTML](https://render.com/docs/cli)).

`render sandbox-groups list --output json` lists groups. 2.32.0 has no sandbox `get` subcommand; find the sandbox in `list` output, or use the SDK.

## Create, execute, retrieve, stop

Run these one at a time, not as an unattended script. Use `--wait` to wait for `running` before `exec`, and retain the created ID even if waiting fails. In automation, bound both polling and individual CLI calls. If a supported `--wait` fails, retain any printed resource ID and inspect its state before retrying creation.

```bash
render sandboxes create --timeout 600 --network-policy deny-all --wait --output json
render sandboxes list --output json
render sandboxes exec "$SANDBOX_ID" -- bash -c 'printf "hello\n" > /tmp/result.txt'
render sandboxes copy "$SANDBOX_ID:/tmp/result.txt" ./result.txt
render sandboxes stop "$SANDBOX_ID" --confirm
```

Download and check the output before `stop`. In scripts, use a cleanup trap that keeps the original exit status and reports any failed cleanup with the sandbox ID. Stop only sandboxes the task says to dispose of. `stop` without `--confirm` only previews; `--confirm` terminates.

`exec ID -- COMMAND` passes argv, so pipes, redirects, `&&`, variables, and `cd` need an explicit `bash -c '...'`. Single-quote it so the host shell doesn't expand it. Plain commands work directly: `exec "$SANDBOX_ID" -- python /tmp/job.py`.

`copy` (alias `cp`) takes local paths and `ID:/absolute/remote/path`, including directories. A successful copy doesn't mean the workload succeeded.

## Creation options

Run `render sandboxes create --help` for the complete flag list and supported values, then follow [creation decisions](creation-options.md). Use an explicit timeout and network policy. `--wait` controls startup readiness, not sandbox lifetime; check its bound in installed help.

For the recommended runtime snapshot, capture with `render sandboxes snapshots create "$SANDBOX_ID" --kind runtime --name NAME --wait`. Set `SNAPSHOT_PLAN` to the plan returned for that snapshot. An offline restore uses:

```bash
render sandboxes create --from NAME --sandbox-group "$GROUP_ID" --plan "$SNAPSHOT_PLAN" --timeout 600 --network-policy deny-all --wait
```

Use `--kind filesystem` only for deliberate file-only capture or a plan change. Restore only after capture is available. See [snapshots](snapshots.md). There are no suspend, resume, or credential subcommands.

Build an image with `render sandbox-groups builds create python:3.13 --name python --group "$GROUP_ID" --output json`. Record the returned ID and poll `render sandbox-groups builds get "$BUILD_ID" --group "$GROUP_ID" --output json` with a deadline until `succeeded`, stopping on `failed`. Only then use `render sandboxes create --build "$BUILD_ID" --sandbox-group "$GROUP_ID" --timeout 600 --network-policy deny-all --wait --output json`. Group creation is available through `render sandbox-groups create --name NAME`; confirm the intended workspace and region first.

Sources: [2.32.0 commands](https://github.com/render-oss/cli/tree/v2.32.0/cmd), [create flags and validation](https://github.com/render-oss/cli/blob/v2.32.0/cmd/sandboxcreate.go).
