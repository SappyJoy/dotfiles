#!/bin/bash

# Remove the single virtual "FILM" monitor
xrandr --delmonitor FILM

# Restore your original i3wm monitor configuration
xrandr \
  --output DP-4 --mode 1920x1200 --pos 0x360 --rotate left \
  --output DP-0 --mode 1920x1200 --pos 1920x0 --rotate left --primary \
  --output DP-2 --mode 1920x1200 --pos 3120x0 --rotate left

# Reload i3
i3-msg restart

# --- Launch Polybar ---
# Terminate any existing bars
killall -q polybar
# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
sleep 1
# Launch a bar on each of the three monitors
polybar work-left &
polybar work-center &
polybar work-right &
