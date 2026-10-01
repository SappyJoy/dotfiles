## Your commands

At work, on the 26.04 PC (the dotfiles with W2 are pushed): its first nvim
start rewrote `lazy-lock.json` (treesitter's branch `main`, hererocks), so `chezmoi
update` would stop at that file. Look at the diff, take the tracked lock, then apply:
the apt rows (sudo asks), then nvim's install (~3 min).

```fish
chezmoi git -- pull --ff-only
chezmoi diff ~/.config/nvim/lazy-lock.json
chezmoi apply --force ~/.config/nvim/lazy-lock.json
chezmoi apply
```

At work (W4): why `dots` is slow there. Paste the three times back.

```fish
time chezmoi status
time chezmoi status --exclude=externals,scripts
time lazygit -p ~/.local/share/chezmoi   # press q at once
```
---

```sh
❯ chezmoi git -- pull --ff-only

Already up to date.
❯ chezmoi diff ~/.config/nvim/lazy-lock.json

❯ time chezmoi status

MM .config/mise/config.toml

________________________________________________________
Executed in    2.86 secs    fish           external
   usr time    2.73 secs    1.24 millis    2.73 secs
   sys time    0.59 secs    1.01 millis    0.59 secs

❯ time chezmoi status --exclude=externals,scripts

MM .config/mise/config.toml

________________________________________________________
Executed in    1.64 secs    fish           external
   usr time    1.56 secs    1.74 millis    1.56 secs
   sys time    0.56 secs    0.25 millis    0.56 secs

❯ time lazygit -p ~/.local/share/chezmoi

________________________________________________________
Executed in  658.73 millis    fish           external
   usr time  452.38 millis    0.53 millis  451.85 millis
   sys time  210.41 millis    1.32 millis  209.09 millis

```
