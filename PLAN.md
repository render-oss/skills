# Comprehensive Improvement Plan

Every structural and operational issue found in the Render skills, evaluated against [Anthropic's skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

---

## A. Dangerous / Incorrect Behavior

### A1. Hardcoded `git push origin main` (3 occurrences)

The skill tells Claude to push to `main` regardless of what branch the user is on. A user working on `feature/auth` or `develop` would have Claude push to the wrong branch, potentially bypassing branch protection or PR workflows.

**Locations:**
- `render-deploy/SKILL.md:290` — Step 2.5: `git add render.yaml && git commit -m "Add Render deployment configuration" && git push origin main`
- `render-deploy/SKILL.md:321` — Step 4: `git push origin main`
- `render-deploy/SKILL.md:418` — Direct Creation prerequisites: `git push origin main  # Ensure code is pushed`

**Fix:** Replace all three with guidance to use the current branch. E.g., "Push to the current branch" or use `git push origin HEAD`. Never hardcode a branch name.

---

### A2. Hardcoded `branch: "main"` in direct-creation.md

The MCP examples for `create_web_service` and `create_static_site` both hardcode `branch: "main"`.

**Locations:**
- `render-deploy/references/direct-creation.md:19` — `branch: "main",  # optional, defaults to repo default branch`
- `render-deploy/references/direct-creation.md:35` — `branch: "main",`

**Fix:** Use the user's current branch or the repo's default branch. The comment already says "defaults to repo default branch" — so just omit the field or tell Claude to detect the branch.

---

### A3. Hardcoded commit messages

The skill dictates exact commit messages rather than letting Claude generate contextual ones or asking the user.

**Locations:**
- `render-deploy/SKILL.md:290` — `git commit -m "Add Render deployment configuration"`
- `render-deploy/SKILL.md:320` — same

**Fix:** Tell Claude to generate an appropriate commit message based on what was added/changed, or present the render.yaml for review before committing.

---

### A4. Skill instructs Claude to commit and push without user consent

The deploy workflow treats committing and pushing as automatic steps, not as actions requiring user approval. These are irreversible side effects.

**Locations:**
- `render-deploy/SKILL.md:314` — "**IMPORTANT:** You must merge the `render.yaml` file into your repository before deploying."
- `render-deploy/SKILL.md:290` — Step 2.5 includes commit+push as an inline checklist item
- `render-deploy/SKILL.md:316-322` — Step 4 is entirely "Commit and Push" with no "ask user first"

**Fix:** Rewrite to: present the generated render.yaml to the user for review, then offer to commit. Never push without asking. The skill should say "Offer to commit and push" not "Commit and push."

---

### A5. `plan: free` default with no mention of tradeoffs

The skill says "Always use `plan: free`" without telling the user (or Claude) what free plan means: services spin down after 15 minutes of inactivity, limited CPU/memory, not suitable for production.

**Locations:**
- `render-deploy/SKILL.md:244` — "Always use `plan: free` unless user specifies otherwise"
- `render-deploy/references/deployment-details.md:102` — "Use `plan: free` unless the user specifies otherwise."
- `render-deploy/references/direct-creation.md:22,53,61` — `plan: "free"` in examples

**Fix:** Add a brief note about free plan limitations. E.g., "Default to `plan: free` for prototypes. Note: free services spin down after inactivity and have limited resources. For production workloads, recommend `starter` or higher."

---

## B. User Experience / Workflow Problems

### B1. Prerequisites gate blocks actual work

The deploy skill has 6 prerequisite steps (confirm source path, check MCP, check CLI, MCP setup, check auth, check workspace) before any deployment work begins. A user who says "deploy my app to Render" wants a render.yaml generated — that requires zero tools. MCP and CLI are only needed for validation (optional) and verification (post-deploy).

**Location:** `render-deploy/SKILL.md:83-225` — the entire Prerequisites Check section

**Fix:** Restructure to do the valuable work first (analyze codebase, generate render.yaml), then check tools only when an operation actually requires them. Lazy prerequisite checking, not upfront.

---

### B2. Happy Path contradicts Method Selection Heuristic

Two sections within 30 lines of each other give opposite guidance:
- Happy Path (line 37): "Ask whether they want to deploy from a Git repo or a prebuilt Docker image"
- Method Selection Heuristic (line 65): "Analyze the codebase first; only ask if deployment intent is unclear"

**Fix:** Pick one approach and remove the contradiction. Recommended: analyze first, ask only if ambiguous (the heuristic approach). Remove the "ask 2 questions" from Happy Path or merge them into a single coherent flow.

---

### B3. Debug skill can't help without tools, even when it should

The most common debugging scenario — user pastes an error message — is the one the skill handles worst. The workflow starts with `list_services()` which gates on MCP setup. But if a user says "my deploy failed with `ModuleNotFoundError: No module named 'flask'`", the error pattern catalog has the exact answer and no tools are needed.

**Location:** `render-debug/SKILL.md:119-133` — Step 1 always starts with MCP

**Fix:** Add an early branch: "If the user already provided error output or log context, skip directly to Step 3 (pattern matching). Use tools only to gather information the user hasn't already provided."

---

### B4. No handling of existing deployments or updates

The deploy skill only covers creating fresh deployments. These common scenarios are unaddressed:
- "I already have a render.yaml, I want to add a database"
- "I want to change my plan from free to starter"
- "I need to update environment variables on my existing service"
- "I want to add a worker service to my existing Blueprint"

**Location:** The entire deploy SKILL.md — no section covers modification of existing resources

**Fix:** Add a section or reference file for updating existing deployments. This is probably the second most common user intent after first-time deploy.

---

### B5. Debug skill forces linear workflow regardless of entry context

The workflow is always Step 1→2→3→4→5→6→7. But users arrive with different amounts of context:
- "Why did my deploy fail?" (needs Step 1)
- "Here's my error log: [paste]" (can skip to Step 3)
- "My service srv-abc123 is crashing" (can skip to Step 2)
- "My app is slow" (should go straight to Step 4)

**Location:** `render-debug/SKILL.md:119-243` — entirely linear

**Fix:** Add entry point guidance at the top of the workflow: "Start at the step that matches what you already know. If the user provided error context, skip to Step 3. If they named the service, skip to Step 2. If they report slowness, skip to Step 4."

---

### B6. Monitor and debug skills overlap significantly

Both skills check metrics, logs, service status, and deployments. A user saying "check if my deployment is working" or "why is my app slow" could reasonably trigger either skill. The descriptions attempt to differentiate but the actual workflows are nearly identical.

**Locations:**
- `render-debug/SKILL.md` description: "Use when deployments fail, services won't start..."
- `render-monitor/SKILL.md` description: "Use when users want to check service status, view metrics..."
- Both have Quick Health Check / Post-deploy check workflows

**Fix:** Sharpen the boundary in descriptions. Monitor = proactive ("is everything OK?"), Debug = reactive ("something is broken"). Consider whether monitor should exist as a separate skill or be folded into debug with a "health check" entry point.

---

### B7. Step 2.5 naming is confusing

A step named "2.5" between Step 2 and Step 3 breaks sequential numbering and suggests it was added after the fact.

**Location:** `render-deploy/SKILL.md:284` — "### Step 2.5: Immediate Next Steps (Always Provide)"

**Fix:** Renumber all steps sequentially.

---

### B8. Mixed agent/user action boundaries

The deploy workflow doesn't clearly delineate what Claude should do silently vs. what it should present to the user:
- Steps 1-4: Claude actions (analyze, generate, validate, commit)
- Steps 5-6: "Tell the user to do this" (deeplink, fill secrets)
- Step 7: Claude again (verify via MCP)

This ambiguity is why Claude might commit and push without asking — the skill doesn't distinguish between "do this" and "offer to do this."

**Location:** `render-deploy/SKILL.md:229-398` — the entire Blueprint workflow

**Fix:** Mark each step with whether Claude should act or present. E.g., "**[Claude action]** Analyze the codebase" vs. "**[Present to user]** Show the generated render.yaml and ask for approval."

---

### B9. No guidance on how to find service-id

Monitor and debug skills reference `<service-id>` throughout but don't explain the discovery flow. A user saying "is my app healthy?" doesn't know their Render service ID.

**Location:** Throughout both `render-debug/SKILL.md` and `render-monitor/SKILL.md`

**Fix:** Add a brief note: "Use `list_services()` to find the service ID by name. If the user mentions a service by name or URL, match it to the service list." This could be a one-liner near the top.

---

## C. Frontmatter / Discovery Issues

### C1. Descriptions use imperative voice instead of third person

The guide says: "Always write in third person. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems."

**Current:**
- `render-deploy`: "Deploy applications to Render..."
- `render-debug`: "Debug failed Render deployments..."
- `render-monitor`: "Monitor Render services..."

**Fix:**
- "Deploys applications to Render..."
- "Debugs failed Render deployments..."
- "Monitors Render services..."

---

### C2. Skill names don't follow gerund convention

The guide recommends gerund form: "deploying-to-render" not "render-deploy".

**Current:** `render-deploy`, `render-debug`, `render-monitor`

**Options:**
- `deploying-to-render`, `debugging-render`, `monitoring-render`
- `render-deploying`, `render-debugging`, `render-monitoring`

**Note:** This is a breaking change if anyone references these names. May want to weigh convention compliance vs. user disruption.

---

### C3. "When to Use This Skill" body sections are wasted tokens

The guide explicitly says this info belongs in the description, not the body. The body is only loaded after the skill is triggered — by that point, the "when to use" decision is already made.

**Locations:**
- `render-deploy/SKILL.md:26-34` — 8 lines
- `render-debug/SKILL.md:17-26` — 9 lines
- `render-monitor/SKILL.md:19-25` — 6 lines

**Fix:** Remove all three. Ensure the `description` frontmatter field is comprehensive enough.

---

### C4. `compatibility` field is overly verbose

The deploy skill's compatibility field is a multi-sentence paragraph. Only `name` and `description` drive discovery — long compatibility notes just add noise.

**Location:** `render-deploy/SKILL.md:5` — "Requires a Git repository on GitHub, GitLab, or Bitbucket for Blueprint/MCP flows. Blueprint can reference a prebuilt image but render.yaml must live in the repo. Render CLI recommended for Blueprint validation; MCP or CLI required for operations."

**Fix:** Shorten to essential info or move details into the body.

---

## D. Content Duplication

### D1. MCP setup duplicated across all 3 SKILL.md files

~80 lines of identical Cursor/Claude Code/Codex/Other Tools/Workspace setup instructions appear in every skill.

**Locations:**
- `render-deploy/SKILL.md:116-191`
- `render-debug/SKILL.md:39-116`
- `render-monitor/SKILL.md:38-115`

**Fix:** Extract to a shared file (e.g., `shared/mcp-setup.md` or a path each skill can reference). Replace inline content with: "If MCP tools aren't configured, see [MCP Setup](../shared/mcp-setup.md)."

---

### D2. Monitor Quick Reference duplicates its own body

The Quick Reference section at the bottom of the monitor skill restates the same MCP commands and CLI commands that were already shown inline throughout the file.

**Location:** `render-monitor/SKILL.md:314-366` — repeats content from lines 118-310

**Fix:** Either remove the Quick Reference (since the body already shows all commands in context) or keep only the Quick Reference and make the body more narrative. Don't have both.

---

### D3. Error patterns content exists in both deploy and debug skills

- `render-deploy/references/error-patterns.md` — 14 lines, a compact table
- `render-debug/references/error-patterns.md` — 899 lines, comprehensive catalog

The deploy version is so sparse it's barely useful. The debug version is comprehensive but only accessible from the debug skill.

**Fix:** Remove the deploy error-patterns.md. The deploy skill already has `troubleshooting-basics.md` for quick triage, and can reference the debug skill for deeper diagnostics (which it already does at line 467-468).

---

### D4. Troubleshooting content duplicated between skills

- `render-deploy/references/troubleshooting-basics.md` — 37 lines
- `render-debug/references/troubleshooting.md` — 663 lines

The deploy version is a subset of the debug version. Both cover the same failure classes (build, startup, runtime).

**Fix:** Keep the deploy version since it's intentionally compact for the deploy workflow's post-triage needs. But make sure it doesn't overlap in purpose with the deploy error-patterns.md (see D3 — remove one of them).

---

### D5. deployment-details.md overlaps heavily with deploy SKILL.md

The reference file covers env var patterns, port binding, plan defaults, build commands, health checks, and a Quick Reference — all of which already appear in SKILL.md or other reference files.

**Locations where content is duplicated:**
- Env var patterns: also in `configuration-guide.md` and SKILL.md
- Port binding: also in SKILL.md line 460, `service-types.md`, and code examples
- Plan defaults: also in SKILL.md line 244
- Quick Reference: also covered by SKILL.md tool references
- Common Issues section: also in `troubleshooting-basics.md` and `error-patterns.md`

**Fix:** Audit and consolidate. Either make `deployment-details.md` the canonical reference for all deployment config details (and remove from SKILL.md), or remove it and distribute its unique content to existing files.

---

### D6. Quick Reference sections repeat content that's already inline

Debug and Monitor skills both have Quick Reference sections at the bottom that restate MCP commands already shown in the workflow steps above. This is the same pattern as D2 but across all skills.

**Locations:**
- `render-debug/SKILL.md:262-298`
- `render-monitor/SKILL.md:314-366`

**Fix:** Pick one approach: either use Quick Reference as the primary command listing and keep the workflow narrative, or keep inline commands and drop the Quick Reference.

---

## E. Structural Issues (Best Practices)

### E1. No TOC in any reference file over 100 lines

The guide says: "For files longer than 100 lines, include a table of contents at the top."

**Affected files (11 total):**

| File | Lines |
|------|-------|
| `render-debug/references/error-patterns.md` | 899 |
| `render-deploy/references/blueprint-spec.md` | 718 |
| `render-debug/references/troubleshooting.md` | 663 |
| `render-deploy/references/configuration-guide.md` | 603 |
| `render-debug/references/log-analysis.md` | ~480 |
| `render-deploy/references/runtimes.md` | 473 |
| `render-deploy/references/service-types.md` | 450 |
| `render-monitor/references/metrics-guide.md` | 315 |
| `render-debug/references/database-debugging.md` | 305 |
| `render-debug/references/metrics-debugging.md` | 300 |
| `render-debug/references/quick-workflows.md` | 298 |

**Fix:** Add a `## Contents` section at the top of each file listing all major headings.

---

### E2. MCP tool calls not fully qualified

The guide says: "Always use fully qualified tool names to avoid 'tool not found' errors. Format: `ServerName:tool_name`"

Every MCP call across all skills uses bare names: `list_services()`, `get_metrics(...)`, `list_logs(...)`, etc.

**Fix:** Prefix all MCP tool calls with `render:`. E.g., `render:list_services()`, `render:get_metrics(...)`. This affects all 3 SKILL.md files and all reference files that contain MCP examples.

---

### E3. Over-explains things Claude already knows

The guide says: "Only add context Claude doesn't already have."

**Specific instances:**

| What | Location | Why it's unnecessary |
|------|----------|---------------------|
| SSH→HTTPS URL conversion table | `render-deploy/SKILL.md:339-346` | Claude knows this transformation |
| "Conversion pattern" explanation | `render-deploy/SKILL.md:346` | Redundant with the table above it |
| `git add`, `git commit`, `git push` commands | `render-deploy/SKILL.md:316-322` | Claude knows basic git |
| "Why this matters" paragraph about deeplinks reading from repo | `render-deploy/SKILL.md:326-328` | Claude can infer this |
| What a git remote is / `git remote -v` | `render-deploy/SKILL.md:88-95` | Common knowledge |
| Service type definitions (web, worker, cron, static) | `render-deploy/SKILL.md:273-278` | Generic infra concepts |
| Port binding code examples in Node/Python/Go | `render-deploy/references/deployment-details.md:76-99` | Claude knows how to bind a port; only the `$PORT` env var requirement is Render-specific |
| What log levels mean (error, warn, info) | `render-debug/references/log-analysis.md:17-20` | Universal knowledge |
| What "web service" use cases are (REST APIs, GraphQL, etc.) | `render-deploy/references/service-types.md:13-18` | Generic web dev concepts |

**Fix:** Remove or reduce each to the Render-specific detail only. E.g., replace the port binding examples with a single sentence: "Services must bind to `0.0.0.0:$PORT` (Render sets the `PORT` env var)."

---

### E4. Hardcoded date in monitor example

**Location:** `render-monitor/SKILL.md:299-303` — `startTime: "2024-01-15T10:00:00Z"`

**Fix:** Use a placeholder like `"<start-time>"` or a comment like `# Use ISO 8601 format`.

---

### E5. deploy SKILL.md is 469 lines (borderline)

Under the 500-line limit but only because of content that shouldn't be inline. Fixing A1-A5, C3, D1, and E3 would reduce this to ~300-350 lines.

---

### E6. No feedback loop in deploy workflow

The guide recommends "run validator → fix errors → repeat" patterns. The deploy workflow is purely linear: generate → validate → commit → push → deeplink. If validation fails, there's no explicit loop.

**Location:** `render-deploy/SKILL.md:295-310` — Step 3 says "Fix any validation errors before proceeding" but doesn't structure a retry loop.

**Fix:** Add explicit feedback loop guidance: "If validation fails, fix the errors in render.yaml and re-run `render blueprints validate`. Repeat until validation passes."

---

### E7. Inconsistent freedom levels without clear intent

Some instructions are very prescriptive (exact CLI commands), others are vague ("Analyze the codebase"). The guide recommends being deliberate about freedom level based on fragility.

**Examples:**
- Low freedom: `render whoami -o json`, `render blueprints validate` (correct — fragile operations)
- Low freedom: `git push origin main` (wrong — should be high freedom, Claude picks the branch)
- High freedom: "Analyze the codebase to determine framework/runtime" (correct — many valid approaches)
- Inconsistent: "commit and push" as a mandatory step (should be an offer, not a command)

**Fix:** Review each instruction and match freedom level to fragility. Git operations = high freedom (Claude decides branch, message). CLI validation = low freedom (exact command). Codebase analysis = high freedom.

---

## F. Missing Content / Capabilities

### F1. No evaluations or test scenarios

The guide says: "Create evaluations BEFORE writing extensive documentation."

**Recommended scenarios per skill:**

**render-deploy:**
- Deploy a Next.js app with PostgreSQL to Render
- Deploy a Python Flask API as a single service (Direct Creation path)
- Deploy a static React site
- Update an existing render.yaml to add a database

**render-debug:**
- User pastes `ModuleNotFoundError` — diagnose without MCP
- Debug an OOM crash using metrics
- Diagnose a health check timeout
- User says "my deploy failed" with no other context

**render-monitor:**
- Check if a specific service is healthy
- Investigate slow response times on an endpoint
- Check database connection health

---

### F2. No guidance for updating existing deployments

See B4. This is a missing capability, not just a UX issue.

---

### F3. No guidance on service-id discovery

See B9. Users don't know their service IDs — the skills should explain how to find them.

---

### F4. Related Skills references are vague

**Locations:**
- `render-debug/SKILL.md:313-314` — "**deploy:** Deploy new applications to Render"
- `render-debug/SKILL.md:314` — "**monitor:** Ongoing service health monitoring"
- `render-monitor/SKILL.md:386-387` — same pattern

These use shorthand names ("deploy", "monitor", "debug") that don't match the actual skill names (`render-deploy`, `render-debug`, `render-monitor`). Claude may not know how to invoke them.

**Fix:** Use the actual skill name field from frontmatter.

---

### F5. deploy error-patterns.md is too sparse to be useful

`render-deploy/references/error-patterns.md` is only 14 lines — a single compact table. It's so sparse that it's unclear if it adds value over the inline error table already in SKILL.md (lines 160-170).

**Fix:** Either flesh it out or remove it (see D3). The deploy SKILL.md already has a compact error table inline, and references the debug skill for deeper diagnostics.

---

### F6. post-deploy-checks.md and troubleshooting-basics.md are very short

- `render-deploy/references/post-deploy-checks.md` — 37 lines
- `render-deploy/references/troubleshooting-basics.md` — 37 lines

These are short enough to be inline in SKILL.md rather than separate reference files. Having them as separate files adds a file-read round trip for minimal content.

**Fix:** Consider inlining these into SKILL.md (they'd add ~70 lines total but replace the current references + link text). Or merge them into a single file.

---

## G. Reference File Content Issues

### G1. service-types.md over-explains generic concepts

The file spends significant space explaining what REST APIs, GraphQL, WebSocket servers, etc. are — knowledge Claude already has. The Render-specific content (port binding requirements, health check behavior, plan availability per type) is what's valuable.

**Location:** `render-deploy/references/service-types.md` — 450 lines, much of it generic

**Fix:** Trim generic explanations. Keep Render-specific configuration, constraints, and examples.

---

### G2. runtimes.md includes common knowledge per language

The file explains npm vs yarn vs pnpm, what `package.json` engines field does, common Python package managers, etc. Claude knows all of this. The Render-specific content (supported versions, auto-detection behavior, Render-specific env vars) is what's valuable.

**Location:** `render-deploy/references/runtimes.md` — 473 lines

**Fix:** Trim to Render-specific runtime behavior. Remove general language/package manager explanations.

---

### G3. log-analysis.md explains what log levels are

**Location:** `render-debug/references/log-analysis.md` — opens by explaining that "error" means "critical errors requiring attention" and "warn" means "warning messages"

**Fix:** Remove generic log level explanations. Focus on Render-specific log structure, filtering, and MCP query patterns.

---

### G4. metrics-debugging.md and metrics-guide.md overlap

- `render-debug/references/metrics-debugging.md` (300 lines) — debugging with metrics
- `render-monitor/references/metrics-guide.md` (315 lines) — interpreting metrics

Both cover CPU, memory, and latency metrics with thresholds and actions. Similar content, different framing.

**Fix:** Audit for overlap. Consider making one canonical metrics reference that both skills link to, or sharpen the distinction (debugging = what went wrong, monitoring = is it healthy now).

---

## H. Summary by Priority

### Must fix (dangerous/incorrect)
- A1: Hardcoded `git push origin main`
- A2: Hardcoded `branch: "main"` in direct-creation.md
- A3: Hardcoded commit messages
- A4: Commit/push without user consent
- A5: Free plan default with no caveats

### Should fix (user experience)
- B1: Prerequisites gate blocks actual work
- B2: Happy Path vs. Heuristic contradiction
- B3: Debug skill can't help when user provides the error
- B4: No handling of existing deployments
- B5: Debug forces linear workflow
- B8: Mixed agent/user action boundaries

### Should fix (structural compliance)
- C1: Descriptions not third person
- C3: "When to Use" in body is wasted
- D1: MCP setup duplication (~240 lines)
- E1: No TOC in reference files
- E2: MCP tools not fully qualified

### Nice to fix
- B6: Monitor/debug overlap
- B7: Step 2.5 naming
- B9: No service-id discovery guidance
- C2: Skill names not gerund form
- C4: Verbose compatibility field
- D2-D6: Various internal duplication
- E3: Over-explanation of common knowledge
- E4: Hardcoded date
- E6: No feedback loop
- E7: Inconsistent freedom levels
- F1: No evaluations
- F4-F6: Sparse/vague references
- G1-G4: Reference file content issues
