#!/bin/bash

# Deactivate current monitor setup to avoid conflicts
xrandr --output DP-4 --off --output DP-0 --off --output DP-2 --off

# Arrange the 3 monitors in vertical rotation, side-by-side
xrandr \
  --output DP-4 --mode 1920x1200 --pos 0x0 --rotate left \
  --output DP-0 --mode 1920x1200 --pos 1200x0 --rotate left --primary \
  --output DP-2 --mode 1920x1200 --pos 2400x0 --rotate left

# Create a single virtual monitor named "FILM"
xrandr --setmonitor FILM 3600/972x1920/518+0+0 DP-4,DP-0,DP-2

# Reload i3 to recognize the new single monitor layout
i3-msg restart

# --- Launch Polybar ---
# Terminate any existing bars
killall -q polybar
# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

sleep 1
# Launch the single, wide bar for film mode
polybar film &
