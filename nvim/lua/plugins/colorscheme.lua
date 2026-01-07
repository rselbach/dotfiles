return {
  {
    "zenbones-theme/zenbones.nvim",
    dependencies = "rktjmp/lush.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      vim.opt.background = "light"
      vim.cmd.colorscheme("zenbones")
    end,
  }
}
