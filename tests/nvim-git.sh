#!/bin/sh
# nvim's git tools (plugins/git.lua, plugins/tools.lua' colors) in a real UI (a
# scratch tmux), in a scratch repo: main, a branch with a commit, a change not
# committed. Each diffview key opens its view in a tab and Ctrl+Q closes it;
# <leader>g opens lazygit in a float; hex colors get their color.
# Needs lazygit. Run: sh tests/nvim-git.sh
#   NVIM=path/to/nvim (default: nvim on PATH); NVIM_APPNAME picks the config as usual

set -u
nvim=${NVIM:-nvim}
tmp=$(mktemp -d)
tm() { tmux -L nvim-git -f /dev/null "$@"; }
trap 'tm kill-server 2>/dev/null; rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name ($*)"; fails=$((fails + 1)); fi
}

mkdir "$tmp/repo" && cd "$tmp/repo" || exit 1
g() { git -c user.name=t -c user.email=t@t -c init.defaultBranch=main "$@"; }
g init -q
printf 'local color = "#e6b450"\nlocal a = 1\nlocal b = 2\n' >theme.lua
g add . && g commit -qm 'first'
g switch -qc feature
printf 'local c = 3\n' >>theme.lua
g commit -qam 'add c'
printf 'local d = 4\n' >>theme.lua

tm new-session -d -x 160 -y 40 -c "$PWD" "sleep 0.5; $nvim theme.lua"
sleep 3
keys() { tm send-keys -t 0 "$@"; sleep 1; }
probe() {
    rm -f "$tmp/probe"
    tm send-keys -t 0 Escape
    sleep 0.2
    tm send-keys -t 0 ":lua vim.fn.writefile({ tostring($1) }, '$tmp/probe')" Enter
    sleep 0.4
    cat "$tmp/probe" 2>/dev/null
}
# view KEYS FILETYPE NAME: KEYS open a tab with a FILETYPE window; Ctrl+Q closes it
view() {
    keys "$1"
    sleep 1
    check "$3: a tab with $2" [ "$(probe "vim.fn.tabpagenr('\$') .. ':' .. #vim.tbl_filter(function(w) return vim.bo[vim.api.nvim_win_get_buf(w)].filetype == '$2' end, vim.api.nvim_tabpage_list_wins(0))")" = 2:1 ]
    keys C-q
    check "  Ctrl+Q closes it" [ "$(probe "vim.fn.tabpagenr('\$') .. vim.fn.expand('%:t')")" = 1theme.lua ]
}

view ' do' DiffviewFiles "<leader>do (changes)"
view ' dm' DiffviewFiles "<leader>dm (branch against main)"
view ' dh' DiffviewFileHistory "<leader>dh (file history)"
view ' dl' DiffviewFileHistory "<leader>dl (line history)"
view ' dc' DiffviewFiles "<leader>dc (the line's commit)"

keys ' g'
sleep 2
check "<leader>g: lazygit in a float" sh -c "tmux -L nvim-git capture-pane -p -t 0 | grep -q 'Local branches'"
keys q
sleep 1
check "  q closes it" [ "$(probe "vim.fn.expand('%:t')")" = theme.lua ]

colored="(function() local n = 0 for name, ns in pairs(vim.api.nvim_get_namespaces()) do if name:find 'colorizer' then n = n + #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) end end return n end)()"
check "a hex color gets its color" [ "$(probe "$colored")" -ge 1 ]

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
