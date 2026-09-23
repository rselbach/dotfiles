### Autonomous run

**You own the exit condition. Define done, then drive to it without stopping.** For "going to bed", "run until done", or equivalent persistent-work requests.

1. State the exit condition as a checkable predicate before the first iteration (tests green, repro fixed, all N PRs merged, pixel-diff zero). A vague goal stalls; a predicate lets you stop.
2. Pick the host's supported wake mechanism. An event such as CI, a merge, or a ref advance gets an event watcher with a long heartbeat fallback. Without an event, use bounded recurring monitoring at an interval sized to when the result is worth re-checking. Under Codex, follow `../references/hosts/codex.md`; do not assume `/loop` exists.
3. Each iteration makes the smallest change the evidence justifies, verifies it against the predicate, commits if it advanced, discards changes that didn't help. Belt-and-suspenders that "might help" gets reverted, not left to ride.
   Sequence the work via the **sequence-verifiable-units** principle skill, verifying each unit before the next instead of batching checks at the end.
4. Address in-scope broken skills, related bugs, flaky verifiers, review noise, tooling failures, and fixable drift. Record out-of-scope discoveries as follow-ups; do not create additional PRs without authorization. Ask only for new authority, genuine product or preference calls no experiment can settle, or a real dead end. Keep the predicate as the main drive.
5. Checkpoint every iteration via the **show-me-your-work** skill, a row for what changed and whether the predicate moved. A run with no trail can't be audited or resumed.
6. Stop when the predicate is met. A plateau is not a stop, so keep going and pivot your approach to push past it. Surface a genuine dead end rather than spinning, and never relax the predicate to declare victory.

**Reply:** the exit condition, iterations run, what landed, what was discarded, final predicate state.
