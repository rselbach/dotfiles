---
name: setup-pstack
description: Configure the models an agent host uses for pstack roles. Detect available models, preserve other hosts' settings, and update the current host's pstack block in AGENTS.md. Use when explicitly invoked or when changing pstack model choices.
---

# Setup pstack

Configure pstack's semantic roles for the current agent host. Skills refer to roles such as `feature`, `how critics`, and `arena runners`; they do not hardcode vendor model names.

Keep the mapping in the repository's `AGENTS.md`. Use a host-specific heading so several agents can coexist without overwriting each other:

```markdown
## <Host> pstack model configuration

feature, refactoring: <model or inherit-parent>
bug-fix: <model or inherit-parent>
...
```

If the active host requires a native configuration file to select subagent models, treat that file as an adapter generated from the `AGENTS.md` mapping. `AGENTS.md` remains the human-readable source of truth.

## Steps

### 1. Identify the host and available models

Identify the current agent host from the environment. Enumerate only model slugs that the host confirms can be assigned to delegated work. Prefer the host's tool metadata or supported model list. In Pi, detect the host through `AI_AGENT=pi` or `PI_CODING_AGENT=true`, inspect the current `PI_PROVIDER` and `PI_MODEL`, and use `pi --list-models` for available slugs. If no dependable list is available, offer `inherit-parent` and ask the user to provide any additional slugs they want.

Never copy defaults from another host. `inherit-parent` and `auto` both mean to omit an explicit model and let the host use the parent session's model.

### 2. Load current state

Read the nearest applicable `AGENTS.md`. Find the `<Host> pstack model configuration` section, if present. Preserve every other instruction and every other host's section.

Start missing roles at `inherit-parent`. Existing confirmed values remain the current choices.

### 3. Map and confirm

Show every role and its current value. Mark unavailable real slugs as needing a choice. Let the user accept the mapping or change specific roles.

Panel roles contain lists. One worker runs per entry, including `inherit-parent` entries. The list length therefore sets fan-out. `arena cross-judge pool` is also a list, but Arena chooses one entry and prefers a different model or agent from the candidates when practical.

### 4. Validate

Every real slug must appear in the host's confirmed model set. `inherit-parent` and `auto` always pass. If a real slug is unavailable, stop and ask for a replacement rather than guessing.

### 5. Update only the current host block

Write these roles under the current host heading, preserving any extra roles already present:

```text
feature, refactoring
bug-fix
perf-issue
hillclimb
judgment and prose
strongest judgment
how explorer
how explainer
how critics
why investigators
why synthesizer
reflect tooling
reflect judgment, divergent, synthesizer
arena runners
arena cross-judge pool
swarm workers
architect runners
interrogate reviewers
```

Keep the edit idempotent. Update the block in place; do not rewrite the rest of `AGENTS.md`.

### 6. Verify

Read the resulting block back. Confirm that all requested roles are present, every real slug is available, and other host sections are unchanged. Tell the user that new sessions will read the mapping through `AGENTS.md`.

### 7. Offer project verification

Check whether the project has a `verify-*` skill or another harness that drives the real artifact. If not, offer once to invoke `create-verification-skill`. Move on if the user declines.
