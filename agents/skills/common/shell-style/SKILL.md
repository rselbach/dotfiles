---
name: shell-style
description: "Apply when writing, editing, or reviewing Bash, Zsh, or POSIX sh scripts. Covers formatting, quoting, arrays, error handling, pipelines, and ShellCheck."
---

# Shell Style

These conventions apply to Bash and Zsh; follow explicit POSIX `sh` requirements when present.

- Send errors to STDERR.
- Executable scripts need a brief header comment. Keep functions near the top; with multiple functions, define `main` and call `main "$@"` at the end.
- Use two-space indentation, no tabs, and an 80-character target.
- Keep `; then` and `; do` on the condition line. For long pipelines, put one segment per line with the pipe on the following indented line.
- Prefer `${var}` and quote expansions, substitutions, whitespace, and metacharacters.
- Use arrays for lists and flags. Declare locals separately from command substitutions.
- Use `lower_snake_case` for functions and variables, `UPPER_SNAKE_CASE` for constants and environment variables, and `package::function_name` for package functions.
- Prefer `$(command)`, `[[ ... ]]`, `(( ... ))`, and explicit `-z`/`-n` checks.
- Run ShellCheck and avoid `eval`.
- Use `./*` rather than bare `*` for wildcard expansion.
- Check command and pipeline results, using `PIPESTATUS` or `pipestatus` as appropriate for the shell.
- Prefer process substitution over piping into `while`.
