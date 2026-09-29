#!/bin/sh
# Tests for the lock script (home/dot_config/i3/executable_lock): dunst paused while
# locked, xss-lock's sleep lock released when the screen is locked (not when it's
# unlocked), SIGTERM passed on. i3lock and dunstctl are stubs; the "screen" stays
# locked for 2 s. Run: sh tests/lock.sh   (bash; offline)

set -u
here=$(cd "$(dirname "$0")" && pwd)
lock=$here/../home/dot_config/i3/executable_lock
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
has() { printf '%s\n' "$out" | grep -qF -- "$1"; }
calls() { out=$(cat "$tmp/calls"); : >"$tmp/calls"; }
now() { date +%s%3N; } # milliseconds

mkdir "$tmp/bin"
# i3lock: --version names i3lock-color's author (not with PLAIN set); a lock closes the sleep lock fd
# at once (like i3lock once the screen is locked), then stays "locked" for 2 s
cat >"$tmp/bin/i3lock" <<'EOF'
#!/bin/bash
[[ $1 == --version && -n ${PLAIN:-} ]] && { echo 'i3lock: version 2.13'; exit; }
[[ $1 == --version ]] && { echo 'i3lock: version 2.13.c.5 © 2021 Raymond Li'; exit; }
echo "i3lock $*" >>"$T/calls"
if [[ -n ${XSS_SLEEP_LOCK_FD:-} ]]; then exec {XSS_SLEEP_LOCK_FD}<&-; fi
trap 'echo "i3lock killed" >>"$T/calls"; exit 1' TERM
sleep 2 & wait
echo "i3lock unlocked" >>"$T/calls"
EOF
cat >"$tmp/bin/dunstctl" <<'EOF'
#!/bin/sh
echo "dunstctl $*" >>"$T/calls"
[ "$1" = get-pause-level ] && echo "$LEVEL"
exit 0
EOF
chmod +x "$tmp/bin/"*
export T=$tmp LEVEL=0
PATH=$tmp/bin:$PATH
: >"$tmp/calls"

bash "$lock" --nofork
calls
check "dunst paused before locking" [ "$(printf '%s\n' "$out" | sed -n 2p)" = 'dunstctl set-paused true' ]
check "i3lock-color's look, no fork" has 'i3lock --nofork --insidever-color'
check "dunst's level back after unlocking" [ "$(printf '%s\n' "$out" | tail -2 | tr '\n' '|')" = 'i3lock unlocked|dunstctl set-pause-level 0|' ]

LEVEL=100 bash "$lock"
calls
check "do not disturb stays on after unlocking" has 'dunstctl set-pause-level 100'

PLAIN=1 bash "$lock"
calls
check "plain i3lock: a dark screen" has 'i3lock --nofork --color=0f1419'

# The sleep lock: a fifo whose reader sees EOF when every copy of the fd is closed
# release SCRIPT: milliseconds from the lock's start until the sleep lock is free
release() {
    rm -f "$tmp/fifo"; mkfifo "$tmp/fifo"
    (cat "$tmp/fifo" >/dev/null; now >"$tmp/eof") &
    start=$(now)
    XSS_SLEEP_LOCK_FD=9 bash "$1" --nofork 9>"$tmp/fifo"
    wait
    echo $(( $(cat "$tmp/eof") - start ))
}
check "sleep lock free once locked, not after unlocking" [ "$(release "$lock")" -lt 1000 ]
grep -v 'exec {XSS_SLEEP_LOCK_FD}<&-' "$lock" >"$tmp/lock-keeps-fd"
check "control: a script keeping its copy holds the suspend" [ "$(release "$tmp/lock-keeps-fd")" -ge 2000 ]
: >"$tmp/calls"

bash "$lock" & pid=$!
sleep 0.5; kill "$pid"; wait "$pid"
sleep 0.2
calls
check "SIGTERM ends i3lock too" has 'i3lock killed'
check "SIGTERM: dunst resumes" has 'dunstctl set-pause-level 0'

# no dunst: dunstctl fails (a stub, so the real one never reaches a running dunst)
printf '#!/bin/sh\nexit 1\n' >"$tmp/bin/dunstctl"
bash "$lock" --nofork
calls
check "no dunst: plain lock" [ "$(printf '%s\n' "$out" | head -1 | cut -c1-35)" = 'i3lock --insidever-color=#ffffff22 ' ]

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
