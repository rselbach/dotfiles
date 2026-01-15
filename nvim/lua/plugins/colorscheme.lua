return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      contrast = "soft",
      italic = {
        strings = false,
        comments = true,
        operators = false,
      },
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = true,
        mini = { enabled = true },
        telescope = { enabled = true },
        which_key = true,
      },
    },
    config = function(_, opts)
      require("gruvbox").setup(opts)
      vim.o.background = "light"
      vim.cmd.colorscheme("gruvbox")
    end,
  },
}
