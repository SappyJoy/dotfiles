#!/bin/bash
# Claude Code on polybar (tail = true): Claude's glyph, spinning like Claude Code's own
# spinner while a session works, then the 5-hour bar from claude-usage.sh. A session
# works while a marker of ~/.claude/busy-hook.sh names a running claude process.
# Prints a line only when it changes; an empty one hides the module (idle, no bar).
here=$(dirname "$(readlink -f "$0")")
busy_dir=${XDG_RUNTIME_DIR:-/tmp}/claude-busy
colors=${XDG_CONFIG_HOME:-$HOME/.config}/polybar/colors.ini
# Claude Code's frames, forward and back, every 120 ms; all from font-1 (DejaVu Sans
# Mono), which has them at one width, so the bar doesn't jitter
frames=(· ✢ ✳ ✶ ✻ ✽ ✽ ✻ ✶ ✳ ✢ ·)
idle=✶

busy() {
    local marker pid comm
    for marker in "$busy_dir"/*; do
        read -r pid 2>/dev/null <"$marker" || continue
        read -r comm 2>/dev/null <"/proc/$pid/comm" && [ "$comm" = claude ] && return 0
    done
    return 1
}

exec {sleeper}<> <(:) # `read -t` on this pipe sleeps without a fork
frame=0 refreshed=0 shown=
while :; do
    printf -v now '%(%s)T' -1
    if ((now - refreshed >= 5)); then
        bar=$(sh "$here/claude-usage.sh")
        primary=$(sed -n 's/^primary *= *//p' "$colors")
        refreshed=$now
    fi
    if busy; then
        working=1 glyph=${frames[frame]} delay=0.12
        frame=$(((frame + 1) % ${#frames[@]}))
    else
        working= glyph=$idle delay=0.5 frame=0
    fi
    line=
    if [ -n "$bar$working" ]; then
        line="%{T2}%{F$primary}$glyph%{F-}%{T-}${bar:+ $bar}"
    fi
    [ "$line" = "$shown" ] || { printf '%s\n' "$line"; shown=$line; }
    read -rt "$delay" -u "$sleeper"
done
