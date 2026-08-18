# Pre-Flight Checklist

Before creating any resources, validate the migration plan and present it to the user. Check each item below.

## Validation Checks

1. **Runtime supported?** If buildpack maps to `docker`, warn user they need a Dockerfile
2. **Worker dynos?** Flag these — can be defined in a Blueprint (`type: worker`, minimum plan `starter`), but cannot be created via MCP tools directly
3. **Release phase?** If Procfile has `release:`, suggest appending to build command
4. **Static site?** Check for static buildpack, `static.json`, or SPA framework deps — use `create_static_site` instead of `create_web_service`. See detection rules in the [buildpack mapping](buildpack-mapping.md).
5. **Third-party add-ons?** List any add-ons without direct Render equivalents (e.g., Papertrail, SendGrid) — user needs to find alternatives and update env vars
6. **Multiple process types?** If Procfile has >1 entry, each becomes a separate Render service (except `release:`)
7. **Repo URL available?** Verify a Git remote exists:

   ```bash
   git remote -v
   ```

   If no remote exists, stop and guide the user to create a GitHub/GitLab/Bitbucket repo, add it as `origin`, and push before continuing.

   If the URL is SSH format, convert it to HTTPS for service creation and deeplinks:

   | SSH Format | HTTPS Format |
   |---|---|
   | `git@github.com:user/repo.git` | `https://github.com/user/repo` |
   | `git@gitlab.com:user/repo.git` | `https://gitlab.com/user/repo` |
   | `git@bitbucket.org:user/repo.git` | `https://bitbucket.org/user/repo` |

   **Conversion pattern:** Replace `git@<host>:` with `https://<host>/` and remove the `.git` suffix.

8. **Database size?** If Postgres is Premium/large tier, recommend contacting Render support for assisted migration

## Migration Plan Table

Look up each Heroku dyno size and add-on plan in the [service mapping](service-mapping.md) to determine the correct Render plan. Then present the full plan as a table:

```
MIGRATION PLAN — [app-name]
─────────────────────────────────
CREATE (include only items that apply):
  ✅ Web service ([runtime], [mapped-plan]) — startCommand: [cmd]
     Heroku: [dyno-size] → Render: [mapped-plan]
  ✅ Background worker ([runtime], [mapped-plan]) — startCommand: [cmd]
     Heroku: [dyno-size] → Render: [mapped-plan]
  ✅ Cron job ([mapped-plan]) — schedule: [cron expr] — command: [cmd]
  ✅ Postgres ([mapped-plan], diskSizeGB: [size])
     Heroku: [plan-slug] → Render: [mapped-plan] + separately billed storage
  ✅ Key Value ([mapped-plan])
     Heroku: [plan-slug] → Render: [mapped-plan]

COST REVIEW:
  Render compute, database storage, HA, Key Value, cron jobs, bandwidth, and
  custom domains can incur charges. Confirm current details at
  https://render.com/pricing before proceeding. Database storage cannot be
  scaled down once provisioned.

METHOD: [Blueprint | MCP Direct Creation]

MANUAL STEPS REQUIRED:
  ⚠️ Custom domain: [domain] — configure after deploy
  ⚠️ Replace add-on: [name] → find alternative

ENV VARS: [N] to migrate, [M] filtered out
DATABASE: [size] — pg_dump/render psql required
─────────────────────────────────
Proceed? (y/n)
```

Do not calculate costs from hard-coded rates. Identify the resources and add-ons that incur charges, then have the user confirm current details at [Render pricing](https://render.com/pricing). Call out that Postgres storage and HA are billed separately from the primary instance.

Wait for user confirmation before creating any resources.
