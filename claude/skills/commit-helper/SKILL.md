---
name: commit-helper
description: Generate clear commit messages from repository changes. Use when creating commits, writing commit messages, or reviewing staged/current changes. Works with both git and jj.
---

# Commit Message Generation

## VCS Detection

**FIRST**: Detect which VCS this repo uses:

```bash
[[ -d .jj ]] && echo "JJ" || echo "GIT"
```

## Getting Changes

**If JJ repo:**
```bash
jj diff  # shows current changes
jj log -r @  # shows current change description
```

**If Git repo:**
```bash
git diff --staged  # for staged changes
git diff  # for unstaged changes
git status  # context on what's changed
```

## Message Format

Generate messages with:

1. **Summary** (under 50 chars, present tense)
2. **Detailed description** (why + what, not how)
3. **Affected components** if relevant

**Style:**
- Present tense ("Add feature" not "Added feature")
- Explain why the change matters
- Reference file:line for key changes
- Keep it human-readable

**Never include:**
- Co-author tags (especially not yourself)
- Thread IDs or internal agent metadata
- Generic fluff like "fixes bug" without context

## Example

```
Add user authentication timeout handling

Users were getting stuck in limbo when auth tokens expired during
long sessions. Now we detect expiration and prompt re-login.

- auth/session.go:42 - token expiration check
- ui/Login.tsx:18 - re-login prompt
```

## Workflow

**For JJ repos:**
1. Show current diff with `jj diff`
2. Suggest message
3. User runs: `jj describe -m "your message"`

**For Git repos:**
1. Show staged changes with `git diff --staged`
2. Suggest message
3. User runs: `git commit -m "your message"`

Do not automatically commit unless explicitly requested.
