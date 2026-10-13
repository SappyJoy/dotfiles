#!/bin/sh
# Tests for vpn-setup (home/dot_local/bin/executable_vpn-setup): the Claude-only
# connection it makes and the system files it writes, in a scratch home. sudo writes
# into a scratch root; nmcli, systemctl, dnsmasq and sing-box are stubs; the nftables
# file is loaded for real, in a network namespace of its own. Run:
# sh tests/vpn-setup.sh (offline; unshare, nft)

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
hasnt() { ! has "$1"; }
calls() { out=$(cat "$tmp/calls" 2>/dev/null); : >"$tmp/calls"; }
line() { printf '%s\n' "$out" | grep -nF -- "$1" | head -1 | cut -d: -f1; }

mkdir -p "$tmp/bin" "$tmp/root" "$tmp/.config/wireguard"
# sudo: cmp and install go to the scratch root; the rest is only noted
cat >"$tmp/bin/sudo" <<'EOF'
#!/bin/sh
echo "sudo $*" >>"$T/calls"
case $1 in
cmp) cmp -s "$3" "$T/root$4" ;;
install) mkdir -p "$(dirname "$T/root$6")" && cp "$5" "$T/root$6" ;;
esac
EOF
# nmcli: $T/conns lists the connections, $T/active names the one on the device; an
# import keeps the file and adds the connection named after it
cat >"$tmp/bin/nmcli" <<'EOF'
#!/bin/sh
echo "nmcli $*" >>"$T/calls"
case "$*" in
'-g NAME connection show'*) cat "$T/conns" ;;
'connection import type wireguard file '*)
    cp "$6" "$T/imported.conf"; basename "$6" .conf >>"$T/conns" ;;
'-g ipv4.routing-rules connection show vpnconfig') echo 'priority 30000 from 0.0.0.0/0 ipproto 6 sport 22 table 254' ;;
'-g GENERAL.CONNECTION device show vpnconfig') cat "$T/active" ;;
esac
EOF
printf '#!/bin/sh\necho "systemctl $*" >>"$T/calls"\n' >"$tmp/bin/systemctl"
printf '#!/bin/sh\necho "dnsmasq $*" >>"$T/calls"\n[ -z "${REJECT:-}" ]\n' >"$tmp/bin/dnsmasq"
printf '#!/bin/sh\n' >"$tmp/bin/sing-box"
chmod +x "$tmp/bin/"*
printf '#!/bin/sh\nexec sh "%s" "$@"\n' "$bin/executable_vpn-hosts" >"$tmp/bin/vpn-hosts"
chmod +x "$tmp/bin/vpn-hosts"
printf '160.79.104.0/23  # Anthropic\nopenrouter.ai\n' >"$tmp/.config/wireguard/claude-only.list"
# a profile shaped like the tracked one: escaped colons, a DNS line, both families
cat >"$tmp/.config/wireguard/vpnconfig.conf" <<'EOF'
[Interface]
PrivateKey = AAAA
Address = 10.8.0.23/24
DNS = 8.8.8.8, 1.1.1.1

[Peer]
PublicKey = BBBB
AllowedIPs = 0.0.0.0/0, \:\:/0
Endpoint = 192.0.2.1\:51820
EOF
export T=$tmp HOME=$tmp
PATH=$tmp/bin:$PATH
echo vpnconfig >"$tmp/conns"
: >"$tmp/active"
setup() { log=$(sh "$bin/executable_vpn-setup" 2>&1); rc=$?; calls; }
etc=$tmp/root/etc

setup
check "first run: exit 0" [ $rc = 0 ]
conf=$(cat "$tmp/imported.conf")
check "profile: any address may enter the tunnel" [ "$(printf '%s\n' "$conf" | grep AllowedIPs)" = 'AllowedIPs = 0.0.0.0/0' ]
check "profile: no routes from the import" [ "$(printf '%s\n' "$conf" | sed -n 2p)" = 'Table = off' ]
check "profile: no DNS" [ -z "$(printf '%s\n' "$conf" | grep DNS)" ]
check "profile: colons unescaped" [ "$(printf '%s\n' "$conf" | grep Endpoint)" = 'Endpoint = 192.0.2.1:51820' ]
check "connection: on the device vpnconfig, no peer routes" has 'connection modify vpnclaude connection.interface-name vpnconfig wireguard.peer-routes no'
check "connection: the mark and a bound socket use table 5353" has 'priority 20000 fwmark 0x14e9 table 5353, priority 20001 oif vpnconfig table 5353'
check "connection: Anthropic's range and the table's default route" has 'connection modify vpnclaude ipv4.routes 160.79.104.0/23,0.0.0.0/0 table=5353'
check "the full tunnel no longer starts at boot" has 'connection modify vpnconfig connection.autoconnect no'
check "not running: no reapply" hasnt 'device reapply'
check "names: openrouter.ai fills the set" grep -qx 'nftset=/openrouter.ai/4#inet#tunnel_names#v4' "$etc/NetworkManager/dnsmasq.d/tunnel-names.conf"
check "names: dnsmasq checked the file first" [ "$(line 'dnsmasq --test')" -lt "$(line '/etc/tunnel-names.nft')" ]
check "names: dnsmasq is the resolver" grep -qx 'dns=dnsmasq' "$etc/NetworkManager/conf.d/dns-dnsmasq.conf"
check "names: the set exists before dnsmasq restarts" [ "$(line 'systemctl enable -q --now tunnel-names.service')" -lt "$(line 'nmcli general reload dns-full')" ]
# loaded twice with an address learned in between, as a reload of the running table
table=$(unshare -rn sh -c "nft -f $etc/tunnel-names.nft && nft add element inet tunnel_names v4 '{ 192.0.2.7 }' && nft -f $etc/tunnel-names.nft && nft list table inet tunnel_names")
check "nftables: the file loads, twice" [ -n "$table" ]
check "nftables: a reload keeps the set's addresses" [ "$(printf '%s\n' "$table" | grep -c '192.0.2.7')" = 1 ]
check "nftables: a reload doesn't double the rules" [ "$(printf '%s\n' "$table" | grep -c 'meta mark set')" = 1 ]
check "nftables: new connections fit the tunnel, both ways" [ "$(printf '%s\n' "$table" | grep -c 'maxseg size set 1380')" = 2 ]
check "nftables: the unit can reload the file" grep -qx 'ExecReload=/usr/bin/nft -f /etc/tunnel-names.nft' "$etc/systemd/system/tunnel-names.service"
check "nftables: marks the set's addresses" grep -q 'ip daddr @v4 meta mark set 0x14e9' "$etc/tunnel-names.nft"
check "nftables: the unit loads that file" grep -qx 'ExecStart=/usr/bin/nft -f /etc/tunnel-names.nft' "$etc/systemd/system/tunnel-names.service"

echo vpnclaude >"$tmp/active"
setup
check "second run: nothing written" [ -z "$(printf '%s\n' "$log" | grep '^written')" ]
check "second run: no import" hasnt 'connection import'
check "second run: DNS left alone" hasnt 'general reload'
check "second run: the rules left alone" hasnt 'systemctl reload'
check "running: the routes are applied at once" has 'nmcli device reapply vpnconfig'

echo '# an older version' >>"$etc/tunnel-names.nft"
setup
check "changed rules: loaded into the running table" has 'systemctl reload tunnel-names.service'
check "changed rules: DNS left alone" hasnt 'general reload'

echo 'example.org' >>"$tmp/.config/wireguard/claude-only.list"
echo '10.1.0.0/16' >>"$tmp/.config/wireguard/claude-only.list"
setup
check "a new name: in dnsmasq's file" grep -qx 'nftset=/example.org/4#inet#tunnel_names#v4' "$etc/NetworkManager/dnsmasq.d/tunnel-names.conf"
check "a new name: dnsmasq restarts" has 'nmcli general reload dns-full'
check "a new range: a route" has 'ipv4.routes 160.79.104.0/23,10.1.0.0/16,0.0.0.0/0 table=5353'

echo 'another.example' >>"$tmp/.config/wireguard/claude-only.list"
REJECT=1 setup
check "a name dnsmasq rejects: exit 1" [ $rc = 1 ]
check "a name dnsmasq rejects: nothing written" hasnt 'install -D'

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
