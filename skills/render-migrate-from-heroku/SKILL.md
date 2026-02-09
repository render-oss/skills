---
name: render-migrate-from-heroku
description: "Migrate from Heroku to Render by reading local project files and generating equivalent Render services. Triggers: any mention of migrating from Heroku, moving off Heroku, Heroku to Render migration, or switching from Heroku. Reads Procfile, dependency files, and app config from the local repo. Optionally uses Heroku MCP to enrich with live config vars, add-on details, and dyno sizes. Uses Render MCP or Blueprint YAML to create services."
license: MIT
compatibility: Requires the Render MCP server. Heroku MCP server is optional (enhances config var and add-on discovery).
metadata:
  author: Render
  version: "1.2.0"
  category: migration
---

# Heroku to Render Migration

Migrate from Heroku to Render by reading local project files first, then optionally enriching with live Heroku data via MCP.

## Prerequisites Check

Before starting, verify what's available:

1. **Local project files** (required) — confirm the current directory contains a Heroku app (look for `Procfile`, `app.json`, `package.json`, `requirements.txt`, `Gemfile`, `go.mod`, or similar)
2. **Render MCP** (required) — confirm access to `list_services` tool
3. **Heroku MCP** (optional) — check if `list_apps` tool is available

If Render MCP is missing, instruct the user to configure it. If Heroku MCP is missing, note that config var values and add-on plan details will need to be provided manually. See the [MCP setup guide](references/mcp-setup.md).

## Migration Workflow

Execute steps in order. Present findings to the user and get confirmation before creating any resources.

### Step 1: Inventory Heroku App

Gather app details from local files first, then supplement with Heroku MCP if available.

#### 1a. Read local project files (always)

Read these files from the repo to determine runtime, commands, and dependencies:

| File | What it tells you |
|---|---|
| `Procfile` | Process types and start commands (`web`, `worker`, `clock`, `release`) |
| `package.json` | Node.js runtime, build scripts, framework deps (Next.js, React, etc.) |
| `requirements.txt` / `Pipfile` / `pyproject.toml` | Python runtime, dependencies (Django, Flask, etc.) |
| `Gemfile` | Ruby runtime, dependencies (Rails, Sidekiq, etc.) |
| `go.mod` | Go runtime |
| `Cargo.toml` | Rust runtime |
| `app.json` | Declared add-ons, env var descriptions, buildpacks |
| `runtime.txt` | Pinned runtime version |
| `static.json` | Static site indicator |
| `yarn.lock` / `pnpm-lock.yaml` | Package manager (affects build command) |

From these files, determine:
- **Runtime** — from dependency files (see the [buildpack mapping](references/buildpack-mapping.md))
- **Build command** — from package manager and framework (see the [buildpack mapping](references/buildpack-mapping.md))
- **Start commands** — from `Procfile` entries
- **Process types** — from `Procfile` (web, worker, clock, release)
- **Add-ons needed** — from `app.json` `addons` field, or infer from dependency files (e.g., `pg` in `package.json` suggests Postgres, `redis` suggests Key Value)
- **Static site?** — from `static.json`, SPA framework deps, or static buildpack in `app.json`

#### 1b. Enrich with Heroku MCP (if available)

If the Heroku MCP server is connected, call these tools to fill in details that aren't in the repo:

1. `list_apps` — let user select which app to migrate (confirms app name)
2. `get_app_info` — capture: region, stack, buildpacks, **config var names**
3. `list_addons` — identify exact add-on plans (Postgres tier, Redis tier)
4. `ps_list` — capture dyno types, sizes, and counts (maps to Render plan tiers)

If Heroku MCP is **not** available, ask the user to provide:
- App region (`us` or `eu`)
- List of add-ons and their plans (or run `heroku addons -a <app>` in terminal)
- Config var names (or run `heroku config -a <app> --shell` and paste output)

#### Present summary

```
App: [name] | Region: [region] | Runtime: [node/python/ruby/etc]
Source: [local files | local files + Heroku MCP]
Build command: [inferred from buildpack/deps]
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

This step has three mandatory sub-steps. Complete all three in order.

#### 3A-i. Write render.yaml

Generate a `render.yaml` file and write it to the repo root. See the [Blueprint example](references/blueprint-example.md) for a complete example and the [Blueprint YAML spec](https://render.com/docs/blueprint-spec#projects-and-environments) for the full reference.

**IMPORTANT: Always use the `projects`/`environments` pattern.** The YAML must start with a `projects:` key — never use flat top-level `services:` or `databases:` keys. This groups all migrated resources into a single Render project.

Use the correct default plan for each service type. Since Heroku has no free tier, default to the cheapest **paid** Render plan (upgrade if the Heroku plan maps higher):

| Service type | Default plan |
|---|---|
| Web service (`type: web`) | `starter` |
| Static site (`runtime: static`) | `starter` |
| Background worker (`type: worker`) | `starter` |
| Cron job (`type: cron`) | `starter` |
| Key Value (`type: keyvalue`) | `starter` |
| Postgres (database) | `basic-1gb` |

**Required Blueprint structure** (always starts with `projects:`):

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
              - key: NON_SECRET_VAR
                value: <value>
              - key: SECRET_VAR
                sync: false
          # Include only if worker dyno exists
          - type: worker
            name: <app>-worker
            runtime: <mapped-runtime>
            plan: starter
            buildCommand: <build-cmd>
            startCommand: <worker-cmd>
            envVars:
              - key: NON_SECRET_VAR
                value: <value>
              - key: SECRET_VAR
                sync: false
          # Include only if scheduler/clock exists
          - type: cron
            name: <app>-cron
            runtime: <mapped-runtime>
            plan: starter
            schedule: "<cron-expression>"
            buildCommand: <build-cmd>
            startCommand: <cron-cmd>
            envVars:
              - key: NON_SECRET_VAR
                value: <value>
              - key: SECRET_VAR
                sync: false
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
```

**Key rules:**
- The YAML **must** start with `projects:` — never use flat top-level `services:`
- Use `fromDatabase` for `DATABASE_URL` — never hardcode connection strings
- Use `fromService` with `type: keyvalue` and `property: connectionString` for `REDIS_URL`
- Define env vars directly on each service (do not use `envVarGroups`)
- Mark secrets with `sync: false` (user fills these in the Dashboard during Blueprint apply)
- Map region from Heroku using the [service mapping](references/service-mapping.md)
- Only include service/database blocks that the Heroku app actually uses

#### 3A-ii. Validate the Blueprint

This step is mandatory. Run the validation command and show the output to the user:

```bash
render blueprints validate render.yaml
```

If validation fails, fix the errors in the YAML and re-validate. Repeat until validation passes. **Do not proceed to the next step until the Blueprint validates successfully.**

#### 3A-iii. Provide the deploy URL

After validation passes:

1. Instruct user to commit and push: `git add render.yaml && git commit -m "Add Render migration Blueprint" && git push`
2. Get the repo URL by running `git remote get-url origin`. If the URL is SSH format (e.g., `git@github.com:user/repo.git`), convert it to HTTPS (`https://github.com/user/repo`). Then construct the deeplink: `https://dashboard.render.com/blueprint/new?repo=<HTTPS_REPO_URL>`
3. Present the **actual working deeplink** to the user — never show a placeholder URL. Guide user to open it, fill in `sync: false` secrets, and click **Apply**

**Do not skip the deploy URL.** The user needs this link to apply the Blueprint on Render.

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

#### Gather config vars

Use the first available source:
1. **Heroku MCP** (preferred) — config vars from `get_app_info` results (Step 1b)
2. **User-provided** — ask the user to paste output of `heroku config -a <app> --shell`
3. **`app.json`** — var names and descriptions (no values, but useful for `sync: false` entries)

#### Filter and categorize

Remove auto-generated and Heroku-specific vars (see the full filter list in the [service mapping](references/service-mapping.md)):
- `DATABASE_URL`, `REDIS_URL`, `REDIS_TLS_URL` (Render generates these)
- `HEROKU_*` vars (e.g., `HEROKU_APP_NAME`, `HEROKU_SLUG_COMMIT`)
- Add-on connection strings (`PAPERTRAIL_*`, `SENDGRID_*`, etc.)

Present filtered list to user — **do not write without confirmation**.

#### Apply vars

**Blueprint path (Step 3A):** Env vars are already embedded in the `render.yaml` on each service (non-secret values inline, secrets marked `sync: false` for the user to fill in during Blueprint apply). No separate MCP call is needed — skip to Step 5.

**MCP path (Step 3B):** Call Render `update_environment_variables` with confirmed vars (supports bulk set, merges by default).

### Step 5: Database Migration (Commands Only)

Neither MCP server supports pg_dump/pg_restore. Generate commands using connection info from both sides:

1. **Source connection string** — use the first available:
   - Heroku MCP `pg_info` (if available)
   - Ask the user to run `heroku pg:credentials:url -a <app>` and paste the result
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
