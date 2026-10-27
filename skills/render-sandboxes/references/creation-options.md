# Choose sandbox create options

Retrieve the complete option list for the client being used, then select the fields the task needs. Do not reconstruct a flag, parameter, plan, or limit catalog from memory.

## Read the current contract

- **CLI:** run `render --version` and `render sandboxes create --help`. Installed help is authoritative for that version. If the CLI is unavailable, follow the root documentation-retrieval workflow for the [CLI reference](https://render.com/docs/sandboxes-cli-reference.md) ([HTML](https://render.com/docs/sandboxes-cli-reference)).
- **Python SDK:** check the project's installed `render` version, then retrieve the [Python SDK reference](https://render.com/docs/sandboxes-sdk-python.md) ([HTML](https://render.com/docs/sandboxes-sdk-python)).
- **TypeScript SDK:** check the project's installed `@renderinc/sdk` version, then retrieve the [TypeScript SDK reference](https://render.com/docs/sandboxes-sdk-typescript.md) ([HTML](https://render.com/docs/sandboxes-sdk-typescript)).

For SDKs, follow the same root retrieval workflow. Inspect the installed method signature/input type or matching release source if published examples differ. If the user asks for every option, enumerate and explain the options from the retrieved contract. Report gaps instead of inventing unsupported fields.

## Make the creation decisions

1. Confirm the workspace and sandbox group. Select the group for placement; do not use a deprecated sandbox `region` field to move it.
2. Choose the default image, a succeeded build, or an available snapshot. Build and snapshot sources are mutually exclusive. Use an ID to pin a resource or a name to follow its latest usable version. See [custom images](environment-and-access.md#custom-images-and-storage) and [snapshots](snapshots.md).
3. Choose compute and time limits for the workload using [current plans and limits](environment-and-access.md#plans-limits-and-pricing). Runtime restores must match the snapshot's plan; filesystem restores can change plans. Keep the startup wait, continuous runtime, and idle-suspension settings distinct.
4. Set egress and guest environment deliberately. Restores need an explicit network policy; guest code can read supplied credentials. See [environment and access](environment-and-access.md).
5. Record the new ID before waiting for readiness. A failed wait does not remove the resource. Follow [SDK cleanup and wait handling](sdk-patterns.md#create-options-and-version-differences) or [CLI operations](cli.md).
