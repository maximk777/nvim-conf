-- lua/plugins/snacks.lua — explorer config
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
            diagnostics = false,
          },
        },
      },
    },
  },
}
