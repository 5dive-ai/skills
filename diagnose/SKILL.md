---
name: diagnose
description: Self-diagnosis skill for 5dive agents. Trigger this skill whenever the user says something is broken, not working, or behaving unexpectedly — or when any tool or command exits with an error. Runs a structured health check covering auth state, service health, disk, memory, recent CLI errors, and skill integrity. Surfaces a root-cause summary so the agent can fix the problem itself instead of asking the user. Also exposes a security audit sub-command for SSH keys, open ports, auth failures, and risky file permissions.
---

# diagnose

This skill turns your agent into its own first-line support. Instead of forwarding
"something's wrong" messages to a human, the agent inspects the VM, identifies the
root cause, and either fixes it or reports a precise diagnosis.

## When to trigger

Trigger this skill automatically when:

- The user says anything like "something's wrong", "not working", "broken", "help",
  "can't connect", "error", or "I'm stuck".
- Any command or tool returns a non-zero exit code and you don't already know why.
- A `StopFailure` or similar hook fires.
- An agent you spawned goes silent or returns a `generic` / `timeout` error class.

Do **not** trigger the security audit sub-capability automatically — run it only
when the user explicitly asks for a security check or audit.

## Standard health check

Run these in order. Stop at the first critical failure and attempt a fix before
continuing. Report the full picture at the end.

### 1. Auth state

```bash
# Check which agent types are authenticated on this host.
sudo 5dive doctor --json | jq '.data.checks | map(select(.name | startswith("auth")))'
```

If a type comes back `status: "fail"`, that's why agents of that type can't start.
Fix with `auth set` (API key) or guide the user through `auth start` (OAuth):

```bash
# API key path — pipe the key, never leave it in the shell history.
echo "$KEY" | sudo 5dive agent auth set claude --api-key=- --json
```

### 2. Recent 5dive-cli errors

```bash
# Last 50 error/warning lines from the CLI audit log.
sudo journalctl -u '5dive-agent@*' -p warning -n 50 --no-pager
```

Look for repeated `auth_required`, `not_running`, or `timeout` entries — they pin
down which agent is failing and why.

### 3. Service health

```bash
# Overall host check — exits 0 even with failures, read data.summary.errors.
sudo 5dive doctor --json

# Per-agent status (running / stopped / failed).
sudo 5dive agent list --json | jq '.data.agents | to_entries[] | {name:.key, status:.value.status}'

# Full systemd state for a specific agent:
sudo systemctl status '5dive-agent@<name>'
```

A `failed` unit usually means the agent crashed on startup. Check
`journalctl -u 5dive-agent@<name> -n 30 --no-pager` for the stack trace.

### 4. Disk usage

```bash
# Filesystem usage — warn if any mount is over 80 %.
df -h | awk 'NR==1 || $5+0 > 80'

# Top 10 disk consumers under /home and /var/lib/5dive:
du -sh /home/*/  /var/lib/5dive/ 2>/dev/null | sort -rh | head -10
```

High disk is the #1 cause of silent install failures and agent crashes.
Clean logs with `sudo journalctl --vacuum-size=200M` if journals are the culprit.

### 5. Memory

```bash
free -h
# Swap usage over 50 % with low free RAM = OOM risk.
```

If an agent OOM-killed, systemd shows `status=1/KILLED` and journalctl shows
`Killed process`. The fix is usually `sudo 5dive agent rm <heavy-agent>` or
adding swap.

### 6. Skill integrity

```bash
# List installed skills for each running agent.
for agent in $(sudo 5dive agent list --json | jq -r '.data.agents | keys[]'); do
  echo "=== $agent ===";
  sudo 5dive agent skill "$agent" list --json | jq -r '.data.skills[].name';
done
```

A missing skill that the agent depends on causes silent capability gaps — not errors,
just "I don't know how to do that". Re-install with:

```bash
sudo 5dive agent skill <name> add --source=<source> --skill=<skillId> --json
```

## Putting it together — the diagnosis report

After running the checks above, produce a report in this structure:

```
## Diagnosis

**Status:** [Healthy / Degraded / Critical]

### Findings
- [auth] claude: authenticated ✓
- [service] agent-worker: failed — exit code 1, OOM at 03:12 UTC
- [disk] /var/lib: 87 % full — journals consuming 4.2 GB
- [skill] worker: brainstorming missing

### Root cause
<one sentence>

### Actions taken
- Vacuumed journals (freed 3.8 GB)
- Re-installed brainstorming skill on worker

### Remaining issues
- worker OOM: recommend reducing concurrent agents or adding 2 GB swap
```

Keep findings machine-readable (one fact per bullet, consistent prefixes) so a
calling agent can parse them with `agent ask`.

## Quick fix recipes

### Restart a failed agent

```bash
sudo systemctl restart 5dive-agent@<name>
sudo 5dive agent list --json | jq '.data.agents["<name>"].status'
```

### Free disk space fast

```bash
sudo journalctl --vacuum-size=200M
docker system prune -f 2>/dev/null || true
```

### Re-authenticate a type

```bash
# API key (non-interactive, safe from an agent):
echo "$KEY" | sudo 5dive agent auth set <type> --api-key=- --json

# OAuth (needs a human — give them the URL):
sudo 5dive agent auth start <type> --json
# Relay the URL to the user; they paste back the callback code:
sudo 5dive agent auth submit <type> --code=<callback-code> --json
```

### Add swap (if OOM is the culprit)

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## Security audit (explicit only — do not auto-run)

Run this block only when the user explicitly asks for a security check.

```bash
# 1. SSH authorized keys — list all keys across all users.
for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do
  [ -f "$f" ] && echo "=== $f ===" && cat "$f";
done

# 2. Open listening ports.
ss -tlnp

# 3. Recent auth failures (last 50).
sudo journalctl -u ssh -n 50 --no-pager | grep -i 'fail\|invalid\|refused'

# 4. World-writable files under /etc and /var/lib/5dive (should be empty).
find /etc /var/lib/5dive -maxdepth 4 -perm -o+w -type f 2>/dev/null

# 5. Setuid/setgid binaries not in the baseline (spot new surprises).
find / -maxdepth 5 \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null \
  | grep -v '^/usr/\|^/bin/\|^/sbin/'

# 6. Agent env files — confirm they are root-readable only.
ls -la /etc/5dive/connectors/
```

Report findings with a **Risk** label: `Low`, `Medium`, or `High`. Only flag
deviations from the expected baseline — an empty world-writable list is a pass,
not a finding.

## Rules of engagement

1. **Read before writing.** Run checks before attempting fixes.
2. **Fix one thing at a time.** Each fix should be verifiable — rerun the relevant check after each action.
3. **Never touch production credentials.** If you find a misconfigured key, report it; don't rotate it without explicit user approval.
4. **Security audit is opt-in.** Never run the security section automatically.
5. **Surface uncertainty.** If you can't determine the root cause, say so clearly rather than guessing.
