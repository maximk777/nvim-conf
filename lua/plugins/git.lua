-- lua/plugins/git.lua — diffview.nvim for visual diffs and merge conflicts
return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      { "<leader>gv", function() vim.cmd("DiffviewOpen -- " .. vim.fn.expand("%")) end, desc = "Diff Current File" },
      { "<leader>gV", "<cmd>DiffviewOpen<cr>", desc = "Diff All Changes" },
      { "<leader>gh", function() vim.cmd("DiffviewFileHistory " .. vim.fn.expand("%")) end, desc = "File History" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Branch History" },
    },
    opts = {
      view = {
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
    },
  },
}
