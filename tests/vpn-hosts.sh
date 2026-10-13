#!/bin/sh
# Tests for vpn-hosts (home/dot_local/bin/executable_vpn-hosts): what it reads from a
# list in a scratch home, and the tracked list itself. Run: sh tests/vpn-hosts.sh
# (offline)

set -u
here=$(cd "$(dirname "$0")" && pwd)
script=$here/../home/dot_local/bin/executable_vpn-hosts
tracked=$here/../home/dot_config/private_wireguard/claude-only.list
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
hosts() { HOME=$tmp sh "$script" "$@" | tr '\n' ' '; }

mkdir -p "$tmp/.config/wireguard"
list=$tmp/.config/wireguard/claude-only.list
cat >"$list" <<'EOF'
# a comment

160.79.104.0/23  # Anthropic
openrouter.ai    # by name
  10.1.2.3
api.example.com
EOF
check "ranges: with and without a prefix" [ "$(hosts ranges)" = '160.79.104.0/23 10.1.2.3 ' ]
check "names: the rest, without comments" [ "$(hosts names)" = 'openrouter.ai api.example.com ' ]

printf '# nothing yet\n' >"$list"
check "an empty list: no ranges" [ -z "$(hosts ranges)" ]
check "an empty list: no names" [ -z "$(hosts names)" ]

HOME=$tmp sh "$script" 2>/dev/null
check "no argument: usage, exit 2" [ $? = 2 ]

cp "$tracked" "$list"
case " $(hosts ranges)" in *' 160.79.104.0/23 '*) true ;; *) false ;; esac
check "the tracked list: Anthropic's range is in it" [ $? = 0 ]
case " $(hosts names)" in *' openrouter.ai '*) true ;; *) false ;; esac
check "the tracked list: openrouter.ai is in it, by name" [ $? = 0 ]

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
