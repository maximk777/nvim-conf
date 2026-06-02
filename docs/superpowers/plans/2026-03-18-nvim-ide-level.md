# Neovim IDE-Level for Go & Rust — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade LazyVim config to IDE-level Go & Rust experience — clean diagnostics, snippets, refactoring, debugger, tests, git.

**Architecture:** Build on existing LazyVim extras (lang.go, lang.rust, dap.core, test.core) which already provide DAP, neotest, and LSP keymaps. Add go.nvim for Go refactoring (with LSP disabled to avoid conflicts), custom VS Code snippets, diffview.nvim for git, and tune diagnostic display.

**Tech Stack:** LazyVim v8, Neovim 0.11+, nvim-snippets (VS Code JSON format), ray-x/go.nvim, sindrets/diffview.nvim

**Spec:** `docs/superpowers/specs/2026-03-18-nvim-ide-level-design.md`

---

## File Structure

| File | Responsibility |
|------|---------------|
| `lua/plugins/diagnostics.lua` | New — disable virtual_text via LazyVim diagnostics opts |
| `lua/plugins/snacks.lua` | Update — disable diagnostics in explorer |
| `snippets/go.json` | New — Go snippets in VS Code JSON format |
| `snippets/rust.json` | New — Rust snippets in VS Code JSON format |
| `lua/plugins/snippets.lua` | New — load custom snippets dir |
| `lua/plugins/go.lua` | Update — add go.nvim (LSP/fmt disabled), Go refactoring keymaps |
| `lua/plugins/rust.lua` | Update — move crates keymaps from `<leader>rc` to `<leader>cp` |
| `lua/plugins/dap.lua` | New — F-key keymaps |
| `lua/plugins/git.lua` | New — diffview.nvim config + keymaps |

**Already provided by LazyVim extras (verified):**
- Rust test adapter — `lang.rust` extra configures `rustaceanvim.neotest`
- nvim-dap-go — `lang.go` extra includes it with delve
- codelldb — `lang.rust` extra installs via Mason and wires DAP
- DAP keymaps (`<leader>d*`) — `dap.core` extra provides full set
- Test keymaps (`<leader>t*`) — `test.core` extra provides full set
- Navigation keymaps (`gd`, `gr`, `<leader>ss`, `<leader>sS`) — LazyVim provides all

---

### Task 1: Diagnostics — Disable virtual text

**Files:**
- Create: `lua/plugins/diagnostics.lua`

- [ ] **Step 1: Create diagnostics plugin file**

Use LazyVim's `opts.diagnostics` key which it passes to `vim.diagnostic.config()` — this ensures our config is not overwritten by LazyVim's own setup.

```lua
-- lua/plugins/diagnostics.lua — clean diagnostic display
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
        underline = true,
        signs = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = true,
        },
      },
    },
  },
}
```

- [ ] **Step 2: Verify in Neovim**

Open a Go file with diagnostics. Confirm:
- No virtual text on the right side of lines
- Underline still appears on problematic code
- Gutter signs (icons) still appear
- `<leader>xx` opens Trouble with all diagnostics
- `gl` on a diagnostic line shows the float

---

### Task 2: Diagnostics — Disable explorer warning badges

**Files:**
- Modify: `lua/plugins/snacks.lua`

- [ ] **Step 1: Update snacks explorer config**

Replace the entire file content:

```lua
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
```

- [ ] **Step 2: Verify in Neovim**

Open snacks explorer (`<leader>e`). Confirm:
- No yellow warning triangles on files
- Dotfiles still visible
- File navigation works normally

---

### Task 3: Snippets — Go snippets

**Files:**
- Create: `snippets/go.json`

- [ ] **Step 1: Create snippets directory and Go snippets file**

```json
{
  "if err != nil return": {
    "prefix": "iferr",
    "body": [
      "if err != nil {",
      "\treturn ${1:nil, err}",
      "}"
    ],
    "description": "if err != nil { return }"
  },
  "if err != nil return fmt.Errorf": {
    "prefix": "iferrf",
    "body": [
      "if err != nil {",
      "\treturn ${1:nil, }fmt.Errorf(\"${2:failed to %s}: %w\", ${3:err})",
      "}"
    ],
    "description": "if err != nil { return fmt.Errorf }"
  },
  "if err := ...; err != nil": {
    "prefix": "ife",
    "body": [
      "if err := ${1:expr}; err != nil {",
      "\treturn ${2:nil, err}",
      "}"
    ],
    "description": "if err := ...; err != nil {}"
  },
  "test function": {
    "prefix": "tst",
    "body": [
      "func Test${1:Name}(t *testing.T) {",
      "\t${0}",
      "}"
    ],
    "description": "Test function"
  },
  "table-driven test": {
    "prefix": "tbt",
    "body": [
      "func Test${1:Name}(t *testing.T) {",
      "\ttests := []struct {",
      "\t\tname string",
      "\t\t${2:// fields}",
      "\t}{",
      "\t\t{",
      "\t\t\tname: \"${3:test case}\",",
      "\t\t},",
      "\t}",
      "",
      "\tfor _, tt := range tests {",
      "\t\tt.Run(tt.name, func(t *testing.T) {",
      "\t\t\t${0}",
      "\t\t})",
      "\t}",
      "}"
    ],
    "description": "Table-driven test"
  },
  "benchmark function": {
    "prefix": "bench",
    "body": [
      "func Benchmark${1:Name}(b *testing.B) {",
      "\tfor i := 0; i < b.N; i++ {",
      "\t\t${0}",
      "\t}",
      "}"
    ],
    "description": "Benchmark function"
  },
  "http handler func": {
    "prefix": "hf",
    "body": [
      "func ${1:handler}(w http.ResponseWriter, r *http.Request) {",
      "\t${0}",
      "}"
    ],
    "description": "HTTP handler function"
  },
  "method with receiver": {
    "prefix": "meth",
    "body": [
      "func (${1:r} *${2:Type}) ${3:Method}(${4}) ${5:error} {",
      "\t${0}",
      "}"
    ],
    "description": "Method with receiver"
  },
  "context parameter": {
    "prefix": "ctx",
    "body": "ctx context.Context",
    "description": "context.Context parameter"
  }
}
```

---

### Task 4: Snippets — Rust snippets

**Files:**
- Create: `snippets/rust.json`

- [ ] **Step 1: Create Rust snippets file**

```json
{
  "test function": {
    "prefix": "test",
    "body": [
      "#[test]",
      "fn ${1:test_name}() {",
      "\t${0}",
      "}"
    ],
    "description": "Test function"
  },
  "test module": {
    "prefix": "tmod",
    "body": [
      "#[cfg(test)]",
      "mod tests {",
      "\tuse super::*;",
      "",
      "\t#[test]",
      "\tfn ${1:test_name}() {",
      "\t\t${0}",
      "\t}",
      "}"
    ],
    "description": "Test module"
  },
  "impl block": {
    "prefix": "impl",
    "body": [
      "impl ${1:Type} {",
      "\t${0}",
      "}"
    ],
    "description": "impl block"
  },
  "impl trait": {
    "prefix": "implt",
    "body": [
      "impl ${1:Trait} for ${2:Type} {",
      "\t${0}",
      "}"
    ],
    "description": "impl Trait for Type"
  },
  "derive": {
    "prefix": "der",
    "body": "#[derive(${1:Debug, Clone})]",
    "description": "derive macro"
  },
  "match expression": {
    "prefix": "match",
    "body": [
      "match ${1:expr} {",
      "\t${2:pattern} => ${3:value},",
      "\t${0}",
      "}"
    ],
    "description": "match expression"
  },
  "Result return": {
    "prefix": "res",
    "body": "Result<${1:T}, ${2:Error}>",
    "description": "Result<T, E>"
  },
  "Option match": {
    "prefix": "opt",
    "body": [
      "match ${1:expr} {",
      "\tSome(${2:val}) => ${3:val},",
      "\tNone => ${0},",
      "}"
    ],
    "description": "Option match"
  },
  "Vec initialization": {
    "prefix": "vec",
    "body": "let ${1:name}: Vec<${2:T}> = Vec::new();",
    "description": "Vec::new()"
  },
  "Vec with values": {
    "prefix": "vecm",
    "body": "let ${1:name} = vec![${0}];",
    "description": "vec![] macro"
  }
}
```

---

### Task 5: Snippets — Load custom snippets

**Files:**
- Create: `lua/plugins/snippets.lua`

- [ ] **Step 1: Create snippets plugin config**

```lua
-- lua/plugins/snippets.lua — load custom VS Code snippets
return {
  {
    "garymjr/nvim-snippets",
    opts = {
      search_paths = { vim.fn.stdpath("config") .. "/snippets" },
    },
  },
}
```

- [ ] **Step 2: Verify in Neovim**

Open a `.go` file, type `iferr` and press `<Tab>` or select from completion menu. Confirm the snippet expands. Repeat with `tbt` for table test. Open a `.rs` file, type `test` and confirm it expands.

If `search_paths` does not work (API may differ by version), check `:help nvim-snippets` and adapt the option name.

---

### Task 6: Refactoring — Add go.nvim

**Files:**
- Modify: `lua/plugins/go.lua`

- [ ] **Step 1: Install CLI dependencies**

Run:
```bash
go install github.com/josharian/impl@latest
go install github.com/fatih/gomodifytags@latest
go install github.com/cweill/gotests/gotests@latest
go install github.com/davidrjenni/reftools/cmd/fillstruct@latest
```

Verify all installed:
```bash
which impl gomodifytags gotests fillstruct
```

- [ ] **Step 2: Update go.lua — add go.nvim and refactoring keymaps**

Replace the entire file:

```lua
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
```

**Note:** Inline Variable is mapped to `<leader>rI` (capital I) to avoid conflict with `<leader>ri` (GoImpl) in Go files.

- [ ] **Step 3: Verify in Neovim**

Open a Go file with a struct. Test:
- `<leader>rt` on a struct — adds json tags
- `<leader>rf` on a struct literal — fills all fields
- `<leader>ri` — prompts for interface to implement
- Visual select code, `<leader>re` — extracts function
- `<leader>rI` on a variable — inlines it

---

### Task 7: Refactoring — Move crates.nvim keymaps

**Files:**
- Modify: `lua/plugins/rust.lua`

- [ ] **Step 1: Update rust.lua — move crates keymaps to `<leader>cp`**

Replace the entire file:

```lua
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
```

- [ ] **Step 2: Verify in Neovim**

Open a `Cargo.toml` file. Test:
- `<leader>cpu` — upgrades all crates
- `<leader>cpi` — shows crate info popup
- which-key shows "crates/packages" group under `<leader>cp`

---

### Task 8: Debugger — F-key keymaps + verify setup

**Files:**
- Create: `lua/plugins/dap.lua`

- [ ] **Step 1: Create DAP config with F-key keymaps**

LazyVim `dap.core` already provides `<leader>d*` keymaps. LazyVim `lang.go` provides delve. LazyVim `lang.rust` provides codelldb. We only add F-key convenience keymaps.

```lua
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
```

**Note:** Step out is available via `<leader>do` (LazyVim default). F12/S-F11 omitted due to terminal compatibility issues.

- [ ] **Step 2: Verify codelldb is installed**

Open Neovim and run `:Mason`. Check that `codelldb` is in the installed list. If not, install it: `:MasonInstall codelldb`

- [ ] **Step 3: Verify Go debugging**

Open a Go file with a `main` function. Set a breakpoint with `<leader>db`. Press `<F5>` to start debugging. Confirm:
- DAP UI opens with variables/call stack panels
- Breakpoint is hit
- `<F10>` steps over, `<F11>` steps into, `<leader>do` steps out

- [ ] **Step 4: Verify Rust debugging**

Open a Rust file. Set a breakpoint with `<leader>db`. Press `<F5>` to start. Confirm debugger attaches via codelldb.

---

### Task 9: Git — Add diffview.nvim

**Files:**
- Create: `lua/plugins/git.lua`

- [ ] **Step 1: Create git plugin config**

```lua
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
```

- [ ] **Step 2: Verify in Neovim**

In a git repo with changes:
- `<leader>gV` — opens diffview with all changes
- `<leader>gh` — shows file history for current file
- `:DiffviewClose` to close

---

### Task 10: Verify tests and navigation (LazyVim extras)

**Files:** None — verification only

- [ ] **Step 1: Verify neotest works for Go**

Open a Go test file. Run `<leader>tr` (run nearest). Confirm test runs and output appears. Run `<leader>ts` to see test summary.

- [ ] **Step 2: Verify neotest works for Rust**

Open a Rust file with tests. Run `<leader>tr`. Confirm `rustaceanvim.neotest` adapter picks up tests and runs them.

- [ ] **Step 3: Verify debug test works**

In a Go test file, place cursor on a test function. Run `<leader>td` (debug nearest). Confirm DAP starts and hits breakpoints.

- [ ] **Step 4: Verify navigation keymaps**

In a Go or Rust file, test:
- `gd` — go to definition
- `gr` — references
- `gi` — implementations
- `<leader>ss` — document symbols (telescope)
- `<leader>sS` — workspace symbols (telescope)
- `]]` / `[[` — next/prev function (treesitter)

---

### Task 11: Final verification

- [ ] **Step 1: Restart Neovim and check for errors**

Run: `nvim --headless "+Lazy sync" +qa` to sync all plugins.
Open Neovim normally. Check `:messages` and `:checkhealth` for any errors.

- [ ] **Step 2: Verify all features work together**

Quick smoke test checklist:
1. Open a Go file — no virtual text diagnostics, underline works, `<leader>xx` shows trouble list
2. Explorer (`<leader>e`) — no yellow warning badges
3. Type `iferr` in Go file — snippet expands
4. Type `test` in Rust file — snippet expands
5. `<leader>rt` on Go struct — adds tags
6. `<leader>ri` in Go — prompts for interface implementation
7. `<leader>rI` — inlines variable
8. `<leader>cpu` in Cargo.toml — upgrades crates
9. `<F5>` starts debugger
10. `<leader>tr` runs nearest test
11. `<leader>gV` opens diffview
12. which-key shows correct group names for `<leader>r` and `<leader>cp`

- [ ] **Step 3: Verify diagnostic handler still works on Neovim 0.11+**

Open a Go file in a package without a package comment. Confirm ST1000 diagnostic is filtered out (should not appear in Trouble list or gutter). If filtering is broken, the `vim.lsp.handlers` override in go.lua needs migration to `vim.lsp.config` — create a follow-up task.
