---
name: baby-lease
description: "Keep the Mac awake with a Baby lease while you work. Use at the start of every task that runs commands, edits files, or takes more than a few steps, and release the lease before you end your turn."
---

# Baby Lease

Baby keeps the Mac awake while any lease is held. Hold one while you work so
the Mac does not sleep in the middle of a task. Release it when you stop.

Run `scripts/lease.sh` from this skill's directory.

## Hold

At the start of a task, before the first long step:

```bash
scripts/lease.sh hold "short task label"
```

- The lease is tied to your agent process, so it ends if you exit or crash.
  It also expires after 2 hours.
- Holding is idempotent. Running `hold` again refreshes the same lease, so run
  it at the start of each new request and before any command you expect to run
  for a long time.
- When Baby is not installed, the script says so and exits 0. Continue without
  mentioning it.
- When `hold` fails, tell the user once in your reply and continue the task.
  Do not retry in a loop or debug Baby unless asked.

## Release

Release whenever you end your turn. That covers a finished task, a failed one,
and a question you are waiting on the user to answer.

```bash
scripts/lease.sh release
```

Releasing a lease that already ended succeeds. Never release a lease you did
not hold.
