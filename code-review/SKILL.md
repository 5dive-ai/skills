---
name: code-review
description: Review a diff or pull request for correctness and quality — logic bugs, edge cases, error handling, race conditions, missing tests, API misuse, performance, and readability. Use when reviewing a PR, auditing a change before merge, giving feedback on someone's code, or self-reviewing your own diff. Keywords code review, PR review, pull request, diff review, review my changes, approve, request changes.
version: 1.0.0
license: MIT
---

# Code Review

Review a change for correctness first, quality second. A review is not a formatting pass — it's a
search for the ways this diff is wrong or will become wrong. Approve when you'd be comfortable
being paged for it at 3am.

## Scope the review before reading line-by-line

Don't review the diff in isolation. A diff shows what changed, not whether the change is correct.

1. **Read the description / linked issue.** What is this change *claiming* to do? You're verifying
   the claim, not just the syntax.
2. **Read the surrounding code, not just the red/green lines.** A removed null check looks fine in
   the diff; whether it's a bug depends on the caller three functions up. Open the files.
3. **Reproduce the claim mentally (or actually).** Trace one real input through the new path. If the
   PR says "fixes the retry loop," follow a failing request through the loop and confirm it now
   terminates. If you can run it, run it.
4. **Check the tests changed with the code.** New behavior with no new test is a finding. A test
   that passes against *both* the old and new code tests nothing.

## What to actually look for

Go in this order — correctness bugs are worth more than style nits.

| Category | Concretely |
| --- | --- |
| **Logic bugs** | Off-by-one, inverted conditions, wrong operator (`&&` vs `\|\|`), `=` vs `==`, swapped args, fallthrough. |
| **Edge cases** | Empty list/string, zero, negative, `null`/`None`/`undefined`, single element, max size, duplicate keys, unicode. |
| **Error handling** | Swallowed exceptions, ignored return/error values, partial failure leaving inconsistent state, no cleanup on the error path, error message that loses the cause. |
| **Concurrency** | Shared mutable state without a lock, check-then-act (TOCTOU), non-atomic read-modify-write, missing `await`, deadlock-prone lock ordering, assuming callback order. |
| **Resource safety** | Leaked file/socket/connection, missing `close`/`defer`/`finally`/context manager, unbounded growth (caches, queues). |
| **API misuse** | Calling a function with wrong assumptions about its contract, ignoring documented preconditions, depending on undefined behavior or implementation details. |
| **Boundaries / input** | Untrusted input used unvalidated (defer real security to a dedicated security review, but flag the obvious). |
| **Tests** | New branch with no test, happy-path-only coverage, assertions that can't fail, flaky timing-dependent tests. |
| **Performance** | N+1 queries, work inside a hot loop that could hoist out, accidental O(n²), a query with no index, loading a whole collection to count it. Flag only when it matters at expected scale. |
| **Readability / reuse** | Duplicated logic that already exists elsewhere, a 6-deep nesting that an early return flattens, a name that lies about what the thing does. |

## Severity model

Tag every finding so the author knows what blocks merge and what doesn't.

| Severity | Meaning | Blocks merge? |
| --- | --- | --- |
| **Blocker** | Correctness bug, data loss, security hole, breaks the build/tests. | Yes |
| **Major** | Likely-wrong under realistic conditions, missing error handling on a real failure path, missing test for new behavior. | Usually |
| **Minor** | Works, but harder to maintain, slightly off-pattern, small inefficiency. | No |
| **Nit** | Pure style/naming preference. Prefix with `nit:` so it's clearly optional. | No |

If you can't articulate the failure mode, it's at most a Minor — don't inflate taste into a Blocker.

## How to phrase feedback

A useful comment points at a line, names the failure, and proposes a fix. Three parts:

> **`payment.go:142` (Blocker)** — If `charge()` throws after `markPaid()` runs, the order is marked
> paid but no charge exists; the next reconciliation will refund a payment that never happened.
> Move `markPaid()` after the charge succeeds, or wrap both in a transaction.

- **Point at `file:line`** so it's locatable.
- **Explain the failure mode** ("if X then Y goes wrong"), not just "this is wrong."
- **Suggest the fix** — even a rough direction. A finding with no path forward stalls the PR.
- **Ask, don't assert, when unsure.** "Is `items` guaranteed non-empty here? If a caller can pass
  `[]`, this indexes out of bounds." — invites the author to confirm rather than starting a fight.
- **Praise sparingly and specifically** when a tricky thing is done well; it calibrates the rest.

Avoid: vague drive-bys ("this seems off"), restating the diff, bikeshedding naming on a Blocker-laden
PR, and demanding rewrites that don't change behavior.

## Approve vs request changes

- **Approve** — no Blockers or Majors; remaining items are Minors/Nits you're happy to see deferred.
  Approving with a couple of `nit:`s the author can take or leave is normal and keeps things moving.
- **Request changes** — any Blocker, or a Major that materially risks correctness. Be explicit about
  *which* findings gate the merge so the author isn't guessing.
- **Comment (no verdict)** — you have questions that change your assessment depending on the answer,
  or you only skimmed and want to flag that.

Don't block a PR on preferences. Don't approve a PR you didn't actually understand — "LGTM" on a
diff you skimmed is how bugs ship.

## Review checklist

- [ ] I read the description and know what the change claims to do
- [ ] I read the surrounding code, not just the diff lines
- [ ] I traced at least one real input through the new path
- [ ] Edge cases covered: empty / null / zero / negative / max / duplicate
- [ ] Every error/failure path leaves state consistent and is observable
- [ ] No shared mutable state touched without synchronization
- [ ] Resources are released on every path (success and error)
- [ ] New/changed behavior has a test that fails against the old code
- [ ] No obvious N+1, accidental quadratic, or unindexed hot query
- [ ] No duplicated logic that already exists in the codebase
- [ ] Every finding is tagged with a severity and names a failure mode
- [ ] My verdict (approve / request changes) matches the findings
