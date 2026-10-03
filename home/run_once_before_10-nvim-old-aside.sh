#!/bin/sh
# Once, before the new nvim config is written: a machine that still has the old one
# (its lua/sap/) gets it moved aside with its plugins and state. chezmoi never
# deletes a file it stopped tracking, and some old ones load by themselves (an
# after/ftplugin that needs quarto, lua/plugins/neorg.lua). Moves, not deletes:
# everything lands in *.bak-<time>. Kept in place or copied over: the Python venv
# (run_onchange_after_27), command history and marks (shada), dadbod's connections.
# Drop this script (and tests/nvim-old-aside.sh) once every machine has the new one.
set -eu
config=$HOME/.config/nvim
[ -d "$config/lua/sap" ] || exit 0
data=${XDG_DATA_HOME:-$HOME/.local/share}/nvim
state=${XDG_STATE_HOME:-$HOME/.local/state}/nvim
bak=.bak-$(date +%Y%m%d-%H%M%S)

mv "$config" "$config$bak"
if [ -f "$config$bak/db_ui/connections.json" ]; then
    mkdir -p "$config/db_ui"
    cp -p "$config$bak/db_ui/connections.json" "$config/db_ui/"
fi
if [ -d "$data" ]; then
    mkdir "$data$bak"
    for f in "$data"/* "$data"/.[!.]*; do
        if [ -e "$f" ] && [ "${f##*/}" != venv ]; then mv "$f" "$data$bak/"; fi
    done
fi
if [ -d "$state" ]; then
    mv "$state" "$state$bak"
    if [ -f "$state$bak/shada/main.shada" ]; then
        mkdir -p "$state/shada"
        cp -p "$state$bak/shada/main.shada" "$state/shada/"
    fi
fi
echo "nvim: the old config, plugins and state moved to *$bak"
if command -v pgrep >/dev/null 2>&1 && pgrep -u "$(id -u)" -x nvim >/dev/null; then
    echo "nvim: an nvim is still running the old config: restart it"
fi
