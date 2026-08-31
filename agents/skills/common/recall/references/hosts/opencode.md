# OpenCode session history

Use this reference only when recall runs under OpenCode. Detect OpenCode through
`OPENCODE=1` when the host is not otherwise clear.

Prefer OpenCode's supported session controls when one session is already known:

- Use `opencode -s <session-id>` to continue a known session.
- Use `opencode -c` to continue the latest session.
- Use `opencode --fork -s <session-id>` to fork a known session.
- Use `opencode --fork -c` to fork the latest session.

For synthesis across sessions:

1. Run `opencode session list --format json` and keep exact directory matches
   unless the user requested a wider scope.
2. Order candidates by `updated`, not by list position or title.
3. Exclude child sessions and evaluation noise when their metadata makes that
   clear. Treat the newest matching top-level session as the active session
   when no active session ID is exposed.
4. Search titles first. A sanitized export is suitable only for metadata triage
   because it removes message text. When the topic may appear only in the
   conversation body, export one likely match with
   `opencode export <session-id>` and search that private output locally. Quote
   only the minimum needed in the recall response and do not persist the raw
   export.
5. Preserve the `ses_...` ID as the stable citation.

OpenCode's database under its data directory is an implementation detail. Do
not parse it unless the supported list and export commands cannot answer the
request. If export output changes shape, stop parsing it and continue from live
repository state and user-provided context.
