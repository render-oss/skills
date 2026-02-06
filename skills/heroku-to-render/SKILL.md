---
name: heroku-to-render
description: "Orchestrate migration from Heroku to Render using both platforms' MCP servers. Triggers: any mention of migrating from Heroku, moving off Heroku, Heroku to Render migration, or switching from Heroku. Guides through a multi-step migration workflow: inventory Heroku app config, create equivalent Render services, bulk-migrate environment variables, generate database migration commands, and verify deployment health."
license: MIT
compatibility: Requires both the Heroku MCP server (heroku mcp:start or @heroku/mcp-server) and the Render MCP server
metadata:
  author: Render
  version: "1.0.0"
  category: migration
---

# Heroku to Render Migration via MCP

Orchestrate migration from Heroku to Render by reading from the Heroku MCP server and writing to the Render MCP server. Both must be connected to the current client.

## Prerequisites Check

Before starting, verify both MCP servers are available. Confirm access to:
- **Heroku MCP**: `list_apps` tool
- **Render MCP**: `list_services` tool

If either is missing, instruct the user to configure both servers. See [references/mcp-setup.md](references/mcp-setup.md).

## Migration Workflow

Execute steps in order. Present findings to the user and get confirmation before creating any resources.

### Step 1: Inventory Heroku App

Call these Heroku MCP tools and compile results:

1. `list_apps` — let user select which app to migrate
2. `get_app_info` — capture: app name, region, stack, buildpacks, config vars
3. `list_addons` — identify Postgres, Redis, Scheduler, third-party add-ons
4. `ps_list` — capture dyno types (web, worker, clock), sizes, counts

From the buildpack URLs, determine runtime. From the config or Procfile, determine start commands. See [references/buildpack-mapping.md](references/buildpack-mapping.md) for buildpack-to-runtime and Procfile-to-service mapping.

Present a summary:

```
App: [name] | Region: [region] | Runtime: [node/python/ruby/etc]
Build command: [inferred from buildpack]
Processes:
  web: [command from Procfile] → Render web service
  worker: [command] → ⚠️ Manual (background worker)
  clock: [command] → Render cron job
  release: [command] → Append to build command
Add-ons: Heroku Postgres (standard-0), Heroku Data for Redis (mini)
Config vars: 14 total (list names, not values)
```

### Step 2: Pre-Flight Check

Before creating anything, validate the migration plan and present it to the user. Check for:

1. **Runtime supported?** If buildpack maps to `docker`, warn user they need a Dockerfile
2. **Worker dynos?** Flag these — must be created manually in Render dashboard
3. **Release phase?** If Procfile has `release:`, suggest appending to build command
4. **Static site?** Check for static buildpack, `static.json`, or SPA framework deps — use `create_static_site` instead of `create_web_service`. See detection rules in [references/buildpack-mapping.md](references/buildpack-mapping.md).
5. **Third-party add-ons?** List any add-ons without direct Render equivalents (e.g., Papertrail, SendGrid) — user needs to find alternatives and update env vars
6. **Multiple process types?** If Procfile has >1 entry, each becomes a separate Render service (except `release:`)
7. **Repo URL available?** Ask user for their GitHub/GitLab repo URL (required for service creation)
8. **Database size?** If Postgres is Premium/large tier, recommend contacting Render support for assisted migration

Present the full plan as a table:

```
MIGRATION PLAN — [app-name]
─────────────────────────────────
CREATE VIA MCP:
  ✅ Web service ([runtime], [plan]) — startCommand: [cmd]
  ✅ Postgres ([plan])
  ✅ Key Value ([plan])
  ✅ Cron job — schedule: [ask user] — command: [cmd]

MANUAL STEPS REQUIRED:
  ⚠️ Background worker: [command] — create in Render dashboard
  ⚠️ Custom domain: [domain] — configure after deploy
  ⚠️ Replace add-on: Papertrail → use Render logs or alternative

ENV VARS: [N] to migrate, [M] filtered out
DATABASE: [size] — pg_dump/pg_restore required
─────────────────────────────────
Proceed? (y/n)
```

Wait for user confirmation before creating any resources.

### Step 3: Create Render Services

After user approves the pre-flight plan, create services in this order:

1. **Database first** — `create_postgres` (so the URL is available for other services)
2. **Key Value** — `create_key_value` if Redis is needed
3. **Web service** — `create_web_service` with:
   - `runtime`: from buildpack mapping
   - `buildCommand`: from [references/buildpack-mapping.md](references/buildpack-mapping.md)
   - `startCommand`: from Procfile `web:` entry
   - `repo`: user-provided GitHub/GitLab URL
   - `region`: mapped from Heroku region
   - `plan`: mapped from dyno size (see [references/service-mapping.md](references/service-mapping.md))
4. **Static site** — `create_static_site` if detected (instead of web service)
5. **Cron job** — `create_cron_job` if Scheduler or `clock:` process exists (ask user for cron schedule)

Present each creation result (service URL, IDs) as they complete.

### Step 4: Migrate Environment Variables

1. Extract config vars from Heroku `get_app_info` results
2. Filter out auto-generated and Heroku-specific vars:
   - `DATABASE_URL`, `REDIS_URL`, `REDIS_TLS_URL` (Render generates these)
   - `HEROKU_*` vars (e.g., `HEROKU_APP_NAME`, `HEROKU_SLUG_COMMIT`)
   - Add-on connection strings (`PAPERTRAIL_*`, `SENDGRID_*`, etc.)
3. Present filtered list to user — **do not write without confirmation**
4. Call Render `update_environment_variables` with confirmed vars (supports bulk set, merges by default)

### Step 5: Database Migration (Commands Only)

Neither MCP server supports pg_dump/pg_restore. Generate commands using connection info from both sides:

1. Call Heroku `pg_info` for source connection string
2. Call Render `get_postgres` for destination connection info
3. Present commands with actual connection strings substituted:

```bash
# Put Heroku in maintenance mode (can use maintenance_on via Heroku MCP)
# Dump from Heroku
pg_dump -Fc --no-acl --no-owner -d <HEROKU_DB_URL> > heroku_dump.sql
# Restore to Render
pg_restore --clean --no-acl --no-owner -d <RENDER_EXTERNAL_DB_URL> heroku_dump.sql
```

Remind user: schedule maintenance window, databases >50GB should contact Render support.

### Step 6: Verify Migration

After user confirms database migration is complete:

1. `list_deploys` / `get_deploy` — check deploy status
2. `list_logs` — pull recent logs, check for errors
3. `get_metrics` — CPU, memory, HTTP latency
4. `query_render_postgres` — read-only query to confirm data (e.g., row count on a key table)

Present health summary.

### Step 7: DNS Cutover (Manual)

Instruct user to:
1. Add CNAME pointing domain to `[service-name].onrender.com`
2. Remove/update old Heroku DNS entries
3. Wait for propagation

## Rollback Plan

If the migration fails at any point:

- **Services created but not working**: Services can be deleted from the Render dashboard (MCP server intentionally does not support deletion). Heroku app is untouched until maintenance mode is enabled.
- **Env vars wrong**: Call `update_environment_variables` with `replace: true` to overwrite, or fix individual vars.
- **Database migration failed**: Render Postgres can be deleted and recreated. Heroku database is read-only during dump (no data loss). If `maintenance_off` is called on Heroku, the original app is fully operational again.
- **DNS already changed**: Revert CNAME to Heroku and disable maintenance mode on Heroku.

Key principle: **Heroku stays fully functional until the user explicitly cuts over DNS.** The migration is additive until that final step.

## Error Handling

- Service creation fails: show error, suggest fixes (invalid plan, bad repo URL)
- Env var migration partially fails: show which succeeded/failed
- Heroku auth errors: instruct `heroku login` or check `HEROKU_API_KEY`
- Render auth errors: check Render API key in MCP config
