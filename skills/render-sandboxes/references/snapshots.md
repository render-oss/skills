# Snapshots and restore

Baseline: SDKs 1.5.0 and CLI 2.32.0, checked 2026-10-27. The runtime default captures memory and CPU state as well as files. Always set `kind` explicitly: `kind="filesystem"` for file-only capture. Follow the root retrieval workflow for the [current overview](https://render.com/docs/sandboxes.md) or [HTML fallback](https://render.com/docs/sandboxes).

| Kind | Captures | Restore constraint |
| --- | --- | --- |
| `filesystem` | Writable filesystem, saved files, installed dependencies | May use a different plan |
| `runtime` | Filesystem plus memory and CPU state | Must match snapshot plan |

Recommend `runtime` for reusable environments: it is the default and restores faster. Choose `filesystem` when the user specifically needs files without process memory/CPU state, or wants to restore onto a different plan. External connections don't survive either kind, and neither gives you shared writable storage.

## Keep secrets out of reusable snapshots

A snapshot keeps whatever is on disk: credential files, shell history, caches. A runtime snapshot also keeps memory, so unsetting a variable or deleting a file afterward doesn't clean it.

Build reusable bases before any credential or sensitive data enters the sandbox. Choosing `filesystem` omits memory, but does not sanitize secrets already on disk. Don't publish a snapshot of a session that held credentials. In advice about contaminated snapshots, explain their independent lifetimes: terminating the source sandbox does not remove existing snapshots or sandboxes restored from them. Identify affected copies and recommend deletion and credential rotation where needed; perform those actions only within the user-authorized remediation scope.

## Capture and restore

1. Finish setup and check exit codes. The source must be running.
2. Capture and record the snapshot ID and group, then wait with bounded requests until the status is `available`. On `failed`, report its error. Keep the source until capture completes. Prefer the installed client's wait helper when available.
3. Create a sandbox from the snapshot, wait for `running`, and check a representative file or process.
4. Terminate disposable sandboxes. Keep snapshots meant for reuse.

The examples below use the recommended runtime capture and restore on its original plan. For file-only capture or a plan change, select `filesystem` explicitly and choose the desired restore plan.

Python signatures, inside async code:

```python
snapshot = await sandboxes.snapshots.create(source_id, kind="runtime")
current = await sandboxes.snapshots.wait_until_available(
    sandbox_group_id=snapshot.sandbox_group_id, snapshot_id=snapshot.id,
    timeout_seconds=300,
)
restored = await sandboxes.create(
    snapshot_id=current.id, sandbox_group_id=current.sandbox_group_id, plan=current.plan,
    timeout_seconds=600, network_policy="deny-all",
)
# Wait for restored.id to become running before use.
```

TypeScript signatures:

```typescript
const snapshot = await sandboxes.snapshots.create({
  sandboxId: sourceId, kind: "runtime",
});
const current = await sandboxes.snapshots.waitUntilAvailable({
  sandboxGroupId: snapshot.sandboxGroupId, snapshotId: snapshot.id,
}, { timeoutMs: 300_000 });
const restored = await sandboxes.create({
  snapshotId: current.id, sandboxGroupId: current.sandboxGroupId, plan: current.plan,
  timeoutSeconds: 600, networkPolicy: { type: "deny-all" },
});
// Wait for restored.id to become running before use.
```

Restore creation sets the network policy anew; omitting it defaults to `allow-all`, so pass the intended policy explicitly. Newly executed commands use the environment supplied on restore. Processes resumed from a runtime snapshot retain their original environment and in-memory secrets; new env values do not replace those. After the restored sandbox is running, verify the policy with a bounded probe to a host that should be blocked, such as `curl -sS --max-time 5 https://example.com`, and check its exit code. A missing `curl` or an unrelated failure isn't proof of enforcement. For code-only requests, include the probe without running it.

These fragments show bounded capture waits, not complete cleanup loops. Record the snapshot ID before waiting; a failed wait does not remove it. Restores must stay in the snapshot's sandbox group.

## Multiple restores and partial failure

To fan out, create several sandboxes from the same snapshot; there's no `fork()` method. Record each ID as soon as its create returns. Keep both creation and readiness waits inside the cleanup guard: a failed readiness wait must clean up all successful creates too. For concurrent creates, wait for all of them to settle before cleaning up: `Promise.all` rejects on the first failure while other creates are still in flight, so recording IDs only after it succeeds loses the ones that did get created.

This TypeScript helper uses the SDK 1.5.0 readiness helper with the `sandboxes` client from [SDK patterns](sdk-patterns.md#typescript-equivalent). The caller keeps the environments until testing is done, then terminates them. The source sandbox and the snapshot are not cleanup targets.

```typescript
async function restoreTestEnvironments(snapshotId: string, sandboxGroupId: string, plan: string) {
  const attempts = await Promise.allSettled(
    Array.from({ length: 3 }, () => sandboxes.create({
      snapshotId, sandboxGroupId, plan, timeoutSeconds: 600,
      networkPolicy: { type: "deny-all" },
    })),
  );
  const created = attempts.flatMap((attempt) =>
    attempt.status === "fulfilled" ? [attempt.value] : [],
  );
  try {
    const failure = attempts.find((attempt) => attempt.status === "rejected");
    if (failure?.status === "rejected") throw failure.reason;
    for (const sandbox of created) {
      await sandboxes.waitUntilRunning(sandbox.id, { timeoutMs: 120_000 });
    }
    return created;
  } catch (error) {
    const cleanup = await Promise.allSettled(
      created.map((sandbox) => sandboxes.terminate(sandbox.id)),
    );
    cleanup.forEach((result, index) => {
      if (result.status === "rejected") {
        console.error(`Cleanup failed for ${created[index].id}`, result.reason);
      }
    });
    throw error;
  }
}
```

A create that times out may still have created a sandbox. This helper cleans up only known IDs; reconcile the rest from the creation context, and never delete unrelated sandboxes.

## Names, expiration, deletion

Capture accepts `name`. Restore takes a snapshot ID or a snapshot name, never both (`snapshot_id` / `snapshot_name` in Python, `snapshotId` / `snapshotName` in TypeScript). A name resolves to the newest available snapshot with that name, so rebuilding under the same name rolls new sandboxes forward; an ID pins one snapshot. Names are case-sensitive and can't start with `snp-`.

Snapshots expire. Read `expires_at` (Python datetime) or `expiresAt` (TypeScript ISO 8601) rather than assuming a lifetime; the beta default is 30 days. For a base your product depends on, rebuild it on a schedule under the same name, for example with a Render cron job.

- Python deletion: `await sandboxes.snapshots.delete(sandbox_group_id=group_id, snapshot_id=snapshot_id)`
- TypeScript deletion: `await sandboxes.snapshots.delete({ sandboxGroupId, snapshotId })`

Deleting a snapshot leaves sandboxes already restored from it intact. Missing, expired, deleted, or wrong-group snapshots can't start new sandboxes. Don't delete a reusable snapshot just because the source's job finished.

Sources: [Python 1.5.0 release](https://github.com/render-oss/sdk/releases/tag/python/v1.5.0), [CLI 2.32.0 snapshot command](https://github.com/render-oss/cli/blob/v2.32.0/cmd/sandboxsnapshotscreate.go), [Python snapshot client](https://github.com/render-oss/sdk/blob/python/v1.5.0/python/render/experimental/sandbox/client.py), [TypeScript snapshot client](https://github.com/render-oss/sdk/blob/typescript/v1.5.0/typescript/src/experimental/sandboxes/index.ts).
