---
name: verify
description: Grade a delivered claim against the artifact instead of against the report of the artifact. Use when acting as a verifier or reviewer on someone else's finished work, checking whether a fix actually landed, confirming a task's done result is true, or auditing your own claim before you publish it. Covers splitting a claim into checkable assertions, the three-state verdict (pass, fail, not-reached), and the specific failure modes that survive a careless check. Keywords verify, verification, grade, verdict, acceptance, prove it, did it actually work, confirm the fix, check the claim, QA sign-off.
version: 1.0.0
license: MIT
---

# Verify

**A verifier's job is to distrust the shape of a claim and go look at the thing.**

This is not code review. Code review asks *is this change any good*. Verification asks *is the
statement made about this change true*. A change can be well written, well tested, merged, and
still have a done-result that says something the artifact does not support.

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

1. **Extract the claim into separate assertions.** "Fixed the retry loop and added a test" is two
   claims. Grade each one on its own. A single verdict over a bundle lets one false thing launder
   through on the strength of the true ones.
2. **Name the artifact for each assertion.** Not the PR description, not the done-result, not the
   author's summary — the committed file, the running process, the row in the database, the
   response from the live endpoint. Write down which one you looked at.
3. **Check that the artifact you read is the artifact that shipped.** A local working tree, a stale
   branch, and the deployed commit are three different things. Confirm they are the same, or say
   which one you graded.
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

## Failure modes that survive a careless check

These are the ones that get past people who are genuinely paying attention.

| Trap | What it looks like | The actual question |
| --- | --- | --- |
| **Defined is not called** | Grep finds the guard function, 17 matching lines. | Is there a **call site**? A never-invoked function matches every grep. |
| **Absent is not forbidden** | "It didn't happen in the test run." | Is it *prevented*, or did it merely not occur this time? |
| **Consistent-with is not evidence-for** | The run did X, so the cause must be Y. | Would something else also produce X? Usually yes. |
| **Succeeding in appearance** | Exit 0, "success" in the log. | Did the operation **do** anything? A no-op exits 0 too. |
| **Right number, wrong subject** | The arithmetic checks out. | What noun does this number describe? Reproducing it proves nothing. |
| **A failed read is not an absence** | Query returned empty → "there are none." | Did it return empty, or **error**? Positive-control the probe. |
| **The caveat beside the payload** | A warning printed next to the misleading list. | Readers act on the payload. Don't emit the payload. |
| **Self-reported identifiers** | A run ID or box ID pasted in the description. | Is it checkable against a record **the claimant did not write**? |

## Grade the premise, not just the work

Sometimes the change is correctly built on something that cannot hold — a privilege boundary that
does not exist in the environment, an ordering guarantee nothing enforces, a file that another
process rewrites. The diff is fine and the claim still fails.

When you reject on a premise, say which premise and what measurement killed it. "This relies on X
being true; I measured X and it is false" is actionable. "Doesn't look right" is not.

## Writing the verdict

State, in this order: **the verdict**, **what you checked it against**, and **what you did not
check**.

```
PASS on 2 of 3 intents, verified against committed artifact <sha> (== deployed HEAD).
  1. retry terminates on 5xx — PASS, traced a failing request through the new path
  2. test covers the new branch — PASS, test fails against the pre-change commit
  3. metric emitted on give-up — NOT-REACHED, no metrics backend in this environment
NOT CHECKED: behaviour above the configured retry ceiling.
```

The "not checked" line is mandatory and it is the most valuable part. A verdict that lists only
what was confirmed reads as total coverage, and the next person will believe it.

## Bounce, or fix and hand back?

**Bounce** when the work is wrong, when the premise fails, or when the claim overstates what the
artifact does. Give the reason and the measurement, not a vibe — the maker has to act on it.

**Locate and post** when the work is right and only the *receipt* is missing — the run happened but
the log was left somewhere nobody else can read. Attaching the evidence is faster than a round trip
and keeps the record honest.

**Never close it yourself.** If a loop names a maker and a verifier, the point is that two different
contexts looked at it. Grading your own work reproduces the reasoning that produced the mistake.
