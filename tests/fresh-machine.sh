#!/bin/sh
# Fresh-machine test: apply this source (with uncommitted changes) in clean Ubuntu
# containers, as a non-root user, the way a new machine gets it.
# Run: sh tests/fresh-machine.sh [IMAGE...]   (default: ubuntu:20.04 ubuntu:24.04)
# Needs docker and the network. GITHUB_TOKEN is passed through when set (GitHub API
# rate limit), e.g. GITHUB_TOKEN=$(gh auth token) sh tests/fresh-machine.sh

set -u

# --- Inside the container, as the user "tester" -------------------------------------
if [ "${1:-}" = --inside ]; then
    fails=0
    check() { # check NAME CONDITION...
        name=$1; shift
        if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
    }
    has() { printf '%s\n' "$out" | grep -qE "$1"; }
    hasnt() { ! has "$1"; }

    mkdir -p ~/.local/share ~/.local/bin
    # A work PC's own ssh config, with a host that overrides a shared default
    mkdir -m 700 ~/.ssh
    printf 'Host work\n\tHostName 10.0.0.1\n\tControlMaster no\n' >~/.ssh/config
    cp -r /src ~/.local/share/chezmoi
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin >/dev/null 2>&1
    cz=~/.local/bin/chezmoi

    # --promptBool matches the prompt texts in home/.chezmoi.toml.tmpl
    out=$($cz init --promptBool 'Desktop (X11 + i3)=false,Own machine (secrets)=false' 2>&1)
    check "init succeeds" [ $? = 0 ]
    out=$($cz apply 2>&1)
    code=$?
    # Show all but mise's progress lines; its errors and warnings stay.
    [ -n "$out" ] && printf '%s\n' "$out" | grep -viE '^(mise|  )' | sed 's/^/     apply: /'
    printf '%s\n' "$out" | grep -iE 'error|warn' | sed 's/^/     apply: /'
    check "apply succeeds" [ "$code" = 0 ]
    # Shown above but not counted: mise's network warnings that end in a working
    # fallback, e.g. a GitHub 502 on its release list.
    problems=$(printf '%s\n' "$out" | grep -iE 'error|warn' | grep -vE '^mise WARN .*fallback=true')
    check "apply prints no errors or warnings" [ -z "$problems" ]
    check "verify: the home matches the source" $cz verify

    # ssh: the machine's hosts stay first, the dotfiles block goes last
    echo "     info: $(ssh -V 2>&1)"
    check "ssh config: own hosts stay first" [ "$(head -n 1 ~/.ssh/config)" = 'Host work' ]
    check "ssh config: the dotfiles block is last" [ "$(tail -n 1 ~/.ssh/config)" = '# <<< dotfiles' ]
    check "ssh config: no personal hosts without secrets" test ! -e ~/.ssh/personal.conf
    out=$(ssh -G other.example 2>&1)
    check "ssh reads defaults.conf" has '^controlmaster auto$'
    out=$(ssh -G work 2>&1)
    check "ssh: a host in config overrides defaults.conf" has '^controlmaster false$'

    out=$(bash -lc 'echo "$PATH"' 2>&1)
    check "bash login: ~/.local/bin on PATH" has "(^|:)$HOME/.local/bin(:|$)"
    out=$(bash -lc 'command -v tools-check' 2>&1)
    check "bash login: tools-check found" has "^$HOME/.local/bin/tools-check$"
    out=$(bash -lc 'true' 2>&1)
    check "bash login prints nothing" [ -z "$out" ]
    # The same line is valid in bash (prints "v=") and fish (prints its version).
    out=$(printf 'echo "v=$FISH_VERSION"\n' | bash -li 2>/dev/null)
    check "interactive bash hands over to fish" has '^v=4\.'
    out=$(bash -lc "fish -ic 'functions -q tide; and functions -q _fzf_search_directory; and echo plugins'" 2>&1)
    check "fisher plugins installed (tide, fzf.fish)" has '^plugins$'
    out=$(bash -lc "fish -c 'echo \$tide_time_format \$tide_prompt_transient_enabled \$tide_left_prompt_items'" 2>&1)
    check "tide style set (24-hour time, transient, two lines)" has '^%T true pwd git newline character$'
    # tide renders the ❯ line in a background, non-interactive fish
    out=$(bash -lc "fish -c 'set _tide_status 0; set fish_bind_mode default; _tide_item_character'" 2>&1)
    check "tide prompt character is ❯, not vi mode's ❮" has '❯'
    out=$(bash -lc 'fish -ic true' 2>&1)
    check "interactive fish starts without output" [ -z "$out" ]

    # Tools: every "mise" row of tools.tsv is installed at its pinned version.
    out=$(bash -lc 'tools-check --missing' 2>&1)
    printf '%s\n' "$out" | sed 's/^/     tools-check: /'
    # A mise row: its install column (after status, tool, have, want) starts with "mise "
    check "tools-check: no mise row missing or older" \
        [ -z "$(printf '%s\n' "$out" | grep -E '^(missing|older) +[^ ]+ +[^ ]+ +[^ ]+ +mise ')" ]
    out=$(bash -lc 'tmux -V' 2>&1)
    check "tmux is the pinned 3.7c" has '^tmux 3\.7c$'
    check "tmux takes allow-passthrough (>= 3.3)" bash -lc \
        'tmux -L t -f /dev/null new-session -d \; set -g allow-passthrough on \; kill-server'
    # The real config, with its status bar plugin from the chezmoi external
    out=$(bash -lc 'tmux -L c new-session -d && tmux -L c show-messages; tmux -L c show -gv status-left; tmux -L c kill-server' 2>&1)
    check "tmux loads its config and status bar" has 'client_prefix'
    check "tmux config loads without errors" hasnt 'error|unknown|invalid'
    check "nvim runs on this glibc" bash -lc 'nvim --clean --headless +q'
    # Without the user config, so lazy.nvim doesn't install plugins and rewrite lazy-lock.json
    out=$(bash -lc "nvim --clean --headless --cmd \"lua vim.g.python3_host_prog = vim.fn.stdpath('data') .. '/venv/bin/python'\" +'py3 import pynvim, jupyter_client' +qa" 2>&1)
    check "nvim's Python host works (the uv venv)" [ -z "$out" ]
    out=$(bash -lc 'command -v fish' 2>&1)
    check "fish comes from mise" has "^$HOME/.local/share/mise/shims/fish$"
    # delta (git's pager, lazygit's diffs): the tracked styles, and light from the seeded
    # theme file, since no theme-switcher runs here
    out=$(bash -lc 'delta --show-config' 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
    check "delta reads .gitconfig" has '^ +file-style += bold blue$'
    check "delta: light, from the seeded theme file" has '^ +minus-style += normal "#ffe0e0"$'
    printf 'a\nb\n' >d1; printf 'a\nc\n' >d2
    out=$(git diff --no-index d1 d2 | bash -lc delta 2>&1)
    rm -f d1 d2
    check "delta: headers without boxes or rules" hasnt '─|┐|┘'

    # apt rows: core and dev ones must exist on this release; desktop ones may not.
    lacking=
    awk -F '\t' '$5 ~ /^apt / { sub(/^apt /, "", $5); print $2, $5 }' ~/.config/tools/tools.tsv >apt.rows
    while read -r group p; do
        apt-cache policy "$p" | grep -q 'Candidate: [^(]' && continue
        if [ "$group" = desktop ]; then lacking="$lacking $p"; else check "apt has $p" false; fi
    done <apt.rows
    rm -f apt.rows
    [ -z "$lacking" ] || echo "     info: not in apt on this release:$lacking"

    out=$($cz apply 2>&1)
    [ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/     apply again: /'
    check "second apply prints nothing" [ -z "$out" ]

    [ $fails = 0 ] || exit 1
    exit 0
fi

# --- On the host --------------------------------------------------------------------
here=$(cd "$(dirname "$0")" && pwd)
src=$(cd "$here/.." && pwd)
[ $# -gt 0 ] || set -- ubuntu:20.04 ubuntu:24.04
failed=

for image in "$@"; do
    echo "== $image"
    tag=$(sh "$here/base-image.sh" "$image") || { failed="$failed $image"; continue; }
    docker run --rm -v "$src:/src:ro" -e GITHUB_TOKEN -u tester -w /home/tester \
        "$tag" sh /src/tests/fresh-machine.sh --inside || failed="$failed $image"
done

if [ -n "$failed" ]; then
    echo "FAILED:$failed"
    exit 1
fi
echo "all images passed"
