local omarchy = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")

if vim.uv.fs_stat(omarchy) then
  return dofile(omarchy)
end

-- fallback when omarchy is not available
return {
  { "ellisonleao/gruvbox.nvim" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
