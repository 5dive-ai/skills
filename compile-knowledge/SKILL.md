---
name: compile-knowledge
description: >-
  Compile durable knowledge into interlinked-markdown stores the "karpathy
  method" way — atomic files, [[wiki-links]], a maintained index. Use after
  producing research, intel, a digest, a learned non-obvious fact, or finishing
  any knowledge-shaped task, BEFORE you close it. Also when asked to "save this",
  "write this to the wiki", "update the wiki/memory", "log this finding",
  "structure this knowledge", or "follow the karpathy method".
---

# compile-knowledge

Durable knowledge is worth keeping as many small, interlinked markdown files,
compiled over time and surfaced through an index — not as one giant doc, a chat
log, or a one-off file that rots. This skill makes compiling consistent so your
agent gets smarter over time instead of relearning the same things.

## Where it goes — pick the right store

- **Agent memory** (default, always available): your `.claude/.../memory/`
  folder with `MEMORY.md` as the index. This is the per-agent store and it
  survives restarts — it's the karpathy "external memory" that keeps you sharp
  across sessions. Governed by the memory rules already in your system prompt —
  follow them. For most agents this is the only store you need.
- **Shared wiki** (only if you work as a team): a `wiki/` folder in your project
  with a `wiki/index.md`. For knowledge the *whole team* benefits from — domain
  facts, research findings, reference material multiple agents would re-derive.
  Skip this entirely if you're a solo agent; don't manufacture team ceremony.

Rule of thumb: "only I act on this" → memory. "Anyone on my team might need
this" → shared wiki. Cross-link between them with `[[slug]]` when they relate.

## Before you write — the hygiene gate

Compile ONLY a durable, non-obvious fact. Skip and move on if it is:
- routine / derivable from the repo, git history, or existing docs,
- true only for this one conversation,
- already covered by an existing file (→ UPDATE that file instead, don't duplicate).

Most tasks (a deploy, a restart, a one-line fix) produce nothing durable. That is
fine — do not manufacture a memory to "have written something." Filler is worse
than nothing; it pollutes recall.

## The procedure

1. **Search first.** Look for an existing file on this topic (grep the store +
   skim the index). If one exists, edit it — never create a near-duplicate.
2. **Atomic.** One fact / one topic per file. If you're tempted to add a second
   unrelated fact, that's a second file.
3. **Name it.** kebab-case slug, with a type prefix for memory
   (`feedback_…`, `project_…`, `reference_…`, `user_…`) or a clear topic slug for
   the wiki. The slug is the link target.
4. **Frontmatter.** `name` (= the slug), `description` (ONE line — this is what
   gets matched during recall, make it specific), and a `type`/category.
5. **Body.** State the fact plainly. Link related entries with `[[slug]]` —
   liberally; a link to a file that doesn't exist yet is a fine TODO marker. For
   `feedback`/`project`, follow with **Why:** and **How to apply:** lines.
6. **Index.** Add or update a ONE-LINE pointer in the index (`MEMORY.md` for
   memory; `wiki/index.md` for the wiki): `- [Title](slug.md) — hook`. Keep it
   under ~200 chars; detail lives in the file, never the index. **If the wiki
   `index.md` doesn't exist yet, create it** so the store stays discoverable.
7. **Hygiene.** Delete files that turned out wrong. Convert relative dates to
   absolute. If the index is getting long, tighten lines — don't let it bloat.

## Lifecycle — supersede, don't silently overwrite

Facts rot. When one is time-sensitive, uncertain, or replaces an older one,
stamp the envelope so recall can age it out instead of surfacing stale truth:

- **`valid_to: YYYY-MM-DD`** — date the fact expires / needs a recheck. Past it,
  recall keeps the fact but demotes + flags it `⚠ expired`.
- **`supersedes: <slug>`** — when a new fact replaces an old one, point at the
  old slug. The old fact is then demoted (`⤴ superseded`) in recall instead of
  lingering as a second, contradictory answer. Prefer this over edit-in-place
  when the OLD value is still worth seeing (audit trail); edit in place when it
  isn't.
- **`confidence: high|medium|low`** — low/medium facts are demoted so a hunch
  never outranks a verified fact.
- **`provenance: "<source>"`** — where the fact came from, distinct from
  `compiled_by` (who wrote the note).

`5dive memory add` writes these: `--valid-to=`, `--supersedes=`, `--confidence=`,
`--provenance=`. All optional — omit them and behaviour is unchanged.

## Anti-patterns

- A wall-of-text doc instead of atomic files.
- Research left as a standalone `notes.md` that never gets folded in — that's
  working notes, not knowledge. Compile the durable parts into the store.
- Duplicating a fact across memory AND wiki — pick one home, cross-link.
- Index entries that restate the whole file.
- Writing filler to satisfy a habit/checklist.

## Quick checklist

`[ ] durable & non-obvious? [ ] right store? [ ] updated existing vs new?`
`[ ] atomic + named + frontmatter? [ ] [[links]]? [ ] index line added?`
