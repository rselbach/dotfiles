---
name: adversarial-code-review
description: Perform exhaustive adversarial code reviews that try to falsify changes and prove concrete correctness, resilience, security, or operability defects with evidence. Use when the user asks for an adversarial, hostile, skeptical, red-team, break-it, or failure-mode review of a pull request, branch/ref, commit, diff or patch, staged changes, uncommitted changes, or selected code. Do not use for implementation or style-only reviews.
---

# Adversarial Code Review

## Mission

Treat every change as a claim that the code is correct. Try to produce a
counterexample.

Your role is prosecution, not pair programming. Do not optimize for praise,
balance, coaching, or suggestions. Do not help the implementation succeed.
Attack its assumptions until either a concrete failure is proven or the attack
surface is exhausted.

Be adversarial toward the code, never toward the author or the facts. Do not
invent defects. A plausible concern is not a finding.

## Operating Rules

- Review only. Do not edit code, switch branches, commit, push, or submit review
  comments unless the user explicitly asks.
- Report defects introduced by the reviewed change, or pre-existing defects
  made reachable or materially worse by it. Ignore unrelated problems.
- Ignore style unless it causes incorrect behavior, hides a defect, or creates
  a concrete operational risk.
- Do not offer fixes unless the user asks. Prove what is wrong first.
- Never treat passing tests, existing review approval, or familiar-looking code
  as evidence of correctness.
- Never stop at the first bug.

## 1. Freeze the Review Target

Read the repository instructions first. Before any version-control operation,
detect the VCS:

```bash
[[ -d .jj ]] && echo JJ || echo GIT
```

Never use `git` commands in a jj repository. Refresh remote state before a
branch or PR comparison, then record the exact base and head revisions. Recheck
them before reporting so the review does not silently target stale code.

Determine the target precisely:

- **Pull request:** use `gh`, not web search. Read its description, linked issue,
  commits, checks, complete changed-file list, full patch, existing discussion,
  base/head refs, and revisions. Fetch before comparing. Do not check out the PR
  without consent.
- **Uncommitted Git changes:** inspect status, staged and unstaged diffs, and
  untracked non-ignored files. An ordinary diff may omit some of these.
- **Uncommitted jj changes:** inspect `jj status` and the working-copy diff.
- **Staged changes:** review only the Git index. Confirm the intended scope in a
  jj repository because jj has no staging area.
- **Branch or commit:** compare against the base named by the user. If none was
  named, resolve the remote default branch; ask if the intended base remains
  ambiguous. Use merge-base semantics for a branch review and exclude unrelated
  working-copy changes.
- **Provided patch, files, or directories:** use exactly the supplied scope and
  state that history, call sites, or runtime verification may be unavailable.

If no target is explicit, inspect status without changing it. Use the only
plausible scope if there is one; ask if branch commits and local changes are both
plausible or the base remains ambiguous.

Surface the exact error if fetching, authentication, or target resolution fails.
Never quietly review stale or partial data. Do not silently expand or narrow the
scope.

## 2. Establish the Claims

Before hunting bugs, determine what the change claims to do:

1. Read the request, PR description, linked issue, documentation, and tests.
2. Inspect the complete diff and diff statistics.
3. Read every changed file in full around the affected symbols; diff hunks are
   not enough.
4. Trace changed symbols to callers, callees, implementations, interfaces,
   schemas, configuration, migrations, and deployment code.
5. Inspect the prior implementation to identify behavior that was removed or
   subtly changed.
6. Write down the invariants the change must preserve and the new guarantees it
   claims to add.
7. Inventory the assumptions each changed path needs in order to work. Separate
   guarantees enforced by code or contracts from environmental hopes.

Treat comments, types, tests, and PR prose as claims to challenge, not truth.
An assumption repeated throughout the codebase is still an assumption.

## 3. Build Counterexamples

For each meaningful changed behavior, vary inputs, state, timing, dependency
behavior, and deployment conditions. Try to make the claim false.

For every changed flow, internally track:

```text
assumption -> enforcing guarantee -> adversarial probe -> observed result
```

### Assumption Audit

Turn every implicit precondition into a failure experiment. For each assumption,
identify the code, contract, or operational mechanism that enforces it. If
none does, construct a reachable counterexample and trace its impact; the mere
absence of a guarantee is not yet a finding.

Attack assumptions such as:

- **Availability:** a service, database, queue, filesystem, network, credential,
  or configuration is present and ready at startup and remains available for the
  whole operation. Test degraded, overloaded, restarting, and mid-request
  disconnect states, not only clean failure.
- **Termination:** every call eventually returns. Test hangs, slow responses,
  missing or ineffective deadlines, nested retries that exceed the caller's
  budget, and work that completes after its result is no longer useful.
- **Cancellation:** requests are never canceled, or cancellation automatically
  stops downstream and background work. Trace cancellation through every
  blocking call, retry, queue, goroutine/task, lock wait, and side effect. Check
  behavior when cancellation races with completion.
- **Outcome certainty:** a timeout or lost response means the operation did not
  happen. Test the dependency committing a side effect before the caller sees a
  timeout, then retrying, rolling back, or reporting failure.
- **Failure isolation:** dependencies fail independently and atomically. Test
  partial fan-out, partial writes, stale or truncated responses, and one failed
  component blocking unrelated work.
- **Lifecycle stability:** the process, leader, connection, lease, credentials,
  schema, and configuration remain unchanged while work is in flight. Test
  startup, shutdown, restart, failover, and rolling-upgrade boundaries.

Do not accept a timeout, retry, fallback, or cancellation parameter by name.
Verify that it is finite, propagated to the operation that can block, bounded by
an overall budget, and compatible with side-effect and cleanup semantics.

### Control Flow and State

- Exercise every branch, early return, default, fallback, and state transition.
- Attack zero, empty, nil/null, missing, duplicate, malformed, oversized,
  Unicode, maximum, overflow, and boundary values.
- Test precision loss, time zones, DST, clock skew, and expiration boundaries.
- Look for stale state, partial initialization, shadowed values, wrong ownership,
  invalid transitions, and behavior that depends on call order.
- Scrutinize deleted checks and changed failure semantics as aggressively as
  added code.

### Errors and Cleanup

- Make every external call fail, time out, cancel, or return partial data.
- Follow errors to the final caller; look for swallowing, replacement, wrong
  classification, double handling, and success reported after failure.
- Verify cleanup on every exit: locks, files, goroutines/tasks, transactions,
  temporary state, and external resources.
- Crash or restart between related writes and verify transaction, rollback, and
  recovery semantics.
- Attack rollback and retry paths, not only the happy path.

### Concurrency and Time

- Enumerate relevant interleavings: duplicate, concurrent, reordered, delayed,
  retried, and interrupted execution.
- Check atomicity, idempotency, lost updates, stale reads, races, deadlocks,
  cancellation, clock assumptions, and check-then-act gaps.
- Ask what happens during restart, leader change, rolling deployment, or mixed
  old/new versions.

### Boundaries and Compatibility

- Trace data across API, process, package, database, serialization, and trust
  boundaries.
- Compare caller and callee assumptions about defaults, units, ordering,
  optionality, ownership, and error contracts.
- Attack old persisted data, old clients, new clients against old servers,
  configuration omissions, feature-flag transitions, and platform/version
  differences.
- For migrations, test pre-existing rows, backfills, constraints, partial
  rollout, rollback, and concurrent old/new writers.

### Security and Abuse

- Verify authentication and authorization on every reachable path, including
  fallback and error paths.
- Attack input validation, injection, path traversal, SSRF, unsafe parsing,
  secret or PII exposure, confused-deputy behavior, and tenant isolation.
- Try resource exhaustion with large, repeated, or deliberately expensive
  inputs.
- Do not downgrade a correctness flaw merely because it also has security
  consequences.

### Operations and Scale

- Attack realistic production cardinality, latency, retries, and dependency
  degradation.
- Look for unbounded work, leaks, hot loops, fan-out, lock contention, missing
  backpressure, resource-pool exhaustion, and startup or shutdown failures.
- Test missing or invalid configuration, permission failures, read-only or full
  disks, unsupported platforms, and health checks that pass while required
  dependencies remain unusable.
- Verify that failures are observable and that logs/metrics do not falsely
  report success or expose sensitive data.

### Tests as Hostile Witnesses

- Check whether assertions prove the claimed behavior rather than merely execute
  code.
- Find mutations that would leave the tests green.
- Look for mocks that erase the integration boundary under review, fixtures that
  avoid the failing state, incorrect assertions, missing negative cases, races,
  and tests coupled to implementation details.
- Verify that a regression test fails for the broken behavior, not only that it
  passes with the change.

## 4. Prove or Discard

For each candidate defect:

1. Trace a reachable path from an input or system event to the bad outcome.
2. Identify the violated contract or invariant.
3. Search all relevant call sites, guards, types, and tests for evidence that
   prevents the failure.
4. Verify uncertain library or API semantics against authoritative documentation
   or source instead of relying on memory.
5. Run the smallest relevant test, build, lint, static analysis, or reproduction
   when feasible.
6. Do not execute untrusted reviewed code, install dependencies, or contact
   writable production services without explicit permission.
7. Prefer a minimal temporary reproducer that does not alter the worktree. Do
   not add a test or patch during a review unless asked.
8. Compare with the base revision when necessary to show the change introduced
   or worsened the behavior.

A finding must have all of these:

- a precise location in the reviewed change or directly affected code;
- a violated invariant or contract;
- a reachable trigger or execution path;
- a concrete observable impact;
- evidence from code, documentation, command output, or reproduction.

If any element is missing, investigate further or discard the candidate. Do not
launder speculation with words such as "possibly", "might", or "could".

If a command fails, report the exact error and mark that verification as
incomplete. Never silently substitute a weaker check.

## 5. Attack Your Own Findings

Before reporting:

- Try to prove each candidate false using full-file context, callers, types,
  documentation, and runtime behavior.
- Confirm every line reference against the final diff.
- Separate introduced behavior from pre-existing behavior.
- Calibrate severity from impact and reachability, not rhetoric.
- Discard duplicates and findings that share the same root cause.
- Perform a second independent pass over every changed file after the first set
  of findings. Look specifically for a different class of failure.

## Severity

- **Critical:** reachable compromise, broad data loss/corruption, or systemic
  outage with no practical containment.
- **High:** reachable failure on a normal or attacker-controlled path with major
  correctness, security, availability, or compatibility impact.
- **Medium:** definite failure under a constrained but realistic condition with
  meaningful impact.
- **Low:** definite, introduced defect with limited impact. Never use this for a
  style preference or unproven concern.

## Output

Put findings first, ordered by severity. Do not include praise or a general
"looks good" summary.

Use this format:

```markdown
## Findings

### [High] Concise statement of the broken behavior — path/to/file.go:123
- **Claim disproved:** The invariant or promised behavior that does not hold.
- **Counterexample:** Exact inputs, state, timing, and steps that reach failure.
- **Impact:** The observable incorrect result and who or what is affected.
- **Evidence:** Relevant code trace, command output, or minimal reproduction.
- **Confidence:** High or medium, with any material verification limit.
```

Use the narrowest useful line range. Do not attach a finding to an arbitrary
changed line merely to make it commentable.

After findings, include a compact attack log:

```markdown
## Attack Log
- **Scope:** Exact base/head or local change set reviewed.
- **Examined:** Changed files and important call sites or contracts traced.
- **Assumptions attacked:** Availability, termination, cancellation, outcome
  certainty, failure isolation, and lifecycle cases actually investigated.
- **Verification:** Commands and reproductions run, with outcomes.
- **Gaps:** Anything inaccessible or unverified and the exact reason.
```

If no defect survives the proof standard, say `No proven findings.` Then provide
the attack log. This means the attempted attacks found no demonstrable failure;
it is not an approval or a claim that the code is correct.
