#!/bin/sh
# Tests for toggle-wireguard and toggle-vless (home/dot_local/bin/): which profile
# each press brings up or down. nmcli, systemctl and notify-send are stubs; nothing
# reaches NetworkManager or systemd. Run: sh tests/toggle-wireguard.sh (offline; 2 s)

set -u
here=$(cd "$(dirname "$0")" && pwd)
bin=$here/../home/dot_local/bin
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
has() { printf '%s\n' "$out" | grep -qF -- "$1"; }
calls() { out=$(cat "$tmp/calls" 2>/dev/null); : >"$tmp/calls"; }
active() { cat "$tmp/active"; }

mkdir "$tmp/bin"
# nmcli: $T/active names the profile on the device (empty: none); "up" replaces it,
# and fails for a profile named in $MISSING
cat >"$tmp/bin/nmcli" <<'EOF'
#!/bin/sh
echo "nmcli $*" >>"$T/calls"
case "$*" in
'-g GENERAL.STATE connection show '*) [ "$(cat "$T/active")" = "$5" ] && echo activated ;;
'connection up '*) [ "$3" != "${MISSING:-}" ] && echo "$3" >"$T/active" ;;
'connection down '*) [ "$(cat "$T/active")" = "$3" ] && : >"$T/active" ;;
esac
EOF
# systemctl: vless runs while $T/vless exists
cat >"$tmp/bin/systemctl" <<'EOF'
#!/bin/sh
echo "systemctl $*" >>"$T/calls"
case $1 in
is-active) [ -e "$T/vless" ] ;;
start) : >"$T/vless" ;;
stop) rm -f "$T/vless" ;;
esac
EOF
printf '#!/bin/sh\necho "notify-send $*" >>"$T/calls"\n' >"$tmp/bin/notify-send"
chmod +x "$tmp/bin/"*
export T=$tmp
PATH=$tmp/bin:$PATH
wg() { sh "$bin/executable_toggle-wireguard"; }
vless() { sh "$bin/executable_toggle-vless"; }

echo vpnconfig >"$tmp/active"
wg; calls
check "full tunnel: a press leaves Claude only" [ "$(active)" = vpnclaude ]
check "full tunnel: says so" has 'notify-send -t 1500 WireGuard Claude only'

wg; calls
check "Claude only: a press brings the full tunnel" [ "$(active)" = vpnconfig ]
check "Claude only: says so" has 'notify-send -t 1500 WireGuard on'

MISSING=vpnclaude wg; calls
check "no Claude-only profile: the full tunnel stays" [ "$(active)" = vpnconfig ]
check "no Claude-only profile: names vpn-setup" has 'vpn-setup'

echo vpnclaude >"$tmp/active"
vless; calls
check "VLESS on from Claude only: WireGuard goes down" [ -z "$(active)" ]
check "VLESS on: started" [ -e "$tmp/vless" ]

vless; calls
check "VLESS off: stopped" [ ! -e "$tmp/vless" ]
check "VLESS off: back to Claude only" [ "$(active)" = vpnclaude ]

echo vpnconfig >"$tmp/active"
vless; calls
check "VLESS on from the full tunnel: WireGuard goes down" [ -z "$(active)" ]

wg; calls
check "full tunnel from VLESS: VLESS stops" [ ! -e "$tmp/vless" ]
check "full tunnel from VLESS: up" [ "$(active)" = vpnconfig ]

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
