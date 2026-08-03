---
name: 5dive-cli
description: Use the local `5dive` CLI on a 5dive runtime VM to spawn, inspect, send to, and tear down sibling agents — plus the shared task queue and org chart. Trigger when the user wants a worker, sub-agent, side task, parallel run, fan-out, or to delegate — or names a sibling agent ("ask X", "ping X", "tell X", "hand off to X", "coordinate with X"); confirm it exists via `5dive agent list --json`, then `agent send` / `agent ask`. Also for filing and tracking shared work (`5dive task add/ls/done`), the org chart (`5dive org tree`), parking a blocking question on a human (`task need`), and a quick recall of team memory (`5dive memory search`). For everything else the CLI can do — crew hosting, multi-account auth, auth recovery, declarative fleets/compose, goal DAGs, objectives, loops, compiling into the wiki, org-chart writes, governance votes, digest/usage/supervisor/fleet/diagnose, telegram pairing, the persona market, BYO providers, and the company wizard — see the `5dive-cli-extras` skill. When a request came over a chat channel (Telegram/Discord `<channel>` tag) and another agent should handle it, pass the chat context via `--reply-to-chat=<id> --reply-to-msg=<id>` so that agent replies from its own bot — don't relay. Always prefer `5dive` over running coding CLIs by hand.
---

# 5dive-cli

This skill teaches you to drive the `5dive` command on a 5dive runtime VM.
You are running inside one such VM. You can spawn additional agents on the
same host by shelling out to `sudo 5dive ...` and parsing the JSON envelope
it emits when you pass `--json`.

## When to use this skill

Use it whenever the work in front of you would benefit from a second pair of
hands — for example:

- The user asks for a "worker", "sub-agent", "another agent", or "side task".
- **The user names a specific sibling agent** — "redirect to marketing",
  "ask scout", "ping ops", "tell research", "coordinate with X", "hand off
  to X". First confirm the agent exists via `sudo 5dive agent list --json`,
  then `agent send`.
- A long task could fan out into independent pieces (e.g. audit each route
  in parallel, run a different model on the same prompt, A/B two implementations).
- You need to keep one agent on a hot context while a second one investigates
  something orthogonal.
- You're coordinating work across several agents and want a shared to-do list
  (`5dive task`) or a reporting structure (`5dive org`).
- You're blocked on something only a human can provide — a decision, a
  secret, an approval (`5dive task need`).
- You want to recall what the team already knows — past decisions, gotchas,
  research — before re-deriving it (`5dive memory search`).

If the user just wants you to do the work yourself, do not spawn an agent.
For crew hosting, accounts, loops/goals, governance, fleet health and the
other less-frequent surfaces, see `5dive-cli-extras`.

## Mental model

Everything the CLI does maps onto these resources on the host:

- One **agent** = one Linux user (`agent-<name>`) + one systemd unit
  (`5dive-agent@<name>.service`) + one tmux session (`agent-<name>`)
  running the chosen CLI in a restart loop.
- Auth is decoupled. You authenticate a *type* once; every agent of that
  type inherits the credentials via `EnvironmentFile`.
- A **channel** (`telegram` / `discord` / `dashboard` / `none`, comma-listable)
  is the inbound message surface. All agent types support channels; each agent
  needs its own bot token. `dashboard` (claude-only, token-free) is web-dashboard
  chat and is folded into every claude create by default — `--channels=none`
  opts out.
- The CLI is idempotent and safe to call from another agent, but **`sudo` is
  gated by isolation tier** (DIVE-1002). New agents default to `standard` —
  zero sudo. Only the first agent on a fresh box, or one created with
  `--isolation=admin`, gets a **scoped** grant: the `5dive` CLI plus non-paging
  `systemctl start|stop|restart` of `5dive-*` units — NOT `NOPASSWD:ALL`. So the
  no-sudo surfaces (`5dive task`, `org` reads, `memory`) run from any agent;
  the root surfaces (`agent create`/`config`/`pair`, `heartbeat on/off`,
  `doctor`, `usage`) need an admin agent.
- Agent types on a current host: `antigravity codex claude openclaw hermes
  grok opencode`. Run `sudo 5dive agent types --json` for what's actually
  installed — the set changes between releases.

## Output contract — always pass `--json`

Pass `--json` as a global flag (anywhere on the command line). Stdout
becomes a stable envelope; progress lines stay on stderr.

```bash
sudo 5dive agent create scout --type=claude --json
```

Success:
```json
{ "ok": true, "data": { "name": "scout", "type": "claude", "created": true } }
```

Failure (exit code matches `error.code`):
```json
{ "ok": false, "error": { "code": 6, "class": "auth_required", "message": "..." } }
```

**Branch on `error.class`, not on the human message.** Classes:
`ok`, `usage`, `validation`, `not_found`, `conflict`, `auth_required`,
`not_installed`, `not_running`, `pairing`, `permission`, `timeout`, `generic`.

See `references/exit-codes.md` for the full table.

## Recipes

### Spawn a worker for a side task

```bash
# 1. Pick a unique name (lowercase letters/digits/hyphens, ≤16 chars,
#    must start with a letter). Check the registry first if you care:
sudo 5dive agent list --json | jq -r '.data[].name'   # data is an ARRAY of agents

# 2. Create the worker. --workdir scopes its tmux cwd; default is
#    /home/claude/projects.
sudo 5dive agent create worker-1 \
  --type=claude \
  --workdir=/home/claude/projects/myrepo \
  --json

# 3. Send it the task. tmux send-keys + Enter, so the text appears
#    in the worker's running CLI prompt.
sudo 5dive agent send worker-1 \
  "audit the auth middleware for OWASP A01 issues; report back as a markdown bullet list"

# 4. Poll its output until it goes idle. --tmux dumps the scrollback.
sudo 5dive agent logs worker-1 --tmux --lines=80

# 5. Tear it down when you're done — frees the systemd unit + Linux user.
sudo 5dive agent rm worker-1 --json
# `5dive fire worker-1` is an alias of `agent rm` (same guarded teardown).
```

`agent info <name>` shows the resolved type, CLI version, model and channel
state for one agent. For personas off the agent market, BYO-provider keys,
`--defer-auth`, and skill-inheritance flags on create, see `5dive-cli-extras`.

### Talking to other agents: `agent send` / `agent ask`

There is no separate channel — messages land in the receiver's running CLI
as if a human had typed them. When you (an agent) call `agent send`, the CLI
wraps the payload as `[5dive-msg from=<you> id=<8-hex>] <your text>` so the
receiver knows a peer is pinging it (only sends from `agent-*` users get
wrapped; `--raw` skips wrapping, `--from=<label>` overrides the inferred name).
**Quote the body in single quotes and keep backticks / `$()` out of it** — the
message passes through a shell.

To reply, send back to the named sender, optionally prefixing `[re=<id>]` so
they can match it to their question:

```bash
sudo 5dive agent send scout "[re=ab12cd34] auth middleware looks clean except for ..."
```

If you want request/response in one call instead of manually polling
`agent logs`, use `ask` — it watches the tmux pane after the marker line and
returns once the scrollback has been quiet for `--idle-secs` (default 5s):

```bash
sudo 5dive agent ask scout \
  "list the OWASP A01 issues you found, one per line" \
  --timeout=180 --json
```

`ask` is heuristic (a receiver that streams continuously stays "busy" until
`--timeout` fires) and returns whatever was on screen, chrome included — ask
for a terse final summary if you need something clean to parse.

If a user pings you on a Telegram/Discord chat where the target agent's bot
is **also** a member, don't relay the answer yourself — hand it off with
`--reply-to-chat=<id> [--reply-to-msg=<id>]` (values come from the inbound
`<channel>` tag's `chat_id`/`message_id`) so the target agent posts directly
via its own bot. See `5dive-cli-extras` for the full chat-delegation walkthrough.

### Track shared work: the task queue + org chart

The host has a shared task queue and org chart in a group-writable sqlite
store, so **no sudo is needed** — any `agent-*` user can read and write directly.

```bash
# Queue a unit of work. Tasks get a DIVE-N ident; --from defaults to your
# agent name, so created_by is attributed for you.
5dive task add "audit the auth middleware for OWASP A01" \
  --assignee=worker-1 --priority=high --json
# --assignee also takes org-routing tokens (role:<r> / charter:<kw>); omit it to
# route to the org lead/coordinator.

# What's open, who's on what (priority-ordered); --mine filters to you.
5dive task ls --json
5dive task ls --mine --json

# Drive status as work moves. block/unblock express dependencies.
5dive task start DIVE-7 --json          # -> in_progress
5dive task done  DIVE-7 --result="one-line summary first; detail below" --json
5dive task block DIVE-9 --by=DIVE-7 --json   # DIVE-9 waits on DIVE-7

# Who reports to whom, at a glance:
5dive org tree --json
```

On `done`/`cancel`, `--result`'s **first line** is what gets pinged to the
owner's phone — lead with a terse one-line summary, detail after the first
newline. A non-trivial `task add` is graded by a verifier other than the
maker by default (DIVE-969); see `5dive-cli-extras` for that rail, projects,
recurring work, and loops.

### Park a question on a human: `task need`

When a task is blocked on something only a human can provide, don't sit on
it and don't guess — gate it:

```bash
5dive task need DIVE-12 --type=decision \
  --ask="Ship behind a flag or straight to prod?" \
  --options="flag|prod" --recommend="flag" --tier=1 --json
# --type: decision | secret | approval | manual | access
# -> task goes blocked; the human gets an alert with tap buttons.

5dive task inbox --json        # everything currently waiting on a human
5dive task answer DIVE-12 --value="flag" --json   # records + unblocks + pings the owner
# You (an agent) can only `task answer` a tier-0/1 DECISION gate. approval /
# secret / manual gates are HUMAN-ONLY (a Telegram tap or a non-agent SUDO_UID).
```

Keep `--ask` to ONE crisp question with ~1 line of context; heavy detail
belongs in the task body. Always pass `--recommend` for decision/approval —
the alert leads with your recommendation so the human can one-tap it.

**Risk tiers (`--tier=0|1|2`):** `0` auto-clears immediately (needs
`--recommend`, no ping); `1` pings but auto-applies the recommendation if
unanswered 48h (default for `decision`); `2` is a hard human gate that never
auto-applies (default for approval/secret/manual). Money, public comms,
secrets, destructive and brand asks are floored to tier 2 regardless of the
flag. See `5dive-cli-extras` for `task park`/`escalate`/`clear-recs`, the
`--type=access` + `--probe` self-check, and precedent prefill.

### Search team memory before re-deriving

```bash
5dive memory search "hetzner capacity gotchas" --json
```

Read-only, no sudo, BM25-ranked snippets with file+heading provenance. Reach
for it before re-deriving past decisions or debugging something a teammate
already hit. For the write-path (`memory add`, compiling into the shared
wiki) and hygiene checks, see `5dive-cli-extras`.

### Check your own identity, or run `gh` as the right one

```bash
5dive whoami --json     # actor, authority (root|sudo:<who>|self) and tier — with the SOURCE of each
```

Reach for this when a gate refusal or a permission error doesn't make sense —
it names which uid/agent/tier the CLI actually sees you as, not what you
assume. Exits 6 (`auth_required`) rather than printing `unknown` if the actor
can't be measured, so it doubles as a scriptable measurability check.

When a task involves opening/commenting on a PR or issue as an agent, prefer
`5dive gh <gh args...>` over calling the `gh` binary directly: writes
(`pr create`, `pr merge`, `issue comment`, …) route to the `5dive-bot`
machine account so the GitHub actor field actually distinguishes an agent
action from a human one (DIVE-2448); reads and admin-class calls stay on
your own credential automatically. `5dive gh --explain <args>` previews the
routing decision without running anything.

## Rules of engagement

1. **Always pass `--json`.** Parse the envelope. Don't grep stderr.
2. **One name = one agent.** Names are lowercase letters/digits/hyphens,
   start with a letter, max 16 chars. Reuse a name only after `agent rm`.
3. **Don't share bot tokens.** Two Telegram-channel agents on the same
   bot will race each other on `getUpdates`. Each agent needs its own.
4. **Tear down what you spin up.** A leaked `worker-N` agent stays
   running across reboots — it's a real systemd unit, not a thread.
   On task completion call `5dive agent rm <name>`.
5. **Don't shell out to the underlying CLI binaries directly.** Going
   around `5dive` skips the systemd unit, the audit log, and the env
   injection — the agent will run with broken auth and no restart loop.
6. **Read `5dive --help`** if a flag is rejected as unknown — the binary
   on the host may be newer or older than this skill. The help output is
   authoritative.
7. **Blocked on a human? Gate it.** Use `task need` with a recommendation
   instead of guessing or letting the task rot silently.
8. **When delegating a chat request, don't relay — hand off context**
   via `agent send --reply-to-chat=<id> --reply-to-msg=<id>`.

## Reference

- `references/commands.md` — every subcommand and flag, copy/pasteable.
  Includes the less-frequent top-level verbs not recapped above: `deploy`
  (delegated production deploy, INST-5), `bug` (diagnostic issue filing) and
  `constitution` (front door onto the machine-enforced guardrails).
- `references/exit-codes.md` — exit codes & error classes.
- `references/paths.md` — on-disk state layout (only for debugging).
- `5dive-cli-extras` skill — crew hosting, accounts, auth recovery, compose/
  team templates, goal DAGs, objectives, loops, memory-write/wiki, org-chart
  writes, governance votes, digest/usage/supervisor/fleet/diagnose, telegram
  pairing detail, the persona market, BYO providers, and the company wizard.

## Going further

The full reference manual lives at <https://5dive.com/docs>. If a flag in
this skill conflicts with what the running binary accepts, trust the
binary — run `sudo 5dive --help` or `sudo 5dive agent <sub> --help`
directly and follow that.

_Synced to 5dive CLI **0.18.6** (commit `089f7d2`, 2026-08-03). A given box's
binary can lag by up to a day behind main (nightly update channel) — trust
`5dive --help` if they differ._
