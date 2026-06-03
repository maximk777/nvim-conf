# Python Language Support for Neovim

**Date:** 2026-06-04
**Approach:** LazyVim extra + custom tuning (Approach A)
**Base:** LazyVim with existing custom plugins (mirrors go.lua / rust.lua)
**Neovim version:** 0.11+

## Context

User has a LazyVim-based Neovim config with Go (gopls) and Rust (rustaceanvim) support
wired through `lazyvim.json` extras plus per-language tuning files in `lua/plugins/`.
There is currently no Python support. The user works on:

- Backend / web (FastAPI, Django)
- DevOps / infra (Ansible, boto3, CLI tools)
- Scripts / automation

No data science / Jupyter work — so no molten/jupytext/REPL tooling.

**Requirements:**
- LSP: basedpyright in `basic` type-checking mode + ruff for lint/format
- Environments: mixed (uv / poetry / plain venv) → universal auto-detecting venv selection
- Engineering-grade setup matching the quality of the existing go.lua / rust.lua

## Approach

Enable LazyVim's `lazyvim.plugins.extras.lang.python` (provides basedpyright, ruff,
treesitter, neotest-python, nvim-dap-python, venv-selector out of the box), then add
`lua/plugins/python.lua` for tuning — the exact pattern already used for Go and Rust.
This keeps custom code minimal and stays compatible with LazyVim updates.

## Implementation Order

1. Enable the extra in `lazyvim.json` (no dependencies)
2. Add `lua/plugins/python.lua` tuning (depends on the extra being active)

## 1. Enable the Python extra

### Solution

- Add `"lazyvim.plugins.extras.lang.python"` to the `extras` array in `lazyvim.json`,
  alphabetically between `markdown` and `rust`.
- This activates: basedpyright LSP, ruff (lint + format via conform/nvim-lint),
  python treesitter, neotest-python adapter, nvim-dap-python (debugpy), venv-selector.
- Mason installs basedpyright, ruff, and debugpy automatically — no manual tool config.

### Files Changed

- `lazyvim.json` (edit — add one extra entry)

## 2. python.lua tuning

### Solution

New file `lua/plugins/python.lua` (mirror of `go.lua`), containing:

- **basedpyright tuning** via `nvim-lspconfig` `opts.servers.basedpyright`:
  - `typeCheckingMode = "basic"` — catches real errors, quiet on third-party libs
  - `diagnosticMode = "openFilesOnly"` — don't scan the whole project/venv (less noise, faster)
  - `autoImportCompletions = true`
  - inlay hints: variable types + function return types enabled
- **ruff:** keep LazyVim defaults (ruff as formatter + organize imports). basedpyright
  provides hover/type diagnostics; ruff provides style. No extra config unless a
  duplicate-diagnostic conflict appears, in which case disable basedpyright's overlapping
  lint reporting.
- **venv-selector:** enable all backends (uv / poetry / venv / conda), keymap
  `<leader>cv` to pick interpreter for the current project.
- **DAP keymaps** (nvim-dap-python, `ft = "python"`):
  - `<leader>dPt` — debug nearest test method
  - `<leader>dPc` — debug current file / test class
- **neotest-python:** `pytest` runner, args `{ "-v" }`.
- **which-key:** register `<leader>cv` group label if needed.

### Files Changed

- `lua/plugins/python.lua` (new — auto-loaded by lazy.nvim)

## Out of Scope

- Jupyter / notebook support (molten, jupytext)
- REPL integration (iron.nvim)
- Changes to `init.lua`, `options.lua`, `keymaps.lua` — all changes are localized to the two files above

## Verification

- `:Lazy sync` installs the new plugins without errors
- Open a `.py` file → basedpyright attaches (`:LspInfo`), ruff available
- `:checkhealth` for dap-python / neotest shows debugpy + pytest detected
- venv-selector (`<leader>cv`) lists available environments
