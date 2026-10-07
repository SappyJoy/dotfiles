#!/bin/sh
# Claude Code's 5-hour limit for polybar: a bar, the percentage used and the time
# until the window resets. Claude Code's status line (~/.claude/statusline-command.sh)
# saves the numbers, one file per account; this shows the account used last. Prints
# nothing before the first one, which hides the module.
dir=${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage
colors=${XDG_CONFIG_HOME:-$HOME/.config}/polybar/colors.ini
cells=10

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

full=$(((pct * cells + 50) / 100))
filled= rest=
i=0
while [ "$i" -lt "$cells" ]; do
    if [ "$i" -lt "$full" ]; then filled="$filled━"; else rest="$rest─"; fi
    i=$((i + 1))
done

# Two digits wide, so the modules to the left don't shift at 10%
printf '%%{F%s}%s%%{F%s}%s%%{F-} %2d%%' "$fill" "$filled" "$track" "$rest" "$pct"
[ -n "$left" ] && printf ' %%{F%s}%s%%{F-}' "$muted" "$left"
echo
