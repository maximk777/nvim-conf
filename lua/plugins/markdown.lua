-- lua/plugins/markdown.lua — disable markdownlint + customize preview
return {
  -- Отключить markdownlint
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },

  -- Расширить markdown-preview из LazyVim extra (light theme + <leader>mp)
  -- ВАЖНО: не переопределять config — LazyVim делает там `do FileType`,
  -- который регистрирует команду MarkdownPreview. Тему ставим в init (до загрузки).
  {
    "iamcco/markdown-preview.nvim",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview", ft = "markdown" },
    },
    init = function()
      vim.g.mkdp_theme = "light"
    end,
  },
}
