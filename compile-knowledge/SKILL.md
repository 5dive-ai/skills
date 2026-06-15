---
name: compile-knowledge
description: >-
  Compile durable knowledge into the team's interlinked-markdown stores the
  "karpathy method" way — atomic files, [[wiki-links]], a maintained index.
  Use after producing research, market/competitor intel, a digest, a learned
  non-obvious fact, or finishing any knowledge-shaped task, BEFORE you close it.
  Also when asked to "write this to the wiki", "save this", "update the
  wiki/memory", "log this finding", "structure this knowledge", or "follow the
  karpathy method".
---

# compile-knowledge

The team runs on the **karpathy method**: knowledge is kept as many small,
interlinked markdown files, compiled over time, and surfaced through an index —
not as one giant doc, a chat log, or a one-off file that rots. Two production
stores already work this way; this skill makes compiling into them consistent.

## The two stores — pick the right one

- **Agent memory** (per-agent, personal + operational): your
  `.claude/.../memory/` folder with `MEMORY.md` as the index. For things only
  *you* need: user preferences, feedback you were given, your project state.
  Governed by the memory rules already in your system prompt — follow them.
- **Team wiki** (shared domain knowledge): `community/wiki/` with an index
  (`index.md`). For knowledge the *whole fleet* benefits from: competitor/market
  intel, Anthropic/ecosystem state, durable reference facts, research findings.

Rule of thumb: "only I act on this" → memory. "Anyone on the team might need
this" → wiki. Cross-link between them with [[slug]] when they relate.

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
3. **Name it.** kebab-case slug with a type prefix:
   `feedback_…`, `project_…`, `reference_…`, `user_…` (memory) or a clear topic
   slug (wiki). The slug is the link target.
4. **Frontmatter.** `name` (= the slug), `description` (ONE line — this is what
   gets matched during recall, make it specific), and a `type`/category.
5. **Body.** State the fact plainly. Link related entries with `[[slug]]` —
   liberally; a link to a file that doesn't exist yet is a fine TODO marker. For
   `feedback`/`project`, follow with **Why:** and **How to apply:** lines.
6. **Index.** Add or update a ONE-LINE pointer in the index
   (`MEMORY.md` for memory; `community/wiki/index.md` for the wiki):
   `- [Title](slug.md) — hook`. Keep it under ~200 chars; detail lives in the
   file, never in the index. **If the wiki `index.md` doesn't exist yet, create
   it** (one line per existing wiki page) so the store stays discoverable.
7. **Hygiene.** Delete files that turned out wrong. Convert relative dates to
   absolute. If the index is getting long, tighten lines — don't let it bloat.

## Anti-patterns

- A wall-of-text doc instead of atomic files.
- Research left as a standalone `DIVE-NNN-notes.md` that never gets folded in —
  that's working notes, not knowledge. Compile the durable parts into the wiki.
- Duplicating a fact across memory AND wiki — pick one home, cross-link.
- Index entries that restate the whole file.
- Writing filler to satisfy a habit/checklist.

## Quick checklist

`[ ] durable & non-obvious? [ ] right store? [ ] updated existing vs new?`
`[ ] atomic + named + frontmatter? [ ] [[links]]? [ ] index line added?`
