#!/bin/sh
# A fresh machine to try by hand: a clean Ubuntu container (default ubuntu:26.04) that
# gets this source (with uncommitted changes) the way a work PC gets the one-liner:
# user "tester" with sudo, answers desktop=false and personal=false, then a shell
# (bash hands over to fish). The container is deleted when that shell exits.
# Run: sh tests/sandbox.sh [IMAGE]
#   A second shell in it: docker exec -it dotfiles-sandbox bash -l
# Needs docker and the network. GITHUB_TOKEN is passed through when set, e.g.
# GITHUB_TOKEN=$(gh auth token) sh tests/sandbox.sh

set -u

# --- Inside the container, as the user "tester" -------------------------------------
if [ "${1:-}" = --inside ]; then
    mkdir -p ~/.local/share ~/.local/bin
    cp -r /src ~/.local/share/chezmoi
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin >/dev/null
    ~/.local/bin/chezmoi init --promptBool 'Desktop (X11 + i3)=false,Own machine (secrets)=false'
    ~/.local/bin/chezmoi apply
    echo "sandbox: ready. Exit the shell to delete the container."
    exec bash -l
fi

# --- On the host --------------------------------------------------------------------
here=$(cd "$(dirname "$0")" && pwd)
src=$(cd "$here/.." && pwd)
tag=$(sh "$here/base-image.sh" "${1:-ubuntu:26.04}") || exit 1
exec docker run --rm -it --name dotfiles-sandbox --hostname sandbox \
    -v "$src:/src:ro" -e GITHUB_TOKEN -e TERM=xterm-256color -u tester -w /home/tester \
    "$tag" sh /src/tests/sandbox.sh --inside
