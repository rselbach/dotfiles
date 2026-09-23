---
name: jj-workflow
description: Jujutsu (jj) version control. Load when the repo has a .jj directory, when the user mentions jj/jujutsu, when running jj commands, or when the system reminder shows vcs=jj or vcs=jj-colocated.
---

# jj Workflow

## When to Load This Skill

Use this skill when:

- The repo has a `.jj` directory (jj is in use)
- The user asks about jj/jujutsu workflow
- You are about to run jj commands (status/diff/describe/bookmark/push)
- The system reminder indicates `vcs=jj` or `vcs=jj-colocated`

## CRITICAL: Avoid Interactive Mode

**Always use `-m` flag** to prevent jj from opening an editor:

```bash
# WRONG - opens editor, blocks AI
jj new
jj describe
jj squash

# CORRECT - non-interactive
jj new -m "message"
jj describe -m "message"
jj squash -m "message"
```

**Never use these interactive commands:**

- `jj split` - inherently interactive, no non-interactive mode

## Mental Model

**No staging area.** Your working directory is always a commit. Every save is tracked.

- `@` = your current change (the working copy)
- `@-` = parent of current change
- Changes are mutable until pushed

## Bookmark Names

Prefix every new branch or bookmark with `llama/`.

- Correct: `llama/feature-x`
- Incorrect: `feature-x`
- Existing shared bookmarks such as `main` or `master` keep their repository
  names, but do not move them unless the user explicitly asks.

## When to Use What

The mutation recipes below apply only when the task authorizes creating,
describing, or rewriting changes. Loading this skill or inspecting status does
not authorize those operations. Preserve unrelated work and follow repository
approval rules, including for recovery commands.

| Situation                   | Do This                                                   |
| --------------------------- | --------------------------------------------------------- |
| Creating an authorized change | `jj new -m "what I'm trying"`                          |
| Describing an owned change when authorized | `jj describe -m "what I'm doing"`          |
| Work is done, move on       | `jj new -m "next task"`                                   |
| Annotate what you did       | `jj describe -m "feat: auth"`                             |
| Broke something             | `jj op log` → `jj op restore <id>`                        |
| Undo one file               | `jj restore --from @- <path>`                             |
| Combine messy commits       | `jj squash -m "combined message"`                         |
| Try something risky         | `jj new -m "experiment"`, then `jj abandon @` if it fails |

## AI Coding Pattern

Give changes meaningful descriptions when creating or describing them is authorized. Do not create or describe a change merely because a task started.

```bash
# When authorized, create a new change
jj new -m "feat: add user logout button"
# Now implement... jj tracks everything automatically

# Describe an owned change when authorized
jj describe -m "feat: what I'm working on"
```

**Why this matters:**

- `jj log` shows meaningful history while working
- Easier to understand what each change does
- Simpler to curate/squash later
- Teammates can follow progress

```bash
# Checkpoint before risky changes
jj describe -m "checkpoint: auth works"
jj new -m "trying OAuth integration"

# If it breaks
jj op log              # Find good state
jj op restore <id>     # Go back

# When done, curate history
jj squash -m "feat: OAuth support"
```

## Push to GitHub

**Pushed commits are immutable.** You can't squash into or modify them. The safe pattern:

```bash
# 1. Abandon empty checkpoint commits cluttering history
jj log -r '::@'                      # Find checkpoints
jj abandon <change-ids>              # Remove empty ones

# 2. Describe your work (don't try to squash into immutable parent)
jj describe -m "feat: what you did"

# 3. Create a prefixed bookmark and push it
jj bookmark create llama/feature-x -r @
jj git push --bookmark llama/feature-x
```

**For feature branches (new):**

```bash
jj bookmark create llama/feature-x -r @
jj git push --bookmark llama/feature-x
```

**For feature branches (updating):**

```bash
jj bookmark set llama/feature-x -r @
jj git push --bookmark llama/feature-x
```

Teammates see clean git. They don't know you used jj.

## Recovery

The oplog records every operation. Nothing is lost.

```bash
jj op log                      # See all operations
jj undo                        # Undo last operation
jj op restore <id>             # Jump to any past state
```
