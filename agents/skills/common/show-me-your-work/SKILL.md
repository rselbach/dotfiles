---
name: show-me-your-work
description: Keep a reviewable TSV decision trail for explicitly auditable or substantial unattended work. Keep it local unless committing it is authorized.
---

# Show me your work

For explicitly auditable or substantial unattended work, keep one decision trail that explains
what happened without requiring the transcript. Record concise rationale and
observable evidence, not private reasoning or transcript excerpts.

## Host adapters

Before creating the log or requesting its independent review, read the adapter
for the current host when one exists:

- Codex: [`references/hosts/codex.md`](references/hosts/codex.md)
- Pi: [`references/hosts/pi.md`](references/hosts/pi.md)
- OpenCode: [`references/hosts/opencode.md`](references/hosts/opencode.md)

The workflow below is the portable core.

## The format

Use one TSV file with one row per decision. GitHub renders a committed TSV as
an interactive table. `column -s$'\t' -t` and spreadsheets can read the same
file. Keep every cell on one line. Evidence is a pointer, not prose.

The canonical columns are:

- **ts.** ISO 8601 timestamp.
- **phase.** The phase, workstream, or iteration identifier.
- **decision.** What was chosen or done, in one line.
- **why.** The reason in plain words.
- **evidence.** A commit, pull request, `file:line`, artifact, trace, screenshot,
  or command-output path that supports the row.
- **result.** The outcome or current state, such as `tests green`, `reverted`,
  `INCONCLUSIVE`, or `open`.

This example is illustrative. Do not copy its rows into a real log.

```text
ts	phase	decision	why	evidence	result
2026-05-24T09:02:00Z	frame	counted about 100 components	needed the size before starting	commit 3a9f1c2	found 5 blockers
2026-05-24T09:40:00Z	harness	captured the old UI	needed a comparison baseline	baseline/	saved 120 screenshots
2026-05-24T11:15:00Z	widget	moved the styles without changing behavior	kept the unit small	commit 7c21e0a, pixel-diff 0	tests green
```

## Logging a row

Resolve the installed skill directory from the path of this loaded `SKILL.md`.
Do not assume the current repository contains the skill. Run:

```text
bash "<skill-directory>/scripts/log.sh" <logfile> <phase> <decision> <why> <evidence> <result>
```

The helper creates or validates the header, stamps `ts`, replaces tabs and line
breaks inside cells, and neutralizes spreadsheet formulas. Prefer it over a
hand-written append when any cell contains generated or user-supplied text.

Write each entry the way you would tell a teammate what happened. Log decision
points and checkpoints, not every command. Useful rows include a chosen fork,
a verified unit, a pivot, a revert, a blocker, or an iteration result.

## Where it lives

Keep the log local by default. Use `decisions.tsv` in the work directory or
`.audit/<task-slug>.tsv` when several efforts run at once. Use an existing
ignored scratch directory when the repository has one. Otherwise leave the log
untracked and do not add an ignore rule solely for it.

Commit the log only when a reviewer needs the trail and the user and repository
rules authorize version-control changes. Most work does not need a committed
trail.

## Rules

- One row is one decision or checkpoint.
- Keep the log append-only. Correct a wrong row with a later row that identifies
  what it supersedes. Never rewrite prior history.
- Use the canonical columns. Put workflow-specific details inside those fields
  instead of inventing another schema.
- Prefer evidence produced by repeatable scripts or commands.

## Audit the log against the work

Before the final handoff, compare the log with changed files, version-control
state, command results, test output, screenshots, traces, pull requests, and
other artifacts from the run. Use the current conversation record when the
host exposes it, but do not depend on a vendor-specific transcript path.

- Confirm that every row maps to a real action.
- Resolve each evidence pointer and check that it supports the claim.
- Add missing forks, pivots, abandoned approaches, and verification results.
- For an invented, aspirational, padded, or wrong row, append a correction that
  identifies the original row and records the actual result.

If the work diverged from a row, correct the log. Do not change the story to
match it.

## Independent review

For explicitly auditable or substantial unattended work, ask an independent
reviewer to inspect the trail before handoff when delegated review is available.
For an optional log on ordinary work, the self-audit above is sufficient unless
independent review was requested. Use the host adapter for delegated review;
if unavailable, perform a separate skeptical pass yourself. Check for:

- weak or missing evidence;
- verification claimed without artifact proof;
- premature, scope-expanding, or symptom-level decisions;
- gaps the user could miss on a casual skim.

When independent review applies, the final handoff includes an `Independent review` section. Identify the
reviewer by agent label or model when known. List each flag with its row and
evidence, or say `No flags`.

## Reviewing the trail

Read it top to bottom, follow the evidence pointers, and spot-check results.
GitHub renders a committed TSV as an interactive table. In a Bash or Zsh
terminal, run `column -s$'\t' -t decisions.tsv`.

## Composing this skill

Other skills should route their audit trail here and use the canonical columns.
They may define how their data maps into those columns, but should not define a
replacement schema.
