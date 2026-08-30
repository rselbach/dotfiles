# Pi host adapter

Use this reference only when `show-me-your-work` runs under Pi.

## Locate the installed skill

Resolve bundled files relative to the `SKILL.md` Pi loaded. Do not assume the
current repository contains the skill, and do not choose a different copy when
more than one is installed.

For the standard personal installation, append a row with:

```bash
bash "$HOME/.agents/skills/show-me-your-work/scripts/log.sh" \
  <logfile> <phase> <decision> <why> <evidence> <result>
```

Replace the skill path when Pi loaded a project or explicitly supplied copy.

## Independent review

When a `subagent` tool is available, run one bounded, read-only delegated task.
Give it the log path and repository root. Ask it to resolve evidence, compare
claims with the work, and return only specific flags or `No flags`. Tell it not
to edit files.

Wait for the result before writing the final handoff. If delegated review is
unavailable, perform the same review as a separate skeptical pass.
