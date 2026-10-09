#!/bin/sh
# nvim's project notes (lua/project_notes.lua) in a real UI (a scratch tmux server), with
# this branch's config in a scratch home: the <leader>p keys on a scratch repo's
# notes/, Enter on [[links]], and a repo without notes. The plugins are the installed
# ones (linked in, read only); `fish` is a stub that records what <leader>po runs.
# Run: sh tests/nvim-notes.sh
#   NVIM=path/to/nvim (default: nvim on PATH)

set -u
nvim=${NVIM:-nvim}
here=$(cd "$(dirname "$0")" && pwd)
data=${XDG_DATA_HOME:-$HOME/.local/share}/nvim
tmp=$(mktemp -d)
tm() { tmux -L nvim-notes -f /dev/null "$@"; }
trap 'tm kill-server 2>/dev/null; rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name ($*)"; fails=$((fails + 1)); fi
}

# a scratch home: this branch's config, the installed plugins
export HOME=$tmp/home XDG_CONFIG_HOME=$tmp/home/.config XDG_DATA_HOME=$tmp/home/.local/share \
    XDG_STATE_HOME=$tmp/home/.local/state XDG_CACHE_HOME=$tmp/home/.cache SHELL=/bin/sh
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME/nvim" "$tmp/bin"
cp -r "$here/../home/dot_config/nvim" "$XDG_CONFIG_HOME/nvim"
for d in lazy mason site; do ln -s "$data/$d" "$XDG_DATA_HOME/nvim/$d"; done
cat >"$tmp/bin/fish" <<EOF
#!/bin/sh
printf '%s\n' "\$@" >"$tmp/fish-args"
echo run >>"$tmp/fish-runs"
sleep 1.5
echo 'npm warn something' >&2
echo 'notes: http://localhost:8123/Shell'
EOF
chmod +x "$tmp/bin/fish"
export PATH="$tmp/bin:$PATH"

repo=$tmp/proj
mkdir -p "$repo/notes/decisions" "$repo/notes/journal" "$repo/src" && cd "$repo" && git init -q
printf 'int main(void) { return 0; }\n' >src/main.c
cat >notes/index.md <<'EOF'
# proj

Parts: [[Shell]] and [[Editor]].
Why fish: [[Use fish|the decision]].
Its reason: [[decisions/Use fish#Why]].
Not written yet: [[Ghost]].
EOF
printf '# Shell\n\nfish. Why: [[Use fish]]. Back: [[index]].\n' >notes/Shell.md
printf '# Editor\n\nnvim, with [[Shell keys]]. Not here: [[nowhere/Shell]].\n' >notes/Editor.md
printf '# Shell keys\n\n| Key | In |\n|---|---|\n| Ctrl+R | [[Shell\\|the shell]] |\n\n[[Editor]]\n' >"notes/Shell keys.md"
printf '# Use fish\n\nFor [[Shell]]. Short: [[#Why]], [[Use fish#Why|why]].\n\n## Why not\n\nbash, zsh.\n\n## Why\n\nAbbreviations.\n' >"notes/decisions/Use fish.md"
for m in 'M1 First' 'M9 Ninth' 'M10 Tenth'; do printf '# %s\n\n[[index]]\n' "$m" >"notes/journal/$m.md"; done
git add . && git -c user.email=t@t -c user.name=t commit -qm notes
mkdir -p "$tmp/other" && git -C "$tmp/other" init -q && printf 'x\n' >"$tmp/other/a.txt"

start() { # start DIR FILE
    tm kill-server 2>/dev/null
    tm new-session -d -x 160 -y 40 -c "$1" "$nvim '$2'"
    sleep 2.5 # past VeryLazy
}
keys() { tm send-keys -t 0 "$@"; sleep 0.6; }
screen() { tm capture-pane -p -t 0; }
shows() { screen | grep -qF -- "$1"; }
# probe LUA: the value of a Lua expression in the running nvim
probe() {
    rm -f "$tmp/probe"
    tm send-keys -t 0 Escape
    sleep 0.2
    tm send-keys -t 0 ":lua vim.fn.writefile({ tostring($1) }, '$tmp/probe')" Enter
    sleep 0.4
    cat "$tmp/probe" 2>/dev/null
}
file() { probe "vim.fn.expand('%:p')"; }
on() { # on TEXT: the cursor on the first TEXT in the buffer
    tm send-keys -t 0 Escape
    sleep 0.2
    keys ":call cursor(1, 1) | call search('\\V$1')" Enter
}

start "$repo" src/main.c
keys ' pi'
check "<leader>pi: the index, from a source file" [ "$(file)" = "$repo/notes/index.md" ]

on 'Shell]]'
keys Enter
check "Enter on [[Shell]]: Shell.md" [ "$(file)" = "$repo/notes/Shell.md" ]
keys ' pi'
on 'Use fish|'
keys Enter
check "Enter on [[Use fish|…]]: the note in decisions/" [ "$(file)" = "$repo/notes/decisions/Use fish.md" ]
keys ' pi'
on 'decisions/Use'
keys Enter
check "Enter on [[decisions/Use fish#Why]]: the note …" [ "$(file)" = "$repo/notes/decisions/Use fish.md" ]
check "  … at its heading (not one that starts the same)" [ "$(probe "vim.fn.getline('.')")" = '## Why' ]
on '#Why]]'
keys Enter
check "Enter on [[#Why]]: this note's heading" [ "$(probe "vim.fn.getline('.')")" = '## Why' ]
check "  … in this note" [ "$(file)" = "$repo/notes/decisions/Use fish.md" ]
keys ':call setline(1, "# Use fish!") | let v:errmsg = ""' Enter
on 'fish#Why'
keys Enter
check "Enter on a link to this changed note: its heading" [ "$(probe "vim.fn.getline('.')")" = '## Why' ]
check "  … no error" [ -z "$(probe vim.v.errmsg)" ]
keys u
keys ':e notes/Shell\ keys.md' Enter
on 'Shell\\|'
keys Enter
check "Enter on [[Shell\\|…]] in a table: Shell.md" [ "$(file)" = "$repo/notes/Shell.md" ]
keys ':e notes/Editor.md' Enter
on 'nowhere/Shell'
keys Enter
check "Enter on [[nowhere/Shell]]: no such note, as in Quartz" [ "$(file)" = "$repo/notes/nowhere/Shell.md" ]
keys ' pi'
on 'Parts'
keys Enter
check "Enter off a link: the next line, as usual" [ "$(probe "vim.fn.line('.')")" = 4 ]
on 'Ghost'
keys Enter
check "Enter on a link to no note: a new note …" [ "$(file)" = "$repo/notes/Ghost.md" ]
check "  … titled" [ "$(probe "vim.fn.getline(1)")" = '# Ghost' ]
check "  … not written until saved" [ ! -e "$repo/notes/Ghost.md" ]

keys ' pj'
check "<leader>pj: the latest journal note (M10, not M9)" [ "$(file)" = "$repo/notes/journal/M10 Tenth.md" ]

keys ' pf'
sleep 1
check "<leader>pf: find in the notes" shows 'Project notes'
check "  … lists the notes" shows 'decisions/Use fish.md'
check "  … and nothing else of the repo" sh -c "! tmux -L nvim-notes capture-pane -p -t 0 | grep -q main.c"
keys Escape Escape

keys ' pg'
sleep 0.5
keys Abbreviations
sleep 1
check "<leader>pg: grep the notes" shows 'Grep the project notes'
check "  … finds a note's line" shows 'Use fish.md'
keys Escape Escape

keys ' pi'
on 'Shell]]'
keys Enter
keys ' pb'
sleep 1
check "<leader>pb: the notes linking here" shows 'Notes linking to Shell'
check "  … the index, the decision, a table" sh -c "tmux -L nvim-notes capture-pane -p -t 0 | grep -q 'index.md' && tmux -L nvim-notes capture-pane -p -t 0 | grep -q 'decisions/Use fish.md' && tmux -L nvim-notes capture-pane -p -t 0 | grep -q 'Shell keys.md'"
check "  … not a link to Shell keys or to nowhere/Shell" sh -c "! tmux -L nvim-notes capture-pane -p -t 0 | grep -q 'Editor.md'"
keys Escape Escape

keys ":lua vim.env.PATH = '$tmp/nothing'" Enter
keys ' po'
check "<leader>po without fish: says so" shows 'ENOENT'
keys ':lua vim.env.PATH = "'"$PATH"'"' Enter
keys ' po'
check "  … and runs once fish is there" sh -c "sleep 0.3; [ -e '$tmp/fish-runs' ]"
sleep 2
rm -f "$tmp/fish-runs"
keys ' po'
keys ' po'
check "<leader>po again while it opens: says so" shows 'Still opening the notes'
sleep 1.5
check "<leader>po: notes FILE for this note" [ "$(tr '\n' ' ' <"$tmp/fish-args" 2>/dev/null)" = "-c notes \$argv $repo/notes/Shell.md " ]
check "  … once" [ "$(wc -l <"$tmp/fish-runs")" = 1 ]
check "  … and says where it opened" shows 'http://localhost:8123/Shell'

keys ' pn'
keys 'Idea' Enter
check "<leader>pn: a new note in notes/ …" [ "$(file)" = "$repo/notes/Idea.md" ]
check "  … titled" [ "$(probe "vim.fn.getline(1)")" = '# Idea' ]

keys ' '
sleep 1
check "which-key names the group" shows 'project notes'
keys Escape

start "$tmp/other" a.txt
keys ' pi'
check "a repo without notes: stays put" [ "$(file)" = "$tmp/other/a.txt" ]
check "  … and says so" shows 'other has no notes/index.md'

check "nothing was written" [ -z "$(git -C "$repo" status --short)" ]

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
