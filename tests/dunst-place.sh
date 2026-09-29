#!/bin/sh
# Tests for dunst-place (home/dot_local/bin/executable_dunst-place): the drop-in it
# writes for a few desks. xrandr, pgrep and dunstctl are stubs. Run: sh tests/dunst-place.sh
# (offline)

set -u
here=$(cd "$(dirname "$0")" && pwd)
place=$here/../home/dot_local/bin/executable_dunst-place
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}

export XDG_CONFIG_HOME="$tmp/config"
drop=$XDG_CONFIG_HOME/dunst/dunstrc.d/60-place.conf
mkdir -p "$tmp/bin"
# xrandr prints $CURRENT for --current, $MONITORS for --listactivemonitors
cat >"$tmp/bin/xrandr" <<'EOF'
#!/bin/sh
case $1 in --current) printf '%s\n' "$CURRENT" ;; --listactivemonitors) printf '%s\n' "$MONITORS" ;; esac
EOF
printf '#!/bin/sh\n[ -n "${DUNST_RUNS:-}" ]\n' >"$tmp/bin/pgrep"
printf '#!/bin/sh\necho "dunstctl $*" >>"%s/calls"\n' "$tmp" >"$tmp/bin/dunstctl"
chmod +x "$tmp/bin/"*
PATH=$tmp/bin:$PATH
export CURRENT MONITORS

# desk LEFT MIDDLE RIGHT: CURRENT for three portrait monitors, the primary marked
desk() {
    x=0
    CURRENT=$(for out in "$@"; do
        case $out in *'*') p='primary ' out=${out%\*} ;; *) p= ;; esac
        echo "$out connected ${p}1200x1920+$x+0 left (normal left inverted right x axis y axis) 518mm x 324mm"
        x=$((x + 1200))
    done)
}
film=' 0: FILM 3600/972x1920/518+0+0  DP-4 DP-0 DP-2'

desk DP-4 'DP-0*' DP-2
MONITORS="Monitors: 1
$film"
sh "$place"
check "FILM, middle primary: offset past the right monitor" grep -qx '    offset = (1210, 50)' "$drop"

desk 'DP-4*' DP-0 DP-2
sh "$place"
check "FILM, left primary: offset past two monitors" grep -qx '    offset = (2410, 50)' "$drop"

desk DP-4 'DP-0*' DP-2
MONITORS='Monitors: 3
 0: +*DP-0 1200/324x1920/518+1200+0  DP-0
 1: +DP-4 1200/324x1920/518+0+0  DP-4
 2: +DP-2 1200/324x1920/518+2400+0  DP-2'
sh "$place"
check "no FILM: the drop-in goes (the first monitor is the primary)" [ ! -e "$drop" ]

desk DP-4 DP-0 'DP-2*'
MONITORS="Monitors: 1
$film"
sh "$place"
check "FILM, right primary: dunst's own default, no drop-in" [ ! -e "$drop" ]

desk DP-4 DP-0 DP-2
sh "$place"
check "no primary: no drop-in" [ ! -e "$drop" ]

desk DP-4 'DP-0*' DP-2
sh "$place"
check "dunst not running: no reload" [ ! -e "$tmp/calls" ]
DUNST_RUNS=1 sh "$place"
check "dunst running: reloads" grep -qx 'dunstctl reload' "$tmp/calls"

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
