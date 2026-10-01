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

## Lists

- `<leader>xx` diagnostics, `<leader>xX` this file's, `<leader>xq` the quickfix list,
  `<leader>xt` TODOs; in a list `q` closes, `Enter` jumps
- `]t` `[t`: next / previous TODO comment; `<leader>st`: search TODOs
- `<leader>cs`: outline of the file (functions, or a note's headings)

## Git review

- `<leader>H`: review mode, stays until Esc: arrows = next / previous hunk,
  `s` stage, `r` reset, `S` / `R` the whole file, `u` undo a stage, `p` preview,
  `b` blame, `d` diff
- `]c` `[c`: next / previous hunk; `<leader>h` + key: the same keys once

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

## Spelling (in text)

- `]s` `[s`: next / previous typo; `z=`: suggestions; `1z=`: take the first
- `zg`: add the word to your dictionary; `:spellrepall`: repeat the last fix in the
  whole file
