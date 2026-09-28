#!/bin/sh
# Tests for the fish function dots (home/dot_config/private_fish/functions/dots.fish)
# in a scratch home with a small chezmoi source: what it adds or re-adds, and what it
# lists as left over. lazygit is a stub. Run: sh tests/dots.sh   (fish, chezmoi; offline)

set -u
here=$(cd "$(dirname "$0")" && pwd)
dots=$here/../home/dot_config/private_fish/functions/dots.fish
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
has() { printf '%s\n' "$out" | grep -qF -- "$1"; }
hasnt() { ! has "$1"; }

unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
export HOME="$tmp/home"
mkdir -p "$tmp/bin" "$HOME/.local/share/chezmoi"
printf '#!/bin/sh\necho "lazygit $*"\n' >"$tmp/bin/lazygit"
chmod +x "$tmp/bin/lazygit"
PATH=$tmp/bin:$PATH
srcdir=$HOME/.local/share/chezmoi
dots() { fish --no-config -c "source '$dots'; dots $*" </dev/null 2>&1; }

cd "$srcdir" && git init -q
printf 'plain\n' >dot_plain
printf 'gone\n' >dot_gone
printf 'pending v1\n' >dot_pending
printf '{{ "templ" }}\n' >dot_templ.tmpl
printf '#!/bin/sh\nsed "/^# block$/d"\necho "# block"\n' >modify_dot_mod
cd "$HOME" && chezmoi apply

out=$(dots)
check "nothing to do: no list" hasnt 'Not in your home yet'
check "nothing to do: lazygit on the source" has "lazygit -p $srcdir"

echo 'edited' >>~/.plain
echo 'edited' >>~/.templ
echo 'Host x' >>~/.mod
echo 'pending v2' >>"$srcdir/dot_pending"
rm ~/.gone
echo 'new' >~/.new
out=$(dots '~/.new' '~/.templ')
printf '%s\n' "$out" | sed 's/^/     dots: /'
check "a live edit is re-added" grep -q edited "$srcdir/dot_plain"
check "a new file is added" test -f "$srcdir/dot_new"
check "a template given as FILE stays a template" grep -qF '{{ "templ" }}' "$srcdir/dot_templ.tmpl"
check "the home is left as it was" grep -qx 'pending v1' ~/.pending
check "a source change waits for apply" has ' M .pending'
check "a script-owned file isn't added twice" test ! -e "$srcdir/dot_mod"
check "template: says chezmoi merge" has '(template: chezmoi merge ~/.templ)'
check "modify_: says chezmoi apply" has "(this machine's own: chezmoi apply ~/.mod keeps the edit)"
check "deleted: says forget or apply" has '(chezmoi forget ~/.gone, or chezmoi apply ~/.gone to restore)'
check "re-added and added files aren't listed" sh -c "! printf '%s\n' \"\$1\" | grep -qE '\\.(plain|new)\$'" _ "$out"

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
