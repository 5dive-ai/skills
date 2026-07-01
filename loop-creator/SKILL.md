---
name: loop-creator
description: >-
  Author, validate, test, and publish an agentic loop — a portable LOOP.md (the
  agenticloops.dev standard) that packs a trigger, skills, and a prompt into one
  file any harness can install and run on a schedule. Use this whenever the user
  wants to "create a loop", "make an agentic loop", "write a LOOP.md", "turn this
  into a recurring agent", "scaffold or publish a loop", or describes a repeating
  job they want an agent to do on a timer (a daily digest, a competitor watcher, a
  triage sweep, a report pipeline) — even if they don't say the word "loop". This
  is the loop-level analogue of skill-creator — it builds the LOOP.md, not a skill.
  For composing an ad-hoc in-session multi-agent run (spawn, verify, panel,
  fan-out) use the `loops` skill instead; for authoring a reusable SKILL.md use
  skill-creator.
---

# Loop Creator

A skill for authoring **agentic loops** — the `LOOP.md` format behind [agenticloops.dev](https://agenticloops.dev).

> An agentic loop is an installable, recurring AI agent defined in one file: a **trigger**, a set of **skills**, and a **prompt**. One file defines it; any harness (Claude Code, Cursor, Codex, GitHub Actions, a 5dive runtime) can install and run it on a schedule.

This is the loop-level analogue of `skill-creator`. A skill is *knowledge*; a loop *runs*. Your job is to figure out where the user is and drive them through: **capture intent → write the LOOP.md → validate → test-run → publish**, iterating as needed. Be flexible — if they just want a quick draft, give them one; if they want to publish properly, walk the whole path.

The authoritative format is spec v0.1 at [github.com/5dive-ai/loops](https://github.com/5dive-ai/loops). This skill teaches the working subset; when a field is ambiguous, defer to the spec.

---

## The process

### 1. Capture intent

A loop is a *recurring job*, so pin down four things (mine the conversation first — the user may have already described the job):

1. **The job** — what one unit of work does this agent do each run? (one sentence; it becomes the prompt)
2. **The trigger** — when does it fire? A `schedule` (`every 4h`, `daily @ 07:00`, `weekdays @ 09:00`, or raw cron) **or** an `event` (`task-done`, `pr-opened`, `push`). One is required.
3. **The skills** — what capabilities does it lean on? (e.g. `deep-research`, `compile-knowledge`). Optional but common.
4. **The environment** — does it need a CLI binary, a secret, an MCP server, or network egress? These go in `requires` so the installer can pre-flight them.

If the job is really a *pipeline* (gather → draft → publish), it's a **multi-agent loop** — see below.

### 2. Write the LOOP.md

A loop is a directory whose name is the loop id, containing one `LOOP.md`. Frontmatter = the manifest; the body = the starter prompt.

**Single-agent template:**

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

Only `name`, `description`, and a trigger (`schedule` **or** `event`) are required. Everything else is optional — start minimal and add fields as the job needs them.

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

### 3. Validate

Never hand over a loop you haven't validated. There's no standalone `validate` command — validation is folded into `install` and `run`. Use a **dry-run install** to check the manifest against spec v0.1 and pre-flight `requires` without registering anything:

```bash
npx -y agenticloops install ./ci-analyst --dry-run --no-telemetry   # or a repo: owner/loop
```

A `✓ <name>` line means the manifest parsed. Fix any schema errors; unknown fields are warnings, not errors (the format is forward-compatible). A missing secret/CLI shows up here as a pre-flight `✗` — that's the check working, not a bad manifest.

### 4. Test-run once, now

Run the loop's chain a single time to see it actually work before scheduling it. On stock Claude Code this shells out to `claude -p` per role:

```bash
npx -y agenticloops run ./ci-analyst --harness=claude-code
# hard spend cap for the test (mapped to `claude --max-budget-usd`):
npx -y agenticloops run ./ci-analyst --harness=claude-code --budget='$0.50'
```

`--harness` is optional — it auto-detects. Iterate on the prompt/skills until the single run does the job.

### 5. Publish

Publishing = pushing a conforming public repo, no curation step:

1. Put the `LOOP.md` in a public GitHub repo (the folder name is the loop id).
2. Add the GitHub **topic `agenticloops`** to the repo.
3. The directory's crawler finds it, validates it, and indexes it. Install with `npx agenticloops install <owner/repo>`.

Ranking is **proof, not popularity** — loops that emit verifiable signed run receipts outrank ones that just have stars.

---

## Golden rules (the ones that trip people up)

- **Model-agnostic: `tier`, never a vendor model.** Write `tier: frontier | standard | fast`; the harness maps it to its own lineup (`frontier` → Opus on Claude, a GPT-5-class model on Codex, …). Naming `opus`/`gpt-5` in a `LOOP.md` breaks portability — the one thing the format exists to prevent. A specific model is a host-side *install* override (`--model=opus`), never in the file.
- **Secrets are NAMES, never values.** `secrets: [X_API_TOKEN]` declares *that* the loop needs a token; the value is supplied host-side at install and never enters the file or the repo.
- **`requires` is declare-and-check, not an installer.** It lists what must already be true; the installer pre-flights and prompts for what's missing. Only `skills` are ever fetched.
- **A trigger is required.** `schedule` or `event`. A loop with neither isn't a loop — it's a prompt. And it needs a *scheduler*: an IDE-only harness can run the agent but can't honor a recurring trigger (the installer warns).
- **Multi-agent handoff is structured, not chat.** Each role passes a defined artifact to `{{previous_output}}`, never transcript scraping. That's what makes an unattended run deterministic anywhere.
- **Prefer explicit skill paths.** `owner/repo/skill` is unambiguous; a bare name resolves against a default registry and can collide. Use the path whenever a name might clash.

---

## Communicating with the user

Loop authors range from engineers to first-time terminal users. Match their level: explain "cron", "MCP", or "egress" briefly if there's any doubt, and lead with the plain-language job ("a bot that emails you a competitor digest every morning") before the YAML. If they just want to vibe out a quick draft, skip the ceremony and hand them a minimal LOOP.md they can run.
