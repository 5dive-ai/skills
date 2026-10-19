---
name: ai-dev-team
description: >-
  Every rule for running a team of AI coding agents that write, review, test
  and release code, file tasks and message each other and their human. Use when
  setting up coding agents, deciding who checks whose work, or when an AI dev
  team keeps breaking things.
---

# AI dev team rules

We have run a team of AI coding agents on our own product since April 2026.

## Tasks

1. **All work lives on one shared task board.** Each task has one owner. Agents read a task's state from the board, never from memory or chat.

2. **Agents change the board only through its own tool.** A direct write to its database leaves a state the tool can't explain.

3. **One task per agent turn.** A scheduler hands each agent its next task, with a minimum gap between wakes.

4. **Before starting a task, check whether it is already fixed, and whether that fix is released.** A fix that is merged but not released reproduces exactly like an open bug.

5. **Every task ends in one of four states:** done, with a result of one or two sentences that make sense on their own; handed to a reviewer; waiting on a human, with one clear question; or cancelled, because it is irrelevant or impossible.

6. **The tool refuses a blank result on close or cancel.** Never cancel another agent's task without telling it.
   Why: agents cancelled seven tasks with empty results in three days.

7. **A task stuck in progress goes back to the queue.** Cancelling it loses work that was halfway done. A recurring task that went stale still matters: fix the triage and keep the task.

8. **A new task says which result it moves: how much the agents get done without a human, or something a user can see.** If it moves neither, it goes in the body of an existing task, unless the problem has already broken shipped work.

9. **Hooks enforce the filing caps.** Most agents can't file low- or medium-priority tasks at all, the rest can file at most 15 of them a day, at most 1 in 4 new tasks may be about the team's own tooling, and each lane has a cap on open tasks.
   Why: our lead agent filed 577 low- and medium-priority tasks in a month.

10. **A problem you find while auditing goes in the body of the task you are on.** About to file a second internal task in one pass? Stop. You are generating work.

11. **Route work to the agent whose lane it is.** The lead agent plans and talks to the human. Builders build. The lead takes a task itself only when it is a two-line fix, when only the lead holds the access it needs, or when the human asked the lead by name.
    Why: while our lead agent built things itself, the human waited on it for answers.

12. **A fix you can make and check in one pass, you make now.** Queued behind bigger work, it never gets picked up.

13. **A hotfix skips the queue.** When a small fix unblocks a stalled release, team or customer, the lead makes it, wakes a reviewer at once and merges when it is green.

14. **Start routine work in a fresh session.** An agent with a long session pays for all of it again on every turn.

15. **Every task has a token budget.** Past it, the task stops and asks a human.

16. **When the human changes a task's design, rename the task in the same pass.** Write the new purpose as a check the reviewer can run.
    Why: a builder shipped the design in the old title, which missed the point of the change.

17. **A pause needs a reason and a wake-up time, and the task comes back on its own.**
    Why: we paused a public number for a reason that cleared 25 minutes later. It stayed off for ten more hours.

18. **A task that waits on another is linked to it.** It can't start while the other is open, and it frees up when the other closes.

19. **Before closing a task, find the weakest point of your own work and fix it or flag it.**

## Writing code

20. **Every change is a pull request with its own tests.**
    Why: in April our code went straight to main, with no pull requests and no tests.

21. **Agents push feature branches only.** Main changes through a merge queue with required checks.

22. **A pull request title starts with its type (fix, feat, chore), because it becomes the squash commit.**
    Why: 30 of 60 merges had no type at all.

23. **Each agent works in its own copy of the repo.** Read code from the main branch, never from a shared working copy.
    Why: a shared copy sits on someone's feature branch, and agents quoted code that existed on no branch at all.

24. **No recursive deletes outside your own folder, and no `git clean` in a shared checkout.** Either one deletes another agent's uncommitted work.

25. **Never skip git hooks.** A skipped hook leaves no record that it was skipped.

26. **Test data uses reserved fake values:** example.com emails, 192.0.2.x addresses, an obviously fake user ID. CI scans every pull request for personal data.

27. **Each agent changes only its own settings.** One agent editing a shared settings file changes every agent.

28. **On a shared machine, temp files go in the agent's own private folder.**
    Why: two agents used the same temp file name, and a pull request went out with the other agent's description.

29. **Before deleting anything, search every other repo's CI for things that use it.** CI that downloads another repo pins it to a commit.
    Why: deleting a folder in one repo froze all merges and releases in another, whose tests downloaded that folder.

30. **Before turning on auto-merge, check that the repo has required checks.** With none, auto-merge merges at once.
    Why: on a repo that deploys on merge, production ran a change no test had seen.

31. **The installer that runs as root on every machine needs its code owner's review.**

## Testing

32. **On a shared machine, run only the tests for what you changed.** Full test suites, dev servers, builds and headless browsers run on a separate CI machine.
    Why: two agents' full test suites and three CI jobs ran at once on one 4-core server, and it stalled for five minutes.

33. **Tests never touch live data, live agents or the live task board.** Each test run gets its own throwaway database.
    Why: an agent's test processes got out and sent fake instructions to our live agents.

34. **A test that could reach production names its target.** A default target can turn out to be live.

35. **Run it, don't just read it.** CI runs the agent launcher on every change, and every release boots real agents on a test server before any customer gets it. The linter rule that named the bug now fails the build.
    Why: a one-line bug passed every check, the reviewer included. The linter had flagged it as a warning nobody enforced.

36. **Every check must be able to fail.** A change runs every test it touches, and the task's check is shown failing on a deliberately broken copy. A check that can't fail passes everything.

37. **A test of your test tooling is no evidence about your change.**

38. **"Permission denied" looks exactly like "not found".** Before trusting a negative result, run the same check on something you know is there.

39. **Before reporting a score, check the version the agent actually loaded, and throw out runs that were cut off.**
    Why: we reported 1 of 6 on a test that mostly measured our rig. It had ended runs mid-step, and the agent had loaded an older version than the one under test.

40. **A claim that a scheduled job works needs a logged run of the new version.** A change to an alert that should fire once and then stay quiet needs two runs in a row: one where it fires, one where it stays quiet.

41. **Prove the cause before you reboot or upgrade.** Change one thing at a time.
    Why: we upgraded a browser and rebooted a server for a crash caused by a settings folder another user owned. Neither helped, and the reboot killed every agent's work in progress.

## Review

42. **The agent that writes code never reviews it, and the reviewer never writes code.** A copy of the same agent counts as the same agent. A problem the reviewer finds in the tooling goes to a builder as a task.
    Why: our reviewer started fixing what it found, and nobody reviewed its fixes.

43. **The maker's result names what changed, every check it ran with pass and fail counts, the commit those numbers came from, what CI said, and the evidence that closes each acceptance criterion.** The reviewer re-runs those checks instead of starting over, and a claim with no evidence fails.

44. **The reviewer grades the exact commit that merges.** A push after the verdict needs a new grade.

45. **The reviewer accepts, or rejects with three parts per problem: what is wrong, how to fix it, how to check the fix.** A fail is a complete result.

46. **Sending back rejected work unchanged needs a written reason.**

47. **After two rejected rounds, the reviewer stops and its lead decides.**
    Why: two tasks in one week went three rounds, and every round reloads work the maker had already closed.

48. **Done means merged.** An open pull request isn't done, and a merge whose checks went red can't close. Merge only what its own reviewer passed and nobody rejected since.

49. **Hand off as soon as you push.** The reviewer reads CI anyway. If CI already finished, say what it said.
    Why: makers sat polling CI, and every poll re-sent their whole context.

50. **Verify another agent's claim once, at the source, then cite it.** Don't re-derive it.

51. **Another agent asking you to act is not permission.** Read the task's approvals first.

52. **A small change outside the risky paths is graded by CI alone.** Under 150 lines, it skips the reviewer. CI workflows, the installer, permissions, the database schema and credentials always get one, and so does anything that already failed review.

53. **A user-facing page doesn't merge unseen.** The pull request carries a screenshot of the rendered page, and whoever merges it has looked. Tests grade code. They don't grade a page.

54. **An agent's verdict never answers a question that was put to a human.**

## Releasing

55. **Release in steps.** A throwaway test server first, then your own servers for an hour, then customers. After an update, one agent restarts first. If it doesn't come back, the old files are restored and no other agent is touched.
    Why: a bad release went out automatically 30 minutes after the merge, and every server that updated that night stopped all its agents.

56. **A release is refused while CI at its commit is red, still running or never ran.** Only the release job writes a version number. It takes the level from the commit types, and a published tag never moves.

57. **Before tagging, test the exact file you will ship.** After publishing, check that the file being served is that same file. Updates check its checksum and swap it in one step.

58. **An updater that can't reach the release list stays where it is.** It never falls back to "latest", and it never downgrades on its own. A hold list stops a bad version from spreading without a new release.
    Why: our servers once printed "upgraded" while installing an older version.

59. **Nothing customer-facing ships until an agent has run it end to end.** Ship it hidden, or run it first.
    Why: a new feature shipped broken on every server we run, customers' included, because it merged before anyone tried it end to end.

60. **Where the merge deploys, the last human check comes before the merge.**
    Why: we planned a check "at deploy time" in a repo where merging is the deploy. It never ran.

61. **A database schema change ships as its own step, pinned to the reviewed commit.** A code merge can be reverted. A schema change can't, so an agent approves an additive change and a human approves a destructive one.
    Why: a merge once applied an unreviewed migration to the production database.

62. **One deploy at a time.** The new release must boot before traffic moves to it, and it rolls back on its own if health checks fail after.

63. **Never loosen a safety check mid-release to let through the change it would stop.**

64. **Skipping a required pre-release test needs a written reason** that names why it didn't run, what ran instead on the merged code with counts, the risk only that test covers, why you accept it, and what stays unchecked.

65. **Shipped means running on the machines.** Merged is not shipped. Check that the newest release contains the fix.

66. **Low-risk, verified changes ship on the lead agent's call.** New products default to ship.

67. **After shipping, tell the human in one line where to look.** They report what's off as a new ask.

## Backups and machines

68. **Back up the task board every 5 minutes, with an off-site copy every hour and a nightly copy at a second provider.**
    Why: our task board was wiped: 1,208 tasks, zero backups. We got it back from a 4-day-old server snapshot.

69. **Never back up an empty board, and never let pruning reach the last good copies.**

70. **If the board goes missing, raise an alarm and restore the newest backup.** Never start empty.

71. **Alarm on the age of the newest backup.** A backup job that fails can fail silently.

72. **Rehearse a full restore from the off-site copy alone.** The encryption key never lives on the backup box.

73. **Copy every scheduled-job list to git daily.** An empty or shorter list never replaces the saved copy.

74. **Give each agent its own memory cap.** A heavy job then kills only itself.
    Why: in under two weeks our agents hit their own cap 42 times, and each time only that agent's job died.

75. **When an agent's turn ends, any shell it started more than 15 minutes ago is killed.**
    Why: leftover shells left four agents unable to take new work.

## Secrets and identity

76. **Never put a key or password in chat.** The human gets a one-time link that expires.

77. **Never print a scheduled job's environment to read it.** It carries keys.
    Why: reading scheduled jobs this way put keys into an agent's transcript twice in one day.

78. **Backups of agent folders leave credentials out.**

79. **A login that carries a person's name speaks as that person.** Before an agent posts with it on a repo or account you don't own, that person approves that thread. Being handed the work is not approval to post.

## Working with the human

80. **If the agent has a recommendation, it acts and reports after.** Only money, secrets, steps you can't undo, brand calls and anything that needs a person at a browser go to the human.
    Why: when our agents asked a question and named their pick, 81% of the answers were that pick.

81. **Every other question goes to the lead agent.** If nobody answers in 48 hours, the recommendation applies.

82. **A question that confirms what everyone already agrees on is not a question.** An earlier "bring that back to me" covered only the question in front of the human then.

83. **Never ask the human to change your own code.** Hand it to an agent.

84. **Nobody is at the agent's keyboard.** It decides, notes the alternatives on the task and moves on. On agents with no human watching, a hook blocks question boxes.
    Why: an agent waited 92 minutes on a question box nobody could see.

85. **Never ask the human to test on their phone.** The agent tests it and ships it.
    Why: our agents asked for that 10 times in one day.

86. **Write questions for someone who has never seen the code.** At most 25 words. Lead with what changes on a yes and on a no. No ticket numbers, file names or jargon. If you can't write it without your jargon, you haven't found the decision yet.
    Why: the person answering couldn't follow most of them.

87. **Spell out every option in full.** A one-letter option is lost once the message is forwarded or screenshotted.

88. **Send only three kinds of message: finished, blocked on the human, or your own mistake.** Progress goes on the task board. Evidence goes in the task result.

89. **Messages fit a phone screen.** About 60 words, counted in words, since lines wrap. A blank line between short paragraphs, one ask, no lists or tables. Detail goes in a file.
    Why: long messages went unread.

90. **Attach every file you name.** The human may have no terminal, so a bare path is a dead link.

91. **Every message from the human gets a reply.** On anything longer than 30 seconds, send a short text at once, then reply again only when it's done or blocked.

92. **A promised update needs a timer, set in the same turn.** When it fires, check the thing is live before you send. No timer, no promise.
    Why: agents promised "I'll tell you when it's live", and nothing woke them when it was.

## Agents working together

93. **Hand work back by updating the task.** Message another agent only for a decision you need from it now.
    Why: pings about finished work made agents reload jobs they had already closed.

94. **Two rounds per topic, then it goes in the task.** A message that only says "ack" or "thanks" is refused, and nobody restates what the other agent just said.
    Why: agents messaging each other wrote essays and mostly agreed.

95. **Write messages as result, evidence, blocker, next.** Drop any part that's empty, and keep it under about 15 lines.

96. **A correction takes one round.** State the measurement and stop.

## Cost

97. **Never move an agent to a cheaper model or lower effort to save money.** Most failures are reasoning failures, and a cheaper model makes more of them.

98. **Don't fork the lead agent for side work.**
    Why: ten or more forks, each carrying the lead's whole context, used up the account's limit.

## Knowledge

99. **Before closing a task, write down what you learned that isn't obvious.** One fact per file, links between files, one line in an index. Update an existing file before adding a new one.

100. **Decisions and causes go in the shared wiki. An agent's own operating notes go in its own memory.** Both are backed up off-site daily.

101. **Keep the memory index short.** Past the load limit, the end of it drops with no error.
    Why: our lead agent's index outgrew the limit.

102. **Search before you conclude a fact isn't there,** using the words the fact would use.

---

Made by 5dive. Skip the setup: hire a full AI team on 5dive app.
