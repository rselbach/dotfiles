# Agent Instructions

## Environment

- Workspace: `~/devel`; personal dotfiles live in `~/devel/dotfiles`.
- For shell, editor, terminal, app, or machine configuration, load the
  `dotfiles-repo` skill. Edit the repo source when it already manages the
  configuration; otherwise keep the change at its normal live location.
- Concurrent edits are normal. Refresh context before editing and handoff.

## Scope and design

- Prefer the simplest solution that fully meets the request. No speculative
  features, abstractions, or configurability.
- Touch only task-related code. Match existing style and avoid adjacent cleanup.
- Do not leave breadcrumbs such as `// moved to X` after deleting or moving code.

## Execution and verification

- Keep closely related statements together, including a call and its error
  check or assertions about the same result. Do not put a blank line after
  every statement or add section comments when whitespace is enough.
- Remove temporary binaries or artifacts created solely for testing.
- Use Community references for fake data, such as Troy Barnes or Greendale
  Community College.

## Go

- Never discard or overwrite an error without checking it. Avoid panics outside
  `Must*` functions.
- Prefer `any` to `interface{}`.
- Prefer early returns and `switch` to `if`/`else`; avoid `else` where practical.
- Use map-based table tests, `tc` for loop cases, and `want` rather than
  `expected`.
- Add Godoc to exported symbols; use lowercase comments for internal symbols.
- When using `testify/require`, prefer to `r := require.New(t)` over using
  package-level function (e.g. good: `r.Equal(..)`, bad `require.Equal(...)`)

## Shell

These conventions apply to Bash and Zsh; follow explicit POSIX `sh` requirements
when present.

- Send errors to STDERR.
- Executable scripts need a brief header comment. Keep functions near the top;
  with multiple functions, define `main` and call `main "$@"` at the end.
- Use two-space indentation, no tabs, and an 80-character target.
- Keep `; then` and `; do` on the condition line. For long pipelines, put one
  segment per line with the pipe on the following indented line.
- Prefer `${var}` and quote expansions, substitutions, whitespace, and
  metacharacters.
- Use arrays for lists and flags. Declare locals separately from command
  substitutions.
- Use `lower_snake_case` for functions and variables, `UPPER_SNAKE_CASE` for
  constants and environment variables, and `package::function_name` for package
  functions.
- Prefer `$(command)`, `[[ ... ]]`, `(( ... ))`, and explicit `-z`/`-n` checks.
- Run ShellCheck and avoid `eval`.
- Use `./*` rather than bare `*` for wildcard expansion.
- Check command and pipeline results, using `PIPESTATUS` or `pipestatus` as
  appropriate for the shell.
- Prefer process substitution over piping into `while`.

## Terraform

- Comment resource relationships.
- Split conventional files such as `variables.tf` and `outputs.tf`.
- Name a sole resource of its type in a module `this`.

## Tools

- Prefer `ast-grep` for structural code searches and tree-safe edits.
- Given a GitHub issue or pull-request URL, use `gh` rather than web search.

## Version control

- Before the first VCS operation, detect `.jj`. Use only JJ when present and only
  Git otherwise; never mix them.
- Prefix new branches and bookmarks with `rselbach/`.
- Never run destructive VCS commands such as `reset --hard`, `clean`, or
  destructive `restore`. Do not delete or rename unexpected files.
- Avoid manual Git stashes and repository-wide search-and-replace operations.
- Before editing and handoff, refresh status and diff. Preserve unrelated work.
- For branch or PR reviews, refresh the relevant remote and compare against the
  intended base. For current-file audits, inspect the requested files. Never
  commit existing uncommitted changes unless explicitly asked.
- Never add yourself as co-author or include internal thread or agent IDs.
- Commit messages need a concise subject and one or two short paragraphs that
  explain the purpose.
- In JJ repositories, load the `jj-workflow` skill. Before committing, pull the
  nearest bookmark with `jj tug`; ask if unsure.

## llama-stack models

Skills name semantic roles such as `bug-fix` or `how critics`. Resolve them
through `~/.agents/llama-stack/models.json`: `roles` maps each role
to a tier (`default`, `strongest`, `fast`, `panel`, `judge`), and `hosts.<host>` maps each
tier to a model or a list of models for `pi`, `claude-code`, `codex`, or
`opencode`. A list runs one agent per entry, so its length sets the fan-out.
`inherit-parent` and `auto` run on the parent session's model. Under Pi, the
`workflow` tool exposes the resolved lists as `roles['<role>']`.
