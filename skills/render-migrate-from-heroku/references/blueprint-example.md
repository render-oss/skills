# Blueprint Example: Heroku Migration with Project/Environment Pattern

This example shows a complete `render.yaml` for migrating a typical Heroku app with a web dyno, worker dyno, Heroku Scheduler (clock), Postgres, and Redis. It uses the `projects`/`environments` pattern to group all resources in a single Render project.

Reference: [Blueprint YAML specification](https://render.com/docs/blueprint-spec#projects-and-environments)

## Full Example

Assumes a Node.js app named `acme-app` migrating from Heroku US region.

```yaml
projects:
  - name: acme-app
    environments:
      - name: production
        services:
          # Web service (from Heroku web dyno)
          - type: web
            name: acme-app-web
            runtime: node
            plan: starter
            region: oregon
            buildCommand: npm ci && npm run build
            startCommand: npm start
            healthCheckPath: /health
            envVars:
              - key: NODE_ENV
                value: production
              - key: DATABASE_URL
                fromDatabase:
                  name: acme-app-db
                  property: connectionString
              - key: REDIS_URL
                fromService:
                  type: keyvalue
                  name: acme-app-cache
                  property: connectionString
              - fromGroup: acme-app-env

          # Background worker (from Heroku worker dyno)
          - type: worker
            name: acme-app-worker
            runtime: node
            plan: starter
            region: oregon
            buildCommand: npm ci
            startCommand: node worker.js
            envVars:
              - key: DATABASE_URL
                fromDatabase:
                  name: acme-app-db
                  property: connectionString
              - key: REDIS_URL
                fromService:
                  type: keyvalue
                  name: acme-app-cache
                  property: connectionString
              - fromGroup: acme-app-env

          # Cron job (from Heroku Scheduler or clock dyno)
          - type: cron
            name: acme-app-cron
            runtime: node
            plan: starter
            region: oregon
            schedule: "0 * * * *"
            buildCommand: npm ci
            startCommand: node scripts/scheduled-task.js
            envVars:
              - key: DATABASE_URL
                fromDatabase:
                  name: acme-app-db
                  property: connectionString
              - fromGroup: acme-app-env

          # Key Value (from Heroku Data for Redis)
          - type: keyvalue
            name: acme-app-cache
            plan: starter
            ipAllowList:
              - source: 0.0.0.0/0
                description: everywhere

        databases:
          # Postgres (from Heroku Postgres)
          - name: acme-app-db
            plan: basic-1gb

        envVarGroups:
          # Shared config vars migrated from Heroku
          - name: acme-app-env
            envVars:
              # Non-secret config vars (hardcoded values)
              - key: APP_NAME
                value: acme-app
              - key: LOG_LEVEL
                value: info
              # Secrets — user fills these in the Dashboard
              - key: STRIPE_API_KEY
                sync: false
              - key: JWT_SECRET
                sync: false
              - key: SENDGRID_API_KEY
                sync: false
```

## Key Patterns

### Service references

Use `fromDatabase` and `fromService` instead of hardcoding connection strings:

```yaml
# Postgres connection string
- key: DATABASE_URL
  fromDatabase:
    name: acme-app-db
    property: connectionString

# Key Value (Redis) connection string
- key: REDIS_URL
  fromService:
    type: keyvalue
    name: acme-app-cache
    property: connectionString
```

### Shared environment variables

Use `envVarGroups` to avoid duplicating config vars across services:

```yaml
# Define the group once
envVarGroups:
  - name: acme-app-env
    envVars:
      - key: LOG_LEVEL
        value: info
      - key: API_KEY
        sync: false

# Reference in each service
envVars:
  - fromGroup: acme-app-env
```

### Secrets

Mark secrets with `sync: false` so the user is prompted in the Dashboard:

```yaml
- key: STRIPE_API_KEY
  sync: false
```

Render prompts for these values only during the initial Blueprint apply. For updates after initial creation, set secrets manually in the Dashboard or via MCP `update_environment_variables`.

## Plan Defaults

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

## Adapting This Example

- **Python app:** Change `runtime: node` to `runtime: python`, update build/start commands (e.g., `pip install -r requirements.txt`, `gunicorn app:app`)
- **Ruby app:** Change to `runtime: ruby`, update commands (e.g., `bundle install`, `bundle exec puma`)
- **No worker:** Remove the `type: worker` service block
- **No cron:** Remove the `type: cron` service block
- **No Redis:** Remove the `type: keyvalue` service block and any `REDIS_URL` env var references
- **No Postgres:** Remove the `databases` section and any `DATABASE_URL` env var references
- **Static site:** Replace `type: web` with `runtime: static` and add `staticPublishPath`
- **EU region:** Change `region: oregon` to `region: frankfurt` (maps from Heroku `eu` region)
