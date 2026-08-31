# OpenCode host adapter

Use this reference only when pstack runs under OpenCode. Detect OpenCode through
`OPENCODE=1` when the host is not otherwise clear.

## Skills and plans

OpenCode discovers personal skills under `$HOME/.agents/skills`,
`$HOME/.claude/skills`, and `$HOME/.config/opencode/skills`. Repository skills
can live under `.agents/skills`, `.claude/skills`, or `.opencode/skills`.
Resolve bundled files from the base directory returned by the loaded skill.

Use `todowrite` for a working plan. OpenCode loads skills and agent definitions
at startup, so restart it after changing either one.

## Delegation

OpenCode Task selects a `subagent_type`; it does not accept a model argument.
For pstack roles, read the model from the OpenCode pstack section in `AGENTS.md`
and replace non-alphanumeric characters with hyphens to derive the generated
`pstack-worker-<model-slug>` or `pstack-reviewer-<model-slug>` agent. Use workers
for implementation, tooling, prose, and candidate runners. Use reviewers for
exploration, explanation, investigation, synthesis, judgment, cross-judging,
architecture, and review. Resolve `inherit-parent` and `auto` to the ordinary
`general` or `reviewer` agent instead.

Launch independent Tasks together in one tool-call batch. Each Task is bounded
and returns before the parent continues. OpenCode does not expose a detached
worker handle that can be polled, steered, or stopped later. Use `explore` for
read-only source discovery, `reviewer` for ordinary review, and `minion` for
focused writes when no pstack role applies.

## Long-running work

OpenCode has no recurring wake mechanism. Do not claim that a watcher, audit
tick, or background worker remains armed after the turn ends.

- Run repository watchers only with a finite foreground timeout or status-only
  mode.
- Leave the predicate, current state, evidence, and exact resume command in the
  decision trail.
- Resume explicitly in a later session.
- Do not select Orchestrate, Autopilot-full, or Autopilot-stack when their done
  predicate cannot be reached in the current session. Use a bounded playbook
  and durable checkpoints instead.
- Treat Babysit `background` as `check` unless a configured external scheduler
  provides the wake mechanism.

## Sessions

For a known prior session, use `opencode -s <session-id>` or
`opencode --fork -s <session-id>`. For synthesis across sessions, invoke
**recall** and follow its OpenCode adapter.

## Skill authoring

Load **customize-opencode**, edit `SKILL.md` directly, and validate discovery
with `opencode debug skill`. OpenCode ignores unknown skill frontmatter. Encode
explicit-only behavior in the description or in OpenCode skill permissions.

## Browser work

Use an exposed browser MCP when available. Otherwise run an existing
project-owned browser harness or the Playwright CLI with the installed system
browser. If none exists, invoke **create-verification-skill** or report the
browser check as not run.
