local omarchy = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")

if vim.uv.fs_stat(omarchy) then
  return dofile(omarchy)
end

return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {},
}
