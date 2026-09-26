#!/bin/bash
# FILM: one virtual RandR monitor spanning all physical monitors, so i3 treats the
# whole desk as a single output. (Re)creates it from the current monitors, e.g. at
# login or after a hotplug (autorandr postswitch), then restarts i3, which only
# notices monitor changes on restart, and puts the focus back.
set -e

# Bounding box of the physical monitors (see `monitors`), with its millimetres
# scaled from the first one, and their outputs left to right.
read -r geometry outputs < <("$HOME/.local/bin/monitors" | awk '
    NR == 1 { x0 = $2; y0 = $3; x1 = $2 + $4; y1 = $3 + $5; mx = $6 / $4; my = $7 / $5 }
    { if ($2 < x0) x0 = $2; if ($3 < y0) y0 = $3
      if ($2 + $4 > x1) x1 = $2 + $4; if ($3 + $5 > y1) y1 = $3 + $5
      outputs = outputs (NR > 1 ? "," : "") $1 }
    END { if (!NR) exit 1
          w = x1 - x0; h = y1 - y0
          printf "%d/%dx%d/%d+%d+%d %s\n", w, w * mx + 0.5, h, h * my + 0.5, x0, y0, outputs }')

focused=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')

xrandr --delmonitor FILM >/dev/null 2>&1 || true
xrandr --setmonitor FILM "$geometry" "$outputs" >/dev/null

# i3-msg gets the reply from the restarted i3, so it is ready right after this.
i3-msg -q restart
# The restart focuses the primary monitor; bring back the workspace that had focus.
if [[ -n $focused ]]; then i3-msg -q "workspace \"$focused\""; fi
