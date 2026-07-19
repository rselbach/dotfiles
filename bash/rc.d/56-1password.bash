get-github-token() {
  local token

  token="$(
    op item \
      --account my.1password.ca \
      get "Github Token" \
      --field credential \
      --reveal
  )" || return 1

  export GITHUB_TOKEN="${token}"
  export HOMEBREW_GITHUB_API_TOKEN="${GITHUB_TOKEN}"
}

print-gpg-keys() {
  op item get \
    "GPG keys (GnuPG)" \
    --account my.1password.ca \
    --field notesPlain \
    --reveal
}

get-token() {
  local item_name
  local account
  local field
  local token
  local exit_code

  if [[ -z "${1:-}" ]]; then
    printf 'Usage: get-token <item-name>\n' >&2
    return 1
  fi

  item_name="${1}"
  account="my.1password.ca"
  field="credential"

  if ! command -v op >/dev/null 2>&1; then
    printf '%s\n' \
      'Error: 1Password CLI (op) is not installed or not in PATH.' >&2
    return 1
  fi

  if ! op account list --format=json >/dev/null 2>&1; then
    printf '%s\n' \
      "Error: Not signed in to 1Password. Run 'eval \$(op signin)' first." \
      >&2
    return 1
  fi

  token="$(
    op item get "${item_name}" \
      --account "${account}" \
      --field "${field}" \
      --reveal 2>&1
  )"
  exit_code=$?

  if (( exit_code != 0 )); then
    printf "Error: Failed to retrieve token for item '%s'.\n" \
      "${item_name}" >&2
    printf '       op said: %s\n' "${token}" >&2
    return "${exit_code}"
  fi

  if [[ -z "${token}" ]]; then
    printf "Error: Token for item '%s' came back empty.\n" \
      "${item_name}" >&2
    return 1
  fi

  printf '%s' "${token}"
}
