#!/bin/sh
# Tests for Claude's spinning glyph on the bar: the hook (home/dot_claude/busy-hook.sh)
# marks a session busy or idle, and polybar's loop (home/dot_config/polybar/scripts/
# executable_claude.sh) spins the glyph while a marker names a running claude. A copy
# of sh or sleep named `claude` stands in for Claude Code.
# Run: sh tests/claude-busy.sh (offline; needs bash and jq, takes ~10 s)

set -u
here=$(cd "$(dirname "$0")" && pwd)
hook=$here/../home/dot_claude/busy-hook.sh
scripts=$here/../home/dot_config/polybar/scripts
tmp=$(mktemp -d)
pids=
trap 'kill $pids 2>/dev/null; rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}

export XDG_RUNTIME_DIR="$tmp/run" XDG_CACHE_HOME="$tmp/cache" XDG_CONFIG_HOME="$tmp/config"
busy=$XDG_RUNTIME_DIR/claude-busy
mkdir -p "$tmp/bin" "$XDG_RUNTIME_DIR"
cp "$(command -v sh)" "$tmp/bin/claude"

# from_claude ACTION JSON: run the hook as Claude Code does (claude → sh -c → hook);
# the stand-in claude saves its PID in $tmp/claude.pid
from_claude() {
    printf '%s' "$2" | "$tmp/bin/claude" -c "echo \$\$ >'$tmp/claude.pid'; sh -c 'sh $hook $1'; :"
}
session='{"session_id": "s1", "hook_event_name": "UserPromptSubmit"}'

from_claude on "$session"
check "on: a marker with the claude process's PID" \
    [ "$(cat "$busy/s1" 2>/dev/null)" = "$(cat "$tmp/claude.pid")" ]
from_claude off "$session"
check "off: the marker goes" [ ! -e "$busy/s1" ]
from_claude off "$session"
check "off without a marker: no error" [ $? -eq 0 ]
from_claude on '{"session_id": "s1", "agent_id": "a1", "hook_event_name": "PostToolUse"}'
check "a subagent's hook: ignored" [ ! -e "$busy/s1" ]
printf '%s' "$session" | sh "$hook" on
check "not run by claude: no marker" [ ! -e "$busy/s1" ]

# No tokens: nothing on stdout or stderr, exit 0, even when the marker can't be written
out=$(XDG_RUNTIME_DIR=/proc/nope from_claude on "$session" 2>&1; echo "exit $?")
check "silent and exit 0, even when it fails" [ "$out" = "exit 0" ]
out=$(printf 'not json' | sh "$hook" off 2>&1; echo "exit $?")
check "silent and exit 0 on bad input" [ "$out" = "exit 0" ]

# The loop: copies under the names polybar runs, a theme, a saved 5-hour window
mkdir -p "$tmp/polybar" "$XDG_CONFIG_HOME/polybar" "$XDG_CACHE_HOME/claude-usage"
cp "$scripts/executable_claude.sh" "$tmp/polybar/claude.sh"
cp "$scripts/executable_claude-usage.sh" "$tmp/polybar/claude-usage.sh"
printf '[colors]\nforeground = #5C6A72\nprimary = #FF9940\nsecondary = #8295A6\nalert = #F07178\ndisabled = #ABB0B6\n' \
    >"$XDG_CONFIG_HOME/polybar/colors.ini"
lines() { timeout 1.3 bash "$tmp/polybar/claude.sh"; } # what the loop prints in 1.3 s

rm -rf "$busy"
check "idle, no window yet: nothing" [ -z "$(lines)" ]

echo "42 $(($(date +%s) + 7530))" >"$XDG_CACHE_HOME/claude-usage/claude-personal"
out=$(lines)
check "idle: one line, ✶ and the bar" \
    [ "$out" = "%{T2}%{F#FF9940}✶%{F-}%{T-} $(sh "$tmp/polybar/claude-usage.sh")" ]

mkdir -p "$tmp/bin/c" && cp "$(command -v sleep)" "$tmp/bin/c/claude"
"$tmp/bin/c/claude" 30 & pids="$pids $!"
mkdir -p "$busy" && echo $! >"$busy/s1"
out=$(lines)
check "busy: Claude Code's frames, forward and back (a line per change)" \
    sh -c 'case $(printf "%s\n" "$1" | sed "s/^%{T2}%{F#FF9940}\(.*\)%{F-}%{T-}.*/\1/" | tr -d "\n") in "·✢✳✶✻✽✻✶"*) ;; *) exit 1 ;; esac' - "$out"
check "busy: the bar stays after the glyph" \
    sh -c 'printf "%s\n" "$1" | grep -q "%{T-} %{F#FF9940}━━━━"' - "$out"

rm -f "$XDG_CACHE_HOME/claude-usage/claude-personal"
out=$(lines | head -n 2)
check "busy, no window yet: the glyph alone" [ "$(printf '%s\n' "$out" | head -n 1)" = "%{T2}%{F#FF9940}·%{F-}%{T-}" ]

sleep 30 & pids="$pids $!"
echo $! >"$busy/s1"
check "a marker naming another program: idle" [ -z "$(lines)" ]
echo 999999999 >"$busy/s1"
check "a marker naming a dead process: idle" [ -z "$(lines)" ]

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
