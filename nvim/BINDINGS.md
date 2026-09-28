# Neovim keybindings

This is the binding index for this configuration. `<leader>` is **Space**.

The main tables cover every explicit mapping in `nvim/`, including mappings
created on LSP attach or for a language/filetype. The final sections also index
the keyboard defaults selected by this configuration for Blink, Surround,
Obsidian, Oil, Telescope, Harpoon, Dropbar, Trouble, and DAP UI. Mouse-only
actions and stock Vim/Neovim commands are outside the index unless this
configuration remaps or deliberately re-registers them. Auto-pair typing behavior
is documented below as well.

Modes used below: **N** = Normal, **V** = Visual, **O** = operator-pending,
**I** = Insert. “Buffer” means the map exists only in the relevant attached or
plugin buffer.

## Core navigation and windows

| Keys | Mode | Scope | Action |
| --- | --- | --- | --- |
| `H` | N | Global | Jump backward in the jump list (`<C-o>`) |
| `L` | N | Global | Jump forward in the jump list (`<C-i>`) |
| `<leader>wh` | N | Global | Focus window left |
| `<leader>wj` | N | Global | Focus window below |
| `<leader>wk` | N | Global | Focus window above |
| `<leader>wl` | N | Global | Focus window right |
| `<leader>ws` | N | Global | Split below |
| `<leader>wv` | N | Global | Split right |
| `<leader>wq` | N | Global | Close current window |
| `<leader>wo` | N | Global | Close all other windows |

The `<leader>w` family is retained as a convenient alias for Vim's native
`<C-w>` commands. Unlock-first Zellij lets both forms reach Neovim.

## Files, search, breadcrumbs, and Harpoon

| Keys | Mode | Scope | Action |
| --- | --- | --- | --- |
| `<leader>e` | N | Global | Toggle Oil in the current window |
| `<leader>ff` | N | Global | Telescope: find files |
| `<leader>fg` | N | Global | Telescope: live grep |
| `<leader>fb` | N | Global | Telescope: open buffer list |
| `<leader>fr` | N | Global | Telescope: find Git-tracked/untracked files |
| `<leader>fs` | N | Global | Prompt for a string, then grep for it |
| `<leader>;` | N | Global | Pick a Dropbar breadcrumb component/symbol |
| `<leader>a` | N | Global | Add current file to the Harpoon list |
| `<leader>m` | N | Global | Toggle the Harpoon quick menu |
| `<leader>1`, `<leader>2`, `<leader>3`, `<leader>4` | N | Global | Open Harpoon item 1 … 4 |

## LSP and diagnostics

These maps are buffer-local and appear whenever an LSP client attaches.

| Keys | Mode | Scope | Action |
| --- | --- | --- | --- |
| `gd` | N | LSP buffer | Go to definition |
| `gi` | N | LSP buffer | Go to implementation |
| `gy` | N | LSP buffer | Go to type definition |
| `gr` | N | LSP buffer | Find references |
| `<leader>li` | N | LSP buffer | Show incoming calls to this symbol |
| `<leader>lo` | N | LSP buffer | Show outgoing calls from this symbol |
| `[d` | N | LSP buffer | Jump to the previous diagnostic and open its float |
| `]d` | N | LSP buffer | Jump to the next diagnostic and open its float |
| `<leader>lr` | N | LSP buffer | Rename symbol across the project |
| `<leader>la` | N | LSP buffer | Show code actions, fixes, and refactors |
| `<leader>ld` | N | LSP buffer | Open the diagnostic float |

Neovim's default `grr`, `grn`, `gra`, `gri`, and `grt` Normal maps and `gra`
Visual map are deliberately removed. This lets the shorter `gr` references map
run without waiting for a chord timeout.

### Rust-only

| Keys | Mode | Scope | Action |
| --- | --- | --- | --- |
| `<leader>lt` | N | Rust buffer | Toggle Rust inlay type hints |
| `<F13>` | N | Rust buffer | Toggle Rust inlay type hints; Ghostty sends F13 for Option+Command+I |
| `<leader>lR` | N | Rust buffer | Render the full `rustc` diagnostic |
| `<leader>lE` | N | Rust buffer | Explain the current error with `rustc --explain` |

### Haskell-only

These exist in Haskell, literate Haskell, Cabal, and Cabal-project buffers.

| Keys | Mode | Action |
| --- | --- | --- |
| `<leader>lhh` | N | Search Hoogle for a signature |
| `<leader>lhe` | N | Evaluate code snippets in comments |
| `<leader>lhp` | N | Open the Cabal or `package.yaml` project file |
| `<leader>lhr` | N | Toggle the package GHCi REPL |
| `<leader>lhf` | N | Toggle a GHCi REPL for the current file |
| `<leader>lhq` | N | Quit the GHCi REPL |

## Git hunks

These maps are buffer-local and appear when Gitsigns attaches to a Git-backed
file.

| Keys | Mode | Action |
| --- | --- | --- |
| `]h` | N | Next hunk |
| `[h` | N | Previous hunk |
| `<leader>hs` | N | Stage or unstage the current hunk |
| `<leader>hr` | N | Reset the current hunk |
| `<leader>hs` | V | Stage or unstage the selected lines |
| `<leader>hr` | V | Reset the selected lines |
| `<leader>hp` | N | Preview current hunk |
| `<leader>hb` | N | Show full blame for the current line |
| `<leader>hd` | N | Diff the buffer against the index |

## Problems and lists

| Keys | Mode | Scope | Action |
| --- | --- | --- | --- |
| `<leader>xx` | N | Global | Toggle all diagnostics in Trouble |
| `<leader>xX` | N | Global | Toggle current-buffer diagnostics in Trouble |
| `<leader>xq` | N | Global | Toggle the quickfix list in Trouble |
| `<leader>xl` | N | Global | Toggle the location list in Trouble |

## Debugging

The first debug key loads the DAP stack. The UI also opens automatically when a
session initializes and closes when it terminates or exits.

| Keys | Mode | Action |
| --- | --- | --- |
| `<leader>dd` | N | Open DAP UI and start/continue |
| `<leader>d<Space>` | N | Start or continue |
| `<leader>dl` | N | Step into |
| `<leader>dj` | N | Step over |
| `<leader>dh` | N | Step out |
| `<F1>` | N | Step out |
| `<F2>` | N | Step over |
| `<F3>` | N | Step into |
| `<leader>d-` | N | Restart debug session |
| `<leader>d_` | N | Terminate session, close UI, and restore line numbers |
| `<leader>du` | N | Toggle DAP UI and restore line numbers |
| `<leader>db` | N | Toggle a persistent breakpoint |
| `<leader>dgt` | N | Set DAP log level to TRACE |
| `<leader>dge` | N | Open the DAP log |

## Folds

| Keys | Mode | Action |
| --- | --- | --- |
| `zf` | N | Collapse every function/method body in the file into a semantic outline |
| `zF` | N | Open every function/method fold in the file |
| `zq` | N | Collapse function/method bodies only in the enclosing `impl`/class/trait |
| `zQ` | N | Open function/method folds only in the enclosing `impl`/class/trait |
| `zK` | N | Peek inside the closed fold under the cursor |
| `zm` / `{count}zm` | N | Close one or `{count}` more fold levels across the file |
| `zr` / `{count}zr` | N | Open one or `{count}` more fold levels across the file |
| `zR` | N | Open every fold |
| `zM` | N | Close every fold |

The outline actions use Treesitter's `@function.outer` and `@class.outer`
textobjects, so methods and their enclosing `impl`/class/trait are selected by
syntax rather than numeric fold depth. These mappings replace native `zf{motion}`
(create a manual fold over a motion) and `zF` (create a manual fold over counted
lines). `zm` and `zr` retain Vim's relative level-stepping semantics but route
through UFO so its pinned `foldlevel` does not desynchronize provider folds.
Entering level mode installs Treesitter fold ranges synchronously, with
indentation fallback, so stepping does not wait for an asynchronous LSP fold
response. Native `za`, `zo`/`zc`, `zO`/`zC`, `zj`/`zk`, and `zv` remain
available. `K` retains Neovim's normal LSP-hover/keyword behavior, and `<Tab>`
retains its normal-mode jump behavior.

## Treesitter text objects and movement

The selection maps use lookahead, so they can select the next matching object
when the cursor is not already inside one. Movement records jump-list entries.

| Keys | Mode | Action |
| --- | --- | --- |
| `af` | V, O | Around function |
| `if` | V, O | Inside function |
| `ac` | V, O | Around class/type |
| `ic` | V, O | Inside class/type |
| `aa` | V, O | Around argument/parameter |
| `ia` | V, O | Inside argument/parameter |
| `]m` | N, V, O | Next function start |
| `[m` | N, V, O | Previous function start |
| `]M` | N, V, O | Next function end |
| `[M` | N, V, O | Previous function end |
| `]]` | N, V, O | Next class/type start |
| `[[` | N, V, O | Previous class/type start |

## Completion and snippets

Blink's configured `default` preset supplies these Insert-mode maps. Each falls
back to normal Insert behavior when completion/snippet state does not apply.

| Keys | Action |
| --- | --- |
| `<C-Space>` | Show completion; then show/hide documentation |
| `<C-e>` | Cancel completion |
| `<C-y>` | Select and accept the highlighted item |
| `<Up>` / `<C-p>` | Select previous item |
| `<Down>` / `<C-n>` | Select next item |
| `<C-b>` | Scroll documentation up |
| `<C-f>` | Scroll documentation down |
| `<Tab>` | Jump forward through snippet placeholders |
| `<S-Tab>` | Jump backward through snippet placeholders |
| `<C-k>` | Show/hide signature help |

## Surround editing

### Automatic pairs while typing

`nvim-autopairs` loads on entering Insert mode. Its default rules pair `()`,
`[]`, `{}`, double quotes, single quotes, and backticks where applicable.
Rust single-quote rules avoid pairing after letters, `<`, or `&` so common
lifetime syntax remains natural.
Typing an existing closing delimiter skips over it. Backspace between an
empty pair removes both characters; Enter between `{}` opens an indented
line and moves the closing brace down. These are Insert-mode mappings;
Blink still uses Ctrl-Y to accept completion and Tab/Shift-Tab for snippet
placeholders. Rust templates from `friendly-snippets` include `fn`, `pfn`,
and `impl-trait`.

### Editing existing surrounds

These are nvim-surround's defaults, enabled by `opts = {}`.

| Keys | Mode | Action |
| --- | --- | --- |
| `ys{motion}{char}` | N | Surround a motion; for example `ysiw"` |
| `yss{char}` | N | Surround the current line |
| `yS{motion}{char}` | N | Surround a motion with delimiters on new lines |
| `ySS{char}` | N | Surround the current line with delimiters on new lines |
| `ds{char}` | N | Delete the surrounding pair |
| `cs{old}{new}` | N | Change a surrounding pair |
| `cS{old}{new}` | N | Change it with the replacement on new lines |
| `S{char}` | V | Surround the selection |
| `gS{char}` | V | Surround the selection on new lines |
| `<C-g>s{char}` | I | Insert a surrounding pair around the cursor |
| `<C-g>S{char}` | I | Insert a surrounding pair on new lines |

Common `{char}` targets include `()`, `[]`, `{}`, quotes, `t` for an HTML tag,
and `f` for a function call. Opening brackets add inner spaces; closing brackets
do not.

## Markdown and Obsidian

Obsidian installs these Normal-mode maps in Markdown buffers:

| Keys | Action |
| --- | --- |
| `gf` | Follow the Markdown/wiki link under the cursor; fall back to normal `gf` |
| `<leader>ch` | Cycle the checkbox under the cursor |
| `<CR>` | Context action: follow a link or toggle a checkbox |

Neovim's Markdown runtime also provides `]]`/`[[` for next/previous section and
`gO` for the document outline. In Markdown buffers those runtime maps take
precedence over the same global Treesitter class/type movement keys.

## Oil buffer

These maps apply only inside the editable Oil directory buffer. Normal Vim
editing commands—such as `dd` to delete a line and `p` to place it elsewhere—
compose file operations; `:write` applies the changes.

| Keys | Mode | Action |
| --- | --- | --- |
| `<CR>` | N, V, O | Open entry |
| `-` | N | Parent directory |
| `_` | N | Open Neovim's working directory |
| `q` / `<C-c>` | N | Close Oil and restore the previous buffer |
| `<C-l>` | N, V, O | Refresh directory |
| `gv` / `<C-s>` | N, V, O | Open entry in a vertical split |
| `gh` / `<C-h>` | N, V, O | Open entry in a horizontal split |
| `gt` / `<C-t>` | N, V, O | Open entry in a new tab |
| `gp` / `<C-p>` | N, V, O | Toggle preview |
| `` ` `` | N | `:cd` to the Oil directory |
| `g~` | N | Set the tab-local directory to the Oil directory |
| `gs` | N | Change sort order |
| `gx` | N, V, O | Open entry with an external application |
| `g.` | N | Toggle hidden files |
| `g\` | N | Jump to/from the trash directory |
| `g?` | N | Show Oil's key help |

The `g` variants for split/tab/preview are convenient local aliases for Oil's
Control-key defaults; unlock-first Zellij lets both forms reach Neovim.

## Plugin-window defaults

These keys are not authored individually in this repo; they come from the
default plugin setups selected here. They are included because they are useful
once one of the configured plugin windows is open.

### Telescope picker

| Keys | Mode | Action |
| --- | --- | --- |
| `<C-n>` / `<Down>` | I | Next result |
| `<C-p>` / `<Up>` | I | Previous result |
| `j` / `k` | N | Next / previous result |
| `<CR>` | I, N | Open selected result |
| `<C-x>` / `<C-v>` / `<C-t>` | I, N | Open in split / vertical split / tab |
| `<Tab>` / `<S-Tab>` | I, N | Toggle selection and move down / up |
| `<C-q>` | I, N | Send results to quickfix and open it |
| `<M-q>` | I, N | Send selected results to quickfix and open it |
| `<C-u>` / `<C-d>` | I, N | Scroll preview up / down |
| `<C-f>` / `<C-k>` | I, N | Scroll preview left / right |
| `<PageUp>` / `<PageDown>` | I, N | Scroll result list |
| `<M-f>` / `<M-k>` | I, N | Scroll result list left / right |
| `<C-c>` | I | Close picker |
| `<Esc>` | N | Close picker |
| `<C-/>` (often `<C-_>`) | I | Show picker mappings |
| `?` | N | Show picker mappings |
| `H` / `M` / `L` | N | Move to top / middle / bottom result |
| `gg` / `G` | N | Move to first / last result |
| `<C-l>` | I | Complete the tag under the prompt cursor |
| `<C-r><C-w>` / `<C-r><C-a>` | I | Insert the original word / WORD into the prompt |
| `<C-r><C-f>` / `<C-r><C-l>` | I | Insert the original filename / line into the prompt |
| `<C-w>` | I | Delete the previous prompt word |

`<C-j>` is deliberately a no-op in Telescope's Insert mode so it cannot add a
newline to the prompt.

### Harpoon quick menu

| Keys | Action |
| --- | --- |
| `<CR>` | Open selected Harpoon item |
| `q` / `<Esc>` | Close the menu |
| `:write` | Save edited list and close the menu |

### Dropbar picker and menu

After `<leader>;`, press one of the displayed `a`–`z` pivot labels to choose a
breadcrumb. If that component opens a menu:

| Keys | Action |
| --- | --- |
| `<CR>` | Select the component under the cursor |
| `i` | Open fuzzy finding within the menu |
| `q` / `<Esc>` | Close the menu |

### DAP UI

Actions apply only where the current DAP UI element supports them.

| Keys | Action |
| --- | --- |
| `<CR>` / double-click | Expand or collapse item |
| `o` | Open/jump to item |
| `d` | Remove item |
| `e` | Edit value/expression |
| `r` | Send item to REPL |
| `t` | Toggle item |
| `w` | Add item to watches |
| `q` / `<Esc>` | Close a DAP floating window |

### Trouble window

Trouble keeps normal `j`/`k` movement and adds:

| Keys | Action |
| --- | --- |
| `?` | Show help |
| `q` | Close |
| `<CR>` | Jump to item |
| `o` | Jump and close Trouble |
| `<Esc>` | Cancel the current action |
| `<C-s>` / `<C-v>` | Jump in split / vertical split |
| `]]` / `}` | Next item |
| `[[` / `{` | Previous item |
| `p` / `P` | Preview / toggle preview |
| `r` / `R` | Refresh / toggle automatic refresh |
| `dd` | Delete item |
| `d` | Delete selected items in Visual mode |
| `i` | Inspect item |
| `gb` | Toggle current-buffer filter |
| `s` | Cycle the severity filter |
| `za`, `zo`, `zc`, `zA`, `zO`, `zC` | Toggle/open/close a group, optionally recursively |
| `zm`, `zM`, `zr`, `zR` | Reduce/close/reveal/open fold levels |
| `zx` / `zX` | Recompute current / all folds |
| `zn` / `zN` / `zi` | Disable / enable / toggle folding |
