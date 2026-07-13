-- lua/plugins/snacks.lua — explorer config
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        actions = {
          -- Скопировать путь относительно корня проекта (cwd)
          copy_relative_path = function(picker, item)
            if not item then
              return
            end
            local path = vim.fn.fnamemodify(item.file, ":.")
            vim.fn.setreg("+", path)
            Snacks.notify.info("Yanked relative path:\n" .. path)
          end,
          -- Скопировать абсолютный путь
          copy_absolute_path = function(picker, item)
            if not item then
              return
            end
            vim.fn.setreg("+", item.file)
            Snacks.notify.info("Yanked absolute path:\n" .. item.file)
          end,
        },
        sources = {
          explorer = {
            hidden = true,
            diagnostics = false,
            win = {
              list = {
                keys = {
                  -- Y — относительный путь (от корня проекта)
                  ["Y"] = "copy_relative_path",
                  -- gy — абсолютный путь
                  ["gy"] = "copy_absolute_path",
                  -- y остаётся дефолтным (explorer_yank → абсолютный путь)
                },
              },
            },
          },
        },
      },
    },
  },
}
