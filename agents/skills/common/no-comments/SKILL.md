---
name: no-comments
description: Review comments and suppressions with an independent deletion-biased pass, fix accepted findings, and offer structural encodings for real constraints.
---

# No comments

Run an independent comment review, then act on accepted findings. Authoring agents tend to defend comments they wrote, so use a fresh reviewer when subagents are available.

## Scope

Use the caller's files or diff. Otherwise use the current diff against the base branch, normally `main`, including the working tree.

## Steps

1. Read `references/reviewer-prompt.md`. Delegate the scoped review with that prompt when the host supports subagents. Otherwise perform a separate review pass directly. The reviewer may edit comments in scope but must not modify application code.
2. Inspect the report and diff. Reject scope escapes, exception-protected deletions, misstated `MUST KILL` reasons, and flags that treat intentional code as guilty without evidence. Audit missed lint and type suppressions. Before accepting an ambiguous constraint comment, invoke **how**, **why**, or both on its symbol. Revert and rerun one rejected delegated review with the failure named. Reject a second bad review, report it, and stop.
3. Fix trivial accepted findings directly by deleting dead paths, dropping obsolete parameters, or using the real API. If a fix needs a new shape, invoke **architect** once for the accepted set and surrounding code before implementation.
4. Implement the smallest root-cause fix in scope. Remove every named workaround. If the root cause is out of scope, make the smallest in-scope correction and report the rest as open work. The root-cause and first-principles skills guide intent; they do not authorize widening scope.
5. For comments that claim a constraint such as "do not remove" or "do not change wording", preserve only constraints imposed by something the repository cannot change. Offer the cheapest in-scope type, runtime check, test, or lint that can encode the constraint. Get any approval required by the current task before adding that mechanism.
6. Report deletion count, restored comments, reruns, architecture sketches, fixes, encoding offers, encodings, unenforced constraints, and remaining work.
