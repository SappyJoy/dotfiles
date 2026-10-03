#!/bin/sh
# Tests for the one-time move of the old nvim config
# (home/run_once_before_10-nvim-old-aside.sh) in a scratch home: what moves, what
# stays, and that it leaves a fresh or new config alone. pgrep is a stub.
# Run: sh tests/nvim-old-aside.sh (offline)

set -u
here=$(cd "$(dirname "$0")" && pwd)
aside=$here/../home/run_once_before_10-nvim-old-aside.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
there() { for f; do [ -e "$f" ] || return 1; done; }
gone() { for f; do [ ! -e "$f" ] || return 1; done; }
has() { printf '%s\n' "$out" | grep -q "$1"; }
hasnt() { ! has "$1"; }
baks() { # baks DIR...: how many *.bak-* dirs each DIR has next to it
    for d; do printf %s "$(ls -d "$d".bak-* 2>/dev/null | wc -l)"; done
}
run() { out=$(sh "$aside"); code=$?; }
quiet() { [ "$code" = 0 ] && [ -z "$out" ]; } # exit 0, no output

mkdir -p "$tmp/bin"
printf '#!/bin/sh\n[ -n "${NVIM_RUNS:-}" ]\n' >"$tmp/bin/pgrep"
chmod +x "$tmp/bin/pgrep"
PATH=$tmp/bin:$PATH
export HOME="$tmp/home"
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME NVIM_RUNS
config=$HOME/.config/nvim data=$HOME/.local/share/nvim state=$HOME/.local/state/nvim

# old: the old config with its plugins, venv, spell file, shada and connections
old() {
    rm -rf "$HOME"
    mkdir -p "$config/lua/sap" "$config/after/ftplugin" "$config/db_ui" \
        "$data/lazy/neorg" "$data/mason/bin" "$data/venv/bin" "$data/site/spell" \
        "$state/shada" "$state/lazy"
    echo 'require("quarto").activate()' >"$config/after/ftplugin/markdown.lua"
    echo '{"name": "db"}' >"$config/db_ui/connections.json"
    touch "$config/lua/sap/options.lua" "$data/venv/bin/python" "$data/.hidden" \
        "$data/site/spell/ru.utf-8.spl" "$state/shada/main.shada" "$state/lazy/state.json"
}

old
run
check "old config: exit 0" [ $code = 0 ]
check "old config: says where it went" has 'moved to \*\.bak-'
check "the config is moved aside" there "$config".bak-*/after/ftplugin/markdown.lua
check "no old file stays in the config" gone "$config/after" "$config/lua"
check "dadbod's connections are copied over" cmp -s "$config/db_ui/connections.json" "$config".bak-*/db_ui/connections.json
check "plugins and mason tools are moved aside" there "$data".bak-*/lazy/neorg "$data".bak-*/mason
check "  hidden files too" there "$data".bak-*/.hidden
check "  nothing else stays (the installer fetches the spell file again)" [ "$(ls -A "$data")" = venv ]
check "the Python venv stays" there "$data/venv/bin/python"
check "the state is moved aside" there "$state".bak-*/lazy/state.json
check "  only shada is copied over" [ "$(cd "$state" && find . -type f)" = ./shada/main.shada ]
check "one backup per dir" [ "$(baks "$config" "$data" "$state")" = 111 ]
check "no running nvim: no restart note" hasnt restart

run
check "a second run: exit 0, silent" quiet
check "  and no new backup" [ "$(baks "$config" "$data" "$state")" = 111 ]

old
rm -rf "$data" "$state" "$config/db_ui"
run
check "old config alone (no data, state, connections): exit 0" [ $code = 0 ]
check "  only the config moves" [ "$(baks "$config" "$data" "$state")" = 100 ]

old
out=$(NVIM_RUNS=1 sh "$aside")
check "a running nvim gets a restart note" has restart

rm -rf "$HOME"
run
check "fresh home: exit 0, silent" quiet
check "  nothing created" gone "$HOME"

mkdir -p "$config/lua/core" "$data/lazy"
run
check "new config: exit 0, silent" quiet
check "  nothing moves" [ "$(baks "$config" "$data" "$state")" = 000 ]

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
