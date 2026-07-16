---
name: prde
description: "Work with the user's PRDE development environment: hcloud prde proxy/connect/up/run, local port-forwarded services, Nomad jobs/logs, Cadence, Vault, Consul, databases, and grpcurl against private APIs. Use when the user mentions PRDE, hcloud prde, local Nomad, port forwarding to a service, debugging a service in the development cluster, deploying a service repo, or checking PRDE health."
---

# PRDE Development Environment

Use this skill when helping Ryan work with PRDE, the AWS-backed Nomad development environment accessed through local port forwarding.

## Mental Model

- PRDE is a remote Nomad cluster, but day-to-day access happens through local ports.
- Ryan's PRDE also has a public URL: `https://rselbach01-ov7lmffx.dev.pedp-remote.hashicorp.services`. This is useful for specific flows such as authentication/OIDC.
- `hcloud prde proxy` is the main foreground proxy. When it is running, Nomad, Vault, Consul, Cadence, databases, and app UIs are reachable on localhost.
- Most services run as Nomad jobs. Use the local `nomad` CLI against `http://localhost:4646` to inspect jobs, allocations, events, and logs.
- Service repos are usually named `cloud-<service>`, but the Nomad job usually drops the prefix and runs as `<service>`; for example, `cloud-iam` deploys/runs as the `iam` job.
- `hcloud prde connect` creates an additional foreground port-forward from a specific Nomad service/port to localhost. Use it for private APIs, especially gRPC with `grpcurl`.
- `hcloud prde run` builds and deploys the current service repo into PRDE. It should work consistently across service repos.
- `hcloud prde up` provisions/starts services. It can take a while and should not be run casually.

## Safety Rules

1. Do not assume the proxy is running. Verify first or ask the user.
2. Treat `hcloud prde proxy` and `hcloud prde connect` as long-running foreground commands. Use `tmux` only when a persistent proxy/session is needed.
3. Do not run `hcloud prde up` unless the user explicitly asks or confirms. Prefer targeted `hcloud prde up <service>` over all-service `hcloud prde up` when that solves the problem.
4. Do not run `hcloud prde run` unless the user intends to deploy the current repo. Confirm the repo/service and run relevant local checks first unless the user asks for a fast deploy.
5. Treat `hcloud prde purge`, `nuke`, `restart`, `deactivate`, and similar commands as disruptive/destructive. Do not run them without explicit confirmation after restating the impact.
6. Do not print, copy, or commit secrets from Vault, environment output, database rows, or logs. If secret inspection is necessary, minimize output and redact in summaries.
7. Surface exact command failures. Do not summarize errors vaguely or silently retry in a different direction.
8. When command syntax is uncertain, run `hcloud prde <command> --help` or `nomad <subcommand> -help` before proceeding.

## Local Service Map

These endpoints are available when `hcloud prde proxy` is healthy:

| Service | Local access |
| --- | --- |
| portal | `http://localhost:8000` |
| admin | `http://localhost:14200` |
| api | `http://localhost:28081` |
| cadence | `http://localhost:7940/domain/hcp/workflows` |
| jaeger | `http://localhost:16686` |
| nomad-ui | `http://localhost:4646` |
| traefik-dashboard | `http://localhost:28080` |
| localstack | `http://localhost:4566` |
| dynamodb | `http://localhost:9002` |
| minio | `http://localhost:9000` |
| vault | `http://localhost:8200` |
| consul | `http://localhost:8500` |
| mysql | `mysql --host=127.0.0.1 --user=root --password=root` |
| postgres | `psql 'postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable'` |

Fresh or purged environments may show app services as unhealthy until `hcloud prde up` has been run. Once Nomad, Consul, and Vault are green, it is generally safe to run `up` if the user confirms.

## Common First Checks

Use the lightest check that answers the question:

```bash
hcloud prde health
nomad status
nomad job status <job>
nomad job allocs <job>
```

If the proxy is not running and the user wants you to start it, use a persistent session:

```bash
tmux new -d -s prde-proxy 'hcloud prde proxy'
tmux capture-pane -pt prde-proxy
```

If the user says the proxy is already running, do not start another one. Verify with `hcloud prde health`, `nomad status`, or a targeted localhost check.

## Nomad Debugging Workflow

When debugging a service in PRDE:

1. Identify the Nomad job name. If the repo is named `cloud-<service>`, first try `<service>` as the Nomad job name. If unclear, use `nomad status` and ask for the likely service name.
2. Inspect the job:
   ```bash
   nomad job status <job>
   nomad job allocs <job>
   ```
3. Inspect the relevant allocation:
   ```bash
   nomad alloc status <alloc-id>
   ```
4. Read recent logs. Prefer bounded log output first:
   ```bash
   nomad alloc logs -tail -n 200 <alloc-id> <task>
   nomad alloc logs -stderr -tail -n 200 <alloc-id> <task>
   ```
   If the task is unknown, inspect allocation status first or use `nomad alloc logs -job <job> -tail -n 200` for a quick look.
5. For live debugging, follow logs only when useful:
   ```bash
   nomad alloc logs -f -job <job>
   ```
6. Correlate failures with Cadence, Jaeger, Vault, Consul, database state, or service HTTP endpoints as appropriate.

In summaries, include the job, allocation, task, exact error lines, and the likely root cause.

## Connecting to Private Service Ports

`hcloud prde connect` requires `hcloud prde proxy` to already be running. It is a long-running foreground command.

Syntax from help:

```bash
hcloud prde connect <service>
hcloud prde connect <local-port>:<service>.<task-group>:<port-label>
```

Examples:

```bash
hcloud prde connect network
hcloud prde connect 8080:network.network:http
```

Find `service`, `task-group`, and `port-label` in the Nomad UI or job spec. The most common port labels are `http` and `grpc`. If the exact values are missing, ask the user instead of guessing.

Repo-to-service naming usually follows `cloud-<service>` repo to `<service>` Nomad service/job. For example, for `cloud-iam`, start by looking for `iam`.

For gRPC once the port is forwarded:

```bash
grpcurl -plaintext localhost:<local-port> list
grpcurl -plaintext localhost:<local-port> list <package.Service>
```

If the service requires protos, metadata, TLS, or auth headers, ask for those details or inspect the repo's existing grpcurl/dev docs.

For public APIs that require auth, include a bearer token:

```bash
grpcurl -plaintext -H "Authorization: Bearer ${TOKEN}" localhost:<local-port> list
curl -H "Authorization: Bearer ${TOKEN}" http://localhost:<port>/<path>
```

## Deploying Current Repo with `hcloud prde run`

`hcloud prde run` is the standard command for deploying local repository changes to PRDE. Use it only from the root of a service repo when the user wants to deploy that local code.

What it does:

- builds the service using Docker;
- pushes the image to the PRDE registry;
- runs Terraform for the service unless skipped;
- submits an updated Nomad job using the new image.

Before running:

1. Confirm `pwd` is the intended service repo root.
2. Check for the repo's normal test/build command and run relevant checks unless the user asks to skip.
3. Confirm the proxy is healthy.
4. Run the deploy:
   ```bash
   hcloud prde run
   ```
5. Watch Nomad status/logs for the affected job.

Useful flags from help, only when appropriate:

```bash
hcloud prde run --skip-build
hcloud prde run --skip-terraform
hcloud prde run --skip-migrate
hcloud prde run --nomad-jobs-path <path>
hcloud prde run --terraform-directory <path>
hcloud prde run --wait-until-running
```

Do not use skip flags to paper over failures unless the user explicitly chooses that tradeoff.

## Starting or Updating Services with `hcloud prde up`

`hcloud prde up` requires the proxy. It provisions configuration such as Vault secrets/policies and starts all services or specified services plus dependencies.

Use cases:

- fresh or purged environment where services have not been started;
- user explicitly wants all jobs on latest available versions;
- a targeted service and dependencies need to be started with current shared config.

Prefer:

```bash
hcloud prde up <service>
```

Only run all services with:

```bash
hcloud prde up
```

when the user confirms the time/redeploy cost.

## Public URL and OIDC

Ryan's PRDE public URL is:

```text
https://rselbach01-ov7lmffx.dev.pedp-remote.hashicorp.services
```

Use the public URL only when it is specifically useful, especially for authentication/OIDC flows. The OIDC discovery document is available at:

```text
https://rselbach01-ov7lmffx.dev.pedp-remote.hashicorp.services/.well-known/openid-configuration
```

Known endpoints from discovery:

```text
authorization_endpoint: https://rselbach01-ov7lmffx.dev.pedp-remote.hashicorp.services/oauth2/auth
token_endpoint:         https://rselbach01-ov7lmffx.dev.pedp-remote.hashicorp.services/oauth2/token
userinfo_endpoint:      https://rselbach01-ov7lmffx.dev.pedp-remote.hashicorp.services/userinfo
```

Prefer local forwarded endpoints for normal service debugging unless the task requires the public URL.

## Public API Auth

Public APIs use an `Authorization` header with a bearer token:

```http
Authorization: Bearer <token>
```

Obtaining a token is interactive OAuth2 authorization-code flow. The client ID is `hcp`. Ryan previously described the client secret as `hcp`, but the tested PRDE Hydra client currently uses `token_endpoint_auth_method=none`; token exchange with `client_secret_post` returns 401. Use authorization code + PKCE and exchange with `client_id=hcp`, no `client_secret`.

Tested working details:

- redirect URI: `http://localhost:8443/oidc/callback`
- scope request: `openid offline_access`
- observed returned scope: `openid offline`
- audience: `https://api.hashicorp.cloud`
- response includes access token, ID token, and refresh token

A helper script is bundled with this skill:

```bash
~/.agents/skills/prde/scripts/get-oidc-token.py
```

It opens the browser, listens on `http://localhost:8443/oidc/callback`, performs the token exchange, stores the token response at `~/.cache/prde-oidc-token.json` with mode `0600`, and does not print token values.

Use a saved token like this without printing it:

```bash
TOKEN=$(python3 - <<'PY'
import json
from pathlib import Path
print(json.loads((Path.home() / '.cache/prde-oidc-token.json').read_text())['access_token'])
PY
)
curl -H "Authorization: Bearer ${TOKEN}" <url>
```

Do not invent another non-interactive token flow. If a public API call needs auth and no token is available, run the helper script or ask the user to complete the OAuth flow.

## Databases and Local Tools

Use local DB access only for targeted investigation or data setup requested by the user.

```bash
psql 'postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable'
mysql --host=127.0.0.1 --user=root --password=root
```

Avoid broad `SELECT *` output. Limit rows, redact sensitive columns, and summarize rather than dumping data.

## Interaction Pattern

When PRDE work starts, gather only the missing essentials:

- Is `hcloud prde proxy` already running?
- Which profile, if not the default?
- Which service/job/API is involved? If the repo is `cloud-<service>`, use `<service>` as the first Nomad job guess.
- Is the goal inspection, a port-forward, a deploy, or a full/targeted `up`?
- For private APIs: service name, task group, port label (`http` or `grpc` are the common ones), protocol, local port, and any auth/proto requirements.
- For public APIs: whether an OAuth bearer token is already available, and whether the public PRDE/OIDC URL is needed for the flow.

Then act in small verified steps and report exact commands run plus results.
