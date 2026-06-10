# 5dive CLI — full command reference

Every subcommand accepts `--json` as a global flag. The exact help output
on the host is authoritative; this file is the canonical reference shape.

## Top-level

```
5dive agent     ...                  # agent CRUD
5dive account   ...                  # named auth profiles
5dive task      ...                  # host-shared task queue (no sudo)
5dive org       ...                  # agent org chart (no sudo)
5dive heartbeat ...                  # wake agents that have queued tasks
5dive up | down | ps | export        # declarative fleet (5dive.yaml)
5dive team import <slug|path> | team ls
5dive watch [--interval=N]           # htop-style live view (interactive TTY)
5dive doctor  [--repair] [--category=deps|types|auth|registry|shelld]
5dive --version
5dive update --check                 # read-only: behind/stale? (no root)
5dive self-update                    # upgrade CLI + plugins, RESTARTS ALL AGENTS
5dive --help | -h | help
```

## Agents

```
5dive agent list                              # --json carries model + effort per agent
5dive agent info <name>                       # type, CLI version, model, channel + state
5dive agent types
5dive agent create <name> --type=<type>
                          [--channels=none|telegram|discord]
                          [--telegram-token=<bot-token>]
                          [--discord-token=<token>]
                          [--workdir=<path>]
                          [--auth-profile=<name>]
                          [--isolation=admin|standard|sandboxed] # default admin
                          [--provider=<id> --api-key=<key|->]    # hermes/openclaw BYO key
                          [--with-skills=<spec>[,<spec>...]]     # bare id (5dive-com/skills) or owner/repo:id
                          [--no-skills]                          # opt out (overrides agent-spawn default)
                          [--defer-auth]                         # skip auth gate; first-run UI handles it
5dive agent clone <src> <dst> [--channels=...] [--telegram-token=...]
                              [--discord-token=...] [--workdir=...]
5dive agent start   <name>
5dive agent stop    <name>
5dive agent restart <name>
5dive agent rm      <name>
5dive agent stats   <name>
5dive agent stats   --all                     # whole fleet, incl. health hints
5dive agent logs    <name> [--follow] [--lines=N] [--tmux]
5dive agent send    <name> <text...> [--from=<sender>] [--raw]
                                     [--reply-to-chat=<id> [--reply-to-msg=<id>]]
5dive agent ask     <name> <text...> [--from=<sender>] [--timeout=120]
                                     [--idle-secs=5] [--poll-secs=2]
                                     [--reply-to-chat=<id> [--reply-to-msg=<id>]]
5dive agent <name>  tui                       # attach this terminal
5dive agent install <type>                    # install the type's binary
5dive agent set-account <agent> <account|default>   # alias for `agent config set auth-profile=`
```

`--provider` ids (hermes/openclaw only; mutually exclusive with
`--defer-auth`): `openrouter google minimax moonshot huggingface anthropic
deepseek qwen nous openai zai`.

When `agent create` runs from another agent (`SUDO_USER=agent-*`),
`--with-skills=5dive-cli` is the default for every supported type. Pass
`--no-skills` to opt out, or `--with-skills=...` to override the list
explicitly.

## Config

```
5dive agent config <name> set channels=<none|telegram|discord>
5dive agent config <name> set workdir=<path>          # "default" clears
5dive agent config <name> set auth-profile=<name>     # "default" clears
5dive agent config <name> set model=<id>              # runtime model (claude/codex/grok/antigravity)
5dive agent config <name> set effort=<low|medium|high|xhigh|max>
                                                      # claude only; xhigh/max are Opus-tier
5dive agent config <name> set telegram.token=<token>  # + channels=telegram attaches a bot post-create
5dive agent config <name> set discord.token=<token>
5dive agent config <name> set telegram.home-channel=<chat-id>   # hermes only
5dive agent config <name> set telegram.allowed-users=<id1,id2,...>
                                                      # seed DM allowlist, no pair-code gate
```

## Pairing & Telegram surface

```
5dive agent pair <name>                                       # returns a code; user DMs the bot
5dive agent pair <name> --code=<code>                         # paste bot reply or bare code
5dive agent pair <name> --user-id=<id> [--chat-id=<id>]       # seed access.json directly; chat_id defaults to user_id (private DM)
5dive agent telegram-discover {--token=<bot-token>|--agent=<name>} [--poll-secs=N]
                                                              # long-poll getUpdates; returns {found, userId, chatId, ...}
5dive agent telegram-getme    --token=<bot-token>             # getMe — {botId, username, firstName}
5dive agent telegram-info     <name> [--refresh]              # name-based getMe; caches botUsername in registry
5dive agent telegram-access get <name>                        # read access.json (DM policy, allowlist, groups)
5dive agent telegram-access set <name>                        # write access.json from JSON on stdin; live, no restart
5dive agent telegram-pending-ignore <name> <code>             # drop a pending pairing without approving
5dive agent telegram-resolve-handle <name> <@handle>          # getChat — {id, isBot, displayName}
```

## Auth (lower-level — prefer `account` for human flows)

```
5dive agent auth status [--probe] [--type=<type>]
5dive agent auth login  <type>                 # TTY only — never from a script
5dive agent auth set    <type> --api-key=<key|->
                        [--auth-profile=<name>] [--provider=<id>]   # --provider required for hermes/openclaw
5dive agent auth start  <type> [--auth-profile=<name>]
5dive agent auth poll   <session_id>
5dive agent auth submit <session_id> --code=<callback>
5dive agent auth cancel <session_id>
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
```

The reserved name `default` is rejected by `account add` / `rename`.

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

## Tasks (shared queue)

Host-shared task queue at `/var/lib/5dive/tasks/tasks.db` (sqlite, WAL). The
store is group-writable, so every `agent-*` user can read/write **without
sudo**. Tasks get a `DIVE-N` ident; statuses are
`todo | in_progress | blocked | done | cancelled`.

```
5dive task add <title...> [--body=<text>] [--priority=low|medium|high|urgent]
                          [--assignee=<agent>] [--parent=<id|DIVE-N>] [--from=<who>]
                          [--recurring="<cron>"]   # 5-field cron — creates a recurring TEMPLATE
5dive task ls   [--status=<s>] [--assignee=<agent>] [--mine] [--all] [--recurring]
                                                  # default: open, priority-ordered; --recurring lists templates
5dive task show <id|DIVE-N>                       # detail + subtasks + blockers
5dive task assign <id|DIVE-N> <agent>
5dive task start  <id|DIVE-N>                     # -> in_progress
5dive task done   <id|DIVE-N> [--result=<text>]   # -> done; FIRST line of result is the owner's phone ping
5dive task cancel <id|DIVE-N> [--result=<text>]   # -> cancelled; --result captures why
5dive task block   <id|DIVE-N> --by=<id|DIVE-N>   # add a blocks edge, mark blocked
5dive task unblock <id|DIVE-N> [--by=<id|DIVE-N>] # drop edge(s); back to todo if clear
5dive task rm <id|DIVE-N>                         # delete (cascades subtasks + edges)
```

### Human Task Inbox — park a task on a human and clear it

```
5dive task need <id|DIVE-N> --type=decision|secret|approval|manual
                --ask="..." [--options=A|B] [--recommend="A"]
                                                  # -> blocked, awaiting a human
5dive task inbox                                  # ONLY human-gated tasks, priority-ordered
5dive task answer <id|DIVE-N> --value="..."       # record answer, unblock, ping the owning agent
```

`--ask` is ONE crisp question (+~1 line context, recommendation up front);
heavy detail goes in the task BODY. `--recommend` is strongly encouraged for
decision/approval — for a decision it must match one of `--options`.

### Recurring templates

A task created with `--recurring="<cron>"` is an inert template (excluded
from default `ls`, heartbeat, inbox). The heartbeat tick materializes it
into a standard todo when the cron matches, skipping if a prior instance is
still open. Templates default to `fresh` (worker `/clear`s before the task);
`--fresh` / `--no-fresh` override per template. No catch-up for missed
ticks — keep schedules coarse (hourly/daily).

`task init` is a one-time root bootstrap run at provision time — agents never
call it. From an agent, `--from` defaults to your `agent-*` name (or `SUDO_USER`
when run via sudo), so `created_by` is attributed automatically.

## Org chart

Who-reports-to-whom across agents, in the same group-writable store (no sudo).
A single self-referential `reports_to` edge per agent, plus optional role/title.

```
5dive org set <agent> [--manager=<agent>|default] [--role=<text>] [--title=<text>]  # upsert; --manager=default clears
5dive org tree                                    # whole hierarchy, indented
5dive org show <agent>                             # manager + direct reports
5dive org ls                                       # flat list of everyone placed
5dive org rm <agent>                               # remove (reports re-parent to null)
```

## Heartbeat

Wakes an enrolled agent only when it has queued tasks (one per tick).
Enrolment uses the agent's **short name** (the same one `task --assignee`
expects), not the `agent-*` Linux user.

```
5dive heartbeat on  <name> [--every=<dur>] [--no-fresh]   # enrol; default 30m, fresh on
5dive heartbeat off <name>                                # stop waking (keeps settings)
5dive heartbeat ls                                        # enrolled + next-wake + queued count
5dive heartbeat tick                                      # root cron driver — wired at provision; don't call
```

`<dur>`: minutes (`30`), or `45m` / `2h` / `1h30m`. `fresh` (default on)
sends `/clear` before each task; `--no-fresh` keeps the running conversation.

## Doctor & maintenance

```
5dive doctor                                   # text
5dive doctor --json                            # always exit 0; branch on data.summary.errors
5dive doctor --repair                          # attempt reversible fixes
5dive doctor --category=deps                   # also: types | auth | registry | shelld
5dive update --check [--json]                  # behind/stale? read-only, no root
5dive self-update                              # upgrade CLI + plugins; RESTARTS every agent
5dive watch [--interval=N]                     # live fleet view; ↑↓ select, ↵ attach, q quit
```

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

All current types support `--channels=telegram`; discord is claude/openclaw.
Run `5dive agent types --json` on the host for the authoritative list —
installers add or drop entries over time (`gemini` was removed).
