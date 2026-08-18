# Instance types on Render

Current Blueprint **plan** specs for Web Services, Private Services, and Background Workers. Verify current pricing at [Render pricing](https://render.com/pricing).

## Plan and spec table

| Plan | CPU | RAM | Availability |
|------|-----|-----|--------------|
| `free` | 0.1 | 512 MB | Web services only |
| `starter` | 0.5 | 512 MB | Web, private, and worker services |
| `standard` | 1 | 2 GB | Web, private, and worker services |
| `pro` | 2 | 4 GB | Web, private, and worker services |
| `pro plus` | 4 | 8 GB | Web, private, and worker services |
| `pro max` | 4 | 16 GB | Web, private, and worker services |
| `pro ultra` | 8 | 32 GB | Web, private, and worker services |

> **Note:** Use [render.com/pricing](https://render.com/pricing) for authoritative current rates.

## Flexible vs non-flexible plans

Some plans are **flexible** (usable in mixed configurations such as **preview environments** alongside other instance types where the platform allows it); others are **non-flexible**. Exact flexible-plan rules depend on workspace and product updates—confirm in the Dashboard or docs when mixing preview and production instance types.

## When to scale up vs out

- **Scale up** (larger **plan**): **Memory-intensive** apps, **single-process** or **single-threaded** architectures, workloads that need **more CPU per request** or **larger heap** without sharding.
- **Scale out** (more **instances**): **Stateless** request handlers, **high concurrency**, **even load distribution** across identical processes.
- **Both**: Start with a **right-sized plan**, then add **horizontal** scaling as traffic grows. Avoid tiny instances multiplied many times if each process needs substantial RAM.

## Free tier limitations

- **Single instance** for a Free web service.
- Web services **spin down after inactivity** (cold starts on the next request).
- **Limited** CPU and memory vs paid plans—treat free-tier behavior as distinct when advising on performance and scaling.
