return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.dashboard = { enabled = false }
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.files = vim.tbl_deep_extend("force", opts.picker.sources.files or {}, { hidden = true })
      return opts
    end,
  },
}
