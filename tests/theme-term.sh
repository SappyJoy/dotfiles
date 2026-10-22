#!/bin/sh
# Tests for theme-term (home/dot_local/bin/executable_theme-term): it writes the
# state file, tmux's accent and delta's include, and switches a running nvim. A
# scratch HOME, tmux dir and runtime dir keep it off the live tmux and nvims; the
# nvim is headless, starts light, with stub ayu colorschemes.
# Run: sh tests/theme-term.sh (offline; needs nvim)

set -u
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
mkdir -p "$tmp/home/.config/nvim" "$tmp/home/.config/tmux" "$tmp/home/.config/git" \
    "$tmp/run" "$tmp/tmux" "$tmp/rt/colors"
echo 'let g:colors_name = "ayu-light" | set background=light' > "$tmp/rt/colors/ayu-light.vim"
echo 'let g:colors_name = "ayu-mirage" | set background=dark' > "$tmp/rt/colors/ayu-mirage.vim"
sock=$tmp/run/nvim.1.0
nvim --headless -u NONE -i NONE --cmd "set rtp^=$tmp/rt" -c "colorscheme ayu-light" --listen "$sock" &
nvim_pid=$!
trap 'kill $nvim_pid 2>/dev/null; rm -rf "$tmp"' EXIT

fail=0
check() { # name, expected, actual
    if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: want '$2', got '$3'"; fail=1; fi
}
# a mise shim finds no nvim under the scratch HOME: put the real binary first
real_nvim=$(mise which nvim 2>/dev/null || command -v nvim)
run() {
    PATH=$(dirname "$real_nvim"):$PATH HOME=$tmp/home XDG_RUNTIME_DIR=$tmp/run TMUX_TMPDIR=$tmp/tmux \
        bash "$here/../home/dot_local/bin/executable_theme-term" "$1"
}
background() { # waits for theme-term's background nvim call to land
    i=0
    while [ $i -lt 20 ]; do
        bg=$(nvim --server "$sock" --remote-expr '&background' 2>/dev/null)
        [ "$bg" = "$1" ] && break
        sleep 0.1; i=$((i + 1))
    done
    echo "$bg"
}

while [ ! -S "$sock" ]; do sleep 0.1; done

run dark
check "dark: state file" dark "$(cat "$tmp/home/.config/nvim/.theme_state")"
check "dark: tmux accent" 'set -g @minimal-tmux-bg "#FFCC66"' "$(cat "$tmp/home/.config/tmux/theme.conf")"
check "dark: delta" "dark = true" "$(sed -n 2p "$tmp/home/.config/git/theme.gitconfig" | tr -d '\t')"
check "dark: running nvim" dark "$(background dark)"

run light
check "light: state file" light "$(cat "$tmp/home/.config/nvim/.theme_state")"
check "light: tmux accent" 'set -g @minimal-tmux-bg "#FF9940"' "$(cat "$tmp/home/.config/tmux/theme.conf")"
check "light: delta" "light = true" "$(sed -n 2p "$tmp/home/.config/git/theme.gitconfig" | tr -d '\t')"
check "light: running nvim" light "$(background light)"

out=$(run blue 2>&1); code=$?
check "other modes refused" "1 Usage" "$code ${out%%:*}"

[ $fail = 0 ] && echo "all passed" || exit 1
