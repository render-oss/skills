# Private network communication patterns

Architecture examples and implementation notes for Render’s private network. Pair with the main `SKILL.md` for limits (region, workspace, free tier, ports).

## Gateway pattern

**Flow:** Public **Web Service** → one or more **Private Services** (or other internal targets).

- Expose only the gateway on the public internet.
- From the gateway process, call backends using **internal hostname and port**: `http://[internal-hostname]:[port]/...`
- Keep sensitive APIs and admin surfaces on Private Services; restrict security groups / auth at the gateway and at each service.

## Worker-to-DB

**Flow:** **Background Worker** → **Managed Postgres** (or **Key Value**) via **internal URL**.

- Workers **cannot** receive inbound private connections (no internal hostname); they are always clients.
- Store the datastore **internal URL** from the Dashboard (**Connect > Internal**) in an env var your worker reads at runtime.
- Use connection pooling appropriate for worker concurrency.

## Service mesh (lightweight)

**Flow:** Multiple **Private Services** (and optionally internal ports on Web Services) call each other by **internal hostnames**.

- Standardize on one scheme (`http` vs `https`) per hop; some clients require an explicit `http://` or `https://` prefix.

## URL construction

Use a consistent template:

```text
http://[internal-hostname]:[port]/path
```

- Replace `[internal-hostname]` and `[port]` with values from **Connect > Internal**.
- Add query strings and headers as needed; preserve trailing slashes if your upstream is sensitive to them.

## Blueprint wiring

In `render.yaml`, link services for private access using **`fromService`** on the consumer:

- Use properties such as **`host`** or **`hostport`** when the template needs the private service’s internal hostname or `host:port` (exact key names follow your Blueprint schema version—align with current Render Blueprint docs).

Ensure the producer service type supports private networking and that region/workspace match the consumer.

## Discovery hostname for custom load balancing

When a service scales to multiple instances:

- The **`[hostname]-discovery`** name resolves to **all** instance IPs.
- Combine with **`RENDER_DISCOVERY_SERVICE`** where provided to drive custom selection, retries, or metrics per instance.
- Useful when round-robin or sticky behavior must be implemented in application code rather than relying on a single internal A-record.
