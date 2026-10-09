#!/bin/sh
# Tests for the fish function notes (home/dot_config/private_fish/functions/notes.fish)
# in a scratch home: the first run's install, one server per repo, its port, the page
# a note opens, stop. Quartz is a stub (its plugin commands print what Quartz prints;
# its server is python's http.server under Quartz's command line), so is npm, and
# xdg-open records the address it gets. The real node checks localhost.cjs.
# Run: sh tests/notes.sh   (fish, git, node, python3, curl, ss; offline)

set -u
here=$(cd "$(dirname "$0")" && pwd)
fn=$here/../home/dot_config/private_fish/functions/notes.fish
config=$here/../home/dot_config/quartz
tmp=$(mktemp -d)
cleanup() {
    for f in "$tmp"/home/.cache/notes/*/pid; do [ -f "$f" ] && kill "$(cat "$f")" 2>/dev/null; done
    [ -n "${squatter:-}" ] && kill "$squatter" 2>/dev/null
    rm -rf "$tmp"
}
trap cleanup EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
has() { printf '%s\n' "$out" | grep -qF -- "$1"; }
hasnt() { ! has "$1"; }

unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
export HOME="$tmp/home"
mkdir -p "$tmp/bin" "$HOME/.config/quartz"
cp "$config"/quartz.config.yaml "$config"/localhost.cjs "$HOME/.config/quartz/"
realnode=$(node -p process.execPath) # not a shim, which would find the stub

# stubs: npm makes node_modules where it runs; node's plugin install reports a failed
# plugin while $T/plugin-fails exists; node's build serves -o on --port (after a
# second, as Quartz does after its first build) with python, keeping Quartz's
# arguments on its command line; a notes/ with BROKEN in it makes it fail
cat >"$tmp/bin/npm" <<'EOF'
#!/bin/sh
echo "npm $* in $(pwd) allow-git=${npm_config_allow_git:-}" >>"$T/calls"
mkdir -p node_modules
EOF
cat >"$tmp/bin/node" <<'EOF'
#!/bin/sh
echo "node $* in $(pwd) allow-git=${npm_config_allow_git:-}" >>"$T/calls"
case "$2 $3" in
"plugin install")
    if [ -e "$T/plugin-fails" ]; then echo '⚠ Installed 19 plugin(s), 1 failed'; else echo '✓ Installed 20 plugin(s)'; fi
    exit 0
    ;;
esac
prev=
for a in "$@"; do
    case $prev in -d) d=$a ;; -o) o=$a ;; esac
    prev=$a
done
[ -e "$d/BROKEN" ] && { echo 'Failed to parse BROKEN'; exit 1; }
mkdir -p "$o" && echo "notes of $d" >"$o/index.html"
sleep 1
exec python3 -c '
import functools, http.server, sys
a = sys.argv
h = functools.partial(http.server.SimpleHTTPRequestHandler, directory=a[a.index("-o") + 1])
h.log_message = lambda *_: None
http.server.ThreadingHTTPServer(("localhost", int(a[a.index("--port") + 1])), h).serve_forever()
' "$@"
EOF
printf '#!/bin/sh\necho "$1" >>"$T/opened"\n' >"$tmp/bin/xdg-open"
chmod +x "$tmp/bin/"*
export T=$tmp PATH="$tmp/bin:$PATH"

# a Quartz to clone: the release tag, a package.json
src=$tmp/quartz-src
mkdir -p "$src/quartz" && cd "$src" && git init -q
echo '{}' >package.json && echo 'stub' >quartz/bootstrap-cli.mjs
git add . && git -c user.email=t@t -c user.name=t commit -qm quartz && git tag v5.0.0
export NOTES_QUARTZ_REPO="file://$src"

repo() { # repo NAME: a git repo with notes
    mkdir -p "$tmp/$1/notes/journal" "$tmp/$1/notes/decisions" "$tmp/$1/src" && cd "$tmp/$1" && git init -q
    printf '# %s\n' "$1" >notes/index.md
}
notes() { fish --no-config -c "source '$fn'; notes \$argv" "$@" 2>&1 </dev/null; }
opens() { # opens URL: xdg-open got URL last (notes starts it in the background)
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        [ "$(tail -n 1 "$tmp/opened" 2>/dev/null)" = "$1" ] && return 0
        sleep 0.1
    done
    return 1
}
state() { cat "$HOME"/.cache/notes/"$1"-*/"$2" 2>/dev/null; }
quartz=$HOME/.local/share/quartz

cd "$tmp" || exit 1
out=$(notes; echo "status $?")
check "outside a repo: says so" has 'notes: not in a git repo'
check "outside a repo: status 1" has 'status 1'

mkdir -p "$tmp/bare/notes" && cd "$tmp/bare" && git init -q
out=$(notes; echo "status $?")
check "a repo without notes/index.md: says so" has "notes: $tmp/bare has no notes/index.md"
check "  … no install" [ ! -e "$quartz" ]

repo alpha
touch "$tmp/plugin-fails"
out=$(notes; echo "status $?")
check "first run: says what the install takes" has 'it takes several minutes and needs GitHub'
check "  … and where it goes" has "notes: installing Quartz v5.0.0 and its plugins into $quartz"
check "first run: the release, cloned" [ "$(git -C "$quartz" describe --tags 2>/dev/null)" = v5.0.0 ]
check "first run: npm ci in Quartz's folder, git dependencies allowed" \
    grep -qF "npm ci --no-audit --no-fund --loglevel=error in $quartz allow-git=all" "$tmp/calls"
check "  … only there: no npm config in the home" [ ! -e "$HOME/.npmrc" -a ! -e "$HOME/.config/npm" ]
check "then the plugins, git dependencies allowed" grep -qF "plugin install in $quartz allow-git=all" "$tmp/calls"
check "a plugin that fails: says so" has 'notes: some plugins failed to install; run notes again to retry'
check "  … status 1" has 'status 1'
check "  … no server" [ -z "$(state alpha pid)" ]
rm "$tmp/plugin-fails"
notes >"$tmp/retry.log"
out=$(cat "$tmp/retry.log")
check "the next run retries the install" [ "$(grep -c 'plugin install' "$tmp/calls")" = 2 ]
check "  … its output, into a file, whole" sh -c "grep -q 'installing Quartz' '$tmp/retry.log' && grep -q 'Installed 20' '$tmp/retry.log' && grep -q 'notes: http://localhost' '$tmp/retry.log'"
check "the config, written in with the repo's name" grep -qF 'pageTitle: "alpha"' "$quartz/quartz.config.yaml"
check "  … and nothing else changed" \
    sh -c "sed 's/{{repo}}/alpha/g' '$config/quartz.config.yaml' | cmp -s - '$quartz/quartz.config.yaml'"
check "Quartz serves alpha's notes" grep -qF "build --serve -d $tmp/alpha/notes -o $HOME/.cache/notes/alpha-" "$tmp/calls"
check "  … from its folder" sh -c "grep -F 'build --serve' '$tmp/calls' | grep -qF 'in $quartz '"
check "  … on this machine only" grep -qF "node --require $HOME/.config/quartz/localhost.cjs quartz/bootstrap-cli.mjs build" "$tmp/calls"
check "localhost.cjs: a port alone listens on 127.0.0.1" [ "$("$realnode" --require "$config/localhost.cjs" -e '
const net = require("net")
const servers = [net.createServer().listen(0), net.createServer().listen(0, undefined, undefined, () => {}),
    net.createServer().listen(0, () => {}), net.createServer().listen(0, "::1")]
Promise.all(servers.map((s) => new Promise((r) => s.on("listening", r)))).then(() => {
    console.log(servers.map((s) => s.address().address).join(" "))
    process.exit()
})')" = '127.0.0.1 127.0.0.1 127.0.0.1 ::1' ]
port=$(state alpha port)
check "opens the index" opens "http://localhost:$port/"
check "and prints it" has "notes: http://localhost:$port/"
check "the server serves alpha's notes" [ "$(curl -s "http://localhost:$port/")" = "notes of $tmp/alpha/notes" ]
check "its port comes from the repo (8100-8499, even)" [ "$port" -ge 8100 -a "$port" -le 8499 -a $((port % 2)) -eq 0 ]

pid=$(state alpha pid)
cd "$tmp/alpha/src" || exit 1
rm -f "$tmp/opened"
out=$(notes)
check "again, from a subfolder: no install" hasnt 'installing'
check "  … and the same server" [ "$(state alpha pid)" = "$pid" ]
check "  … opened again" opens "http://localhost:$port/"

echo '# Edited config' >>"$HOME/.config/quartz/quartz.config.yaml"
notes >/dev/null
check "a changed config is written in" grep -qF '# Edited config' "$quartz/quartz.config.yaml"
check "the install ran once" [ "$(grep -c 'plugin install' "$tmp/calls")" = 2 ]
sed -i 's/{{repo}}/Fixed/' "$HOME/.config/quartz/quartz.config.yaml"
out=$(notes; echo "status $?")
check "a config with a title of its own: kept" grep -qF 'pageTitle: "Fixed"' "$quartz/quartz.config.yaml"
check "  … and notes goes on" has 'status 0'
cp "$config/quartz.config.yaml" "$HOME/.config/quartz/"

printf '# M1 Shell & keys\n' >"$tmp/alpha/notes/journal/M1 Shell & keys.md"
printf '# Ёлка 50%%?\n' >"$tmp/alpha/notes/Ёлка 50%?.md"
printf '# Decisions\n' >"$tmp/alpha/notes/decisions/index.md"
cd "$tmp" || exit 1
notes "alpha/notes/journal/M1 Shell & keys.md" >/dev/null
check "a note opens its page (Quartz's slug)" opens "http://localhost:$port/journal/M1-Shell--and--keys"
notes "alpha/notes/Ёлка 50%?.md" >/dev/null
check "  … with what Quartz drops or spells out" opens "http://localhost:$port/Ёлка-50-percent"
notes alpha/notes/decisions/index.md >/dev/null
check "a folder's index opens the folder" opens "http://localhost:$port/decisions/"
notes alpha/notes/index.md >/dev/null
check "the index opens /" opens "http://localhost:$port/"

repo beta
notes >/dev/null
bport=$(state beta port)
check "a second repo: its own port" [ -n "$bport" -a "$bport" != "$port" ]
check "  … and title" grep -qF 'pageTitle: "beta"' "$quartz/quartz.config.yaml"
check "  … both serve, each its notes" sh -c "curl -s localhost:$port/ | grep -q alpha/notes && curl -s localhost:$bport/ | grep -q beta/notes"

cd "$tmp/alpha" || exit 1
mv notes/index.md notes/index.away
out=$(notes stop)
mv notes/index.away notes/index.md
check "stop: says so, even without index.md" has "notes: stopped the server for $tmp/alpha/notes"
sleep 0.5
check "stop: the server is gone" sh -c "! curl -s localhost:$port/ >/dev/null"
out=$(notes stop)
check "stop again: nothing runs" has "notes: no server runs for $tmp/alpha/notes"
notes >/dev/null
check "a restart keeps the port" [ "$(state alpha port)" = "$port" ]
notes stop >/dev/null
sleep 0.5

python3 -m http.server "$port" --bind localhost >/dev/null 2>&1 &
squatter=$!
sleep 1
notes >/dev/null
check "port taken: the next pair" [ "$(state alpha port)" = $((port + 2)) ]
notes stop >/dev/null

mv "$HOME/.config/quartz/quartz.config.yaml" "$tmp/config.away"
out=$(notes; echo "status $?")
mv "$tmp/config.away" "$HOME/.config/quartz/quartz.config.yaml"
check "no config to read: status 1" has 'status 1'
check "  … no server" [ -z "$(state alpha pid)" ]

repo broken
touch notes/BROKEN
out=$(notes; echo "status $?")
check "Quartz fails: says so, with its log" has 'Failed to parse BROKEN'
check "  … status 1" has 'status 1'

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
