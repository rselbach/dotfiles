return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "retrobox",
    },
    init = function()
      vim.o.background = "light"
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "retrobox",
        callback = function()
          vim.api.nvim_set_hl(0, "Normal", { fg = "#282828", bg = "#f9f5d7" })
          vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#282828", bg = "#f9f5d7" })
          vim.api.nvim_set_hl(0, "SignColumn", { fg = "#3c3836", bg = "#f9f5d7" })
          vim.api.nvim_set_hl(0, "FoldColumn", { fg = "#928374", bg = "#f9f5d7" })
          vim.api.nvim_set_hl(0, "LineNr", { fg = "#a89984", bg = "NONE" })
          vim.api.nvim_set_hl(0, "CursorLine", { bg = "#ebdbb2" })
          vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#d5c4a1" })
        end,
      })
    end,
  },
}
