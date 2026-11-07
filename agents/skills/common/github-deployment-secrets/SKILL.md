---
name: github-deployment-secrets
description: Configure or audit GitHub Actions deployment secrets sourced from the 1Password Environment "Github deployment". Use when setting up a GitHub repository for macOS Developer ID signing, notarization, Sparkle update signing, or Homebrew tap updates, when a workflow references Apple deployment credentials or TAP_GITHUB_TOKEN, or when checking which shared deployment fields already exist in 1Password.
---

# GitHub Deployment Secrets

Use the 1Password Environment `Github deployment` as the source of shared macOS
deployment credentials. Its secrets are mounted as a local `.env` file at
`~/.config/scimtest-deploy/github-deployment.env`.

## Safety

- Never print, log, paste, or store secret values in files or model output.
- Read values only through `scripts/configure-macos-secrets.sh`, which pipes
  each one directly into `gh secret set`.
- Report variable names and availability only.
- Never commit credentials or the mounted file.
- Get explicit user authorization before writing GitHub secrets. Reading
  secret names is safe by default.

## Known variables

Map the Environment variables to GitHub Actions secrets as follows:

| Environment variable | GitHub secret |
| --- | --- |
| `APPLE_ACCOUNT_ID` | `APPLE_ID` |
| `APP_SPECIFIC_PASSWORD` | `APPLE_APP_SPECIFIC_PASSWORD` |
| `APPLE_TEAM_ID` | `APPLE_TEAM_ID` |
| `APPLE_SIGNING_IDENTITY` | `APPLE_SIGNING_IDENTITY` |
| `P12_CERTIFICATE_BASE64` | `MACOS_CERTIFICATE_P12_BASE64` |
| `P12_CERTIFICATE_PASSWORD` | `MACOS_CERTIFICATE_PASSWORD` |
| `SPARKLE_EDDSA_PRIVATE_KEY` | `SPARKLE_EDDSA_PRIVATE_KEY` |
| `HOMEBREW_TAP_TOKEN` | `TAP_GITHUB_TOKEN` |

These variables support Developer ID signing plus `notarytool` authentication
with an Apple Account. The Sparkle private key signs update archives and
appcasts. They do not imply App Store distribution.

The `HOMEBREW_TAP_TOKEN` variable is a GitHub token that can push to
`rselbach/homebrew-tap`. Release workflows use it to update a formula or cask
after they publish a release.

The `SPARKLE_EDDSA_PUBLIC_KEY` variable is not a GitHub secret. Add its value to
the application's `Info.plist` as `SUPublicEDKey`. The public key is safe to
commit, but read it only when the task requires configuring Sparkle.

The `APPLE_SIGNING_IDENTITY` variable contains the full Developer ID Application
identity used by `codesign`.

Use the secret names required by the target workflow. For example, LlamaProxy
uses `APPLE_PASSWORD`, `APPLE_CERTIFICATE`, and `APPLE_CERTIFICATE_PASSWORD`
instead of `APPLE_APP_SPECIFIC_PASSWORD`, `MACOS_CERTIFICATE_P12_BASE64`, and
`MACOS_CERTIFICATE_PASSWORD`, respectively. The source variables are unchanged.

Do not invent missing values. A repository workflow may additionally require an
ephemeral keychain password, another GitHub token, or application-specific
configuration.
Identify those separately from the workflow and ask the user where they are
stored.

## Workflow

1. Inspect the repository workflow and enumerate required secret names.
2. For a read-only audit, call the 1Password MCP `list_secrets` for the
   `Github deployment` Environment and confirm each expected variable name is
   present. Report only present or missing names.
3. Confirm the mount exists at `~/.config/scimtest-deploy/github-deployment.env`.
   If it is missing, recreate it with the MCP `create_local_env_file` tool
   (accountId `DCEK4TMLNBDINKUDDVMEZSEG6E`, environmentId
   `6gbwtrqhednbhoojky2jt352uq`, environmentName `Github deployment`) and
   ask the user before doing so.
4. For authorized GitHub configuration, run
   `scripts/configure-macos-secrets.sh OWNER/REPO`. For a workflow that signs
   Sparkle updates, add `--sparkle`. For a workflow that updates the Homebrew
   tap, add `--homebrew-tap`. The script checks that every expected variable is
   present before it writes anything. If the workflow uses different secret
   names, adapt the mappings in the script first.
5. Compare the configured names with the workflow again and report any
   repo-specific secrets that remain.
6. The helper removes the mount after all secrets are set. If it fails, the
   mount stays so the run can be retried. Check leftovers with the MCP
   `list_local_env_files` tool.

Prefer repository secrets. Use environment secrets only when the workflow
explicitly references a protected GitHub Environment and adjust the helper
deliberately rather than assuming a destination.
