return {
  "mfussenegger/nvim-lint",
  optional = true,
  opts = {
    linters = {
      ["markdownlint-cli2"] = {
        args = { "--config", os.getenv("HOME") .. "/.config/nvim/.markdownlint.yaml", "--" },
      },
    },
  },
}
