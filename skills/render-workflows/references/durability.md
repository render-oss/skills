# Replay Diagnosis and Recovery Verification

Read [flows.md](flows.md) for flow APIs, execution rules, retry behavior, and external-write idempotency. Use this reference to investigate recorded history or verify recovery.

## Diagnose a replay mismatch

A replay mismatch fails the run. Preserve the history and investigate before proposing a repair:

1. Locate the first divergent call in the recorded history and compare its step name, serialized inputs, and position with the replayed call.
2. Trace those differences to orchestration outside steps: clock reads, randomness, external reads, or unstable iteration.
3. Reproduce the divergence with an isolated recorded-history fixture.

Runs retain their starting image/version: redeploying alone neither changes their replay code nor tests a mismatch. Do not discard history to bypass the error.

## Recovery verification

The development SDK includes Python step/retry/replay unit tests in `python/render/workflows/tests/test_flow.py` and TypeScript tests in `typescript/src/workflows/durable/flow.test.ts`. Run these from an isolated SDK checkout with its declared dependencies to check the local implementation. Passing fake-backend tests does not establish CLI or deployed recovery support.

For the internal staging harness, use the smoke apps in `internal-examples/durability` and `internal-examples/durability-typescript` from `feature/durability`, pinned to the same commit. `smoke_inline_retry` verifies inline retry; `smoke_replay` verifies completed-step reuse after node loss. Replay requires deployed step-history REST readers and explicit permission to terminate the staging node, which can affect other workloads. A process exit is terminal in this runtime and is not a substitute for node loss.

Use a disposable development workflow and test data. Verify the backend supports recovery; do not kill production processes as a test.

1. Unit-test plain helpers and run the complete workflow once. Confirm expected output and ordered step history.
2. With the environment's supported fault-injection mechanism, interrupt after a completed step has been recorded and before the next finishes. A user cancellation or thrown business error is not a substitute for infrastructure failure.
3. Confirm recovery belongs to the same logical run and uses the original code version. Previously completed bodies must not execute again. Use recorded history and external invocation counters, not only final output.
4. Interrupt a step mid-attempt and verify retry counts continue across recovery and respect the configured limit. Test the exhausted-budget outcome.
5. Test a write that succeeds before its completion is recorded. Verify the business operation is deduplicated even if its body executes again.
6. In an isolated replay fixture or supported test harness, change a recorded step's name/input/order and verify a terminal determinism failure. Deploying new code is not a reliable mismatch test because existing runs retain their original version.
7. Verify durable parallel calls and registered tasks passed to `ctx.step` are rejected by the selected SDK.

If fault injection or durable runtime access is unavailable, report the untested cases explicitly. Function tests, static checks, fixture replay, and deployed recovery tests provide different evidence; do not collapse them into “durability verified.”
