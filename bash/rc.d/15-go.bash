export GOLANG_PROTOBUF_REGISTRATION_CONFLICT='ignore'
export GOPRIVATE='github.com/hashicorp'

_bash_path+=(
  "${HOME}/.govm/current/bin"
  "${HOME}/devel/go/bin"
  "${HOME}/go/bin"
)

coverhtml() {
  go test -coverprofile=/tmp/c.out "$@" || return 1
  go tool cover -html=/tmp/c.out -o /tmp/coverage.html || return 2

  if command -v open >/dev/null 2>&1; then
    open /tmp/coverage.html
    return
  fi

  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open /tmp/coverage.html
  fi
}
