# Codex host adapter

Use this reference only when `show-me-your-work` runs under Codex.

## Locate the installed skill

Codex includes the loaded skill's `SKILL.md` path in its skill context. Resolve
bundled files relative to that path. Do not assume the current repository
contains the skill, and do not choose a different copy when more than one is
installed.

For the standard personal installation, append a row with:

```bash
bash "$HOME/.agents/skills/show-me-your-work/scripts/log.sh" \
  <logfile> <phase> <decision> <why> <evidence> <result>
```

Replace the skill path when Codex loaded a repository, admin, system, or
symlinked copy.

## Independent review

Spawn one bounded, read-only subagent to review the completed log. Give it the
log path and repository root. Ask it to resolve evidence, compare claims with
the work, and return only specific flags or `No flags`. Tell it not to edit
files.

Wait for the reviewer before writing the final handoff. A built-in Codex agent
is enough. This workflow does not require a custom agent under `.codex/agents`.
If subagents are unavailable in the current session, perform the same review as
a separate skeptical pass.
