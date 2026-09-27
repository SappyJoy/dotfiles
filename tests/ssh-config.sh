#!/bin/sh
# Tests for ~/.ssh/config: the modify script that keeps the dotfiles' Include block at
# the end of each machine's own file, and the override order that block relies on
# (ssh -G reads a config without connecting). No network. Run: sh tests/ssh-config.sh

set -u

here=$(cd "$(dirname "$0")" && pwd)
src=$(cd "$here/.." && pwd)
modify="$src/home/private_dot_ssh/modify_private_config"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0

check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
has() { printf '%s\n' "$out" | grep -qF -- "$1"; }
hasnt() { ! has "$1"; }
count() { printf '%s\n' "$out" | grep -cF -- "$1"; }

block=$(sh "$modify" </dev/null)
own='Host work
	HostName 10.0.0.1'

# No file yet: only the block
out=$block
check "empty file: the block, which starts the file" [ "$(printf '%s\n' "$out" | head -n 1)" = '# >>> dotfiles: kept last by chezmoi. Add your own hosts above this block.' ]
check "empty file: it includes both files" has '	Include personal.conf defaults.conf'

# A machine's own hosts stay first, then one blank line, then the block
out=$(printf '%s\n\n\n' "$own" | sh "$modify")
check "own hosts: kept, then the block" [ "$out" = "$(printf '%s\n\n%s' "$own" "$block")" ]
again=$(printf '%s\n' "$out" | sh "$modify")
check "run again: nothing changes" [ "$again" = "$out" ]

# Hosts added below the block move above it; the block stays last and single
out=$(printf '%s\n\n%s\nHost later\n' "$own" "$block" | sh "$modify")
check "hosts below the block: kept" has 'Host later'
check "hosts below the block: the block moves to the end" \
    [ "$(printf '%s\n' "$out" | tail -n 1)" = '# <<< dotfiles' ]
check "hosts below the block: one block" [ "$(count '# >>> dotfiles')" = 1 ]

# A block that lost its end line: only the start line goes, nothing else is lost
out=$(printf '%s\n# >>> dotfiles\nHost orphan\n' "$own" | sh "$modify")
check "broken block: its lines are kept" has 'Host orphan'
again=$(printf '%s\n' "$out" | sh "$modify")
check "broken block: stable on the next run" [ "$again" = "$out" ]

# A file without a final newline
out=$(printf 'Host work' | sh "$modify")
check "no final newline: the last line is kept" [ "$(printf '%s\n' "$out" | head -n 1)" = 'Host work' ]

# The order the block relies on: a host above it overrides defaults.conf. The Include
# gets an absolute path here: relative ones resolve in the real ~/.ssh.
printf 'Host work\n\tAddKeysToAgent no\n' | sh "$modify" |
    sed "s|Include personal.conf defaults.conf|Include $src/home/private_dot_ssh/defaults.conf|" \
        >"$tmp/config"
out=$(ssh -F "$tmp/config" -G other.example 2>&1)
check "ssh reads defaults.conf" has 'addkeystoagent true'
out=$(ssh -F "$tmp/config" -G work 2>&1)
check "a host above the block overrides it" has 'addkeystoagent false'

# Which machines get what: personal.conf only on own machines, config everywhere
out=$(chezmoi execute-template --source "$src" --override-data '{"personal": false}' \
    <"$src/home/.chezmoiignore")
check "not personal: personal.conf ignored" has '.ssh/personal.conf'
check "not personal: config still managed" hasnt '.ssh/config'
out=$(chezmoi execute-template --source "$src" --override-data '{"personal": true}' \
    <"$src/home/.chezmoiignore")
check "personal: personal.conf managed" hasnt '.ssh/personal.conf'

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
