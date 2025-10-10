-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.api.nvim_set_keymap("i", "jj", "<Esc>", { noremap = false })
vim.api.nvim_set_keymap("i", "jk", "<Esc>", { noremap = false })

vim.keymap.set('n', '<C-_>', '<C-o>', { desc = 'Jump back (older position)' })
vim.keymap.set('n', '<C-->', '<C-o>', { desc = 'Jump back (older position duplicate)' })
vim.keymap.set('n', '<C-=>', '<C-i>', { desc = 'Jump forward (newer position)' })
