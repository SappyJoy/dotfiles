#!/bin/sh
# Tests for the fish function claude-with
# (home/dot_config/private_fish/functions/claude-with.fish): what it passes to claude,
# and which first arguments it takes as no plugin. claude is a stub.
# Run: sh tests/claude-with.sh   (fish; offline)

set -u
here=$(cd "$(dirname "$0")" && pwd)
fn=$here/../home/dot_config/private_fish/functions/claude-with.fish
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
# claude-with ARGS...: its output and exit status, with a claude that prints its args
with() {
    fish --no-config -c 'function claude; echo "claude $argv"; end; source $argv[1]
claude-with $argv[2..]; echo "status $status"' "$fn" "$@" 2>&1
}
usage() { out=$(with "$@"); [ "$out" = "usage: claude-with <plugin>[@marketplace] [claude options]
status 2" ]; }

out=$(with session-report --resume x)
check "official marketplace by default, options passed on" [ "$out" = 'claude --settings {"enabledPlugins":{"session-report@claude-plugins-official":true}} --resume x
status 0' ]
out=$(with mason-lsp@personal -p hi)
check "another marketplace" [ "$out" = 'claude --settings {"enabledPlugins":{"mason-lsp@personal":true}} -p hi
status 0' ]
check "no argument: usage" usage
for arg in -h --resume @personal foo@ 'a b' 'a"b' 'a\b' a@b@c ''; do
    check "'$arg' first: usage" usage "$arg" x
done

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
