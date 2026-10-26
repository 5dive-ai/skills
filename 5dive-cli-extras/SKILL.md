---
name: 5dive-cli-extras
description: >-
  Administer the local 5dive runtime beyond everyday delegation: accounts and
  auth recovery, declarative fleets and remote boxes, every seat's live screen
  at once, loops and goal DAGs,
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
  BYO-provider agents (`--provider`), multi-account auth (`5dive account`),
  moving a seat between accounts as usage fills (`agent rotation`).
- **Fleets and hosts** — declarative fleets and company templates
  (`5dive up/down/ps/export`, `team import`, roster-wide `--type=<harness>`),
  every seat's live TUI on one screen (`5dive wall`), widening an existing
  seat's grants (`agent grant`), agents on other registered boxes
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
  governance votes (`5dive council`, a plugin since it left core).
- **Health and history** — fleet health, token burn and the daily standup
  (`5dive supervisor`, `5dive usage`, `5dive digest`), machine-readable health
  checks (`5dive doctor --json`, `5dive selfcheck --json`), a task's causal
  history (`5dive trace`), the current model id per alias (`5dive models`),
  seat liveness (`5dive liveness`), gate owners (`5dive human`), one agent's
  single attempt at one task (`5dive run`).
- **Delivery and comms** — a delegated GitHub push-for-review (`5dive push`),
  Telegram/Discord pairing and shared team-bot setup, the nostr handset rail
  (`5dive buzz`, `agent buzz enable`, from the buzz plugin since 0.102.0),
  installing and rolling back plugins
  (`5dive plugin`, `5dive market --kind=plugin`).


Companion to the `5dive-cli` skill: everything on the `5dive` CLI that isn't
reached for every session. Read `5dive-cli` first for the mental model,
the `--json` output contract, and the core spawn/send/task recipes — they
apply here too and aren't repeated.

## Host lifecycle: `5dive init` and `5dive uninstall`

`5dive init` is the interactive first-run wizard for a one-agent host. It is a
human-facing bootstrap path, not the way an existing agent should add a sibling
(use `agent create` for that).

```bash
5dive init
5dive uninstall
5dive uninstall --purge --yes
```

Plain `5dive uninstall` removes 5dive. `--purge` additionally wipes its state
and user, so treat that form as destructive and require explicit human intent.

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
symlink (zip-slip + link-escape guards). Since 0.91.0 it also refuses a pack
holding a secret-shaped string (the same tripwire export runs).

**A pack is an OpenAgent agent bundle (since 0.91.0, DIVE-6202).**
`agent export --format=pack` writes the open bundle format (sha256 per member,
skill bodies under `skills/<id>/`), so `openagent import agent.tar.gz
--to=hermes|openclaw|claude-code|codex` lands it in another harness; and
`agent import` reads a bundle `openagent export` wrote, adopting its memory as
`raw`. A member whose sha256 does not match imports with a warning naming it.

**a2a vouching (since 0.90.0, DIVE-6169).** `sudo 5dive agent a2a-vouch <name>`
tells a2a.5dive.ai the agent is this box's own (did:key read from
`~/.openagent/agent.key`), so its posts skip the per-IP caps and the spam check
— never the per-agent daily cap, the leak guard or a ban. `agent import` vouches
by itself when it adopts a persona's signing key; a failed vouch only warns.

`agent clone <src> <dst>` copies an existing agent's type/config into a new
one. `--with-skills=<spec>[,<spec>...]` (bare id or `<owner/repo>:<id>`) /
`--no-skills` control what a spawned child inherits (defaults to the
`5dive-cli` skill when the caller is another agent; since 0.98.0 `--no-skills`
skips the default skills too, and the nightly skill refresh leaves that seat
alone); `--inherit-memory=<scope>`
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
sudo 5dive agent config worker-1 set chrome=on   # Claude in Chrome (DIVE-6345)
```

`chrome=on` (claude seats, since 0.93.0) turns the extension on in the box's
Chrome policy. A setup token cannot run Claude in Chrome, so the seat needs its
own claude.ai login first (`5dive browser claude connect`: one sign-in, one
Authorize tap); until then it starts as before, Chrome off, and says how to
connect. `chrome=off` puts it back on the shared token at its next restart.

Move a seat between harnesses **in place** (DIVE-5501): same name, unix user,
bot, tasks and grants; memory and instructions are converted, and the old
side's files are kept so switching back is instant.

```bash
sudo 5dive agent switch worker-1 --to=codex [--account=<account|default>]
sudo 5dive agent switch worker-1 --to=claude --no-handoff   # skip the handoff note
```

A hired (pack) agent picks up its pack's later skill, persona.yaml and CLAUDE.md
fixes with `pack-sync` (DIVE-5205, DIVE-5211) — `--dry-run` first:

```bash
sudo 5dive agent pack-sync worker-1 --dry-run
sudo 5dive agent pack-sync --all [--no-restart]
```

Since 0.99.0 (DIVE-6796) a pack skill arrives whole, with its scripts,
`references/` and `evals/`, not just `SKILL.md`. `pack-sync` (also run by the
nightly update) copies an existing agent's missing pack-skill files back in,
never overwrites a file the agent has, and reports those skills as
`backfilled`.

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
sudo 5dive account poll                  # read every Claude account's 5h/7d now (no seat turn)
sudo 5dive account show acme-prod --json # detail incl. which env keys are populated

sudo 5dive account add acme-prod         # provision empty, then sign in (TTY-only)
sudo 5dive account login acme-prod --type=claude

sudo 5dive agent set-account worker-1 acme-prod --json   # rebind + restart
sudo 5dive agent set-account worker-1 default --json     # clear the override

sudo 5dive account rename acme-prod acme-staging --json  # remove refuses while bound
sudo 5dive account remove acme-staging --json
sudo 5dive account set-active-provider acme-prod hermes openrouter --json  # hermes-only

# Move an alias-mapping account (e.g. the seeded OpenRouter one) to another
# model WITHOUT re-entering its key; re-pins its agents, restarts them when
# idle (DIVE-5259). A standard seat may switch its own account (DIVE-5367).
sudo 5dive account set-model acme-prod --model=<slug>
```

The reserved name `default` is rejected by `account add`/`rename` — at the
agent level, `auth-profile=default` means "no override, use the shared
`/etc/5dive/connectors/<type>.env`". Check `account usage` **before** blaming
quota for a failure or moving agents between accounts. A standard seat that
holds the self-account grant runs `account list` and `account usage` without
sudo, over that rail (since 0.94.0, DIVE-6430); one without it is still refused.

`account usage` used to show only what a busy seat last saw. With
`5dive config account-poll=on` (off by default; since 0.97.0, DIVE-6713) the
heartbeat reads every Claude account's 5h/7d about every 10 minutes, in no seat.
The table gains BURN/H, SEATS and the reading's age. A login the provider
refuses shows `stale` with its reason and last numbers, never 0%. Nothing
switches accounts on its own.

#### Rotation: move a seat to an account with room

A seat's **pool** is the accounts it may move between (DIVE-4416):

```bash
5dive agent rotation get worker-1                       # pool, current, cooldowns (read-only)
sudo 5dive agent rotation set worker-1 --enabled=true --accounts=acme,acme-2
sudo 5dive agent rotation set worker-1 --balance=true   # drain the pool evenly (DIVE-6106)
sudo 5dive agent rotation rotate worker-1 [--cooldown-current=<epoch>] [--require-live-headroom]
5dive agent rotation rotate <yourself> --wall=<reset-epoch>   # your own usage-limit move (DIVE-6121)
sudo 5dive agent rotation cooldown worker-1 acme --until=<epoch>
sudo 5dive agent rotation clear-cooldown worker-1 [acme]
```

`--wall` moves only to an account another live seat measures under the limit,
parks the walled one until its reset and never moves again within 30 min; with
no room the seat waits. A standard seat may run that one form on itself (the
telegram plugin's stop-failure hook does, and resumes the chat on the new
account). Balance mode moves an idle seat at a fresh task boundary when its 7d
is 15+ points above the least-used account with 5h room — at most once per 3h
per seat, once per tick fleet-wide. An account with no fresh reading gets one
live probe; an unmeasured account never counts as 0% (DIVE-6149, DIVE-6210).

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

That is for a value you already hold. To get a key FROM the owner, file a
secret gate with `--connector=tools` so they paste it through a one-time link
and every agent sees it as an env var. Never ask for it in chat. The core
skill's "Ask your owner for a key" recipe covers this.

Who may talk to the bot is governed by `access.json` (no restart needed —
the plugin re-reads per message):

```bash
sudo 5dive agent telegram-access get worker-1 --json
echo '{"dmPolicy":"allowlist","allowFrom":[1234567890],"groups":{}}' \
  | sudo 5dive agent telegram-access set worker-1
sudo 5dive agent config worker-1 set telegram.allowed-users=1234567890,5551234  # shortcut
sudo 5dive agent telegram-access groups worker-1 [--answer=name|every] [--names="Оля,Liv"]
sudo 5dive agent telegram-access seed-names [worker-1]   # add the persona card name, once
```

`groups` (since 0.96.0 to 0.98.0, DIVE-6675/6684/6729) sets how the agent answers
in its groups: when called by name (the default) or every message. `--names=`
writes EVERY name it answers to, its bot name included, and replaces the list.
An empty `--names=` leaves only an @mention or a reply. `seed-names` adds the
card name once and never re-adds one the owner removed.

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

### Widen an existing seat's grants: `agent grant`

A capability added to the sudoers template after a seat was created does not
reach it retroactively. Re-render that seat's managed policy:

```bash
sudo 5dive agent grant dev merge      # also: push | deploy — re-render a STANDARD
                                      # seat's managed sudoers from the template.
                                      # Idempotent; refuses any policy this CLI
                                      # did not write.
sudo 5dive agent grant dev root       # CONFER unrestricted root (any command, any
                                      # user) on a seat of any tier — wider than
                                      # `admin`, which is the 5dive CLI as root only.
sudo 5dive agent grant dev admin      # re-isolate to admin (DIVE-6410), from
                                      # standard OR from managed root
```

`grant root` writes a managed, visudo-checked drop-in, stamps the seat
`beyond-admin` so `agent info` stops disagreeing with the grant, and audits it.
**Since 0.94.0 it is no longer one-way:** `grant <name> admin` narrows a root
seat back, rendered exactly as `agent create --isolation=admin` renders it. It
refuses a sandboxed seat or a sudoers file the CLI did not write.

The tier a NEW seat gets is a box setting: `sudo 5dive config
seat-isolation=admin` makes every create or import that names no `--isolation`
admin (a pack manifest's tier included); `default` restores first-seat-admin,
later-seats-standard. An explicit `--isolation` always wins.

## Declarative fleets: compose + team templates

For more than a couple of agents, declare the fleet in `5dive.yaml`:

```bash
sudo 5dive up         # bring up everything declared (idempotent)
sudo 5dive ps         # declared agents' state
sudo 5dive down       # tear down declared agents
sudo 5dive export     # dump the LIVE fleet to a v2 5dive.yaml

sudo 5dive team ls
sudo 5dive team import startup --json   # bundled multi-agent company template

# every bundled template says `type: claude`. --type puts the WHOLE roster on
# one harness instead — the parsed spec is rewritten, so the create argv, the
# persona target and `ps` all agree. It overrides a per-agent `type:` too, and
# reaches the character-pack import path. Claude-only model aliases are dropped
# (and the affected agents printed) when the target is not claude.
sudo 5dive team import startup --type=codex --json
sudo 5dive up --type=codex ; sudo 5dive ps --type=codex

# A hired team ASKS FIRST (DIVE-5729): on its first start every seeded goal and
# loop is held behind one kickoff row for the lead, who sends the owner a short
# plan and waits. Answer the kickoff with these, never `task done`/`cancel`
# (both refuse while it holds work). --start-now on import keeps the old
# start-at-once behaviour; re-importing a running team never asks again.
5dive team plan [<lead>]                       # what is waiting for the yes
5dive team start [<lead>] --skip=DIVE-41,DIVE-42   # release it, minus what was dropped
5dive team decline [<lead>]                    # start none of it
# The kickoff's title is written TO the owner in their language (DIVE-6484):
# --lang=ru|en|zh on import/up, else the template's `lang:`, else the lead's
# paired chat, else English.
sudo 5dive team import startup --lang=ru --json
# A template from a file or stdin instead of the registry (DIVE-6088); a seat
# may carry a signed `pack_url:`. Every link is fetched before any agent is
# created, so one refused link leaves nothing half-made.
sudo 5dive team import acme --template=./team.yaml --json
# A team file may name its pushers (since 0.94.2, DIVE-6543): once any seat
# declares `can_push: true|false`, a seat without `true` gets no push grant.
# A pack seat also gets its template's extra skills (since 0.102.0, DIVE-6900).

# One character is one agent per box (DIVE-5769): a seat whose persona is
# already here is filled by that agent, even when he is in another team. He is
# then in both (one memory, one chat, the new role added to his instructions).
5dive team leave <team> <agent>                # out of one team, still in the others
5dive team rm <team>                           # forget a team; fires nobody (`agent rm` fires)
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

# move a project through its lifecycle:
5dive project set-status frog complete   # active | complete | archived | binned | backlogged

5dive task add "port the lexer" --project=frog --assignee=worker-1 --json
5dive task ls --project=frog --json
```

Everything else — `start`/`done`/`need`/`block`/`loop`/`heartbeat` — works
identically on a project's tasks.

## Task queue extras: park, escalate, bulk-clear, org writes

**Owner follow-ups: `task followup`.** The owner's follow-up on a row is
recorded in its body and sent to the assignee in one verb (DIVE-5507) — never
append to the body and a2a separately:

```bash
5dive task followup DIVE-123 --text="also cover the empty-list case" [--from=<who>]
```

On a `done` or `cancelled` row it no longer refuses (since 0.90.0, DIVE-6157):
it files a linked child (`--parent=<ident>`, same assignee and priority, title
"Follow-up: …", the parent's result in the body) and wakes the assignee once.
The finished row is never reopened; the JSON reply adds `child`.

**Quiet waits: `task park`.** Sleep a task without putting it in the human
inbox:

```bash
5dive task park DIVE-12 --reason="revisit after launch" --wake=+3d --json
5dive task unpark DIVE-12 --json   # wake it early
```

Both `--reason` and `--wake` are REQUIRED (no block-graveyard). If you're
actually waiting on a person, use `task need` instead; `park` also refuses
over a task with a live `task need` gate.

A row can be BORN held or parked, in the same write, so no heartbeat tick can
start it first (DIVE-5729): `task add ... --held-by=DIVE-40` (blocked behind
that row, freed when it closes) or `--park="<why>" --park-wake=+3d`.
Since 0.99.0 (DIVE-6807) `--park-wake` takes `+Nm`, `+Nh`, `+Nd` or a wall-clock
`'YYYY-MM-DD HH:MM'` read in `--tz=<zone>` (default: the box's zone). That is the
one-off reminder. A past time, `--tz` on a relative wake and `--park-wake` with
`--recurring` are refused.

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
5dive task ls --recurring --json     # list templates (each prints its zone)
# The cron is read in the BOX's time zone (since 0.85.0, DIVE-5913); --tz=<zone>
# picks another. Older templates stay UTC until moved:
5dive task set-tz <template> box     # or an IANA zone: Asia/Bangkok, UTC, ...
# No --assignee? Since 0.99.0 (DIVE-6804) the filing agent owns the template.

sudo 5dive heartbeat on worker-1 --every=30m   # default every=30m; fresh sends /clear per task
sudo 5dive heartbeat ls              # enrolled agents + next wake + queued count
# since 0.32.0: wake ONE seat for ONE row NOW, reusing the tick's own delivery
# path — how an incident row gets a grader without waiting its turn in the queue.
sudo 5dive heartbeat wake-task [--fresh|--no-fresh] <agent> <task_id> [<ident>]
sudo 5dive heartbeat off worker-1
# since 0.101.0 (DIVE-6853): the cron that runs the tick at all. install.sh and
# `agent create` add it on a self-installed box; it skips a box that has one.
sudo 5dive heartbeat install
sudo 5dive heartbeat uninstall
```

Enrolment uses the agent's short name, the same name `task --assignee`
expects. No catch-up for missed ticks — keep schedules coarse.

Since 0.93.0 (DIVE-6359) the tick also reads the OpenAgent inbox of every seat
holding `~/.openagent/agent.key` (`openagent inbox --new`, CLI 0.61.0+) and
wakes it once per batch of new DMs, each inside an UNTRUSTED block (a question
comes with its `openagent dm --re` command, an answer with "do not reply"); an
empty inbox costs no turn. Read every 5 min, then not for 30 min after a wake.
Opt one seat out with `openagentInbox: false` in the registry, the box with
`FIVE_OPENAGENT_INBOX=0`.

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

#### Score a loop by a number (DIVE-5777)

```bash
5dive task loop outcome <loop> --cmd="<command that prints one number>"
5dive task loop resume <loop>   # it pauses itself after 3 days without a rise
```

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

## Governance votes: `5dive council` (a PLUGIN, no longer core)

`council` moved out of the core CLI. On a box without it, `5dive council`
prints the move note and the one-line fix rather than a verb error:

```bash
5dive plugin add 5dive-ai/5dive-council   # then '5dive council' works exactly as before
```

Everything below is unchanged once it is installed. For decisions that should
be a recorded vote rather than one agent's call — membership motions,
constitutional amendments, or routing an open gate to a deliberation:

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
conventional-commit PR title itself** so `pr-title-lint` can pass. Two paths, and
which one you get is not only about your commits:

1. **your commit subject**, reused verbatim (with the ident appended if missing) —
   but ONLY when the range holds exactly one commit AND that subject passes the
   lint;
2. otherwise `<type>(<IDENT>): <the task's title>`, with the type derived over the
   WHOLE range (feat if any commit declares feat, else fix, else chore) so a `wip`
   first commit cannot demote a feature's release cut.

**The lint is read from the TARGET repo**, at `.github/workflows/pr-title-lint.yml`,
and a repo that has no such file fails the check by definition — so in a docs-only
repo like `5dive-ai/skills` path 1 can never fire and every delegated PR is titled
from the ROW, whatever your commit says. That is not a bug to work around; it just
means the row title is the PR title there, so write the row title you want on the PR.

Pass `--pr-title=` only to override the mint — a hand-written title that is not
conventional-commit shaped reds the lint and the PR needs a manual retitle.

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

## Publish zero-human evidence: `5dive proof`

`proof` publishes the digest-derived badge, datapoint, and history to a repo;
the scheduled form installs a daily root cron job:

```bash
5dive proof publish --dry-run
5dive proof publish --repo=<url> --branch=<branch>
5dive proof on --repo=<url> --branch=status --at=<0-23>
5dive proof off
5dive proof status --json
```

Use the dry run before first publication. `off` removes the cron configuration
but retains the saved publishing configuration.

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
sudo 5dive plugin auto-upgrade               # what self-update runs (official plugins only)
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
  `fivedive.setup.command`. **As of CLI 0.39.0** (DIVE-4475) the step runs **as the
  calling seat**, not as root, so invoke it with `sudo` from the seat that owns the
  box-half. On a box still on 0.38.0 it runs the publisher's command as root, which
  rewrites `SUDO_USER` to `root` one process later and makes the step refuse — check
  `5dive --version` before you trust this paragraph.

Since 0.91.0 a **bare `plugin add browser` installs from 5dive-ai/5dive-browser**
(DIVE-6241), not the registry's older mirror; `browser@5dive-plugins` still
names the mirror, and a box already on it keeps it. A plugin with a setup step
names that step for its packages, not `npm install` (DIVE-6112).

**`plugin upgrade` re-pins each Claude seat** (since 0.92.0, DIVE-6304) and
reports the pin it read back (`re-pinned 1.39.0 -> 1.41.0`); a seat still below
the box's version counts as failed. It does not restart seats: a seat whose
running session has the old version loaded is named with the `5dive agent
restart` that loads the new one.

Since 0.95.0 (DIVE-6650) an upgrade keeps the newest 3 versions of that plugin
and deletes the rest, never the enabled one or one an agent still pins
(`FIVEDIVE_PLUGIN_KEEP_VERSIONS` changes the count). Since 0.94.3 (DIVE-6618)
self-update runs `plugin auto-upgrade`: each official plugin moves to the
newest marketplace version, never downwards and never while disabled.
Community plugins are only reported. `update --check` lists box plugins that
are behind (`hostPluginsBehind` in `--json`).

**The devteam plugin may replace core's dev-team code** (since 0.102.1,
DIVE-6935/6959). With `devteam@5dive-plugins` installed, 5dive runs that
plugin's copy of the `gh`, `push`, `deploy`, PR-delivery and grader modules.
Only that official plugin may: it must be enabled, declare the `core`
capability and ship root-only files. Any other plugin declaring `core` is
refused at install. `5dive doctor --category=plugins` says which copy this
box runs, and `FIVEDIVE_DEVTEAM=0` skips the plugin for one run.

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

Since 0.102.0 (DIVE-6934) these commands come with the buzz plugin:
`sudo 5dive plugin install buzz` (`install` is an alias of `add`). Without it,
every buzz command answers `Buzz is a plugin now: 5dive plugin install buzz`.
Core keeps `buzz` as a channel name, and a seat's `agent send` is no longer
echoed into its buzz room.

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

## Owner asks: `5dive owner-ask` (DIVE-4982)

A browser step only the box OWNER may allow — a purchase, a login, anything
the seat must not self-approve. The browser plugin writes the request; this
verb is how it reaches a person and how the tap comes back:

```bash
5dive owner-ask browser <request-file>          # send the ask to the owner: payload,
                                                # screenshot, Approve / Decline buttons
sudo 5dive owner-ask tap <bap|bdn>:<12hex>:<32hex> --tap-uid=<telegram user id>
```

The request file is `<seat home>/.5dive/browser-approvals/<seat>-<12 hex>.json`.
`browser` writes the proof's sha256 into the request as root; with no route to
the owner it sends NOTHING and says why, exiting 0 — silence is reported, not
faked. `tap` is root-only (the team-bot listener runs it): it applies the
owner's answer through `5dive browser approve` and wakes the seat, and any
tapper who is not the owner is refused.

## Decision receipts: `5dive reflex` (DIVE-4866)

Read-only instrumentation on the decision points the CLI already makes —
receipts now, and an offline replay of a candidate model backend against them.
**Nothing here changes behaviour.** Policies: `task-route`, `retry-action`,
`stuck`, `gate-answer`.

```bash
5dive reflex status [--probe] [--json]      # receipts on/off, 24h decisions, endpoint, model
5dive reflex log [--policy=<p>] [--limit=N] [--json]
5dive reflex replay [--since=14d] [--policy=<p>] [--backend=fake:echo|fake:first|fake:recommend|<cmd>]
                    [--inputs=none|titles] [--timeout=<s>] [--dump=<file>] [--json]
5dive reflex fake [--strategy=echo|first|recommend]   # JSONL stdin -> stdout
5dive reflex report --live [--policy=gate-answer] [--since=7d] [--json]
```

`--inputs=titles` lets a replay carry task titles, gate asks/options and seat
roles — never a body; the default sends ids and labels only. Receipts are
written by the decision points themselves, so stopping them is config, not a
flag: `5dive config reflex-receipts=off` (`FIVEDIVE_REFLEX_RECEIPTS=0` in the
environment wins over that). `report --live` scores the gate-answer SHADOW
(DIVE-4916) — the configured model's pick on each new gate, recorded and never
acted on — against the answer the gate actually got, by confidence band; it
runs only on a box that set `reflex-model=` and holds the key, or a custom
`reflex-endpoint=`. The two browser drafters, `login-marker` (DIVE-4928) and
`pick-ref` (DIVE-4929), are shadow too: the code lists and verifies the
candidates, the model only picks one, and nothing is written to an adapter.
A standard seat cannot read the box's key file, so since 0.88.0 (DIVE-6115) its
`reflex status`, `pick-ref` and `login-marker` run root-side through its grant
and only the decision comes back — `status` then reads configured true.

## Hardened host remediation: `5dive host`

```bash
sudo 5dive host unit ...      # 5dive-* unit remediation
sudo 5dive host journal --unit=<u> | --comm=<process> | --grep=<text> \
     [--lines=N] [--since=2h] [--count-secrets]
                              # whole-journal search, EVERY line secret-masked;
                              # --grep matches after masking (DIVE-5842)
sudo 5dive host cron ...      # cron surface
```

These exist so an admin agent can fix a sick host **under the CLI-root grant it
already holds**, instead of needing `NOPASSWD:ALL`. Run `sudo 5dive host --help`
for the current verb set — it is the narrowest surface here and moves most.

`5dive host timezone` reads the box's zone; `sudo 5dive host timezone set
<IANA zone> [--no-restart]` changes it and restarts cron and every running
agent so they pick it up (DIVE-5165 — a partner client's box runs in the
client's clock). A no-op when the zone already matches.

`5dive sysadmin` (privileged work on a PARTNER box, each change behind the
owner's tap) **left core** for the partner plugin (DIVE-5247); core's help
only points at it.

## Work without root: publish an app, add a package, use a tool key, hire

A standard or sandboxed seat (no sudo) has its own narrow verbs for the four
things it used to ask root for (DIVE-5396). Each refuses rather than widens.

```bash
# Publish an app you already run on 127.0.0.1:<port>. Refused for a port
# nothing is listening on — start the app first.
5dive route add myapp --port=3000      # https://myapp.<box-domain>/
5dive route add /myapp --port=3000     # https://<box-domain>/myapp/ (app sees paths from /)
5dive route ls --json
5dive route rm myapp

# A system package from the box's apt repos. Install only, names only (no
# flags, versions, files or URLs), nothing is ever removed. For a CLI tool
# prefer your own no-sudo install: npm i -g / pip install / uv tool install.
5dive pkg install ffmpeg --json

# Tool keys every agent's commands see as env vars, from their next command
# on (DIVE-5366; business apps DIVE-5513). ls never prints a key; set/rm are
# root-only and read values on STDIN, one line per field.
5dive tool ls --json
printf '%s\n' "$GH_TOKEN" | sudo 5dive tool set github
sudo 5dive tool rm github
# `5dive tool help` lists every tool and the variables it fills
# (github, vercel, stripe, cloudflare, meta, elevenlabs, fal, higgsfield,
#  aws, bitrix24, amocrm, hubspot, pipedrive, notion, asana, calendly, lexoffice,
#  sevdesk, holded). Any other app: `tool set <id> --env="APP_LOGIN APP_TOKEN"`.
# Google signs in instead of taking a key — one sign-in serves every agent
# (DIVE-5934). Every google verb, and `rm google`, is root-only:
sudo 5dive tool google start                 # -> {session, state}
sudo 5dive tool google poll <session>        # state, the url to open, account when done
printf '%s\n' "$CODE" | sudo 5dive tool google submit <session>   # the code Google shows
sudo 5dive tool google cancel <session>      # or: sudo 5dive tool rm google (sign out)

# Hire: a standard seat sends its human a one-tap link; an admin seat hires
# itself with `sudo 5dive agent import <slug> --as=<name>`. Slugs: 5dive market.
5dive hire-link <slug> --json

# No catalogue agent fits the need? A lead makes a CUSTOM agent from chat
# (DIVE-5722): you write only the name and the need; the skills, role and voice
# are picked as the Mini App picks them. Making the draft hires nothing.
5dive hire-link --create --name=<Name> --description="<the need, in the owner's words>" --json
# -> prints the draft and its card link. Standard seat: show your owner the
# draft and card; they tap Hire on it. Admin seat: hire it now, then tell them:
5dive hire-link custom-<id> --hire --json

# The owner's ASK is the go-ahead, both paths (DIVE-5974, since 0.86.0 — it
# reverses DIVE-5823/5824's "a need is not a yes"). "I need someone to ..." →
# check `5dive market <words>`, and an admin seat hires its pick, then tells
# the owner who ("fire <name>" undoes it); a standard seat sends them
# `5dive hire-link <slug>`. Only a hire that needs a PLAN UPGRADE waits for a yes.

# On a PARTNER box only: hire from the partner's catalogue, same account, and
# the new agent shows in the partner's list (DIVE-5168). No root needed.
# Exit 4 = not in this partner's catalogue, 10 = not a partner box.
5dive partner hire <pack> [--as=<name>] --json
```

Two box-owner surfaces round this out:

- `5dive telegram-app link --telegram-id=<id> [--json]` — a one-time (15 min)
  link that opens the 5dive Mini App in Telegram, signed into the box owner's
  account, for that Telegram user only; the id must be in the calling seat's
  allowlist. The telegram plugin's `/app` runs it (DIVE-5185). Off box-wide
  with `5dive config telegram-app=off`.
- `sudo 5dive disk sweep [--dry-run]` deletes ONLY caches a tool rebuilds on
  its own (old Chrome temp files, npm/nvm download caches, `apt-get clean`,
  disabled snap revisions, and since 0.92.0 old Codex release dirs, leaked
  Chrome cache dirs and `pip cache purge`, DIVE-6329); `5dive disk alarm` tells the owner once at <5%
  free; `5dive disk tick` is the hourly cron driver (DIVE-5190). Never touches
  homes, projects, agent memory, transcripts, model caches or backups. Log:
  `/var/log/5dive/disk-sweep.log`.

## Every agent on one screen: `5dive wall` (DIVE-4614)

`5dive watch` is a list of seats; **`5dive wall` is the seats themselves** —
every running `claude` agent's live TUI tiled into one tmux session,
**read-only by default**.

```bash
sudo 5dive wall                  # every running claude seat, in registry order
sudo 5dive wall main dev ops     # only these seats, in this order
sudo 5dive wall --grid=4x2       # a different shape; remembered per box (needs root)
sudo 5dive wall --rebuild        # tear the layout down and lay it out again
```

Inside: `C-b d` detach (agents keep running) · `C-b z` zoom a pane ·
`C-b w` make THIS pane writable · `C-b r` back to read-only · `C-b ←→` move.

Read-only is a safety property, not a default: a stray `Ctrl-C` into an agent
pane kills that seat's unit, so `C-b w` opts **one** pane in, never the wall.
The grid defaults to 3 columns (the readable ceiling for a Claude TUI) with as
many rows as the roster needs, and a `--grid=` holding fewer panes than there
are seats is refused — a seat you cannot see is the failure the wall exists to
prevent. Spare slots stay as vacant panes so the layout does not move when a
seat is down.

A pane reaches a seat's tmux socket only as that seat's user, so the caller
must be root or hold a runas grant. Without it the wall prints NOT PERMITTED
per pane and refuses up front if no seat is reachable — it never renders a
permissions problem as a dead fleet.

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
`--category=deps|types|auth|creds|registry|shelld|channels|host|memory|mod|policy|plugins|caps|models`.

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
`update --check` reports the install receipt in the past tense — `last resolved
v<x> at <time> (from <rung>)` — and on the canary rung adds `(stale: v<y>
published since)` (since 0.92.0, DIVE-6288); doctor grades freshness against
what `update` would install, not the newest tag (DIVE-6049). `doctor
--category=registry` warns `registry/parked-running` for a seat parked in the
registry whose unit still runs — its update restart is held (since 0.93.1,
DIVE-6382): `agent stop` it if the park is real, `agent start` if stale.
`5dive self-update` upgrades the CLI + plugins and **restarts every agent on
the host** — never run it casually from an agent session.

On a self-hosted box, `sudo 5dive self-update --on` (since 0.99.0, DIVE-6799)
turns on nightly updates: an hourly timer installs a version between 01:00 and
06:00 local time, and only after 5dive's fleet has served it for 24 hours.
`--off` removes it; `5dive self-update --status` says whether it is on and what
the last run did. Every self-update also moves a seat still on a model 5dive
pinned (a current or previous default) to the bare family alias, so it follows
each Claude release (DIVE-6788). A model somebody chose is left alone.

## Reference

See `5dive-cli`'s `references/commands.md`, `exit-codes.md`, and `paths.md`
for full flag detail, and `sudo 5dive --help` / `sudo 5dive <noun> --help`
as the ultimate authority if a flag here is rejected.

_Synced to 5dive CLI **0.102.2** (commit `46c65af9`, 2026-10-26). A given box's
binary can lag by up to a day behind main (nightly update channel) — trust
`5dive --help` if they differ._
