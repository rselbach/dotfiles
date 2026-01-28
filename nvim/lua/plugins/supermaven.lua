return {
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    config = function()
      require("supermaven-nvim").setup({})
      require("supermaven-nvim.api").stop()
      vim.keymap.set("n", "<leader>aS", function()
        local api = require("supermaven-nvim.api")
        api.toggle()
        vim.notify(api.is_running() and "Supermaven enabled" or "Supermaven disabled", vim.log.levels.INFO)
      end, { desc = "Toggle Supermaven" })
    end,
  },
}
