# Skill Quality Evaluation

Critical evaluation of the Render skills (`render-deploy`, `render-debug`, `render-monitor`) against [Anthropic's official skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) and [The Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf?hsLang=en).

---

## Summary

The skills are functional and contain genuinely useful Render-specific knowledge. However, they have significant structural and authoring issues when measured against the official guidelines. The main problems are: massive content duplication across all three skills, naming that doesn't follow conventions, descriptions written in the wrong grammatical voice, over-explanation of things Claude already knows, missing tables of contents in long reference files, and a "When to Use" section in the body that's redundant once the description triggers loading.

---

## Issue 1: MCP Setup Instructions Duplicated Across All Three Skills

**Severity: High** | Guideline violated: "Concise is key", "The context window is a public good"

The identical MCP setup block (Cursor, Claude Code, Codex, Other Tools, Workspace Selection) is copy-pasted across all three SKILL.md files. This is approximately 75-80 lines of identical content repeated 3 times.

**Where it appears:**
- `render-deploy/SKILL.md` lines 116-191
- `render-debug/SKILL.md` lines 41-116
- `render-monitor/SKILL.md` lines 40-115

**Why this is a problem:** When Claude loads any skill, ~80 tokens of duplicated boilerplate consumes context window for no added value. If multiple skills are loaded in one session, the redundancy compounds. The guide states: "every token competes with conversation history and other context."

**Fix:** Extract to a shared `references/mcp-setup.md` file and link from each SKILL.md with a one-line reference like: "If MCP tools aren't configured, see [MCP Setup](../shared/mcp-setup.md)."

---

## Issue 2: Naming Convention Doesn't Follow Guidelines

**Severity: Medium** | Guideline violated: "Use gerund form (verb + -ing) for Skill names"

Current names:
- `render-deploy`
- `render-debug`
- `render-monitor`

The official best practices recommend gerund form: "We recommend using gerund form (verb + -ing) for Skill names, as this clearly describes the activity or capability the Skill provides."

**Recommended names:**
- `deploying-to-render`
- `debugging-render`
- `monitoring-render`

Or at minimum: `render-deploying`, `render-debugging`, `render-monitoring`.

---

## Issue 3: Descriptions Use Imperative Voice Instead of Third Person

**Severity: Medium** | Guideline violated: "Always write in third person"

The guide explicitly warns:
> "Always write in third person. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems."
> - Good: "Processes Excel files and generates reports"
> - Avoid: "I can help you process Excel files"

Current descriptions:
- `render-deploy`: "Deploy applications to Render by analyzing codebases..."
- `render-debug`: "Debug failed Render deployments by analyzing logs..."
- `render-monitor`: "Monitor Render services in real-time..."

These are imperative voice ("Deploy", "Debug", "Monitor"), not third person.

**Should be:**
- "Deploys applications to Render by analyzing codebases..."
- "Debugs failed Render deployments by analyzing logs..."
- "Monitors Render services in real-time..."

---

## Issue 4: "When to Use This Skill" Section in Body is Redundant

**Severity: Medium** | Guideline violated: "Include all 'when to use' information in description — not in the body"

The guide says:
> "Include all 'when to use' information here [in the description] — not in the body. The body is only loaded after triggering, so 'When to Use This Skill' sections in the body are not helpful to Claude."

All three skills have a "When to Use This Skill" section in their SKILL.md body. By the time Claude reads this section, it has already decided to load the skill — making these sections wasted tokens.

**Affected files:**
- `render-deploy/SKILL.md` lines 27-34
- `render-debug/SKILL.md` lines 18-26
- `render-monitor/SKILL.md` lines 20-25

**Fix:** Remove these sections from the body. Ensure the description field in frontmatter is comprehensive enough to cover all trigger conditions.

---

## Issue 5: Over-Explaining Things Claude Already Knows

**Severity: Medium** | Guideline violated: "Claude is already very smart — only add context Claude doesn't already have"

The guide says to challenge each piece of information: "Does Claude really need this explanation?" Several sections explain common knowledge:

1. **SSH to HTTPS URL conversion** (`render-deploy/SKILL.md` lines 339-352): Claude knows how to convert `git@github.com:user/repo.git` to `https://github.com/user/repo`. A full table with three provider mappings and a "Conversion pattern" explanation is unnecessary.

2. **Basic git commands** (`render-deploy/SKILL.md` lines 316-323): Claude knows `git add`, `git commit`, `git push`. The full block with explanation "Why this matters: The Dashboard deeplink will read..." is over-explained.

3. **Service type definitions** (`render-deploy/SKILL.md` lines 273-279): Explaining that `web` means "HTTP services, APIs, web applications (publicly accessible)" and `worker` means "Background job processors" is generic infrastructure knowledge Claude already has. The Render-specific nuances (like `pserv` for private services) are the only parts worth including.

4. **What a Git remote is** (`render-deploy/SKILL.md` lines 88-95): Explaining what a git remote is and showing `git remote -v` is unnecessary context.

**Fix:** Remove common-knowledge explanations. Keep only Render-specific information that Claude wouldn't know (Blueprint syntax, MCP tool signatures, Render-specific service behaviors).

---

## Issue 6: Long Reference Files Missing Table of Contents

**Severity: Medium** | Guideline violated: "For files longer than 100 lines, include a table of contents at the top"

The guide says:
> "Structure longer reference files — for files longer than 100 lines, include a table of contents at the top so Claude can see the full scope when previewing."

Files over 100 lines that lack a TOC:

| File | Lines | Has TOC? |
|------|-------|----------|
| `render-debug/references/error-patterns.md` | 899 | No |
| `render-deploy/references/blueprint-spec.md` | 718 | No |
| `render-debug/references/troubleshooting.md` | 663 | No |
| `render-deploy/references/configuration-guide.md` | 603 | No |
| `render-deploy/references/runtimes.md` | 473 | No |
| `render-deploy/references/service-types.md` | 450 | No |
| `render-debug/references/log-analysis.md` | ~480 | No |
| `render-debug/references/quick-workflows.md` | ~298 | No |
| `render-monitor/references/metrics-guide.md` | ~315 | No |

None of the reference files have a table of contents. This means when Claude previews these files (which it may do with `head -100` per the guide), it can't see the full scope of available information.

**Fix:** Add a `## Contents` section at the top of every reference file listing all major sections.

---

## Issue 7: render-deploy SKILL.md Is Borderline Too Long

**Severity: Low-Medium** | Guideline violated: "Keep SKILL.md body under 500 lines"

`render-deploy/SKILL.md` is 469 lines — under 500 but barely. A significant portion of this is the duplicated MCP setup block (~75 lines) and content that explains things Claude already knows (~30-40 lines). Removing these would bring it down to ~350 lines and leave room for the content that actually matters.

The other two skills are within reasonable limits (315 and 388 lines).

---

## Issue 8: No Evaluations or Testing Infrastructure

**Severity: Medium** | Guideline violated: "Build evaluations first", "Create evaluations BEFORE writing extensive documentation"

The guide recommends:
> "Create evaluations BEFORE writing extensive documentation. This ensures your Skill solves real problems rather than documenting imagined ones."

There are no evaluation files, test scenarios, or testing infrastructure in this repository. Without evaluations, there's no way to measure whether the skills actually improve Claude's performance on Render tasks, or whether specific instructions are helping vs. wasting context.

**Recommended:** Create at least 3 evaluation scenarios per skill:
- render-deploy: "Deploy a Next.js app with PostgreSQL", "Deploy a Python Flask API", "Deploy a static React site"
- render-debug: "Fix a service failing with missing env vars", "Debug an OOM crash", "Diagnose a health check timeout"
- render-monitor: "Check if a service is healthy", "Investigate slow response times", "Monitor database connections"

---

## Issue 9: Hardcoded Date in Example

**Severity: Low** | Guideline violated: "Avoid time-sensitive information"

`render-monitor/SKILL.md` line 299-303 contains:
```
startTime: "2024-01-15T10:00:00Z",
endTime: "2024-01-15T11:00:00Z"
```

This is a minor issue since it's clearly an example, but the guide recommends avoiding time-sensitive information. A relative or placeholder format would be better.

---

## Issue 10: Content Overlap Between debug and deploy Skills

**Severity: Low-Medium** | Guideline violated: "Concise is key"

Both `render-deploy` and `render-debug` have `references/error-patterns.md` files. The deploy skill also has `references/troubleshooting-basics.md`. While there is value in having deployment-specific vs. debugging-specific error references, there's likely significant content overlap between:
- `render-deploy/references/error-patterns.md`
- `render-deploy/references/troubleshooting-basics.md`
- `render-debug/references/error-patterns.md`
- `render-debug/references/troubleshooting.md`

This should be audited for redundancy.

---

## Issue 11: Inconsistent Freedom Levels Without Clear Intent

**Severity: Low** | Guideline violated: "Set appropriate degrees of freedom"

The deploy skill mixes freedom levels without clear reasoning:
- **Low freedom** (exact commands): `render whoami -o json`, `render blueprints validate`, `git add render.yaml && git commit...`
- **High freedom** (vague guidance): "Analyze the codebase to determine framework/runtime, build and start commands..."

The guide recommends being deliberate about this: "Think of Claude as a robot exploring a path: narrow bridge = specific guardrails, open field = general direction." The deploy skill doesn't clearly signal which parts need exact execution vs. which allow judgment.

---

## Issue 12: No MCP Tool Fully-Qualified Names

**Severity: Low** | Guideline violated: "Always use fully qualified tool names"

The guide states:
> "If your Skill uses MCP tools, always use fully qualified tool names to avoid 'tool not found' errors. Format: ServerName:tool_name"

All MCP references use bare tool names: `list_services()`, `get_metrics(...)`, `list_logs(...)`. These should be `render:list_services()`, `render:get_metrics(...)`, etc.

---

## What the Skills Do Well

To be fair, several things are done right:

1. **Progressive disclosure structure**: Reference files are organized by domain and linked from SKILL.md. This is the correct pattern.
2. **Reference nesting depth**: All references are one level deep from SKILL.md — exactly as recommended.
3. **Render-specific domain knowledge**: The error patterns catalog, MCP tool signatures, and Blueprint spec are genuinely useful context Claude wouldn't have.
4. **Conditional workflow pattern**: The deploy skill's "Blueprint vs. Direct Creation" decision tree is a good implementation of the conditional workflow pattern.
5. **Fallback patterns**: MCP-first with CLI fallback is a pragmatic design choice.
6. **Asset templates**: The render.yaml templates in `assets/` are a good use of bundled resources.

---

## Priority Fixes (Ordered by Impact)

1. **Extract shared MCP setup** to a common reference file (eliminates ~160 lines of duplication)
2. **Add TOC to all reference files** over 100 lines (improves Claude's navigation)
3. **Fix descriptions** to use third-person voice (improves skill discovery)
4. **Remove "When to Use" body sections** (saves tokens, was never useful)
5. **Remove over-explanations** of common knowledge (saves ~50-80 tokens per skill)
6. **Add evaluation scenarios** (enables measuring actual skill quality)
7. **Rename skills** to gerund form (follows naming convention)
8. **Audit cross-skill content overlap** in error/troubleshooting references
9. **Use fully-qualified MCP tool names** (prevents tool-not-found errors)
10. **Replace hardcoded date** in monitor example
