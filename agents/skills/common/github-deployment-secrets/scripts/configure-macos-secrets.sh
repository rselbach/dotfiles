#!/usr/bin/env bash
# Configure shared macOS deployment secrets from 1Password in a GitHub repo.

set -euo pipefail

readonly OP_ITEM="App deployment secrets"
readonly OP_VAULT="Private"

usage() {
  echo "usage: $0 [--sparkle] OWNER/REPO" >&2
}

set_secret() {
  local repo="$1"
  local field="$2"
  local secret_name="$3"
  local reference

  reference="op://${OP_VAULT}/${OP_ITEM}/${field}"
  if ! op read "${reference}" \
    | gh secret set "${secret_name}" --repo "${repo}"; then
    echo "failed to configure ${secret_name}" >&2
    return 1
  fi
  echo "configured ${secret_name}"
}

main() {
  local include_sparkle=false
  if [[ "${1:-}" == "--sparkle" ]]; then
    include_sparkle=true
    shift
  fi
  if (( $# != 1 )); then
    usage
    return 2
  fi

  local repo="$1"
  local fields=(
    "apple_account_id"
    "app_specific_password"
    "apple_team_id"
    "p12_certificate_base64"
    "p12_certificate_password"
  )
  local secret_names=(
    "APPLE_ID"
    "APPLE_APP_SPECIFIC_PASSWORD"
    "APPLE_TEAM_ID"
    "MACOS_CERTIFICATE_P12_BASE64"
    "MACOS_CERTIFICATE_PASSWORD"
  )
  local index

  if [[ "${include_sparkle}" == true ]]; then
    fields+=("sparkle_eddsa_private_key")
    secret_names+=("SPARKLE_EDDSA_PRIVATE_KEY")
  fi

  if [[ ! "${repo}" =~ ^[^/]+/[^/]+$ ]]; then
    echo "repository must use OWNER/REPO format: ${repo}" >&2
    return 2
  fi
  command -v op >/dev/null || {
    echo "1Password CLI (op) is required" >&2
    return 1
  }
  command -v gh >/dev/null || {
    echo "GitHub CLI (gh) is required" >&2
    return 1
  }
  op account get >/dev/null
  gh auth status >/dev/null

  for index in "${!fields[@]}"; do
    set_secret "${repo}" "${fields[${index}]}" \
      "${secret_names[${index}]}"
  done
}

main "$@"
