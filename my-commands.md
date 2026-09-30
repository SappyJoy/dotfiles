## Your commands

On arch (step 18, brightness): try $mod+PgUp/PgDn (hold one: presses merge) and
scrolling on the bar's sun. Then the old setup goes: first find the ddccontrol
sudoers rule and paste the output back (Claude writes the removal from it); removing
ddccontrol also takes its AUR `ddccontrol-db-git` (nothing else needs either).

```fish
sudo grep -rn ddccontrol /etc/sudoers /etc/sudoers.d
sudo pacman -Rns ddccontrol
```

On arch (step 17, dunst): try the keys. `$mod+n` closes the newest notification,
`$mod+Shift+n` brings it back, Ctrl+`$mod+n` pauses (a bell on the bar; the second
notification waits) and again resumes (it shows then). A middle click on a
notification with actions opens rofi.

```fish
notify-send 'one' 'close me with $mod+n, bring me back with $mod+Shift+n'
notify-send -u critical 'critical' 'red frame, stays until closed'
```

On arch (VPN, 2026-09-30): sing-box is installed and both profiles are in dotfiles
(done). Now the service and the polkit rule (sudo; WireGuard is already in
NetworkManager), then a round trip. `curl` prints the exit IP: with VLESS on it's the
VLESS server's. The bar shows which tunnel is bright. Paste the output back.

```fish
vpn-setup
toggle-vless; sleep 3; curl -s https://api.ipify.org; echo
systemctl status vless --no-pager | head -5
toggle-wireguard
```

Once VLESS has worked for a while (Claude asks before each): remove Throne
(`sudo pacman -Rns throne-bin`, then `~/.config/Throne` with its old profiles), and
the old 2024 sing-box config `~/.config/sing-box/config.json.bak-20260930-003342`
(world-readable, old credentials). Rotate the WireGuard preshared key when
convenient: this session's output showed it (a Claude mistake); `wg genpsk`, then
set it on the server and in `~/.config/wireguard/vpnconfig.conf` (`vd`), and
re-import (README, VPN).

On arch (step 13): the installs are done (2026-09-29): xss-lock 0.4.0, i3lock-color
2.13.c.5-3 from the AUR (replaced the hand install; pacman needed `--overwrite` for
its binary, PAM file and licence), the stale man page removed, and
`10-extensions.conf` moved aside (`.bak-20260929-030338`; DPMS returns at the next
X start).

The i3 changes are applied (2026-09-29). Log out and in (X restarts with DPMS, i3
starts xss-lock and reads its split config), and try the keys. Ctrl+$mod+l locks (unlock with your password).
Ctrl+$mod+m turns the monitors off; a key wakes them, check FILM is intact.
Ctrl+$mod+s suspends; wake it with a key or the power button, and the lock screen
should be there first. Then check the monitors and a GPU app (e.g. a video in
Firefox). Paste this output back, plus what you saw:

```fish
xdpyinfo -queryExtensions | grep -c DPMS
xset q | grep -A2 DPMS
pgrep -a xss-lock
journalctl -b --since -15min | grep -iE 'nvidia|suspend|resume|PM:' | tail -20
```

On arch (step 12), once, when a logout suits you: the `startx` fallback. Save your
work and log out of i3 ($mod+Shift+u). Then press Ctrl+Alt+F3, log in on the TTY
and run `startx`. In the i3 that comes up, open kitty and run the check below: a
notification should appear, and the user manager should show `DISPLAY=:0`. Leave
with $mod+Shift+u, `exit` the TTY, and log in through ly as usual (Ctrl+Alt+F2 or
F1 if ly isn't shown).

```fish
notify-send 'startx works'
systemctl --user show-environment | grep DISPLAY
```

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
