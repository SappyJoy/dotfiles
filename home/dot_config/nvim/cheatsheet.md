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
