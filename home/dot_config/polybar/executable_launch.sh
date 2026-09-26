#!/usr/bin/env bash
# One bar per active monitor (i3-outputs); the primary monitor's bar gets the tray.
# i3 runs this on start and restart; run it by hand after other monitor changes.

killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

primary=$("$HOME/.local/bin/i3-outputs" --primary) || exit 1
for monitor in $("$HOME/.local/bin/i3-outputs"); do
    bar=main
    [[ $monitor == "$primary" ]] && bar=main-primary
    MONITOR=$monitor polybar --reload "$bar" &
done
