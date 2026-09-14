### Multi-phase or multi-PR plan

Prepare a plan for work spanning phases or stacked PRs. For a plan-only request, the plan is the deliverable. For an authorized implementation, present the plan and continue execution unless the user requested a checkpoint or authority is missing.

1. For one or two files with an obvious approach, use a short plan. Continue implementation when authorized.
2. Settle open questions by prototype before you write. For a question about layout, timing, behavior, or whether an API works, run `playbooks/prototype.md`. Keep the branch, the SHA, and the screenshots for Appendix A. Ask the operator only about a product or preference call that no run can settle. Give options (the **never-block-on-the-human** principle skill).
3. Explore with bounded subagents when the host supports them, using the semantic roles from the Subagents section (the **guard-the-context-window** principle skill). Each returns file pointers, conventions, test commands, and entry points. No inlined dumps.
4. Copy the skeleton below into the plan file and fill every placeholder. Unless the operator names a path, write the file under the agent store's `docs/`. Keep the main sections and PR sub-blocks in order. Mark an inapplicable verification block `None. <reason>`; do not invent checks to fill it. One section per PR. One PR is one change with its own evidence (the **sequence-verifiable-units** principle skill). Name the execution playbook in **How to read this**. Pick between `playbooks/autopilot-full.md` and `playbooks/autopilot-stack.md` per the rule at the end of `playbooks/autopilot-stack.md`. A standing program takes `playbooks/orchestrate.md`.
5. Apply **technical-writing** in full, then **unslop**. The body is one Diátaxis mode, how-to. Appendices hold explanation and reference. Two rules apply verbatim. "i dont want any abstract metaphors" and "write like hemingway". Each heading states the task or finding. No long dashes. No mid-sentence colons.
6. Run `node .agents/skills/poteto-mode/scripts/check-plan.mjs <plan.md>` and fix every line it prints (the **encode-lessons-in-structure** principle skill). It checks the plan structure, evidence for applicable checks, and punctuation.
7. Present the plan path and validation results. Stop for a plan-only request, a requested checkpoint, or missing authority. Otherwise continue under the named execution playbook using existing authorization.

**Verification.** Preserve repository-required checks and select additional checks for the changed behavior. Reuse passing results while their code, dependencies, and environment remain unchanged. Live checks apply to runtime behavior; performance checks apply to performance-sensitive changes. Mark inapplicable blocks `None. <reason>`. Use as many isolated lanes as the concrete scenarios require, each with an artifact and pass predicate. Applicable performance checks name the metric, probe, baseline, and failure threshold. Preserve requested interaction-review gates.

**Control skill.** Pick an available control capability for each surface. Browser, Electron, web, CLI, TUI, and native mobile may need different tools. A PR that touches two surfaces gets lanes on both. A surface with no control capability is a risk in Appendix C, and its live block still names how each lane will drive it.

````markdown
# <Program> plan

<Under ten lines. What changes, for whom, the rule the program enforces, and the PR ids in order.>

## How to read this

One box is one unit of work. Every box names the evidence that checks it. A nested box is a sub-step of the box above it. Check a box only when its evidence exists, a file, a log line, a screenshot, a test run, or a SHA. The body is a how-to. The appendices explain and record.

The program runs `.agents/skills/poteto-mode/playbooks/<execution playbook>.md`. <Who merges, and which PR ids are the operator's items that stop at merge-ready.>

Run repository-required checks and checks relevant to the changed behavior. Reuse valid results for unchanged code.

## Program checklist

### Arm the program

- [ ] Present the protocol and plan. Continue within existing authorization; pause only for a plan-only request, a requested checkpoint, or missing authority.
- [ ] When authorized, record a durable program objective through the host's supported mechanism with this exact text. "<The plan path, the PR ids in order, the verification rule, who merges, and the done condition.>"
- [ ] Read relevant guidance from trunk when needed. Re-read it after a source change or lost context, not at every tick.
  - [ ] `git show origin/main:.agents/skills/poteto-mode/playbooks/<execution playbook>.md`
  - [ ] `git show origin/main:.agents/skills/swarm/SKILL.md`
  - [ ] `git show origin/main:<control skill path>`
  - [ ] `git show origin/main:.agents/skills/poteto-mode/playbooks/opening-a-pr.md`
  - [ ] `git show origin/main:.agents/skills/<each other leaf skill the program uses>`
- [ ] Arm the 30-minute audit tick through the current host's recurring-monitoring mechanism. Never leave the cadence to memory.
- [ ] Use this tick prompt, verbatim. "Consult the execution playbook and durable program objective already in context. Refresh changed or missing guidance. Audit the operation against both and fix drift in this tick. Probe every active lane and judge progress by externalized artifacts only. Stand down a stuck lane and dispatch its replacement now. Then send the operator a status message, whether or not anything changed, with the queue table of PR, owner, state, and head SHA, the verdicts since the last tick, what merged, open operator gates, and blockers."
- [ ] On the operator's hold or stand-down, send every owner a zero-writes order at once.

### Spawn owners

- [ ] Spawn one owner per PR with the full lifecycle the execution playbook names.
- [ ] Follow this dependency graph. Start dependent work only after its parent merges, or base it on the parent branch when the execution playbook stacks.
  - [ ] <PR id> and <PR id> are independent and first. Both branch from `main`.
  - [ ] <PR id> after <PR id>.
- [ ] Hold the file boundaries. <PR id or class> touches only `<glob>`.
- [ ] Hold requested review gates. <User-designated PR ids> wait for the operator's interaction review with screenshots and a video before merge.

### PR mechanics, for every PR

- [ ] Open the PR ready, never draft, with `gh pr create` and `draft: false`, or with Graphite `gt` for a stack.
- [ ] Run the repo's lint and typecheck once before the PR-facing push. Push with hooks on.
- [ ] Apply `unslop` to substantial prose. Use `no-comments` only when explicitly requested, read-only unless editing is requested.
- [ ] Triage every automated and security-reviewer comment per `../references/automated-review-triage.md`.
- [ ] Rebase onto current trunk before babysit and again before the merge-ready report.

### Verdict and merge, for every PR

- [ ] At the merge-ready head SHA, run the swarm per `.agents/skills/swarm/SKILL.md`. One gates lane. The applicable live lanes from the PR's **Verify, live** block and perf lane from its **Verify, perf** block. One audit lane that reads the diff and receipts and distrusts the PR body.
- [ ] Clean only when every lane is `PASS`. Findings go back to the owner. A new head gets a fresh swarm and a fresh verdict.
- [ ] <The merge or append rule from the execution playbook, with the patch-id rule from `playbooks/shipping.md`.>

### Boot recipe, for every live lane

Each live lane runs in an isolated environment at the PR head. Drive through the control capability selected for that surface.

- [ ] `git fetch origin <head-branch> && git checkout <head SHA>`.
- [ ] <Start the backend and the surface. Wait for ready.>
- [ ] <Deliver input only through the control skill's commands. Name the read-only diagnostics.>
- [ ] Save every screenshot to `/tmp/swarm-<pr-id>/worker-<n>/<slug>.png` and return the paths with the report.

## <Task as a verb phrase> (<PR id>)

**Depends on.** <PR id, or None.>

**Files.**

- [ ] Edit `<path>`.
- [ ] Create `<path>`.
- [ ] Delete `<path>`.

**Build.**

- [ ] <One change. Name the symbol and the file.>

**You see.**

- [ ] <One observable result, with the exact log line or screen state.>

**Verify, unit.** <Relevant checks, or None. with a reason when inapplicable.>

- [ ] <Test file and the case it gains.> Run `<command>`.

**Verify, live.** Use one isolated lane per scenario at the PR head, per the boot recipe. Replace this block with `None. <reason>` when runtime checks are inapplicable.

- [ ] Lane 1. <Scenario.> Save `<slug>.png`. Pass when <predicate>.

**Verify, perf.** <Applicable performance checks, or None. with a reason when inapplicable.>

- [ ] Metric. <What is measured.>
- [ ] Probe. <The command or procedure, run at trunk and at the head, interleaved.>
- [ ] Baseline. Record the trunk <value> first.
- [ ] Rule. <Head against trunk, with the number that fails.>

**Review gate.** <Requested operator review before merge, or None. when no such gate was requested.>

- [ ] Copy lane <n> screenshots into `<media path>/<pr-id>-review-<slug>.png`.
- [ ] Record a 30 to 60 second video of the change on a lane VM. Save it as `<media path>/<pr-id>-review.mp4`.
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] Automated-review triage done.
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] <The owner squash-merges its own PR, or the root appends the PR to the Graphite stack and the operator lands it.>

## Close the program

- [ ] Every box above is checked with its evidence.
- [ ] Reply to the operator with the report the execution playbook names.

## Appendix A. Prototype evidence

<Each open question a prototype answered, with the branch, the SHA, and the artifact links. Each question that stays unproven.>

## Appendix B. Alternatives rejected

<Each approach weighed and why it lost.>

## Appendix C. Risks

<Each risk with the PR it lands in and what the owner watches.>

## Appendix D. Links and reading list

<Docs to consult for specific decisions. Which PRs need `.agents/skills/how/SKILL.md` and `.agents/skills/interrogate/SKILL.md`. The trail per `.agents/skills/show-me-your-work/SKILL.md`.>
````

**Reply:** the plan path, the PR ids with their dependencies and the review-gated set, what the prototypes proved and what stays unproven, and the check script's output.
