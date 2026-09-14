---
name: no-comments
description: Review comments and suppressions only when explicitly requested. Report findings without edits unless the user requests changes.
---

# No comments

Review the caller's files or diff for comments that repeat code, obsolete
explanations, and suppressions that hide defects. Use the current diff against
the intended base when no narrower scope is supplied.

## Review

1. Use [the reviewer prompt](references/reviewer-prompt.md). Delegate a
   substantial review when useful; a small review can stay in the current thread.
2. Keep review-only work read-only. Report proposed deletions and structural
   fixes with evidence. Preserve uncertain comments and suppressions.
3. Investigate ambiguous constraints in the relevant code and history. Use
   **how** or **why** only when an unresolved question warrants those workflows.
4. Reject findings that conflict with repository-required comments or rely on
   speculation. If a delegated review is unreliable, finish the scoped review
   directly rather than stopping the task.

## Authorized edits

When the user requests edits, implement accepted fixes within the supplied
scope. Remove a correctness suppression only after demonstrating and verifying
its replacement. Preserve legal headers, public API documentation, required
script headers, and comments required by repository conventions.

Use **architect** only when a fix substantially reshapes an architectural
boundary with multiple viable designs. Report out-of-scope root causes instead
of expanding the task.

Report findings, any authorized edits, verification, and remaining uncertainty.
