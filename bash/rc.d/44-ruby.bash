if command -v rbenv >/dev/null 2>&1; then
  if rbenv_init_output="$(rbenv init - bash)"; then
    if ! eval "${rbenv_init_output}"; then
      printf '%s\n' 'rbenv: failed to evaluate Bash initialization' >&2
    fi
  else
    printf '%s\n' 'rbenv: failed to generate Bash initialization' >&2
  fi
  unset rbenv_init_output
fi
