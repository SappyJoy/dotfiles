#!/bin/sh
# Tests for the one-time move of the old nvim config
# (home/run_once_before_10-nvim-old-aside.sh) in a scratch home: what moves, what
# stays, that it leaves a fresh or new config alone, and a chezmoi round trip (the
# old config applied, then the new one, without a TTY: chezmoi must not ask).
# pgrep is a stub. Run: sh tests/nvim-old-aside.sh (offline; needs chezmoi)

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
run() { out=$(sh "$aside" 2>&1); code=$?; }
quiet() { [ "$code" = 0 ] && [ -z "$out" ]; } # exit 0, no output

mkdir -p "$tmp/bin"
printf '#!/bin/sh\n[ -n "${NVIM_RUNS:-}" ]\n' >"$tmp/bin/pgrep"
chmod +x "$tmp/bin/pgrep"
PATH=$tmp/bin:$PATH
export HOME="$tmp/home"
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME NVIM_RUNS
config=$HOME/.config/nvim data=$HOME/.local/share/nvim state=$HOME/.local/state/nvim

# file PATH [CONTENT]: a file with its dirs
file() { mkdir -p "${1%/*}"; printf '%s\n' "${2:-x}" >"$1"; }

# The sources: the old config and the new one (no chezmoi prefixes inside nvim, a
# .gitignore for git only); both have init.lua, the lock and a dadbod query.
old_src=$tmp/old/home new_src=$tmp/new/home
for f in init.lua lazy-lock.json lua/sap/options.lua lua/plugins/neorg.lua \
    after/ftplugin/markdown.lua 'db_ui/dota_bets/Match Data'; do
    file "$old_src/dot_config/nvim/$f" old
done
file "$old_src/dot_config/nvim/dot_gitignore"
for f in init.lua lazy-lock.json lua/core/options.lua lua/plugins/lsp.lua \
    'db_ui/dota_bets/Match Data' .gitignore; do
    file "$new_src/dot_config/nvim/$f" new
done
cp "$aside" "$new_src/run_once_before_10-nvim-old-aside.sh"
echo home >"$tmp/old/.chezmoiroot"
echo home >"$tmp/new/.chezmoiroot"
export CHEZMOI_SOURCE_DIR="$new_src"

# old: the old config as chezmoi wrote it, plus what nvim made: plugins, a venv, a
# spell file, shada, lazy's state, dadbod's connections
old() {
    rm -rf "$HOME"
    mkdir -p "$HOME/.config"
    cp -r "$old_src/dot_config/nvim" "$config"
    mv "$config/dot_gitignore" "$config/.gitignore"
    file "$config/db_ui/connections.json" '{"name": "db"}'
    for f in lazy/neorg/init.lua mason/bin/x venv/bin/python site/spell/ru.utf-8.spl .hidden; do
        file "$data/$f"
    done
    file "$state/shada/main.shada"
    file "$state/lazy/state.json"
}

old
run
check "old config: exit 0" [ $code = 0 ]
check "old config: says where it went" has 'in \*\.bak-'
check "the whole old config is copied aside" \
    there "$config".bak-*/after/ftplugin/markdown.lua "$config".bak-*/init.lua "$config".bak-*/.gitignore
check "the old-only files leave the config" \
    gone "$config/after" "$config/lua/sap" "$config/lua/plugins/neorg.lua" "$config/.gitignore"
check "  their dirs too" gone "$config/after" "$config/lua/sap"
check "  but not the dirs the new config has (chezmoi wrote them)" there "$config/lua/plugins"
check "the files both have stay, unchanged" \
    [ "$(cat "$config/init.lua" "$config/lazy-lock.json" "$config/db_ui/dota_bets/Match Data")" = "old
old
old" ]
check "dadbod's connections stay" there "$config/db_ui/connections.json"
check "plugins and mason tools are moved aside" there "$data".bak-*/lazy/neorg "$data".bak-*/mason "$data".bak-*/.hidden
check "  nothing but the venv stays" [ "$(ls -A "$data")" = venv ]
check "the state is moved aside" there "$state".bak-*/lazy/state.json
check "  only shada is copied over" [ "$(cd "$state" && find . -type f)" = ./shada/main.shada ]
check "one backup per dir" [ "$(baks "$config" "$data" "$state")" = 111 ]
check "no running nvim: no restart note" hasnt restart

run
check "a second run: exit 0, silent" quiet
check "  and no new backup" [ "$(baks "$config" "$data" "$state")" = 111 ]

old
rm -rf "$data" "$state" "$config/db_ui/connections.json"
run
check "old config alone (no data, state, connections): exit 0" [ $code = 0 ]
check "  only the config is backed up" [ "$(baks "$config" "$data" "$state")" = 100 ]

old
out=$(NVIM_RUNS=1 sh "$aside")
check "a running nvim gets a restart note" has restart

old
out=$(env -u CHEZMOI_SOURCE_DIR sh "$aside" 2>&1)
check "not run by chezmoi: refuses" [ $? != 0 ]
check "  and touches nothing" [ "$(baks "$config" "$data" "$state")" = 000 ]

rm -rf "$HOME"
run
check "fresh home: exit 0, silent" quiet
check "  nothing created" gone "$HOME"

mkdir -p "$config/lua/core" "$data/lazy"
run
check "new config: exit 0, silent" quiet
check "  nothing moves" [ "$(baks "$config" "$data" "$state")" = 000 ]

# chezmoi round trip: apply the old source, then the new one with this script, no TTY
cz() { chezmoi --destination "$HOME" --persistent-state "$tmp/state.boltdb" \
    --config "$tmp/none.toml" --no-tty "$@" </dev/null 2>&1; }
rm -rf "$HOME"
mkdir -p "$HOME"
out=$(cz --source "$tmp/old" apply)
check "chezmoi: the old config applies" [ $? = 0 ]
check "  with its files" there "$config/lua/sap/options.lua" "$config/.gitignore"
file "$config/db_ui/connections.json"
file "$data/lazy/neorg/init.lua"
out=$(cz --source "$tmp/new" apply)
code=$?
[ $code = 0 ] || printf '%s\n' "$out" | sed 's/^/     chezmoi: /'
check "chezmoi: the new config applies without asking" [ $code = 0 ]
check "  no question about a changed file" hasnt 'has changed since chezmoi last wrote it'
check "  the script ran first" has 'in \*\.bak-'
check "  the new files are in" there "$config/lua/core/options.lua" "$config/lua/plugins/lsp.lua"
check "  the old-only ones are out" gone "$config/lua/sap" "$config/after" "$config/.gitignore"
check "  the shared ones are the new version" [ "$(cat "$config/init.lua")" = new ]
out=$(cz --source "$tmp/new" verify)
check "  verify: the home matches the new source" [ $? = 0 ]

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
