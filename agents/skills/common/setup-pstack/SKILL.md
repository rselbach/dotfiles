---
name: setup-pstack
description: Configure which models pstack uses per role. Detects available models and writes a shared config that overrides the skill defaults. Use for the `setup-pstack` skill, "configure pstack models", or changing pstack's model choices.
---

# Setup pstack

Write `${XDG_CONFIG_HOME:-$HOME/.config}/pstack/models.conf`, which sets pstack's model per role. The skills read it and fall back to their inline defaults when a line is absent, so this is an override layer, not a requirement.

## Steps

### 1. Detect available models

Query the current agent harness for model identifiers accepted by its delegation tool. Prefer a documented model API or CLI when one is available. If the harness cannot enumerate models, use `inherit-parent` or ask the user for valid identifiers. Never write an identifier you have not confirmed is available. The `inherit-parent` alias is always valid.

### 2. Load current state

The default role-to-model mapping is the config shape shown in step 5 below. If `${XDG_CONFIG_HOME:-$HOME/.config}/pstack/models.conf` already exists, read it and treat its values as the current choices. Otherwise start from those defaults.

### 3. Map and confirm

Show every role with its current model, marking any real identifier not in the detected set as needing a choice. Ask whether to accept the mapping or change specific roles. Offer the detected models plus `inherit-parent`, which runs the role on the parent model. Use a structured question UI when the harness provides one; otherwise ask in chat. For panel roles (how critics, arena runners, architect runners, interrogate reviewers), the value is a list and one subagent runs per entry, including aliases, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena selects one value from it whose model family differs from the parent's when possible. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

Every real model identifier written must be in the detected set; `inherit-parent` always passes. If a chosen identifier is not available, stop and ask again. A config entry pointing at a model the user cannot use breaks every delegation that reads it.

### 5. Write the config

Create the parent directory, then write `${XDG_CONFIG_HOME:-$HOME/.config}/pstack/models.conf` with one line per role, using the same labels poteto-mode uses. Overwrite the whole file so re-runs stay idempotent. Shape:

```
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` as a value runs the role on the parent model. Alias entries in a panel list still count toward its fan-out.
feature, refactoring: grok-4.6-fast-xhigh
bug-fix: gpt-5.6-sol-max
perf-issue: gpt-5.6-sol-max
hillclimb: gpt-5.6-sol-max
judgment and prose: claude-fable-5-thinking-max
hardest tasks: claude-fable-5-thinking-max
how explorer: grok-4.6-fast-xhigh
how explainer: claude-fable-5-thinking-max
how critics: claude-fable-5-thinking-max, gpt-5.6-sol-max, grok-4.6-fast-xhigh, claude-opus-5-thinking-xhigh
why investigators: grok-4.6-fast-xhigh
why synthesizer: claude-fable-5-thinking-max
reflect tooling: gpt-5.6-sol-max
reflect judgment, divergent, synthesizer: claude-fable-5-thinking-max
arena runners: claude-fable-5-thinking-max, gpt-5.6-sol-max, grok-4.6-fast-xhigh, claude-opus-5-thinking-xhigh
arena cross-judge pool: claude-fable-5-thinking-max, gpt-5.6-sol-max, grok-4.6-fast-xhigh, claude-opus-5-thinking-xhigh
swarm workers: grok-4.6-fast-xhigh
architect runners: claude-fable-5-thinking-max, gpt-5.6-sol-max, grok-4.6-fast-xhigh, claude-opus-5-thinking-xhigh
interrogate reviewers: claude-fable-5-thinking-max, gpt-5.6-sol-max, grok-4.6-fast-xhigh, claude-opus-5-thinking-xhigh
```

### 6. Confirm

Tell the user where the config was written. Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with the `create-verification-skill` skill." On yes, invoke the `create-verification-skill` skill from the project or user skill root where pstack is installed. On no, move on without pushing.
