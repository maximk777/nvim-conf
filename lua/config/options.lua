-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.scrolloff = 8

-- Disable all snacks.nvim animations
vim.g.snacks_animate = false

-- Disable autoformat on save (use <leader>cf for manual formatting)
vim.g.autoformat = false

-- Go uses tabs (gofumpt convention)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gowork", "gotmpl" },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.expandtab = false
  end,
})

-- Rust uses 4-space indentation (rustfmt convention)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
})
