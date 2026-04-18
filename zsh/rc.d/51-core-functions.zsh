if ! command -v open >/dev/null 2>&1 && command -v xdg-open >/dev/null 2>&1; then
  open() (
    xdg-open "$@" >/dev/null 2>&1 &
  )
fi

n() {
  if (( $# == 0 )); then
    command nvim .
    return
  fi

  command nvim "$@"
}

compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress='tar -xzf'
