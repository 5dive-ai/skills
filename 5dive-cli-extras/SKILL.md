---
name: 5dive-cli-extras
description: >-
  Administer the local 5dive runtime beyond everyday delegation: accounts and
  auth recovery, declarative fleets and remote boxes, loops and goal DAGs,
  governance, memory and wiki writes, plugins and host remediation. Use when
  runtime administration itself is the task; `5dive-cli` already covers
  spawning agents, messaging them and the shared task queue.
---

# 5dive-cli-extras

## What lives in here

Read the `5dive-cli` skill first for spawning and messaging sibling agents and
the basic task queue. This skill is the administration surface on top of it:

- **Market and hiring** — hire a ready-made persona (`5dive market`,
  `hire --from-market`) or fire one (`5dive fire`).
- **Auth and accounts** — auth recovery (`error.class=auth_required`,
  `--defer-auth`, device-code login via `agent auth start/poll/submit`),
  BYO-provider agents (`--provider`), multi-account auth (`5dive account`).
- **Fleets and hosts** — declarative fleets and company templates
  (`5dive up/down/ps/export`, `team import`), agents on other registered boxes
  (`5dive fleet`), hosting a CrewAI crew (`5dive crew`), hardened host
  remediation (`5dive host`), the onboarding wizard (`5dive company`).
- **Recurring and structured work** — `task add --recurring`,
  `5dive heartbeat`, projects (`5dive project add`), multi-agent loops (a relay
  with optional human gates via `task loop start`, or a maker→verifier review
  loop via `task add --verifier`, `task reject`, the `5dive loop` LOOP-7 verbs),
  guardrailed task DAGs (`5dive goal add`), self-steering objectives bound to a
  live metric (`5dive objective`), signed external events turned into tasks
  (`5dive trigger`).
- **Knowledge and org** — compiling durable knowledge into the shared wiki
  (`5dive memory add`), two-stage recall on a large store
  (`memory search --index` + `memory get`), org-chart writes (`5dive org set`),
  governance votes (`5dive council`).
- **Health and history** — fleet health, token burn and the daily standup
  (`5dive supervisor`, `5dive usage`, `5dive digest`), machine-readable health
  checks (`5dive doctor --json`, `5dive selfcheck --json`), a task's causal
  history (`5dive trace`), the current model id per alias (`5dive models`),
  seat liveness (`5dive liveness`), gate owners (`5dive human`), one agent's
  single attempt at one task (`5dive run`).
- **Delivery and comms** — a delegated GitHub push-for-review (`5dive push`),
  Telegram/Discord pairing and shared team-bot setup, the nostr handset rail
  (`5dive buzz`, `agent buzz enable`), installing and rolling back plugins
  (`5dive plugin`, `5dive market --kind=plugin`).


Companion to the `5dive-cli` skill: everything on the `5dive` CLI that isn't
reached for every session. Read `5dive-cli` first for the mental model,
the `--json` output contract, and the core spawn/send/task recipes — they
apply here too and aren't repeated.

## Advanced agent create: personas, BYO providers, auth deferral

#### Hire a ready-made persona from the agent market

Beyond a blank teammate, hire a ready-made **persona** off the agent market
(character-pack registry, DIVE-993/1020):

```bash
5dive market                          # browse every pack, rarity-first
5dive market <keyword> [--role=<r>] [--rarity=<tier>] [--seasoned]  # --seasoned = ships trained memory
5dive market show <slug>              # preview: tier, model, skills, card, DID

5dive hire <role> --from-market --dry-run --json          # resolve + show disclosure, create NOTHING
5dive hire <role> --from-market [--as=<name>] --yes --json  # provision the top match
```

`--from-market` **provisions a REAL teammate** (DIVE-1013): `--dry-run`
creates nothing; a TTY requires an interactive `y/N`; non-interactive needs
an explicit `--yes` or it aborts after the disclosure. `5dive hire <name>
[--role="CTO"] [--title=...]` (no `--from-market`) is plain sugar for `agent
create` plus an `org set` when `--role`/`--title` are given.

`agent import` is the path to clone an exact persona from a market slug or a
local `.tar.gz`. Always `inspect` an untrusted pack first (read-only, no root):

```bash
5dive agent inspect <slug|pack.tar.gz> --json        # what shell/hooks/skills it would run
sudo 5dive agent import <slug|pack.tar.gz> --as=<name> [--allow-hooks] --json
```

A pack's hooks are arbitrary shell that auto-runs on the new agent's tool
events, so `import` is **deny-by-default on hooks** — stripped unless you
pass `--allow-hooks` — and refuses any member with a `..`/absolute path or a
symlink (zip-slip + link-escape guards).

`agent clone <src> <dst>` copies an existing agent's type/config into a new
one. `--with-skills=<spec>[,<spec>...]` (bare id or `<owner/repo>:<id>`) /
`--no-skills` control what a spawned child inherits (defaults to the
`5dive-cli` skill when the caller is another agent); `--inherit-memory=<scope>`
seeds recall from `wiki`, a sibling `<agent-name>`, or `all`/`team`;
`--no-team-bot` opts a new no-bot agent out of the shared team bot.

#### Create-then-auth: `--defer-auth`

Registers the agent before its credentials are wired up:

```bash
sudo 5dive agent create draft-bot --type=claude --defer-auth --json
```

#### BYO API key: `--provider` (hermes / openclaw / claude)

`hermes` and `openclaw` are bring-your-own-model harnesses:

```bash
sudo 5dive agent create cheap-bot --type=openclaw \
  --provider=openrouter --api-key=- --json   # key on stdin
```

Providers: `openrouter google minimax moonshot huggingface anthropic
deepseek qwen nous openai zai`. Since 0.8.0, `--provider` also works on
`--type=claude` for the Anthropic-compatible subset (`openrouter deepseek
moonshot zai`); it requires `--auth-profile=<name>` and wires
`ANTHROPIC_BASE_URL`/`ANTHROPIC_AUTH_TOKEN` plus per-tier model defaults.
Override with `--model=<slug>` at create or `agent config set model=<slug>`
later. Keep the background HAIKU slot on a prompt-caching-capable model.

### Tune a running claude agent: model + effort

```bash
sudo 5dive agent config worker-1 set model=claude-opus-4-8
sudo 5dive agent config worker-1 set effort=high
# effort: low|medium|high|xhigh|max — claude only; xhigh/max are Opus-tier.
```

### Recover from `auth_required`

```bash
# If create fails with error.class=auth_required, the type isn't authenticated.
# A) Static API key in $KEY (preferred for automation)
echo "$KEY" | sudo 5dive agent auth set claude --api-key=- --json

# B) Device-code flow (when only a human can complete login)
sudo 5dive agent auth start claude --json
# -> session id; give the URL from `auth poll` to the user; they paste the
#    callback code back via `auth submit`.
```

Never call `5dive agent auth login <type>` from your own process — it hands
the TTY off to the upstream CLI's interactive flow and hangs your agent.
Use `auth start`/`auth set` instead.

### Multi-account: the `account` noun

A 5dive **account** is a named auth profile — one bag of credentials that any
number of agents can share via `--auth-profile=<name>`. Use it when the host
has more than one human/billing identity and different agents should use
different ones.

```bash
sudo 5dive account list --json           # which accounts exist, types, agents bound
sudo 5dive account usage --json          # per-account 5h/7d rate-limit headroom
sudo 5dive account show acme-prod --json # detail incl. which env keys are populated

sudo 5dive account add acme-prod         # provision empty, then sign in (TTY-only)
sudo 5dive account login acme-prod --type=claude

sudo 5dive agent set-account worker-1 acme-prod --json   # rebind + restart
sudo 5dive agent set-account worker-1 default --json     # clear the override

sudo 5dive account rename acme-prod acme-staging --json  # remove refuses while bound
sudo 5dive account remove acme-staging --json
sudo 5dive account set-active-provider acme-prod hermes openrouter --json  # hermes-only
```

The reserved name `default` is rejected by `account add`/`rename` — at the
agent level, `auth-profile=default` means "no override, use the shared
`/etc/5dive/connectors/<type>.env`". Check `account usage` **before** blaming
quota for a failure or moving agents between accounts.

## Telegram/Discord pairing and shared team bot

```bash
# Classic — return a pairing code, user DMs the bot, paste the bot reply.
sudo 5dive agent pair worker-1 --json
sudo 5dive agent pair worker-1 --code=AB12CD --json

# Auto-detect — long-poll for the next inbound message, seed access.json.
sudo 5dive agent telegram-discover --token="$BOT_TOKEN" --poll-secs=60 --json
sudo 5dive agent pair worker-1 --user-id=<userId> --chat-id=<chatId> --json

# Bot identity for a tappable deep link.
sudo 5dive agent telegram-getme --token="$BOT_TOKEN" --json
```

`telegram-discover`/`telegram-getme` are read-only and need no bound agent.
A few more helpers:

```bash
sudo 5dive agent telegram-info worker-1 [--refresh] --json         # cached getMe, backfills @handle
sudo 5dive agent telegram-pending-ignore worker-1 <code> --json    # drop a pending pairing
sudo 5dive agent telegram-resolve-handle worker-1 @someuser --json # getChat for @handle
```

Attach a bot **after** create, and prefer stdin over argv for tokens (never
lands in `/proc/<pid>/cmdline` or logs):

```bash
echo "$BOT_TOKEN" | sudo 5dive agent config worker-1 set telegram.token=-
sudo 5dive agent config worker-1 set channels=telegram
sudo 5dive agent config worker-1 set telegram.home-channel=<chat-id>  # hermes only
```

Only one `=-` key can be read per invocation, and `=-` with nothing piped
blocks on stdin until your timeout. For non-channel secrets there's a
root-only drop primitive:

```bash
echo -n "$TOKEN" | sudo 5dive secret write OPENAI_API_KEY --connector=openai
```

Who may talk to the bot is governed by `access.json` (no restart needed —
the plugin re-reads per message):

```bash
sudo 5dive agent telegram-access get worker-1 --json
echo '{"dmPolicy":"allowlist","allowFrom":[1234567890],"groups":{}}' \
  | sudo 5dive agent telegram-access set worker-1
sudo 5dive agent config worker-1 set telegram.allowed-users=1234567890,5551234  # shortcut
```

A group chat the bot should reply in must be present in `groups{}` — without
it, replies into that group are dropped.

#### Shared team bot: one bot, every agent

Instead of one token per agent, every agent can post into one Telegram forum
group (its own topic per agent) on a single token, with a root listener as
the sole `getUpdates` consumer (per-agent bridges go send-only):

```bash
sudo 5dive agent team-bot status|provision|shared|intercom|discover|refresh-listener
sudo 5dive agent team-group discover|provision|shared|status [--group=<chat_id>]
sudo 5dive agent topic get|set <name> [--thread-id=N --chat-id=N]  # per-agent forum topic
```

#### Delegating a request that came in over a channel — full walkthrough

When the user's request arrives via the channel plugin, it's wrapped:

```
<channel source="plugin:telegram:telegram" chat_id="1234567890" message_id="4671" user="..." ts="...">
redirect to marketing
</channel>
```

Map `chat_id` → `--reply-to-chat=<chat_id>` and `message_id` →
`--reply-to-msg=<message_id>` (optional; threads the reply):

```bash
sudo 5dive agent send marketing \
  --reply-to-chat=1234567890 --reply-to-msg=4671 \
  "User @alice asked your take on the Q3 launch copy. Reply in the chat
   via your own bot — do not reply back to me."
```

Receiver-side the envelope carries `reply-to-chat=<id> reply-to-msg=<id>`; on
seeing it, post directly in that chat via your own Telegram/Discord tool
instead of replying back to the sender. If the target agent's bot is **not**
in the chat, relay the reply yourself and tell the user the bot needs adding.

## Declarative fleets: compose + team templates

For more than a couple of agents, declare the fleet in `5dive.yaml`:

```bash
sudo 5dive up         # bring up everything declared (idempotent)
sudo 5dive ps         # declared agents' state
sudo 5dive down       # tear down declared agents
sudo 5dive export     # dump the LIVE fleet to a v2 5dive.yaml

sudo 5dive team ls
sudo 5dive team import startup --json   # bundled multi-agent company template
```

Spec keys per agent: `type, channels, telegram_token, discord_token,
workdir, skills, no_skills, defer_auth, isolation, auth_profile, provider,
api_key`. Strings expand `${ENV_VAR}` from the process env and fail loudly
when missing.

## Host a CrewAI crew: `5dive crew`

The box can run a CrewAI crew as a first-class workload: its own venv, BYO
LLM key stored owner-600, durable memory on disk (`CREWAI_STORAGE_DIR`), and
a co-signed receipt per run.

```bash
sudo 5dive crew install <git-url> --as=<name> [--entry=<module:Crew>] [--branch=<b>]
sudo 5dive crew secret set <name> KEY=VALUE [KEY=VALUE ...]
sudo 5dive crew run <name>          # also: show <name> | list | uninstall <name>
```

## Projects: group a multi-task effort under its own ident namespace

Open a **project** instead of filing a sprawl of loose `DIVE-N` tasks — a
named task workspace with its own ident prefix and an optional lead:

```bash
5dive project add frog --name="Frog migration" --goal="port the parser" \
  --lead-agent=worker-1 --json          # prefix defaults to the upper-cased key
5dive project ls --json                 # key, prefix, task count, lead, status
5dive project show frog --json

5dive task add "port the lexer" --project=frog --assignee=worker-1 --json
5dive task ls --project=frog --json
```

Everything else — `start`/`done`/`need`/`block`/`loop`/`heartbeat` — works
identically on a project's tasks.

## Task queue extras: park, escalate, bulk-clear, org writes

**Quiet waits: `task park`.** Sleep a task without putting it in the human
inbox:

```bash
5dive task park DIVE-12 --reason="revisit after launch" --wake=+3d --json
5dive task unpark DIVE-12 --json   # wake it early
```

Both `--reason` and `--wake` are REQUIRED (no block-graveyard). If you're
actually waiting on a person, use `task need` instead; `park` also refuses
over a task with a live `task need` gate.

**`--type=access` gates** are for "I'm blocked on a permission I don't
have" — pair with `--probe=<cmd>` (a self-check that must currently FAIL, so
the gate isn't filed for something you already have):

```bash
5dive task need DIVE-9 --type=access --probe="aws s3 ls s3://prod-bucket" \
  --ask="Need read access to prod-bucket" --recommend="grant s3:GetObject" --json
```

**Precedent prefill.** A gate filed with a blank `--recommend` looks for the
closest answered precedent (same need type + ask shape, equal-or-higher
tier, within 90 days) and prefills the recommendation, citing it on the
alert — never overrides an explicit `--recommend`.

**Flag for attention:** `task escalate <id>` bumps priority a tier (capped
at urgent) and pings the owner + paired human, without filing a gate.

**Bulk-clear as the paired human:** `task clear-recs --channel-proof=<chat_id>
[--only=<id>]` clears every eligible low-risk gate (tier<2, has a
`--recommend`) in one shot from a verified DM.

**Who fronts the inbox:** `task coordinator [--json]` prints the resolved
org coordinator — the sole agent a surface should pin a needs-you banner to.

**Org chart writes** (reads live in `5dive-cli` core):

```bash
5dive org set worker-1 --manager=lead --title="Auth audit" --json
5dive org show worker-1 --json     # manager + direct reports
5dive org ls --json                # flat list of everyone placed
5dive org rm worker-1 --json       # remove (reports re-parent to null)
```

Writes are root-only — the chart is trusted input to gate routing.

### Recurring work + waking workers: heartbeat

A recurring **template** materializes into a normal todo on schedule; the
**heartbeat** wakes an enrolled agent only when it actually has queued work.

```bash
5dive task add "rotate the weekly metrics digest" \
  --recurring="0 9 * * 1" --assignee=worker-1 --json
5dive task ls --recurring --json     # list templates

sudo 5dive heartbeat on worker-1 --every=30m   # default every=30m; fresh sends /clear per task
sudo 5dive heartbeat ls              # enrolled agents + next wake + queued count
# since 0.32.0: wake ONE seat for ONE row NOW, reusing the tick's own delivery
# path — how an incident row gets a grader without waiting its turn in the queue.
sudo 5dive heartbeat wake-task [--fresh|--no-fresh] <agent> <task_id> [<ident>]
sudo 5dive heartbeat off worker-1
```

Enrolment uses the agent's short name, the same name `task --assignee`
expects. No catch-up for missed ticks — keep schedules coarse.

## Loops: relay work across agents (+ human gates)

A loop chains agents into an auto-relay: each step hands off the moment its
`task done` lands, and a human gate pauses the chain for a tap. You can
build, edit, and inspect it conversationally.

```bash
5dive task loop start --title="Content pipeline" --steps='[
  {"agent":"olivia","label":"Pick the topic and brief the writer","handoff":"briefs"},
  {"agent":"theo","label":"Draft the post","handoff":"sends to review"},
  {"gate":"approval","label":"You approve before it publishes"},
  {"agent":"theo","label":"Publish and close"}
]' --json

5dive task loop ls --json        # board of loop runs: per-run step progress + status
```

The relay creates one subtask per step, chained N+1-blocked-by-N under a run
parent. To **edit a running loop**, act on its subtasks (`task ls`, `task
assign`, `task block/unblock`, `task rm`, or slip in a `task need` gate); to
stop it, `task rm` the run parent (cascades).

#### Maker→verifier loops: the writer never grades itself

Verification is on by default for non-trivial tasks (a grader distinct from
the maker); `--no-verify` opts out. To pin a specific grader:

```bash
5dive task add "migrate the auth module to the new SDK" \
  --assignee=dario --verifier=marcus --max-iters=3 \
  --accept="builds clean, tests pass, no public API change" --json

5dive task reject DIVE-7 --feedback="tests pass but the public signature changed" --json
# -> bounces back to the maker; escalates to a human at --max-iters.

5dive task loops --json          # board of maker→verifier loops (--stuck / --escalate-stuck)
5dive task loops --runs --json   # loop_runs control window: topology/stage/iteration/ceiling
```

`5dive task verifier <id> <agent> [--accept=<criteria>] [--max-iters=<n>]`
attaches the rail to an already-filed task. Once delivered, `task done` is
refused from anyone but the verifier — send corrections there instead. If
the work ships as a PR, `5dive task deliver <id> --pr=<url> [--result=<text>]`
hands off to the verifier without closing; `task done` then refuses to close
until that PR is merged and green (`--force-merge-gate` overrides false
positives).

#### LOOP-7: agent-native orchestration verbs

Lower-level than the relay above — JSON in/out, each verb spawns/grades
agents directly and honors `--ceiling` (self-halts + escalates at the
limit). Humans watch/kill via `task loops --kill <loopId>`; they never
author a loop.

```bash
5dive loop spawn --role=maker|verifier|worker --agent=<type|name> \
  --prompt="…" [--schema=<json>] [--ceiling=<tok>] [--wait[=<sec>]]
5dive loop verify --target=<id> --verifier=<agent> [--accept="…"]
5dive loop grade  --target=<id> --verifier=<agent> [--accept="…"] [--threshold=0-100] [--wait]
5dive loop panel  --n=<k> --lens="correctness,security" --claim="…" --quorum=<m>   # jury
5dive loop map    --over=<json-array> --do=<spawn-spec> [--max-concurrency=<n>]    # fan-out
5dive loop until-dry --round=<spawn-spec> --stop-after=<K> --dedup-key="…"         # drain a queue
5dive loop collect --handles=<id,id,…>       # gather results from spawned handles
5dive loop status  --handle=<loopId>         # read-only single-loop drilldown
5dive loop install <slug> --onto=<agent> [--cron="…"] [--ceiling=<tok>] [--dry-run]
```

## Goals: decompose an outcome into a task graph

`5dive goal add` turns a one-line outcome into a validated, guardrailed task
DAG (checked for acyclicity, size/depth caps, tier-floor, assignability
before anything is created). Over the count checkpoint or carrying any
Tier-2 task, ONE decision gate holds the plan.

```bash
5dive goal add "ship a public status page" --dry-run --json   # plan + render, create NOTHING
5dive goal add "ship a public status page" --json \
  [--project=<key>] [--planner=<agent>] [--max-tasks=12] [--depth-cap=5] \
  [--checkpoint=6] [--ceiling=40000] [--yes]
5dive goal add --from-gate=<id> --json    # materialize a plan a HUMAN answered 'approve'
```

`goal add` is **async by default**: it returns immediately with a job id
after spawning the planner (unless the planner is already idle, in which
case it may return the finished result inline). Poll with:

```bash
5dive goal status <job>   # queued | running | done (plan/gated/materialized) | failed
```

Pass `--wait` for the legacy bounded-block behavior in scripts, or
`--plan=<json>` to skip the planner entirely. Always `--dry-run` first to
eyeball the plan.

## Objectives: a standing goal bound to a live metric

`5dive objective` is different from `goal`: a **standing target tied to a
read-only metric command** re-measured each `tick`, for tracking a number you
want to move rather than decomposing work.

```bash
5dive objective add "warm pool >= 1" --metric-cmd="5dive ps --warm --json | jq length" \
  --target=1 --direction=up [--unit=count] [--public]
5dive objective ls | show <name> | tick [<name>] | pause <name> | rm <name>
5dive objective resume <name> [--force]   # --force bypasses a preflight refusal
```

**Self-steer it:** `objective replan <name>` drives one cycle — a planner
proposes a diff (new/reprioritized/cancelled tasks) toward the target,
validated like a `goal add` plan:

```bash
5dive objective replan warm-pool --dry-run --json     # see the proposed diff, create nothing
5dive objective replan warm-pool --json \
  [--max-new-per-cycle=3] [--no-progress-limit=3] [--yes] [--from-gate=<id>]
```

`--yes` waives only the count-over-checkpoint gate — a Tier-2 task in the
diff still hard-gates. Always `--dry-run` a replan first.

## Governance votes: `5dive council`

For decisions that should be a recorded vote rather than one agent's call —
membership motions, constitutional amendments, or routing an open gate to a
deliberation:

```bash
5dive council convene "<question>" [--seats=a,b,c] [--mode=quick|deliberate|adversarial]
                                   [--bench=<name>] [--class=<decisionClass>] [--timeout=120]
5dive council gate-clear <task|DIVE-N> [--mode=deliberate] [--seats=a,b,c] [--dry-run]
5dive council schedule add <name> --question="<template>" --cron="<m h dom mon dow>"
5dive council schedule ls | show <name> | rm <name> | run <name> [--dry]

5dive council roster --json    # current seats, threshold + quorum, veto holder
5dive council log --limit=20 --json    # sealed verdict history
5dive council verify [<receipt-digest>]   # re-seal + hash-chain check, fails closed on tamper
```

`convene` dispatches to the real seated agents (each votes via its own
harness, blind first round) and seals an auditable, tamper-evident verdict.
`gate-clear` routes an open **tier-1** gate to the council — a tier-2 or
human-only-type gate is never self-cleared, always bumped to a human. Writes
(`init`, `promote`/`demote`/`expel`, `bench add/rm`, `schedule add/rm`) are
sudo-gated; reads (`roster`, `log`, `verify`, `record`) are not. Reach for
council deliberately, not as a substitute for a normal `task need` gate.

## Delegated push: `5dive push`

An agent created with `--can-push` (needs `--isolation=standard`, the
default) can push ONE named feature branch for PR review once its task's
gate is cleared and bound to that branch:

```bash
5dive push DIVE-42 [--branch=<b>] [--repo=<o/r>] [--dry-run] [--yes]
5dive push DIVE-42 --open-pr [--pr-title=<t>] [--pr-body-file=<f>] [--pr-draft]
sudo 5dive push setup   # once per box: scaffold the GitHub App config
```

The agent's own process never touches a GitHub token; a root-only helper
mints one scoped to just that repo, pushes, and discards it.

`--open-pr` opens the PR in the same call. Since 0.35.1 (DIVE-4423) it **mints a
conventional-commit PR title itself** so `pr-title-lint` can pass: it reuses the
commit subject only for a single-commit range, and derives a type over the whole
range otherwise. Pass `--pr-title=` only when you want to override that — a
hand-written title that is not conventional-commit shaped reds the lint and the PR
needs a manual retitle.

## Company wizard: `5dive company`

```bash
5dive company --yes --name=<n> --objective="<outcome>" --metric-cmd="<cmd>" \
  --target=<n> --direction=up|down
```

Sugar over `project add` + `objective add` (+ optional `goal add`) — stands
up a whole self-steering project namespace in one call. Bare (TTY) walks an
interactive wizard.

## Compile durable knowledge: `memory add` + hygiene

The `memory search` read-path (core) has a write twin — the CLI behind
"compile before you close." Body on stdin:

```bash
echo "$BODY" | 5dive memory add --name=hetzner-cpx-drought \
  --description="cpx line delisted post price-hike; cx dry-run false-positive" \
  --type=reference --store=wiki --tags=hetzner,capacity \
  [--valid-to=2026-12-31] [--supersedes=<slug>] [--confidence=high] [--provenance="<src>"]

5dive memory doctor --json   # hygiene: index drift, dangling [[links]], stale refs, near-dupes
```

Writes into your own store (or the shared team wiki with `--store=wiki`,
the path teammates can search), stamps provenance, and appends the store's
index line. A token/key tripwire refuses secret-shaped bodies (`--force`
does NOT bypass it). More read-path flags: `--limit=N --max-tokens=T
--roots=a,b --store=all|mine|wiki --agent=<name>` (another agent's store,
root-only).

### `--check`: a checkable fact says how to re-check itself (DIVE-3885)

```bash
... | 5dive memory add --name=<slug> --check='5dive task show DIVE-4029 | grep -q done'
... | 5dive memory add --name=<slug> --no-check="a judgement, not a measurable state"
```

`add` will not let a checkable fact skip one — supply `--check` or say why
not. `5dive memory check` re-runs them and demotes what has gone stale. Its
exit code 2 cannot distinguish a broken checker from a false fact; the
discriminator is whether the string parses (`bash -n`).

### Two-stage recall on a large store (DIVE-3821)

```bash
5dive memory search "<topic>" --index      # stage 1: slug + one-liner + score, no bodies
5dive memory get <slug> [<slug>...]        # stage 2: full bodies, only what you chose
5dive memory router --write                # rebuild MEMORY.md as a router, not a flat list
```

A flat index grows with the store and, past the ~24 KB load limit, the loader
drops its TAIL with **no error** — the oldest facts stop existing silently.
`memory router` replaces the enumeration with a recall protocol + a typed topic
map + the newest N slugs; nothing is deleted, and a
`<!-- router:keep-start/end -->` block is carried over verbatim.

An empty stage-1 result is evidence of absence; a short router is not. Search
with the words the FACT would use, not the words your task uses.

### Who compiles what

An async pass (`5dive memory consolidate`, DIVE-3628, run for you by the
heartbeat) distils FINISHED transcripts into memory atoms, so you do not have
to hand-copy facts out of a session to keep them. It cannot produce
JUDGEMENT-shaped knowledge — a wiki page, a decision record, a gap analysis,
the CAUSE behind a finding — because that is a claim you are making, not a fact
lying in the transcript. Compile those yourself, to the shared wiki, before you
close the row. **The pipeline never publishes to the wiki; only you can.**

## Read the fleet: digest, usage, supervisor

Read-only surfaces, no agent reasoning, no tokens burned. **`usage`/`cost`/
`activity` require an admin (sudo) agent** even for reads:

```bash
5dive digest --json          # standup: shipped/in-progress/gates/token burn (--7d widens)
sudo 5dive digest --send     # deliver to the paired Telegram chat
sudo 5dive digest on --at=7  # opt in to daily auto-delivery (default OFF); off | status

sudo 5dive usage --json           # board: top agents + top tasks, 24h (--7d)
sudo 5dive usage worker-1 --json  # one agent: per-model + per-task breakdown
sudo 5dive cost --json            # per-agent 24h burn vs soft/ceiling + state
sudo 5dive activity worker-1 --json    # files touched, commands run, cost (--task=DIVE-N, --7d)
sudo 5dive usage loops --json     # spend rolled up per loop / topology
sudo 5dive usage budget set worker-1 --daily=2000000 [--ceiling=<tok>] [--hard-stop]
sudo 5dive usage budget ls        # all budgets; `budget clear worker-1` removes one

sudo 5dive supervisor              # per-agent state, classification, cause, last activity
sudo 5dive supervisor --watch      # live repaint (default 5s)
```

Check `usage`/`account usage` **before** blaming quota for a failure; check
`supervisor` before restarting an agent on a hunch.

## Plugins: `5dive plugin`

Plugins are the box's optional capabilities (voice, telegram, dashboard,
buzz). Browse before installing, and prefer `disable` to `remove` when you
only want the behaviour off:

```bash
5dive market --kind=plugin                   # browse what's available
5dive plugin list --json                     # installed, with version and tier
sudo 5dive plugin add <plugin>[@<marketplace>] [--yes]
sudo 5dive plugin add <owner>/<repo>[/<plugin>] [--as=<marketplace>] [--yes]
sudo 5dive plugin setup <plugin>[@<marketplace>] [--yes]   # run its host step
sudo 5dive plugin upgrade <plugin>[@<marketplace>]
sudo 5dive plugin remove <plugin>[@<marketplace>]
sudo 5dive plugin enable|disable <plugin>    # a flag flip; the code stays on disk
sudo 5dive plugin rollback <plugin> [<version>]
sudo 5dive plugin marketplace add <local-path|owner/repo[@ref]|git-url> [--as=<name>]
sudo 5dive plugin marketplace remove <name>
5dive plugin marketplace list --json
```

Two things changed under this verb since 0.32.0:

- **`add` takes a GitHub repo directly** (DIVE-4290) — `owner/repo[/plugin]`
  registers the marketplace and installs in ONE step, so there is no longer a
  `marketplace add` then `add` dance for a repo you found on GitHub.
- **`plugin setup` runs a plugin's declared one-time host step** (DIVE-4467) so a
  host step can be run without a terminal. It reads the manifest through the
  ENABLED pointer — the version actually live on this box, never the marketplace
  source — and refuses when the plugin is disabled or declares no
  `fivedive.setup.command`. Since DIVE-4475 the step runs **as the calling seat**,
  not as root, so invoke it with `sudo` from the seat that owns the box-half.

## Is a seat actually alive? `5dive liveness` (DIVE-3778)

A process-presence check calls a wedged seat green. `liveness` grades a seat
against a **timestamped artifact it WROTE** inside a window:

```bash
5dive liveness --json                  # every registered seat + the box's own claude seat
5dive liveness --agent=<name>          # one seat (does not need the registry)
5dive liveness --window=120            # freshness window in minutes (default 60)
```

Three verdicts, and the third never collapses into the other two:

- `alive` — an artifact this seat wrote, inside the window. It is named in the output.
- `no-effect` — every probe RAN and found nothing this seat wrote in the window.
- `not-reached` — at least one probe could not run and nothing positive was
  found. **UNKNOWN, not healthy.** This is exactly the state a process check
  silently reports as fine.

Exit: `0` all alive · `4` some no-effect · `3` some not-reached · `2` usage.
Reach for `liveness` before `supervisor` when the question is "did this seat
do anything", and before restarting a seat on a hunch.

## Who can clear a gate: `5dive human` (DIVE-3342)

Gate routing resolves a person, not just a chat id. That mapping is its own
table:

```bash
5dive human ls                        # everyone on record
5dive human show <id>                 # their ids + the agents they own
5dive human owner <agent>             # resolved owner of that agent
5dive human recipient <ident>         # who a gate on THAT row would page
sudo 5dive human add <id> --name="..." --telegram=<chat id> [--buzz=<npub>] [--discord=<id>]
sudo 5dive human link <id> --agent=<name>      # they own that agent's gates
sudo 5dive human unlink <id> --agent=<name>
```

Reads need no sudo; **every write is root-only** — this table is trusted input
to gate routing. When a gate "pinged nobody", `human recipient <ident>` is the
first thing to run, not the last.

## Runs: one attempt by one agent at one task

`5dive trace` is the causal story ACROSS attempts. A **run** is the unit
beneath it — one agent's single attempt to advance one row:

```bash
5dive run ls --task=DIVE-4029 --json
5dive run ls --agent=<name> --role=maker|verifier --status=running|completed|failed|abandoned|parked
5dive run ls --since=7d --limit=50 --json
5dive run show <RUN-ID> --json
5dive run events <RUN-ID> --json
5dive run logs <RUN-ID> [--follow] [--lines=N]
5dive run retry <RUN-ID> --json
5dive run metrics --since=7d --agent=<name> --json
```

Use it when a row looks stalled but the seat looks busy: `run ls` says whether
an attempt is running, was abandoned, or never started.

## Triggers: signed external events become ordinary tasks

```bash
sudo 5dive trigger add github --name=<slug> --event=issues.labeled \
  --repo=owner/repo --assignee=<agent> --where='label.name == "5dive"' \
  --secret-from-stdin [--task-title=<title>] [--max-pending=50]

sudo 5dive trigger add webhook --name=<slug> --event=<event.type> \
  --role=<role> --secret-from-stdin [--where='actor == "service"']

5dive trigger ls
5dive trigger show <name>
5dive trigger deliveries <name> [--limit=50]
sudo 5dive trigger rotate <name> --secret-from-stdin
sudo 5dive trigger enable|disable <name>
```

The shared secret is read from **stdin** on both `add` and `rotate` — it never
enters argv. `--where` is the filter that decides which deliveries become rows;
`--max-pending` is the backstop against a loud repo filling the queue.

## The nostr handset rail: `5dive buzz`

Pairing is **per SERVER** — one QR pairs the phone as the OWNER of this box,
and that identity is wired into every buzz agent's channels:

```bash
sudo 5dive buzz pair [--timeout=<secs>] [--agent=<name>]   # prefer this form
5dive buzz owner [--envelope]        # the box's handset identity (--envelope carries a PRIVATE key)
```

Who talks in team chat is a separate, per-agent question:

```bash
sudo 5dive agent buzz enable <name> --relay=https://…  [--channels=<csv>] [--poll-ms=<n>] [--rotate-key]
5dive agent buzz status <name>       # plugin/config/binary — NOT the unit's liveness. rc 3 = declared, not usable
5dive agent buzz whois <pubkey|npub1…> [--role]   # rc 0 name · 4 MEASURED unknown · 5 ambiguous · 3 not a key · 1 registry unreadable
```

`agent buzz enable` and `status` never dial the relay, so neither is evidence
of reachability. `--rotate-key` mints a NEW identity and the handset must
re-pair.

## Hardened host remediation: `5dive host`

```bash
sudo 5dive host unit ...      # 5dive-* unit remediation
sudo 5dive host journal ...   # journal reads
sudo 5dive host cron ...      # cron surface
```

These exist so an admin agent can fix a sick host **under the CLI-root grant it
already holds**, instead of needing `NOPASSWD:ALL`. Run `sudo 5dive host --help`
for the current verb set — it is the narrowest surface here and moves most.

## Control other boxes: `5dive fleet`

A fleet registry maps box names to SSH targets (references only — never key
material):

```bash
sudo 5dive fleet add prod-2 --host=1.2.3.4 --key=/home/claude/.ssh/id_ed25519
5dive fleet ls
5dive fleet status --json          # per-box reachability + agent counts (parallel SSH)
5dive fleet agents --json          # every agent across the fleet, one view
5dive fleet send scout@prod-2 "status report please"
5dive fleet restart scout@prod-2
```

One unreachable box never fails the whole view. `add`/`rm` need root; the
read surfaces don't.

## Diagnose a sick host

```bash
sudo 5dive doctor --json
```

Envelope is always `{ ok: true, data: { summary, checks } }` with exit 0.
Branch on `data.summary.errors > 0`. Add `--fix` (alias `--repair`) to
attempt reversible fixes; `--dry-run` previews them. Narrow with
`--category=deps|types|auth|creds|registry|shelld|channels|host|memory`.

```bash
5dive selfcheck --json                # proves gate delivery, audit log, bundle integrity,
                                       # scorecard FOR REAL in an isolated sandbox
sudo 5dive agent stats --all --json   # whole fleet: unit state, restarts, health
5dive update --check --json           # is the CLI behind/stale? read-only, no root
5dive trace <id|DIVE-N>               # causal timeline: goal/parent/objective/loop -> ship -> verdict
5dive models --json                   # live model id per alias (opus/sonnet/fable/haiku)
sudo 5dive watch                      # htop-style live view (interactive TTY only)
```

Treat any `selfcheck` "not-reached" probe as "unmeasured here", not "fine".
`5dive self-update` upgrades the CLI + plugins and **restarts every agent on
the host** — never run it casually from an agent session.

## Reference

See `5dive-cli`'s `references/commands.md`, `exit-codes.md`, and `paths.md`
for full flag detail, and `sudo 5dive --help` / `sudo 5dive <noun> --help`
as the ultimate authority if a flag here is rejected.

_Synced to 5dive CLI **0.38.0** (tag `e6e132e5`, 2026-09-14)._
