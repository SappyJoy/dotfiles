#!/bin/sh
# Tests for home/dot_local/bin/executable_tools-check. Run: sh tests/tools-check.sh
# TC_SHELL picks the shell that runs tools-check (default sh), e.g. TC_SHELL=dash.
# Fake tools in a temporary PATH cover every status.

set -u

here=$(cd "$(dirname "$0")" && pwd)
tc="$here/../home/dot_local/bin/executable_tools-check"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0

check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
has() { printf '%s\n' "$out" | grep -qE "$1"; }
hasnt() { ! has "$1"; }

mkdir "$tmp/bin"
fake() { # fake NAME OUTPUT: a tool that prints OUTPUT for any argument
    printf '#!/bin/sh\nprintf "%%b\\n" "%s"\n' "$2" >"$tmp/bin/$1"
    chmod +x "$tmp/bin/$1"
}
fake same 'same 1.2.3'
fake old 'old version 1.2.0'
fake new 'v2.0.1 (build 7)'
fake color '\033[1m4.5.6\033[0m'
fake plain 'plain v13 (rev d87a5ba)'
fake gui 'gui 3.1'
fake bare 'no version here'

T=$(printf '\t')
cat >"$tmp/tools.tsv" <<EOF
# name${T}group${T}version${T}check${T}install
same${T}core${T}1.2.3${T}same --version${T}get-same
old${T}core${T}1.2.3${T}old --version${T}get-old
new${T}dev${T}1.2.3${T}new --version${T}get-new
color${T}dev${T}4.5.6${T}color --version${T}get-color
plain${T}dev${T}13${T}plain --version${T}get-plain
gone${T}core${T}1.0${T}gone --version${T}get-gone
gui${T}desktop${T}3.1${T}gui --version${T}get-gui
bare${T}core${T}-${T}-${T}get-bare
EOF

run() { # run ARGS...: sets out and code; no display unless the caller sets DISPLAY
    out=$(env -u WAYLAND_DISPLAY PATH="$tmp/bin:/usr/bin:/bin" TOOLS_LIST="$tmp/tools.tsv" \
        DISPLAY="${DISPLAY_FOR_TEST:-}" ${TC_SHELL:-sh} "$tc" "$@" 2>&1)
    code=$?
}

run
check "same version is ok" has '^ok +same +1\.2\.3 +1\.2\.3 *$'
check "older version is older, with hint" has '^older +old +1\.2\.0 +1\.2\.3 +get-old$'
check "newer version is newer" has '^newer +new +2\.0\.1 +1\.2\.3 *$'
check "color codes are stripped" has '^ok +color +4\.5\.6 '
check "plain number is parsed" has '^ok +plain +13 +13 '
check "missing tool is missing, with hint" has '^missing +gone +- +1\.0 +get-gone$'
check "presence-only tool is ok" has '^ok +bare +- +- '
check "desktop tool skipped without display" hasnt ' gui '
check "skip is reported" has '1 desktop tools skipped'
check "exit 1 when something needs action" [ "$code" = 1 ]

run --missing
check "--missing hides ok and newer" hasnt '^(ok|newer) '
check "--missing shows older" has '^older +old '
check "--missing shows missing" has '^missing +gone '

DISPLAY_FOR_TEST=:99; run; DISPLAY_FOR_TEST=
check "desktop tool shown with a display" has '^ok +gui +3\.1 '
run --all
check "--all shows desktop tools" has '^ok +gui '

grep -E '^(#|same|new|bare)' "$tmp/tools.tsv" >"$tmp/ok.tsv"
out=$(PATH="$tmp/bin:/usr/bin:/bin" ${TC_SHELL:-sh} "$tc" --list "$tmp/ok.tsv"); code=$?
check "exit 0 when nothing needs action" [ "$code" = 0 ]

chmod 640 "$tmp/tools.tsv"
run --record
check "--record reports the older one" has '^old: 1\.2\.3 -> 1\.2\.0$'
check "--record reports the newer one" has '^new: 1\.2\.3 -> 2\.0\.1$'
row() { grep "^$1$T" "$tmp/tools.tsv" | cut -f3; }
check "--record writes the older version" [ "$(row old)" = 1.2.0 ]
check "--record writes the newer version" [ "$(row new)" = 2.0.1 ]
check "--record keeps missing rows" [ "$(row gone)" = 1.0 ]
check "--record keeps any-version rows" [ "$(row bare)" = - ]
check "--record records desktop tools too" [ "$(row gui)" = 3.1 ]
check "--record keeps comments" grep -q '^# name' "$tmp/tools.tsv"
check "--record keeps the file mode" [ "$(stat -c %a "$tmp/tools.tsv")" = 640 ]
run --record
check "second --record changes nothing" has '0 version\(s\) recorded'

run --bogus
check "unknown option exits 2" [ "$code" = 2 ]

[ $fails = 0 ] && echo "all passed" || echo "$fails failed"
[ $fails = 0 ]
