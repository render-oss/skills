# Troubleshooting and lifecycle

Use the exact installed version, selected workspace, resource ID, returned state, and sanitized error. Distinguish a client-side rejection, a control-plane response, guest execution failure, and an uncertain transport outcome. Do not report a fix as verified without exercising the affected operation.

| Symptom | Check and next action |
| --- | --- |
| Missing group or resource not found | Check the workspace and access, then the resource state. Listing groups doesn't create one, but first sandbox creation can create the default group automatically. |
| Created ID but first call fails | Wait for `running` with bounded status requests. Retry only status checks or harmless readiness probes with backoff; a 404 or 409 alone doesn't prove that a submitted workload never started. |
| Command returns nonzero | Read stderr and the exit code. It's a workload failure, not an API failure. |
| Stream drops or lacks final exit | Outcome is unknown. Check artifacts or side effects before retrying; cancelling doesn't kill the remote process. |
| Create request times out | A sandbox may exist. Check the workspace before retrying, and don't delete unrelated sandboxes. |
| HTML 403 from an API request | Check the response source and request ID. A gateway or WAF block isn't a filesystem permission error inside the guest. Escalate with sanitized details. |
| File transfer fails | Check the absolute path, that the source exists, destination permissions, and file versus tar format. Inspect any partial local extraction before retrying. |
| TypeScript upload with trailing slash fails | Check the installed version; TypeScript 1.5.0 normalizes transfer paths. Use an explicit absolute destination and inspect file versus directory semantics. |
| No Python output until completion | Output is buffered; use `python -u`. |
| Snapshot unavailable or restore fails | Check capture status, group, expiry, name or ID, and plan match for runtime snapshots; see [snapshots](snapshots.md). |
| Restored files exist but network access differs | Set the restore's network policy explicitly and verify it. New commands use new env values; runtime-resumed processes retain their original environment. |
| HTTP 429 or concurrency errors | Operations have separate rate limits per user, shared across that user's API keys. Bound concurrency, back off, and leave capacity for cleanup. |

## Lifetime is not idle timeout

The lifetime (`timeoutSeconds`, default 24 hours) limits continuous runtime and resets after suspension/resume. Its maximum is 30 days, or 24 hours on Hobby workspaces. It is not an absolute retention deadline; enforce a separate caller deadline and termination if that is required. The idle timeout (default 900 seconds) controls suspension when no command execution or file transfer is in progress. Set both deliberately. `0` disables idle suspension; other idle values run from 300 to 86400. SDKs 1.5.0 accept `idle_timeout_seconds` (Python) / `idleTimeoutSeconds` (TypeScript); CLI 2.32.0 accepts `--idle-timeout`. Compare the returned settings with the request.

## Recover a suspended sandbox

Status polling does not wake a suspended sandbox, and SDK readiness helpers reject that state. In beta, executing a command or transferring a file automatically resumes a sandbox suspended within the last 30 days.

When explaining recovery, include both timeout budgets and the failure path:

1. Trigger wake on the existing sandbox with a harmless command or file operation under a finite **caller timeout**, for example 30 seconds. A guest command timeout alone cannot bound a stalled wake request. Do not replay a mutating workload as a probe.
2. After wake starts, wait for `running` using the SDK helper with a separate deadline, for example 120 seconds. Manual polling must bound each request and stop on `errored` or `terminated`.
3. If it remains `suspended`, reaches a terminal state, or either deadline expires, report the state and preserve the ID for recovery. Once running, verify the preserved files before resuming work.

Check [current lifecycle documentation](https://render.com/docs/sandboxes-creating.md) ([HTML](https://render.com/docs/sandboxes-creating)) if the target workspace behaves differently. If wake cannot be established, report the gap and preserve the sandbox. Snapshots require a running source. Detached background processes do not keep a sandbox awake, and external connections do not survive suspension.

There are no explicit suspend or resume methods or CLI commands; `suspending` and `resuming` are states, not APIs.

## Recovery completion

Retrieve outputs before disposing of anything. If one of several restores fails, clean up the ones that succeeded too. Report both the workload failure and any cleanup failure, with the IDs needed to finish recovery. Don't rerun a mutating workload just because cleanup or result retrieval failed.

Sources: [Python lifecycle client](https://github.com/render-oss/sdk/blob/python/v1.5.0/python/render/experimental/sandbox/client.py), [TypeScript client](https://github.com/render-oss/sdk/blob/typescript/v1.5.0/typescript/src/experimental/sandboxes/index.ts), [CLI validation](https://github.com/render-oss/cli/blob/v2.32.0/cmd/sandboxcreate.go).
