# nvim cheatsheet

`<leader>?` opens this, `<leader>s?` searches it. Space is `<leader>`. Every key
works in the Russian layout too. Forgot a key? Press its first key and wait:
which-key lists the rest. Vim's own commands: `<leader>sh` searches the help.

## Moving

- `s` + 2 letters: jump anywhere on screen by label (flash)
- `S`: pick a treesitter node (function, block, …) to select
- `]f` `[f`: next / previous function
- `Ctrl+O` `Ctrl+I`: back / forward through jumps
- `Ctrl+D` `Ctrl+U`: half a page down / up, centered

## Text objects (after d, c, y, v)

- `if` `af`: inside / around a function; `ic` `ac`: a class
- `i(` `i"` `i{` …: also from before the brackets on the line (`ci(` changes the
  next parentheses' content); `q` = any quote, `b` = any bracket
- `ih`: the git hunk under the cursor

## Editing

- Select, then `S` + `"` / `(` / `{`: surround the selection
- `ysiw)`: surround a word; `ds"`: delete quotes; `cs"'`: change `"` to `'`
- Visual `J` `K` (or Shift+Up/Down): move the selected lines
- `<leader>co`: change every occurrence of the word under the cursor
- `gcc` / `gc` + motion: comment lines
- `.`: repeat the last change; `<leader>u`: the undo tree

## Search and replace

- `<leader>sf` files, `<leader>sg` grep, `<leader>sw` word under cursor,
  `<leader>s.` recent, `<leader>sr` resume the last search, `<leader><leader>` buffers
- In a telescope list, `Ctrl+Q`: every result to the list (trouble), `Ctrl+Y` opens
- In a telescope list, `Ctrl+/` (Normal mode: `?`) shows all of its keys
- `<leader>xr`: replace in every line of the list (asks old, new; plain text,
  case-sensitive, files saved)
- The same by hand: `:cdo s/old/new/g | update` (`cdo` runs a command on each list
  entry; `:cfdo` on each file)

## Code

- `gd` definition, `gD` declaration, `grr` references, `gri` implementations,
  `grt` type definition, `K` docs (twice: into the float)
- `<leader>ca` (or `gra`) code action: fixes, organize imports; `<leader>cr` (or `grn`)
  rename
- `<leader>ss` symbols of the file, `<leader>sS` of the project
- `<leader>ch` inlay hints (types, parameter names) on / off
- Diagnostics: the message shows on the cursor's line; `<leader>cD` on every line;
  `]d` `[d` next / previous; `Ctrl+W d` the full message in a float

## Completion

- `Ctrl+Y` take the first item (or the picked one), `Enter` only a picked one,
  `Ctrl+N` `Ctrl+P` move, `Ctrl+E` close, `Ctrl+Space` open (in text it doesn't open
  by itself), `Ctrl+K` the signature
- Snippets are items too; `Tab` / `Shift+Tab` jump between their fields
- On the `:` line the menu completes commands as you type (`:cd` → `cdo`, `cfdo`)

## Formatting

- Saving formats the lines you changed, where the project has a formatter config
  (`[tool.ruff]`, `.clang-format`, `stylua.toml`, …); other lines stay as they are
- `<leader>fm` format your changes (Visual: the selection), `<leader>fM` the whole
  file

## Languages

- LaTeX (vimtex, `\` is `<localleader>`): `\ll` compile on every save (again:
  stop), `\lv` show the cursor's spot in zathura (Ctrl+click there jumps back),
  `\le` errors, `\lc` clean
- SQL: `<leader>db` the database UI (dadbod): connections, tables, saved queries
- Python finds the project's uv `.venv` by itself (imports resolve and complete)

## Debugging and tests

- `<leader>b`: a breakpoint on this line (again: remove it)
- `<leader>D`: debug mode until Esc: `c` start / continue, `n` next line, `i` step
  into, `o` step out, `r` run to the cursor, `b` breakpoint, `B` one that stops only
  when a condition holds, `e` the value under the cursor, `w` watch it, `u` the
  panel, `q` stop
- While stopped, values show next to the code. The panel: `S` scopes (locals), `W`
  watches, `B` breakpoints, `T` threads, `R` REPL (type code there, e.g. Python)
- `<leader>tt` run the test under the cursor, `<leader>td` debug it (it stops at
  your breakpoints), `<leader>tf` the file's tests, `<leader>ta` all, `<leader>tl`
  the last again, `<leader>ts` summary, `<leader>to` the output, `<leader>tw` rerun
  on every save
- Python runs in the project's `.venv`; `<leader>Dc` in a plain file offers "Launch
  file". C, C++, Rust: build with debug info first, `<leader>Dc` asks for the program

## Per-project settings

- A `.nvim.lua` in a project (or any dir above where nvim starts) runs at start.
  nvim shows it once and asks; after you edit it, `:trust`. Keep it out of the
  project's git: add `.nvim.lua` to its `.git/info/exclude`.
- Example: the project's own C/C++ compilers, for clangd's system headers:

  ```lua
  local root = vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2))
  vim.env.CLANGD_FLAGS = '--query-driver=' .. root .. '/prebuilts/**/bin/clang*'
  ```

- For the whole machine instead: `set -gx CLANGD_FLAGS …` in an untracked fish file
  such as `~/.config/fish/conf.d/local.fish`

## Notes (vault-13, prompts, dota-analytics in ~/notes)

- `<leader>na` today's note, `<leader>nc` this week's, `<leader>nf` next week's,
  `<leader>nd` the last 30 days, `<leader>ni` the inbox (vault-13's inbox.md)
- `<leader>no` open a note, `<leader>ns` search, `<leader>nt` tags, `<leader>nn` new,
  `<leader>nb` backlinks, `<leader>nl` links, `<leader>nr` rename (links follow),
  `<leader>nm` insert a template, `<leader>nw` switch vault, `<leader>nO` the Obsidian
  app, `<leader>np` paste an image
- Selection: `<leader>ne` extract into a new note, `<leader>nl` link it to a note,
  `<leader>nn` to a new one
- `Enter`: follow a link, toggle a checkbox (on a list item: make one), list a tag's
  notes, fold a heading; `]o` `[o` next / previous link; `gd` follows a link too,
  `grr` lists the notes linking here
- In any Markdown file (nvim's own): `]]` `[[` next / previous heading, `gO` an
  outline of the headings in a side list
- Org: `<leader>oa` agenda, `<leader>oc` capture (task, note, prompt into
  ~/orgfiles), `<leader>oh` every heading and TODO, `<leader>of` the org files

## Notebooks

- An `.ipynb` opens as Python with `# %%` cells (markdown cells are comments), starts
  the project's kernel (its `.venv`, registered once as a Jupyter kernel) and shows the
  saved outputs (`[OLD]` until rerun). Saving writes code and outputs back
- `Shift+Enter` run the cell and go to the next (a new one at the end), `Ctrl+Enter`
  run it and stay; in Insert mode too
- `]j` `[j` next / previous cell; `ij` `aj` a cell's code / with its `# %%` line
  (`vij`, `daj`); `za` folds a cell
- `<leader>J` notebook mode until Esc, or `<leader>j` + key once: arrows cells, `r`
  run, `a` this and all above, `A` all, `o` `O` new cell below / above, `d` delete,
  `s` output in a float, `h` hide it, `x` clear it, `i` interrupt, `k` (re)start the
  kernel, `c` connect to a running one (VS Code, jupyter), `b` output in the browser
- A `.py` file with `# %%` cells gets the same keys (its kernel starts on the first
  run)

## Documents

- PDF, Word and LibreOffice (docx, odt, rtf), epub, pptx, Excel, Parquet, SQLite,
  arrays and weights (npy, npz, safetensors, pt, pkl, h5), audio and video, 7z and
  rar open as text, read-only. `gx` opens the original (a PDF in zathura)
- Wide tables: `zl` `zh` scroll sideways, `zL` `zH` half a screen
- zip and tar: nvim's own browser, Enter opens a file inside
- CSV and TSV: columns aligned on screen, still editable; `Tab` `Shift+Tab` next /
  previous field, `if` `af` a field
- A pickle (`.pkl`, `.pt`) is read without running it: its classes show by name
- Files over 1.5 MB open without treesitter, LSP and folds, so they open fast

## Lists

- `<leader>xx` diagnostics, `<leader>xX` this file's, `<leader>xq` the quickfix list,
  `<leader>xt` TODOs; in a list `q` closes, `Enter` jumps
- `]t` `[t`: next / previous TODO comment; `<leader>st`: search TODOs
- `<leader>cs`: outline of the file (functions, or a note's headings)

## Git

- `<leader>H`: review mode, stays until Esc: arrows = next / previous hunk,
  `s` stage, `r` reset, `S` / `R` the whole file, `u` undo a stage, `p` preview,
  `b` blame, `d` diff
- `]c` `[c`: next / previous hunk; `<leader>h` + key: the same keys once
- diffview, in its own tab, `Ctrl+Q` closes it: `<leader>do` the changes not
  committed, `<leader>dm` this branch against main, `<leader>dh` this file's
  history, `<leader>dH` all history, `<leader>dl` this line's history (or the
  selected lines'), `<leader>dc` the commit that last changed this line. Inside:
  `Tab` / `Shift+Tab` next / previous file, `-` stages a file, `g?` help
- `<leader>g`: lazygit in a float (`q` closes)

## Claude Code

Claude runs in tmux, connected to this nvim: it sees the file and the selection,
shows its edits here as diffs and reads the errors. A `claude` started by hand in
this folder connects too.

- `<leader>ac` / `<leader>aC`: Claude (personal / team) in a pane to the right,
  connected; again: jumps to it. `Ctrl+\` back
- `<leader>as`: send the selection (or this file; in oil or the tree, the file under
  the cursor) as `@file#L10-20`, then jump to Claude to ask
- An edit Claude asks about opens here as a diff: `<leader>aa` or `:w` accepts (edit
  it first if you like), `<leader>ad` rejects. An edit it doesn't ask about (auto or
  accept-edits mode) is written at once: review it with `<leader>H`
- In Claude: `Ctrl+G` writes the prompt in nvim (`:wq` hands it back), `/ide` picks
  another nvim, `/export` saves the conversation

## Files

- `-`: the file's directory in oil: rename, move, delete by editing lines,
  `Ctrl+S` applies, `Ctrl+Q` back to the file, `g.` hidden files, `g?` help
- `<leader>e`: the explorer tree

## Windows and tabs

- `<leader>w`: window mode until Esc: arrows focus, Shift+arrows move,
  `+ - < > =` size, `s` `v` split, `q` close, `o` only this one, `T` to a tab
- `Ctrl+arrows`: to the next window or tmux pane
- `Ctrl+T`: a scratch tab (closes without asking); `Alt+Left/Right`: switch tabs,
  `Alt+Shift+Left/Right`: move them
- `Ctrl+S` save, `Ctrl+Q` close (asks if unsaved)

## Tools

- `<leader>T`: translate the line or the selection: Russian to English, anything else
  to Russian (Google, needs the network)
- Color codes (`#e6b450`, `rgb(…)`) show their color behind them

## Writing

- In text (Markdown, notes, commit messages, LaTeX, Typst) the line you type on stays
  in the middle of the screen, like paper in a typewriter: `<leader>mt` on / off;
  `<leader>mn` line numbers on / off
- In text `j` `k` and the arrows move by screen line through a wrapped paragraph
  (in Insert mode too); a count moves by real lines (`5j`)
- Markdown is rendered in place: `<leader>mr` on / off. Images, `$math$` and
  ```` ```mermaid ```` blocks are drawn in the note (kitty)
- `<leader>mp` paste a screenshot from the clipboard as an image file + link (in a
  vault: into its attachments folder)
- `<leader>me` export to PDF, DOCX or HTML next to the file (pandoc; the PDF opens in
  zathura)
- Typst: saving writes the PDF, `\lv` opens it in zathura, which reloads it on every
  save. LaTeX: `\ll` (Languages)

## Spelling (in text)

- `]s` `[s`: next / previous typo; `z=`: suggestions; `1z=`: take the first
- `zg`: add the word to your dictionary; `:spellrepall`: repeat the last fix in the
  whole file
