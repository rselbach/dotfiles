---
name: figure-it-out
description: "Design an auditable playbook when no narrower one fits: a large migration, an ambitious multi-part change, or work a human reviews after stepping away. Scales rigor to the task, runs a hypothesis loop, and logs decisions via show-me-your-work. Use when explicitly invoked, for 'figure it out', for a large migration, or when no narrower playbook applies."
---

# Figure it out

When the task matches no playbook, design one. The deliverable before any code is the workflow itself: a sequence of phases that scales rigor to the task, runs the scientific method, and leaves a decision trail a human can audit after stepping away. Bias toward more rigor. The cost of building the wrong thing dwarfs the cost of being careful.

Don't reinvent a playbook you already have. A focused single-unit task that matches Bug fix, Perf, Feature, Visual parity, Eval, or Multi-phase plan routes there. But a large or cross-cutting version of one (a migration across many call sites, an ambitious multi-part change), or work the user reviews after stepping away, belongs here even though a single-unit version would be a Feature. The rigor and the audit trail are the point.

## Start

Create a task-specific checklist. Consult relevant **llama-mode** principles
when they help resolve a decision. Use the host's plan or todo facility when it has
one. Under Pi, keep a concise checklist in chat, use workflow phases during a
workflow, or write a durable plan file for long work. Then add the phases below.

## Phase A: Frame

Ground first, then commit. Don't start the run until you can state:

- The definition of done as a falsifiable predicate (the **prove-it-works** principle skill). "Done well" has to be checkable.
- Scope, quantified: rough units and effort, plus the blockers grounding surfaced. Raise them before spending hours, not after fifty doomed commits.
- The rigor level, biased high. One-way doors and high blast radius get more; reversible low-stakes steps get less. Rigor is gates and artifacts, not "try harder".

Present the framing and tradeoffs, then continue authorized work. Pause only for a plan-only request, a requested checkpoint, or missing authority, not merely because the run is long.

## Phase B: Design the workflow

Decompose into atomic, independently-landable units. Sequence riskiest-unknown-first so option value stays high. Scaffold and verification come before features (the **foundational-thinking** principle skill).

- Build the verification harness before the work, with the baseline captured from the pre-change state, so the check reads as "old value vs new value".
- For one-way-door design decisions, run the **architect** skill (it runs **arena**) with diverse, isolated, opinionated candidates and a read-only judge on a different model family. Skip it for mechanical work whose shape is already concrete. A second arena over a settled design is over-engineering (the **laziness-protocol** principle skill).
- Decide what fans out. Parallelize only across genuine seams, and give each worker its own worktree or branch (the **separate-before-serializing-shared-state** principle skill). Don't over-fan.
- Write the designed phase list down. That list is what the human reviews.

Then put the design into motion. Add its steps to the working checklist as
concrete items, after the Phase C entry and before Phase D. Run each under the
Phase C loop discipline, and weave the Phase D log through them, a row as each
step lands, rather than saving the whole trail for the end.

## Phase C: Run the loop

Each unit is an experiment: state the hypothesis, make the smallest change, measure against the predicate on the real artifact, keep it if it advanced, revert it if it didn't.
Apply the **sequence-verifiable-units** principle skill, verifying each unit before starting the next instead of batching checks at the end.

- Verify by inspecting the artifact, never a self-report. When something passes too easily, suspect the observation method before the system. A blank screenshot passes a lazy gate.
- Pair delegated work with a judge and audit the delegates' artifacts yourself before trusting them. If a worker games the gate, reset and harden the contract. If the gate itself is wrong, fix the gate in its own change rather than routing around it.
- A verdict is VERIFIED, NOT VERIFIED, or INCONCLUSIVE. Inconclusive is not a pass. Don't hide a negative.

## Phase D: Keep the audit trail

For explicitly auditable or substantial unattended work, log the run via **show-me-your-work**, one canonical TSV with a row per decision and per unit, evidence as links. Otherwise retain concise progress and verification notes. Figure-it-out's work may justify committing the trail so the reviewer can read it in the PR, but commit it only when confidence has to be shown and the user and repository rules authorize version-control changes. Prefer evidence produced by committed scripts so a reviewer can re-run it. The trail plus the diff is what lets the human come back and trust the work.

## Phase E: Verify and hand back

Check the whole against the Phase A predicate on the real product, not just the harness. Encode any recurring correction as a gate, a lint rule, a check, or a script, so the win can't silently regress (the **encode-lessons-in-structure** principle skill).

**Reply:** the playbook you designed, the rigor level and why, the decision-trail path, what's verified against the predicate, and what's still open.
