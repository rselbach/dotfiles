---
name: recall
description: "Reconstruct recent working context from the user's agent-session history, live repository state, and shared records, then return a tight current-state brief. Use for 'recall my work on X', 'catch me up', 'what have I been working on', or 'where did I leave off'."
---

# Recall

Rebuild the user's recent working context before starting or resuming work. Keep the search scoped and return a compact account of where things stand now.

The context comes from two records. Agent-session history holds what the user and agents did and decided. Shared records hold what happened around the same code through pull requests, tickets, team chat, documents, incidents, and production evidence. The **why** skill owns that shared-record sweep.

## Process

1. **Classify the request.** A specific known session should use the host's resume or fork feature. Turning habits into a durable skill is `automate-me`. Recall is for reconstruction across one or more recent sessions. If the user already supplied a complete state capsule, use it instead of mining history.
2. **Lock the scope.** Pin the workspace, topic, and time window. Default to the active workspace and the last seven days. Never read another workspace's sessions without being asked, and never silently turn "all" into a smaller range.
3. **Use the host adapter.** Discover session history through the current host's supported commands or storage. For Codex, read [`references/hosts/codex.md`](references/hosts/codex.md). For Pi, read [`references/hosts/pi.md`](references/hosts/pi.md). For OpenCode, read [`references/hosts/opencode.md`](references/hosts/opencode.md). For another host, use its documented session mechanism. If none exists, say that session history is unavailable and continue from repository state and user-provided context.
4. **Mine only relevant sessions.** Order candidates by actual time, exclude the current session and obvious worker or evaluation noise, search the topic before reading full records, and read only the regions needed. For a large corpus, delegate disjoint time slices and keep raw records out of the main context. Each result includes the goal, decisions, corrections, open threads, and artifacts, with a stable session identifier.
5. **Sweep the shared record for named targets.** When the topic names a feature, file, subsystem, or bug, invoke **why** with the question reframed as current state, prior attempts, reversions, and continuing reports. Run this alongside session mining when possible. Skip it for pure activity recall with no named target.
6. **Verify live state.** Check surfaced branches, pull requests, commits, tickets, and files with the repository's normal tools. Session history is evidence of past action, not current truth.
7. **Write the brief.** Group it by thread and stay on topic.

## Output contract

- **Capsule.** At most five bullets describing the work and its overall state.
- **Threads.** One line each, prefixed with `[merged #N]`, `[open PR #N]`, `[in flight <branch>]`, `[verified, uncommitted]`, `[reverted #N]`, or `[planned, not started]`.
- **Problems.** At most five recurring problems, including reverted fixes and continuing symptoms.
- **Next move.** The single most useful concrete action.

Keep adjacent work out unless it blocks the named topic. Cite session findings with the host's stable session identifier and shared-record findings with their original source. Sanitize private context before public output. Apply **unslop** to the brief.
