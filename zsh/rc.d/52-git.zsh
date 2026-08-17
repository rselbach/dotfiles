alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
alias rebase='git fetch -va && git rebase origin/main'
alias rb='git fetch -va && git rebase origin/main'

# Create a new worktree and branch from within current git directory.
ga() {
  local branch
  local base
  local path

  if [[ -z "${1:-}" ]]; then
    printf 'Usage: ga [branch name]\n' >&2
    return 1
  fi

  branch="${1}"
  base="$(basename "${PWD}")" || return 1
  path="../${base}--${branch}"

  git worktree add -b "${branch}" "${path}" || return 1
  mise trust "${path}" || return 1
  cd "${path}" || return 1
}

# Remove worktree and branch from within active worktree directory.
gd() {
  local cwd
  local worktree
  local root
  local branch

  if gum confirm "Remove worktree and branch?"; then
    cwd="$(pwd)" || return 1
    worktree="$(basename "${cwd}")" || return 1

    # Split on the first `--`.
    root="${worktree%%--*}"
    branch="${worktree#*--}"

    # Protect against accidentally removing a non-worktree directory.
    if [[ "${root}" != "${worktree}" ]]; then
      cd "../${root}" || return 1
      git worktree remove "${cwd}" --force || return 1
      git branch -D "${branch}" || return 1
    fi
  fi
}
