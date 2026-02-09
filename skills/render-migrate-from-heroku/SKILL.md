---
name: render-migrate-from-heroku
description: "Orchestrate migration from Heroku to Render using both platforms' MCP servers. Triggers: any mention of migrating from Heroku, moving off Heroku, Heroku to Render migration, or switching from Heroku. Guides through a multi-step migration workflow: inventory Heroku app config, create equivalent Render services, bulk-migrate environment variables, generate database migration commands, and verify deployment health."
license: MIT
compatibility: Requires both the Heroku MCP server (heroku mcp:start or @heroku/mcp-server) and the Render MCP server
metadata:
  author: Render
  version: "1.1.0"
  category: migration
---

# Heroku to Render Migration via MCP

Orchestrate migration from Heroku to Render by reading from the Heroku MCP server and writing to the Render MCP server. Both must be connected to the current client.

## Prerequisites Check

Before starting, verify both MCP servers are available. Confirm access to:
- **Heroku MCP**: `list_apps` tool
- **Render MCP**: `list_services` tool

If either is missing, instruct the user to configure both servers. See the [MCP setup guide](references/mcp-setup.md).

## Migration Workflow

Execute steps in order. Present findings to the user and get confirmation before creating any resources.

### Step 1: Inventory Heroku App

Call these Heroku MCP tools and compile results:

1. `list_apps` — let user select which app to migrate
2. `get_app_info` — capture: app name, region, stack, buildpacks, config vars
3. `list_addons` — identify Postgres, Redis, Scheduler, third-party add-ons
4. `ps_list` — capture dyno types (web, worker, clock), sizes, counts

From the buildpack URLs, determine runtime. From the config or Procfile, determine start commands. See the [buildpack mapping](references/buildpack-mapping.md) for buildpack-to-runtime and Procfile-to-service mapping.

Present a summary:

```
App: [name] | Region: [region] | Runtime: [node/python/ruby/etc]
Build command: [inferred from buildpack]
Processes:
  web: [command from Procfile] → Render web service
  worker: [command] → Render background worker (Blueprint only)
  clock: [command] → Render cron job
  release: [command] → Append to build command
Add-ons: Heroku Postgres (standard-0), Heroku Data for Redis (mini)
Config vars: 14 total (list names, not values)
```

### Step 2: Pre-Flight Check

Before creating anything, validate the migration plan and present it to the user. Check for:

1. **Runtime supported?** If buildpack maps to `docker`, warn user they need a Dockerfile
2. **Worker dynos?** Flag these — can be defined in a Blueprint (`type: worker`, minimum plan `starter`), but cannot be created via MCP tools directly
3. **Release phase?** If Procfile has `release:`, suggest appending to build command
4. **Static site?** Check for static buildpack, `static.json`, or SPA framework deps — use `create_static_site` instead of `create_web_service`. See detection rules in the [buildpack mapping](references/buildpack-mapping.md).
5. **Third-party add-ons?** List any add-ons without direct Render equivalents (e.g., Papertrail, SendGrid) — user needs to find alternatives and update env vars
6. **Multiple process types?** If Procfile has >1 entry, each becomes a separate Render service (except `release:`)
7. **Repo URL available?** Ask user for their GitHub/GitLab repo URL (required for service creation)
8. **Database size?** If Postgres is Premium/large tier, recommend contacting Render support for assisted migration

Present the full plan as a table:

```
MIGRATION PLAN — [app-name]
─────────────────────────────────
CREATE (include only items that apply):
  ✅ Web service ([runtime], starter) — startCommand: [cmd]
  ✅ Background worker ([runtime], starter) — startCommand: [cmd]
  ✅ Cron job (starter) — schedule: [cron expr] — command: [cmd]
  ✅ Postgres (basic-1gb)
  ✅ Key Value (starter)

METHOD: [Blueprint | MCP Direct Creation]

MANUAL STEPS REQUIRED:
  ⚠️ Custom domain: [domain] — configure after deploy
  ⚠️ Replace add-on: [name] → find alternative

ENV VARS: [N] to migrate, [M] filtered out
DATABASE: [size] — pg_dump/pg_restore required
─────────────────────────────────
Proceed? (y/n)
```

Wait for user confirmation before creating any resources.

### Choose Creation Method

After the user approves the pre-flight plan, select the creation method:

**Use MCP Direct Creation** when ALL are true:
- Single web or static site service only
- No background workers or cron jobs
- No databases or Key Value stores needed

**Use Blueprint** (recommended for most migrations) when ANY are true:
- Multiple process types (web + worker, web + cron, etc.)
- Databases or Key Value stores needed
- Background workers in the Procfile
- User prefers Infrastructure-as-Code configuration

Most Heroku apps include at least a database, so Blueprint is the default path. If unsure, use Blueprint.

### Step 3A: Generate Blueprint (Multi-Service)

Generate a `render.yaml` file using the `projects`/`environments` pattern to group all migrated resources in a single Render project. See the [Blueprint example](references/blueprint-example.md) for a complete example and the [Blueprint YAML spec](https://render.com/docs/blueprint-spec#projects-and-environments) for the full reference.

Use the correct default plan for each service type. Since Heroku has no free tier, default to the cheapest **paid** Render plan (upgrade if the Heroku plan maps higher):

| Service type | Default plan |
|---|---|
| Web service (`type: web`) | `starter` |
| Static site (`runtime: static`) | `starter` |
| Background worker (`type: worker`) | `starter` |
| Cron job (`type: cron`) | `starter` |
| Key Value (`type: keyvalue`) | `starter` |
| Postgres (database) | `basic-1gb` |

**Blueprint structure:**

```yaml
projects:
  - name: <heroku-app-name>
    environments:
      - name: production
        services:
          - type: web
            name: <app>-web
            runtime: <mapped-runtime>
            plan: starter
            buildCommand: <build-cmd>
            startCommand: <web-cmd>
            envVars:
              - key: DATABASE_URL
                fromDatabase:
                  name: <app>-db
                  property: connectionString
              - key: REDIS_URL
                fromService:
                  type: keyvalue
                  name: <app>-cache
                  property: connectionString
              - fromGroup: <app>-env
          # Include only if worker dyno exists
          - type: worker
            name: <app>-worker
            runtime: <mapped-runtime>
            plan: starter
            buildCommand: <build-cmd>
            startCommand: <worker-cmd>
            envVars:
              - fromGroup: <app>-env
          # Include only if scheduler/clock exists
          - type: cron
            name: <app>-cron
            runtime: <mapped-runtime>
            plan: starter
            schedule: "<cron-expression>"
            buildCommand: <build-cmd>
            startCommand: <cron-cmd>
            envVars:
              - fromGroup: <app>-env
          # Include only if Redis add-on exists
          - type: keyvalue
            name: <app>-cache
            plan: starter
            ipAllowList:
              - source: 0.0.0.0/0
                description: everywhere
        databases:
          # Include only if Postgres add-on exists
          - name: <app>-db
            plan: basic-1gb
        envVarGroups:
          - name: <app>-env
            envVars:
              - key: NON_SECRET_VAR
                value: <value>
              - key: SECRET_VAR
                sync: false
```

**Key rules:**
- Use `fromDatabase` for `DATABASE_URL` — never hardcode connection strings
- Use `fromService` with `type: keyvalue` and `property: connectionString` for `REDIS_URL`
- Put shared config vars in `envVarGroups` and reference via `fromGroup` in each service
- Mark secrets with `sync: false` (user fills these in the Dashboard during Blueprint apply)
- Map region from Heroku using the [service mapping](references/service-mapping.md)
- Only include service/database blocks that the Heroku app actually uses

**After generating render.yaml:**

1. Write the file to the repo root
2. Validate with CLI if available: `render blueprints validate render.yaml`
3. Instruct user to commit and push: `git add render.yaml && git commit -m "Add Render migration Blueprint" && git push`
4. Generate Dashboard deeplink: `https://dashboard.render.com/blueprint/new?repo=<REPO_URL>`
5. Guide user to open the deeplink, fill in `sync: false` secrets, and click **Apply**

### Step 3B: MCP Direct Creation (Single-Service)

For single-service migrations without databases, create via MCP tools:

1. **Web service** — `create_web_service` with:
   - `runtime`: from the [buildpack mapping](references/buildpack-mapping.md)
   - `buildCommand`: from the [buildpack mapping](references/buildpack-mapping.md)
   - `startCommand`: from Procfile `web:` entry
   - `repo`: user-provided GitHub/GitLab URL
   - `region`: mapped from Heroku region
   - `plan`: `starter` (or mapped from dyno size, see the [service mapping](references/service-mapping.md))
2. **Static site** — `create_static_site` if detected (instead of web service)

Present the creation result (service URL, ID) when complete.

### Step 4: Migrate Environment Variables

1. Extract config vars from Heroku `get_app_info` results
2. Filter out auto-generated and Heroku-specific vars:
   - `DATABASE_URL`, `REDIS_URL`, `REDIS_TLS_URL` (Render generates these)
   - `HEROKU_*` vars (e.g., `HEROKU_APP_NAME`, `HEROKU_SLUG_COMMIT`)
   - Add-on connection strings (`PAPERTRAIL_*`, `SENDGRID_*`, etc.)
3. Present filtered list to user — **do not write without confirmation**

**Blueprint path (Step 3A):** Env vars are already embedded in the `render.yaml` via `envVarGroups` (non-secret values) and `sync: false` (secrets the user fills in during Blueprint apply). No separate MCP call is needed — skip to Step 5.

**MCP path (Step 3B):** Call Render `update_environment_variables` with confirmed vars (supports bulk set, merges by default).

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
