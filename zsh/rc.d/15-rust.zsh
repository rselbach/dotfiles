_path_add "${HOME}/.cargo/bin"

# Homebrew's rustup is keg-only, so its cargo and rustc proxies need a path entry.
if [[ -d /opt/homebrew/opt/rustup/bin ]]; then
  _path_add /opt/homebrew/opt/rustup/bin
fi
