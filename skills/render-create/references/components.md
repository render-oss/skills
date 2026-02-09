# Components reference

Components are individual building blocks that can be composed together to create a custom project. Each section below describes how to scaffold one component.

## New project (composable mode)

1. Create the project root directory: `mkdir {{PROJECT_NAME}} && cd {{PROJECT_NAME}}`
2. Initialize git at the root: `git init`
3. For each selected component, follow the instructions below. Each component creates its own subdirectory within the project.
4. After all components are scaffolded, generate a combined `render.yaml` at the project root (see `references/blueprint-patterns.md`).
5. Copy Cursor rules to `.cursor/rules/` at the root (merge rules from all components, always include `general`).
6. Final commit: `git add -A && git commit -m "Initial commit"`

Replace `{{PROJECT_NAME}}` with the actual project name in all files.

## Adding to an existing project

When the agent is in **add mode** (detected an existing project), follow these modified steps:

1. **Stay in the project root.** Do not create a new root directory or run `git init`.
2. **Derive the project name** from the existing `render.yaml` (use the first service name, stripping suffixes like `-api`, `-web`, `-worker`) or fall back to the current directory name.
3. **Scaffold the component** into a subdirectory by following the per-component instructions below, just like composable mode. Skip only the root-level `mkdir` and `git init`.
4. **Cursor rules** — before copying a rule file to `.cursor/rules/`, check if it already exists. Only copy rules that are missing.
5. **Merge into `render.yaml`** — do not overwrite the existing file. Follow the "Merging into an existing render.yaml" section in [references/blueprint-patterns.md](blueprint-patterns.md) to append the new service.
6. **Commit:** `git add -A && git commit -m "Add <component-name>"`

---

## Frontends

### nextjs

**Subdirectory:** `frontend/`

#### Steps

1. Run the create command from the project root:

```bash
npx create-next-app@latest frontend --yes --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --turbopack
```

2. Install additional dev dependencies:

```bash
cd frontend
npm install -D @biomejs/biome @tailwindcss/typography
```

3. Copy template files:

| Source (in templates/) | Destination (in frontend/) |
|------------------------|---------------------------|
| `styles/globals.css` | `src/app/globals.css` |
| `next/layout.tsx` | `src/app/layout.tsx` |
| `next/page.tsx` | `src/app/page.tsx` |
| `assets/favicon.png` | `src/app/icon.png` |

4. Delete replaced files:

```bash
rm -f src/app/favicon.ico
```

5. Copy configs:

| Source (in templates/) | Destination (in frontend/) |
|------------------------|---------------------------|
| `configs/biome.json` | `biome.json` |

6. Return to project root: `cd ..`

**Cursor rules:** `typescript`, `nextjs`, `tailwind`, `react`

**Supports web service mode:** Yes. If deploying as a web service (SSR) instead of static, skip the static config. If deploying as static, also copy `templates/next/next.config.static.ts` to `frontend/next.config.ts`.

**Blueprint:** See `blueprint-patterns.md` — "Next.js static site" or "Next.js web service" pattern.

---

### vite

**Subdirectory:** `frontend/`

#### Steps

1. Run the create command from the project root:

```bash
npm create vite@latest frontend -- --template react-ts
```

2. Install dependencies:

```bash
cd frontend
npm install
npm install -D tailwindcss @tailwindcss/vite @tailwindcss/typography @biomejs/biome
```

3. Copy template files:

| Source (in templates/) | Destination (in frontend/) |
|------------------------|---------------------------|
| `vite/vite.config.ts` | `vite.config.ts` |
| `styles/globals.css` | `src/index.css` |
| `assets/favicon.svg` | `public/favicon.svg` |

4. Copy configs:

| Source (in templates/) | Destination (in frontend/) |
|------------------------|---------------------------|
| `configs/biome.json` | `biome.json` |

5. Return to project root: `cd ..`

**Cursor rules:** `typescript`, `vite`, `tailwind`, `react`

**Blueprint:** See `blueprint-patterns.md` — "Vite static site" pattern.

### remix

**Subdirectory:** `frontend/`

#### Steps

1. Run the create command from the project root:

```bash
npx create-react-router@latest frontend --yes
```

2. Install additional dependencies:

```bash
cd frontend
npm install -D @biomejs/biome tailwindcss @tailwindcss/vite @tailwindcss/typography
```

3. Copy template files:

| Source (in templates/) | Destination (in frontend/) |
|------------------------|---------------------------|
| `remix/root.tsx` | `app/root.tsx` |
| `remix/home.tsx` | `app/routes/home.tsx` |
| `styles/globals.css` | `app/app.css` |

4. Copy configs:

| Source (in templates/) | Destination (in frontend/) |
|------------------------|---------------------------|
| `configs/biome.json` | `biome.json` |

5. Return to project root: `cd ..`

**Cursor rules:** `typescript`, `remix`, `tailwind`, `react`

**Blueprint:** See `blueprint-patterns.md` — "Remix web service" pattern.

---

### astro

**Subdirectory:** `frontend/`

#### Steps

1. Run the create command from the project root:

```bash
npm create astro@latest frontend -- --template minimal --yes
```

2. Install additional dev dependencies:

```bash
cd frontend
npm install -D @biomejs/biome
```

3. Copy template files:

| Source (in templates/) | Destination (in frontend/) |
|------------------------|---------------------------|
| `styles/globals.css` | `src/styles/globals.css` |
| `astro/index.astro` | `src/pages/index.astro` |

4. Copy configs:

| Source (in templates/) | Destination (in frontend/) |
|------------------------|---------------------------|
| `configs/biome.json` | `biome.json` |

5. Return to project root: `cd ..`

**Cursor rules:** `typescript`, `astro`

**Blueprint:** See `blueprint-patterns.md` — "Astro static site" pattern.

---

### sveltekit

**Subdirectory:** `frontend/`

#### Steps

1. Run the create command from the project root:

```bash
npx sv create frontend --template minimal --types ts
```

2. Install dependencies:

```bash
cd frontend
npm install
npm install @sveltejs/adapter-node
npm install -D @biomejs/biome tailwindcss @tailwindcss/vite @tailwindcss/typography
```

3. Update `svelte.config.js` to use adapter-node:

```javascript
import adapter from "@sveltejs/adapter-node";
import { vitePreprocess } from "@sveltejs/vite-plugin-svelte";

export default {
  preprocess: vitePreprocess(),
  kit: {
    adapter: adapter(),
  },
};
```

4. Copy template files:

| Source (in templates/) | Destination (in frontend/) |
|------------------------|---------------------------|
| `sveltekit/+layout.svelte` | `src/routes/+layout.svelte` |
| `sveltekit/+page.svelte` | `src/routes/+page.svelte` |
| `styles/globals.css` | `src/app.css` |

5. Copy configs:

| Source (in templates/) | Destination (in frontend/) |
|------------------------|---------------------------|
| `configs/biome.json` | `biome.json` |

6. Return to project root: `cd ..`

**Cursor rules:** `typescript`, `svelte`, `tailwind`

**Blueprint:** See `blueprint-patterns.md` — "SvelteKit web service" pattern.

---

## APIs

### fastify

**Subdirectory:** `node-api/`

#### Steps (without database)

1. Create the subdirectory:

```bash
mkdir -p node-api && cd node-api
```

2. Create `package.json`:

```json
{
  "name": "{{PROJECT_NAME}}-node-api",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "biome check .",
    "format": "biome check --write ."
  }
}
```

3. Install dependencies:

```bash
npm install fastify @fastify/cors @fastify/env zod
npm install -D typescript @types/node tsx @biomejs/biome
```

4. Copy template files:

| Source (in templates/) | Destination (in node-api/) |
|------------------------|---------------------------|
| `fastify/index-simple.ts` | `src/index.ts` |

5. Copy configs:

| Source (in templates/) | Destination (in node-api/) |
|------------------------|---------------------------|
| `configs/biome.json` | `biome.json` |
| `configs/tsconfig.base.json` | `tsconfig.json` |

   Add `"outDir": "dist"` and `"rootDir": "src"` to `compilerOptions`, and add `"include": ["src"]` to the tsconfig.

6. Return to project root: `cd ..`

#### Steps (with database — when composed with `postgres`)

Follow the same steps, but with these changes:

- In step 2, add these additional scripts to `package.json`:

```json
{
  "db:generate": "drizzle-kit generate",
  "db:migrate": "drizzle-kit migrate",
  "db:studio": "drizzle-kit studio"
}
```

- In step 3, add these dependencies:

```bash
npm install drizzle-orm postgres
npm install -D drizzle-kit
```

- In step 4, copy these files instead:

| Source (in templates/) | Destination (in node-api/) |
|------------------------|---------------------------|
| `fastify/index.ts` | `src/index.ts` |
| `drizzle/db-index.ts` | `src/db/index.ts` |
| `drizzle/schema.ts` | `src/db/schema.ts` |
| `drizzle/drizzle.config.ts` | `drizzle.config.ts` |

**Cursor rules:** `typescript`, `fastify` (add `drizzle` if using database)

**Blueprint:** See `blueprint-patterns.md` — "Node.js web service" pattern.

---

### fastapi

**Subdirectory:** `python-api/`

#### Steps (without database)

1. Create the subdirectory:

```bash
mkdir -p python-api && cd python-api
```

2. Create `requirements.txt`:

```
fastapi
uvicorn[standard]
pydantic
python-dotenv
```

3. Set up virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

4. Copy template files:

| Source (in templates/) | Destination (in python-api/) |
|------------------------|------------------------------|
| `fastapi/main-simple.py` | `main.py` |

5. Copy configs:

| Source (in templates/) | Destination (in python-api/) |
|------------------------|------------------------------|
| `configs/ruff.toml` | `ruff.toml` |

6. Deactivate and return: `deactivate && cd ..`

#### Steps (with database — when composed with `postgres`)

Follow the same steps, but:

- In step 2, use this `requirements.txt`:

```
fastapi
uvicorn[standard]
sqlalchemy
psycopg2-binary
pydantic
pydantic-settings
python-dotenv
alembic
```

- In step 4, copy these files instead:

| Source (in templates/) | Destination (in python-api/) |
|------------------------|------------------------------|
| `fastapi/main.py` | `main.py` |
| `fastapi/app/__init__.py` | `app/__init__.py` |
| `fastapi/app/config.py` | `app/config.py` |
| `fastapi/app/database.py` | `app/database.py` |
| `fastapi/app/models.py` | `app/models.py` |

**Cursor rules:** `python` (add `sqlalchemy` if using database)

**Blueprint:** See `blueprint-patterns.md` — "Python web service" pattern.

---

### express

**Subdirectory:** `node-api/`

#### Steps (without database)

1. Create the subdirectory:

```bash
mkdir -p node-api && cd node-api
```

2. Create `package.json`:

```json
{
  "name": "{{PROJECT_NAME}}-node-api",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "biome check .",
    "format": "biome check --write ."
  }
}
```

3. Install dependencies:

```bash
npm install express cors zod
npm install -D typescript @types/node @types/express tsx @biomejs/biome
```

4. Copy template files:

| Source (in templates/) | Destination (in node-api/) |
|------------------------|---------------------------|
| `express/index-simple.ts` | `src/index.ts` |

5. Copy configs:

| Source (in templates/) | Destination (in node-api/) |
|------------------------|---------------------------|
| `configs/biome.json` | `biome.json` |
| `configs/tsconfig.base.json` | `tsconfig.json` |

   Add `"outDir": "dist"` and `"rootDir": "src"` to `compilerOptions`, and add `"include": ["src"]`.

6. Return to project root: `cd ..`

#### Steps (with database — when composed with `postgres`)

Follow the same steps, but:

- In step 2, add DB scripts to `package.json`
- In step 3, add: `npm install drizzle-orm postgres` and `npm install -D drizzle-kit`
- In step 4, copy these files instead:

| Source (in templates/) | Destination (in node-api/) |
|------------------------|---------------------------|
| `express/index.ts` | `src/index.ts` |
| `drizzle/db-index.ts` | `src/db/index.ts` |
| `drizzle/schema.ts` | `src/db/schema.ts` |
| `drizzle/drizzle.config.ts` | `drizzle.config.ts` |

**Cursor rules:** `typescript`, `express` (add `drizzle` if using database)

**Blueprint:** See `blueprint-patterns.md` — "Node.js web service" pattern.

---

### hono

**Subdirectory:** `node-api/`

#### Steps (without database)

1. Create the subdirectory:

```bash
mkdir -p node-api && cd node-api
```

2. Create `package.json`:

```json
{
  "name": "{{PROJECT_NAME}}-node-api",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "biome check .",
    "format": "biome check --write ."
  }
}
```

3. Install dependencies:

```bash
npm install hono @hono/node-server zod
npm install -D typescript @types/node tsx @biomejs/biome
```

4. Copy template files:

| Source (in templates/) | Destination (in node-api/) |
|------------------------|---------------------------|
| `hono/index-simple.ts` | `src/index.ts` |

5. Copy configs:

| Source (in templates/) | Destination (in node-api/) |
|------------------------|---------------------------|
| `configs/biome.json` | `biome.json` |
| `configs/tsconfig.base.json` | `tsconfig.json` |

   Add `"outDir": "dist"` and `"rootDir": "src"` to `compilerOptions`, and add `"include": ["src"]`.

6. Return to project root: `cd ..`

#### Steps (with database — when composed with `postgres`)

Follow the same steps, but:

- In step 2, add DB scripts to `package.json`
- In step 3, add: `npm install drizzle-orm postgres` and `npm install -D drizzle-kit`
- In step 4, copy these files instead:

| Source (in templates/) | Destination (in node-api/) |
|------------------------|---------------------------|
| `hono/index.ts` | `src/index.ts` |
| `drizzle/db-index.ts` | `src/db/index.ts` |
| `drizzle/schema.ts` | `src/db/schema.ts` |
| `drizzle/drizzle.config.ts` | `drizzle.config.ts` |

**Cursor rules:** `typescript`, `hono` (add `drizzle` if using database)

**Blueprint:** See `blueprint-patterns.md` — "Node.js web service" pattern.

---

### django

**Subdirectory:** `python-api/`

#### Steps

1. Create the subdirectory:

```bash
mkdir -p python-api && cd python-api
```

2. Create `requirements.txt`:

```
django
gunicorn
psycopg2-binary
django-environ
whitenoise
```

3. Set up virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

4. Copy template files:

| Source (in templates/) | Destination (in python-api/) |
|------------------------|------------------------------|
| `django/manage.py` | `manage.py` |
| `django/project/__init__.py` | `project/__init__.py` |
| `django/project/settings.py` | `project/settings.py` |
| `django/project/urls.py` | `project/urls.py` |
| `django/project/wsgi.py` | `project/wsgi.py` |
| `django/app/__init__.py` | `app/__init__.py` |
| `django/app/views.py` | `app/views.py` |
| `django/app/models.py` | `app/models.py` |

5. Run initial migrations:

```bash
python manage.py migrate
```

6. Copy configs:

| Source (in templates/) | Destination (in python-api/) |
|------------------------|------------------------------|
| `configs/ruff.toml` | `ruff.toml` |

7. Return: `deactivate && cd ..`

**Cursor rules:** `python`, `django`

**Blueprint:** See `blueprint-patterns.md` — "Django web service" pattern.

---

## Workers

### worker-ts

**Subdirectory:** `worker/`

#### Steps

1. Create the subdirectory:

```bash
mkdir -p worker && cd worker
```

2. Create `package.json`:

```json
{
  "name": "{{PROJECT_NAME}}-worker",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/worker.ts",
    "build": "tsc",
    "start": "node dist/worker.js",
    "lint": "biome check .",
    "format": "biome check --write ."
  }
}
```

3. Install dependencies:

```bash
npm install -D typescript @types/node tsx @biomejs/biome
```

4. Copy template files:

| Source (in templates/) | Destination (in worker/) |
|------------------------|--------------------------|
| `background-tasks/ts/worker.ts` | `src/worker.ts` |

5. Copy configs:

| Source (in templates/) | Destination (in worker/) |
|------------------------|--------------------------|
| `configs/biome.json` | `biome.json` |
| `configs/tsconfig.base.json` | `tsconfig.json` |

   Add `"outDir": "dist"` and `"rootDir": "src"` to `compilerOptions`, and add `"include": ["src"]`.

6. Return to project root: `cd ..`

**Cursor rules:** `typescript`

**Blueprint:** See `blueprint-patterns.md` — "Background worker" pattern.

---

### worker-py

**Subdirectory:** `worker/`

#### Steps

1. Create the subdirectory:

```bash
mkdir -p worker && cd worker
```

2. Create `requirements.txt`:

```
python-dotenv
```

3. Set up virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

4. Copy template files:

| Source (in templates/) | Destination (in worker/) |
|------------------------|--------------------------|
| `background-tasks/py/worker.py` | `worker.py` |

5. Copy configs:

| Source (in templates/) | Destination (in worker/) |
|------------------------|--------------------------|
| `configs/ruff.toml` | `ruff.toml` |

6. Return: `deactivate && cd ..`

**Cursor rules:** `python`

**Blueprint:** See `blueprint-patterns.md` — "Background worker (Python)" pattern.

---

### cron-ts

**Subdirectory:** `cron/`

#### Steps

1. Create the subdirectory:

```bash
mkdir -p cron && cd cron
```

2. Create `package.json`:

```json
{
  "name": "{{PROJECT_NAME}}-cron",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx src/cron.ts",
    "build": "tsc",
    "start": "node dist/cron.js",
    "lint": "biome check .",
    "format": "biome check --write ."
  }
}
```

3. Install dependencies:

```bash
npm install -D typescript @types/node tsx @biomejs/biome
```

4. Copy template files:

| Source (in templates/) | Destination (in cron/) |
|------------------------|------------------------|
| `background-tasks/ts/cron.ts` | `src/cron.ts` |

5. Copy configs:

| Source (in templates/) | Destination (in cron/) |
|------------------------|------------------------|
| `configs/biome.json` | `biome.json` |
| `configs/tsconfig.base.json` | `tsconfig.json` |

   Add `"outDir": "dist"` and `"rootDir": "src"` to `compilerOptions`, and add `"include": ["src"]`.

6. Return to project root: `cd ..`

**Cursor rules:** `typescript`

**Blueprint:** See `blueprint-patterns.md` — "Cron job" pattern.

---

### cron-py

**Subdirectory:** `cron/`

#### Steps

1. Create the subdirectory:

```bash
mkdir -p cron && cd cron
```

2. Create `requirements.txt`:

```
python-dotenv
```

3. Set up virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

4. Copy template files:

| Source (in templates/) | Destination (in cron/) |
|------------------------|------------------------|
| `background-tasks/py/cron.py` | `cron.py` |

5. Copy configs:

| Source (in templates/) | Destination (in cron/) |
|------------------------|------------------------|
| `configs/ruff.toml` | `ruff.toml` |

6. Return: `deactivate && cd ..`

**Cursor rules:** `python`

**Blueprint:** See `blueprint-patterns.md` — "Cron job (Python)" pattern.

---

### workflow-ts

**Subdirectory:** `workflow/`

#### Steps

1. Create the subdirectory:

```bash
mkdir -p workflow && cd workflow
```

2. Create `package.json`:

```json
{
  "name": "{{PROJECT_NAME}}-workflow",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/workflow.ts",
    "build": "tsc",
    "start": "node dist/workflow.js",
    "lint": "biome check .",
    "format": "biome check --write ."
  }
}
```

3. Install dependencies:

```bash
npm install @renderinc/sdk
npm install -D typescript @types/node tsx @biomejs/biome
```

4. Copy template files:

| Source (in templates/) | Destination (in workflow/) |
|------------------------|----------------------------|
| `background-tasks/ts/workflow.ts` | `src/workflow.ts` |

5. Copy configs:

| Source (in templates/) | Destination (in workflow/) |
|------------------------|----------------------------|
| `configs/biome.json` | `biome.json` |
| `configs/tsconfig.base.json` | `tsconfig.json` |

   Add `"outDir": "dist"` and `"rootDir": "src"` to `compilerOptions`, and add `"include": ["src"]`.

6. Return to project root: `cd ..`

**Cursor rules:** `typescript`, `workflows`

**Blueprint:** See `blueprint-patterns.md` — "Background worker" pattern (workflows run as workers).

---

### workflow-py

**Subdirectory:** `workflow/`

#### Steps

1. Create the subdirectory:

```bash
mkdir -p workflow && cd workflow
```

2. Create `requirements.txt`:

```
render-sdk
python-dotenv
```

3. Set up virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

4. Copy template files:

| Source (in templates/) | Destination (in workflow/) |
|------------------------|----------------------------|
| `background-tasks/py/workflow.py` | `workflow.py` |

5. Copy configs:

| Source (in templates/) | Destination (in workflow/) |
|------------------------|----------------------------|
| `configs/ruff.toml` | `ruff.toml` |

6. Return: `deactivate && cd ..`

**Cursor rules:** `python`, `workflows`

**Blueprint:** See `blueprint-patterns.md` — "Background worker (Python)" pattern (workflows run as workers).

---

## Databases

### postgres

PostgreSQL is a managed database on Render. It doesn't create files—it adds a database entry to `render.yaml` and influences how API components are scaffolded (enabling Drizzle/SQLAlchemy setup).

When `postgres` is selected alongside an API component:

- **With `fastify`:** Use the "with database" variant in the fastify steps above
- **With `express`:** Use the "with database" variant in the express steps above
- **With `hono`:** Use the "with database" variant in the hono steps above
- **With `fastapi`:** Use the "with database" variant in the fastapi steps above
- **With `django`:** Database is included by default (Django ORM + PostgreSQL)

**Blueprint:** Add a `databases` section to `render.yaml`:

```yaml
databases:
  - name: {{PROJECT_NAME}}-db
    plan: free
```

And add `DATABASE_URL` to each service that connects to the database:

```yaml
envVars:
  - key: DATABASE_URL
    fromDatabase:
      name: {{PROJECT_NAME}}-db
      property: connectionString
```

---

## Caches

### redis

Redis is a managed key-value store on Render. Like postgres, it doesn't create files—it adds entries to `render.yaml`.

**Blueprint:** Add to `render.yaml`:

```yaml
services:
  - type: redis
    name: {{PROJECT_NAME}}-cache
    plan: free
    maxmemoryPolicy: allkeys-lru
    ipAllowList: []
```

And add `REDIS_URL` to services that use the cache:

```yaml
envVars:
  - key: REDIS_URL
    fromService:
      name: {{PROJECT_NAME}}-cache
      type: redis
      property: connectionString
```
