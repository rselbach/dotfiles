---
name: github-deployment-secrets
description: Configure or audit GitHub Actions deployment secrets sourced from the 1Password item "App deployment secrets". Use when setting up a GitHub repository for macOS Developer ID signing, notarization, or Sparkle update signing, when a workflow references Apple deployment credentials, or when checking which shared deployment fields already exist in 1Password.
---

# GitHub Deployment Secrets

Use the 1Password item `App deployment secrets` in the `Private` vault as the
source of shared macOS deployment credentials.

## Safety

- Never print, log, paste, or store secret values in files or model output.
- Retrieve fields with `op read` and pipe them directly to the consumer.
- Report field names and availability only.
- Never commit credentials. Keep 1Password references out of public CI config
  when they reveal private account or vault structure unnecessarily.
- Get explicit user authorization before writing GitHub secrets. Reading field
  metadata is safe by default.

## Known fields

Map the item fields to GitHub Actions secrets as follows:

| 1Password field | GitHub secret |
| --- | --- |
| `apple_account_id` | `APPLE_ID` |
| `app_specific_password` | `APPLE_APP_SPECIFIC_PASSWORD` |
| `apple_team_id` | `APPLE_TEAM_ID` |
| `p12_certificate_base64` | `MACOS_CERTIFICATE_P12_BASE64` |
| `p12_certificate_password` | `MACOS_CERTIFICATE_PASSWORD` |
| `sparkle_eddsa_private_key` | `SPARKLE_EDDSA_PRIVATE_KEY` |

These fields support Developer ID signing plus `notarytool` authentication with
an Apple Account. The Sparkle private key signs update archives and appcasts.
They do not imply App Store distribution.

The `sparkle_eddsa_public_key` field is not a GitHub secret. Add its value to
the application's `Info.plist` as `SUPublicEDKey`. The public key is safe to
commit, but read it only when the task requires configuring Sparkle.

Do not invent missing values. A repository workflow may additionally require a
signing identity, ephemeral keychain password, GitHub token, or
application-specific configuration. Identify those separately from the
workflow and ask the user where they are stored.

## Workflow

1. Inspect the repository workflow and enumerate required secret names.
2. Check `op account list` without exposing values. If desktop integration is
   unavailable, ask the user to unlock/restart 1Password and enable its CLI
   integration under Developer settings.
3. For a read-only audit, check that each expected field resolves; discard the
   value and report only present/missing state.
4. For authorized GitHub configuration, run
   `scripts/configure-macos-secrets.sh OWNER/REPO`. For a workflow that signs
   Sparkle updates, add `--sparkle`. The script streams each value from
   1Password directly into `gh secret set`.
5. Compare the configured names with the workflow again and report any
   repo-specific secrets that remain.

Prefer repository secrets. Use environment secrets only when the workflow
explicitly references a protected GitHub Environment and adjust the helper
deliberately rather than assuming a destination.
