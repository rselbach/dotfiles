---
name: setup-llama-stack
description: Configure the models an agent host uses for llama-stack roles. Detect available models, preserve other hosts' settings, and update the current host's tiers in models.json. Use when explicitly invoked or when changing llama-stack model choices.
---

# Setup llama-stack

Configure llama-stack's semantic roles for the current agent host. Skills refer to roles such as `feature`, `how critics`, and `arena runners`; they do not hardcode vendor model names.

The mapping lives in this skill's [`models.json`](models.json). `roles` maps each role to a tier, and `hosts` gives each host its models per tier:

```json
{
  "roles": { "bug-fix": "strongest", "how critics": "panel", "swarm workers": "fast" },
  "hosts": {
    "<host>": { "default": "<model>", "strongest": "<model>", "fast": "<model>", "panel": ["<model>", "<model>"], "judge": "<model>" }
  }
}
```

Host keys are `pi`, `claude-code`, `codex`, and `opencode`. A tier is one model or a list; a list runs one agent per entry, so its length sets the fan-out. `inherit-parent` and `auto` run on the parent session's model. The Pi `workflow` extension reads this file and exposes `roles['<role>']`; other hosts read it through the pointer in the shared `AGENTS.md`.

If the active host requires native agent definitions to select subagent models, treat those files as an adapter generated from `models.json`.

## Steps

### 1. Identify the host and available models

Identify the current agent host from the environment. Enumerate only model slugs that the host confirms can be assigned to delegated work. Prefer the host's tool metadata or supported model list. In Pi, detect the host through `AI_AGENT=pi` or `PI_CODING_AGENT=true`, inspect the current `PI_PROVIDER` and `PI_MODEL`, and use `pi --list-models` for available slugs; Pi slugs are `provider/model-id`. In OpenCode, detect `OPENCODE=1` and use `opencode models`. If no dependable list is available, offer `inherit-parent` and ask the user to provide any additional slugs they want.

Never copy model values from another host.

### 2. Load current state

Read `models.json`. Show the current host's tiers and which roles use each tier. Start a missing host with every tier at `inherit-parent`.

### 3. Map and confirm

Mark unavailable real slugs as needing a choice. Let the user accept the tiers, change a tier's models, or move a role to another tier. A role change affects every host, so say so. `arena cross-judge pool` uses the `judge` tier. Keep its models out of `panel` so the arena judge never built a candidate.

### 4. Validate

Every real slug must appear in the host's confirmed model set. `inherit-parent` and `auto` always pass. Every tier a role names must exist for every host. If a real slug is unavailable, stop and ask for a replacement rather than guessing.

### 5. Update models.json

Change only the current host's entry, plus any role moves the user approved. Keep the edit idempotent and the JSON formatting stable.

### 6. Generate the OpenCode adapter

Skip this step outside OpenCode. OpenCode Task selects a subagent type rather
than accepting a model per call, so render a worker and a read-only reviewer for
every unique real model in the `opencode` host.

Resolve this skill's installed base directory and run:

```sh
python3 scripts/render-opencode-agents.py \
  --output <managed-opencode-agent-source> \
  --model <provider/model> [--model <provider/model> ...]
```

The output must be the source directory managed by the user's configuration,
not an installed symlink destination. The generated names are
`llama-stack-worker-<provider-model-slug>` and
`llama-stack-reviewer-<provider-model-slug>`. Use worker agents for implementation,
tooling, prose, and candidate-runner roles. Use reviewer agents for exploration,
explanation, investigation, synthesis, judgment, cross-judging, architecture,
and review roles. `inherit-parent` and `auto` use the ordinary `general` or
`reviewer` agent instead and are not rendered.

Run the same command with `--check` after rendering.

### 7. Verify

Read `models.json` back. Confirm that it parses, every role resolves for every host, every real slug is available, and other hosts are unchanged. In Pi, the workflow extension's test suite also checks that the shipped file resolves for every host; its README lists the development steps. Under OpenCode, also inspect at least one generated worker and reviewer with `opencode debug agent <agent-name>` and confirm their model and permissions. Tell the user that new sessions will read the mapping and agent definitions after restart.

### 8. Offer project verification

Check whether the project has a `verify-*` skill or another harness that drives the real artifact. If not, offer once to invoke `create-verification-skill`. Move on if the user declines.
