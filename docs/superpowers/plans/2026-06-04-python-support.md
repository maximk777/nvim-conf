# Python Language Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add engineering-grade Python support (basedpyright + ruff + debugpy + pytest + venv) to this LazyVim config, matching the quality of the existing Go/Rust setup.

**Architecture:** Enable LazyVim's `lang.python` extra (provides basedpyright, ruff, treesitter, neotest-python, nvim-dap-python, venv-selector out of the box), then add a focused `lua/plugins/python.lua` that tunes only what differs from defaults. Switch the LSP to basedpyright via the documented `vim.g.lazyvim_python_lsp` global.

**Tech Stack:** LazyVim, lazy.nvim, basedpyright, ruff, neotest-python (pytest), nvim-dap-python (debugpy), venv-selector.nvim, Mason.

**Note on testing:** This is a Neovim Lua config, not a code base with a unit-test runner. "Verify" steps mean launching Neovim (headless where possible, interactive otherwise) and inspecting `:Lazy`, `:LspInfo`, `:checkhealth`. There is no TDD red/green cycle here.

**Note on commits:** The user prefers no automatic git commits. Commit steps are listed for completeness but the user runs them manually — do NOT auto-commit.

---

## What comes free with the extra (do NOT re-implement)

These are LazyVim defaults from `lang.python`; the plan does NOT duplicate them:

- ruff as formatter + organize-imports (via conform.nvim / nvim-lint)
- python treesitter parser
- DAP keymaps `<leader>dPt` (debug test method) and `<leader>dPc` (debug test class), `ft = "python"`
- venv-selector keymap `<leader>cv` → `:VenvSelect` (regexp branch auto-detects `.venv`, poetry, uv, conda)
- Mason auto-install of basedpyright, ruff, debugpy, debugpy-adapter

The custom `python.lua` only tunes: LSP type-checking mode, diagnostic scope, inlay hints, and the neotest runner.

---

## File Structure

- `lazyvim.json` — add the python extra entry (1 line)
- `lua/config/options.lua` — set `vim.g.lazyvim_python_lsp = "basedpyright"` (must be set before the extra loads; options.lua is the documented place)
- `lua/plugins/python.lua` — new, basedpyright + neotest tuning (mirror of `go.lua`)

---

## Task 1: Enable the Python extra

**Files:**
- Modify: `lazyvim.json` (the `extras` array)

- [ ] **Step 1: Add the extra entry**

Edit `lazyvim.json`. Insert `"lazyvim.plugins.extras.lang.python"` into the `extras` array, alphabetically between the `markdown` and `rust` entries. After the edit that region reads:

```json
    "lazyvim.plugins.extras.lang.markdown",
    "lazyvim.plugins.extras.lang.python",
    "lazyvim.plugins.extras.lang.rust",
```

- [ ] **Step 2: Sync plugins (headless)**

Run:
```bash
nvim --headless "+Lazy! sync" +qa
```
Expected: exits without errors; lazy installs venv-selector, neotest-python, nvim-dap-python if not present.

- [ ] **Step 3: Verify Mason tools install**

Run:
```bash
nvim --headless "+MasonInstall basedpyright ruff debugpy" +qa
```
Expected: each tool reports installed or "already installed". No error lines.

- [ ] **Step 4 (manual, user runs): Commit**

```bash
git add lazyvim.json lazy-lock.json
git commit -m "feat(python): enable LazyVim python extra"
```

---

## Task 2: Switch LSP to basedpyright

**Files:**
- Modify: `lua/config/options.lua`

- [ ] **Step 1: Read the file to find the insertion point**

Open `lua/config/options.lua`. The file holds `vim.g.*` and `vim.opt.*` assignments. Add the new global near the other `vim.g.*` lines (top of file).

- [ ] **Step 2: Add the LSP global**

Append this line in the `vim.g` section:

```lua
-- Use basedpyright (strict, fast pyright fork) as the Python LSP
vim.g.lazyvim_python_lsp = "basedpyright"
```

- [ ] **Step 3: Verify basedpyright attaches**

Create a throwaway file and check the active LSP client headlessly:
```bash
printf 'import os\n\n\ndef f(x):\n    return os.path.join(x)\n' > /tmp/lsp_check.py
nvim --headless /tmp/lsp_check.py "+lua vim.defer_fn(function() local c = vim.lsp.get_clients({bufnr=0}); print('clients: '..vim.inspect(vim.tbl_map(function(x) return x.name end, c))) vim.cmd('qa') end, 4000)"
```
Expected: output contains `basedpyright` (and `ruff`). If empty, basedpyright is still installing — re-run after `:Mason` finishes.

- [ ] **Step 4 (manual, user runs): Commit**

```bash
git add lua/config/options.lua
git commit -m "feat(python): use basedpyright as the Python LSP"
```

---

## Task 3: basedpyright + neotest tuning

**Files:**
- Create: `lua/plugins/python.lua`

- [ ] **Step 1: Create the tuning file**

Create `lua/plugins/python.lua` with this exact content:

```lua
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
```

- [ ] **Step 2: Reload and check config loads cleanly (headless)**

Run:
```bash
nvim --headless "+Lazy! load nvim-lspconfig" "+lua print('ok')" +qa
```
Expected: prints `ok`, no Lua errors about `python.lua`.

- [ ] **Step 3: Verify basedpyright settings applied**

Run:
```bash
printf 'def f(x):\n    return x + 1\n' > /tmp/lsp_check.py
nvim --headless /tmp/lsp_check.py "+lua vim.defer_fn(function() for _,c in ipairs(vim.lsp.get_clients({bufnr=0})) do if c.name=='basedpyright' then print('mode='..vim.inspect((c.config.settings.basedpyright or {}).analysis and c.config.settings.basedpyright.analysis.typeCheckingMode)) end end vim.cmd('qa') end, 4000)"
```
Expected: output contains `mode="basic"`.

- [ ] **Step 4: Interactive smoke test (user)**

Open a real project file: `nvim some_project/app.py`. Confirm:
- `:LspInfo` shows `basedpyright` + `ruff` attached
- inlay hints appear for inferred variable/return types (toggle with `<leader>uh` if needed)
- `<leader>cv` opens the venv picker and lists environments
- `<leader>dPt` on a `test_*` function starts a debug session (after `pip install debugpy` in the venv)
- `:checkhealth neotest` and `:checkhealth dap` report pytest + debugpy detected

- [ ] **Step 5 (manual, user runs): Commit**

```bash
git add lua/plugins/python.lua
git commit -m "feat(python): tune basedpyright (basic) and neotest pytest runner"
```

---

## Self-Review (completed by author)

- **Spec coverage:** extra enablement (Task 1) ✓; basedpyright basic + diagnosticMode + inlay hints (Task 3) ✓; ruff = default, not duplicated ✓; mixed venv via venv-selector default = free, noted ✓; DAP keymaps = free, noted ✓; neotest pytest (Task 3) ✓. Spec's "no options.lua changes" was relaxed: switching to basedpyright requires `vim.g.lazyvim_python_lsp`, the documented mechanism — one line, justified.
- **Placeholder scan:** no TBD/TODO; all code blocks complete.
- **Consistency:** `basedpyright` server key matches the global LSP choice; neotest adapter key `neotest-python` matches the extra's adapter; keymaps referenced (`<leader>cv`, `<leader>dPt`) are the extra's real defaults.
