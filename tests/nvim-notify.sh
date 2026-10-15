#!/bin/sh
# nvim's notifications for a waiting Claude session (lua/control_board/notify.lua) in a
# real UI (a scratch tmux server), with this branch's config in a scratch home: a
# notification when a session starts asking for an answer or goes idle and when a review
# appears, none for what waited at the start, for a review the user put off or for the
# session you are typing in, and <leader>an to open the newest one. The plugins are the
# installed ones (linked in, read only). `board.py` is a stub that prints canned data,
# `claude` a stub (attach echoes what you type).
# Run: sh tests/nvim-notify.sh (takes ~1 minute)
#   NVIM=path/to/nvim (default: nvim on PATH)

set -u
nvim=${NVIM:-nvim}
here=$(cd "$(dirname "$0")" && pwd)
data=${XDG_DATA_HOME:-$HOME/.local/share}/nvim
tmp=$(mktemp -d)
tm() { tmux -L nvim-notify -f /dev/null "$@"; }
trap 'tm kill-server 2>/dev/null; rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name ($*)"; fails=$((fails + 1)); fi
}

unset CLAUDE_CONFIG_DIR TMUX # a session of Claude would leak its own account and tmux in
export HOME=$tmp/home XDG_CONFIG_HOME=$tmp/home/.config XDG_DATA_HOME=$tmp/home/.local/share \
    XDG_STATE_HOME=$tmp/home/.local/state XDG_CACHE_HOME=$tmp/home/.cache SHELL=/bin/sh
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME/nvim" "$tmp/bin" "$HOME/.claude-personal"
cp -r "$here/../home/dot_config/nvim" "$XDG_CONFIG_HOME/nvim"
for d in lazy mason site; do ln -s "$data/$d" "$XDG_DATA_HOME/nvim/$d"; done

# the stubs
cat >"$tmp/bin/board.py" <<EOS
open("$tmp/board-calls", "a").write("x")
print(open("$tmp/board.json").read())
EOS
cat >"$tmp/bin/claude" <<EOS
#!/bin/sh
echo "\${CLAUDE_CONFIG_DIR:-unset} \$PWD \$*" >>"$tmp/claude-calls"
case \$1 in
    attach) echo "ATTACHED \$2"; exec cat ;;
esac
EOS
chmod +x "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH" MILESTONE_FLOW_BOARD=$tmp/bin/board.py

# a scratch project with a review
proj=$tmp/proj
mkdir -p "$proj" && cd "$proj" && git init -q
seq 1 20 | sed 's/^/line /' >REVIEW.md
printf 'x\n' >src.txt
git add . && git -c user.email=t@t -c user.name=t commit -qm init

# canned data: what the collector would print. board SESSIONS REVIEWS, each a Python list:
#   sessions: (short id, name, activity, detail)     reviews: (title, put off)
board() {
    SESSIONS=$1 REVIEWS=$2 python3 - >"$tmp/board.json" <<'EOS'
import json, os, sys, time
now = time.time()
p = os.environ["PROJ"]
sessions = [
    {"id": s[0] + "-0000", "short": s[0], "account": "claude-personal", "config_dir": os.environ["HOME"] + "/.claude-personal",
     "kind": "background", "name": s[1], "cwd": p, "activity": s[2], "detail": s[3], "since": now - 60,
     "tmux": None, "project": "proj", "project_path": p}
    for s in eval(os.environ["SESSIONS"])]
needs = [
    {"kind": "review", "project": "proj", "title": r[0], "detail": "put off" if r[1] else "review waiting",
     "put_off": r[1], "since": now - 7200, "project_path": p, "path": p + "/REVIEW.md", "line": 1 + 4 * i}
    for i, r in enumerate(eval(os.environ["REVIEWS"]))]
json.dump({"now": now, "accounts": [], "needs": needs, "sessions": sessions,
           "projects": [{"name": "proj", "path": p, "current": None, "done": 0, "total": 0, "reviews": [], "waiting": []}],
           "counts": {"answer": 0, "review": len(needs), "waiting": 0, "working": 0, "sessions": len(sessions)}}, sys.stdout)
EOS
}
export PROJ=$proj

start() { # start ARGS...
    tm kill-server 2>/dev/null
    tm new-session -d -x 160 -y 40 -c "$proj" "$nvim $*"
    sleep 4 # past VeryLazy, and the 2 s before the notifications start listening
}
keys() { tm send-keys -t 0 "$@"; sleep 0.6; }
screen() { tm capture-pane -p -t 0; }
shows() { screen | grep -qF -- "$1"; }
# probe LUA: the value of a Lua expression in the running nvim (from Normal mode)
probe() {
    rm -f "$tmp/probe"
    tm send-keys -t 0 Escape
    sleep 0.2
    tm send-keys -t 0 ":lua vim.fn.writefile({ tostring($1) }, '$tmp/probe')" Enter
    sleep 0.4
    cat "$tmp/probe" 2>/dev/null
}
# lua STATEMENT: run it in the running nvim (from Normal mode)
lua() {
    tm send-keys -t 0 Escape
    sleep 0.2
    tm send-keys -t 0 ":lua $1" Enter
    sleep 0.4
}
# refresh: nvim asks the collector now, as its timer does every 10 s
refresh() { lua "require('control_board.data').refresh()"; sleep 1; }
dismiss() { lua "Snacks.notifier.hide()"; }
normal() { tm send-keys -t 0 'C-\' C-n; sleep 0.4; } # out of a session tab's Terminal mode
not() { ! "$@"; }
# noticed TEXT: the notifier has shown it (its history; a float over a session's tab is garbled)
noticed() { probe "vim.inspect(vim.tbl_map(function(n) return n.msg end, Snacks.notifier.get_history()))" | grep -qF -- "$1"; }

# ---- what waited at the start is not news ---------------------------------------------
board "[('abc12345', 'Fix parser', 'answer', 'Which parser?'), ('def67890', 'Write docs', 'working', '')]" \
    "[('M3 Third', False), ('M2 Second', True)]"
start src.txt
refresh # the first answer: remembered, not announced
check "at the start: a question and a review waiting are not announced" sh -c "! tmux -L nvim-notify capture-pane -p -t 0 | grep -q 'needs an answer\|ready for your review'"

# ---- what changes is ----------------------------------------------------------------------
board "[('abc12345', 'Fix parser', 'working', ''), ('def67890', 'Write docs', 'idle', ''), ('fed09876', 'Pick a DB', 'answer', 'Which database?   and\nmore'), ('ghi13579', 'Run tests', 'working', '')]" \
    "[('M3 Third', False), ('M2 Second', True), ('M5 Fifth', False), ('M9 Late', True)]"
refresh
check "a session that goes idle: a notification with the project's name" shows "Write docs is idle"
check "  … titled with the project" shows "proj"
check "a session that starts asking: its question" shows "Which database? and more"
check "  … on its own line, under the words that say it needs an answer" shows "Pick a DB needs an answer"
check "a review that appears: a notification" shows "M5 Fifth is ready for your review"
check "  … and a key to open it" shows "<leader>an opens it"
check "a question that turned into work: no notification" sh -c "! tmux -L nvim-notify capture-pane -p -t 0 | grep -q 'Fix parser'"
check "a review the user put off: no notification" sh -c "! tmux -L nvim-notify capture-pane -p -t 0 | grep -q 'M9 Late'"
check "a review that was already there: no notification" sh -c "! tmux -L nvim-notify capture-pane -p -t 0 | grep -q 'M3 Third is ready'"

# ---- <leader>an ---------------------------------------------------------------------------
dismiss
keys ' an'
check "<leader>an: the newest notification, the review, in REVIEW.md" [ "$(probe "vim.fn.expand '%:t'")" = REVIEW.md ]
check "  … at the review's line" [ "$(probe "vim.fn.line '.'")" = 9 ]
keys ' an'
sleep 1
check "  … again: the session that asks, in a tab" shows "ATTACHED fed09876"
normal
check "  … a tab of its own" [ "$(probe "vim.fn.tabpagenr '\$'")" = 3 ]
normal
keys ' an'
sleep 1
check "  … again: the session that went idle" shows "ATTACHED def67890"
normal
keys ' an'
check "  … and when they are all opened: it says so" noticed "No new Claude notification"

# ---- the session you are typing in ---------------------------------------------------------
dismiss
keys ':tabnew' Enter
keys ':lua require("control_board.session").open(require("control_board.data").last().sessions[1])' Enter
sleep 1
normal
board "[('abc12345', 'Fix parser', 'idle', ''), ('def67890', 'Write docs', 'idle', ''), ('fed09876', 'Pick a DB', 'answer', 'Which database?'), ('ghi13579', 'Run tests', 'idle', '')]" \
    "[('M3 Third', False), ('M2 Second', True), ('M5 Fifth', False), ('M9 Late', True)]"
refresh
check "Another session goes idle: announced" noticed "Run tests is idle"
check "The session whose tab you are in goes idle: not announced to you" not noticed "Fix parser is idle"
keys ':tabclose' Enter

# ---- it polls by itself -------------------------------------------------------------------
start src.txt
: >"$tmp/board-calls"
sleep 13
check "nvim asks the collector by itself, every few seconds" [ "$(wc -c <"$tmp/board-calls")" -ge 1 ]
board "[('abc12345', 'Fix parser', 'idle', '')]" "[('M3 Third', False), ('M6 Sixth', False)]"
sleep 12
check "  … a review that appears while you work" shows "M6 Sixth is ready for your review"

echo
[ "$fails" = 0 ] && echo "all passed" || echo "$fails failed"
exit "$fails"
