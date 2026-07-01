---
name: agentic-loops
description: >-
  The full lifecycle for agentic loops — recurring, scheduled AI agents packaged
  as a portable LOOP.md (the agenticloops.dev standard: a trigger + skills + a
  prompt in one file any harness can install and run on a schedule). Use this
  whenever the user wants to FIND, INSTALL, RUN, or BUILD a loop: "find a loop for
  X", "is there a loop that…", "install a recurring agent that does X", "run this
  loop", as well as "create a loop", "make an agentic loop", "write a LOOP.md",
  "turn this into a recurring agent", "schedule an agent", "set up a cron job for
  an agent", or any description of a repeating job they want an agent to do on a
  timer (a daily digest, a competitor watcher, a triage sweep, a report pipeline,
  "email me X every morning", "check Y every hour") — even if they never say the
  word "loop". Always search the directory first and install an existing loop when
  one fits; author a new LOOP.md only when nothing does. This is the loop-level
  analogue of skill-creator + find-skills combined. For an ad-hoc in-session
  multi-agent run (spawn, verify, panel, fan-out) use the `loops` skill instead;
  for authoring a reusable SKILL.md use skill-creator.
---

# Agentic Loops — find, install, run & build recurring agents

The full lifecycle for **agentic loops** — the `LOOP.md` format behind [agenticloops.dev](https://agenticloops.dev).

> An agentic loop is an installable, recurring AI agent defined in one file: a **trigger**, a set of **skills**, and a **prompt**. One file defines it; any harness (Claude Code, Cursor, Codex, GitHub Actions, a 5dive runtime) can install and run it on a schedule.

This one skill covers the whole lifecycle — the loop-level analogue of `find-skills` **and** `skill-creator` in one:

1. **Find** an existing loop in the directory
2. **Install / run** it on your harness
3. **Author** a new `LOOP.md` when nothing fits

**Always try 1–2 before 3.** Search the directory and install an existing loop when one fits; only build a new one when nothing does. The authoritative format is spec v0.1 at [github.com/5dive-ai/loops](https://github.com/5dive-ai/loops); when a field is ambiguous, defer to the spec.

The CLI for the whole flow is `npx agenticloops` (`find` · `install` · `run` · `list` · `update`). On a 5dive runtime, the native path is `5dive loop find|show|install`.

---

## Part A — Find & install an existing loop

Do this first whenever the user wants a recurring agent for a job.

### A1. Understand the job

Identify the **job** (competitive intel, PR triage, security scan, news digest), the **cadence** (hourly, daily, on an event), and whether it's a single-agent job or a pipeline (gather → draft → publish = a multi-agent loop).

### A2. Search the directory

```bash
npx agenticloops find <query>        # searches agenticloops.dev
```

Examples: "watch our competitors" → `find competitive intel`; "triage new PRs" → `find pr triage`; "daily security scan" → `find security`. Or browse [agenticloops.dev](https://agenticloops.dev) directly (ci-analyst, intel-brief, autonomous-pr-loop, agentic-security-scanner, daily-news-radar, issue-triage-bot, …).

### A3. Vet before recommending

A loop *runs unattended on a schedule*, so vet it harder than a skill:

1. **Proof, not popularity.** The directory ranks on **verifiable, signed run receipts**, not stars — prefer a loop that emits receipts (proof it actually did the job).
2. **Read the `requires` block** — the trust surface: exactly which `cli` binaries, `secrets` (names), `mcp` servers, and `network` egress the loop touches, *before* it runs. Confirm the user is comfortable with all of it.
3. **Source reputation** — official `5dive-ai/loops` entries over an unknown author.
4. **Can the harness honor the trigger?** A loop needs *scheduling* — a run-only harness (an IDE) can run it once but can't fire it on time. Target a scheduler (5dive, GitHub Actions, cron); the installer warns otherwise.

### A4. Install (and test-run first)

```bash
npx agenticloops install <owner/loop> --dry-run    # validate + pre-flight, change nothing
npx agenticloops run <owner/loop> --harness=<id>    # optional: one live run to see it work
npx agenticloops install <owner/loop> --yes         # register the recurring job
# native on a 5dive box:
5dive loop install <slug> --onto=<agent> [--cron="…"]
```

`--harness` auto-detects. Supply any `requires.secrets` host-side at install (the installer prompts) — secrets are names in the file, never values. Manage installed loops with `npx agenticloops list` and `npx agenticloops update [<slug>]`.

If nothing in the directory fits → go to Part B and author one.

---

## Part B — Author a new loop

### B1. Capture intent

A loop is a *recurring job*, so pin down four things (mine the conversation first):

1. **The job** — what one unit of work does this agent do each run? (one sentence; it becomes the prompt)
2. **The trigger** — a `schedule` (`every 4h`, `daily @ 07:00`, `weekdays @ 09:00`, or raw cron) **or** an `event` (`task-done`, `pr-opened`, `push`). One is required.
3. **The skills** — capabilities it leans on (e.g. `deep-research`, `compile-knowledge`). Optional but common.
4. **The environment** — any CLI binary, secret, MCP server, or network egress? These go in `requires` for install-time pre-flight.

If the job is a *pipeline* (gather → draft → publish), it's a **multi-agent loop** — see the `agents:` template below.

### B2. Write the LOOP.md

A loop is a directory whose name is the loop id, containing one `LOOP.md`. Frontmatter = manifest; body = starter prompt.

```markdown
---
name: ci-analyst                 # kebab-case, ≤64 chars, matches the folder name
description: >                    # what it does + when to use it (drives discovery)
  Competitive-intel analyst — watches every competitor and the field, catches
  what changed, and writes a digest before it matters.
schedule: every 4h               # or: event: pr-opened  (one trigger is REQUIRED)
skills:                          # owner/repo/skill is explicit & recommended
  - 5dive-ai/skills/deep-research
  - 5dive-ai/skills/compile-knowledge
requires:                        # what must ALREADY be true in the env (declare-and-check)
  cli: [gh]                      #   binaries on PATH
  secrets: [X_API_TOKEN]         #   env-var NAMES only — never values
  mcp: [github]                  #   optional MCP servers
  network: [api.x.com]           #   optional egress allowlist
tier: frontier                   # capability hint: frontier | standard | fast (NEVER a vendor model)
effort: high                     # reasoning budget: high | medium | low
concurrency: skip                # overlap policy: skip | queue | replace | allow
timeout: 30m                     # per-run wall-clock cap (optional)
budget: 200k                     # per-run spend cap: tokens (200k) or cost ($2.00) (optional)
tags: [research, market-intel]
license: MIT
---

Scan our competitor set and the field for the last interval — launches, pricing,
funding, notable chatter. Update the watchlist and, once a day, write a concise
sourced briefing of what changed and what it means for us, then post it to the team.
```

Only `name`, `description`, and a trigger (`schedule` **or** `event`) are required. Start minimal; add fields as the job needs them.

**Multi-agent (pipeline) template** — an ordered `agents:` chain replaces the single body. Roles run strictly in array order; each role's structured output is injected at `{{previous_output}}` in the next:

```markdown
---
name: intel-brief
description: Competitive-intel pipeline — a researcher gathers what changed, a writer turns it into a sourced briefing.
schedule: every 4h
tier: frontier
effort: high
agents:
  - role: researcher             # kebab id, unique in the loop
    skills: [deep-research, compile-knowledge]   # per-role, additive to top-level skills
    prompt: |
      Scan our competitor set and the field for the last interval. Return a
      structured list of what changed, with sources. No prose, just findings.
  - role: writer
    skills: [copywriting]
    prompt: |
      From the findings below, write a concise sourced briefing of what changed
      and what it means for us, then post it to the team.
      Findings:
      {{previous_output}}
tags: [research, multi-agent]
license: MIT
---
```

Triggers, `requires`, `tier`, `effort`, `concurrency`, `timeout`, `budget`, and `tags` stay **top-level** — they govern the whole run, not one role.

### B3. Validate

There's no standalone `validate` command — validation is folded into `install` and `run`. Use a **dry-run install** to check the manifest against spec v0.1 and pre-flight `requires` without registering anything:

```bash
npx agenticloops install ./ci-analyst --dry-run --no-telemetry
```

A `✓ <name>` line means the manifest parsed. Fix any schema errors; unknown fields are warnings, not errors. A missing secret/CLI shows up as a pre-flight `✗` — that's the check working, not a bad manifest.

### B4. Test-run once, now

```bash
npx agenticloops run ./ci-analyst --harness=claude-code
npx agenticloops run ./ci-analyst --harness=claude-code --budget='$0.50'   # hard cap via `claude --max-budget-usd`
```

`--harness` auto-detects. Iterate on the prompt/skills until the single run does the job.

### B5. Publish

Publishing = pushing a conforming public repo, no curation step:

1. Put the `LOOP.md` in a public GitHub repo (the folder name is the loop id).
2. Add the GitHub **topic `agenticloops`**.
3. The crawler finds it, validates it, and indexes it. Others install with `npx agenticloops install <owner/repo>`.

Ranking is **proof, not popularity** — loops that emit verifiable signed run receipts outrank ones that just have stars.

---

## Golden rules (the ones that trip people up)

- **Model-agnostic: `tier`, never a vendor model.** Write `tier: frontier | standard | fast`; the harness maps it to its own lineup. Naming `opus`/`gpt-5` in a `LOOP.md` breaks portability. A specific model is a host-side *install* override (`--model=opus`), never in the file.
- **Secrets are NAMES, never values.** `secrets: [X_API_TOKEN]` declares *that* the loop needs a token; the value is supplied host-side at install and never enters the file or repo.
- **`requires` is declare-and-check, not an installer.** It lists what must already be true; the installer pre-flights and prompts for what's missing. Only `skills` are ever fetched.
- **A trigger is required.** `schedule` or `event`. And it needs a *scheduler* — an IDE-only harness can run the agent but can't honor a recurring trigger.
- **Multi-agent handoff is structured, not chat.** Each role passes a defined artifact to `{{previous_output}}`, never transcript scraping — that's what makes an unattended run deterministic anywhere.
- **Prefer explicit skill paths.** `owner/repo/skill` is unambiguous; a bare name resolves against a default registry and can collide.

---

## Communicating with the user

Loop users range from engineers to first-time terminal users. Match their level: explain "cron", "MCP", or "egress" briefly if there's any doubt, and lead with the plain-language job ("a bot that emails you a competitor digest every morning") before the YAML. Default to **find-first** — most people want a job done, not a file authored; reach for Part B only when the directory has nothing that fits.
