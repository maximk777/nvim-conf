-- lua/plugins/dap.lua — F-key debug keymaps (supplements LazyVim dap.core <leader>d* keymaps)
return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: Continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
    },
  },
}
