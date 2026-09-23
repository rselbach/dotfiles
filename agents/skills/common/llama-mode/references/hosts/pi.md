# Pi host adapter

Use this reference only when llama-stack runs under Pi. Detect Pi through
`AI_AGENT=pi` or `PI_CODING_AGENT=true` when the host is not otherwise clear.

## Skills

Pi discovers personal skills under `$HOME/.agents/skills` and
`$HOME/.pi/agent/skills`. Repository skills can live under `.agents/skills` or
`.pi/skills` after the project is trusted. Explicit invocation uses
`/skill:<name>`. Keep these spellings out of portable workflow prose unless the
instruction is specifically for Pi.

Resolve bundled scripts relative to the `SKILL.md` Pi loaded. Do not assume the
current repository contains the skill. Run `/reload` after changing an
installed skill when the current session must discover the change.

Pi has no built-in plan or todo mode. Keep a concise checklist in chat for
ordinary work. Use workflow phases for a multi-agent workflow and a durable
plan file for work that must survive the session.

## Delegation

Pi core has no subagents. Use only delegation tools exposed in the current
session:

- `subagent` runs one bounded delegated task. In the standard extension used by
  this setup, calls are serialized and children cannot delegate recursively.
- `workflow` provides bounded fan-out and fan-in. Use it only when the request
  explicitly authorizes a workflow, fan-out, or multi-agent orchestration. Pass
  functions to `parallel`, give every agent a unique label, isolate writable
  outputs, check for failed branches, and finish with a synthesis agent.
- If neither tool is available, run the same passes sequentially and keep their
  findings separate.

Use model slugs from the Pi llama-stack block in `AGENTS.md` when the active tool
supports model selection. Omit the model for `inherit-parent` or `auto`.

Pi's one-shot delegated tools do not provide persistent workers that can be
steered, queried, or stopped later. Do not select Orchestrate, Autopilot-full,
or Autopilot-stack unless the session exposes a persistent-agent extension and
a supported wake mechanism. Fall back to a bounded playbook and leave durable
state for explicit resume.

## Long-running work

Pi core has no background shell or recurring wake mechanism. Use a repository
watcher with bounded foreground polling, or save durable state and resume
explicitly. Never claim that a timed audit tick is armed when no extension
provides one.

When goal tools are exposed, follow their tool contract. In this setup,
`create_goal` requires an explicit user request for a durable goal. A playbook
mention alone is not authorization. Without that request, keep the objective in
the plan or audit file instead. Mark a goal complete only after the objective is
actually achieved.

## Skill authoring

Pi has no built-in `$skill-creator`. Read Pi's current `docs/skills.md`, author
the skill directly, and validate `name`, `description`, references, and bundled
paths. Pi ignores `agents/openai.yaml`. Do not copy its Codex-only policy into
shared `SKILL.md` frontmatter because other hosts may honor the same field.
Use `disable-model-invocation: true` only when explicit-only behavior is
intended on every host that loads the shared skill. Project skills need project
trust, and the current session needs `/reload` before newly created or renamed
skills appear.

## Tool vocabulary

Use the tools exposed by the session rather than names copied from another
host. In this setup, path search maps to `fffind`, content search to `ffgrep`,
and file reads to `read`.
