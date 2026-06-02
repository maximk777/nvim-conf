-- lua/plugins/openapi.lua — Swagger UI + gRPC UI preview tools
-- <leader>oa — OpenAPI spec in Swagger UI with reverse proxy
-- <leader>og — gRPC UI with server reflection

local swagger_job = nil
local grpcui_job = nil

local function stop_swagger()
  if swagger_job then
    vim.fn.jobstop(swagger_job)
    swagger_job = nil
  end
end

local function stop_grpcui()
  if grpcui_job then
    vim.fn.jobstop(grpcui_job)
    grpcui_job = nil
  end
end

local function start_swagger()
  local spec = vim.fn.expand("%:p")
  vim.ui.input({ prompt = "API port (default 8080): " }, function(input)
    if input == nil then return end
    local port = input ~= "" and input or "8080"

    stop_swagger()

    local script = vim.fn.stdpath("config") .. "/scripts/swagger-proxy/main.go"
    swagger_job = vim.fn.jobstart({
      "go", "run", script, "--spec", spec, "--port", port,
    }, {
      detach = true,
      on_stderr = function(_, data)
        if data and data[1] ~= "" then
          vim.schedule(function()
            vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
          end)
        end
      end,
    })

    vim.defer_fn(function()
      vim.ui.open("http://localhost:9090")
    end, 1500)

    vim.notify("Swagger UI starting on :9090 → API on :" .. port)
  end)
end

local function start_grpcui()
  vim.ui.input({ prompt = "gRPC server port (default 50051): " }, function(input)
    if input == nil then return end
    local port = input ~= "" and input or "50051"

    stop_grpcui()

    grpcui_job = vim.fn.jobstart({
      "grpcui", "-plaintext", "-open-browser", "localhost:" .. port,
    }, {
      detach = true,
      on_stdout = function(_, data)
        if data then
          for _, line in ipairs(data) do
            local url = line:match("http[s]?://[%w%.%-:/_]+")
            if url then
              vim.schedule(function()
                vim.notify("gRPC UI: " .. url)
              end)
            end
          end
        end
      end,
      on_stderr = function(_, data)
        if data and data[1] ~= "" then
          vim.schedule(function()
            vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
          end)
        end
      end,
    })

    vim.notify("gRPC UI starting → localhost:" .. port)
  end)
end

-- Stop servers when Neovim exits
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    stop_swagger()
    stop_grpcui()
  end,
})

return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>o", group = "open" },
      },
    },
  },

  {
    dir = vim.fn.stdpath("config") .. "/scripts/swagger-proxy",
    name = "swagger-proxy",
    lazy = true,
    keys = {
      {
        "<leader>oa",
        start_swagger,
        desc = "OpenAPI Swagger UI",
        ft = { "yaml", "json" },
      },
      {
        "<leader>og",
        start_grpcui,
        desc = "gRPC UI",
      },
    },
  },
}
