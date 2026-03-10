# Create a new jj workspace and bookmark next to the current workspace.
jja() {
  if [[ -z "${1}" ]]; then
    printf 'Usage: jja [bookmark name]\n' >&2
    return 1
  fi

  local bookmark workspace_root base parent_dir path
  bookmark="${1}"

  workspace_root="$(jj workspace root 2>/dev/null)" || {
    printf 'jja: not inside a jj workspace\n' >&2
    return 1
  }

  base="$(basename "${workspace_root}")"
  parent_dir="$(dirname "${workspace_root}")"
  path="${parent_dir}/${base}--${bookmark}"

  jj workspace add "${path}" --name "${bookmark}" || return 1
  cd "${path}" || return 1
  jj bookmark create "${bookmark}" -r @ || return 1
  mise trust "${path}" || return 1
}

# Remove the current jj workspace and its bookmark.
jjd() {
  if gum confirm "Remove workspace and bookmark?"; then
    local workspace_root workspace_name root bookmark parent_dir

    workspace_root="$(jj workspace root 2>/dev/null)" || {
      printf 'jjd: not inside a jj workspace\n' >&2
      return 1
    }

    workspace_name="$(basename "${workspace_root}")"
    root="${workspace_name%%--*}"
    bookmark="${workspace_name#*--}"

    if [[ "${root}" != "${workspace_name}" ]]; then
      jj bookmark forget "${bookmark}" || return 1
      jj workspace forget || return 1

      parent_dir="$(dirname "${workspace_root}")"
      cd "${parent_dir}" || return 1
      command rm -rf -- "${workspace_root}"
    fi
  fi
}
