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
# modify FILE CURRENT [DESKTOP]: a modify-template's output for a target that holds
# CURRENT, with .desktop set (default true)
modify() {
    chezmoi execute-template --source "$src" --override-data \
        "{\"desktop\": ${3:-true}, \"chezmoi\": {\"stdin\": $(printf '%s' "$2" | python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))')}}" \
        <"$src/home/$1"
}
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

# Claude Code's settings.json: the shared keys on every machine, the machine's own
# (theme) kept
out=$(modify dot_claude/modify_settings.json '')
check "claude settings: a new file gets the status line" has '"command": "bash ~/.claude/statusline-command.sh"'
out=$(modify dot_claude/modify_settings.json '{"theme": "light", "statusLine": {"type": "command", "command": "old"}}')
check "claude settings: the machine's theme stays" has '"theme": "light"'
check "claude settings: shared keys win" hasnt '"old"'
out=$(modify dot_claude/modify_settings.json '{"env": {"OWN": "1"}}')
check "claude settings: auto-connect to nvim, the machine's env kept" python3 -c '
import json, sys
env = json.loads(sys.argv[1])["env"]
sys.exit(env != {"OWN": "1", "CLAUDE_CODE_AUTO_CONNECT_IDE": "1"})' "$out"
# Desktops: the busy hook (polybar's spinning glyph) on its events; nowhere else
out=$(modify dot_claude/modify_settings.json '{}')
check "claude settings: busy hook on and off on a desktop" python3 -c '
import json, sys
hooks = json.loads(sys.argv[1])["hooks"]
cmd = lambda event: hooks[event][0]["hooks"][0]["command"]
on = [e for e in hooks if cmd(e).endswith(" on || :")]
off = [e for e in hooks if cmd(e).endswith(" off || :")]
ok = (sorted(on) == ["PostToolUse", "UserPromptSubmit"]
      and sorted(off) == ["Notification", "SessionEnd", "Stop", "StopFailure"]
      and "idle_prompt" in hooks["Notification"][0]["matcher"]
      and all(cmd(e).startswith("sh ~/.claude/busy-hook.sh ") for e in hooks))
sys.exit(not ok)' "$out"
out=$(modify dot_claude/modify_settings.json '{}' false)
check "claude settings: no hooks elsewhere" hasnt '"hooks"'

# Per machine: arch uses pacman, so its mise config has only the settings (per-project
# versions), and it gets no mise external, no scripts and no apt list.
os=$(chezmoi execute-template --source "$src" '{{ .chezmoi.osRelease.id }}')
out=$(chezmoi execute-template --source "$src" <"$src/home/.chezmoiignore")
check "$os: mise config not ignored" hasnt '.config/mise/**'
if [ "$os" = arch ]; then
    out=$(render dot_config/mise/config.toml.tmpl)
    check "arch: mise config has no [tools]" hasnt '[tools]'
    for script in run_onchange_after_20-mise-install.sh.tmpl run_onchange_after_25-fisher.sh.tmpl \
        run_onchange_after_30-packages.sh.tmpl run_onchange_after_40-nvim-plugins.sh.tmpl; do
        out=$(render "$script")
        check "arch: $script renders empty" [ -z "$out" ]
    done
    out=$(render .chezmoiexternal.toml.tmpl)
    check "arch: no mise external" hasnt '.local/bin/mise'
    check "arch: no btop theme external (pacman's btop has its themes)" hasnt '.config/btop/themes'
else
    out=$(render dot_config/mise/config.toml.tmpl)
    check "$os: mise config pins the tools" has '[tools]'
    out=$(render run_onchange_after_20-mise-install.sh.tmpl)
    check "$os: mise install script" has 'mise" install'
    out=$(render run_onchange_after_40-nvim-plugins.sh.tmpl)
    check "$os: nvim install script" has 'nvim --headless'
    out=$(render .chezmoiexternal.toml.tmpl)
    check "$os: mise external" has '.local/bin/mise'
fi

# btop's seed names a theme; off arch, mise's btop can't find its own themes, so an
# external brings that file. Rendered as Ubuntu, so it's checked on arch too.
theme=$(sed -n 's/^color_theme = "\(.*\)"$/\1/p' "$src/home/dot_config/btop/create_btop.conf")
out=$(chezmoi execute-template --source "$src" --override-data '{"chezmoi": {"osRelease": {"id": "ubuntu"}}}' \
    <"$src/home/.chezmoiexternal.toml.tmpl")
check "ubuntu: btop's theme \"$theme\" comes as an external" has "\".config/btop/themes/$theme.theme\""

# polybar stops when a file it includes is missing: colors.ini is seeded (theme-switcher
# rewrites it later) and defines every color the config uses
seed="$src/home/dot_config/polybar/create_colors.ini"
keys=$(sed -n 's/^\([a-z-]*\) = .*/\1/p' "$seed" 2>/dev/null)
missing=$(grep -v '^[[:space:]]*;' "$src/home/dot_config/polybar/config.ini" | grep -o '${colors\.[a-z-]*}' | sort -u |
    sed 's/^${colors\.\(.*\)}$/\1/' |
    while IFS= read -r key; do printf '%s\n' "$keys" | grep -qx -- "$key" || echo "$key"; done)
check "polybar: colors.ini is seeded" [ -f "$seed" ]
check "polybar: the seed has every color the config uses" [ -z "$missing" ]
[ -z "$missing" ] || printf '     not in the seed: %s\n' "$missing"

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
