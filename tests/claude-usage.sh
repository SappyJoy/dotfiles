#!/bin/sh
# Tests for Claude Code's 5-hour limit on the bar: the status line
# (home/dot_claude/statusline-command.sh) saves the window per account, and polybar's
# script (home/dot_config/polybar/scripts/executable_claude-usage.sh) draws it.
# Run: sh tests/claude-usage.sh (offline; needs bash and jq)

set -u
here=$(cd "$(dirname "$0")" && pwd)
statusline=$here/../home/dot_claude/statusline-command.sh
bar=$here/../home/dot_config/polybar/scripts/executable_claude-usage.sh
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}

export XDG_CACHE_HOME="$tmp/cache" XDG_CONFIG_HOME="$tmp/config"
export CLAUDE_CONFIG_DIR="$tmp/.claude-personal"
usage=$XDG_CACHE_HOME/claude-usage
now=$(date +%s)
reset=$((now + 2 * 3600 + 5 * 60 + 30))

# status [PERCENT RESETS_AT]: run the status line, with a 5-hour window if given
status() {
    if [ $# -eq 2 ]; then
        limits=", \"rate_limits\": {\"five_hour\": {\"used_percentage\": $1, \"resets_at\": $2}}"
    else
        limits=
    fi
    printf '{"workspace": {"current_dir": "%s"}, "model": {"display_name": "Opus"}%s}' \
        "$tmp" "$limits" | bash "$statusline"
}
saved() { [ "$(cat "$usage/$1" 2>/dev/null)" = "$2" ]; } # saved ACCOUNT CONTENT

status >/dev/null
check "no rate limits: nothing saved" [ ! -e "$usage" ]

out=$(status 23.5 "$reset")
check "saves the rounded percentage, per account" saved claude-personal "24 $reset"
check "the status line still shows the exact percentage" \
    sh -c 'case $1 in *"5h 23.5%"*) ;; *) exit 1 ;; esac' - "$out"

status 10 "$reset" >/dev/null
check "same window, lower (an idle session): kept" saved claude-personal "24 $reset"
status 42 $((reset + 30)) >/dev/null
check "same window, higher: saved" saved claude-personal "42 $((reset + 30))"
status 5 $((reset - 3600)) >/dev/null
check "an older window: ignored" saved claude-personal "42 $((reset + 30))"
status 3 $((reset + 5 * 3600)) >/dev/null
check "a newer window, lower: replaces" saved claude-personal "3 $((reset + 5 * 3600))"
CLAUDE_CONFIG_DIR= status 7 "$reset" >/dev/null
check "no CLAUDE_CONFIG_DIR: the default account's file" saved claude "7 $reset"

# The bar
mkdir -p "$XDG_CONFIG_HOME/polybar"
printf '[colors]\nforeground = #5C6A72\nprimary = #FF9940\nsecondary = #8295A6\nalert = #F07178\ndisabled = #ABB0B6\n' \
    >"$XDG_CONFIG_HOME/polybar/colors.ini"
draws() { [ "$(sh "$bar")" = "$1" ]; } # draws EXPECTED

rm -rf "$usage"
check "no saved window: prints nothing" draws ''

mkdir -p "$usage"
# The window above has 2h05m left: 58% of it passed, so the tick sits in cell 6 of 10
echo "42 $reset" >"$usage/claude-personal"
check "42%: 4 of 10 cells, the tick past them, the time to the reset" \
    draws "%{F#FF9940}━━━━%{F#ABB0B6}━%{F#5C6A72}┿%{F#ABB0B6}━━━━%{F-} 42% %{F#8295A6}2h05m%{F-}"

echo "74 $((now + 4 * 3600 + 8 * 60 + 30))" >"$usage/claude-personal"
check "74% after 17% of the window: the tick on the fill" \
    draws "%{F#FF9940}━%{F#5C6A72}┿%{F#FF9940}━━━━━%{F#ABB0B6}━━━%{F-} 74% %{F#8295A6}4h08m%{F-}"

echo "85 $((now + 630))" >"$usage/claude-personal"
check "85%: red, the tick in the last cell, minutes only under an hour" \
    draws "%{F#F07178}━━━━━━━━━%{F#5C6A72}┿%{F-} 85% %{F#8295A6}10m%{F-}"

echo "100 $reset" >"$usage/claude-personal"
check "100%: all cells" \
    draws "%{F#F07178}━━━━━%{F#5C6A72}┿%{F#F07178}━━━━%{F-} 100% %{F#8295A6}2h05m%{F-}"

echo "64 $((now - 10))" >"$usage/claude-personal"
check "the window has reset: empty, no tick, no time" draws "%{F#ABB0B6}━━━━━━━━━━%{F-}  0%"

echo "30 $reset" >"$usage/claude"
touch -d '1 minute ago' "$usage/claude-personal"
check "two accounts: the one used last" \
    draws "%{F#FF9940}━━━%{F#ABB0B6}━━%{F#5C6A72}┿%{F#ABB0B6}━━━━%{F-} 30% %{F#8295A6}2h05m%{F-}"

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
