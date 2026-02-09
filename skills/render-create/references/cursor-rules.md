# Cursor rules reference

Copy Cursor rules from `templates/cursor-rules/` into the project's `.cursor/rules/` directory.

## Rules by stack

| Rule file | Used by |
|-----------|---------|
| `general.mdc` | All projects |
| `typescript.mdc` | All TypeScript projects |
| `fastify.mdc` | Fastify API projects |
| `express.mdc` | Express API projects |
| `hono.mdc` | Hono API projects |
| `nextjs.mdc` | Next.js projects |
| `remix.mdc` | Remix / React Router v7 projects |
| `react.mdc` | React projects (Next.js, Vite, Remix) |
| `tailwind.mdc` | Tailwind CSS projects |
| `vite.mdc` | Vite SPA projects |
| `astro.mdc` | Astro projects |
| `svelte.mdc` | SvelteKit projects |
| `python.mdc` | All Python projects |
| `django.mdc` | Django projects |
| `drizzle.mdc` | Drizzle ORM projects |
| `sqlalchemy.mdc` | SQLAlchemy projects (FastAPI + DB) |
| `workflows.mdc` | Render Workflow projects |

## Rules per preset

| Preset | Rules |
|--------|-------|
| `next-fullstack` | general, typescript, nextjs, tailwind, drizzle, react |
| `next-frontend` | general, typescript, nextjs, tailwind, react |
| `vite-spa` | general, typescript, vite, tailwind, react |
| `fastify-api` | general, typescript, fastify, drizzle |
| `express-api` | general, typescript, express, drizzle |
| `hono-api` | general, typescript, hono, drizzle |
| `fastapi` | general, python, sqlalchemy |
| `django` | general, python, django |
| `remix-fullstack` | general, typescript, remix, tailwind, drizzle, react |
| `astro-static` | general, typescript, astro |
| `sveltekit-fullstack` | general, typescript, svelte, tailwind |

## How to copy

1. Create `.cursor/rules/` in the project directory
2. For each rule in the preset's list, copy `templates/cursor-rules/<rule>.mdc` to `<project>/.cursor/rules/<rule>.mdc`
3. No variable substitution is needed—rule files are copied as-is
