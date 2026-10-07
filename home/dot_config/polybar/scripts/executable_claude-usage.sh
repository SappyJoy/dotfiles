#!/bin/sh
# Claude Code's 5-hour limit for polybar: a bar with a pace tick, the percentage used
# and the time until the window resets. The tick marks how much of the 5 hours has
# passed: a fill past it means the limit comes before the reset at this rate.
# Claude Code's status line (~/.claude/statusline-command.sh) saves the numbers, one
# file per account; this shows the account used last. Prints nothing before the first
# one, which hides the module.
dir=${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage
colors=${XDG_CONFIG_HOME:-$HOME/.config}/polybar/colors.ini
cells=10
window=18000 # 5 hours

file=$(ls -t "$dir"/* 2>/dev/null | head -n 1)
[ -n "$file" ] && read -r pct reset <"$file" || exit 0

# A window that has reset is empty until the next message starts a new one
now=$(date +%s)
left=
if [ "$reset" -le "$now" ]; then
    pct=0
else
    mins=$(((reset - now) / 60))
    if [ "$mins" -ge 60 ]; then left=$(printf '%dh%02dm' $((mins / 60)) $((mins % 60))); else left="${mins}m"; fi
fi
[ "$pct" -gt 100 ] && pct=100

# Colors from the theme (a label can't use ${colors.x}); red from 80%
color() { sed -n "s/^$1 *= *//p" "$colors"; }
fill=$(color primary)
[ "$pct" -ge 80 ] && fill=$(color alert)
track=$(color disabled)
muted=$(color secondary)
tick_color=$(color foreground)

full=$(((pct * cells + 50) / 100))
tick=-1
if [ -n "$left" ]; then
    tick=$(((window - (reset - now)) * cells / window))
    [ "$tick" -lt 0 ] && tick=0
    [ "$tick" -ge "$cells" ] && tick=$((cells - 1))
fi

# seg COLOR TEXT: add TEXT to the bar, with a color tag only where the color changes
bar= cur=
seg() {
    [ "$1" = "$cur" ] || bar="$bar%{F$1}" cur=$1
    bar="$bar$2"
}
i=0
while [ "$i" -lt "$cells" ]; do
    if [ "$i" -eq "$tick" ]; then
        if [ "$i" -lt "$full" ]; then seg "$tick_color" ┿; else seg "$tick_color" ┼; fi
    elif [ "$i" -lt "$full" ]; then
        seg "$fill" ━
    else
        seg "$track" ─
    fi
    i=$((i + 1))
done

# Two digits wide, so the modules to the left don't shift at 10%
printf '%s%%{F-} %2d%%' "$bar" "$pct"
[ -n "$left" ] && printf ' %%{F%s}%s%%{F-}' "$muted" "$left"
echo
