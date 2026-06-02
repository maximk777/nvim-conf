-- lua/plugins/rust.lua — rust-analyzer tuning + crates.nvim
return {
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            check = {
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            inlayHints = {
              chainingHints = { enable = true },
              closingBraceHints = { enable = true, minLines = 25 },
              closureReturnTypeHints = { enable = "with_block" },
              parameterHints = { enable = true },
              typeHints = { enable = true },
              maxLength = 25,
              renderColons = true,
            },
            completion = {
              fullFunctionSignatures = { enable = true },
              postfix = { enable = true },
            },
            imports = {
              granularity = { group = "module" },
              prefix = "self",
            },
            typing = {
              autoClosingAngleBrackets = { enable = true },
            },
          },
        },
      },
    },
  },

  {
    "Saecki/crates.nvim",
    opts = {
      popup = {
        autofocus = true,
        border = "rounded",
      },
    },
    keys = {
      { "<leader>cpu", function() require("crates").upgrade_all_crates() end, desc = "Upgrade All Crates" },
      { "<leader>cpi", function() require("crates").show_crate_popup() end, desc = "Crate Info" },
      { "<leader>cpf", function() require("crates").show_features_popup() end, desc = "Crate Features" },
      { "<leader>cpd", function() require("crates").show_dependencies_popup() end, desc = "Crate Dependencies" },
    },
  },

  -- which-key group registration
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>cp", group = "crates/packages" },
      },
    },
  },
}
