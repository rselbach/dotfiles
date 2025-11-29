
return {
    "saghen/blink.cmp",
    version = "1.*",
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
            ["<Tab>"] = { "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
            ["<Up>"] = { "select_prev", "fallback" },
            ["<CR>"] = { "accept", "fallback" },
        }
        return opts
    end,
}
