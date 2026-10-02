#!/bin/sh
# Start nvim in a terminal (a scratch tmux server) the way a user does, and print what
# it reported: prompts left on the screen, its messages, and notifications that are
# warnings, errors or installs. Prints nothing when the start is clean.
# With FILE, nvim opens it and a line is typed in Insert mode (completion, AI plugins).
# Run: sh tests/nvim-start.sh [FILE]   (needs nvim and tmux on PATH)

set -u
tmp=$(mktemp -d)
sock=$tmp/nvim.sock
tm() { tmux -L nvim-start -f /dev/null "$@"; }
trap 'tm kill-server 2>/dev/null; rm -rf "$tmp"' EXIT

cat >"$tmp/report.lua" <<'EOF'
local lines = {}
for _, l in ipairs(vim.split(vim.fn.execute('messages'), '\n', { trimempty = true })) do
  table.insert(lines, 'message: ' .. l)
end
local ok, notifier = pcall(require, 'snacks.notifier')
for _, n in ipairs(ok and notifier.get_history() or {}) do
  if n.level == 'warn' or n.level == 'error' or n.msg:find('install') then
    table.insert(lines, ('notification (%s): %s'):format(n.level, n.msg))
  end
end
return table.concat(lines, '\n')
EOF

# settle SECONDS: wait, answering (and printing) every prompt that blocks the screen
settle() {
    i=0
    while [ "$i" -lt "$1" ]; do
        sleep 1
        i=$((i + 1))
        screen=$(tm capture-pane -p -t 0 2>/dev/null) || return
        if printf '%s\n' "$screen" | grep -qE -- '-- More --|Press ENTER|Download\? \[y/N\]'; then
            printf '%s\n' "$screen" | grep -v '^[[:space:]~]*$' | sed 's/^/screen: /'
            tm send-keys -t 0 Enter
        fi
    done
}

tm new-session -d -x 200 -y 50 "env TERM=xterm-256color nvim --listen $sock ${1:-}"
settle 15
if [ -n "${1:-}" ]; then
    tm send-keys -t 0 G o 'import o'
    settle 3
    tm send-keys -t 0 Escape
    settle 3
fi
nvim --server "$sock" --remote-expr "luaeval(\"dofile('$tmp/report.lua')\")"
