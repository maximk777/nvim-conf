-- lua/plugins/python.lua — basedpyright tuning + neotest (pytest)
return {
  -- basedpyright fine-tuning
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                -- Catch real errors, stay quiet on third-party libs
                typeCheckingMode = "basic",
                -- Only analyze open files: less noise, faster on big repos/venvs
                diagnosticMode = "openFilesOnly",
                autoImportCompletions = true,
                inlayHints = {
                  variableTypes = true,
                  functionReturnTypes = true,
                  callArgumentNames = true,
                  genericTypes = false,
                },
              },
            },
          },
        },
      },
    },
  },

  -- neotest-python: use pytest with verbose output
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = {
      adapters = {
        ["neotest-python"] = {
          runner = "pytest",
          args = { "-v" },
        },
      },
    },
  },
}
