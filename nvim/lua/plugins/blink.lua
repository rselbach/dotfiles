
return {
    "saghen/blink.cmp",
    opts = function(_, opts)
        opts.completion = {
            list = {
                selection = {
                    preselect = true,
                    auto_insert = false,
                }
            }
        }
        opts.keymap = {
            preset = "default",
            ["<Tab>"] = { "accept", "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
            ["<Up>"] = { "select_prev", "fallback" },
            ["<CR>"] = { "fallback" },
        }
        return opts
    end,
}
