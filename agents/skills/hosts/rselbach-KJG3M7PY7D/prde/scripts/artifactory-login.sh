#!/usr/bin/env bash
# Refresh both PRDE Docker registry logins with a temporary Doormat token.
set -euo pipefail
set +x

main() {
  local token_json token registry username
  local -a registries=(
    cloud-services-local.artifactory.hashicorp.engineering
    cloud-dev-docker-local.artifactory.hashicorp.engineering
  )

  username="${USER:?USER must identify the HashiCorp account}@hashicorp.com"
  if ! doormat login; then
    printf 'Failed to authenticate with Doormat.\n' >&2
    return 1
  fi
  if ! token_json="$(doormat artifactory create-token)"; then
    printf 'Failed to create an Artifactory token.\n' >&2
    return 1
  fi
  if ! token="$(jq -er \
    '.access_token | select(type == "string" and length > 0 and . != "null")' \
    <<< "${token_json}")"; then
    printf 'Failed to obtain a valid Artifactory token.\n' >&2
    return 1
  fi

  for registry in "${registries[@]}"; do
    if ! printf '%s\n' "${token}" \
      | docker login --username "${username}" --password-stdin \
          "${registry}"; then
      printf 'Failed to authenticate Docker to %s.\n' "${registry}" >&2
      return 1
    fi
  done
}

main "$@"
