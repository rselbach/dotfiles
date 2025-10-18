-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here



local map = vim.keymap.set
-- start visual selection with shift+arrows (normal mode)
map("n", "<S-Left>", "v<Left>")
map("n", "<S-Right>", "v<Right>")
map("n", "<S-Up>", "v<Up>")
map("n", "<S-Down>", "v<Down>")
-- start visual selection with shift+arrows (insert mode)
map("i", "<S-Left>", "<Esc>v<Left>")
map("i", "<S-Right>", "<Esc>v<Right>")
map("i", "<S-Up>", "<Esc>v<Up>")
map("i", "<S-Down>", "<Esc>v<Down>")
-- extend selection when already in visual mode
map("v", "<S-Left>", "<Left>")
map("v", "<S-Right>", "<Right>")
map("v", "<S-Up>", "<Up>")
map("v", "<S-Down>", "<Down>")
