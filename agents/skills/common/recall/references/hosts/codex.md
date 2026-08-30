# Codex session history

Prefer Codex's supported session controls when one session is already known:

- In an interactive session, use `/resume` to select and resume a previous session.
- From the CLI, use `codex resume <SESSION_ID>` for a known session.
- Use `codex resume --last` for the most recent session in the current working-directory scope.
- Use `codex resume --all` only when the requested scope genuinely crosses working directories.
- Use `codex fork` when the user wants a new branch of conversation rather than continuing the original session.

For synthesis across several local sessions, Codex currently stores session records under `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` and archived records under `~/.codex/archived_sessions/`.

Treat this storage as a versioned implementation detail:

1. Inspect record keys before parsing and keep format-specific parsing isolated.
2. Read `session_meta` first and require an exact `payload.cwd` match for the active workspace unless the user requested broader scope.
3. Order candidates by their recorded time or filesystem modification time, never by filename.
4. Exclude the current session ID and obvious delegated-worker sessions.
5. Search for the topic before reading a full record.
6. Never scan unrelated workspaces merely because `--all` or the directory tree makes them visible.

If the on-disk schema no longer matches these checks, stop parsing it. Fall back to supported resume commands, live repository state, and user-provided context rather than guessing.
