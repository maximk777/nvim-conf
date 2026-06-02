-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Center screen after search
map("n", "n", "nzzzv", { desc = "Next Search Result (Centered)" })
map("n", "N", "Nzzzv", { desc = "Prev Search Result (Centered)" })

-- Center screen after half-page jumps
map("n", "<C-d>", "<C-d>zz", { desc = "Half Page Down (Centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half Page Up (Centered)" })
