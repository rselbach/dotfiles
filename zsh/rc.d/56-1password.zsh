get-github-token() {
  export GITHUB_TOKEN=$(op item --account my.1password.ca get "Github Token" --field credential --reveal)
  export HOMEBREW_GITHUB_API_TOKEN=$GITHUB_TOKEN
}

print-gpg-keys() {
  op item get "GPG keys (GnuPG)" --account my.1password.ca --field notesPlain --reveal
}

get-token() {
  local item_name="${1:?Usage: get-token <item-name>}"
  local account="my.1password.ca"
  local field="credential"
  local token

  # Check that the op CLI is available.
  if ! command -v op &>/dev/null; then
    echo "Error: 1Password CLI (op) is not installed or not in PATH." >&2
    return 1
  fi

  # Check if we have a valid session (op account list will fail if not signed in).
  if ! op account list --format=json &>/dev/null; then
    echo "Error: Not signed in to 1Password. Run 'eval \$(op signin)' first." >&2
    return 1
  fi

  # Attempt to retrieve the token.
  token="$(op item get "$item_name" \
    --account "$account" \
    --field "$field" \
    --reveal 2>&1)"

  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo "Error: Failed to retrieve token for item '$item_name'." >&2
    echo "       op said: $token" >&2
    return $exit_code
  fi

  if [[ -z "$token" ]]; then
    echo "Error: Token for item '$item_name' came back empty." >&2
    return 1
  fi

  printf '%s' "$token"
}
