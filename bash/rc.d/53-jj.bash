# Create a new jj workspace and bookmark next to the current workspace.
jja() {
  local bookmark
  local workspace_root
  local base
  local parent_dir
  local path

  if [[ -z "${1:-}" ]]; then
    printf 'Usage: jja [bookmark name]\n' >&2
    return 1
  fi

  bookmark="${1}"

  workspace_root="$(jj workspace root 2>/dev/null)" || {
    printf 'jja: not inside a jj workspace\n' >&2
    return 1
  }

  base="$(basename "${workspace_root}")" || return 1
  parent_dir="$(dirname "${workspace_root}")" || return 1
  path="${parent_dir}/${base}--${bookmark}"

  jj workspace add "${path}" --name "${bookmark}" || return 1
  cd "${path}" || return 1
  jj bookmark create "${bookmark}" -r @ || return 1
  mise trust "${path}" || return 1
}

# Remove the current jj workspace and its bookmark.
jjd() {
  local workspace_root
  local workspace_name
  local root
  local bookmark
  local parent_dir

  if gum confirm "Remove workspace and bookmark?"; then
    workspace_root="$(jj workspace root 2>/dev/null)" || {
      printf 'jjd: not inside a jj workspace\n' >&2
      return 1
    }

    workspace_name="$(basename "${workspace_root}")" || return 1
    root="${workspace_name%%--*}"
    bookmark="${workspace_name#*--}"

    if [[ "${root}" != "${workspace_name}" ]]; then
      jj bookmark forget "${bookmark}" || return 1
      jj workspace forget || return 1

      parent_dir="$(dirname "${workspace_root}")" || return 1
      cd "${parent_dir}" || return 1
      command rm -rf -- "${workspace_root}" || return 1
    fi
  fi
}
