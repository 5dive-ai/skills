---
name: verify
description: Grade a delivered claim against the artifact instead of against the report of the artifact. Use when acting as a verifier or reviewer on someone else's finished work, checking whether a fix actually landed, confirming a task's done result is true, auditing a claim that has no diff to read — a backfill, a migration, a deploy, a config change — or self-auditing your own claim before you publish it. Covers splitting a claim into checkable assertions, the three-state verdict (pass, fail, not-reached), and the specific failure modes that survive a careless check. Keywords verify, verification, grade, verdict, acceptance, prove it, did it actually work, confirm the fix, check the claim, QA sign-off.
version: 1.1.0
license: MIT
---

# Verify

**A verifier's job is to distrust the shape of a claim and go look at the thing.**

This is not code review. Code review asks *is this change any good*. Verification asks *is the
statement made about this change true* — and it applies just as much when there is no diff to read
at all. A backfill that reports 40,000 rows, a migration described as reversible, a deploy announced
as live: each is a claim with an artifact behind it and nothing for a reviewer to read.

The output is a verdict someone else can act on without redoing your work.

## The one rule

**Check the effect, not the report of the effect.**

Almost every bad verification is some version of accepting the report. The command exited 0. The
function is defined. The follow-up ticket exists. The log says success. None of those are the thing
being claimed; they are artifacts that would *also* be produced if the claim were false.

Before accepting any piece of evidence, ask: **what would look identical if the claim were wrong?**
If the answer is "this exact output", the evidence is not evidence and you need a different
instrument.

## Procedure

1. **Extract the claim into separate assertions.** "Backfilled the table and made it idempotent" is
   two claims. Grade each on its own. A single verdict over a bundle lets one false thing launder
   through on the strength of the true ones.
2. **Name the artifact for each assertion.** Not the description, not the done-result, not the
   author's summary — the rows in the table, the running process, the response from the live
   endpoint, the committed file. Write down which one you looked at.
3. **Check that the artifact you read is the artifact that shipped.** A local working tree, a stale
   branch, a staging database and the deployed thing are different objects. Confirm they are the
   same, or say which one you graded.
4. **Try to make each assertion false.** Find the input, the ordering, or the environment where it
   breaks. A verification that only confirms is a re-reading.
5. **Emit a verdict per assertion**, with the instrument named.

## Three states, not two

`PASS` · `FAIL` · **`NOT-REACHED`**

The third one is the one people drop, and dropping it is how a broken check reads as a passing one.
If the probe did not run — no fixture, no credentials, the environment was missing, the code path
was never entered — that is **not a pass**. It is an absence of information, and it must render
differently from a clean result.

**Unmeasured and measured-clean must never look the same.** If your report cannot distinguish "I
checked and it was fine" from "I could not check", the report is broken regardless of the verdict.

**Composition rule: an overall verdict cannot be `PASS` if any assertion is `NOT-REACHED`.** A
headline PASS printed above a NOT-REACHED line reproduces the exact collapse this section exists to
prevent. Say "PASS on 2 of 3" and let the third stay visible.

## Failure modes that survive a careless check

These are the ones that get past people who are genuinely paying attention.

| Trap | What it looks like | The actual question |
| --- | --- | --- |
| **Defined is not called** | Grep finds the guard function, 17 matching lines. | Is there a **call site**? A never-invoked function matches every grep. |
| **Absent is not forbidden** | "It didn't happen in the test run." | Is it *prevented*, or did it merely not occur this time? |
| **Consistent-with is not evidence-for** | The run did X, so the cause must be Y. | Would something else also produce X? Usually yes. |
| **Succeeding in appearance** | Exit 0, "success" in the log. | Did the operation **do** anything? A no-op exits 0 too. |
| **Right number, wrong subject** | The arithmetic checks out. | What noun does this number describe? Reproducing it proves nothing. |
| **A failed read is not an absence** | Query returned empty → "there are none." | Did the probe run to **completion**? Empty, errored, and never-finished are three different results, and only the first is evidence of absence. |
| **The instrument is the anomaly** | Every row looks wrong. | What **fraction** of the population reads the same way? If everything is broken, suspect the tool before the subject. |
| **The caveat beside the payload** | A warning printed next to the misleading list. | Readers act on the payload. Don't emit the payload. |
| **Self-reported identifiers** | A run ID or job ID pasted in the description. | Is it checkable against a record **the claimant did not write**? |

## Grade the premise, not just the work

Sometimes the change is correctly built on something that cannot hold — a privilege boundary that
does not exist in the environment, an ordering guarantee nothing enforces, a file that another
process rewrites. The work is fine and the claim still fails.

When you reject on a premise, say which premise and what measurement killed it. "This relies on X
being true; I measured X and it is false" is actionable. "Doesn't look right" is not.

## Writing the verdict

State, in this order: **the verdict**, **what you checked it against**, and **what the verdict does
not extend to**.

```
PASS on 2 of 3 intents, verified against the production table — not the migration script.
  1. backfill touched 40,312 rows — PASS. Counted rows with filled_at set against the
     pre-run snapshot. The job's own log said "40k", which was rounded, not measured.
  2. no existing values were overwritten — PASS. Checksum of the untouched column is
     unchanged from the snapshot.
  3. re-running is idempotent — NOT-REACHED. No safe way to re-run against production,
     and staging has 0 matching rows, so the staging run would have proved nothing.
THIS VERDICT DOES NOT EXTEND TO: rows created after the snapshot was taken.
```

Note what the third line does. Running it in staging would have produced a green — against zero
matching rows. **A check that cannot fail is not a check**, and reporting it as NOT-REACHED is the
honest result.

The scope line is not a confession and it is not optional. Frame it as *what this verdict covers*,
which is answerable even when coverage was complete. A verdict that lists only what was confirmed
reads as total coverage, and the next person will believe it.

## Bounce, or fix and hand back?

**Bounce** when the work is wrong, when the premise fails, or when the claim overstates what the
artifact does. Give the reason and the measurement, not a vibe — the maker has to act on it.

**Locate and post** when the work is right and only the *receipt* is missing — the run happened but
the log was left somewhere nobody else can read. Attaching the evidence is faster than a round trip
and keeps the record honest.

## On verifying your own work

Auditing your own claim before you publish it is worth doing, and this procedure applies to it. It
lowers what a verifier finds.

**It does not make you the verifier of record.** If a process names a maker and a separate verifier,
the point is that two different contexts looked at the artifact — grading your own work reproduces
the reasoning that produced the mistake. Self-audit reduces the defect rate; it does not discharge
the independent check.

## See also

[`code-review`](../code-review) — the complementary skill. Use `code-review` when you have a diff
and the question is whether the change is any good; use `verify` when you have a claim and the
question is whether it is true.
