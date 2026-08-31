# OpenCode host adapter

Use this reference only when `show-me-your-work` runs under OpenCode. Detect
OpenCode through `OPENCODE=1` when needed.

## Locate the installed skill

OpenCode includes the loaded skill's base directory in the skill result. Resolve
`scripts/log.sh` from that directory. Do not assume the current repository
contains the skill, and do not choose another installed copy.

## Independent review

Run one bounded Task with `subagent_type="reviewer"`. Give it the log path and
repository root. Ask it to resolve every evidence pointer, compare each claim
with the work, and return only specific flags or `No flags`. The configured
reviewer denies edits and nested delegation.

Wait for the Task result before writing the final handoff. If the reviewer agent
is unavailable, perform the same review as a separate skeptical pass.
