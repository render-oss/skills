# Environment and access

Baseline: SDKs 1.5.0 and CLI 2.32.0, checked 2026-10-27. Follow the root documentation-retrieval workflow for the [current overview](https://render.com/docs/sandboxes.md), with [HTML fallback](https://render.com/docs/sandboxes). Verify a changing capability in both the installed client and the target workspace.

## Resolve a capability gap

If the installed client doesn't expose what the user wants, check the current docs and that client version's source once, then answer with:

- What the client supports, and which part of the request it can't do.
- The upgrade, client, or rollout needed to proceed.
- Any supported partial solution, labeled as partial.

Generated REST types alone don't mean a feature is deployed. Don't keep searching other SDKs or changelogs to prove a negative, and don't write speculative integration code.

## Egress policies

Pass a policy on every create; the default is `allow-all`. The types are `allow-all`, `deny-all`, and `allow-list`, and a policy can't change after creation. Python uses typed objects; TypeScript uses `type` and `rules` (not the older `default` or `allowedDomains` shapes).

```python
from render.sandbox import EgressRule, NetworkPolicy
policy = NetworkPolicy(type="allow-list", rules=[
    EgressRule(domain="pypi.org"),
    EgressRule(domain="files.pythonhosted.org"),
])
# await sandboxes.create(network_policy=policy, timeout_seconds=600)
```

```typescript
const policy = {
  type: "allow-list" as const,
  rules: [{ domain: "pypi.org" }, { domain: "files.pythonhosted.org" }],
};
// await sandboxes.create({ networkPolicy: policy, timeoutSeconds: 600 });
```

These hosts are for Python package installs; list the workload's actual registry, redirect, and artifact hosts. Rules are HTTPS only. Matching is exact (`example.com` doesn't cover `api.example.com`), and a wildcard works only as the leftmost label. Don't widen to `allow-all` just to make a failing install pass. Better still, install dependencies once into a [snapshot](snapshots.md) so untrusted runs need no registry access.

After create or restore, check one allowed and one blocked destination. A failed request can also be a DNS, TLS, or application error, so read the actual error. Restores don't inherit the source's policy; pass it again.

## Select inputs before upload

Upload an explicit list of the source and data files the job needs, not the whole project. Decide by path without printing secret contents. Exclude `.env` files, private keys, credential directories, `.git`, unrelated customer data, and symlinks that point outside the selected inputs. `.gitignore` isn't an upload filter, so check ignored and untracked files too. Never copy a home directory or forward the caller's full environment.

If the job needs a credential, pass only that value, and remember guest code can read it. Before turning a used sandbox into a reusable base, apply the [snapshot checks](snapshots.md).

## Credentials and connectivity

Guest code can read every `env` value. The Render API key stays in the caller; the sandbox never needs it. Don't inject broad credentials into untrusted workloads.

Credential brokering is **not available at beta launch**. Do not offer Dashboard setup, an enablement request, or invented SDK/CLI methods as a working integration. If the user requires an API token to be inaccessible to guest code, explain that this part cannot currently be met with native credential brokering. You can still provide the supported sandbox/build portion, clearly labeled as partial. Passing the token through `env` does not meet that requirement.

Don't assume a sandbox can reach a Render service's private hostname because both are on Render; verify it. Don't open a database to public traffic as a workaround. A process listening inside a sandbox doesn't get public ingress or a preview URL.

## Plans, limits, and pricing

Before choosing compute or quoting limits, follow the root documentation-retrieval workflow to read the [current compute-plan reference](https://render.com/docs/compute-plans.md) ([HTML](https://render.com/docs/compute-plans)) and [Sandboxes documentation](https://render.com/docs/sandboxes.md) ([HTML](https://render.com/docs/sandboxes)). Use the Sandbox-specific sections and verify that the installed client's create input accepts the selected plan. Do not infer a workspace-specific plan allow-list.

Check the limits relevant to the task, including workspace-tier differences, continuous runtime, idle suspension, concurrency, storage, and request rates. For the beta timeout behavior, see [lifecycle and recovery](troubleshooting.md#lifetime-is-not-idle-timeout); snapshot expiry and restore constraints live in [snapshots](snapshots.md). Keep these distinct from ordinary Render service limits.

Read [Render pricing](https://render.com/pricing) for current Sandbox rates and billing units before estimating cost. Do not substitute web-service pricing or assume suspension is free. If a requested plan, rate, or limit cannot be verified, identify the gap and preserve an existing valid configuration where possible.

## Custom images and storage

SDKs 1.5.0 and CLI 2.32.0 support builds from OCI images. State the required architecture in the integration: `linux/amd64`. Create the build in the intended group, record its ID, and poll with a deadline and request timeouts until `succeeded`; report `failure_reason` (Python) / `failureReason` (TypeScript) on `failed`. Build creation returns before conversion finishes. Then create a sandbox in that same group using the build ID or name. A name selects the newest succeeded build; use an ID to pin one build. Do not combine a build source with a snapshot source.

| Step | Python async | TypeScript |
| --- | --- | --- |
| Start build | `await sandboxes.builds.create(sandbox_group_id=group_id, name="agent", source_image="python:3.13")` | `await sandboxes.builds.create({ sandboxGroupId, name: "agent", sourceImage: "python:3.13" })` |
| Check build | `await sandboxes.builds.from_id(sandbox_group_id=group_id, build_id=build.id)` | `await sandboxes.builds.get({ sandboxGroupId, buildId: build.id })` |
| Create after success | `await sandboxes.create(sandbox_group_id=group_id, build_id=build.id, timeout_seconds=600, network_policy="deny-all")` | `await sandboxes.create({ sandboxGroupId, buildId: build.id, timeoutSeconds: 600, networkPolicy: { type: "deny-all" } })` |

There is no built-in build wait helper in SDK 1.5.0. For Python, this caller deadline bounds both status requests and sleeps:

```python
import asyncio

async def wait_for_build(sandboxes, group_id, build_id, timeout_seconds=300):
    async def poll():
        while True:
            build = await sandboxes.builds.from_id(
                sandbox_group_id=group_id, build_id=build_id,
            )
            if build.status == "succeeded":
                return build
            if build.status == "failed":
                raise RuntimeError(f"Build {build_id} failed: {build.failure_reason}")
            await asyncio.sleep(2)
    return await asyncio.wait_for(poll(), timeout=timeout_seconds)
```

Call it after recording the created build's ID and before creating a sandbox. A timeout does not cancel the remote build; retain its ID for recovery. TypeScript's build `get` does not accept an abort signal in 1.5.0; a strict deadline needs a bounded caller process, not just a clock check between unbounded requests. These build signatures are not complete sandbox readiness/cleanup loops; use [SDK patterns](sdk-patterns.md) after creation. For older clients, upgrade or use a prepared [filesystem snapshot](snapshots.md) for file-only reuse. SDK 1.4.0 has no high-level build workflow.

Guest files live and die with the sandbox unless downloaded or snapshotted. Snapshots make independent copies, not a shared volume.

Sources: [Python policy types](https://github.com/render-oss/sdk/blob/python/v1.5.0/python/render/experimental/sandbox/types.py), [TypeScript input serialization](https://github.com/render-oss/sdk/blob/typescript/v1.5.0/typescript/src/experimental/sandboxes/index.ts), [CLI plans](https://github.com/render-oss/cli/blob/v2.32.0/cmd/sandboxcreate.go).
