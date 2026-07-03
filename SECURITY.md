# Security model

These skills are **instruction documents** (`SKILL.md` + reference markdown) that
teach an AI agent how to operate tooling. They are loaded as context by an agent
harness. **They contain no executable scripts** — nothing in this repository runs
on its own or is invoked as a build/install step.

## Why `5dive-cli` looks alarming to a heuristic scanner (and why it isn't)

Automated malware heuristics flag `5dive-cli` because its documentation describes
capabilities that *pattern-match* to malicious behavior:

| Flagged pattern | What it actually is |
| --- | --- |
| "inter-agent command injection" (`5dive agent send`) | Sending a message to another agent **the same operator owns, on the operator's own host**. This is the core function of an agent-orchestration tool — the equivalent of `ssh`, `kubectl exec`, or Ansible running a command on your own fleet. It is not remote code execution against a third party. |
| "credential auto-inherit via EnvironmentFiles" | Agents the operator **provisions themselves** on **their own machines** receive the operator's configured credentials — the same trust model as any CI runner or provisioning tool the operator sets up. |
| "self-update / skill-install / writable skill store" | A **first-party** update channel for the operator's own tooling, analogous to `apt upgrade`, `npm i -g`, or an IDE auto-update. |

Every one of these operates **within a single operator's own trust boundary**. The
`5dive` CLI is agent-orchestration infrastructure; like all such infrastructure
(`ssh`, `kubectl`, `ansible`, `terraform`), its legitimate capabilities overlap
with what an attacker would want — the same reason those tools are not malware.

## Trust boundary

- All agents driven by `5dive` run **as one operator**, on **that operator's own
  hosts**, under credentials **that operator configured**.
- `sudo` access is **by design**: these are single-tenant operator boxes, not
  shared multi-user systems. The operator already has root.
- `5dive agent send` reaches only **siblings in the operator's own fleet**; it
  cannot target machines or agents the operator does not control.

## Active hardening

We treat the *real* residual risk in this class of tooling seriously. Ongoing work
(internal refs DIVE-916 / DIVE-950) adds **tamper-evidence to human-approval
gates**: it closes a path by which one agent could self-clear an approval/secret
gate meant to require a human, replacing a forgeable proof token with a per-gate
nonce that only a verified human tap can emit. That is the correct place to invest
— authorization boundaries between agents — rather than removing the orchestration
capabilities themselves, which are the tool's intended function.

## Reporting a real vulnerability

If you believe you have found a genuine security issue in these skills (not a
false-positive flag on documented, intended capabilities), please email
**security@5dive.ai** rather than opening a public issue.
