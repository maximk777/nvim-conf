-- lua/plugins/go.lua — gopls tuning + go.nvim refactoring
return {
  -- gopls fine-tuning
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              analyses = {
                fieldalignment = true,
                shadow = true,
                unusedvariable = true,
              },
              symbolMatcher = "FastFuzzy",
              diagnosticsDelay = "500ms",
            },
          },
        },
      },
    },
  },

  -- Filter out MismatchedPkgName and ST1000 diagnostics
  {
    "neovim/nvim-lspconfig",
    opts = function()
      local original_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
      vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
        if result and result.diagnostics then
          result.diagnostics = vim.tbl_filter(function(d)
            if d.message and d.message:match("MismatchedPkgName") then return false end
            if d.code and tostring(d.code) == "ST1000" then return false end
            return true
          end, result.diagnostics)
        end
        if original_handler then
          original_handler(err, result, ctx, config)
        end
      end
    end,
  },

  -- neotest-golang config
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = {
      adapters = {
        ["neotest-golang"] = {
          go_test_args = { "-v", "-race", "-count=1", "-timeout=60s" },
        },
      },
    },
  },

  -- go.nvim — refactoring and code generation (LSP/formatting disabled)
  {
    "ray-x/go.nvim",
    dependencies = {
      "ray-x/guihua.lua",
    },
    ft = { "go", "gomod", "gowork", "gotmpl" },
    build = ':lua require("go.install").update_all_sync()',
    opts = {
      lsp_cfg = false,
      lsp_gfumpt = false,
      lsp_keymaps = false,
      lsp_codelens = false,
      dap_debug = false,
      run_in_floaterm = true,
      floaterm = { position = "center", width = 0.8, height = 0.8 },
    },
    keys = {
      { "<leader>ri", "<cmd>GoImpl<cr>", desc = "Implement Interface", ft = "go" },
      { "<leader>rt", "<cmd>GoAddTag<cr>", desc = "Add Struct Tags", ft = "go" },
      { "<leader>rT", "<cmd>GoRmTag<cr>", desc = "Remove Struct Tags", ft = "go" },
      { "<leader>rf", "<cmd>GoFillStruct<cr>", desc = "Fill Struct", ft = "go" },
      { "<leader>rg", "<cmd>GoTestFunc<cr>", desc = "Generate Test for Func", ft = "go" },
      { "<leader>rG", "<cmd>GoTestFile<cr>", desc = "Generate Tests for File", ft = "go" },
    },
  },

  -- refactoring.nvim keymaps (plugin already installed via LazyVim extra)
  {
    "ThePrimeagen/refactoring.nvim",
    keys = {
      { "<leader>re", function() require("refactoring").refactor("Extract Function") end, mode = "v", desc = "Extract Function" },
      { "<leader>rv", function() require("refactoring").refactor("Extract Variable") end, mode = "v", desc = "Extract Variable" },
      { "<leader>rI", function() require("refactoring").refactor("Inline Variable") end, mode = { "n", "v" }, desc = "Inline Variable" },
    },
  },

  -- which-key group registration
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>r", group = "refactor" },
      },
    },
  },
}
