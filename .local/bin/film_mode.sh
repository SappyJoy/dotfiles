#!/bin/bash
# FILM: one virtual RandR monitor spanning all monitors, so i3 treats the whole desk
# as a single output. This script only adds or removes FILM; the physical layout
# comes from X (xorg.conf / autorandr).
#
#   film_mode.sh on      span FILM over the current monitors (again, if already on)
#   film_mode.sh off     remove FILM
#   film_mode.sh toggle
#
# i3 only notices a monitor change on restart. The workspace assignments are
# written first, so the restarted i3 puts every workspace on its monitor, and its
# exec_always lines relaunch the bars.
set -e

film_on() {
    # "on" rebuilds FILM from the physical monitors, e.g. after a hotplug.
    xrandr --delmonitor FILM >/dev/null 2>&1 || true
    # One "x y width mm height mm outputs" line per monitor, left to right.
    # xrandr lines look like " 1: +DP-4 1200/324x1920/518+0+0  DP-4"
    local monitors geometry outputs
    monitors=$(xrandr --listactivemonitors | awk 'NR > 1 {
        split($3, g, /[\/x+]/)
        # RandR keeps the millimetres of a rotated monitor unrotated: swap them back.
        if ((g[1] > g[3]) != (g[2] > g[4])) { t = g[2]; g[2] = g[4]; g[4] = t }
        out = $4; for (i = 5; i <= NF; i++) out = out "," $i
        print g[5], g[6], g[1], g[2], g[3], g[4], out
    }' | sort -k1,1n -k2,2n)
    # FILM = their bounding box, with the millimetres scaled from the first monitor.
    geometry=$(awk 'NR == 1 { x0 = $1; y0 = $2; x1 = $1 + $3; y1 = $2 + $5; mx = $4 / $3; my = $6 / $5 }
        { if ($1 < x0) x0 = $1; if ($2 < y0) y0 = $2
          if ($1 + $3 > x1) x1 = $1 + $3; if ($2 + $5 > y1) y1 = $2 + $5 }
        END { w = x1 - x0; h = y1 - y0
              printf "%d/%dx%d/%d+%d+%d\n", w, w * mx + 0.5, h, h * my + 0.5, x0, y0 }' <<<"$monitors")
    outputs=$(awk '{ print $7 }' <<<"$monitors" | paste -sd,)
    xrandr --setmonitor FILM "$geometry" "$outputs" >/dev/null
}

is_on() { "$HOME/.local/bin/i3-outputs" | grep -qx FILM; }

focused=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')

case $1 in
    on) film_on ;;
    off) is_on && xrandr --delmonitor FILM || true ;;
    toggle) if is_on; then xrandr --delmonitor FILM; else film_on; fi ;;
    *) echo "usage: film_mode.sh on|off|toggle" >&2; exit 2 ;;
esac

"$HOME/.config/i3/dynamic_workspaces.sh" --no-reload
# i3-msg gets the reply from the restarted i3, so it is ready right after this.
i3-msg -q restart
# The restart focuses the primary monitor; bring back the workspace that had focus.
if [[ -n $focused ]]; then i3-msg -q "workspace \"$focused\""; fi
