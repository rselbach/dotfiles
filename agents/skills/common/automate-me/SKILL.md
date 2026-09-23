---
name: automate-me
description: "Use for 'automate me', 'create, update, or refresh my mode skill', or requests to capture the user's working style as a skill. Drafts or revises a personal mode skill, optionally using recent session evidence."
---

# Automate me

Turn the user's working conventions into one concise `-mode` skill tailored to them.

This workflow combines **recall** for session evidence, the host's
skill-authoring capability, and **unslop** for prose discipline. In Codex, use
`$skill-creator` for authoring. In Pi, read Pi's current skills documentation
and edit `SKILL.md` directly. In OpenCode, load **customize-opencode**, edit
`SKILL.md` directly, and validate it with `opencode debug skill`.

## Flow

### 0. Check for an existing skill

Look recursively for `.agents/skills/**/*-mode/SKILL.md` and `~/.agents/skills/**/*-mode/SKILL.md` matching the user's handle. Mode skills can live in a personal category directory, not only at the top level. If one exists, confirm intent unless the user already asked to update it:

- Update the existing skill, the default for repeat runs.
- Start fresh, which is rare and needs a reason.

In update mode, mine only history since the skill was last edited, ask what changed or is missing, and preserve sections the user has not contradicted.

### 1. Mine their history

Invoke **recall** with a preference-mining scope over the active workspace and a concrete time window, normally the last two to four weeks. Never search another workspace without the user's request. Ask recall to return recurring patterns with evidence pointers in these areas:

- Response preferences such as length, tone, and format.
- Delegation habits, including parallelism and model roles.
- Verification posture and what "done" means.
- Code and prose discipline.
- Process conventions for worktrees, commits, pull requests, and reviews.
- Meta preferences such as fixing skills during work.

For a large history, let recall partition the work across subagents. Cross-check findings before elevating them. Patterns seen in at least two sessions are high-confidence; lone signals are weak unless the user confirms them.

### 2. Ask the user directly

Mining misses intent that has not appeared in prior work. Prefer the host's structured-question capability when available. Use one or two short category questions, then one free-form question for anything the options missed. Do not dump a questionnaire on the user.

### 3. Cluster findings

Group only the combined signals that earn a section. Common sections include response style, autonomy, understanding before implementation, subagents, prose and code discipline, review and verification, process, and skill-authoring habits.

Read **llama-mode** for granularity, not content. The user's rules are not llama's rules.

### 4. Draft the skill

Use the host's skill-authoring capability. In Codex, invoke `$skill-creator`.
In Pi, read Pi's current skills documentation and edit `SKILL.md` directly.
In OpenCode, load **customize-opencode**, edit `SKILL.md` directly, and validate
it with `opencode debug skill`.

- Preserve an existing mode skill's category.
- For a new project skill, use `.agents/skills/<handle>-mode/SKILL.md`, or `.agents/skills/<handle>/<handle>-mode/SKILL.md` when the repository already groups personal skills that way.
- Use `~/.agents/skills/<handle>-mode/` only when the user wants a personal skill.
- Make the frontmatter name match the directory.
- Make the description trigger on the user's handle, the skill name, and requests to work in their style, not generic work such as coding or reviewing.
- Keep the mode explicit-only by default. Add host-specific invocation metadata when supported. For Codex, set `policy.allow_implicit_invocation: false` in `agents/openai.yaml`. For OpenCode, begin the description with `Use only when explicitly invoked`; it has no equivalent skill metadata. In a shared skill, do not use Pi's `disable-model-invocation` unless every host should honor it.

### 5. Iterate on prose

Apply **unslop** and the active skill-authoring guidance. Show the draft to the user, take feedback, and cut anything that does not change future behavior.

### 6. Land it

When the user asks to land the skill, follow the repository's version-control workflow. Do not create branches, commits, or pull requests without the authorization required by repository instructions.

## Guardrails

- Do not overfit to one conversation or one correction.
- Reference other skills instead of copying their contents.
- Add a section only for a specific non-default rule.
- Use "the user" or "the human" in instructions so others can adopt the skill.
- Sparse is fine. Do not force every possible category into the result.

## Evaluation

A mode skill is subjective output. Ask whether it reads like the user and whether it missed anything. Run trigger evaluation only when real use shows that the description routes poorly.

## When not to use

- For a task-specific skill, use the host's skill-authoring capability directly without history mining.
- For one narrow workflow, create a regular skill rather than a mode skill.
