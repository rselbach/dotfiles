return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      -- keep the cursor line rendered instead of expanding links and markers under it
      anti_conceal = { enabled = false },
      win_options = { concealcursor = { rendered = "nc" } },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "--config", vim.fn.stdpath("config") .. "/markdownlint.yaml", "-" },
        },
      },
    },
  },
}
