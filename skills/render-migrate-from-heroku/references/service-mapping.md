# Heroku → Render Service Mapping

## How to Use This Reference

Look up the Heroku plan from `ps_list` (dyno size) or `list_addons` (add-on plan slug) and use the corresponding Render plan in the Blueprint or MCP creation call. If the Heroku plan is unknown, use the fallback default.

## Compute (Dynos → Services)

Match web and worker dynos by RAM to avoid out-of-memory issues. See the cron-specific guidance below before mapping a scheduled Heroku process.

| Heroku dyno | Heroku RAM | Render `plan` value | Render RAM |
|---|---|---|---|
| Eco | 512 MB | `starter` | 512 MB |
| Basic | 512 MB | `starter` | 512 MB |
| Standard-1X | 512 MB | `starter` | 512 MB |
| Standard-2X | 1 GB | `standard` | 2 GB |
| Performance-M | 2.5 GB | `pro` | 4 GB |
| Performance-L | 14 GB | `pro max` | 16 GB |
| Performance-L-RAM | 30 GB | `pro ultra` | 32 GB |
| Performance-XL | 62 GB | Custom | 64 GB |
| Performance-2XL | 126 GB | Custom | 128 GB |

**Fallback default:** `starter` (when Heroku dyno size is unknown)

**Notes:**
- Worker dynos on Heroku can be any size (Standard-1X, Performance-M, etc.) — use the same mapping based on the dyno size reported by `ps_list`
- **Cron jobs:** Render cron jobs support `starter`, `standard`, `pro`, and `pro plus` only (up to 4 CPU / 8 GB RAM). Use the table for cron jobs through Performance-M. For Performance-L and larger Heroku cron dynos, there is no equivalent Render cron plan; reduce or split the job, move the scheduled work to a background worker, or contact Render about the workload.
- Performance-L-RAM has 4 CPU (half of Pro Ultra's 8 CPU). For non-enterprise customers, default to `pro ultra`; contact Render if custom sizing is required.
- For Performance-XL and Performance-2XL, instruct the user to [contact Render](https://render.com/contact) for custom sizing.
- Confirm current plan charges at [Render pricing](https://render.com/pricing); do not estimate costs from proportional sizing.

## Postgres (Heroku Postgres → Render Postgres)

Heroku has deprecated Mini and Basic plans. Current tiers are Essential, Standard, and Premium.

Render has three Postgres tiers:
- **Basic** — entry-level, for development and low-traffic apps
- **Pro** — balanced CPU-to-RAM ratio (1:4), for production workloads
- **Accelerated** — memory-optimized CPU-to-RAM ratio (1:8), for high-performance and memory-intensive workloads

Map Heroku Essential → Render Basic. For Standard and Premium, both map to the **same Render plan per tier** — Standard as a single instance, Premium with HA enabled. HA adds a separately billed standby instance. Tiers 0 and 2 map to Render Pro; tiers 3 through 9 map to Render Accelerated.

### Essential and legacy plans → Render Basic

| Heroku plan | Heroku disk | Render `plan` value | Render `diskSizeGB` |
|---|---|---|---|
| Essential-0 | 1 GB | `basic-256mb` | 1 |
| Essential-1 | 10 GB | `basic-256mb` | 10 |
| Essential-2 | 32 GB | `basic-1gb` | 35 |
| Mini (legacy, EOL) | 1 GB | `basic-256mb` | 1 |
| Basic (legacy, EOL) | 10 GB | `basic-256mb` | 10 |

### Standard and Premium plans → Render Pro / Accelerated

Heroku Standard and Premium share the same tier numbering (X-0 through X-9) with identical vCPU, RAM, and storage specs. The difference is that **Premium includes HA by default**. On Render, both map to the same plan—enable HA on Render to match Premium. The standby instance adds cost.

| Heroku tier | vCPU | RAM | Storage | Render `plan` value | Render `diskSizeGB` |
|---|---|---|---|---|---|
| X-0 | 2 | 4 GB | 64 GB | `pro-4gb` | 65 |
| X-2 | 2 | 8 GB | 256 GB | `pro-8gb` | 260 |
| X-3 | 2 | 15 GB | 512 GB | `accelerated-16gb` | 515 |
| X-4 | 4 | 30 GB | 768 GB | `accelerated-32gb` | 770 |
| X-5 | 8 | 61 GB | 1 TB | `accelerated-64gb` | 1025 |
| X-6 | 16 | 122 GB | 1.5 TB | `accelerated-128gb` | 1540 |
| X-7 | 32 | 244 GB | 2 TB | `accelerated-256gb` | 2050 |
| X-8 | 64 | 488 GB | 3 TB | `accelerated-512gb` | 3075 |
| X-9 | 96 | 768 GB | 4 TB | `accelerated-768gb` | 4100 |

**How to read the tier number:** The add-on plan slug from `list_addons` looks like `heroku-postgresql:standard-0` or `heroku-postgresql:premium-4` — the number after the hyphen is the tier (X-0, X-4, etc.). Both Standard-4 and Premium-4 map to the same Render plan (`accelerated-32gb`); Premium just needs HA enabled.

**HA cost note:** Heroku Premium includes HA by default. To match this on Render, enable HA in the Dashboard or Blueprint. The standby is billed separately, so call out the additional cost and confirm current details at [Render pricing](https://render.com/pricing).

### Disk sizing

On Render, storage is billed separately from compute and configured with `diskSizeGB` in the Blueprint. Storage is provisioned in **5 GB increments** (minimum 1 GB) and **cannot be scaled down** once provisioned. Confirm current storage charges at [Render pricing](https://render.com/pricing).

**Heuristic:** Carry over the Heroku disk size as the `diskSizeGB` value. Since `diskSizeGB` must be 1 or a multiple of 5, round up to the nearest valid value.

**Disclaimer to present to the user:** Heroku bundles a fixed storage allocation with each plan. On Render, compute and storage are billed separately. Storage cannot be scaled down once provisioned, so right-size based on actual usage rather than the Heroku allocation. Check current usage with `heroku pg:info` (look for `Data Size`). If actual data is much smaller than the allocated disk, start with a smaller `diskSizeGB`; you can expand later from the Render Dashboard. Confirm current charges at [Render pricing](https://render.com/pricing).

**Fallback default:** `basic-1gb` with no `diskSizeGB` (when Heroku Postgres plan is unknown — Render uses a default disk size)

**Notes:**
- Render Pro and Accelerated both support HA (enable separately in Dashboard or Blueprint)
- For databases beyond tier X-9, contact Render support
- Get actual disk usage from `pg_info` (`Data Size` field) to inform the `diskSizeGB` recommendation

## Key Value (Heroku Key-Value Store → Render Key Value)

Heroku's Key-Value Store is Valkey-based. Its plans use non-sequential numbering (0, 1, 2, 3, 5, 7, 9, 10, 12, 14). Match by the exact plan number from `list_addons`.

| Heroku plan | Heroku memory | Heroku connections | Render `plan` value | Render RAM | Render connections |
|---|---|---|---|---|---|
| Mini | 25 MB | 20 | `free` | 25 MB | 50 |
| Premium-0 | 50 MB | 40 | `starter` | 256 MB | 250 |
| Premium-1 | 100 MB | 80 | `starter` | 256 MB | 250 |
| Premium-2 | 250 MB | 200 | `starter` | 256 MB | 250 |
| Premium-3 | 500 MB | 400 | `standard` | 1 GB | 1,000 |
| Premium-5 | 1 GB | 1,000 | `standard` | 1 GB | 1,000 |
| Premium-7 | 7 GB | 10,000 | `pro plus` | 10 GB | 10,000 |
| Premium-9 | 10 GB | 25,000 | `pro max` | 20 GB | 20,000 |
| Premium-10 | 25 GB | 40,000 | Custom | — | — |
| Premium-12 | 50 GB | 65,000 | Custom | — | — |
| Premium-14 | 100 GB | 65,000 | Custom | — | — |

**Fallback default:** `starter` (when the Heroku Key-Value Store plan is unknown)

**Notes:**
- Confirm current Key Value charges at [Render pricing](https://render.com/pricing); do not infer savings from historical plan prices.
- The add-on plan slug from `list_addons` looks like `heroku-redis:mini` or `heroku-redis:premium-0` — use the part after the colon to look up the mapping. Plans 4, 6, 8, 11, and 13 do not exist on Heroku.
- Render Key Value requires `ipAllowList` in the Blueprint (use `0.0.0.0/0` for public access)
- Neither Heroku nor Render supports Key Value high availability.
- For Premium-10 and above, instruct the user to [contact Render](https://render.com/contact) for custom sizing.

## Runtime Mapping

| Heroku Buildpack | Render Runtime | `runtime` param |
|---|---|---|
| heroku/nodejs | Node | `node` |
| heroku/python | Python | `python` |
| heroku/go | Go | `go` |
| heroku/ruby | Ruby | `ruby` |
| heroku/java | Docker | `docker` |
| heroku/php | Docker | `docker` |
| heroku/scala | Docker | `docker` |
| Multi-buildpack | Docker | `docker` |

## Region Mapping

| Heroku Region | Render Region | `region` param |
|---|---|---|
| us | Oregon (default) | `oregon` |
| eu | Frankfurt | `frankfurt` |

## Not Directly Mappable (Manual)

These Heroku features require manual alternatives on Render:
- **Heroku Pipelines** → Use Render Preview Environments + manual promotion
- **Review Apps** → Render Pull Request Previews
- **Heroku Add-ons Marketplace** → Find equivalent third-party services
- **Heroku ACM (SSL)** → Render auto-provisions TLS for custom domains
- **Private Spaces** → Contact Render for private networking options
- **Heroku Kafka** → Not supported on Render. Recommend cloud providers (Confluent Cloud, AWS MSK, etc.)
- **Hirefire** → Not supported on Render. Recommend Render's native [horizontal autoscaling](https://render.com/docs/scaling) or JudoScale (which is supported).
- **Bandwidth** → Render workspace plans include an outbound-bandwidth allowance. Usage beyond that allowance incurs an additional cost. Confirm current allowances and charges at [Render pricing](https://render.com/pricing) or in the Dashboard.

## Environment Variables to Filter

Always exclude these when migrating env vars:

**Render auto-generates:**
- `DATABASE_URL`
- `REDIS_URL`, `REDIS_TLS_URL`

**Heroku-specific (no Render equivalent):**
- `HEROKU_APP_NAME`
- `HEROKU_SLUG_COMMIT`
- `HEROKU_SLUG_DESCRIPTION`
- `HEROKU_DYNO_ID`
- `HEROKU_RELEASE_VERSION`
- `PORT` (Render sets its own)

**Add-on connection strings (replace with new service URLs):**
- `PAPERTRAIL_*`
- `SENDGRID_*`
- `CLOUDAMQP_*`
- `BONSAI_*`
- `FIXIE_*`
- Any other `*_URL` vars pointing to Heroku add-on services
