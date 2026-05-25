-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

if vim.fn.has("macunix") == 1 then
  map("n", "<D-c>", '"+yy', { desc = "Copy line to system clipboard" })
  map("x", "<D-c>", '"+y', { desc = "Copy selection to system clipboard" })
end

-- jump backwards in jump list (alternative to <C-o>)
map("n", "<C-->", "<C-o>", { desc = "Jump backwards in jump list" })
-- gui-style buffer navigation
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<C-w>", "<cmd>bd<cr>", { desc = "Close buffer" })
-- command palette
map("n", "<C-S-p>", "<cmd>lua Snacks.picker.commands()<cr>", { desc = "Command palette" })
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
