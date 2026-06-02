-- lua/plugins/snippets.lua — load custom VS Code snippets
return {
  {
    "garymjr/nvim-snippets",
    opts = {
      search_paths = { vim.fn.stdpath("config") .. "/snippets" },
    },
  },
}
