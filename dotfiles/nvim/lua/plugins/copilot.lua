return {
  "zbirenbaum/copilot.lua",
  opts = {
    suggestion = {
      enabled = not vim.g.ai_cmp,
      auto_trigger = true,
      hide_during_completion = vim.g.ai_cmp,
      keymap = {
        accept = false, -- handled by nvim-cmp / blink.cmp
        next = "<M-]>",
        prev = "<M-[>",
      },
    },
    panel = { enabled = false },
    filetypes = {
      markdown = true,
      help = true,
    },
  },
  config = function()
        vim.g.copilot_no_tab_map = true
        vim.api.nvim_set_keymap("i", "<C-j>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
        vim.api.nvim_set_keymap("i", "<Tab>", 'copilot#Accept("<Tab>")', { silent = true, expr = true })
        vim.api.nvim_set_keymap("i", "<C-e>", 'copilot#Dismiss()', { silent = true, expr = true })
    end,
}
