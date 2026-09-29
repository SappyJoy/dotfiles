#!/bin/sh
# Tests for brightness (home/dot_local/bin/executable_brightness): levels, the bus
# cache, parallel writes and merged presses. ddcutil and notify-send are stubs (a
# write takes 0.3 s); nothing reaches the real monitors. Run: sh tests/brightness.sh
# (bash, flock; offline)

set -u
here=$(cd "$(dirname "$0")" && pwd)
script=$here/../home/dot_local/bin/executable_brightness
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
has() { printf '%s\n' "$out" | grep -qF -- "$1"; }
calls() { out=$(cat "$tmp/calls" 2>/dev/null); : >"$tmp/calls"; }
count() { printf '%s\n' "$out" | grep -c -- "$1"; }
now() { date +%s%3N; }

mkdir "$tmp/bin"
# ddcutil: three Dells on buses 6-8 (as `detect --brief` printed them on arch);
# $DEAD names a bus that fails; getvcp reads 40
cat >"$tmp/bin/ddcutil" <<'EOF'
#!/bin/sh
echo "ddcutil $*" >>"$T/calls"
case $1 in
detect)
    for b in 6 7 8; do
        [ "$b" = "${DEAD:-}" ] && [ -n "${GONE:-}" ] && continue
        printf 'Display %s\n   I2C bus:          /dev/i2c-%s\n   Monitor:          DEL:DELL U2412M:X\n\n' "$b" "$b"
    done
    echo 'Failed to find connector name for /dev/i2c-7' >&2 ;;
getvcp) echo 'VCP 10 C 40 100' ;;
setvcp) sleep 0.3; [ "$5" != "${DEAD:-}" ] ;;
esac
EOF
printf '#!/bin/sh\necho "notify-send $*" >>"$T/calls"\n' >"$tmp/bin/notify-send"
chmod +x "$tmp/bin/"*
export T=$tmp XDG_CACHE_HOME=$tmp/cache XDG_RUNTIME_DIR=$tmp/run
mkdir -p "$XDG_RUNTIME_DIR"
PATH=$tmp/bin:$PATH
b() { bash "$script" "$@"; }

b +10
calls
check "first run: finds the buses" [ "$(cat "$tmp/cache/brightness-buses" | tr '\n' ' ')" = '6 7 8 ' ]
check "first run: starts from the first monitor's level" has 'ddcutil getvcp 10 --bus 6 --brief'
check "first run: 40 + 10" [ "$(b)" = 50 ]
check "notification with a bar and a stack tag" has 'notify-send -t 1500 -i display-brightness-symbolic -h string:x-dunst-stack-tag:brightness -h int:value:50 Brightness 50%'
check "every monitor gets it" [ "$(count 'setvcp 10 50 --bus')" = 3 ]

start=$(now); b -20; took=$(( $(now) - start ))
calls
check "the monitors in parallel (0.3 s each)" [ "$took" -lt 800 ]
check "no detect with a cache" [ "$(count 'detect')" = 0 ]
check "down: 50 - 20" [ "$(b)" = 30 ]

b -50; check "stops at 0" [ "$(b)" = 0 ]
b 250; check "stops at 100" [ "$(b)" = 100 ]
b 50; b +010; check "+010 is ten, not octal (8)" [ "$(b)" = 60 ]
b 7; check "set: 7" [ "$(b)" = 7 ]
calls
b 7; calls
check "same level again: no write" [ "$(count setvcp)" = 0 ]
b x 2>/dev/null; check "junk: usage, exit 2" [ $? = 2 ]

# Key repeat: 10 presses at once; the level adds up, the writes merge
b 0; calls
for i in 1 2 3 4 5 6 7 8 9 10; do b +1 & done; wait
calls
check "10 quick presses: level 10" [ "$(b)" = 10 ]
check "10 quick presses: the last write is 10" [ "$(printf '%s\n' "$out" | grep setvcp | tail -1 | cut -d' ' -f4)" = 10 ]
check "10 quick presses: at most 3 rounds of writes" [ "$(count 'setvcp .* --bus 6')" -le 3 ]

# A monitor stops answering: find the buses again, write again
DEAD=8 GONE=1 b 60
calls
check "a failed write: detect again" [ "$(count detect)" = 1 ]
check "a failed write: the rest get it" [ "$(count 'setvcp 10 60 --bus 7')" = 2 ]
check "a failed write: the bus leaves the cache" [ "$(cat "$tmp/cache/brightness-buses" | tr '\n' ' ')" = '6 7 ' ]
DEAD=7 b 61 2>/dev/null
calls
check "still failing: a critical notification" has 'notify-send -u critical Brightness'

# No ddcutil: a notification says so (a PATH without the real one)
mkdir "$tmp/min"
for c in bash cat mkdir flock awk mv head; do ln -s "$(command -v $c)" "$tmp/min/$c"; done
ln -s "$tmp/bin/notify-send" "$tmp/min/notify-send"
PATH=$tmp/min bash "$script" +10 2>/dev/null
check "no ddcutil: exit 1" [ $? = 1 ]
calls
check "no ddcutil: says so" has "ddcutil isn't installed"

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
