# 5dive skills

Skills published by [5dive](https://5dive.ai?utm_source=github&utm_medium=referral&utm_campaign=skills-readme) for use with
[skills.sh](https://skills.sh/) and any agent harness that loads
`SKILL.md` bundles (Claude Code, openclaw, hermes, …).

| Skill                  | Purpose                                                       |
| ---------------------- | ------------------------------------------------------------- |
| [`5dive-cli`](./5dive-cli) | Drive the local `5dive` CLI on a 5dive runtime VM. Lets an agent spawn, inspect, send to, and tear down sibling agents on the same host. |
| [`diagnose`](./diagnose) | Self-diagnosis for 5dive agents. Runs auth, service, disk, memory, and skill-integrity checks on the VM and returns a root-cause report — so the agent can fix problems itself instead of asking the user. |
| [`compile-knowledge`](./compile-knowledge) | Compile durable knowledge into interlinked-markdown stores the "karpathy method" way — atomic files, `[[links]]`, a maintained index — so the agent gets smarter over time instead of relearning. Memory-first; shared wiki only for teams. |
| [`openagent`](./openagent) | Author your own OpenAgent persona and mint your shareable holo trading card. Self-service: write a `<id>.persona.yaml`, validate it, check your rarity tier (Common→Mythical) + completeness, render the PNG card, and PR into the character-packs registry. |
| [`copywriting`](./copywriting) | Write, rewrite, and improve conversion-focused marketing copy for any page — homepage, landing, pricing, feature, product. Headlines, CTAs, value props, taglines, hero sections. |
| [`ad-creative`](./ad-creative) | Generate and iterate ad creative at scale — headlines, descriptions, and primary text for paid platforms — and refine based on real performance data. |
| [`loops`](./loops) | The full lifecycle for agentic loops — recurring agents packaged as a portable [`LOOP.md`](https://agenticloops.dev?utm_source=github&utm_medium=referral&utm_campaign=skills-readme). Find + install + run an existing loop from the directory, or author a new one when nothing fits. The loop-level analogue of `find-skills` + `skill-creator` in one. |
| [`playwright-e2e`](./playwright-e2e) | End-to-end testing and click-verification of web apps with Playwright. Install, write specs, drive authenticated pages, screenshot, and run in CI. Use to prove a web change actually works in a real browser before shipping. |
| [`code-review`](./code-review) | Review a diff or pull request for correctness first, quality second. Logic bugs, edge cases, error handling, races, missing tests, API misuse, performance, readability, with a severity model and clear approve vs request-changes verdict. |

## Quick start (any coding agent)

Install straight from the [skills.sh](https://skills.sh/) directory with the open
`skills` CLI — works in Claude Code, Codex, Cursor, and any harness that loads
`SKILL.md`:

```bash
# mint your own OpenAgent persona + shareable holo card
npx skills add 5dive-ai/skills --skill openagent

# find, install, and run agentic loops (recurring agents)
npx skills add 5dive-ai/skills --skill loops

# or pull the whole set
npx skills add 5dive-ai/skills --skill '*'
```

`openagent` and `loops` are the best starting points — they work in any agent,
no 5dive account required. [`loops`](./loops) pairs with the open
[agenticloops.dev](https://agenticloops.dev?utm_source=github&utm_medium=referral&utm_campaign=skills-readme)
directory + `LOOP.md` spec.

## Install on a 5dive agent

From the dashboard: **Agents → Connect skills → 5dive-cli → Install**.

From the host:

```bash
sudo 5dive agent skill <agent-name> add \
  --source=5dive-ai/skills \
  --skill=5dive-cli
```

Or via the upstream `skills` CLI from any agent's home:

```bash
npx skills add https://github.com/5dive-ai/skills --skill 5dive-cli --agent claude-code --yes
```

## License

MIT.
