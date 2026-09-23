### Feature

**You own the design. Plan, review, verify.** Delegate implementation; stay in the lead.

1. Read the affected code. Use `how` for an unresolved architectural question.
2. Use `architect` when introducing or substantially reshaping an architectural boundary with multiple viable designs.
3. Plan applicable dependencies and independent workstreams. Omit irrelevant dimensions:
   - **Blocking first steps.** Gates run before fan-out.
   - **Independent workstreams.** Disjoint files, services, or layers parallelize. Shared writes serialize.
   - **Shared mutable state.** Default to splitting the target (the **separate-before-serializing-shared-state** principle skill). Serialize only for real invariants.
   - **Smallest safe decomposition.** Use one worker when the code is tightly coupled.
4. Delegate code-writing with the configured `feature` role when the host supports it. Give the worker exact paths, the named data shape and organizing structure, and success criteria; review its diff yourself. When several valid implementation shapes exist, use **arena**. Without subagents, implement directly from the same scoped brief and perform a separate review pass. Comments follow the parent skill. Re-ground against source for upstream-derived files, port shared-primitive improvements to every consumer, and verify each. Commit only when the task and repository workflow authorize it.
5. Verify on the matching surface. "Inconclusive" or wrong-surface is not a pass; flag it.
6. Rebase into small, ordered commits; stack follow-ups.
   Use the **sequence-verifiable-units** principle skill, building, verifying, and committing each small unit before the next.
7. If the design is contested, `interrogate` before shipping.
8. Run **Opening a PR**.

Code-coupled work (one feature, one migration) goes to a single owner with the checkpoint inline; that owner fans out internally after the blocking phase. Parent-level fan-out is for slices that produce independent artifacts (audits, cross-subsystem investigations, competing experiments). Rewrite the checkpoint at phase boundaries; spawn a fresh owner rather than chaining interrupts.

**Reply:** what you built, what you chose and why, open decisions. Tables for design alternatives.
