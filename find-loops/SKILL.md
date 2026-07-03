---
name: find-loops
description: Helps users discover and install agentic loops (recurring, scheduled AI agents) when they ask "find a loop for X", "is there a loop that…", "install a recurring agent that does X", "schedule an agent to do X", or want a repeating job run on a timer (a daily digest, a competitor watcher, a triage sweep, an every-morning report) — even if they never say the word "loop". Use this to SEARCH the agenticloops.dev directory and INSTALL an existing loop. This is the loop-level analogue of find-skills. For AUTHORING a new loop when none fits, use the fuller `loops` skill.
---

# Find Loops

This skill helps you discover and install **agentic loops** from the open loops ecosystem — the loop-level analogue of `find-skills`.

> An agentic loop is an installable, recurring AI agent defined in one file (a `LOOP.md`): a **trigger** (schedule/event), a set of **skills**, and a **prompt**. Any harness (Claude Code, Cursor, Codex, GitHub Actions, a 5dive runtime) can install and run it on a schedule. The standard lives at [agenticloops.dev](https://agenticloops.dev) / [github.com/5dive-ai/loops](https://github.com/5dive-ai/loops).

## When to Use This Skill

Use this skill when the user:

- Says "find a loop for X" or "is there a loop that does X"
- Wants a **recurring / scheduled** agent for a job (hourly, daily, on an event)
- Describes a repeating job without saying "loop": "email me a digest every morning", "watch our competitors", "triage new PRs each day", "run a security scan nightly", "check Y every hour"
- Wants to browse or search the loops directory before building anything

**Always try to find + install an existing loop before authoring a new one.** If nothing fits, hand off to the `loops` skill (which covers authoring a fresh `LOOP.md`).

## The loops CLI

The package manager for loops is `npx agenticloops`. On a 5dive runtime, the native path is `5dive loop`.

**Key commands:**

- `npx agenticloops find [query]` — search the agenticloops.dev directory
- `npx agenticloops install <owner/loop> --dry-run` — validate + pre-flight, change nothing
- `npx agenticloops run <owner/loop> --harness=<id>` — one live run to see it work (optional)
- `npx agenticloops install <owner/loop> --yes` — register the recurring job
- `npx agenticloops list` / `npx agenticloops update [<slug>]` — manage installed loops
- Native on a 5dive box: `5dive loop find|show|install <slug> --onto=<agent> [--cron="…"]`

**Browse loops at:** https://agenticloops.dev

## How to Help Users Find a Loop

### Step 1: Understand the Job

Identify:

1. The **job** (competitive intel, PR triage, security scan, news digest, report pipeline)
2. The **cadence** (hourly, daily, on an event)
3. Whether it's a single-agent job or a **pipeline** (gather → draft → publish = a multi-agent loop)

### Step 2: Search the Directory

```bash
npx agenticloops find <query>
```

Examples:

- "watch our competitors" → `npx agenticloops find competitive intel`
- "triage new PRs" → `npx agenticloops find pr triage`
- "daily security scan" → `npx agenticloops find security`
- "morning news digest" → `npx agenticloops find news digest`

Or browse [agenticloops.dev](https://agenticloops.dev) directly (ci-analyst, intel-brief, autonomous-pr-loop, agentic-security-scanner, daily-news-radar, issue-triage-bot, …).

### Step 3: Vet Before Recommending

A loop **runs unattended on a schedule**, so vet it harder than a one-shot skill:

1. **Proof, not popularity.** The directory ranks on **verifiable, signed run receipts**, not stars — prefer a loop that emits receipts (proof it actually did the job).
2. **Read the `requires` block** — the trust surface, listed *before* it runs: exactly which `cli` binaries, `secrets` (names only, never values), `mcp` servers, and `network` egress the loop touches. Confirm the user is comfortable with all of it.
3. **Source reputation** — prefer official `5dive-ai/loops` entries over an unknown author.
4. **Can the harness honor the trigger?** A loop needs *scheduling*. A run-only harness (an IDE) can run it once but can't fire it on a timer — target a scheduler (5dive, GitHub Actions, cron). The installer warns otherwise.

### Step 4: Present Options to the User

For each relevant loop, show:

1. The loop name + what it does
2. Its **cadence** and whether it emits **run receipts** (proof)
3. Its `requires` trust surface (cli / secrets / mcp / network)
4. The install command
5. A link to learn more on agenticloops.dev

### Step 5: Install (dry-run first)

```bash
npx agenticloops install <owner/loop> --dry-run   # validate + pre-flight, no changes
npx agenticloops run <owner/loop> --harness=<id>   # optional: one live run to see it work
npx agenticloops install <owner/loop> --yes        # register the recurring job
# native on a 5dive box:
5dive loop install <slug> --onto=<agent> [--cron="…"]
```

Supply any `requires.secrets` host-side at install (the installer prompts) — secrets are **names** in the file, never values. `--harness` auto-detects.

### Step 6: When No Loop Fits

If the directory has nothing for the job:

1. Say so honestly — no existing loop matched.
2. Hand off to the **`loops` skill**, which covers authoring a new `LOOP.md` (the loop-level analogue of skill-creator). Don't hand-roll one here — find-loops is discovery + install; `loops` owns building.

Example:

```
I searched the loops directory for "xyz" but didn't find a matching recurring agent.
I can build you one — a LOOP.md that runs your job on a schedule. Want me to draft it?
(That uses the `loops` skill, which handles authoring.)
```

## Tips

1. **Search the job, not the tool** — `find pr triage`, not `find github`.
2. **Try alternative terms** — if "deploy" misses, try "release" or "ci-cd".
3. **Prefer receipts + official sources** — a loop runs on its own on a timer; trust matters more than for a one-shot skill.
4. **Confirm the harness can schedule** before promising a recurring install.

Related: the fuller **`loops`** skill (find + install + **build**) and **`orchestrate`** (ad-hoc in-session multi-agent runs). find-loops is the lightweight discovery front door.
