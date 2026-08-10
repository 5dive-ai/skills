# 5dive CLI — full command reference

Every subcommand accepts `--json` as a global flag. The exact help output
on the host is authoritative; this file is the canonical reference shape.
Synced to CLI **0.19.11** (commit `35af66f`, 2026-08-10).

## Top-level

```
5dive agent      ...                 # agent CRUD + comms
5dive account    ...                 # named auth profiles (group sign-ins)
5dive market     ...                 # browse/search the agent market (no sudo)
5dive hire       <role> [--from-market]   # sugar: create a teammate (+ org slot)
5dive fire       <name>              # sugar: remove a teammate (alias of agent rm)
5dive company    [--yes] [flags]     # onboarding wizard: project + objective + goal in one shot
5dive task       ...                 # host-shared task queue (no sudo)
5dive project    add|ls|show         # ident namespaces for the queue (no sudo)
5dive goal       add "<outcome>"     # outcome -> validated, guardrailed task DAG
5dive objective  ...                 # standing target bound to a live metric, self-steers via replan
5dive council    ...                 # standalone deliberation council (governance votes, sudo for writes)
5dive constitution ...               # front door onto the machine-enforced constitution (show/init/set/edit)
5dive push       <id|DIVE-N> | setup # delegated GitHub push-for-review (needs a cleared gate + agent create --can-push)
5dive deploy     <id|DIVE-N>         # delegated PRODUCTION deploy (needs a cleared gate + agent create --can-deploy)
5dive gh         <gh args...>        # actor-routed gh: writes as 5dive-bot, admin/reads as your own credential
5dive loop       ...                 # LOOP-7 agent-native orchestration verbs
5dive org        ...                 # agent org chart (no sudo)
5dive heartbeat  ...                 # wake agents that have queued tasks
5dive memory     search|add|doctor   # queryable team memory (search/doctor no sudo)
5dive usage | cost | activity        # token burn, budgets, per-agent audit
5dive supervisor ...                 # observe-only fleet health board
5dive digest     [on|off]            # daily standup summary
5dive fleet      ...                 # register + control OTHER boxes
5dive up | down | ps | export        # declarative fleet (5dive.yaml)
5dive team import <slug|path> | team ls
5dive crew       ...                 # host a CrewAI crew (install/secret/run/show/list/uninstall)
5dive secret write <KEY> --connector=<name> [--task=<DIVE-N>]   # root-only credential drop, value on stdin
                                               # (--task clears that task's pending secret gate on a
                                               # confirmed write — the secure-drop path)
5dive gate-proof ...                 # root-only: mint human-proof nonces, enforce on|off|status, verify <id>
5dive proof      ...                 # zero-human autonomy badge publisher (on/off/status/scorecard/publish/tick)
5dive trace      <id|DIVE-N> [--json] [--no-audit]   # read-only origin/lifecycle/gate-provenance for one task
5dive ui         [--port=8735] [--host=127.0.0.1]    # local web UI: org chart, queue, gates (read-only, no sign-in)
5dive acp                            # speak ACP over stdio, spawned BY a client (Buzz, Zed) — not interactive
5dive watch [--interval=N]           # htop-style live view (interactive TTY)
5dive doctor  [--fix] [--dry-run] [--category=deps|types|auth|creds|registry|shelld|channels|host|memory]
5dive selfcheck [--json] [--only=<probe,...>] [--full] [--assume-clean] [--strict] [--allow=<probe,...>] [--report=<file>] [--label=<env>] [--list]
5dive models    [--json]             # current Claude model id per alias (opus/sonnet/fable/haiku)
5dive whoami    [--json]             # actor/authority/tier, with the SOURCE of each; exits 6 if unmeasurable
5dive bug       [--file]             # preview (default) or file a diagnostic issue against 5dive-ai/5dive
5dive --version
5dive update --check                 # read-only: behind/stale? (no root)
5dive self-update                    # upgrade CLI + plugins, RESTARTS ALL AGENTS (alias: update)
5dive uninstall [--purge] [--yes]    # remove 5dive (--purge also wipes state + user)
5dive init                           # interactive first-run wizard
5dive --help | -h | help
```

`sudo` is gated by isolation tier (DIVE-1002): only `admin` agents (first on a
box, or `--isolation=admin`) can run the root surfaces (`agent create/config/
pair`, `heartbeat on/off`, `doctor --fix`, `fleet add/rm`, `self-update`). The
no-sudo surfaces — `task`, `project`, `org`, `memory search/doctor`, `usage`,
`market`, `agent list/info`, `ui` — run from any agent.

## Agents

```
5dive agent list                              # --json carries model + effort per agent
5dive agent info <name>                       # type, CLI version, model, channel + state
5dive agent types
5dive agent create <name> --type=<type>
                          [--channels=none|telegram|discord|dashboard[,ch...]]
                          [--telegram-token=<bot-token>]
                          [--discord-token=<token>]
                          [--workdir=<path>]
                          [--auth-profile=<name>]
                          [--isolation=standard|admin|sandboxed]  # DEFAULT standard (zero sudo)
                          [--provider=<id> --api-key=<key|->]     # BYO key (hermes/openclaw/claude)
                          [--model=<slug>]                        # override BYO per-tier model defaults (DIVE-1103)
                          [--telegram-home-channel=<id>]
                          [--telegram-allowed-users=<csv>]
                          [--telegram-cos=<child-username>] [--telegram-cos-avatar=<png>]
                          [--with-skills=<spec>[,<spec>...]]      # bare id (5dive-ai/skills) or owner/repo:id
                          [--no-skills]                           # opt out (overrides agent-spawn default)
                          [--inherit-memory=<scope>]              # seed recall store: wiki | <agent> | all/team (DIVE-990)
                          [--no-team-bot]                         # opt out of shared team-bot auto-attach
                          [--defer-auth]                          # skip auth gate; first-run UI handles it
                          [--can-push]                            # DIVE-1462/STEER-4: grant delegated `5dive push`
                                                                  # (sudoers for _push_do); refused on --isolation=
                                                                  # sandboxed, no-op+warn on --isolation=admin (already
                                                                  # covered by its broad sudo)
5dive agent clone <src> <dst> [--channels=...] [--telegram-token=...]
                              [--discord-token=...] [--workdir=...]
5dive agent inspect <slug|pack.tar.gz>        # read-only install-time disclosure (no root):
                                              # shell/hooks/skills/plugins/prompt-rerender/memory-seed
5dive agent import  <slug|file.tar.gz> [--as=<name>] [--allow-hooks]
                                              # clone an exact persona; DENY-BY-DEFAULT on hooks
                                              # (--allow-hooks to keep); zip-slip + symlink guards
5dive agent start   <name>
5dive agent stop    <name>
5dive agent restart <name> [--defer]          # --defer = internal systemd-run restart (no raw grant)
5dive agent rm      <name>                    # `agent fire` / top-level `5dive fire` are aliases
5dive agent export  <name> [--with-memory] [--approve-memory=<dir>] [--out=<path>]
                                              # dump an agent to a persona pack tarball
5dive agent marketplace [ls]                  # packs published from this box
5dive agent _svc <start|stop|restart> <unit>  # scoped service lifecycle, 5dive-owned units only
                                              # (root; replaces raw systemctl in the admin sudoers — sudo-rs safe)
5dive agent stats   <name> | --all            # --all = whole fleet, incl. health hints
5dive agent logs    <name> [--follow] [--lines=N] [--tmux]
5dive agent send    <name> <text...>|--message=<text>|--message-file=<path>
                                     [--from=<sender>] [--raw] [--wake]
                                     [--reply-to-chat=<id> [--reply-to-msg=<id>]]
                                     # --message-file reads the body VERBATIM from a file (DIVE-2627) — use it
                                     # for any message that quotes CLI verbs (backticks/$() in --message=
                                     # execute as you otherwise). --wake starts a stopped agent's unit and
                                     # delivers once its prompt is up, instead of failing with exit 8.
5dive agent ask     <name> <text...>|--message=<text> [--from=<sender>] [--timeout=120]
                                     [--idle-secs=5] [--poll-secs=2] [--buffer-lines=2000]
                                     [--allow-unfenced]
                                     [--reply-to-chat=<id> [--reply-to-msg=<id>]]
                                     # --allow-unfenced restores best-effort pane-scraping for a reply that
                                     # isn't fenced (refused when --from=council*: a seat that can't fence
                                     # must surface as a capture failure, never a scraped guess)
5dive agent <name>  tui                       # attach this terminal
5dive agent install <type> [--upgrade]        # install (or, with --upgrade/--force/-u, reinstall @latest) the type's binary
5dive agent set-account <agent> <account|default>   # alias for `agent config set auth-profile=`
```

`--provider` ids (mutually exclusive with `--defer-auth`): `openrouter google
minimax moonshot huggingface anthropic deepseek qwen nous openai zai`
(hermes/openclaw). For `--type=claude` (0.8.0, DIVE-1100) only providers with
an Anthropic-compatible endpoint are valid — `openrouter deepseek moonshot
zai` — and `--auth-profile` is required (creds are profile-scoped). The CLI
pins safe per-tier model defaults; `--model=<slug>` (create) or `agent config
set model=<slug>` (later) overrides them — via OpenRouter any slug the router
serves works (DIVE-1103).

When `agent create` runs from another agent (`SUDO_USER=agent-*`) against a
claude-typed agent, `--with-skills=5dive-cli` is the default so the child
inherits inter-agent comms knowledge. `--no-skills` opts out. Where the box has
a shared team bot, new no-bot agents auto-attach (own forum topic, send-only on
the shared token) unless `--no-team-bot`.

Every `--type=codex` create (DIVE-1535) auto-seeds `~/.codex/AGENTS.md` with
the a2a return-channel convention — `5dive agent send <from> "<result>"` on
finish, since a headless codex worker only prints to its own tmux pane. Skipped
if that file already exists (never clobbers a hand-curated one).

## Hire from the agent market

```
5dive market                          # browse every pack, rarity-first (no sudo)
5dive market <keyword>                # search slug/name/tagline/role/tags/skills
5dive market search <keyword>         #   explicit alias
5dive market --role=<r>               # filter by role/character
5dive market --rarity=<tier>          # mythical | legendary | epic | rare
5dive market --seasoned               # only packs that ship pre-trained memory
5dive market show <slug>              # preview: tier, model, skills, card, DID

5dive hire <name> [--role="CTO"] [--title=...]        # blank teammate + org slot
5dive hire <role> --from-market [--as=<name>] --dry-run   # preview a real hire, PROVISION NOTHING
5dive hire <role> --from-market [--as=<name>] --yes       # provision the top match (DIVE-993)
```

`--from-market` provisions a REAL teammate and is gated (DIVE-1013): `--dry-run`
creates nothing; a TTY requires interactive `y/N`; non-interactive needs an
explicit `--yes` or it aborts after the disclosure. It runs `agent import` under
the hood — `agent inspect <slug>` first for the full disclosure.

## Config

```
5dive agent config <name> set channels=<none|telegram|discord|dashboard[,ch...]>
                                                      # dashboard = claude-only, token-free web chat
5dive agent config <name> set workdir=<path>          # "default" clears
5dive agent config <name> set auth-profile=<name>     # "default" clears
5dive agent config <name> set model=<id>              # runtime model (claude/codex/grok/antigravity);
                                                      #   BYO-provider claude takes any provider slug (DIVE-1103)
5dive agent config <name> set effort=<low|medium|high|xhigh|max>
                                                      # claude only; xhigh/max are Opus-tier
5dive agent config <name> set telegram.token=<token|->   # + channels=telegram attaches a bot post-create;
                                                      # =- reads the token from stdin (argv hygiene)
5dive agent config <name> set discord.token=<token|->
5dive agent config <name> set telegram.home-channel=<chat-id>   # hermes only
5dive agent config <name> set telegram.allowed-users=<id1,id2,...>
                                                      # seed DM allowlist, no pair-code gate
```

## Pairing & Telegram surface

```
5dive agent pair <name>                                       # returns a code; user DMs the bot
5dive agent pair <name> --code=<code>                         # paste bot reply or bare code
5dive agent pair <name> --user-id=<id> [--chat-id=<id>]       # seed access.json directly; chat_id defaults to user_id (private DM)
5dive agent telegram-discover {--token=<bot-token|->|--agent=<name>} [--poll-secs=N]
                                                              # long-poll getUpdates; returns {found, userId, chatId, ...}
5dive agent telegram-getme    --token=<bot-token|->           # getMe — {botId, username, firstName}
5dive agent telegram-info     <name> [--refresh]              # name-based getMe; caches botUsername in registry
5dive agent telegram-access get <name>                        # read access.json (DM policy, allowlist, groups)
5dive agent telegram-access set <name>                        # write access.json from JSON on stdin; live, no restart
5dive agent telegram-pending-ignore <name> <code>             # drop a pending pairing without approving
5dive agent telegram-resolve-handle <name> <@handle>          # getChat — {id, isBot, displayName}
5dive agent topic get|set <name> [--thread-id=N --chat-id=N]  # per-agent forum topic (team-bot mode)
5dive agent cos set|verify|mint-link|claim|rotate|set-avatar  # chief-of-staff child bot management
                   [--token=<tok|->] [--agent=<name>] [--avatar=<png>] [...]
```

### Shared team bot

One bot token for the whole box: agents post into one forum group (own topic
each), a root listener (`5dive-team-bot-listener`) is the sole `getUpdates`
consumer, and per-agent bridges run send-only (`TELEGRAM_SEND_ONLY`,
DIVE-1087). The listener answers gate approval-button taps itself, re-reading
the live gate first (DIVE-1093).

```
5dive agent team-bot  status|provision|shared|intercom|discover|refresh-listener --group=<chat_id> [--owner=<user_id>]
5dive agent team-group discover|provision|shared|status [--group=<chat_id>] [--agents=<csv>] [--owner=<user_id>]
```

`refresh-listener` re-materializes `/opt/5dive/team-bot-listener.ts` from the
current bundle and restarts the service (idempotent; no-op without a team
bot). `self-update` and the nightly host update call it automatically
(DIVE-1095).

`--token=-` reads the token from stdin (never argv); passing `=-` without piping
anything blocks on stdin until the caller's timeout.

## Auth (lower-level — prefer `account` for human flows)

```
5dive agent auth status [--probe] [--type=<type>]        # --probe reveals stale creds
5dive agent auth login  <type>                 # TTY only — never from a script
5dive agent auth set    <type> --api-key=<key|->
                        [--auth-profile=<name>] [--provider=<id>]   # --provider required for hermes/openclaw
5dive agent auth start  <type> [--auth-profile=<name>]   # non-TTY device-code; returns session id
5dive agent auth poll   <session_id>                     # {state, url, error}
5dive agent auth submit <session_id> --code=<callback>
5dive agent auth cancel <session_id>
5dive agent auth reap   [--ttl=<secs>] [--max-age=<secs>] [--dry-run]
                        # kill abandoned login processes (non-terminal, older than --max-age) and drop
                        # old terminal session dirs (older than --ttl); also runs opportunistically
                        # from `auth start` so the fleet self-heals without a cron entry
```

## Accounts (named auth profiles)

```
5dive account list                                   # name, types signed in, # agents bound
5dive account show   <name>                          # detail incl. envKeys present
5dive account usage                                  # per-account 5h/7d rate-limit headroom
5dive account add    <name>                          # create empty account; sign in next
5dive account login  <name> --type=<type>            # TTY-only interactive login into an account
5dive account rename <old> <new>                     # repoints + restarts every bound agent
5dive account remove <name>                          # refuses if any agents still bound
5dive account set-active-provider <profile> <type> <provider>   # flip a profile's BYO provider (hermes only)
```

The reserved name `default` is rejected by `account add` / `rename`.

Account rotation (move an agent across profiles on quota exhaustion):

```
5dive agent rotation get <agent>
5dive agent rotation set <agent> [--enabled=true|false] [--accounts=a,b,c]
5dive agent rotation rotate|cooldown|clear-cooldown <agent> [...]
```

## Skills

```
5dive agent skill <name> add  --source=<owner/repo> --skill=<id>
5dive agent skill <name> list
5dive agent skill <name> rm   <skill-id>
```

## Compose (declarative agents via 5dive.yaml)

```
5dive up   [-f file]                 # bring up declared agents (idempotent)
5dive down [-f file]                 # tear down declared agents
5dive ps   [-f file]                 # declared agents' state
5dive export [-o file]               # dump the live fleet to a v2 5dive.yaml
5dive team import <slug|path> [--auth-profile=<name>]   # provision a whole team template
5dive team ls                        # bundled templates
```

Default file: `5dive.yaml` / `5dive.yml` in cwd. Per-agent spec keys:
`type, channels, telegram_token, discord_token, workdir, skills, no_skills,
defer_auth, isolation, auth_profile, provider, api_key`. Strings expand
`${ENV_VAR}` from the process env; missing vars fail loudly.

## Crew (host a CrewAI crew — DIVE-787)

```
5dive crew install <git-url> --as=<name> [--entry=<module:Crew>]   # own venv on the box
5dive crew secret set <name> KEY=VALUE [KEY=VALUE ...]             # BYO LLM key, owner-600
5dive crew run <name>                                              # co-signed receipt per run
5dive crew show <name> | list | uninstall <name>
```

Durable memory persists on the box disk (`CREWAI_STORAGE_DIR`).

## Tasks (shared queue)

Host-shared task queue at `/var/lib/5dive/tasks/tasks.db` (sqlite, WAL). The
store is group-writable, so every `agent-*` user can read/write **without
sudo**. Tasks get a `DIVE-N` ident (or a project prefix); statuses are
`todo | in_progress | blocked | done | cancelled`.

```
5dive task add <title...> [--body=<text>] [--priority=low|medium|high|urgent]
               [--assignee=<agent|role:<r>|charter:<kw>>]   # token routes via the org chart (DIVE-980);
                                                            #   omit = org lead/coordinator
               [--parent=<id|DIVE-N>] [--project=<key>] [--from=<who>]
               [--recurring="<cron>"]        # 5-field cron — creates a recurring TEMPLATE
               [--task-budget=<tokens|$cost>] # per-run spend cap for the on-host loop (DIVE-824)
               [--verifier=<agent>] [--accept=<criteria>] [--verify=<cmd>] [--max-iters=<n>] [--no-verify]
               [--branch=<name>]              # seed a 'Branch: <name>' delegated-push binding (DIVE-1697)
5dive task ls   [--status=<s>] [--assignee=<agent>] [--mine] [--all] [--recurring] [--project=<key>]
                                             # default: open, priority-ordered; --recurring lists only
                                             #   templates the scheduler still drives (schedule set,
                                             #   status=todo); --recurring --all lists every template
                                             #   regardless (DIVE-2055)
5dive task show <id|DIVE-N>                  # detail + subtasks + blockers
5dive task assign <id|DIVE-N> <agent>
5dive task verifier <id|DIVE-N> <agent> [--accept=<criteria>] [--max-iters=<n>]
                                             # DIVE-1880: attach the maker→verifier rail to an
                                             # already-filed task (grader must ≠ maker). One-way —
                                             # no --none/--clear to detach; opting out stays add-time
5dive task set-branch <id|DIVE-N> <branch>   # DIVE-1462/1697: bind the task to a git branch for
                                             # delegated push; writes/updates a 'Branch: <name>' body line
5dive task set-title <id|DIVE-N> <text...>          # rename (single line, <=200 chars); refused once done/cancelled
5dive task set-body <id|DIVE-N> <text...> [--append]
                                             # DIVE-1920: edit a task's body after creation. Default
                                             # OVERWRITES the body; --append tacks text on (blank-line
                                             # separated). Works on recurring templates; refused once
                                             # the task is done/cancelled
5dive task start  <id|DIVE-N>                # -> in_progress
5dive task done   <id|DIVE-N> [--result=<text>] [--force-merge-gate] [--keep-worktree]
                                             # -> done (or HANDS OFF to grader if verified); result = owner ping
5dive task deliver <id|DIVE-N> --pr=<url> [--result=<text>]
                                             # DIVE-1830: maker records the delivery PR + hands off to the
                                             # verifier; 'task done' now stays BLOCKED until that PR is
                                             # MERGED and green (see merge-gate note below)
5dive task cancel <id|DIVE-N> [--result=<text>] [--keep-worktree]   # -> cancelled; --result captures why
5dive task verify <id|DIVE-N> [--cmd="<cmd>"] [--no-done] [--timeout=<s>]
                                             # run a check; exit 0 => proven-done (flips to done)
5dive task reject <id|DIVE-N> [--feedback="<what to fix>"]   # verifier FAIL: bounce to maker; escalate at max-iters
5dive task merge-audit [--limit=N] [--json]  # DIVE-1935: retrospective, READ-ONLY sweep of DONE tasks
                                             # for a named PR that never merged (or merged red); never reopens
5dive task reclaim <id|DIVE-N>|--all [--dry-run]
                                             # DIVE-1967: reclaim node_modules from closed tasks' worktrees
                                             # (gitignored, npm-ci-regenerable — data-loss-free). --all skips
                                             # any worktree whose task is in_progress/blocked
5dive task block   <id|DIVE-N> --by=<id|DIVE-N>   # add a blocks edge, mark blocked
5dive task unblock <id|DIVE-N> [--by=<id|DIVE-N>] # drop edge(s); back to todo if clear
5dive task park   <id|DIVE-N> --reason="..." --wake=<YYYY-MM-DD[ HH:MM]|+Nd|+Nh>  # QUIET wait (no ping/inbox)
5dive task unpark <id|DIVE-N>                # clear a park early -> todo (unless deps still block)
5dive task rm <id|DIVE-N>                    # delete (cascades subtasks + edges)
5dive task coordinator [--json]              # print the resolved org coordinator (DIVE-333/1568):
                                             #   sole role=coordinator, else the lone org root, else
                                             #   empty on ambiguity — callers must treat empty as "nobody pins"
5dive task gate-escalate <ident>             # root-only, internal: re-send a pending gate's alert from a
                                             # privileged context when its filer itself has no paired
                                             # channel (DIVE-1927/1968); not a normal agent workflow verb
```

**`park --wake` is REQUIRED, not optional** (fail-closed since DIVE-1357, so a
park can't rot with no revisit date): `--reason=` is required too. Accepts
`+Nd` / `+Nh` or an absolute `YYYY-MM-DD[ HH:MM]`. `park` refuses to run over a
task that already has a live, unanswered `task need` gate — answer the gate
first (DIVE-1453; parking over it would silently destroy the gate with no
audit trail).

**Verification is ON by default (DIVE-969):** a non-trivial `task add` derives
acceptance criteria and assigns a grader ≠ maker, so a plain `task done` HANDS
OFF to grade instead of closing. Trivial/low-priority/recurring tasks auto-skip;
`--no-verify` opts out and `FIVE_VERIFY_DEFAULT=0` is a fleet kill-switch.
Writer ≠ grader is the whole point — never set `--verifier` to the assignee.

**A delivered loop is durable against its own maker (DIVE-2007):** once a
task is handed to its verifier, `task done` from anyone but that verifier is
refused outright — even a second `task done` from the *maker*. To amend a
delivered result, send the correction to the verifier and let them fold it
in; don't re-run `done`. Real exits mid-review: `task reject` (verifier
bounces it back), `task verify --cmd=` (evidence-backed close), or `task
cancel` (abandon). `task verifier <id> <agent>` is the retrofit for a task
that was filed *without* the rail (either `--no-verify` or the DIVE-969
auto-skip for low-priority/chore titles) — it can also re-point an
already-in-review handoff to a different grader (moves the queue, re-stamps
the delivery clock, leaves the maker and iteration count untouched). There is
no way to detach a verifier once attached; only add-time `--no-verify` opts
out.

**Merge-gate (DIVE-1830/1835/1935/1955/1965): `done` means merged-to-main,
not "PR opened."** Once a task carries a *declared* delivery binding —
either a `delivery_ref` (set by `task deliver --pr=<url>`) or a `Branch:
<name>` body line (set by `task set-branch` / `task add --branch=`) — `task
done` refuses to close until `gh` confirms that PR is **MERGED and its
checks are not RED** (a merged-but-failing PR is refused too). Even with
*no* declared binding, a second, *mandatory* auto-detect gate still runs on
every close: it scans open PRs across every repo in `FIVE_GATE_REPOS`
(default: the CLI repo, `lodar/5dive-api`, `lodar/5dive-frontend`) for a
title/branch naming the task's ident, and separately greps the close's own
`--result`/body text for PR references the text asserts were *delivered*
(a shipping verb like "merged as #6", or a `Delivered:` line — a PR merely
*cited* in passing, e.g. in a review/triage close, is deliberately not
checked). `task deliver` is the opt-in half: it's the maker's own act of
declaring "this is what I shipped," and it hands off to the verifier exactly
like `task done` would (DIVE-477) except it does **not** close — if there's
no distinct verifier, the delivery is recorded but the task stays
`in_progress` until a verifier confirms the merge and closes it themselves.
A bare `#N` PR reference (no full URL, no `Repo: <owner>/<repo>` body line)
only resolves when it's unambiguous across the known repos — otherwise the
gate reports `ambiguous` rather than guess, since repo numbering collides.
When the gate genuinely can't reach a verdict (no `gh` token, a broken
parser, a partial repo scan), the close still proceeds but the stored result
is stamped `[merge-gate: UNVERIFIED — …]` rather than looking silently
clean. `--force-merge-gate` is the audited escape hatch for any of these
refusals (a flaky post-merge CI run, etc.) — it's logged, and the leftover
unmerged PR still surfaces in the weekly branch-hygiene digest. `task
merge-audit [--limit=N] [--json]` is the read-only retrospective version of
this same check, run over already-DONE tasks across every `FIVE_GATE_REPOS`
repo — it only reports, it never reopens anything.

**A close reclaims worktree disk (DIVE-1966/1967):** `task done`/`task
cancel` automatically deletes `node_modules` (gitignored, `npm ci`
-regenerable, so provably data-loss-free) from that task's worktree(s) unless
you pass `--keep-worktree`. The worktree *directory* itself is never
deleted — it may hold unpushed commits, so `task reclaim` only ever reports
on that, never prunes it. `task reclaim <id|DIVE-N>|--all [--dry-run]` runs
the same sweep manually and, with `--all`, skips any worktree whose task is
still `in_progress`/`blocked`. Env kill-switch: `FIVEDIVE_NO_WT_RECLAIM=1`.

`task set-body <id|DIVE-N> <text...> [--append]` (DIVE-1920) is the only
route to edit a body after `task add` — a direct DB edit isn't available to
scoped-sudo makers. It's audited (actor, overwrite-vs-append, prior body
length) and refuses on a closed (done/cancelled) task; bounce it back with
`task reject` first if it needs one.

### Human Task Inbox — park a question on a human

```
5dive task need <id|DIVE-N> --type=decision|secret|approval|manual|access
                --ask="..." [--options=A|B] [--recommend="A"] [--tier=0|1|2]
                [--secret-key=<ENV_VAR> --connector=<name>]   # type=secret only, together
                [--probe=<cmd>]                               # type=access only
                                             # -> blocked, awaiting a human; risk-tiered
5dive task need <id|DIVE-N> --withdraw       # DIVE-1401: cancel a still-pending gate the team itself
                                             # filed but that's now moot — filer, their lead/coordinator,
                                             # or a genuine human, no tap required
5dive task inbox                             # ONLY human-gated tasks, priority-ordered
5dive task inbox --send [--channel-proof=<chat>]
                                             # root-only: DM the owner ONE tap-button digest
                                             # of up to 10 pending gates (fresh per-gate nonce,
                                             # never exposed via --json; rotates old buttons dead)
5dive task answer <id|DIVE-N> --value="..."  # record answer, unblock, ping the owning agent
5dive task clear-recs --channel-proof=<chat_id> [--only=<id|DIVE-N>] [--from=<who>]
                                             # DIVE-1305: paired-human bulk-clear — apply every
                                             # eligible gate's own --recommend as a HUMAN clear
                                             # (unanswered, blocked, tier<2, has a --recommend,
                                             # NOT lead-routed); each clear goes through the normal
                                             # `task answer` path, so provenance matches a real tap
```

`--ask` is ONE crisp question (+~1 line context, recommendation up front); heavy
detail goes in the task BODY. `--recommend` is strongly encouraged (for a
decision it must match one of `--options`). Gate tiers: T0 auto / T1 48h
auto-apply the recommendation / T2 hard floor. An agent can `task answer` only
a **decision** gate — `approval`/`secret`/`manual`/`access` are HUMAN-ONLY
(enforcement ON): they clear via a Telegram tap (per-gate `--human-proof` nonce,
minted as root) or a non-agent `SUDO_UID`, never a bare agent-session `task
answer`.

`--type=access` (DIVE-1243) is for "I'm blocked on a permission/grant I don't
have." Pair it with `--probe=<cmd>` — a self-check that MUST currently fail
(non-zero exit); if it succeeds the gate is refused ("you already have this
access; not filing") so a stale block can't waste a human ping. Without
`--probe` the gate still files, just with a warning to confirm you actually
tested the block.

`--withdraw` (DIVE-1401) cancels a gate that's still pending
(`need_answered_at IS NULL`) — it's the antidote to filing an `access`/
`secret`/`approval` gate that turned out to be moot. It is **not** a grant:
it never writes `need_answer`/`need_answered_at`, so no secret or approval is
ever recorded as provided — which is why it's safe to allow without a human
tap. Authorized callers are the gate's filer, the filer's routed lead/org
coordinator, or a genuine human caller — resolved from the trusted `EUID`/
`SUDO_USER` chain (or the real unix login for a non-root caller), **never**
from `--from`, which is caller-asserted and forgeable. Genuine grant-clears
still go exclusively through `task answer`.

Precedent prefill (OSS-11/DIVE-976): a gate filed with a blank `--recommend`
gets its recommendation prefilled from the closest matching answered precedent
(same type + ask shape, equal-or-higher tier, ≤90 days) and the alert cites it.
Never mutates the tier or the clear path; never overrides an explicit rec.

### Recurring templates

A task created with `--recurring="<cron>"` is an inert template (excluded from
default `ls`, heartbeat, inbox). The heartbeat tick materializes it into a
standard todo when the cron matches, skipping if a prior instance is still open.
Templates default to `fresh` (worker `/clear`s first). No catch-up for missed
ticks — keep schedules coarse. Turn a recurring loop off by `task rm`-ing the
template.

### Loops — relay work across agents (+ maker→verifier review)

```
# Relay loop: each step auto-hands-off to the next on `task done`; a gate pauses for a human.
5dive task loop start --title=<name> --steps=<json>   # --steps = JSON array; each item is:
            #   {"agent":"<name>","label":"...","handoff":"..."}  work step (handoff optional)
            #   {"gate":"approval","label":"..."}                 human approval gate
            # [--project=<key>] [--owner=<agent>] [--from=<who>]
5dive task loop ls [--all]                            # board of loop runs: step progress + status
# Edit a running loop = act on its subtasks (task ls/assign/block/unblock/rm, slip in a task need gate).
# Stop it = `task rm` the run parent (cascades to the steps).

5dive task loops [--stuck] [--all] [--escalate-stuck] [--runs] [--watch[=secs]] [--kill <loopId>]
            # observability board (DIVE-478/597): maker→verifier loops + the LOOP-7 loop_runs
            # control window (topology/stage/iter/tokens-vs-ceiling/status/⚠stuck).
            # --runs = only loop_runs; --watch repaints; --kill flips kill_requested (deferred-safe).
```

`task init` is a one-time root bootstrap run at provision time — agents never
call it. `--from` defaults to your `agent-*` name (or `SUDO_USER` under sudo).

## Projects (ident namespaces for the queue)

```
5dive project add <key> --prefix=FROG [--name=<text>] [--goal=<text>]
                        [--folder=<path>] [--lead-agent=<agent>]   # prefix defaults to upper(key)
5dive project ls
5dive project show <key>                     # detail + the task_deps graph (topological layers, critical path)
```

Tasks filed with `--project=<key>` number per project (`FROG-1`, `FROG-2`, …).
Default project `dive` = `DIVE-N`.

## Goals (outcome → guardrailed task graph)

```
5dive goal add "<outcome>"
     [--project=<key>]      # else derive a key/prefix from the outcome
     [--planner=<agent>]    # default: project lead_agent, else org coordinator
     [--max-tasks=N]        # hard plan-size cap (default 12; over -> reject)
     [--depth-cap=N]        # hard dep-DAG depth cap (default 5)
     [--checkpoint=K]       # > K tasks -> human checkpoint (default 6)
     [--ceiling=<tokens>]   # planner budget (default 40000)
     [--dry-run]            # plan + render, create NOTHING
     [--yes]                # waive the COUNT checkpoint (a T2 plan still gates)
     [--plan=<json>]        # supply a plan directly (skip the planner)
     [--from-gate=<id>]     # materialize a plan a HUMAN answered 'approve' (only T2 path)
     [--from=<who>]
```

A plan is validated (DAG acyclicity, size/depth caps, tier-floor,
assignability) BEFORE anything is created. Over the checkpoint threshold or
carrying any Tier-2 task, ONE decision gate holds the plan and nothing
materializes until a human approves. Always `--dry-run` first.

## Objectives (standing goal bound to a live metric)

```
5dive objective add "<outcome>" --metric-cmd="<read-only cmd>" --target=<n>
                    --direction=up|down [--unit=<u>] [--public] [--planner=<agent>]
                    [--review="<cron>"] [--max-new-per-cycle=<n>]
5dive objective ls | show <name> | status|dash <name> | live <name> | shadow <name>
5dive objective tick [<name>]                # re-measure the metric now
5dive objective pause  <name>                # stop measurement/replanning (always allowed)
5dive objective resume <name> [--force]      # restart; --force bypasses an OSS-33 preflight
                                             #   refusal (planner role can't currently do the work)
5dive objective rm <name>

5dive objective replan <name> [--planner=<agent>] [--max-new-per-cycle=N]
                       [--checkpoint=N] [--depth-cap=N] [--ceiling=<tok>] [--wait=<secs>]
                       [--no-progress-limit=N] [--dry-run] [--yes] [--force]
                       [--propose-only|--shadow] [--diff=<json>] [--from-gate=<id>] [--from=<who>]
```

`replan` (OSS-27/OSS-33) drives one self-steering cycle: a planner proposes a
diff (new/reprioritized/cancelled tasks) toward the metric target, validated
the same way `goal add` validates a plan. `--yes` waives ONLY the
count-over-`--checkpoint` gate — never a diff containing a Tier-2 task, and
never anything under `--propose-only`/`--shadow` (forced when `run_mode` is
`shadow`; the WHOLE diff gates then, unwaivable). `--no-progress-limit=N`
auto-pauses the objective after N flat/adverse cycles (`0` = off). `--force`
overrides a preflight refusal (also usable on `resume`). `--from-gate=<id>`
applies a diff a human already approved on a prior gate; `--diff=<json>`
supplies a manual diff instead of invoking the planner.

## Council (standalone deliberation council — governance votes)

```
sudo 5dive council init --seats=<a:chair,b,c,...> --threshold=<majority|all|N|a/b> --veto=<principal>
                                             # human-seed the primary Council ONCE (fail-closed if
                                             # already init'd; --force re-seeds, logged in lineage)
5dive council lineage [verify|ls]            # verify the sealed hash-chain, or list it
5dive council roster                         # live seats, threshold/quorum, veto holder, lineage head
5dive council log [--limit=N]                # sealed verdict history (genesis + every motion + vetoes)
5dive council record [--json]                # per-seat track record: votes scored vs REAL task outcomes
5dive council amend --file=<new 5dive.md> [--dry-run]
                                             # constitutional-class motion (2/3 + full quorum + veto);
                                             # only swaps 5dive.md on a PASS, digest-sealed not file-authority
5dive council verify [<receipt-digest>]      # whole-lineage integrity + constitution-drift check

5dive council convene "<question>" [--seats=a,b,c] [--mode=quick|deliberate|adversarial]
                                   [--bench=<name>] [--class=<decisionClass>] [--threshold=<n>]
                                   [--timeout=120] [--idle-secs=5] [--poll-secs=2] [--standalone]
                                             # dispatches to real seated agents by DEFAULT (each
                                             # votes via its own harness over `agent ask`, blind
                                             # first round); --standalone uses the single-key
                                             # modelCall seam instead. A primary-Council PASS
                                             # offers the founder veto (non-blocking, one-time nonce).
sudo 5dive council {promote|demote|expel} --subject=<seat> [--lens="..."] [--mode=...] [--dry-run]
                                             # membership motion as a convened vote; subject recuses;
                                             # class auto-derived (promote=majority, demote/expel=2/3)
5dive council veto exercise --receipt=<digest> --nonce=<tap nonce> [--tier=hold|posthoc] [--reason=...]
                                             # the authenticated founder-veto tap on a sealed pass
5dive council sign-vote --seat=<id> --vote=approve|reject|escalate|abstain --convene=<id>
                       (--qdigest=<hex>|--question=<text>) --key-file=<PEM|-> [--rationale=...] [--emit=line|json]
                                             # a seat signs its own vote at source (sign-at-source);
                                             # emits the COUNCIL-SIG: line pasted after COUNCIL-VOTE
5dive council verify-votes --votes=<json|@file> --roster=<json|@file> --convene=<id>
                           (--qdigest=<hex>|--question=<text>)
                                             # re-check every co-signed vote vs roster pubkeys +
                                             # revocation; non-zero exit if any is unsigned/forged/replayed

5dive council bench ls | show <name>
5dive council bench add <name> --seats=a:lens|b:lens [--mode=] [--threshold=] [--desc=]  # sudo
5dive council bench rm  <name>                                                          # sudo
                                             # built-ins council/ship/brand/security; `council`
                                             # itself is refused (seats change only via promote/demote)
5dive council schedule add <name> --question="<template>" --cron="<m h dom mon dow>"
                                   [--bench=<name>] [--mode=quick|deliberate|adversarial]
                                   [--class=<c>] [--max-actions=N] [--ballot-deadline=<secs>]
                                   [--context-cmd="<sh>"] [--no-cron]
5dive council schedule ls | show <name> | rm <name>
5dive council schedule run <name> [--dry]
                                             # productize a recurring convene (CNCL-23): `add` binds
                                             # a named question template to a cron expression and
                                             # installs a managed crontab line (rides the EXISTING
                                             # cron rail — NO daemon; --no-cron just saves the config
                                             # and prints the line instead). The template may embed
                                             # {{date}}/{{context}}; --context-cmd is a shell snippet
                                             # run at each fire whose (bounded) stdout fills {{context}}.
                                             # `run <name>` is what cron actually invokes: gathers
                                             # context, convenes on the DEFAULT ballot rail (no
                                             # pane-scrape, CNCL-18 — convene seals its own receipt
                                             # into the lineage), then files up to --max-actions
                                             # ACTION: items from seat rationales as --from=council
                                             # board tasks. An inquorate or failed run is a CNCL-18
                                             # signal, never fatal (exit 0). `add`/`rm` write the
                                             # root-owned schedules.json — run under sudo.
5dive council gate-clear <task|DIVE-N> [--mode=deliberate] [--seats=a,b,c] [--dry-run]
                                             # route an OPEN tier-1 gate to the council; a tier>=2 or
                                             # human-only type is NEVER self-cleared, always bumped
5dive council rot-triage [<task|DIVE-N>|--all] [--older-than-hours=48] [--dry-run]
                                             # re-brief a stale unanswered tier-2 gate sharper for
                                             # the human; NEVER clears it (tier-2 stays human-only)
```

A veto can never be asserted from a CLI string — `convene --veto-by=...` is a
detected forge-attempt and refused with exit 9. `--json` is a global flag here
too. The default `convene` dispatch path needs no model key (each seat uses
its own harness); `--standalone` uses `COUNCIL_API_KEY`/`COUNCIL_BASE_URL`;
`COUNCIL_MOCK=1` runs a deterministic offline council for tests/smoke.

A schedule's crontab line is keyed by a `# 5dive-council-schedule:<name>`
marker, so `add` (re-running it updates in place) and `rm` are idempotent —
install/remove only ever touches that one line, never duplicating or
clobbering unrelated cron entries. `add`/`rm` require write access to the
root-owned council dir (schedules.json), so they need `sudo`; `ls`/`show`/
`run` don't. `run <name>` (what cron actually calls) never fails the cron job
itself: a failed convene, or a quorate-but-inquorate verdict, both log to
`<name>.log` and return exit 0 (CNCL-18 signal, not an error) with no tasks
filed; only a quorate PASS files up to `--max-actions` `ACTION:`-prefixed
board tasks via a real `5dive task add --from=council`, each stamped with the
sealed receipt digest for traceability. `--dry` runs the same pipeline but
prints the `task add` invocations instead of executing them. A `schedule
render <name>` action also exists in the dispatch, but it's internal-only
plumbing that `run` calls to resolve `{{date}}`/`{{context}}` into the final
question — it's not listed in `council --help` and has no standalone use case.

## Constitution (machine-enforced guardrails — DIVE-1742)

```
5dive constitution show [--json]                        # read-only: hard_gates, ship/comms, thresholds,
                                                         # veto, sealed vs live digest, drift + verify status
sudo 5dive constitution init [--force] [--json]         # seed a fresh guardrails-only constitution.yaml
                                                         # (Council keys present but dormant); unsealed
echo '{"hard_gates":{...}}' | sudo 5dive constitution set --json
                                                         # dashboard EDIT contract: JSON patch on stdin,
                                                         # merged + re-serialized + validated server-side
sudo 5dive constitution set --file=<constitution.yaml> [--principal=<human:agent|tg:id>] [--dry-run] [--json]
sudo 5dive constitution edit [--json]                   # open in $EDITOR, seal the edited bytes on save
```

A solo-user-friendly front door onto the same sealed guardrails a Council
governs. `show` is the read-only envelope the dashboard consumes instead of
parsing `constitution.yaml` itself; only `hard_gates`/`ship`/`comms` are
settable through `set` — governance keys (council/quorum/veto/thresholds) are
unreachable here and only move via `council amend`. Write paths route by
mode: a real multi-seat Council governs → a constitutional amendment (2/3 +
full quorum + founder veto); otherwise a single-principal direct-seal (no
convene, no quorum). A later hand-edit of the file drifts from the sealed
digest and fails closed (DIVE-1695).

## Company (onboarding wizard)

```
5dive company [--yes] [--name=<company>] [--key=<slug>] [--prefix=<UPPER>]
              [--objective="<outcome>"] [--metric-cmd="<cmd>"] [--target=<n>]
              [--direction=up|down] [--unit=<u>] [--planner=<agent>]
              [--review="<cron>"] [--max-new-per-cycle=<n>] [--goal="<outcome>"]
```

Thin sugar over `project add` + `objective add` + (optionally) `goal add`: one
call stands up a project namespace, an objective bound to a metric, and a
re-plan cadence. Bare (TTY, no `--yes`) walks an interactive wizard; otherwise
`--yes`/`-y` requires `--name`, `--objective`, `--metric-cmd` and uses
flags/defaults for the rest — fails if neither a TTY nor `--yes` is present.

## Push (delegated GitHub push-for-review)

```
5dive push <id|DIVE-N> [--branch=<b>] [--repo=<url>] [--dry-run] [--yes|-y]
5dive push <id|DIVE-N> --open-pr[=<base>] [--pr-title=<t>] [--pr-body-file=<f>] [--pr-draft]
sudo 5dive push setup [--author="Name <email>"]
```

Pushes ONE named feature branch for PR review (never `main`/`master`/`HEAD`,
never a merge) — the agent process itself never touches a token. Requires the
task's gate to be cleared by a human or a designated lead AND bound to the
branch being pushed (DIVE-1462); a root-only helper then mints a
GitHub-App-installation token scoped to just that repo, pushes, and discards
it. Needs `agent create --can-push` on the calling agent (see Agents, above).
`push setup` (root) scaffolds the App env file / checks for the private key
and reports readiness — never pass the key itself on argv.

`--open-pr[=<base>]` (DIVE-2605) opens the pull request on the same root-side
rail immediately after the push, as `5dive-bot`; `<base>` overrides the
default base branch. `--pr-title`/`--pr-body-file`/`--pr-draft` shape that PR
and are refused with a usage error if passed without `--open-pr` (a body you
think you attached but that silently did nothing). `--pr-body-file` reads the
body from a file, not argv/a quoted string. `--yes`/`-y` is accepted (does not
error) but as of this sync isn't read anywhere past argument parsing — treat
it as a no-op, not a confirmation bypass.

## Deploy (delegated PRODUCTION deploy — INST-5)

```
5dive deploy <id|DIVE-N> [--target=<project@ref>] [--env=production|preview] [--dry-run]
```

Same gate → bind → root-only-executor shape as `push`, generalized to a
production deploy. Needs the task's gate cleared AND bound to the target
(`Deploy: <project>@<ref>` line in the task body, or `--target` — a flag that
disagrees with the task's own line is refused, never silently overridden).
The repo deployed is **not a parameter**: it's read from the named Vercel
project's own GitHub link, so a granted agent can point at an already-linked
project/ref but never redirect it to a repo of its choosing. The credential
(`VERCEL_TOKEN`) is read root-only inside `_deploy_do` and never held by the
agent process. Requires `agent create --can-deploy` on the calling agent
(separate axis from `--can-push` — shipping a reviewable branch and pushing
it to production are different capabilities). `--dry-run` previews (gate +
target-binding checks only, no deploy, no privilege needed beyond reading the
task).

## Proof (zero-human autonomy badge — OSS-17/OSS-38)

```
5dive proof on --repo=<url> [--branch=status] [--at=<0-23>] [--user=<u>]
               [--as-name=<name> --as-email=<email>]
5dive proof off
5dive proof status [--json]
5dive proof scorecard [--json] [--7d] [--by=tier|class]   # LOCAL multi-dim metrics by risk tier
5dive proof publish [--dry-run] [--repo=<url>] [--branch=<b>]
5dive proof tick                                            # cron driver; gated on the on/off pref
```

Publishes a daily public "zero-human" status badge/scorecard to a repo,
answering "how much of what shipped needed a human?" from real task-outcome
data (not self-report). `on` installs an idempotent daily cron (`proof tick`)
gated by a per-box preference (`${STATE_DIR}/proof.json`); `off` removes it.
`scorecard` is the read-only local metrics view (`--by=tier` is the only
grouping that actually varies output — `--by=class` was planned but never
wired, so it silently falls back to the same tier grouping).

**`publish`/`on` refuse without a resolved git identity (DIVE-2051) — exit
code 4, distinct from the healthy-no-op exit 3.** Identity resolves in order:
(1) `ZH_GIT_NAME`/`ZH_GIT_EMAIL` env, per-invocation; (2)
`proof.json .identity.{name,email}`, set via `proof on --as-name=
--as-email=` (both required together, email format-validated); (3) the
publishing user's own git config. `--user=<u>` on `proof on` resolves layer 3
AS that user, not the caller — a cron-ownership trap if you pin the wrong
one. **The very first `publish` is gated behind an explicit approval task
filed to lodar** (emitting a public brand/comms artifact), cached once
approved via a verifiable human-tap nonce — a plain `task answer` doesn't
satisfy it. Nothing publishes silently: every refusal path (no identity, no
approval, approval declined, state-write failure after a successful push)
prints its own loud reason rather than degrading to a stale "last published:
never".

## LOOP-7 (agent-native orchestration verbs)

JSON in / JSON out; each verb spawns/grades agents directly and honors
`--ceiling` (per-loop token budget; self-halt + escalate-with-proof at the
limit). Humans watch/kill via `task loops --kill <loopId>`; they never author a
loop.

```
5dive loop spawn  --role=maker|verifier|worker --agent=<type|name> --prompt="…"
                  [--schema=<json>] [--ceiling=<tokens>] [--wait[=<sec>]]
5dive loop verify --target=<id> --verifier=<agent> [--accept="…"]
5dive loop grade  --target=<id> --verifier=<agent> [--accept="…"] [--threshold=<0-100>] [--wait]
5dive loop panel  --n=<k> --lens="correctness,security,repro" --claim="…" --quorum=<m>
5dive loop map    --over=<json-array> --do=<spawn-spec> [--max-concurrency=<n>]
5dive loop until-dry --round=<spawn-spec> --stop-after=<K> --dedup-key="…"
5dive loop collect --handles=<id,id,…>
5dive loop status  --handle=<loopId>          # read-only single-loop drilldown
5dive loop install <slug> --onto=<agent> [--cron="…"] [--ceiling=<tokens>] [--dry-run]
5dive loop uninstall <slug> --from=<agent> [--purge-skills]
                                               # removes the recurring TEMPLATE row only; already-materialized
                                               # instances are left alone. Skills stay by default (the agent
                                               # may use them elsewhere); --purge-skills also removes them.
5dive loop show <slug>                        # peek at a marketplace loop pack before install
```

## Org chart

Who-reports-to-whom across agents, in the same group-writable store (no sudo).
A single self-referential `reports_to` edge per agent, plus optional role/title.

```
5dive org set <agent> [--manager=<agent>|default] [--role=<text>] [--title=<text>]  # upsert; default clears
5dive org tree                                    # whole hierarchy, indented
5dive org show <agent>                             # manager + direct reports
5dive org ls                                       # flat list of everyone placed
5dive org rm <agent>                               # remove (reports re-parent to null)
```

## Heartbeat

Wakes an enrolled agent only when it has queued tasks (one per tick). Enrolment
uses the agent's **short name** (the same one `task --assignee` expects).

```
5dive heartbeat on  <name> [--every=<dur>] [--no-fresh]   # enrol; default 30m, fresh on
5dive heartbeat off <name>                                # stop waking (keeps settings)
5dive heartbeat ls                                        # enrolled + next-wake + queued count
5dive heartbeat tick                                      # root cron driver — wired at provision; don't call
5dive heartbeat wake-mode <name> [always_on|cold] [--cap=<n>] [--sleep-after=<min>]
                                                           # no mode/flags => print current mode/budget/sleep/cost.
                                                           # 'cold' opts an agent into reactive wake-on-alert with
                                                           # a wakes/day budget cap (default 24) so a chatty
                                                           # trigger can't thrash it; a cold agent idle with no
                                                           # open work auto-sleeps (systemctl stop) after
                                                           # --sleep-after minutes (default 15m) and wakes again
                                                           # on the next trigger. 'always_on' (default) is
                                                           # unchanged; some agents may be pinned always-on and
                                                           # refuse 'cold'.
```

`<dur>`: minutes (`30`), or `45m` / `2h` / `1h30m`. `fresh` (default on) sends
`/clear` before each task; `--no-fresh` keeps the running conversation.

## Memory (queryable team memory)

```
5dive memory search "<query>" [--limit=N] [--max-tokens=T] [--roots=a,b]
                              [--store=all|mine|wiki] [--agent=<name>]
                                             # BM25-ranked snippets + provenance; read-only, no sudo
                                             # --store all (default) | mine | wiki
                                             # --agent = another agent's store (per-user 0600 — root only)
5dive memory add --name=<kebab-slug> --description="<one-liner>"
                 [--type=user|feedback|project|reference] [--store=mine|wiki]
                 [--tags=a,b] [--valid-to=YYYY-MM-DD] [--supersedes=<slug>]
                 [--confidence=high|medium|low] [--provenance="<source>"] [--force]
                                             # body on STDIN; writes a frontmatter file to your store
                                             # (or the shared wiki with --store=wiki), stamps provenance,
                                             # appends the index line; token/key tripwire (--force won't bypass)
5dive memory doctor [--roots=a,b] [--agent=<name>] [--code-root=<dir>] [--json]
                                             # hygiene: index drift, dangling [[links]], stale refs, near-dupes
```

## Usage, cost & activity

```
5dive usage [--7d] [--json]                  # board: top agents + top tasks by tokens (24h default)
5dive usage <agent> [--7d]                   # one agent: per-model + per-task breakdown
5dive usage loops [--json]                   # spend rolled up per loop / topology
5dive cost [--7d] [--json]                   # budget-focused: per-agent 24h burn vs soft/ceiling + state
5dive activity <agent> [--7d] [--task=DIVE-N] [--limit=N]   # files touched, commands run, cost
5dive usage budget set <agent> --daily=<tok> [--ceiling=<tok>] [--hard-stop]   # soft warn + optional hard-stop
5dive usage budget ls                        # all budgets  (hard-stop OFF by default, warn-only)
5dive usage budget clear <agent>             # remove a budget
5dive account usage                          # per-account 5h/7d rate-limit headroom (vs token burn)
```

## Trace (read-only causal timeline for one task)

```
5dive trace <id|DIVE-N> [--json] [--no-audit]
```

Reconstructs one task's story goal → ship from columns the row already
carries (`created_at`, `started_at`, `handoff_delivered_at`,
`handoff_ack_at`, `need_answered_at`, `shipped_flag_at`, `done_at`) plus its
project/goal, parent chain, originating objective/loop, and any audit-log
lines mentioning its ident. No mutation, no lock — same posture as `usage`/
`digest`/`memory search`. Text mode: origin block, chronological timeline
(a pending gate shows inline as `(pending)`), audit-log refs if any matched,
and a final `verdict:` line.

**The verdict is the zero-human proof story compiled into one line** — it
reads gate *provenance*, not effort: `human_touchpoints` only counts a
`need_answered_at` whose `need_answered_by` is prefixed `human:` (the
verified-human-clear path, DIVE-394); a decision gate an agent answered
itself does **not** count even though the row exists. `zero-human` = done
with 0 counted human touchpoints; otherwise `human-in-the-loop` names the
count, or `cancelled`, or (open task) `in progress — blocked on a pending
<type> gate` / `in progress — N human touchpoint(s) so far`.

**Audit-log references are supplementary, never authoritative — the tool
says so on its own output.** Two structural gaps mean "absent from the log"
is not proof an action didn't happen: rows written before CLI v0.15.26
systematically omit `task`/`task need` sub-events taken by a non-root agent
acting as itself (gone forever), and a row whose append failed used to
vanish silently — it now leaves a marker surfaced as `audit_drops`
(JSON) / an `audit-log DROPS:` line (text) when nonzero. Both caveats print
in text mode whenever audit is consulted; `--no-audit` skips reading the log
(and the caveat) entirely. Exit codes: `E_USAGE` (2) no id/unknown flag,
`E_VALIDATION` (3) malformed ref, `E_NOT_FOUND` (4) no match — otherwise 0
regardless of the task's own status; tracing a cancelled or stuck task is
not itself a failure.

## Web UI (DIVE-2655)

```
5dive ui                        # serve on http://127.0.0.1:8735 (Ctrl-C to stop)
5dive ui --port=9000            # pick the port
5dive ui --host=<addr>          # loopback only unless FIVE_UI_ALLOW_REMOTE=1 (there is no sign-in)
5dive ui --data                 # print the JSON the views render (no server)
5dive ui --html                 # print the page itself (no server)
5dive ui --once                 # serve exactly one request, then exit (tests/probes)
```

The free single-host web UI: three read-only views (org chart, queue, gates)
served by the CLI itself, reading only the LOCAL task store and LOCAL org
chart — no fleet roll-up, no aggregation across boxes (that's the paid
tier). The HTTP surface answers GET/HEAD on exactly three paths and 405s
every other method, so no client-side code can make it write; anything that
mutates state already has a CLI verb. **No accounts, so no routable bind**:
`--host` accepts loopback addresses only (`127.x`, `::1`, `localhost`);
binding elsewhere needs `FIVE_UI_ALLOW_REMOTE=1` set deliberately, and warns
loudly at startup that the board and gates are then readable by anyone who
can reach the port. Needs `python3` (stdlib only — no pip/venv) to hold the
socket; bash can't listen on one and a serial `nc -l` loop drops a browser's
second connection.

## Actor-routed gh (DIVE-2448)

```
5dive gh <gh args...>                    # route by operation, decision printed on stderr
5dive gh --as=bot <gh args...>           # force the machine account (still refused for admin-class ops)
5dive gh --as=caller <gh args...>        # force your own credential (pre-2448 behaviour), on the record
5dive gh --explain <gh args...>          # print the routing decision, run nothing
5dive gh whoami                          # resolve BOTH identities: caller login and bot login
```

An agent's `gh` write authenticates as the human account by default, so the
audit trail can't tell an agent action from a human one (DIVE-2232). This
verb makes the routing decision CONFIGURATION instead of caller discipline:
`write`-class operations (pr create/merge/comment, issue edit, release
create, …) go out as the `5dive-bot` machine account so the actor field means
something; `admin`-class (repo settings, secrets, rulesets, collaborators —
`5dive-bot` is `admin=false` on every repo) and `read`-class calls stay on
your own credential. The credential itself is never held by the agent
process — read root-only inside `_gh_do` from `/etc/5dive/connectors/github-bot.env`
and passed to `gh` as an env prefix, never argv. An operation this file
doesn't recognize routes to the caller (today's behaviour) and says so,
rather than silently guessing.

## Identity (`whoami`)

```
5dive whoami [--json]
5dive whoami --for=<id|DIVE-N> [--json]
```

Prints the actor (unix principal + registry agent), authority
(`root` | `sudo:<who>` | `self`) and tier of the CURRENT process — with the
SOURCE of each value, not just the value. Read-only: no lock, no write, no
audit row (a verb whose job is reporting identity must not need identity to
be writable first). Identity is uid-first — `$EUID` (or `$SUDO_UID` at real
root) resolved against `/etc/passwd` in pure bash — and deliberately never
consults `--from`/argv, `$USER`, `$SUDO_USER`, `$FIVEDIVE_AUDIT_USER`, `id`,
or `getent` (the last two are PATH-resolved and therefore spoofable).
**Exit status is part of the contract:** an unmeasurable actor exits 6
(`auth_required`) rather than printing `unknown` with a success code, so
`5dive whoami >/dev/null` is itself a usable measurability check.

**`--for=<id|DIVE-N>` (DIVE-2519) renders the RECORDED authority chain for
one board row instead of the current process** — who created / started /
delivered / answered-a-gate-on / closed it, and under whose authority, read
from the ledger. Scope it with `--for=task:DIVE-N`, `gate:DIVE-N`, or
`action:DIVE-N`. Every link in the chain resolves to one of three verdicts:
`measured` (an event of the right kind exists and names an identity), `n/a`
(the state row says the transition never happened — by design, not a gap),
or `unmeasurable` (the state row says it DID happen and the record can't say
who or under what authority). **Exit 1 when a link that HAPPENED is
unmeasurable** — distinct from a clean `n/a`.

## Digest & supervisor

```
5dive digest [--7d|--30d|--24h] [--send]     # standup: shipped 24h(default)/window / in progress / open gates / burn / heartbeat health
                                             # --send delivers to the paired Telegram chat (root)
5dive digest on --at=<hour> | digest off | digest status   # daily auto-delivery (default OFF)

5dive supervisor                             # health board: per-agent state + classification + cause
5dive supervisor --watch[=secs]              # live repaint (default 5s; q quits)
5dive supervisor --tick                      # cron pass (root); no-ops unless /var/lib/5dive/supervisor.enabled
```

Supervisor classes: `healthy | slow | update-pending | stuck | drift`. Causes:
`service-dead | tmux-dead | poller-dead | loop-stuck | no-progress | stale-cli
| goal-drift`. Poller + activity signals cover
claude/codex/grok/antigravity/opencode. The board itself takes ZERO actions;
the P2 recovery ladder (DIVE-857/970) is a separate opt-in behind its own root
sentinel (`supervisor.actions.enabled`): nudge → resume → rotate with
exponentially spaced attempts, escalate to the paired human on exhaustion.
Crash-loop detection is SEPARATE — it lives in the restart wrapper
(`hooks/run-loop.sh`, DIVE-1029): exponential backoff on rapid deaths,
surfaces the real stderr once, and suppresses the false "usage limit reset,
agent resumed" banner.

## Fleet (register + control OTHER boxes)

```
5dive fleet add <name> --host=<addr> [--user=<u>] [--port=<n>] [--key=<path>]   # root; default user=claude port=22
5dive fleet ls                               # registered boxes
5dive fleet show <name>                      # one box's connection details
5dive fleet rm <name>                        # remove a box (root)
5dive fleet status [--timeout=<s>]           # per-box reachability + agent counts (parallel SSH)
5dive fleet agents [--timeout=<s>]           # every agent across the fleet, one view
5dive fleet send <agent>@<box> <text>        # message one agent on a box (text base64-transported)
5dive fleet restart <agent>@<box>            # restart one agent on a box
```

`add`/`rm` need root (write `/var/lib/5dive/fleet.json`, 0640 root:claude);
`ls/show/status/agents` are read-only. `--key` takes a PATH to a private key
(never key material); omit to use the default fleet key. `status`/`agents` fan
out over SSH in parallel and degrade gracefully — one unreachable box never
fails the whole view.

## Doctor & maintenance

```
5dive doctor                                   # text preview — every fixable check says so
5dive doctor --json                            # always exit 0; branch on data.summary.errors
5dive doctor --fix                             # (alias --repair) attempt reversible fixes
5dive doctor --dry-run                         # preview fixes (also alongside --fix)
5dive doctor --category=<c>                    # deps|types|auth|creds|registry|shelld|channels|host|memory
5dive update --check [--json]                  # behind/stale? read-only, no root
5dive self-update                              # upgrade CLI + plugins; RESTARTS every agent
5dive uninstall [--purge] [--yes]              # remove 5dive (--purge also wipes state + user)
5dive watch [--interval=N]                     # live fleet view; ↑↓ select, ↵ attach, q quit
```

`--fix` self-heals: apt installs, type installer recipes, bun, shelld restart,
registry reseed, rename a stale `~/.claude/.credentials.json` that shadows an
env token, restart an agent whose telegram poller died, and force `needrestart`
to list-only so a library upgrade can't bounce the whole fleet.

## Bug reports (diagnostic issue filing — DIVE-2323)

```
5dive bug [--verb=<name>] [--exit=<code>] [--no-probes] [--file]
```

Preview (the default) builds and prints a diagnostic payload; files nothing.
`--verb`/`--exit` name the 5dive verb that failed and its exit code, for
context. `--file` re-prints the identical payload and then opens it as a
GitHub issue against `5dive-ai/5dive` (via `5dive gh issue create`, so it
files as `5dive-bot` when routing allows it) — a TTY also gets an
interactive y/N, and there is no separate unattended path: an agent takes
the same `--file` flag a human does. **The payload is a fixed ALLOWLIST**,
never a denylist — version, OS, bash version, install method, the failing
verb + exit code, and `selfcheck` probe **name + verdict pairs only** (never
the free-text `reason`/`detail` fields underneath them, which is where
paths/hostnames/agent names could leak). `--no-probes` drops the selfcheck
summary entirely. Nothing ever leaves the box except via an explicit
`--file`.

## Selfcheck (does the fleet's OWN instrumentation still work?)

```
5dive selfcheck [--json] [--only=<probe,...>] [--full] [--assume-clean]
                [--strict] [--allow=<probe,...>] [--report=<file>] [--label=<env>] [--list]
```

Where `doctor` asks "is the box healthy", `selfcheck` asks "can our own
instruments still tell?" — it runs each critical rail FOR REAL against a
throwaway, isolated state (own `STATE_DIR`/`TASKS_DB`/`AUDIT_LOG` per probe,
never the live store) and asserts the *effect* it's supposed to have, not the
string it printed. `--list` prints the probe corpus: `lead-clear-seal`,
`t2-forge`, `gate-delivery`, `audit-root`, `audit-nonroot`,
`harness-verdicts`, `bundle-integrity`, `snapshot-rails`,
`scorecard-honesty`.

Each probe reports `pass` | `fail` | `not-reached` | `error`. **`not-reached`
is a first-class state, never folded into `pass`** — a probe whose
precondition is absent (e.g. `audit-root` run as non-root) has not shown its
rail works, and is only excusable with a machine-readable `reason`; a
`not-reached` with no reason counts `unexplained` and fails the run.
`audit-root`/`audit-nonroot` are deliberately never reachable together in one
run — a root run always reports `audit-nonroot` not-reached and vice versa —
so full coverage needs a root job and a non-root job unioned via
`--report=<file>` + `--label=<env>` (`tests/meta/selfcheck-union.sh`).

`--full` runs the harness-verdict mutation sweep over the WHOLE test corpus
(~164-168 harnesses) instead of a 3-harness sample — budget ~10min with
`--assume-clean`, ~22min bare (progress streams to stderr throughout; never
put this on an interactive path). `--strict` treats ANY `not-reached` (even
with a reason) as failure — only sound in an environment you know is fully
complete. `--allow=<probe,...>` declares probes THIS deployment structurally
can never reach; it's recorded for the union checker and does NOT change
this run's own exit code.

**Exit codes differ from `doctor`:** `doctor --json` always exits 0 and
expects callers to branch on `data.summary`; **`selfcheck --json` exits
non-zero on failure** — `E_GENERIC` (1) if any probe failed, errored, or was
an unexplained not-reached (also under `--strict`, any not-reached at all).
0 only if every probe passed or was a reasoned not-reached.

## ACP (Agent Client Protocol — DIVE-3017)

```
5dive acp
5dive acp -h | --help    # usage one-liner; takes no other arguments
```

Speaks ACP over stdin/stdout so an ACP client — Buzz (block/buzz), Zed —
can select 5dive as a coding-agent runtime. **Not interactive: the client
spawns it**, so this is not a verb a human or another agent runs directly.
A NATIVE verb, not an adapter: 5dive registers as its own runtime
(`command: "5dive", args: ["acp"]`) rather than going through a third-party
bridge.

A session **ATTACHES to a named fleet agent** (its memory, tasks, org
position and heartbeat intact) instead of opening a blank one — the roster
is exposed as ACP `availableCommands`, so `/<name>` or `/attach <name>`
picks the agent and `/agents` re-lists the fleet. Each prompt on an attached
session becomes one `5dive agent ask <name> <text> --timeout=${ACP_ASK_TIMEOUT:-180}`
turn — a real turn on a real agent, streamed at the granularity `agent ask`
prints at, not per-token.

Runs on **bun**, staged from an embedded server into `${ACP_RUN_DIR:-/opt/5dive}/acp-server.ts`
at each invocation. Resolves its own bun binary — `ACP_BUN_BIN` overrides,
then `/usr/local/bin/bun` / `~/.bun/bin/bun`, then the caller's own `PATH`
(load-bearing off-box: a Buzz user on their own Mac has none of this VM's
fixed paths), then a `sudo -u claude` login-shell probe. Missing bun fails
loud (`E_NOT_INSTALLED`) with an install hint, rather than dying silently
once the ACP client has already spawned it. `exec`s into bun on success, so
the row this verb writes to the audit log is emitted *before* the exec
(the dispatcher's own EXIT-trap audit row never fires past an `exec`).

## Models

```
5dive models [--json]
```

Prints the current Claude model id for each short alias (`opus`, `sonnet`,
`fable`, `haiku`), read-only, no sudo. This is the single source of truth
(`src/lib/models.sh`, DIVE-1883) that both `agent create`/`agent config set
model=` alias-resolution and the Telegram `/model` picker read against — a
model release is meant to be a one-line edit to that file and nothing else.
Check it rather than assuming a hardcoded model id is still current; the
alias and the underlying id drift apart across releases.

## Known agent types (default install)

| Type        | Channels | Notes |
| ----------- | -------- | ----- |
| antigravity | yes      | Google Antigravity CLI (binary: `agy`) |
| claude      | yes      | Anthropic Claude Code |
| codex       | yes      | OpenAI Codex CLI |
| grok        | yes      | xAI Grok CLI |
| hermes      | yes      | Nous Research hermes harness (BYO provider key) |
| openclaw    | yes      | Third-party Claude harness (BYO provider key) |
| opencode    | yes      | opencode.ai (free models, no signup) |

All current types support `--channels=telegram`; `discord` is claude/openclaw;
`dashboard` is claude-only (token-free web chat, folded into every claude create
by default). Run `5dive agent types --json` on the host for the authoritative
list — installers add or drop entries over time (`gemini` was removed).
