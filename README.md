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
- **Own machine (secrets)**: decrypt `private.fish` (API keys) and the personal ssh
  hosts (`~/.ssh/personal.conf`).
  Say no on borrowed machines.

To change an answer later, run `chezmoi init --prompt`.

On machines other than arch, the same `apply` also installs the tools (see
[Tools](#tools)), so a fresh machine is ready when it finishes. There, an interactive
bash hands over to fish: a fish in `~` can't be the login shell without root.

`tools-check` lists what's still missing or older than on arch, with an install hint
for each.

### Guest machines

On someone else's machine (over SSH, no root), `guest.sh` installs the same setup
without secrets or the desktop stack, and undoes it when you leave:

```sh
curl -fsLS https://raw.githubusercontent.com/SappyJoy/dotfiles/master/guest.sh | sh -s install
sh ~/.local/share/chezmoi/guest.sh remove
```

- `install` backs up the files chezmoi would overwrite into `~/.guest-dotfiles`. Run
  it again to update.
- `remove` puts them back and deletes what chezmoi, mise, fisher and the tools
  created, chezmoi included. Files you made yourself stay, and so do directories that
  aren't empty.

### The age key (own machines only)

The secrets are encrypted to one age key. It is never in this repo. Copy it before
`init`:

```sh
mkdir -p ~/.config/chezmoi
scp arch:.config/chezmoi/key.txt ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

Where arch isn't reachable, copy it from the offline copy instead, e.g.
`cp /media/$USER/STICK/chezmoi-age-key.txt ~/.config/chezmoi/key.txt`.

Keep an offline copy. Without the key the encrypted files can't be read. Everything in
them can be regenerated (API keys, ssh hosts), but it's tedious.

## Daily use

| Task | Command |
|---|---|
| Commit edits made to live files | `dots`: re-add the edited files, then lazygit on this repo; it lists what's left with the command for each |
| Get changes from other machines | `chezmoi update` (pull + apply) |
| What differs on this machine | `chezmoi status`, `chezmoi diff` |
| Track a new file | `dots <file>…` (adds it, then as above); secrets: `chezmoi add --encrypt <file>` |
| Edit a template or secret | `vd <file>` (`chezmoi edit --apply`) |
| Tools missing or outdated | `tools-check` (`--missing`: only what needs action) |
| After upgrading tools on arch | `tools-check --record`, then `dots` |

### ssh

- `~/.ssh/config` is each machine's own file: add that machine's hosts there. chezmoi
  only keeps a block at its end, which includes `personal.conf` (own machines: the
  personal hosts, encrypted; `vd ~/.ssh/personal.conf`) and `defaults.conf` (every
  machine). ssh takes the first value it finds, so a host in `config` overrides a
  default.
- `defaults.conf` shares one connection per host (a second shell, scp or git starts
  at once) and gives up on an unreachable host after 10 s. `ssh -O exit HOST` closes
  a shared connection, e.g. one that hangs after a VPN switch.
- sshfs: its own connection, and a reconnect after a dead link:
  `sshfs -o reconnect,ServerAliveInterval=15,ControlPath=none HOST:DIR MOUNTPOINT`

### VPN (own desktops)

Two tunnels, one at a time: WireGuard (NetworkManager's connection `vpnconfig`) and
VLESS (sing-box's tunnel, no window or tray). `toggle-wireguard` ($mod+Shift+v) and
`toggle-vless` ($mod+Shift+t), or a click on the bar; turning one on turns the other
off.

- The profiles are encrypted here: `~/.config/wireguard/vpnconfig.conf` (wg-quick
  format) and `~/.config/sing-box/config.json`. Edit with `vd`; after a WireGuard
  change, `nmcli connection delete vpnconfig` and run `vpn-setup` to import it again.
  The VLESS server in use is the `proxy` outbound; `systemctl restart vless` applies
  an edit.
- A new machine: install sing-box (`tools-check`), then run `vpn-setup` once (sudo). It
  writes the `vless` service (sing-box as you, with network rights only), a polkit rule
  that lets you start and stop it without a password, and imports the WireGuard
  profile into NetworkManager. The package's own `sing-box.service` stays off: its
  default config is a shadowsocks server open to the LAN.
- Logs: `journalctl -u vless`.

Pull with `chezmoi update`, not in lazygit. If you do pull in lazygit, run
`chezmoi apply` right after. `dots` leaves pulled changes alone, but a file that
changed on both sides needs `chezmoi merge <file>`.

## Tools

`home/dot_config/tools/tools.tsv` lists the tools and the version arch runs. Its
`install` column says how the other machines get each one, by the first word:

| First word | Installed by | Where |
|---|---|---|
| `mise <tool>` | `chezmoi apply`, through mise, pinned to the list's version | every machine but arch; no root needed |
| `apt <package>` | `chezmoi apply`, with sudo; packages the release lacks are skipped | Debian/Ubuntu with sudo; desktop rows only on desktops |
| anything else | you, by hand: `tools-check` shows it as the hint | |

- Keep the fleet in step: after upgrades on arch, `tools-check --record` and `dots`.
  Then `chezmoi update` on another machine installs the new versions.
- mise itself is a chezmoi external in `~/.local/bin/mise`, pinned in
  `home/.chezmoiexternal.toml.tmpl`. To upgrade it, change the version and the two
  checksums (from the release's `SHASUMS256.txt`).
- `~/.config/mise/config.toml` is rendered from the list: edit the list, not the
  config. A tool you install by hand through mise (node, java, jless: their hints)
  goes into `~/.config/mise/conf.d/local.toml`, which mise also reads and chezmoi
  leaves alone: `mise use -p ~/.config/mise/conf.d/local.toml TOOL@VERSION`.
  `mise use -g` would write into the rendered config.
- The tools run through mise's shims (`~/.local/share/mise/shims`); `.profile` and
  fish's `conf.d/path.fish` put them on PATH.
- fish plugins: `~/.config/fish/fish_plugins` is installed with fisher, and again
  whenever the list changes.
- nvim: `apply` also installs its plugins (at `lazy-lock.json`'s commits), treesitter
  parsers and mason tools, headless, so nvim's first start has nothing left to do.
  It runs again when the lock or those lists change; its log is
  `~/.local/state/nvim/install.log`. The parsers need `cc`, some mason tools `unzip`
  or Python's venv (all apt rows), others npm, and Copilot node (a hand install, see
  above). nvim leaves out what a machine can't build, without errors.
- arch installs its tools with pacman, so none of this runs there.

## Per-machine differences

In order of preference:

1. **Existence check in the config itself**, e.g. `if [ -d … ]` in `.profile`,
   `isdirectory()` in nvim. It works everywhere and needs no chezmoi logic.
2. **Machine data** in a template (`*.tmpl`) or in `.chezmoiignore`: the prompt answers
   (`.desktop`, `.personal`) or detected facts (`.chezmoi.osRelease.id`, hostname).
   Example: the i3 autostart starts the polkit agent on Arch only.
3. **Files an app rewrites** (`btop.conf`, kitty `theme.conf`, polybar's
   `colors.ini`) get the `create_` prefix: written once, then owned by the app. A
   seed is also the way when a config can't start without its include (polybar).
4. **A file the machine owns, with one managed part**: a `modify_` script gets the
   live file on stdin and prints the new one. `~/.ssh/config` keeps its own hosts;
   the script keeps the dotfiles' Include block at its end. Claude Code's
   `settings.json` keeps each machine's theme; a modify-template (no script, no jq)
   sets the keys every machine shares, like the status line.
5. **State a script writes** stays untracked and is included by a tracked config:
   `theme-switcher` writes `tmux/theme.conf` and `i3/colors` (both skip a missing
   include). dunst reads drop-ins from `dunstrc.d/`: `theme-switcher` writes the dark
   colors there, `dunst-place` the offset that keeps notifications on the primary
   monitor inside FILM.
6. **Secrets**: `chezmoi add --encrypt`.

`re-add` (and so `dots`) skips templates. Edit those with `vd`, or bring a live edit
over with `chezmoi merge`.

## Layout

- `home/` is the source state (see `.chezmoiroot`). The names encode attributes:
  - `dot_` → `.`
  - `executable_`
  - `private_` (0600 / 0700)
  - `encrypted_*.age`
  - `create_`
  - `modify_`
  - `*.tmpl`
- `home/.chezmoi.toml.tmpl`: the prompts and the age settings
- `home/.chezmoiignore`: what each kind of machine skips
- `home/.chezmoiexternal.toml.tmpl`: tmux's status bar plugin, yazi's piper
  previewer, and off arch btop's theme and mise
- `home/dot_config/tools/tools.tsv`: the tool list behind `tools-check` and the
  installs
- `home/.chezmoitemplates/tools.json`: the list parsed, for the templates that install
- `home/run_onchange_after_*`: install scripts; chezmoi runs one again when its input
  changes
- `home/run_once_before_10-nvim-old-aside.sh`: once per machine, before the new nvim
  config is written: backs up the old one to `*.bak-<time>`, removes the files the new
  one doesn't have, and moves the old plugins and state aside
- `tests/`:
  - `sh tests/tools-check.sh`
  - `sh tests/render.sh`: the templates that read the tool list
  - `sh tests/ssh-config.sh`: the `~/.ssh/config` block and the override order
  - `sh tests/dots.sh`: the fish function `dots` in a scratch home
  - `sh tests/dunst-place.sh`: the notification offset for a few desks
  - `sh tests/lock.sh`: the lock script (dunst paused, xss-lock's sleep lock)
  - `sh tests/brightness.sh`: levels, the bus cache, parallel writes, merged presses
  - `sh tests/nvim-old-aside.sh`: the move of the old nvim config in a scratch home,
    and a chezmoi round trip (old config, then the new one, without a TTY)
  - `sh tests/guest.sh [IMAGE]`: guest install, a visit, remove; the home must match
    the one before
  - `sh tests/fresh-machine.sh [IMAGE…]`: applies this source as a user with sudo in
    clean Ubuntu containers, then checks the shell, the tools and nvim's first start
    (docker; default `ubuntu:20.04`, `24.04` and `26.04`)
  - `sh tests/nvim-start.sh [FILE]`: starts nvim in a scratch tmux and prints the
    prompts, errors and installs it reports (used by fresh-machine)
  - `sh tests/nvim-langmap.sh [--write]`: nvim's Russian langmap against the XKB
    layouts (`--write` regenerates it)
  - `sh tests/nvim-bench.sh [FILE]`: nvim's startup to the first screen in a scratch
    tmux, empty and with a file, against the budget (60 / 120 ms)
  - `sh tests/nvim-keys.sh`: nvim's own keys in a scratch tmux: the Russian layout
    (leader keys through which-key's popup, twins like `ъс` = `]c`), the review and
    window modes, the scratch tab
  - `sh tests/nvim-lang.sh [NAME…]`: every language of nvim's `lang/` on a sample
    file: its servers attach, it's highlighted
  - `sh tests/nvim-documents.sh`: nvim's documents module on a sample of each format
    (and the files it must leave alone)
  - `sh tests/nvim-notebook.sh`: nvim's notebooks in a scratch tmux: a uv project's
    kernel, saved outputs back, running cells, outputs saved
  - `sh tests/sandbox.sh [IMAGE]`: a fresh machine to try by hand, the same install
    as fresh-machine, then a shell in it (default `ubuntu:26.04`)

## Moving a machine off the old bare repo

Until 2026-09 these files lived in the bare repos `~/.dotfiles` and `~/.secrets`, with
`$HOME` as the work tree. To switch a machine over (every block works in fish and in
bash; keep the output):

1. What the machine is (read-only):
   ```sh
   sh -c '
   v() { command -v "$1" >/dev/null && "$@" 2>&1 | head -n 1 || echo -; }
   . /etc/os-release
   echo "host:    $(hostname)"
   echo "os:      $PRETTY_NAME ($(uname -m))"
   echo "glibc:   $(ldd --version 2>&1 | head -n 1 | grep -oE "[0-9]+[.][0-9]+$")"
   grep -qi microsoft /proc/version && echo "wsl:     yes" || echo "wsl:     no"
   echo "shell:   $SHELL"
   echo "groups:  $(id -Gn)"
   echo "i3:      $(v i3 --version)"
   echo "fish:    $(v fish --version)"
   echo "tmux:    $(v tmux -V)"
   echo "git:     $(v git --version)"
   echo "nvim:    $(v nvim --version)"
   curl -fsSI https://github.com >/dev/null 2>&1 && echo "github:  ok" || echo "github:  blocked"
   for r in .dotfiles .secrets; do
       [ -d "$HOME/$r" ] && echo "$r: $(git --git-dir="$HOME/$r" --work-tree="$HOME" status --porcelain -uno | wc -l) changed"
   done
   true
   '
   ```
2. If `shell:` is a fish older than 4 (Ubuntu 20.04's apt has 3.1), make bash the
   login shell. Its `.bashrc` then hands over to mise's fish:
   ```sh
   chsh -s /bin/bash
   ```
3. Save the old repos' local changes, and move a tpm checkout that points into them
   aside:
   ```sh
   sh -c 'cd ~ && for r in .dotfiles .secrets; do [ -d $r ] && git --git-dir=$HOME/$r --work-tree=$HOME diff > ~/$r-local.patch; done; [ -f ~/.tmux/plugins/tpm/.git ] && mv ~/.tmux/plugins/tpm ~/.tmux/plugins/tpm.old; true'
   ```
4. Own machine with secrets only: copy the age key (see [The age key](#the-age-key-own-machines-only)).
5. Install chezmoi and fetch the source without applying. Answer "Own machine
   (secrets)" yes only with the key from step 4:
   ```sh
   sh -c 'sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init SappyJoy'
   ~/.local/bin/chezmoi diff
   ```
   Compare with `~/.dotfiles-local.patch` and carry wanted local bits into the source
   ([rules above](#per-machine-differences)). `~/.ssh/config` only gets a block at
   its end; its hosts stay (on an own machine, the personal hosts can go from it:
   `personal.conf` has them).
6. Apply. mise installs the tools (a minute or two); on a desktop, sudo asks for the
   apt packages:
   ```sh
   ~/.local/bin/chezmoi apply
   ```
7. Move the old repos aside, open a new terminal or SSH session (it lands in fish 4)
   and check:
   ```sh
   sh -c 'ts=$(date +%Y%m%d-%H%M%S); for r in .dotfiles .secrets; do [ -d ~/$r ] && mv ~/$r ~/$r.bak-$ts; done; true'
   fish --version; tools-check --missing
   ```
