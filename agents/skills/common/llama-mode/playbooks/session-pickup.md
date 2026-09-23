### Session pickup

**You own the resume point. Read the prior trail, don't redo it.** For "take over this", "resume this conversation", "continue from <transcript path>", "you're taking over", "pick up where X left off", a cloud-agent URL handoff, or a pushed branch you're meant to continue.

A pickup is inheritance. The prior agent already paid the cost of reading the code, running the repros, making the design choices. Redoing loses the bias check and burns context. Resist the urge to re-derive; read.

1. Locate the prior trail through the host's resume facility, the **recall** skill, a remote-agent URL, a decision log, or a pushed branch. Prefer resuming a known session over parsing storage. For a long record, have recall return a reduced timeline so raw history stays out of the main context (the **principle-guard-the-context-window** skill). Under Codex, follow `../references/hosts/codex.md`.
2. Reconstruct operational state. The branch and worktree, what already landed (`git log`, `git diff` against the base), the open todos, the decisions made. The prior trail is authoritative input. Resist the bias to re-derive it.
3. Diff done vs pending. Compare what shipped against what was planned, name the resume point, do not re-run the prior repro or redo completed work. A "let me verify from scratch" pass is the tell that you're treating the trail as untrustworthy when it's actually authoritative.
4. Route the remaining work to the matching playbook and pick the verdict: continue the execution, ship a finished recommendation, ratify or override a prior conclusion, or postmortem a failed run. The pickup playbook ends here; the routed playbook owns the rest.
5. Verify the inherited claims against the original goal on the real artifact (the **principle-prove-it-works** skill). A passing prior self-report is not the proof.

**Reply:** where the prior agent stopped, what you inherited vs redid (ideally nothing redone), the resume point, and the outcome.
