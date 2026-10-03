#!/bin/sh
# Once, before the new nvim config is written, on a machine that still has the old
# one (its lua/sap/): its plugins and state move aside, and its config loses the files
# the new one doesn't have. chezmoi never deletes a file it stopped tracking, and
# some old ones load by themselves (an after/ftplugin that needs quarto,
# lua/plugins/neorg.lua). The files both have stay for chezmoi to update: one it
# wrote and finds gone, it asks about ("has changed since chezmoi last wrote it").
# Nothing is lost: the whole old config is copied to *.bak-<time> first. Kept: the
# Python venv (run_onchange_after_27), shada, dadbod's connections.
# Drop this script (and tests/nvim-old-aside.sh) once every machine has the new one.
set -eu
config=$HOME/.config/nvim
[ -d "$config/lua/sap" ] || exit 0
new=${CHEZMOI_SOURCE_DIR:?run by chezmoi}/dot_config/nvim
data=${XDG_DATA_HOME:-$HOME/.local/share}/nvim
state=${XDG_STATE_HOME:-$HOME/.local/state}/nvim
bak=.bak-$(date +%Y%m%d-%H%M%S)

# kept: dadbod's connections and what the new config has. Its source uses no chezmoi
# prefixes, so a target's source has its name; a dot file there is git's, not a target.
keep() {
    [ "$1" = db_ui/connections.json ] && return 0
    case /$1 in */.*) return 1 ;; esac
    [ -e "$new/$1" ]
}
cp -a "$config" "$config$bak"
(cd "$config" && find . -type f -o -type l) | while IFS= read -r f; do
    f=${f#./}
    keep "$f" || rm "$config/$f"
done
# then the old-only dirs that are empty now (a dir chezmoi wrote, it asks about too)
(cd "$config" && find . -mindepth 1 -depth -type d) | while IFS= read -r d; do
    d=${d#./}
    keep "$d" || rmdir "$config/$d" 2>/dev/null || true
done
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
echo "nvim: the old config, plugins and state are in *$bak; the new config replaces them"
if command -v pgrep >/dev/null 2>&1 && pgrep -u "$(id -u)" -x nvim >/dev/null; then
    echo "nvim: an nvim is still running the old config: restart it"
fi
