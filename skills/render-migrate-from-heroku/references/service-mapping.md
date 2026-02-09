# Heroku → Render Service Mapping

## Default Render Plans (Migration)

Since Heroku has no free tier, default to the cheapest **paid** Render plan. Upgrade if the Heroku plan maps higher.

| Service type | Default plan | Notes |
|---|---|---|
| Web service (`type: web`) | `starter` | |
| Static site (`runtime: static`) | `starter` | |
| Background worker (`type: worker`) | `starter` | |
| Cron job (`type: cron`) | `starter` | |
| Private service (`type: pserv`) | `starter` | |
| Key Value (`type: keyvalue`) | `starter` | `ipAllowList` required |
| Postgres (database) | `basic-1gb` | Cheapest paid Postgres |

## Compute

| Heroku | Render | Render MCP Tool / Blueprint | Notes |
|--------|--------|-----------------|-------|
| Basic dyno (web) | Starter plan | `create_web_service` or Blueprint `type: web` | Heroku eliminated free/hobby dynos |
| Standard-1X (web) | Starter plan | `create_web_service` or Blueprint `type: web` | |
| Standard-2X (web) | Standard plan | `create_web_service` or Blueprint `type: web` | |
| Performance-M (web) | Pro plan | `create_web_service` or Blueprint `type: web` | |
| Performance-L (web) | Pro Plus plan | `create_web_service` or Blueprint `type: web` | |
| Worker dyno | Starter plan (min) | Blueprint `type: worker` | MCP cannot create workers; use Blueprint or Dashboard |
| Heroku Scheduler | Starter plan (min) | `create_cron_job` or Blueprint `type: cron` | Convert schedule to cron syntax |

## Databases

| Heroku | Render | Render MCP Tool | Notes |
|--------|--------|-----------------|-------|
| Postgres Mini/Basic | basic-1gb Postgres | `create_postgres` | Cheapest paid Postgres |
| Postgres Standard-0 | Starter Postgres | `create_postgres` | |
| Postgres Standard-2+ | Pro Postgres | `create_postgres` | Match RAM/storage tier |
| Postgres Premium | Pro+ Postgres | `create_postgres` | |

## Caching

| Heroku | Render | Render MCP Tool | Notes |
|--------|--------|-----------------|-------|
| Heroku Data for Redis Mini | Starter Key Value | `create_key_value` | Cheapest paid Key Value |
| Heroku Data for Redis Premium-0+ | Starter+ Key Value | `create_key_value` | Match plan tier |

## Runtime Mapping

| Heroku Buildpack | Render Runtime | `runtime` param |
|-----------------|----------------|-----------------|
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
|--------------|---------------|----------------|
| us | Oregon (default) | `oregon` |
| eu | Frankfurt | `frankfurt` |

## Not Directly Mappable (Manual)

These Heroku features require manual alternatives on Render:
- **Heroku Pipelines** → Use Render Preview Environments + manual promotion
- **Review Apps** → Render Pull Request Previews
- **Heroku Add-ons Marketplace** → Find equivalent third-party services
- **Heroku ACM (SSL)** → Render auto-provisions TLS for custom domains
- **Private Spaces** → Contact Render for private networking options

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
