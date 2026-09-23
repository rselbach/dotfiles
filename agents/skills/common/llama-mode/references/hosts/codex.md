# Codex host adapter

Use this reference only when llama-stack runs under Codex.

## Skills

Codex discovers personal skills under `$HOME/.agents/skills` and repository skills under `.agents/skills`. Explicit invocation uses `$skill-name`. Keep these spellings out of portable workflow prose unless the instruction is specifically for Codex.

Resolve bundled scripts relative to the `SKILL.md` Codex loaded. Do not assume the current repository contains the skill. For a standard personal installation, the worktree audit command is:

```bash
bash "$HOME/.agents/skills/llama-mode/scripts/worktree-audit.sh" \
  "$(git rev-parse --show-toplevel)"
```

## Delegation

Codex can delegate after a direct request or when an applicable `AGENTS.md` or skill asks for subagents. Use bounded role prompts and the semantic model roles from the repository's Codex llama-stack configuration. A custom `.codex/agents` definition is optional and is not required by llama-stack.

## Long-running work

Codex does not provide a `/loop` command. Use the recurring-monitoring or scheduled-task mechanism available in the current Codex surface. `/goal` may hold a durable objective when that command is available. In a plain CLI session without recurring wake support, run bounded polling through the repository's watcher, return durable state, and resume explicitly instead of simulating persistence with an unattended shell sleep.

## Sessions

For a known prior session, prefer `/resume`, `codex resume`, or `codex fork`. For synthesis across sessions, invoke **recall** and follow its Codex session adapter. Do not make llama playbooks parse Codex JSONL directly.
