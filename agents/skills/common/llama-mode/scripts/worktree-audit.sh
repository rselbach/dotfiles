#!/usr/bin/env bash
# Audit git worktrees without deleting them. Reports size, age, merge state,
# local changes, remote state, PR state, and a suggested review bucket.
set -u

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
if [[ -z "${repo}" ]]; then
  echo "not in a git repo; pass a repo path" >&2
  exit 1
fi

if ! cd "${repo}"; then
  echo "could not enter repo: ${repo}" >&2
  exit 1
fi

main_wt="$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')"
if [[ -z "${main_wt}" ]]; then
  echo "could not identify the main worktree" >&2
  exit 1
fi

if ! git fetch origin main --quiet 2>/dev/null; then
  echo "warn: could not fetch origin/main; merged state may be stale" >&2
fi

prs="$(mktemp)"
cleanup() {
  rm -f "${prs}"
}
trap cleanup EXIT

if ! gh pr list --author "@me" --state all --limit 1000 \
  --json number,state,headRefName > "${prs}" 2>/dev/null; then
  printf '[]\n' > "${prs}"
fi

now="$(date +%s)"
printf "SIZE\tAGE\tMERGED\tDIRTY\tREMOTE\tPR\tBUCKET\tWORKTREE\n"

while read -r wt; do
  [[ "${wt}" == "${main_wt}" ]] && continue

  size="$(du -sh "${wt}" 2>/dev/null | awk '{print $1}')"
  [[ -z "${size}" ]] && size="?"

  head="$(git -C "${wt}" rev-parse HEAD 2>/dev/null)"
  head_ts="$(git -C "${wt}" log -1 --format='%ct' HEAD 2>/dev/null)"
  if [[ -n "${head_ts}" ]] && (( head_ts > 0 )); then
    age="$(( (now - head_ts) / 86400 ))d"
  else
    age="?"
  fi

  if [[ -n "${head}" ]] \
    && git merge-base --is-ancestor "${head}" origin/main 2>/dev/null; then
    merged="YES"
  else
    merged="no"
  fi

  porcelain="$(git -C "${wt}" status --porcelain 2>/dev/null)"
  if [[ -z "${porcelain}" ]]; then
    dirty="clean"
  elif grep -qv '^??' <<< "${porcelain}"; then
    tracked_count="$(grep -cv '^??' <<< "${porcelain}")"
    dirty="wip:${tracked_count}"
  else
    scratch_count="$(grep -c '^??' <<< "${porcelain}")"
    dirty="scratch:${scratch_count}"
  fi

  branch="$(git -C "${wt}" symbolic-ref --quiet --short HEAD 2>/dev/null)"
  if [[ -z "${branch}" ]]; then
    remote="detached"
  elif git -C "${wt}" show-ref --verify --quiet \
    "refs/remotes/origin/${branch}"; then
    remote_head="$(git -C "${wt}" rev-parse "origin/${branch}" 2>/dev/null)"
    if [[ "${remote_head}" == "${head}" ]]; then
      remote="pushed"
    else
      ahead="$(git -C "${wt}" rev-list --count \
        "origin/${branch}..HEAD" 2>/dev/null)"
      remote="ahead${ahead:-?}"
    fi
  else
    remote="no-remote"
  fi

  if [[ -n "${branch}" ]]; then
    pr="$(jq -r --arg branch "${branch}" \
      'first(.[] | select(.headRefName == $branch) |
        "#\(.number)/\(.state)") // empty' "${prs}" 2>/dev/null)"
  else
    pr=""
  fi
  [[ -z "${pr}" ]] && pr="-"

  case "${dirty}" in
    wip:*) bucket="hold-wip" ;;
    *)
      case "${pr}" in
        *OPEN*) bucket="hold-open-pr" ;;
        *)
          if [[ "${merged}" == "YES" || "${pr}" != "-" ]]; then
            bucket="safe-candidate"
          else
            bucket="review"
          fi
          ;;
      esac
      ;;
  esac

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "${size}" "${age}" "${merged}" "${dirty}" "${remote}" "${pr}" \
    "${bucket}" "${wt}"
done < <(git worktree list --porcelain | awk '/^worktree /{print $2}')
