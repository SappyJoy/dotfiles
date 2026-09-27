# dotfiles

Configs and scripts for my Linux machines (an Arch desktop, Ubuntu boxes, WSL, and
borrowed machines over SSH), managed with [chezmoi](https://www.chezmoi.io). Secrets
are encrypted with [age](https://age-encryption.org).

## Install

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply SappyJoy
```

chezmoi asks two questions, once per machine:

- **Desktop (X11 + i3)**: also install the i3 / polybar / picom / kitty / rofi configs
  and their scripts.
- **Own machine (secrets)**: decrypt `private.fish` (API keys) and `~/.ssh/config`.
  Say no on borrowed machines.

To change an answer later, run `chezmoi init --prompt`.

Then `tools-check` lists the tools that are missing or older than on arch, with an
install hint for each.

### The age key (own machines only)

The secrets are encrypted to one age key. It is never in this repo. Copy it before
`init`:

```sh
mkdir -p ~/.config/chezmoi
scp arch:.config/chezmoi/key.txt ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

Keep an offline copy. Without the key the encrypted files can't be read. Everything in
them can be regenerated (API keys, ssh hosts), but it's tedious.

## Daily use

| Task | Command |
|---|---|
| Commit edits made to live files | `dots`: re-add the edited files, then lazygit on this repo |
| Get changes from other machines | `chezmoi update` (pull + apply) |
| What differs on this machine | `chezmoi status`, `chezmoi diff` |
| Track a new file | `chezmoi add <file>`; add `--encrypt` for secrets |
| Edit a template or secret | `vd <file>` (`chezmoi edit --apply`) |
| Tools missing or outdated | `tools-check` (`--missing`: only what needs action) |
| After upgrading tools on arch | `tools-check --record`, then `dots` |

Pull with `chezmoi update`, not in lazygit. If you do pull in lazygit, run
`chezmoi apply` right after. `dots` leaves pulled changes alone, but a file that
changed on both sides needs `chezmoi merge <file>`.

## Per-machine differences

In order of preference:

1. **Existence check in the config itself**, e.g. `if [ -d … ]` in `.profile`,
   `isdirectory()` in nvim. It works everywhere and needs no chezmoi logic.
2. **Machine data** in a template (`*.tmpl`) or in `.chezmoiignore`: the prompt answers
   (`.desktop`, `.personal`) or detected facts (`.chezmoi.osRelease.id`, hostname).
   Example: the i3 config renders the Throne key and the polkit agent on Arch only.
3. **Files an app rewrites** (`btop.conf`, kitty `theme.conf`) get the `create_`
   prefix: written once, then owned by the app.
4. **State a script writes** stays untracked and is included by a tracked config:
   `theme-switcher` writes `tmux/theme.conf`, `i3/colors` and `polybar/colors.ini`.
5. **Secrets**: `chezmoi add --encrypt`.

`re-add` (and so `dots`) skips templates. Edit those with `vd`, or bring a live edit
over with `chezmoi merge`.

## Layout

- `home/` is the source state (see `.chezmoiroot`). The names encode attributes:
  - `dot_` → `.`
  - `executable_`
  - `private_` (0600 / 0700)
  - `encrypted_*.age`
  - `create_`
  - `*.tmpl`
- `home/.chezmoi.toml.tmpl`: the prompts and the age settings
- `home/.chezmoiignore`: what each kind of machine skips
- `home/.chezmoiexternal.toml`: tmux plugin manager (tpm)
- `home/dot_config/tools/tools.tsv`: the tool list behind `tools-check`
- `tests/`:
  - `sh tests/tools-check.sh`
  - `sh tests/fresh-machine.sh [IMAGE…]`: applies this source as a non-root user in
    clean Ubuntu containers (docker; default `ubuntu:20.04` and `ubuntu:24.04`)

## Moving a machine off the old bare repo

Until 2026-09 these files lived in the bare repos `~/.dotfiles` and `~/.secrets`, with
`$HOME` as the work tree. To switch a machine over:

1. Save its local changes:
   ```sh
   git --git-dir=$HOME/.dotfiles --work-tree=$HOME diff > ~/dotfiles-local.patch
   git --git-dir=$HOME/.secrets --work-tree=$HOME diff > ~/secrets-local.patch
   ```
2. Own machine: copy the age key (above).
3. If `~/.tmux/plugins/tpm/.git` is a file, the checkout points into `~/.dotfiles`.
   Move `~/.tmux/plugins/tpm` aside so chezmoi clones it fresh.
4. Run `chezmoi init SappyJoy` (no `--apply`), then `chezmoi diff`: this is what apply
   would change. Carry wanted local bits into the source (rules above) and commit.
5. `chezmoi apply`.
6. Move the old repos aside:
   ```sh
   mv ~/.dotfiles ~/.dotfiles.bak-$(date +%Y%m%d-%H%M%S)
   mv ~/.secrets ~/.secrets.bak-$(date +%Y%m%d-%H%M%S)
   ```
