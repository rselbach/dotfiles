#!/usr/bin/env bash
# Configure shared macOS deployment secrets from the "Github deployment"
# 1Password Environment, mounted as a local .env file, in a GitHub repo.

set -euo pipefail

readonly ENV_FILE="${HOME}/.config/scimtest-deploy/github-deployment.env"

usage() {
  echo "usage: $0 [--sparkle] [--homebrew-tap] OWNER/REPO" >&2
}

env_has() {
  local name="$1"

  awk -v name="${name}" '
    index($0, name "=") == 1 { found = 1 }
    END { exit !found }
  ' "${ENV_FILE}"
}

env_value() {
  local name="$1"

  awk -v name="${name}" '
    index($0, name "=") == 1 { print substr($0, length(name) + 2) }
  ' "${ENV_FILE}"
}

set_secret() {
  local repo="$1"
  local name="$2"
  local secret_name="$3"

  if ! env_value "${name}" \
    | gh secret set "${secret_name}" --repo "${repo}"; then
    echo "failed to configure ${secret_name}" >&2
    return 1
  fi
  echo "configured ${secret_name}"
}

main() {
  local include_sparkle=false
  local include_homebrew_tap=false
  while [[ "${1:-}" == --* ]]; do
    case "$1" in
      --sparkle) include_sparkle=true ;;
      --homebrew-tap) include_homebrew_tap=true ;;
      *)
        usage
        return 2
        ;;
    esac
    shift
  done
  if (( $# != 1 )); then
    usage
    return 2
  fi

  local repo="$1"
  local names=(
    "APPLE_ACCOUNT_ID"
    "APP_SPECIFIC_PASSWORD"
    "APPLE_TEAM_ID"
    "APPLE_SIGNING_IDENTITY"
    "P12_CERTIFICATE_BASE64"
    "P12_CERTIFICATE_PASSWORD"
  )
  local secret_names=(
    "APPLE_ID"
    "APPLE_APP_SPECIFIC_PASSWORD"
    "APPLE_TEAM_ID"
    "APPLE_SIGNING_IDENTITY"
    "MACOS_CERTIFICATE_P12_BASE64"
    "MACOS_CERTIFICATE_PASSWORD"
  )
  local index

  if [[ "${include_sparkle}" == true ]]; then
    names+=("SPARKLE_EDDSA_PRIVATE_KEY")
    secret_names+=("SPARKLE_EDDSA_PRIVATE_KEY")
  fi
  if [[ "${include_homebrew_tap}" == true ]]; then
    names+=("HOMEBREW_TAP_TOKEN")
    secret_names+=("TAP_GITHUB_TOKEN")
  fi

  if [[ ! "${repo}" =~ ^[^/]+/[^/]+$ ]]; then
    echo "repository must use OWNER/REPO format: ${repo}" >&2
    return 2
  fi
  command -v gh >/dev/null || {
    echo "GitHub CLI (gh) is required" >&2
    return 1
  }
  if [[ ! -e "${ENV_FILE}" ]]; then
    echo "Environment mount not found: ${ENV_FILE}" >&2
    return 1
  fi
  gh auth status >/dev/null

  for index in "${!names[@]}"; do
    if ! env_has "${names[${index}]}"; then
      echo "missing ${names[${index}]} in Environment mount" >&2
      return 1
    fi
  done

  for index in "${!names[@]}"; do
    set_secret "${repo}" "${names[${index}]}" \
      "${secret_names[${index}]}"
  done

  rm -f -- "${ENV_FILE}"
  echo "removed ${ENV_FILE}"
}

main "$@"
