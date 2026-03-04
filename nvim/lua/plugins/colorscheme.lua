local omarchy = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")

if vim.uv.fs_stat(omarchy) then
  return dofile(omarchy)
end

return {
  "maxmx03/solarized.nvim",
  lazy = false,
  priority = 1000,
  ---@type solarized.config
  opts = {},
  config = function(_, opts)
    vim.o.termguicolors = true
    vim.o.background = "light"
    require("solarized").setup(opts)
    vim.cmd.colorscheme("solarized")
  end,
}

-- fallback when omarchy is not available
--return {
--  { "ellisonleao/gruvbox.nvim" },
--  {
--    "LazyVim/LazyVim",
--    opts = {
--      colorscheme = "gruvbox",
--    },
--  },
--}
