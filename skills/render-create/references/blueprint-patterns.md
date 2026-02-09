# Blueprint patterns reference

This document describes `render.yaml` patterns for every service type, plus validation and adaptation guidance.

All examples use `{{PROJECT_NAME}}` as a placeholder—replace it with the actual project name.

## Validation

Always validate the generated `render.yaml` if the Render CLI is installed:

```bash
render blueprint validate --path render.yaml
```

- If the command succeeds, the Blueprint is valid.
- If it fails, read the error output carefully. Common issues:
  - Missing required fields (`name`, `type`, `runtime`)
  - Invalid `type` values (must be `web`, `worker`, `cron`, `redis`)
  - Invalid `runtime` values (must be `node`, `python`, `go`, `rust`, `ruby`, `docker`, `elixir`, `static`, `image`)
  - YAML syntax errors (indentation, missing colons)
- Fix the issues and re-run validation until it passes.
- If the Render CLI isn't installed, skip validation. The templates in `templates/render-yaml/` are known-good patterns.

## Schema reference

The full render.yaml JSON Schema is hosted at:

```
https://render.com/schema/render.yaml.json
```

Use this as the source of truth for field names, types, and allowed values.

---

## Service patterns

### Next.js web service (SSR)

```yaml
services:
  - type: web
    runtime: node
    name: {{PROJECT_NAME}}
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: npm install && npm run build
    startCommand: npm start
    healthCheckPath: /
    envVars:
      - key: NODE_ENV
        value: production
      - key: DATABASE_URL
        fromDatabase:
          name: {{PROJECT_NAME}}-db
          property: connectionString
```

### Next.js static site

```yaml
services:
  - type: web
    runtime: static
    name: {{PROJECT_NAME}}
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: npm install && npm run build
    staticPublishPath: out
    envVars:
      - key: NODE_ENV
        value: production
    routes:
      - type: rewrite
        source: /*
        destination: /index.html
```

### Vite static site

```yaml
services:
  - type: web
    runtime: static
    name: {{PROJECT_NAME}}
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: npm install && npm run build
    staticPublishPath: dist
    envVars:
      - key: NODE_ENV
        value: production
    routes:
      - type: rewrite
        source: /*
        destination: /index.html
```

### Node.js web service (Fastify, Express, etc.)

```yaml
services:
  - type: web
    runtime: node
    name: {{PROJECT_NAME}}
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: npm install && npm run build
    startCommand: npm run start
    healthCheckPath: /health
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: "10000"
      - key: HOST
        value: 0.0.0.0
```

### Python web service (FastAPI, Flask, etc.)

```yaml
services:
  - type: web
    runtime: python
    name: {{PROJECT_NAME}}
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn main:app --host 0.0.0.0 --port $PORT
    healthCheckPath: /health
    envVars:
      - key: PYTHON_VERSION
        value: "3.13"
```

### Django web service (gunicorn)

```yaml
services:
  - type: web
    runtime: python
    name: {{PROJECT_NAME}}
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: pip install -r requirements.txt && python manage.py collectstatic --noinput && python manage.py migrate
    startCommand: gunicorn project.wsgi:application --bind 0.0.0.0:$PORT
    healthCheckPath: /health
    envVars:
      - key: PYTHON_VERSION
        value: "3.13"
      - key: SECRET_KEY
        generateValue: true
```

### Remix web service (SSR)

```yaml
services:
  - type: web
    runtime: node
    name: {{PROJECT_NAME}}
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: npm install && npm run build
    startCommand: npm start
    healthCheckPath: /api/health
    envVars:
      - key: NODE_ENV
        value: production
```

### Astro static site

```yaml
services:
  - type: web
    runtime: static
    name: {{PROJECT_NAME}}
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: npm install && npm run build
    staticPublishPath: dist
    envVars:
      - key: NODE_ENV
        value: production
    routes:
      - type: rewrite
        source: /*
        destination: /index.html
```

### SvelteKit web service (adapter-node)

```yaml
services:
  - type: web
    runtime: node
    name: {{PROJECT_NAME}}
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: npm install && npm run build
    startCommand: node build
    healthCheckPath: /api/health
    envVars:
      - key: NODE_ENV
        value: production
```

### Background worker (Node.js)

```yaml
services:
  - type: worker
    runtime: node
    name: {{PROJECT_NAME}}-worker
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: npm install && npm run build
    startCommand: npm run start
    envVars:
      - key: NODE_ENV
        value: production
```

### Background worker (Python)

```yaml
services:
  - type: worker
    runtime: python
    name: {{PROJECT_NAME}}-worker
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: pip install -r requirements.txt
    startCommand: python worker.py
    envVars:
      - key: PYTHON_VERSION
        value: "3.13"
```

### Cron job (Node.js)

```yaml
services:
  - type: cron
    runtime: node
    name: {{PROJECT_NAME}}-cron
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: npm install && npm run build
    startCommand: npm run start
    schedule: "0 * * * *"
    envVars:
      - key: NODE_ENV
        value: production
```

### Cron job (Python)

```yaml
services:
  - type: cron
    runtime: python
    name: {{PROJECT_NAME}}-cron
    repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
    plan: free
    buildCommand: pip install -r requirements.txt
    startCommand: python cron.py
    schedule: "0 * * * *"
    envVars:
      - key: PYTHON_VERSION
        value: "3.13"
```

---

## Database and cache patterns

### PostgreSQL

```yaml
databases:
  - name: {{PROJECT_NAME}}-db
    plan: free
```

To connect a service to the database, add to the service's `envVars`:

```yaml
      - key: DATABASE_URL
        fromDatabase:
          name: {{PROJECT_NAME}}-db
          property: connectionString
```

### Redis (KeyVal)

```yaml
services:
  - type: redis
    name: {{PROJECT_NAME}}-cache
    plan: free
    maxmemoryPolicy: allkeys-lru
    ipAllowList: []
```

To connect a service to Redis, add to the service's `envVars`:

```yaml
      - key: REDIS_URL
        fromService:
          name: {{PROJECT_NAME}}-cache
          type: redis
          property: connectionString
```

---

## Multi-service patterns

When combining multiple services in one Blueprint, use the `projects`/`environments` structure to group services, databases, and caches under a single project. Use `rootDir` to point each service to its subdirectory.

```yaml
projects:
  - name: {{PROJECT_NAME}}
    environments:
      - name: production
        services:
          - type: web
            runtime: node
            name: {{PROJECT_NAME}}-node-api
            repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
            rootDir: node-api
            plan: free
            buildCommand: npm install && npm run build
            startCommand: npm run start
            healthCheckPath: /health
            envVars:
              - key: NODE_ENV
                value: production
              - key: DATABASE_URL
                fromDatabase:
                  name: {{PROJECT_NAME}}-db
                  property: connectionString

          - type: web
            runtime: python
            name: {{PROJECT_NAME}}-python-api
            repo: https://github.com/YOUR_ORG/{{PROJECT_NAME}}
            rootDir: python-api
            plan: free
            buildCommand: pip install -r requirements.txt
            startCommand: uvicorn main:app --host 0.0.0.0 --port $PORT
            healthCheckPath: /health
            envVars:
              - key: PYTHON_VERSION
                value: "3.13"
              - key: DATABASE_URL
                fromDatabase:
                  name: {{PROJECT_NAME}}-db
                  property: connectionString

        databases:
          - name: {{PROJECT_NAME}}-db
            plan: free
```

Key rules for multi-service Blueprints:

- Use `projects` → `environments` to group all resources under one project
- Each service must have a unique `name`
- Use `rootDir` when services live in subdirectories
- All services share the same `repo` URL
- `databases` and Key Value instances go inside the same environment as the services that reference them
- Any service in the environment can reference shared resources (e.g., `{{PROJECT_NAME}}-db`)
- Single-service Blueprints can use the flat root-level `services`/`databases` structure — switch to `projects`/`environments` when adding a second service

---

## Merging into an existing render.yaml

When adding a component to an existing project (add mode), merge the new service into the existing `render.yaml` instead of overwriting it.

### Steps

1. **Read the existing `render.yaml`** and note what's already defined: services, databases, caches, and whether it uses `projects`/`environments` or the flat structure.
2. **Convert to `projects`/`environments`** if the existing file uses the flat `services`/`databases` structure. When adding a second service, the Blueprint should use the `projects`/`environments` structure (see example below).
3. **Find the matching pattern** above for the new component (e.g., "Fastify web service" or "Background worker").
4. **Append the new service** to the environment's `services` array. Give it a unique name by appending a suffix (e.g., `{{PROJECT_NAME}}-python-api`, `{{PROJECT_NAME}}-worker`).
5. **Add `rootDir`** to the new service entry pointing to its subdirectory (e.g., `rootDir: python-api`). Also add `rootDir` to the existing service if it didn't have one before.
6. **Reuse existing resources:**
   - If the environment already has a `databases` section and the new service needs a database, reference the existing database name in the new service's `DATABASE_URL` env var (use `fromDatabase` with the existing database name). Do not create a duplicate.
   - Same for Key Value — if a `keyvalue` service already exists, reference it instead of adding another.
7. **Add new resources** only if they don't already exist. For example, if the new service needs PostgreSQL and there is no `databases` section, add one inside the environment.
8. **Validate** the merged result:

```bash
render blueprint validate --path render.yaml
```

### Example: adding a Python API to a project that already has a Next.js frontend and database

Before (existing flat structure):

```yaml
services:
  - type: web
    runtime: node
    name: my-app
    repo: https://github.com/YOUR_ORG/my-app
    plan: free
    buildCommand: npm install && npm run build
    startCommand: npm start
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: my-app-db
          property: connectionString

databases:
  - name: my-app-db
    plan: free
```

After (converted to `projects`/`environments` and merged):

```yaml
projects:
  - name: my-app
    environments:
      - name: production
        services:
          - type: web
            runtime: node
            name: my-app
            repo: https://github.com/YOUR_ORG/my-app
            rootDir: frontend
            plan: free
            buildCommand: npm install && npm run build
            startCommand: npm start
            envVars:
              - key: DATABASE_URL
                fromDatabase:
                  name: my-app-db
                  property: connectionString

          - type: web
            runtime: python
            name: my-app-python-api
            repo: https://github.com/YOUR_ORG/my-app
            rootDir: python-api
            plan: free
            buildCommand: pip install -r requirements.txt
            startCommand: uvicorn main:app --host 0.0.0.0 --port $PORT
            envVars:
              - key: DATABASE_URL
                fromDatabase:
                  name: my-app-db
                  property: connectionString
              - key: PYTHON_VERSION
                value: "3.13"

        databases:
          - name: my-app-db
            plan: free
```

Key points:

- The flat `services`/`databases` structure is converted to `projects`/`environments` when adding a second service.
- The existing service gets `rootDir` added (it didn't need one when it was the only service).
- `databases` moves inside the environment alongside the services.
- The existing database is reused — no duplicate entry. Both services reference the same `my-app-db`.
- Each service has a unique `name`.

---

## Adaptation guidance

When the user's project doesn't exactly match a template:

1. **Start from the closest matching template** in `templates/render-yaml/`
2. **Add or remove services** as needed
3. **Adjust environment variables** for the user's specific setup
4. **Change build/start commands** if the project uses different tooling
5. **Add `rootDir`** if the service lives in a subdirectory of a monorepo
6. **Always validate** the result with `render blueprint validate`

Common adaptations:

| Change | What to modify |
|--------|---------------|
| Add database | Add `databases` section + `DATABASE_URL` env var |
| Add Redis | Add redis service + `REDIS_URL` env var |
| Change port | Update `PORT` env var value |
| Monorepo | Add `rootDir` to each service |
| Multi-service | Convert to `projects`/`environments` structure |
| Custom domain | Add `domains` array to the service |
| Auto-deploy off | Add `autoDeploy: false` to the service |
| Different plan | Change `plan` from `free` to `starter`, `standard`, etc. |
