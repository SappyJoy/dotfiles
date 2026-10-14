#!/bin/sh
# Tests for vpn-status (home/dot_local/bin/executable_vpn-status): its verdict in each
# tunnel state. nmcli, systemctl, ip and curl are stubs; nothing leaves the machine.
# Run: sh tests/vpn-status.sh (offline; 1 s)

set -u
here=$(cd "$(dirname "$0")" && pwd)
script=$here/../home/dot_local/bin/executable_vpn-status
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
has() { printf '%s\n' "$out" | grep -qF -- "$1"; }

mkdir "$tmp/bin"
# the state comes from the environment: ACTIVE (the NM profile up), VLESS (set: on),
# ROUTE (the device to Anthropic), LISTED and DIRECT (the address each site sees,
# empty: no answer)
cat >"$tmp/bin/nmcli" <<'EOF'
#!/bin/sh
[ "$5" = "${ACTIVE:-}" ] && echo activated
EOF
printf '#!/bin/sh\n[ -n "${VLESS:-}" ]\n' >"$tmp/bin/systemctl"
printf '#!/bin/sh\necho "$3 dev $ROUTE src 10.8.0.23 uid 1000"\n' >"$tmp/bin/ip"
cat >"$tmp/bin/curl" <<'EOF'
#!/bin/sh
for a; do url=$a; done
case $url in
*openrouter.ai*) ip=$LISTED ;;
*) ip=$DIRECT ;;
esac
[ -n "$ip" ] && printf 'fl=1\nip=%s\nloc=XX\n' "$ip"
EOF
chmod +x "$tmp/bin/"*
PATH=$tmp/bin:$PATH
run() { out=$(env "$@" sh "$script"); code=$?; }
tun=89.110.84.20 home=94.188.60.95

run ACTIVE=vpnclaude ROUTE=vpnconfig LISTED=$tun DIRECT=$home
check "Claude only: ok" [ $code = 0 ]
check "Claude only: names the state" has 'VPN: Claude only'
check "Claude only: shows both addresses" has "openrouter.ai: $tun XX"

run ACTIVE=vpnclaude ROUTE=vpnconfig LISTED=$home DIRECT=$home
check "Claude only, listed name direct: broken" [ $code = 1 ]
check "Claude only, listed name direct: says so" has 'BROKEN: openrouter.ai goes direct'

run ACTIVE=vpnclaude ROUTE=enp6s0 LISTED=$tun DIRECT=$home
check "Anthropic direct: broken" has 'BROKEN: Anthropic goes through enp6s0, not vpnconfig'

run ACTIVE=vpnclaude ROUTE=vpnconfig LISTED= DIRECT=$home
check "no answer: broken" has 'BROKEN: no answer from openrouter.ai'

run ACTIVE=vpnconfig ROUTE=vpnconfig LISTED=$tun DIRECT=$tun
check "full tunnel: ok" [ $code = 0 ]
check "full tunnel: names the state" has 'VPN: WireGuard'

run ACTIVE=vpnconfig ROUTE=vpnconfig LISTED=$tun DIRECT=$home
check "full tunnel, the rest direct: broken" has 'BROKEN: www.cloudflare.com goes direct'

run VLESS=1 ROUTE=vless LISTED=1.2.3.4 DIRECT=1.2.3.4
check "VLESS: ok" [ $code = 0 ]
check "VLESS: names the state" has 'VPN: VLESS'

run ROUTE=enp6s0 LISTED=$home DIRECT=$home
check "nothing up: exit 1" [ $code = 1 ]
check "nothing up: says off" has 'VPN: off'

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
