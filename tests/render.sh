#!/bin/sh
# Tests for the templates that read tools.tsv: home/.chezmoitemplates/tools.json, the
# mise config and the install scripts. Renders this source with chezmoi on this
# machine; no network. Run: sh tests/render.sh

set -u

here=$(cd "$(dirname "$0")" && pwd)
src=$(cd "$here/.." && pwd)
tsv="$src/home/dot_config/tools/tools.tsv"
fails=0

check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}
has() { printf '%s\n' "$out" | grep -qF -- "$1"; }
hasnt() { ! has "$1"; }
# render FILE [DESKTOP]: FILE (under home/) rendered, with .desktop set (default true)
render() {
    chezmoi execute-template --source "$src" --override-data "{\"desktop\": ${2:-true}}" \
        <"$src/home/$1"
}
json_len() { python3 -c 'import json, sys; print(len(json.load(sys.stdin)))'; }
rows() { # rows AWK_CONDITION: count the tools.tsv rows matching it
    awk -F '\t' "!/^#/ && NF && ($1)" "$tsv" | wc -l | tr -d ' '
}

# tools.json: one object per row; desktop rows only when .desktop
out=$(render .chezmoitemplates/tools.json true | json_len)
check "tools.json: every row on a desktop" [ "$out" = "$(rows 1)" ]
out=$(render .chezmoitemplates/tools.json false | json_len)
check "tools.json: no desktop rows elsewhere" [ "$out" = "$(rows '$2 != "desktop"')" ]

# mise [tools]: exactly the "mise" rows, each pinned to its version
out=$(render .chezmoitemplates/mise-tools.toml true)
missing=$(awk -F '\t' '!/^#/ && $5 ~ /^mise / { sub(/^mise /, "", $5); print "\"" $5 "\" = \"" $3 "\"" }' "$tsv" |
    while IFS= read -r pin; do has "$pin" || echo "$pin"; done)
check "mise config: every mise row pinned" [ -z "$missing" ]
[ -z "$missing" ] || printf '     not found: %s\n' "$missing"
check "mise config: nothing but mise rows" [ "$(printf '%s\n' "$out" | grep -c '^"')" = "$(rows '$5 ~ /^mise /')" ]
check "mise config: tool options kept" has '"pipx:aider-chat[uvx_args=--python 3.12]"'
out=$(render .chezmoitemplates/mise-tools.toml false)
check "mise config: desktop rows only on a desktop" hasnt 'greenclip'
out=$(render dot_config/mise/config.toml.tmpl)
check "mise config: per-project node and java versions" has 'idiomatic_version_file_enable_tools = ["node", "java"]'

# Per machine: arch uses pacman, so its mise config has only the settings (per-project
# versions), and it gets no mise external, no scripts and no apt list.
os=$(chezmoi execute-template --source "$src" '{{ .chezmoi.osRelease.id }}')
out=$(chezmoi execute-template --source "$src" <"$src/home/.chezmoiignore")
check "$os: mise config not ignored" hasnt '.config/mise/**'
if [ "$os" = arch ]; then
    out=$(render dot_config/mise/config.toml.tmpl)
    check "arch: mise config has no [tools]" hasnt '[tools]'
    for script in run_onchange_after_20-mise-install.sh.tmpl run_onchange_after_25-fisher.sh.tmpl \
        run_onchange_after_30-packages.sh.tmpl; do
        out=$(render "$script")
        check "arch: $script renders empty" [ -z "$out" ]
    done
    out=$(render .chezmoiexternal.toml.tmpl)
    check "arch: no mise external" hasnt '.local/bin/mise'
else
    out=$(render dot_config/mise/config.toml.tmpl)
    check "$os: mise config pins the tools" has '[tools]'
    out=$(render run_onchange_after_20-mise-install.sh.tmpl)
    check "$os: mise install script" has 'mise" install'
    out=$(render .chezmoiexternal.toml.tmpl)
    check "$os: mise external" has '.local/bin/mise'
fi

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
