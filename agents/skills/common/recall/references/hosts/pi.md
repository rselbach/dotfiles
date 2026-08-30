# Pi session history

Use this reference only when recall runs under Pi. Detect Pi through
`AI_AGENT=pi` or `PI_CODING_AGENT=true` when needed.

Prefer Pi's supported session controls when one session is already known:

- Use `/resume` or `pi --session <path-or-id>` to continue a known session.
- Use `/tree` to revisit another point in the same session.
- Use `/fork`, `/clone`, or `pi --fork <path-or-id>` when the user wants a new
  session rather than continuing the original.
- Use `/session` to show the active session file and stable session ID.

For synthesis across several local sessions, Pi stores JSONL records under
`~/.pi/agent/sessions/--<cwd>--/` by default. A custom
`PI_CODING_AGENT_SESSION_DIR` or `--session-dir` changes that location. Shell
tools expose `PI_SESSION_ID` and, for persistent sessions, `PI_SESSION_FILE`.
Exclude those values from the candidate set so recall does not mine itself.

Treat storage as a versioned implementation detail:

1. Read the first line and require a `type: "session"` header. Require an exact
   `cwd` match unless the user requested broader scope.
2. Accept the documented session version only after inspecting the header.
   Current Pi sessions use version 3 and tree-shaped `id` and `parentId`
   entries.
3. Order candidates by recorded timestamps or filesystem modification time,
   never by filename.
4. Search message text, compaction summaries, and branch summaries for the
   topic before reading a whole session tree.
5. Exclude obvious delegated-worker and evaluation sessions.
6. Preserve the session header ID as the stable citation.

If the schema no longer matches these checks, stop parsing it. Fall back to
Pi's supported session controls, live repository state, and user-provided
context rather than guessing.
