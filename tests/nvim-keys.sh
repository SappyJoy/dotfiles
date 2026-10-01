#!/bin/sh
# nvim's own keys in a real UI (a scratch tmux server): the Russian layout (leader keys
# typed fast and with pauses, so through which-key's popup; twins like ъс = ]c), the
# review and window modes, the scratch tab.
# Run: sh tests/nvim-keys.sh
#   NVIM=path/to/nvim (default: nvim on PATH); NVIM_APPNAME picks the config as usual

set -u
nvim=${NVIM:-nvim}
tmp=$(mktemp -d)
tm() { tmux -L nvim-keys -f /dev/null "$@"; }
trap 'tm kill-server 2>/dev/null; rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name ($*)"; fails=$((fails + 1)); fi
}

# a repo with two changed hunks: line 3 changed, line 11 added
repo=$tmp/repo
mkdir -p "$repo" && cd "$repo" && git init -q
printf '# Notes\n\nline one\ntwo\nthree\n\n## Part\n\nmore\nand more\n' >note.md
git add . && git -c user.email=t@t -c user.name=t commit -qm init
printf '# Notes\n\nline one CHANGED\ntwo\nthree\n\n## Part\n\nmore\nand more\nadded\n' >note.md

start() {
    tm kill-server 2>/dev/null
    tm new-session -d -x 160 -y 40 -c "$repo" "$nvim note.md"
    sleep 2.5 # past VeryLazy: which-key, gitsigns and the twins are in
}
keys() { tm send-keys -t 0 "$@"; sleep 0.6; }
screen() { tm capture-pane -p -t 0; }
# probe LUA: the value of a Lua expression in the running nvim
probe() {
    rm -f "$tmp/probe"
    tm send-keys -t 0 Escape
    sleep 0.2 # apart, or the terminal reads Esc + : as Alt+:
    tm send-keys -t 0 ":lua vim.fn.writefile({ tostring($1) }, '$tmp/probe')" Enter
    sleep 0.4
    cat "$tmp/probe" 2>/dev/null
}

start
keys ' ву'
check "Space в у (fast) opens find files" sh -c "tmux -L nvim-keys capture-pane -p -t 0 | grep -q 'Find Files'"
keys C-c

keys ' '
sleep 0.5
keys 'в'
sleep 0.5
keys 'у'
check "Space, в, у with pauses (which-key's popup) opens find files" sh -c "tmux -L nvim-keys capture-pane -p -t 0 | grep -q 'Find Files'"
keys C-c

keys ' Ь'
check "Space Ь opens the review mode (<leader>H)" sh -c "tmux -L nvim-keys capture-pane -p -t 0 | grep -q 'Stage hunk'"
keys Down
check "Down in the review mode goes to the next hunk" [ "$(probe "vim.fn.line('.')")" = 3 ]
keys Escape

keys 'ъс'
check "ъс (]c) goes to the next hunk" [ "$(probe "vim.fn.line('.')")" = 11 ]

keys ' w'
keys v
keys Right
check "<leader>w, v, Right: split and focus right" [ "$(probe "vim.fn.winnr() .. '/' .. vim.fn.winnr('\$')")" = 2/2 ]
keys ' w'
keys q
keys Escape
check "<leader>w, q: closes it" [ "$(probe "vim.fn.winnr('\$')")" = 1 ]

keys C-t
keys i 'scratch text' Escape
keys C-q
check "Ctrl+T scratch tab, Ctrl+Q closes it without asking" [ "$(probe "vim.fn.tabpagenr('\$')")" = 1 ]

check "the file wasn't changed" [ "$(probe 'vim.bo.modified')" = false ]

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
