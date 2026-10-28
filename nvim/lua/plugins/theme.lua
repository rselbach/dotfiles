local omarchy_theme = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
if vim.fn.filereadable(omarchy_theme) == 1 then
  return dofile(omarchy_theme)
end

return {
  {
    "loctvl842/monokai-pro.nvim",
    opts = {},
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "monokai-pro",
    },
  },
}
