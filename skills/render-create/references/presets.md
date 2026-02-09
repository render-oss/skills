# Presets reference

Each preset section below contains the exact steps to scaffold that project type. Follow every step in order.

In all steps, replace `{{PROJECT_NAME}}` with the actual project name the user provided.

---

## next-fullstack

**Stack:** Next.js + Tailwind + Drizzle ORM + PostgreSQL

### 1. Create the Next.js app

```bash
npx create-next-app@latest {{PROJECT_NAME}} --yes --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --turbopack
```

### 2. Enter the project directory

```bash
cd {{PROJECT_NAME}}
```

### 3. Install additional dependencies

```bash
npm install drizzle-orm zod postgres
npm install -D drizzle-kit @biomejs/biome @tailwindcss/typography
```

### 4. Add scripts to package.json

Merge these scripts into the existing `scripts` section:

```json
{
  "db:generate": "drizzle-kit generate",
  "db:migrate": "drizzle-kit migrate",
  "db:studio": "drizzle-kit studio"
}
```

### 5. Copy template files

Copy these files from the skill's `templates/` directory to the project, replacing `{{PROJECT_NAME}}` in file contents:

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `drizzle/db-index.ts` | `src/db/index.ts` |
| `drizzle/schema.ts` | `src/db/schema.ts` |
| `drizzle/drizzle.config.ts` | `drizzle.config.ts` |
| `styles/globals.css` | `src/app/globals.css` |
| `next/layout.tsx` | `src/app/layout.tsx` |
| `next/page-fullstack.tsx` | `src/app/page.tsx` |
| `assets/favicon.png` | `src/app/icon.png` |

### 6. Delete generated files that were replaced

```bash
rm -f src/app/favicon.ico
```

### 7. Copy config files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `configs/biome.json` | `biome.json` |
| `gitignore/node.gitignore` | `.gitignore` (overwrite) |

### 8. Copy Cursor rules

Rules: `general`, `typescript`, `nextjs`, `tailwind`, `drizzle`, `react`

```bash
mkdir -p .cursor/rules
```

Copy each rule file from `templates/cursor-rules/<rule>.mdc` to `.cursor/rules/<rule>.mdc`.

### 9. Generate render.yaml

Copy `templates/render-yaml/next-fullstack.yaml` to `render.yaml`, replacing `{{PROJECT_NAME}}`.

### 10. Validate and initialize git

```bash
render blueprint validate --path render.yaml  # if Render CLI is available
git init && git add -A && git commit -m "Initial commit"
```

### Dev command

```bash
npm run dev
```

---

## next-frontend

**Stack:** Next.js + Tailwind (static export)

### 1. Create the Next.js app

```bash
npx create-next-app@latest {{PROJECT_NAME}} --yes --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --turbopack
```

### 2. Enter the project directory

```bash
cd {{PROJECT_NAME}}
```

### 3. Install additional dev dependencies

```bash
npm install -D @biomejs/biome @tailwindcss/typography
```

### 4. Copy template files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `next/next.config.static.ts` | `next.config.ts` |
| `styles/globals.css` | `src/app/globals.css` |
| `next/layout.tsx` | `src/app/layout.tsx` |
| `next/page.tsx` | `src/app/page.tsx` |
| `assets/favicon.png` | `src/app/icon.png` |

### 5. Delete generated files that were replaced

```bash
rm -f src/app/favicon.ico
```

### 6. Copy config files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `configs/biome.json` | `biome.json` |
| `gitignore/node.gitignore` | `.gitignore` (overwrite) |

### 7. Copy Cursor rules

Rules: `general`, `typescript`, `nextjs`, `tailwind`, `react`

```bash
mkdir -p .cursor/rules
```

### 8. Generate render.yaml

Copy `templates/render-yaml/next-frontend.yaml` to `render.yaml`, replacing `{{PROJECT_NAME}}`.

### 9. Validate and initialize git

```bash
render blueprint validate --path render.yaml  # if Render CLI is available
git init && git add -A && git commit -m "Initial commit"
```

### Dev command

```bash
npm run dev
```

---

## vite-spa

**Stack:** Vite + React + Tailwind (static site)

### 1. Create the Vite app

```bash
npm create vite@latest {{PROJECT_NAME}} -- --template react-ts
```

### 2. Enter the project directory

```bash
cd {{PROJECT_NAME}}
```

### 3. Install dependencies

```bash
npm install
npm install -D tailwindcss @tailwindcss/vite @tailwindcss/typography @biomejs/biome
```

### 4. Copy template files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `vite/vite.config.ts` | `vite.config.ts` |
| `styles/globals.css` | `src/index.css` |
| `assets/favicon.svg` | `public/favicon.svg` |

### 5. Copy config files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `configs/biome.json` | `biome.json` |
| `gitignore/node.gitignore` | `.gitignore` (overwrite) |

### 6. Copy Cursor rules

Rules: `general`, `typescript`, `vite`, `tailwind`, `react`

```bash
mkdir -p .cursor/rules
```

### 7. Generate render.yaml

Copy `templates/render-yaml/vite-spa.yaml` to `render.yaml`, replacing `{{PROJECT_NAME}}`.

### 8. Validate and initialize git

```bash
render blueprint validate --path render.yaml  # if Render CLI is available
git init && git add -A && git commit -m "Initial commit"
```

### Dev command

```bash
npm run dev
```

---

## fastify-api

**Stack:** Fastify + Drizzle ORM + Zod + PostgreSQL

### 1. Create the project directory

```bash
mkdir {{PROJECT_NAME}} && cd {{PROJECT_NAME}}
```

### 2. Create package.json

Write this file as `package.json`:

```json
{
  "name": "{{PROJECT_NAME}}",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "biome check .",
    "format": "biome check --write .",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio"
  }
}
```

### 3. Install dependencies

```bash
npm install fastify @fastify/cors @fastify/env drizzle-orm zod postgres
npm install -D typescript @types/node tsx drizzle-kit @biomejs/biome
```

### 4. Copy template files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `fastify/index.ts` | `src/index.ts` |
| `drizzle/db-index.ts` | `src/db/index.ts` |
| `drizzle/schema.ts` | `src/db/schema.ts` |
| `drizzle/drizzle.config.ts` | `drizzle.config.ts` |

Replace `{{PROJECT_NAME}}` in file contents.

### 5. Create tsconfig.json

Write this file as `tsconfig.json`:

```json
{
  "extends": "./node_modules/@biomejs/biome/configuration_schema.json",
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

### 6. Copy config files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `configs/biome.json` | `biome.json` |
| `gitignore/node.gitignore` | `.gitignore` |

### 7. Copy Cursor rules

Rules: `general`, `typescript`, `fastify`, `drizzle`

```bash
mkdir -p .cursor/rules
```

### 8. Generate render.yaml

Copy `templates/render-yaml/fastify-api.yaml` to `render.yaml`, replacing `{{PROJECT_NAME}}`.

### 9. Validate and initialize git

```bash
render blueprint validate --path render.yaml  # if Render CLI is available
git init && git add -A && git commit -m "Initial commit"
```

### Dev command

```bash
npm run dev
```

---

## fastapi

**Stack:** FastAPI + SQLAlchemy + Pydantic + PostgreSQL

### 1. Create the project directory

```bash
mkdir {{PROJECT_NAME}} && cd {{PROJECT_NAME}}
```

### 2. Create requirements.txt

Write this file as `requirements.txt`:

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

### 3. Create a virtual environment and install dependencies

```bash
python3 -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
```

### 4. Copy template files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `fastapi/main.py` | `main.py` |
| `fastapi/app/__init__.py` | `app/__init__.py` |
| `fastapi/app/config.py` | `app/config.py` |
| `fastapi/app/database.py` | `app/database.py` |
| `fastapi/app/models.py` | `app/models.py` |

Replace `{{PROJECT_NAME}}` in file contents.

### 5. Copy config files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `configs/ruff.toml` | `ruff.toml` |
| `gitignore/python.gitignore` | `.gitignore` |

### 6. Copy Cursor rules

Rules: `general`, `python`, `sqlalchemy`

```bash
mkdir -p .cursor/rules
```

### 7. Generate render.yaml

Copy `templates/render-yaml/fastapi.yaml` to `render.yaml`, replacing `{{PROJECT_NAME}}`.

### 8. Validate and initialize git

```bash
render blueprint validate --path render.yaml  # if Render CLI is available
git init && git add -A && git commit -m "Initial commit"
```

### Dev command

```bash
uvicorn main:app --reload
```

---

## express-api

**Stack:** Express + Drizzle ORM + Zod + PostgreSQL

### 1. Create the project directory

```bash
mkdir {{PROJECT_NAME}} && cd {{PROJECT_NAME}}
```

### 2. Create package.json

Write this file as `package.json`:

```json
{
  "name": "{{PROJECT_NAME}}",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "biome check .",
    "format": "biome check --write .",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio"
  }
}
```

### 3. Install dependencies

```bash
npm install express cors zod drizzle-orm postgres
npm install -D typescript @types/node @types/express tsx drizzle-kit @biomejs/biome
```

### 4. Copy template files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `express/index.ts` | `src/index.ts` |
| `drizzle/db-index.ts` | `src/db/index.ts` |
| `drizzle/schema.ts` | `src/db/schema.ts` |
| `drizzle/drizzle.config.ts` | `drizzle.config.ts` |

Replace `{{PROJECT_NAME}}` in file contents.

### 5. Create tsconfig.json

Write this file as `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "declaration": true,
    "sourceMap": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

### 6. Copy config files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `configs/biome.json` | `biome.json` |
| `gitignore/node.gitignore` | `.gitignore` |

### 7. Copy Cursor rules

Rules: `general`, `typescript`, `express`, `drizzle`

```bash
mkdir -p .cursor/rules
```

### 8. Generate render.yaml

Copy `templates/render-yaml/express-api.yaml` to `render.yaml`, replacing `{{PROJECT_NAME}}`.

### 9. Validate and initialize git

```bash
render blueprint validate --path render.yaml  # if Render CLI is available
git init && git add -A && git commit -m "Initial commit"
```

### Dev command

```bash
npm run dev
```

---

## hono-api

**Stack:** Hono + Drizzle ORM + Zod + PostgreSQL

### 1. Create the project directory

```bash
mkdir {{PROJECT_NAME}} && cd {{PROJECT_NAME}}
```

### 2. Create package.json

Write this file as `package.json`:

```json
{
  "name": "{{PROJECT_NAME}}",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "lint": "biome check .",
    "format": "biome check --write .",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio"
  }
}
```

### 3. Install dependencies

```bash
npm install hono @hono/node-server zod drizzle-orm postgres
npm install -D typescript @types/node tsx drizzle-kit @biomejs/biome
```

### 4. Copy template files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `hono/index.ts` | `src/index.ts` |
| `drizzle/db-index.ts` | `src/db/index.ts` |
| `drizzle/schema.ts` | `src/db/schema.ts` |
| `drizzle/drizzle.config.ts` | `drizzle.config.ts` |

Replace `{{PROJECT_NAME}}` in file contents.

### 5. Create tsconfig.json

Write this file as `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "declaration": true,
    "sourceMap": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

### 6. Copy config files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `configs/biome.json` | `biome.json` |
| `gitignore/node.gitignore` | `.gitignore` |

### 7. Copy Cursor rules

Rules: `general`, `typescript`, `hono`, `drizzle`

```bash
mkdir -p .cursor/rules
```

### 8. Generate render.yaml

Copy `templates/render-yaml/hono-api.yaml` to `render.yaml`, replacing `{{PROJECT_NAME}}`.

### 9. Validate and initialize git

```bash
render blueprint validate --path render.yaml  # if Render CLI is available
git init && git add -A && git commit -m "Initial commit"
```

### Dev command

```bash
npm run dev
```

---

## django

**Stack:** Django + PostgreSQL

### 1. Create the project directory

```bash
mkdir {{PROJECT_NAME}} && cd {{PROJECT_NAME}}
```

### 2. Create requirements.txt

Write this file as `requirements.txt`:

```
django
gunicorn
psycopg2-binary
django-environ
whitenoise
```

### 3. Create a virtual environment and install dependencies

```bash
python3 -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
```

### 4. Copy template files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `django/manage.py` | `manage.py` |
| `django/project/__init__.py` | `project/__init__.py` |
| `django/project/settings.py` | `project/settings.py` |
| `django/project/urls.py` | `project/urls.py` |
| `django/project/wsgi.py` | `project/wsgi.py` |
| `django/app/__init__.py` | `app/__init__.py` |
| `django/app/views.py` | `app/views.py` |
| `django/app/models.py` | `app/models.py` |

Replace `{{PROJECT_NAME}}` in file contents.

### 5. Run initial migrations

```bash
python manage.py migrate
```

### 6. Copy config files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `configs/ruff.toml` | `ruff.toml` |
| `gitignore/python.gitignore` | `.gitignore` |

### 7. Copy Cursor rules

Rules: `general`, `python`, `django`

```bash
mkdir -p .cursor/rules
```

### 8. Generate render.yaml

Copy `templates/render-yaml/django.yaml` to `render.yaml`, replacing `{{PROJECT_NAME}}`.

### 9. Validate and initialize git

```bash
render blueprint validate --path render.yaml  # if Render CLI is available
git init && git add -A && git commit -m "Initial commit"
```

### Dev command

```bash
python manage.py runserver
```

---

## remix-fullstack

**Stack:** Remix (React Router v7) + Tailwind + Drizzle ORM + PostgreSQL

### 1. Create the Remix app

```bash
npx create-react-router@latest {{PROJECT_NAME}} --yes
```

### 2. Enter the project directory

```bash
cd {{PROJECT_NAME}}
```

### 3. Install additional dependencies

```bash
npm install drizzle-orm postgres
npm install -D drizzle-kit @biomejs/biome tailwindcss @tailwindcss/vite @tailwindcss/typography
```

### 4. Add scripts to package.json

Merge these scripts into the existing `scripts` section:

```json
{
  "db:generate": "drizzle-kit generate",
  "db:migrate": "drizzle-kit migrate",
  "db:studio": "drizzle-kit studio"
}
```

### 5. Copy template files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `remix/root.tsx` | `app/root.tsx` |
| `remix/home.tsx` | `app/routes/home.tsx` |
| `styles/globals.css` | `app/app.css` |
| `drizzle/db-index.ts` | `app/db/index.ts` |
| `drizzle/schema.ts` | `app/db/schema.ts` |
| `drizzle/drizzle.config.ts` | `drizzle.config.ts` |

Replace `{{PROJECT_NAME}}` in file contents.

### 6. Copy config files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `configs/biome.json` | `biome.json` |
| `gitignore/node.gitignore` | `.gitignore` (overwrite) |

### 7. Copy Cursor rules

Rules: `general`, `typescript`, `remix`, `tailwind`, `drizzle`, `react`

```bash
mkdir -p .cursor/rules
```

### 8. Generate render.yaml

Copy `templates/render-yaml/remix-fullstack.yaml` to `render.yaml`, replacing `{{PROJECT_NAME}}`.

### 9. Validate and initialize git

```bash
render blueprint validate --path render.yaml  # if Render CLI is available
git init && git add -A && git commit -m "Initial commit"
```

### Dev command

```bash
npm run dev
```

---

## astro-static

**Stack:** Astro (static site)

### 1. Create the Astro app

```bash
npm create astro@latest {{PROJECT_NAME}} -- --template minimal --yes
```

### 2. Enter the project directory

```bash
cd {{PROJECT_NAME}}
```

### 3. Install additional dev dependencies

```bash
npm install -D @biomejs/biome
```

### 4. Copy template files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `styles/globals.css` | `src/styles/globals.css` |
| `astro/index.astro` | `src/pages/index.astro` |

Replace `{{PROJECT_NAME}}` in file contents.

### 5. Copy config files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `configs/biome.json` | `biome.json` |
| `gitignore/node.gitignore` | `.gitignore` (overwrite) |

### 6. Copy Cursor rules

Rules: `general`, `typescript`, `astro`

```bash
mkdir -p .cursor/rules
```

### 7. Generate render.yaml

Copy `templates/render-yaml/astro-static.yaml` to `render.yaml`, replacing `{{PROJECT_NAME}}`.

### 8. Validate and initialize git

```bash
render blueprint validate --path render.yaml  # if Render CLI is available
git init && git add -A && git commit -m "Initial commit"
```

### Dev command

```bash
npm run dev
```

---

## sveltekit-fullstack

**Stack:** SvelteKit + Tailwind

### 1. Create the SvelteKit app

```bash
npx sv create {{PROJECT_NAME}} --template minimal --types ts
```

### 2. Enter the project directory

```bash
cd {{PROJECT_NAME}}
```

### 3. Install dependencies

```bash
npm install
npm install @sveltejs/adapter-node
npm install -D @biomejs/biome tailwindcss @tailwindcss/vite @tailwindcss/typography
```

### 4. Update svelte.config.js

Replace `@sveltejs/adapter-auto` with `@sveltejs/adapter-node`:

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

### 5. Copy template files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `sveltekit/+layout.svelte` | `src/routes/+layout.svelte` |
| `sveltekit/+page.svelte` | `src/routes/+page.svelte` |
| `styles/globals.css` | `src/app.css` |

Replace `{{PROJECT_NAME}}` in file contents.

### 6. Copy config files

| Source (in templates/) | Destination (in project) |
|------------------------|--------------------------|
| `configs/biome.json` | `biome.json` |
| `gitignore/node.gitignore` | `.gitignore` (overwrite) |

### 7. Copy Cursor rules

Rules: `general`, `typescript`, `svelte`, `tailwind`

```bash
mkdir -p .cursor/rules
```

### 8. Generate render.yaml

Copy `templates/render-yaml/sveltekit-fullstack.yaml` to `render.yaml`, replacing `{{PROJECT_NAME}}`.

### 9. Validate and initialize git

```bash
render blueprint validate --path render.yaml  # if Render CLI is available
git init && git add -A && git commit -m "Initial commit"
```

### Dev command

```bash
npm run dev
```
