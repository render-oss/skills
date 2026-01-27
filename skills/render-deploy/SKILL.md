---
name: render-deploy
description: Deploy applications to Render by analyzing codebases, generating render.yaml Blueprints, and providing Dashboard deeplinks. Use when the user wants to deploy, host, publish, or set up their application on Render's cloud platform.
license: MIT
compatibility: Requires Render CLI and Git repository on GitHub, GitLab, or Bitbucket
metadata:
  author: Render
  version: "1.1.0"
  category: deployment
---

# Deploy to Render

Deploy applications to Render using two methods:
1. **Blueprint Method** - Generate render.yaml for Infrastructure-as-Code deployments
2. **Direct Creation** - Create services instantly via MCP tools

## When to Use This Skill

Activate this skill when users want to:
- Deploy an application to Render
- Create a render.yaml Blueprint file
- Set up Render deployment for their project
- Host or publish their application on Render's cloud platform
- Create databases, cron jobs, or other Render resources

## Choose Your Deployment Method

Both methods require your code to be pushed to GitHub, GitLab, or Bitbucket.

| Method | Best For | Pros |
|--------|----------|------|
| **Blueprint** | Multi-service apps, IaC workflows | Version controlled, reproducible, supports complex setups |
| **Direct Creation** | Single services, quick deployments | Instant creation, no render.yaml file needed |

## Prerequisites Check

When starting a deployment, verify these requirements:

**1. Check MCP Tools Availability**

MCP tools provide the best experience. Check if available by attempting:
```
list_services()
```

If MCP tools are available, you can skip CLI installation for most operations.

**2. Check Render CLI Installation (for Blueprint validation)**
```bash
render --version
```
If not installed, offer to install:
- macOS: `brew install render`
- Linux/macOS: `curl -fsSL https://raw.githubusercontent.com/render-oss/cli/main/bin/install.sh | sh`

**3. Check Authentication (try both methods)**
```bash
# Check if API key is set
echo $RENDER_API_KEY

# Check if user is logged in (use -o json for non-interactive mode)
render whoami -o json
```

If neither is configured, ask user which method they prefer:
- **API Key**: `export RENDER_API_KEY="rnd_xxxxx"` (Get from https://dashboard.render.com/settings/api-keys)
- **Login**: `render login` (Opens browser for OAuth)

**4. Verify Git Repository (for Blueprint method)**
```bash
git remote -v
```
- Must be a Git repository
- Must have a remote (GitHub, GitLab, or Bitbucket)
- Repository should be pushed to remote

**5. Check Workspace Context**

Verify the active workspace:
```
get_selected_workspace()
```

Or via CLI:
```bash
render workspace current -o json
```

To list available workspaces:
```
list_workspaces()
```

If user needs to switch workspaces, they must do so via Dashboard or CLI (`render workspace set`).

Once prerequisites are met, proceed with deployment workflow.

---

# Method 1: Blueprint Deployment (Recommended for Complex Apps)

## Blueprint Workflow

### Step 1: Analyze Codebase

Read the project files to understand the tech stack and requirements.

**Node.js Projects:**
- Read `package.json` to detect framework (Express, Next.js, Nest.js, Fastify, etc.)
- Check `scripts` section for build/start commands
- Look for `engines` field for Node version, or look in `.node-versions` or `.nvmrc`
- Detect package manager:
  - `bun.lockb` (Bun) → `bun install --frozen-lockfile` / `bun run start`
  - `pnpm-lock.yaml` (pnpm) → `pnpm install --frozen-lockfile` / `pnpm start`
  - `yarn.lock` (Yarn) → `yarn install --frozen-lockfile` / `yarn start`
  - `package-lock.json` (npm) → `npm ci` / `npm start`
  - `package.json` only (npm fallback) → `npm install` / `npm start`

**Python Projects:**
- Check for dependency files and detect package manager:
  - `uv.lock` (uv) → `uv sync` / `uv run gunicorn app:app`
  - `poetry.lock` (Poetry) → `poetry install --no-dev` / `poetry run gunicorn app:app`
  - `Pipfile.lock` (pipenv) → `pipenv install --deploy` / `pipenv run gunicorn app:app`
  - `requirements.txt` (pip) → `pip install -r requirements.txt` / `gunicorn app:app`
  - `pyproject.toml` only → check for `[tool.uv]`, `[tool.poetry]`, or use pip
- Detect framework: Django, Flask, FastAPI, Celery, others
- Check for Python version:
  - `.python-version` (uv/pyenv)
  - `runtime.txt` (Render-specific)
  - `pyproject.toml` (requires-python field)

**Go Projects:**
- Read `go.mod` for dependencies
- Identify web framework (Gin, Echo, Chi, Fiber, net/http)
- Note Go version from `go.mod`

**Static Sites:**
- Look for build output directories (`build/`, `dist/`, `site/`, `public/`)
- Detect framework: React, Vue, Gatsby, Next.js (static export)
- Check build scripts in `package.json`

**Docker Projects:**
- Look for `Dockerfile`
- Note exposed ports and build stages
- Check for `docker-compose.yml` patterns

**Key Information to Extract:**
- Build command (e.g., `npm ci`, `pip install -r requirements.txt`, `go build`)
- Start command (e.g., `npm start`, `gunicorn app:app`, `./bin/app`)
- Environment variables used in code (API keys, database URLs, secrets)
- Database requirements (PostgreSQL, Redis, MongoDB)
- Port binding (check if app uses an environment variable for port to run on)

### Step 2: Generate render.yaml

Create a `render.yaml` Blueprint file following the Blueprint specification.

Complete specification: [references/blueprint-spec.md](references/blueprint-spec.md)

**Key Points:**
- Always use `plan: free` unless user specifies otherwise
- Include ALL environment variables the app needs
- Mark secrets with `sync: false` (user fills these in Dashboard)
- Use appropriate service type: `web`, `worker`, `cron`, `static`, or `pserv`
- Use appropriate runtime: [references/runtimes.md](references/runtimes.md)

**Basic Structure:**
```yaml
services:
  - type: web
    name: my-app
    runtime: node
    plan: free
    buildCommand: npm ci
    startCommand: npm start
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: postgres
          property: connectionString
      - key: JWT_SECRET
        sync: false  # User fills in Dashboard

databases:
  - name: postgres
    databaseName: myapp_db
    plan: free
```

**Service Types:**
- `web`: HTTP services, APIs, web applications (publicly accessible)
- `worker`: Background job processors (not publicly accessible)
- `cron`: Scheduled tasks that run on a cron schedule
- `static`: Static sites (HTML/CSS/JS served via CDN)
- `pserv`: Private services (internal only, within same account)

Service type details: [references/service-types.md](references/service-types.md)
Runtime options: [references/runtimes.md](references/runtimes.md)
Template examples: [assets/](assets/)

### Step 3: Validate Configuration

Validate the render.yaml file to catch errors before deployment:

```bash
render blueprints validate
```

Fix any validation errors before proceeding. Common issues:
- Missing required fields (`name`, `type`, `runtime`)
- Invalid runtime values
- Incorrect YAML syntax
- Invalid environment variable references

Configuration guide: [references/configuration-guide.md](references/configuration-guide.md)

### Step 4: Commit and Push

**IMPORTANT:** You must merge the `render.yaml` file into your repository before deploying.

Ensure the `render.yaml` file is committed and pushed to your Git remote:

```bash
git add render.yaml
git commit -m "Add Render deployment configuration"
git push origin main
```

**Why this matters:** The Dashboard deeplink will read the render.yaml from your repository. If the file isn't merged and pushed, Render won't find the configuration and deployment will fail.

Verify the file is in your remote repository before proceeding to the next step.

### Step 5: Generate Deeplink

Get the Git repository URL:

```bash
git remote get-url origin
```

This will return a URL from your Git provider. **If the URL is SSH format, convert it to HTTPS:**

| SSH Format | HTTPS Format |
|------------|--------------|
| `git@github.com:user/repo.git` | `https://github.com/user/repo` |
| `git@gitlab.com:user/repo.git` | `https://gitlab.com/user/repo` |
| `git@bitbucket.org:user/repo.git` | `https://bitbucket.org/user/repo` |

**Conversion pattern:** Replace `git@<host>:` with `https://<host>/` and remove `.git` suffix.

Format the Dashboard deeplink using the HTTPS repository URL:
```
https://dashboard.render.com/blueprint/new?repo=<REPOSITORY_URL>
```

Example:
```
https://dashboard.render.com/blueprint/new?repo=https://github.com/username/repo-name
```

### Step 6: Guide User

**CRITICAL:** Ensure the user has merged and pushed the render.yaml file to their repository before clicking the deeplink. If the file isn't in the repository, Render cannot read the Blueprint configuration and deployment will fail.

Provide the deeplink to the user with these instructions:

1. **Verify render.yaml is merged** - Confirm the file exists in your repository on GitHub/GitLab/Bitbucket
2. Click the deeplink to open Render Dashboard
3. Complete Git provider OAuth if prompted
4. Name the Blueprint (or use default from render.yaml)
5. Fill in secret environment variables (marked with `sync: false`)
6. Review services and databases configuration
7. Click "Apply" to deploy

The deployment will begin automatically. Users can monitor progress in the Render Dashboard.

### Step 7: Verify Deployment

After the user deploys via Dashboard, verify everything is working.

**Check deployment status via MCP:**
```
list_deploys(serviceId: "<service-id>", limit: 1)
```
Look for `status: "live"` to confirm successful deployment.

**Check for runtime errors (wait 2-3 minutes after deploy):**
```
list_logs(resource: ["<service-id>"], level: ["error"], limit: 20)
```

**Check service health metrics:**
```
get_metrics(
  resourceId: "<service-id>",
  metricTypes: ["http_request_count", "cpu_usage", "memory_usage"]
)
```

If errors are found, use the **debug** skill to diagnose and fix issues.

---

# Method 2: Direct Service Creation (Quick Single-Service Deployments)

For simple deployments without Infrastructure-as-Code, create services directly via MCP tools.

## When to Use Direct Creation

- Single web service or static site
- Quick prototypes or demos
- When you don't need a render.yaml file in your repo
- Adding databases or cron jobs to existing projects

## Prerequisites for Direct Creation

**Repository must be pushed to a Git provider.** Render clones your repository to build and deploy services.

```bash
git remote -v  # Verify remote exists
git push origin main  # Ensure code is pushed
```

Supported providers: GitHub, GitLab, Bitbucket

## Direct Creation Workflow

### Step 1: Analyze Codebase

Same as Blueprint method - read project files to understand:
- Framework and runtime
- Build and start commands
- Required environment variables
- Database requirements

### Step 2: Create Resources via MCP

**Create a Web Service:**
```
create_web_service(
  name: "my-api",
  runtime: "node",  # or python, go, rust, ruby, elixir, docker
  repo: "https://github.com/username/repo",
  branch: "main",  # optional, defaults to repo default branch
  buildCommand: "npm ci",
  startCommand: "npm start",
  plan: "starter",  # starter, standard, pro, pro_max, pro_plus, pro_ultra
  region: "oregon",  # oregon, frankfurt, singapore, ohio, virginia
  envVars: [
    {"key": "NODE_ENV", "value": "production"}
  ]
)
```

**Create a Static Site:**
```
create_static_site(
  name: "my-frontend",
  repo: "https://github.com/username/repo",
  branch: "main",
  buildCommand: "npm run build",
  publishPath: "dist",  # or build, public, out
  envVars: [
    {"key": "VITE_API_URL", "value": "https://api.example.com"}
  ]
)
```

**Create a Cron Job:**
```
create_cron_job(
  name: "daily-cleanup",
  runtime: "node",
  repo: "https://github.com/username/repo",
  schedule: "0 0 * * *",  # Daily at midnight (cron syntax)
  buildCommand: "npm ci",
  startCommand: "node scripts/cleanup.js",
  plan: "starter"
)
```

**Create a PostgreSQL Database:**
```
create_postgres(
  name: "myapp-db",
  plan: "free",  # free, basic_256mb, basic_1gb, basic_4gb, pro_4gb, etc.
  region: "oregon"
)
```

**Create a Key-Value Store (Redis):**
```
create_key_value(
  name: "myapp-cache",
  plan: "free",  # free, starter, standard, pro, pro_plus
  region: "oregon",
  maxmemoryPolicy: "allkeys_lru"  # eviction policy
)
```

### Step 3: Configure Environment Variables

After creating services, add environment variables:

```
update_environment_variables(
  serviceId: "<service-id-from-creation>",
  envVars: [
    {"key": "DATABASE_URL", "value": "<connection-string>"},
    {"key": "JWT_SECRET", "value": "<secret-value>"},
    {"key": "API_KEY", "value": "<api-key>"}
  ]
)
```

**Note:** For database connection strings, get the internal URL from the database details in Dashboard or via `get_postgres(postgresId: "<id>")`.

### Step 4: Verify Deployment

Services with `autoDeploy: "yes"` (default) will deploy automatically when created.

**Check deployment status:**
```
list_deploys(serviceId: "<service-id>", limit: 1)
```

**Monitor logs for errors:**
```
list_logs(resource: ["<service-id>"], level: ["error"], limit: 50)
```

**Check health metrics:**
```
get_metrics(
  resourceId: "<service-id>",
  metricTypes: ["http_request_count", "cpu_usage", "memory_usage"]
)
```

---

# Service Discovery

Before creating new services, check what already exists.

## List Existing Resources

**List all services:**
```
list_services()
```
Returns all services with IDs, names, types, and status.

**Get specific service details:**
```
get_service(serviceId: "<id>")
```
Returns full configuration including environment variables, build/start commands.

**List PostgreSQL databases:**
```
list_postgres_instances()
```

**List Key-Value stores:**
```
list_key_value()
```

## Find Service IDs

When you need a service ID:
1. Use `list_services()` to see all services
2. Match by name or type
3. Use the `id` field for subsequent operations

---

## Important Configuration Details

### Environment Variables

**All environment variables must be declared in render.yaml.**

**Three patterns for environment variables:**

1. **Hardcoded values** (non-sensitive configuration):
```yaml
envVars:
  - key: NODE_ENV
    value: production
  - key: API_URL
    value: https://api.example.com
```

2. **Database connections** (auto-generated):
```yaml
envVars:
  - key: DATABASE_URL
    fromDatabase:
      name: postgres
      property: connectionString
  - key: REDIS_URL
    fromDatabase:
      name: redis
      property: connectionString
```

3. **Secrets** (user fills in Dashboard):
```yaml
envVars:
  - key: JWT_SECRET
    sync: false
  - key: API_KEY
    sync: false
  - key: STRIPE_SECRET_KEY
    sync: false
```

Complete environment variable guide: [references/configuration-guide.md](references/configuration-guide.md)

### Port Binding

**CRITICAL:** Web services must bind to `0.0.0.0:$PORT` (NOT `localhost`)

Render sets the `PORT` environment variable (default: `10000`). Your application must:
1. Read the `PORT` environment variable
2. Bind to `0.0.0.0` (not `127.0.0.1` or `localhost`)

**Node.js Example:**
```javascript
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
```

**Python Example:**
```python
import os

port = int(os.environ.get('PORT', 5000))
app.run(host='0.0.0.0', port=port)
```

**Go Example:**
```go
port := os.Getenv("PORT")
if port == "" {
    port = "3000"
}
http.ListenAndServe(":"+port, handler)
```

**Deployment will fail if your app doesn't bind correctly.**

### Free Tier Defaults

**Always use `plan: free` unless user specifies otherwise.**

Free tier includes:
- 1 web service
- 1 PostgreSQL database
- 750 hours/month compute
- 512 MB RAM, 0.5 CPU

Users can upgrade plans later in the Dashboard.

### Build Commands

**Use non-interactive flags to prevent build hangs:**

- **npm:** `npm ci` (NOT `npm install`)
- **yarn:** `yarn install --frozen-lockfile`
- **pnpm:** `pnpm install --frozen-lockfile`
- **bun:** `bun install --frozen-lockfile`
- **pip:** `pip install -r requirements.txt` (no prompts)
- **uv:** `uv sync` (fast Python package manager)
- **apt:** `apt-get install -y <package>` (auto-confirm)
- **bundler:** `bundle install --jobs=4 --retry=3`

Builds time out after 15 minutes on free tier.

### Database Connections

**Use internal URLs for better performance:**

When services connect to databases in the same Render account, use internal/private Render network URLs instead of external URLs. This is automatic when using `fromDatabase` references.

Example:
```yaml
envVars:
  - key: DATABASE_URL
    fromDatabase:
      name: postgres
      property: connectionString
```

This automatically provides the internal connection string.

### Health Checks

**Optional but recommended:** Add a `/health` endpoint for faster deployment detection.

**Node.js Example:**
```javascript
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});
```

Health checks help Render detect when your service is ready to receive traffic.

## Quick Reference

### MCP Tools (Preferred)

```
# Service Discovery
list_services()                              # List all services
get_service(serviceId: "<id>")               # Get service details
list_postgres_instances()                    # List databases
list_key_value()                             # List KV stores

# Service Creation
create_web_service(name, runtime, buildCommand, startCommand, ...)
create_static_site(name, buildCommand, publishPath, ...)
create_cron_job(name, runtime, schedule, buildCommand, startCommand, ...)
create_postgres(name, plan, region)
create_key_value(name, plan, region)

# Environment Variables
update_environment_variables(serviceId, envVars: [{key, value}, ...])

# Deployment & Monitoring
list_deploys(serviceId, limit)               # Check deploy status
list_logs(resource: ["<id>"], level: ["error"])  # View logs
get_metrics(resourceId, metricTypes: [...])  # Get metrics

# Workspace
get_selected_workspace()                     # Current workspace
list_workspaces()                            # All workspaces
```

### CLI Commands

```bash
# Validate Blueprint
render blueprints validate

# Check workspace
render workspace current -o json
render workspace set

# List services
render services -o json

# View deployment logs
render logs -r <service-id> -o json

# Create deployment
render deploys create <service-id> --wait
```

### Templates by Framework

- **Node.js Express:** [assets/node-express.yaml](assets/node-express.yaml)
- **Next.js + Postgres:** [assets/nextjs-postgres.yaml](assets/nextjs-postgres.yaml)
- **Django + Worker:** [assets/python-django.yaml](assets/python-django.yaml)
- **Static Site:** [assets/static-site.yaml](assets/static-site.yaml)
- **Go API:** [assets/go-api.yaml](assets/go-api.yaml)
- **Docker:** [assets/docker.yaml](assets/docker.yaml)

### Documentation

- **Full Blueprint specification:** [references/blueprint-spec.md](references/blueprint-spec.md)
- **Service types explained:** [references/service-types.md](references/service-types.md)
- **Runtime options:** [references/runtimes.md](references/runtimes.md)
- **Configuration guide:** [references/configuration-guide.md](references/configuration-guide.md)

## Common Issues

**Issue:** Deployment fails with port binding error

**Solution:** Ensure app binds to `0.0.0.0:$PORT` (see Port Binding section above)

---

**Issue:** Build hangs or times out

**Solution:** Use non-interactive build commands (see Build Commands section above)

---

**Issue:** Missing environment variables in Dashboard

**Solution:** All env vars must be declared in render.yaml. Add missing vars with `sync: false` for secrets.

---

**Issue:** Database connection fails

**Solution:** Use `fromDatabase` references for automatic internal connection strings.

---

**Issue:** Static site shows 404 for routes

**Solution:** Add rewrite rules to render.yaml for SPA routing:
```yaml
routes:
  - type: rewrite
    source: /*
    destination: /index.html
```

For more detailed troubleshooting, see the **debug** skill or [references/configuration-guide.md](references/configuration-guide.md).
