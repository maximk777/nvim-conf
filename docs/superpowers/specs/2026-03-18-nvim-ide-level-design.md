# Neovim IDE-Level Configuration for Go & Rust

**Date:** 2026-03-18
**Approach:** Minimal plugins (Approach A)
**Base:** LazyVim with existing custom plugins
**Neovim version:** 0.11+

## Context

User has a LazyVim-based Neovim config with Go (gopls) and Rust (rustaceanvim) support. Wants to reach IDE-level experience (GoLand/RustRover quality) while keeping the config lean.

## Implementation Order

1. Diagnostics (no dependencies)
2. Snippets (no dependencies)
3. Refactoring — go.nvim + refactoring.nvim keymaps
4. Debugger — DAP for Go and Rust (depends on nothing but recommended after refactoring)
5. Tests — neotest-rust (depends on DAP for debug-test feature)
6. Navigation — verify existing, add missing
7. Git — diffview.nvim (independent)

## 1. Diagnostics

### Problem
- Virtual text inline diagnostics (staticcheck ST1000, ST1003 etc.) clutter the code
- Warning badges (yellow triangles) on every file in snacks explorer make the file tree noisy

### Solution
- `vim.diagnostic.config()`: disable `virtual_text`, keep `underline` and `signs` (gutter icons)
- Diagnostics accessible via:
  - Underline on problematic code
  - Gutter signs (left column)
  - `<leader>xx` — Trouble list (already works)
  - Hover — `vim.diagnostic.open_float()`
- Snacks explorer (picker-based): disable diagnostic decorations via `explorer.diagnostics` or decorator config
- Keep existing ST1000 filter in go.lua
- **Note:** existing `vim.lsp.handlers["textDocument/publishDiagnostics"]` override in go.lua may need updating for Neovim 0.11+ API changes

### Files Changed
- `lua/plugins/diagnostics.lua` (new — auto-loaded by lazy.nvim)
- `lua/plugins/snacks.lua` (update explorer config)

## 2. Snippets

### Problem
Missing Go/Rust-specific snippets (iferr, table tests, impl blocks, etc.)

### Solution
Custom snippets in **VS Code JSON format** (compatible with `nvim-snippets` which is already installed via LazyVim). NOT LuaSnip — the config uses `nvim-snippets`.

**Go snippets:**
- `iferr` — `if err != nil { return err }` (variants: return nil/err, fmt.Errorf, log.Fatal)
- `ife` — `if err := ...; err != nil {}`
- `tst` — test function boilerplate
- `tbt` — table-driven test boilerplate
- `bench` — benchmark function
- `hf` — http handler func
- `ctx` — context parameter pattern
- `meth` — method with receiver

**Rust snippets:**
- `test` / `tmod` — test function / test module
- `impl` — impl block
- `der` — derive macro
- `match` — match with arms
- `res` — Result<T, E> return
- `opt` — Option<T> handling
- `vec` — Vec initialization patterns

### Files Changed
- `snippets/go.json` (new — VS Code format snippet definitions)
- `snippets/rust.json` (new — VS Code format snippet definitions)
- `lua/plugins/snippets.lua` (new — configure nvim-snippets to load custom snippets)

## 3. Refactoring

### Problem
Refactoring barely works — no interface implementation, struct tags, extract function, test generation.

### Solution

**`ray-x/go.nvim` — configured to NOT conflict with LazyVim:**
- `lsp_cfg = false` (LazyVim manages gopls)
- `lsp_gfumpt = false` (conform.nvim manages formatting)
- `lsp_keymaps = false` (LazyVim manages LSP keymaps)
- Features used: `GoImpl`, `GoAddTag`, `GoRmTag`, `GoIfErr`, `GoFillStruct`, `GoTestFunc`, `GoTestFile`
- **CLI dependencies (must be installed):** `impl`, `gomodifytags`, `gotests`, `fillstruct` — install via `go install` or Mason

**`refactoring.nvim` (already installed via LazyVim `editor.refactoring` extra):**
- Extract function / variable (visual selection)
- Inline variable
- Extract block

**Rust — `rustaceanvim` (already installed):**
- Code actions via rust-analyzer: implement trait, fill match arms, add missing fields, extract function
- All via `<leader>ca` (code action menu) — this is the primary Rust refactoring entry point

**Keymaps under `<leader>r` (refactor):**
| Keymap | Action | Scope |
|--------|--------|-------|
| `<leader>ri` | Implement interface (GoImpl) | Go |
| `<leader>rt` | Add struct tags | Go |
| `<leader>rT` | Remove struct tags | Go |
| `<leader>rf` | Fill struct | Go |
| `<leader>re` | Extract function | Visual (universal) |
| `<leader>rv` | Extract variable | Visual (universal) |

**Note:** LSP rename stays at LazyVim default `<leader>cr`. No redundant GoRename.

**Crates.nvim keymaps moved to `<leader>cp` (crates/packages):**
| Keymap | Action |
|--------|--------|
| `<leader>cpu` | Upgrade all crates |
| `<leader>cpi` | Show crate info |
| `<leader>cpf` | Show crate features |
| `<leader>cpd` | Show crate dependencies |

**which-key group registrations:**
- `<leader>r` → "Refactor"
- `<leader>cp` → "Crates/Packages"

### Files Changed
- `lua/plugins/go.lua` (update — add go.nvim with safe config, refactoring keymaps)
- `lua/plugins/rust.lua` (update — move crates keymaps to `<leader>cp`)

## 4. Debugger

### Problem
DAP not configured for Go or Rust.

### Solution

**Go — `nvim-dap-go` (already enabled via LazyVim DAP extra):**
- Delve debugger
- Configs: debug current file, debug test, attach to process
- Build flags: `-race` by default

**Rust — `rustaceanvim` + `nvim-dap`:**
- `rustaceanvim` has built-in DAP integration that auto-detects CodeLLDB
- Ensure `codelldb` is installed via Mason
- Verify LazyVim `lang.rust` extra doesn't already wire this up (avoid duplication)

**UI — `nvim-dap-ui` (already enabled via LazyVim DAP extra):**
- Panels: variables, watches, call stack, breakpoints, console
- Auto open/close on debug start/stop

**Keymaps (verify against LazyVim DAP defaults, override only where needed):**
| Keymap | Action |
|--------|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dc` | Continue |
| `<leader>dt` | Debug nearest test |
| `<leader>dl` | Debug last config |
| `<F5>` | Continue |
| `<F10>` | Step over |
| `<F11>` | Step into |

**Note:** Removed `<F12>` (step out) — unreliable in some terminals. Use `<leader>do` instead.

### Files Changed
- `lua/plugins/dap.lua` (new — DAP config, Rust debug adapter verification, keymaps)

## 5. Tests

### Problem
neotest-golang works but no Rust test runner.

### Solution
- Add `rouge8/neotest-rust` adapter (verify LazyVim `lang.rust` extra doesn't already include it)
- Align keymaps with LazyVim `test.core` defaults

**Keymaps (LazyVim defaults, verify and supplement):**
| Keymap | Action |
|--------|--------|
| `<leader>tt` | Run nearest test |
| `<leader>tT` | Run file tests |
| `<leader>ts` | Test summary panel |
| `<leader>to` | Test output |
| `<leader>td` | Debug nearest test (via DAP) |

### Files Changed
- `lua/plugins/test.lua` (new — neotest-rust adapter)

## 6. Navigation (improvements)

### Solution
- `<leader>ss` — LSP document symbols (telescope) — verify already mapped by LazyVim
- `<leader>sS` — LSP workspace symbols (telescope) — verify already mapped by LazyVim
- `]]` / `[[` — function navigation via Treesitter textobjects (verify configured)
- Existing `gd` / `gr` / `gi` / `gy` already work via LazyVim

### Files Changed
- Mostly already configured via LazyVim — verify and add missing keymaps in `lua/config/keymaps.lua`

## 7. Git (improvements)

### Problem
No visual diff/merge tool.

### Solution
Add `sindrets/diffview.nvim`:
- `<leader>gv` — diff current file (avoiding `<leader>gd` which may conflict with mini-diff)
- `<leader>gV` — diff all changes
- `<leader>gh` — file history
- `<leader>gH` — branch history
- 3-way merge conflict resolution
- Gitsigns already handles blame, hunks, stage/reset

### Files Changed
- `lua/plugins/git.lua` (new — diffview.nvim config + keymaps)

## New Plugins Summary

| Plugin | Purpose |
|--------|---------|
| `ray-x/go.nvim` | Go refactoring, code generation |
| `ray-x/guihua.lua` | go.nvim dependency (floating UI) |
| `rouge8/neotest-rust` | Rust test runner for neotest |
| `sindrets/diffview.nvim` | Git diff/merge UI |

**CLI tools required (for go.nvim):**
- `impl` — `go install github.com/josharian/impl@latest`
- `gomodifytags` — `go install github.com/fatih/gomodifytags@latest`
- `gotests` — `go install github.com/cweill/gotests/gotests@latest`
- `fillstruct` — `go install github.com/davidrjenni/reftools/cmd/fillstruct@latest`

## Files Changed Summary

| File | Action |
|------|--------|
| `lua/plugins/snacks.lua` | Update — disable explorer diagnostics |
| `lua/plugins/diagnostics.lua` | New — diagnostic display config |
| `snippets/go.json` | New — Go snippets (VS Code format) |
| `snippets/rust.json` | New — Rust snippets (VS Code format) |
| `lua/plugins/snippets.lua` | New — nvim-snippets custom snippet config |
| `lua/plugins/go.lua` | Update — add go.nvim (LSP/fmt disabled), refactoring keymaps |
| `lua/plugins/rust.lua` | Update — move crates keymaps to `<leader>cp` |
| `lua/plugins/dap.lua` | New — DAP config, keymaps |
| `lua/plugins/test.lua` | New — neotest-rust adapter |
| `lua/plugins/git.lua` | New — diffview.nvim |
| `lua/config/keymaps.lua` | Update — navigation keymaps (if needed) |
