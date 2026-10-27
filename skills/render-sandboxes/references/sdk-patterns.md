# SDK patterns

Baseline: Python and TypeScript SDK 1.5.0, checked 2026-10-27. Inspect installed versions before adapting these examples. Client source establishes available methods, not workspace enablement. Use the project's existing dependency manager and lockfile; install `render` for Python or `@renderinc/sdk` for TypeScript. Python 1.5.0 requires Python 3.10 or newer (below 4).

For current documentation, follow the root retrieval workflow: Python [Markdown](https://render.com/docs/sandboxes-sdk-python.md) / [HTML](https://render.com/docs/sandboxes-sdk-python), TypeScript [Markdown](https://render.com/docs/sandboxes-sdk-typescript.md) / [HTML](https://render.com/docs/sandboxes-sdk-typescript). If docs and installed signatures disagree, verify the versioned implementation before emitting code.

## Python: create, run, download, terminate

Python imports from `render`; `render_sdk` is a legacy shim, so match what older projects use. Pin the version when installing: the unversioned PyPI name once belonged to an unrelated package.

```python
import asyncio
import sys
from pathlib import Path
from tempfile import mkdtemp
from render import RenderAsync
from render.sandbox import SandboxExecExit, SandboxExecOutput


async def main():
    sandboxes = RenderAsync().sandboxes
    sandbox = await sandboxes.create(timeout_seconds=600, network_policy="deny-all")
    print(f"Sandbox ID: {sandbox.id}", file=sys.stderr)
    try:
        await sandboxes.wait_until_running(sandbox.id, timeout_seconds=120)
        exit_code = None
        command = "printf 'hello from Render\\n' > /tmp/result.txt && cat /tmp/result.txt"
        async for event in sandboxes.exec(sandbox.id, command):
            if isinstance(event, SandboxExecOutput):
                stream = sys.stderr if event.stream == "stderr" else sys.stdout
                print(event.data, end="", file=stream, flush=True)
            elif isinstance(event, SandboxExecExit):
                exit_code = event.exit_code
        if exit_code != 0:
            raise RuntimeError(f"Command did not succeed; exit code: {exit_code}")
        destination = Path(mkdtemp(prefix="render-sandbox-")) / "result.txt"
        output = await sandboxes.copy_from(sandbox.id, "/tmp/result.txt", destination)
        if Path(output).read_text() != "hello from Render\n":
            raise RuntimeError("Unexpected output contents")
        print(f"Verified output: {output}")
    except BaseException:
        try:
            await asyncio.wait_for(sandboxes.terminate(sandbox.id), timeout=15)
        except Exception as cleanup_error:
            print(f"Cleanup failed for {sandbox.id}: {cleanup_error}", file=sys.stderr)
        raise
    else:
        try:
            await asyncio.wait_for(sandboxes.terminate(sandbox.id), timeout=15)
        except Exception as cleanup_error:
            raise RuntimeError(f"Cleanup failed for {sandbox.id}") from cleanup_error


if __name__ == "__main__":
    asyncio.run(main())
```

The 120-second wait limits startup; `timeout_seconds=600` limits sandbox runtime. Cleanup has its own 15-second budget and reports the sandbox ID if termination is unconfirmed. A client timeout does not prove the remote operation stopped.

## TypeScript equivalent

The 1.5.0 readiness helper bounds status requests as well as polling. `terminate` still has no abort-signal parameter; enforce a caller-process deadline if cleanup needs a strict wall-clock bound, and retain the ID when termination is unconfirmed.

```typescript
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { Render } from "@renderinc/sdk";

const sandboxes = new Render().sandboxes;

async function main() {
  const sandbox = await sandboxes.create({ timeoutSeconds: 600, networkPolicy: { type: "deny-all" } });
  console.error(`Sandbox ID: ${sandbox.id}`);
  try {
    await sandboxes.waitUntilRunning(sandbox.id, { timeoutMs: 120_000 });
    let exitCode: number | undefined;
    const command = "printf 'hello from Render\\n' > /tmp/result.txt && cat /tmp/result.txt";
    for await (const event of await sandboxes.exec(sandbox.id, command)) {
      if (event.type === "output") {
        (event.stream === "stderr" ? process.stderr : process.stdout).write(event.data);
      } else if (event.type === "exit") {
        exitCode = event.exit_code;
      }
    }
    if (exitCode !== 0) throw new Error(`Command did not succeed; exit code: ${exitCode}`);
    const output = await sandboxes.download(sandbox.id, "/tmp/result.txt");
    if (output.data.toString("utf8") !== "hello from Render\n") {
      throw new Error("Unexpected output contents");
    }
    const destination = join(await mkdtemp(join(tmpdir(), "render-sandbox-")), "result.txt");
    await writeFile(destination, output.data);
    console.log(`Verified output: ${destination}`);
  } catch (error) {
    try { await sandboxes.terminate(sandbox.id); }
    catch (cleanupError) { console.error(`Cleanup failed for ${sandbox.id}`, cleanupError); }
    throw error;
  }
  try { await sandboxes.terminate(sandbox.id); }
  catch (cleanupError) {
    throw new Error(`Cleanup failed for ${sandbox.id}`, { cause: cleanupError });
  }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
```

## File transfer and pagination

| Operation | Python | TypeScript |
| --- | --- | --- |
| Upload file | `await sandboxes.copy_to(id, local_path, remote_path)` | `await sandboxes.upload(id, remotePath, bytes)` |
| Upload directory | `copy_to` archives and extracts it | Supply tar bytes or stream with `upload(id, path, data, undefined, { contentType: "application/x-tar" })` |
| Download | `copy_from` writes or extracts locally | `download` returns `{ data, size, contentType }`; directory responses need archive handling |
| Lookup | `from_id(id)` | `get(id)` |
| List groups | `list_groups()` returns `.groups` | `listGroups()` returns entries with `.sandboxGroup` |
| List sandboxes | `.sandboxes` and `.next_cursor` | Array of `{ sandbox, cursor }`; trailing cursor pages forward |

Relative remote paths resolve under the sandbox home directory, so use absolute paths.

Downloaded archives are untrusted:

- Extract into a fresh staging directory outside the repository and home directory. Python downloads can leave partial contents on failure.
- Reject absolute paths, `..` traversal, links that escape the directory, and special files. Use an extractor that enforces containment, not just a filename precheck. Python's SDK has extraction defenses; TypeScript leaves extraction to you.
- Don't follow extracted links or run downloaded scripts.

Set transfer and extraction budgets appropriate to the task: total bytes, expanded bytes, file count, and elapsed time. TypeScript `download` buffers the entire response, so checking `data.length` afterward cannot prevent memory exhaustion. For an untrusted or unbounded artifact, use a verified streaming path that counts received bytes and aborts before exceeding the byte budget, or perform the download in a disposable process/container with an OS-enforced memory limit that covers native allocations and buffers. A timeout limits duration, not bytes. Node worker threads and V8 heap limits do not cap external buffers and cannot protect the host from this exhaustion. Do not invent a `maxBytes` SDK option. Guest-reported sizes and HTTP metadata alone are not trustworthy limits.

## Create options and version differences

Follow [create options](creation-options.md) to retrieve the current SDK input contract and select settings for the workload.

Both 1.5.0 SDKs accept idle timeouts: `idle_timeout_seconds` in Python and `idleTimeoutSeconds` in TypeScript. TypeScript 1.4.0 did not serialize that field; casting it never fixed the old client. Upgrade, then verify backend acceptance: compare `sandbox.idleTimeoutSeconds` with the requested value (for example, `300`). Report both values; a mismatch remains unresolved, even if create succeeded. Explain the two settings when diagnosing this issue: idle timeout suspends an inactive sandbox; `timeout_seconds` / `timeoutSeconds` terminates it after its continuous runtime limit, which resets after suspension/resume. Set both deliberately. See [troubleshooting](troubleshooting.md).

Use `wait_until_running` / `waitUntilRunning` and snapshot `wait_until_available` / `waitUntilAvailable` for bounded readiness checks. These helpers do not wake suspended sandboxes. Record the created ID before waiting. If combined creation-and-wait fails, inspect `SandboxCreateWaitError` for `sandbox_id` (Python) or `sandboxId` (TypeScript) before cleanup or retry; a wait failure does not prove creation failed. For Python `create(wait=...)`, set the deadline in the SDK wait options; an outer `asyncio.wait_for` can cancel before the created ID is recovered.

SDK 1.5.0 moves the public client from `.experimental.sandboxes` to `.sandboxes`; Python sandbox imports move to `render.sandbox`. The old experimental client namespace is removed. Sandbox placement follows the group's region; the create `region` field is deprecated and ignored.

Python network policies use `NetworkPolicy` and `EgressRule` objects, not plain dicts; TypeScript uses `{ type, rules }`. See [environment and access](environment-and-access.md).

For an existing sandbox, skip creation and termination unless the user asked to dispose of it. In resumable applications, store the sandbox ID in a durable job record as soon as create returns, so an interrupted caller can recover it.

## Public sources

- [Python async client](https://github.com/render-oss/sdk/blob/python/v1.5.0/python/render/experimental/sandbox/client.py)
- [Python package](https://github.com/render-oss/sdk/blob/python/v1.5.0/python/pyproject.toml)
- [TypeScript client](https://github.com/render-oss/sdk/blob/typescript/v1.5.0/typescript/src/experimental/sandboxes/index.ts)
