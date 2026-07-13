-- lua/plugins/lsp-signature.lua — as-you-type inline signature hints.
-- Shows the current parameter as inline virtual text while filling call
-- arguments (the VS Code / GoLand "advancing parameter hint" equivalent),
-- complementing gopls usePlaceholders tab-through placeholders.
return {
  "ray-x/lsp_signature.nvim",
  event = "LspAttach",
  opts = {
    hint_enable = true, -- show the current parameter as virtual text
    hint_prefix = "» ",
    hint_inline = function()
      return true -- render at cursor (inline) rather than end-of-line
    end,
    floating_window = false, -- rely on inline virtual text, no popup clutter
    hi_parameter = "LspSignatureActiveParameter",
  },
  config = function(_, opts)
    require("lsp_signature").setup(opts)
  end,
}
