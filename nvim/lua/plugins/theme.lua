local omarchy_theme = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
if vim.fn.filereadable(omarchy_theme) == 1 then
  return dofile(omarchy_theme)
end

return {
  {
    "loctvl842/monokai-pro.nvim",
    opts = {
      override = function(scheme)
        return {
          Cursor = { fg = scheme.editor.background, bg = scheme.editor.foreground },
        }
      end,
    },
    config = function(_, opts)
      local monokai = require("monokai-pro")
      monokai.setup(opts)

      -- the colorscheme entry point resets the filter to pro on every reload
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("monokai_background", { clear = true }),
        pattern = "monokai-pro",
        callback = function()
          local filter = vim.o.background == "light" and "light" or "pro"
          if monokai.get_config().filter ~= filter then
            monokai.set_filter(filter)
          end
        end,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "monokai-pro",
    },
  },
}
