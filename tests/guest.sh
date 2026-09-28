#!/bin/sh
# Guest mode test: on a home with its own .bashrc, .gitconfig and ssh config,
# guest.sh install, use the tools, make some files of your own, guest.sh remove. The
# home must then match the snapshot taken before, apart from your own files.
# Run: sh tests/guest.sh [IMAGE]   (default: ubuntu:24.04)
# Needs docker and the network. GITHUB_TOKEN is passed through when set.

set -u

# --- Inside the container, as the user "tester" -------------------------------------
if [ "${1:-}" = --inside ]; then
    fails=0
    check() { # check NAME CONDITION...
        name=$1; shift
        if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
    }
    has() { printf '%s\n' "$out" | grep -qE "$1"; }
    # snapshot FILE: every path under ~ with its type and mode, plus file checksums
    snapshot() {
        { find ~ -mindepth 1 -printf '%P %y %m\n'; find ~ -type f -printf '%P\n' |
            (cd ~ && xargs -r -d '\n' sha256sum); } | sort >"$1"
    }

    # A home that isn't ours: its own .bashrc, .gitconfig and ssh config.
    echo '# the host owner line' >>~/.bashrc
    printf '[user]\n\tname = Host Owner\n' >~/.gitconfig
    mkdir -m 700 ~/.ssh && printf 'Host owner\n\tHostName 10.0.0.2\n' >~/.ssh/config
    snapshot /tmp/before

    cp -r /src /tmp/src
    out=$(DOTFILES_REPO=/tmp/src sh /tmp/src/guest.sh install 2>&1)
    code=$?
    printf '%s\n' "$out" | grep -iE 'error|warn|guest:' | sed 's/^/     install: /'
    check "install succeeds" [ "$code" = 0 ]
    check "our .bashrc is in place" grep -q 'exec fish' ~/.bashrc
    check "our .gitconfig is in place" sh -c '! grep -q "Host Owner" ~/.gitconfig'
    check "ssh config: the owner's host stays, our block is added" \
        sh -c 'grep -q "^Host owner" ~/.ssh/config && grep -q "^# >>> dotfiles" ~/.ssh/config'
    out=$(printf 'echo "v=$FISH_VERSION"\n' | bash -li 2>/dev/null)
    check "interactive bash hands over to fish" has '^v=4\.'
    out=$(DOTFILES_REPO=/tmp/src sh ~/.local/share/chezmoi/guest.sh install 2>&1)
    check "install again (update) succeeds" [ $? = 0 ]

    # A visit: fish, tmux, zoxide; and files of your own.
    bash -lc "fish -ic 'z /tmp; true'" >/dev/null 2>&1
    bash -lc 'tmux -L guest new-session -d; tmux -L guest kill-server' >/dev/null 2>&1
    bash -lc 'zoxide add /tmp' >/dev/null 2>&1
    mkdir -p ~/work && echo notes >~/work/notes.txt
    echo '#!/bin/sh' >~/.local/bin/mine

    out=$(sh ~/.local/share/chezmoi/guest.sh remove 2>&1)
    code=$?
    printf '%s\n' "$out" | sed 's/^/     remove: /'
    check "remove succeeds" [ "$code" = 0 ]
    check "your own files stay" test -f ~/work/notes.txt -a -f ~/.local/bin/mine
    rm -r ~/work ~/.local/bin/mine
    rmdir ~/.local/bin ~/.local 2>/dev/null
    snapshot /tmp/after
    check "the home is as before" cmp -s /tmp/before /tmp/after
    diff /tmp/before /tmp/after | cut -c 1-100 | sed 's/^/     /' | head -40

    [ $fails = 0 ] || exit 1
    exit 0
fi

# --- On the host --------------------------------------------------------------------
here=$(cd "$(dirname "$0")" && pwd)
src=$(cd "$here/.." && pwd)
tag=$(sh "$here/base-image.sh" "${1:-ubuntu:24.04}") || exit 1
docker run --rm -v "$src:/src:ro" -e GITHUB_TOKEN -u guest -w /home/guest \
    "$tag" sh /src/tests/guest.sh --inside
