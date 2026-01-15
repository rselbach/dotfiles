-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
vim.opt.wrap = true
vim.opt.scrolloff = 8
-- vim.g.codeium_os = "Darwin"
-- vim.g.codeium_arch = "arm64"
vim.g.codeium_enabled = false
vim.g.ai_cmp = true
vim.o.completeopt = "menuone,noselect,noinsert"
vim.opt.clipboard = "unnamedplus" -- Sync with system clipboard

-- OSC 52: enables clipboard over SSH (requires terminal support: iTerm2, Kitty, Alacritty, etc.)
-- only enable when SSH_TTY is set (i.e., we're in an SSH session)
if vim.env.SSH_TTY then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end
