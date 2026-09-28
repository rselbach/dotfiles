---
name: scimtest
description: Operate scimtest through its local API to configure test environments, manage users and groups, exercise OIDC or SAML sign-in, provision SCIM resources, and inspect failures. Use when testing an application's identity integration with scimtest. Repository development and browser UI verification have separate workflows.
---

# scimtest

scimtest acts as a test OIDC/SAML identity provider and a SCIM client. Control
it through the authenticated local REST API. The control API stays on loopback
even when the identity-provider endpoints use a public tunnel.

## Connect to the intended instance

Use the state file named by the user or the process you started. Default paths
are `~/Library/Application Support/scimtest/state.db` on macOS and
`${XDG_CONFIG_HOME:-$HOME/.config}/scimtest/state.db` on Linux.

Read `<state-file>.lock` for the running instance's `url` and `token`. Preserve
the exact origin, including the hostname and port. Send the token in
`X-Scimtest-Instance-Token` only to that instance's `/api/v1` endpoints. Browser
cookies do not authenticate API requests. Do not print the lock file or token.

The bundled helper needs Python 3 and its standard library. Set `SCIMTEST_API`
to the absolute path of `scripts/scimtest_api.py` beside this skill, and set
`SCIMTEST_STATE` to the intended state file. Paths below are relative to
`/api/v1`.

```sh
python3 "${SCIMTEST_API}" --state-file "${SCIMTEST_STATE}" GET /status
python3 "${SCIMTEST_API}" --state-file "${SCIMTEST_STATE}" GET /
python3 "${SCIMTEST_API}" --state-file "${SCIMTEST_STATE}" GET /environments
```

The helper rereads the lock file for each call, bypasses proxies, refuses
redirects, and handles JSON and empty `204` responses. It returns a nonzero
exit status for HTTP or connection errors. It does not retry requests.

If an instance is needed, start the installed desktop app or run this from a
scimtest source checkout with a task-specific state path:

```sh
go run ./cmd/scimtest --no-open --state-file "${SCIMTEST_STATE}"
```

Keep a server you start in the host's supported persistent process runner.
Wait for the lock file and a successful `/status` response. Source builds serve
OIDC/SAML locally and do not have the desktop release's tunnel identity. Do not
delete another process's lock file or reuse its database for disposable tests.

## Select the operation and environment

`GET /` is the running version's catalog of methods, paths, and accepted body
fields. Consult it instead of guessing commands or writing SQLite directly.
Use the environment's returned `id` in `/environments/{id}/...`; a slug is for
OIDC/SAML protocol URLs. An environment owns its own users and groups. UI
selection and query parameters cannot switch an API request's environment.

List environments before creating one. Reuse the intended environment when it
exists. If a name is ambiguous, resolve the target before changing it. Capture
returned IDs and fetch resources again after changes to confirm persistence.

Read [workflows.md](references/workflows.md) for the relevant task:

- Environment setup, directory edits, and a minimal OIDC experiment.
- OIDC or SAML flows against an application, including identifier mode.
- SCIM planning, asynchronous jobs, import, and backup/restore.
- Faults, diagnostics, desktop authorization, and tunnel status.

Send small updates with `--json '{...}'`. Use `--data-file PATH`, or
`--data-file -` for standard input, for certificates, backups, or larger JSON.
Shell-quote JSON and paths. Supply credentials through a private file or
standard input rather than exposing them in command arguments.

## Respect the API's update and result semantics

- `PATCH` preserves omitted fields. Send only the intended changes. Explicit
  `false`, empty strings, and empty arrays update fields subject to validation.
  Unknown fields and `null` are rejected, except nulls in backup restores.
- Claim-mapping objects replace the whole supplied mapping. Omit the object to
  preserve it. Disabling a protocol removes its configuration.
- An empty `oidc_client_secret` preserves or generates a confidential-client
  secret. Use `regenerate_oidc_secret: true` to rotate it. Public clients use
  PKCE and no secret. An empty `scim_bearer_token` clears the SCIM token.
- A `202` sync response means the job started. Poll the environment's
  `/sync/status` until `done`, then check `success`, `error`, and events. Use a
  bounded wait and report a still-running job instead of starting it again.
- The OIDC playground can return HTTP `200` for a failed protocol experiment.
  Check `token_status`, `userinfo_status`, `error`, and the expected claims.
  A successful playground proves scimtest's flow; verify the target app's own
  session or provisioned resource when that is the user's goal.
- A timed-out write might have completed. Read state or job status before
  retrying. A sync conflict needs a status check; a stale import needs a fresh
  preview. Do not retry every `409` as if it meant the same thing.

SCIM sync, reconcile, and per-resource push can change the configured remote
system. Keep them within the user's authorized target and changes. Backups,
connection exports, tokens, SAML responses, and raw traffic can contain
credentials or identity data. Save necessary artifacts privately and report
IDs, outcomes, and relevant claims without copying secrets into chat.

## Diagnose and finish

For `401`, reread the lock metadata and check `/status` and `/account`.
Desktop GitHub authorization may need the user's action at the returned
enrollment URL. For `421`, restore the lock file's exact host. Connection
refusal or a missing lock means there is no reachable instance at that path.
A non-JSON or missing API response can indicate an older build; report that
before trying UI endpoints as API substitutes.

After a failed protocol flow, inspect the environment's `/flows` and
`/inspections/oidc` or `/inspections/saml`, plus global `/traffic`. SCIM failures
use the environment's `/sync/trace` and resource `/operations`. Diagnostics and
armed faults are in memory and disappear on restart, so capture needed evidence
first.

Disarm faults or scenarios you armed when the experiment ends. Preserve any
environment the user needs. Stop only disposable processes you started and
remove their temporary state when it is no longer needed. Report the target
environment, the observed result, and anything still running or unverified.
