return {
  -- Disable LSP inlay hints by default (LazyVim enables them unless overridden)
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
    },
  },
}
