import { test } from "bun:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const checker = fileURLToPath(new URL("./check-plan.mjs", import.meta.url));

function checkPlan({ unit = "None. Documentation only.", live = "None. No runtime behavior changes.", perf = "None. No performance-sensitive changes." } = {}) {
	const directory = mkdtempSync(path.join(tmpdir(), "check-plan-"));
	try {
		const filename = path.join(directory, "plan.md");
		writeFileSync(filename, `# Update Greendale documentation

Clarify enrollment instructions.

## How to read this
One box is one unit of work and names the evidence.
Check a box only when its evidence exists.
Use playbooks/autopilot-stack.md within existing authorization.

## Program checklist
### Arm the program
- [ ] Record the durable program objective.
- [ ] Consult git show origin/main:AGENTS.md when needed.
- [ ] Send a status message at the 30-minute checkpoint.
### Spawn owners
- [ ] Assign the documentation task.
### PR mechanics
- [ ] Inspect the diff.
### Verdict and merge
- [ ] Preserve the operator's merge gate.
### Boot recipe
No runtime instance is needed.

## Clarify enrollment instructions
**Depends on.** None.
**Files.**
- [ ] Edit README.md.
**Build.**
- [ ] Clarify the enrollment command.
**You see.**
- [ ] Troy Barnes can find the command.
**Verify, unit.** ${unit}
**Verify, live.** ${live}
**Verify, perf.** ${perf}
**Review gate.** None.
**Merge.**
- [ ] Wait for the operator to merge.

## Close the program
- [ ] Report the diff and checks.
## Appendix A. Prototype evidence
No prototype needed.
`);
		return spawnSync(process.execPath, [checker, filename], { encoding: "utf8" });
	} finally {
		rmSync(directory, { recursive: true, force: true });
	}
}

test("accepts documented omissions for a documentation change", () => {
	const result = checkPlan();
	assert.equal(result.status, 0, result.stderr);
});

test("accepts one live scenario and applicable unit and performance checks", () => {
	const result = checkPlan({
		unit: "\n- [ ] Run the enrollment regression test.",
		live: "Use one isolated lane per scenario at the PR head.\n- [ ] Lane 1. Enroll Troy Barnes. Save `enrollment.json`. Pass when the enrollment persists.",
		perf: "\n- [ ] Metric. Enrollment latency.\n- [ ] Probe. Run the load check.\n- [ ] Baseline. Record current latency.\n- [ ] Rule. Fail above the agreed latency limit.",
	});
	assert.equal(result.status, 0, result.stderr);
});

test.each([
	["unexplained omission", { live: "None." }, "needs a reason"],
	["omission with checks", { perf: "None. No timing change.\n- [ ] Run a benchmark." }, "says None but has boxes"],
	["missing unit check", { unit: "Run relevant tests." }, "has no check"],
	["missing artifact", { live: "Use one isolated lane per scenario at the PR head.\n- [ ] Lane 1. Enroll Troy. Pass when saved." }, "names no artifact"],
	["missing predicate", { live: "Use one isolated lane per scenario at the PR head.\n- [ ] Lane 1. Save `enrollment.json`." }, "has no pass predicate"],
	["missing performance evidence", { perf: "\n- [ ] Metric. Latency." }, "perf boxes"],
	["duplicate lane", { live: "Use one isolated lane per scenario at the PR head.\n- [ ] Lane 1. Save `first.json`. Pass when saved.\n- [ ] Lane 1. Save `second.json`. Pass when saved." }, "numbered consecutively"],
])("rejects %s", (_name, input, message) => {
	const result = checkPlan(input);
	assert.equal(result.status, 1);
	assert.ok(result.stderr.includes(message), result.stderr);
});
