# AGENTS: Neovim config repository (LazyVim + Lua)
Purpose: document build, lint, style, and editing rules for agents.
Tech Stack: Neovim config in Lua; no Go/TS backend or test harness present.
Build: none (config only). Do not add build steps.
Plugin manager: use :Lazy sync (install/update), :Lazy check, :Lazy restore.
Lint/Format: run `stylua .` (config in stylua.toml: 2-space, width 120).
Import/style: keep `local` requires at top; group stdlib, then plugins, then local modules.
Module naming: use snake_case file names under lua/, return tables from plugin specs.
Indentation: 2 spaces; do not use tabs (enforced by stylua).
Line length: target <= 120 chars per stylua config.
Comments: keep existing header comments; write lowercase inline comments; no large ascii banners.
Error handling: prefer early return; for critical failures (e.g., cloning lazy) use `os.exit(1)`.
Avoid global pollution: use `local` for functions/vars; only write to `vim.g`, `vim.o`, `vim.opt` deliberately.
Plugin specs: return list/table; modify opts via function(_, opts) and return opts.
Keymaps/autocmds: place custom maps in lua/config/keymaps.lua and autocmds in config/autocmds.lua.
Testing: no test suite; if adding tests, prefer plenary (`:lua require'plenary.test_harness'.test_directory(...)`); single test file via that path.
Single-test example cmd: `nvim --headless -c "PlenaryBustedDirectory tests/file_spec.lua {minimal_init='tests/minimal_init.vim'}"`.
Do not introduce dependencies without user approval; keep repository minimal.
Cursor/Copilot rules: none present; copilot configured in plugins/copilot.lua (respect existing keymaps).
Commit scope: only touch relevant files; run stylua before proposing commits.
