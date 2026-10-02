#!/bin/sh
# nvim's startup time with a real UI (a scratch tmux server): the median of 5 starts
# to the first screen, empty and opening FILE (default: a scratch note), with the
# plugins loaded and the slowest steps. Fails over the budget: 60 ms empty, 120 ms
# with a file (Phase 7).
# Run: sh tests/nvim-bench.sh [FILE]
#   NVIM=path/to/nvim (default: nvim on PATH); NVIM_APPNAME picks the config as usual,
#   e.g. NVIM_APPNAME=nvim-next NVIM=~/.local/share/bob/v0.12.5/bin/nvim

set -u
nvim=${NVIM:-nvim}
tmp=$(mktemp -d)
tm() { tmux -L nvim-bench -f /dev/null "$@"; }
trap 'tm kill-server 2>/dev/null; rm -rf "$tmp"' EXIT
fails=0

note=${1:-$tmp/note.md}
[ $# -gt 0 ] || printf -- '---\ntags: [test]\n---\n\n# A note\n\nSome *text*, a [[link]].\n' >"$note"

# A TUI start is two processes, the UI client and the embedded server, each with its
# section in the log; the server's is the one that counts.
embedded() { awk '/process: Embedded/ { e = 1 } e' "$1"; }

# start N LOG [FILE]: nvim in a fresh tmux, until its server says it started, then quit
start() {
    n=$1 log=$2; shift 2
    tm new-session -d -x 200 -y 50 "$nvim --startuptime $log $*"
    i=0
    while ! embedded "$log" 2>/dev/null | grep -q 'NVIM STARTED'; do
        i=$((i + 1))
        [ $i -lt 200 ] || { echo "nvim didn't start: $*"; return 1; }
        sleep 0.05
    done
    if [ "$n" = 5 ]; then # the last run reports what it loaded
        tm send-keys -t 0 Escape ":lua vim.fn.writefile({ tostring(package.loaded.lazy and require('lazy').stats().loaded or 0) }, '$tmp/loaded')" Enter
        sleep 0.5
    fi
    tm kill-server 2>/dev/null
}

# bench NAME BUDGET [FILE]
bench() {
    name=$1 budget=$2; shift 2
    start 0 "$tmp/warm.log" "$@" || { fails=$((fails + 1)); return; } # caches warm
    for n in 1 2 3 4 5; do
        start $n "$tmp/$n.log" "$@" || { fails=$((fails + 1)); return; }
        embedded "$tmp/$n.log" | awk '/NVIM STARTED/ { print $1 }'
    done | sort -n >"$tmp/times"
    ms=$(sed -n 3p "$tmp/times" | cut -d. -f1)
    if [ "$ms" -le "$budget" ]; then status=ok; else status=FAIL; fails=$((fails + 1)); fi
    printf '%-4s %-6s %4s ms (budget %s), %s plugins loaded\n' "$status" "$name" "$ms" "$budget" "$(cat "$tmp/loaded" 2>/dev/null)"
    # the slowest steps of the median run: sourced files and requires, by own time
    log=$(grep -l "^$(sed -n 3p "$tmp/times") " "$tmp"/[1-5].log | head -1)
    embedded "$log" | awk 'NF >= 4 && $3 ~ /:$/ { t = $3; sub(":", "", t); $1 = $2 = $3 = ""; printf "       %6.1f ms %s\n", t, $0 }' |
        sort -rn | head -3
    rm -f "$tmp"/*.log "$tmp/loaded"
}

bench empty "${BUDGET_EMPTY:-60}"
bench note "${BUDGET_FILE:-120}" "$note"

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
