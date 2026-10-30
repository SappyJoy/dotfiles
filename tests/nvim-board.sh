#!/bin/sh
# nvim's control board (lua/control_board/) in a real UI (a scratch tmux server), with
# this branch's config in a scratch home: the first page's line and key, the board
# (plan usage, Needs you, Sessions, Projects), its keys on a scratch project (open a
# session tab, tick, comment, Inbox note, new session), the picker, the refresh, and
# the fish functions cb and cl. The plugins are the installed ones (linked in, read
# only). `board.py` is a stub that prints canned data, `claude` a stub (attach echoes
# what you type), `tmux` records the jump to a session started by hand.
# Run: sh tests/nvim-board.sh
#   NVIM=path/to/nvim (default: nvim on PATH)

set -u
nvim=${NVIM:-nvim}
here=$(cd "$(dirname "$0")" && pwd)
data=${XDG_DATA_HOME:-$HOME/.local/share}/nvim
real_tmux=$(command -v tmux)
tmp=$(mktemp -d)
tm() { tmux -L nvim-board -f /dev/null "$@"; }
trap 'tm kill-server 2>/dev/null; rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name ($*)"; fails=$((fails + 1)); fi
}

unset CLAUDE_CONFIG_DIR # a session of Claude would leak its own account in
export HOME=$tmp/home XDG_CONFIG_HOME=$tmp/home/.config XDG_DATA_HOME=$tmp/home/.local/share \
    XDG_STATE_HOME=$tmp/home/.local/state XDG_CACHE_HOME=$tmp/home/.cache SHELL=/bin/sh
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME/nvim" "$tmp/bin" "$HOME/.claude-personal"
cp -r "$here/../home/dot_config/nvim" "$XDG_CONFIG_HOME/nvim"
for d in lazy mason site; do ln -s "$data/$d" "$XDG_DATA_HOME/nvim/$d"; done

# the stubs
cat >"$tmp/bin/board.py" <<EOS
import os, sys
open("$tmp/board-calls", "a").write("x")
if os.path.exists("$tmp/board-fails"):
    sys.exit("boom")
if sys.argv[1] == "--tail":
    print("TAIL OF " + sys.argv[2])
else:
    print(open("$tmp/board.json").read())
EOS
cat >"$tmp/bin/runner_status.py" <<EOS
import sys
open("$tmp/runner-calls", "a").write(" ".join(sys.argv[1:]) + "\\n")
print(open("$tmp/runners.json").read())
EOS
cat >"$tmp/bin/claude" <<EOS
#!/bin/sh
echo "\${CLAUDE_CONFIG_DIR:-unset} \$PWD \$*" >>"$tmp/claude-calls"
case \$1 in
    --bg) echo "backgrounded · feed1234" ;;
    attach) echo \$\$ >"$tmp/attach.pid.\$2"; echo "ATTACHED \$2"; trap 'exit 0' TSTP; while IFS= read -r l; do echo "\$l"; done ;;
esac
EOS
cat >"$tmp/bin/tmux" <<EOS
#!/bin/sh
[ "\$1" = switch-client ] && echo "\$*" >>"$tmp/tmux-calls"
exec "$real_tmux" "\$@"
EOS
cat >"$tmp/bin/asciinema" <<EOS
#!/bin/sh
echo "\$*" >>"$tmp/asciinema-calls"
echo "PLAYING \$2"
sleep 1.5
echo "THE LAST FRAME"
EOS
chmod +x "$tmp/bin/claude" "$tmp/bin/tmux" "$tmp/bin/asciinema"
export PATH="$tmp/bin:$PATH" MILESTONE_FLOW_BOARD=$tmp/bin/board.py

# a scratch project with a roadmap, a review and an inbox
proj=$tmp/proj
mkdir -p "$proj" && cd "$proj" && git init -q
cat >ROADMAP.md <<'EOF'
# proj

A project.

## Now

M3 is in review.

## Waiting on you

- [ ] Review M3 — in REVIEW.md; Claude waits for it
- [ ] Log in to npm: `npm login` — M4 needs it
- [ ] Try the demo

## Next

- [ ] M4 Four — more
EOF
cat >TRACK.md <<'EOF'
# Track scorer

The scorer findings, in three lines.
EOF
cat >REVIEW.md <<'EOF'
# Review: M3 🚦 Third

Look at the page.

## Questions

1. Is it fine?

# Review: M2 🚦 Second

Put off 2026-10-01: later.
EOF
mkdir -p .agent/review/M3
printf '{"version": 2, "width": 100, "height": 28}\n' >.agent/review/M3/demo.cast
printf '# Inbox\n\nNotes for later.\n\n- first\n\n' >INBOX.md
printf 'x\n' >src.txt
git add . && git -c user.email=t@t -c user.name=t commit -qm init

# week.py, next to the stub board.py: canned Week data (the second line shows what a run costs)
cat >"$tmp/bin/week.py" <<EOS
import json, os, time
open("$tmp/week-calls", "a").write("x")
if os.path.exists("$tmp/week-fails"):
    raise SystemExit("week boom")
now = time.time()
days = [time.strftime("%Y-%m-%d", time.localtime(now - n * 86400)) for n in range(6, -1, -1)]
print(json.dumps({
    "days": days,
    "tokens": {"total": 3000000, "projects": [
        {"name": "proj", "days": [0, 0, 100, 400000, 0, 800000, 1200000], "total": 2400000},
        {"name": "other", "days": [0, 0, 0, 0, 0, 0, 600000], "total": 600000}],
        "top_prompt": {"project": "proj", "text": "fix the parser", "tokens": 900000}},
    "windows": [{"account": "personal", "kind": "5h", "pct": 92, "resets_at": now - 3600},
                {"account": "personal", "kind": "5h", "pct": 30, "resets_at": now + 3600}],
    "milestones": [{"project": "proj", "count": 3}],
    "growth": [{"name": "proj", "path": "$proj", "loc": 12500, "added": 3400, "removed": 200,
        "grew": [{"part": "lib/parser", "delta": 900}], "new": ["lib/report"],
        "big": [{"path": "src.txt", "lines": 412}]}]}))
EOS
# canned data: what the collector would print. board SESSION_NAME STATE
board() {
    python3 - "$@" >"$tmp/board.json" <<EOS
import json, sys, time
now = time.time()
p = "$proj"
name, state = sys.argv[1], sys.argv[2]
bg = lambda short, name, activity, detail: {
    "id": short + "-0000", "short": short, "account": "claude-personal",
    "config_dir": "$HOME/.claude-personal", "kind": "background", "name": name, "cwd": p,
    "activity": activity, "detail": detail, "since": now - 600, "tmux": None,
    "project": "proj", "project_path": p}
asking = bg("abc12345", name, state, "Which parser?")
hand = {"id": "hand-1", "short": None, "account": "claude-personal",
        "config_dir": "$HOME/.claude-personal", "kind": "interactive", "name": "by-hand",
        "cwd": p, "activity": "idle", "detail": "", "since": now - 3000,
        "tmux": "0:@3.%7", "project": "proj", "project_path": p}
loose = dict(hand, id="hand-2", name="loose", tmux=None)
sessions = [asking, bg("def67890", "Write docs", "working", ""), hand, loose]
waiting = lambda text, line: {"kind": "waiting", "project": "proj", "title": text, "detail": "",
    "since": now - 90000, "project_path": p, "path": p + "/ROADMAP.md", "line": line}
needs = []
if state == "answer":
    needs.append({"kind": "answer", "project": "proj", "title": name, "detail": "Which parser?",
        "since": now - 600, "session": asking["id"], "project_path": p})
needs.append({"kind": "review", "project": "proj", "title": "M3 Third", "detail": "review waiting",
    "since": now - 7200, "project_path": p, "path": p + "/REVIEW.md", "line": 1})
needs.append({"kind": "track", "project": "proj", "title": "track scorer", "detail": "report ready",
    "since": now - 3600, "project_path": p, "path": p + "/TRACK.md"})
needs.append(waiting("Log in to npm: \`npm login\` — M4 needs it", 12))
needs.append(waiting("Try the demo", 13))
if len(sys.argv) > 3:  # another project, in another folder, with the same name
    other = "$tmp/other/proj"
    needs.append(dict(waiting("Other thing", 5), project_path=other, path=other + "/ROADMAP.md"))
runner = lambda id, state, label, short, idle, steps: {
    "id": id, "project": "proj", "project_path": p, "milestone": "M7", "label": label, "state": state,
    "short": short, "idle": idle, "tokens": 2000,
    "detail": ["proj · M7 Runner status", "state    " + state, "steps    " + steps + " ticked",
               "now      " + short.split(" · ")[0], "recent", "  " + short.split(" · ")[0]]}
runners = [
    runner("r-work", "working", "M7 · 2/4 steps", "Edit board.py · 2k tokens", 120, "2 of 4"),
    runner("r-wait", "waiting", "M8 · 1/3 steps", "Bash: sleep 240 · 5k tokens", 400, "1 of 3"),
    runner("r-stall", "stalled", "M9 · 3/4 steps", "Bash: make check · 9k tokens", 2400, "3 of 4")]
json.dump(runners, open("$tmp/runners.json", "w"))
projects = [{"name": "proj", "path": p,
    "current": {"id": "M3", "gate": True, "title": "Third", "status": "review"},
    "done": 2, "total": 4, "reviews": [], "waiting": []}]
if len(sys.argv) > 3:
    projects.append(dict(projects[0], path=other))
json.dump({
    "now": now,
    "accounts": [
        {"key": "claude", "label": "team", "five_hour": None, "seven_day": None},
        {"key": "claude-personal", "label": "personal",
         "five_hour": {"pct": 34, "resets_at": now + 3 * 3600},
         "seven_day": {"pct": 61, "resets_at": now + 3 * 86400}}],
    "needs": needs, "sessions": sessions, "runners": runners,
    "projects": projects,
    "counts": {"answer": 1 if state == "answer" else 0, "review": 1, "track": 1, "waiting": 2,
        "working": 1, "sessions": 4, "runners": 3}}, sys.stdout)
EOS
}
board "Fix parser" answer

start() { # start ARGS...
    tm kill-server 2>/dev/null
    # a server that is still going down (nvim has just quit, the machine is busy) refuses the new session: ask again
    for _ in 1 2 3 4 5 6; do
        tm new-session -d -x 160 -y 70 -c "$proj" "$nvim $*" 2>/dev/null && break
        sleep 1
    done
    sleep 4 # past VeryLazy, and the first run of the collector
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
on() { # on TEXT: the cursor on the first line with TEXT
    tm send-keys -t 0 Escape
    sleep 0.2
    keys ":call cursor(1, 1) | call search('\\V$1') | normal! zv" Enter
}
normal() { tm send-keys -t 0 'C-\' C-n; sleep 0.4; } # out of a session tab's Terminal mode

# ---- the first page -------------------------------------------------------------
start
check "first page: the line with the counts" shows "Control board   ❓1  🚦1  ☐2  ⏳1 working"
check "  … and its key b" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep 'Control board' | grep -q ' b\$'"
check "  … the art, the name and the quote stay" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '████████╗██╗   ██╗██████╗' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Чехов' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Find file'"

# ---- the board ------------------------------------------------------------------
keys b
# the board opens on what needs you, the other sections folded
check "b: the board opens on Needs you" shows "Needs you (5)"
check "  … Needs you is open: its rows show" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Which parser' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Log in to npm'"
check "  … Plan, Sessions, Projects and the Week are folded: their headings stay, their rows hide" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Plan ▸ 4 lines' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Sessions (4) ▸ 4 lines' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Projects ▸' && ! tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Write docs' && ! tmux -L nvim-board capture-pane -p -t 0 | grep -q '34%'"
check "  … the cursor is on the first thing that needs you" [ "$(probe "vim.api.nvim_get_current_line():find('Which parser', 1, true) ~= nil")" = true ]
check "  … the footer lists the keys, five or so" shows "⏎ open · t tick · s jump · a new session · ? all keys"
keys ":call cursor(1, 1) | call search('Sessions (')" Enter # on() would unfold it
keys Enter
check "Enter on a folded heading: the section opens" shows "Write docs"
keys Enter
check "  … and again: it folds" sh -c "! tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Write docs'"
keys r
sleep 2
check "  … the refresh keeps it folded" sh -c "! tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Write docs'"
keys Enter
sleep 3
check "  … and an opened section stays open through a refresh" shows "Write docs"
keys Enter
on 'M3 Third'
keys zc
keys Enter
check "Enter on a section closed with zc (cursor on a hidden row): the section opens, no file" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'M3 Third' && [ \"\$(tmux -L nvim-board capture-pane -p -t 0 | grep -c 'Look at the page')\" = 0 ]"
keys Enter
sleep 1
check "a review opened from the board (Enter on M3 Third): its window has none of the board's window options" [ "$(probe "tostring(vim.wo.foldtext:find('control_board') == nil and vim.wo.fillchars:find('fold: ', 1, true) == nil and vim.go.signcolumn == 'yes' and vim.go.cursorline)")" = true ]
keys ':tabclose' Enter
keys s
check "s on the board: flash waits for text (⚡ in the command line)" shows "⚡"
keys 'Log in'
keys Enter
check "  … and Enter jumps to the one match" [ "$(probe "vim.api.nvim_get_current_line():find('Log in', 1, true) ~= nil")" = true ]
check "every <leader>a key has a label for which-key" [ "$(probe "#vim.tbl_filter(function(m) return m.lhs:match('^ a') and (m.desc or '') == '' end, vim.api.nvim_get_keymap 'n')")" = 0 ]
keys zR
check "b: the board" shows "Plan ──"
check "  … a bar with the percent and its reset" shows "34%  resets in 3h"
check "  … a window with no data" shows "no data yet"
check "  … Needs you, Sessions, Projects" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Needs you (5)' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Sessions (4)' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Projects ──'"
check "  … a session that asks, a review, a waiting line" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Which parser' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'M3 Third' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Log in to npm'"
check "  … a project with its milestone and progress" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'M3 🚦 Third · review.*2 of 4 done'"
check "  … the review has a recording: a ▶ after its icon" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '▶ proj *M3 Third'"
check "  … and no other row has one" sh -c "[ \$(tmux -L nvim-board capture-pane -p -t 0 | grep -c '▶') = 1 ]"
check "  … a finished track under Needs you" shows "track scorer"
check "  … the Week: tokens per project with their share" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Week ──' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'proj *2.4M.* 80%'"
check "  … a spark for each day, and the costliest prompt" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '▁▁▁▃▁▆█' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Costliest prompt: 900k in proj, \"fix the parser\"'"
check "  … the 5-hour windows as bars, milestones finished, code growth" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '5h personal' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Milestones finished: proj 3' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'proj *13k *+3.4k −200' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'lib/parser +900 · new: lib/report' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'src.txt *412 lines'"
check "  … Runners: a working, a waiting and a stalled one, with their state" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Runners (3)' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'M7 · 2/4 steps *Edit board.py · 2k tokens *working *2m' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'M8 · 1/3 steps.*waiting *6m' && tmux -L nvim-board capture-pane -p -t 0 | grep -q '🛑 *proj *M9 · 3/4 steps.*stalled *40m'"
on 'M9 · 3/4'
keys Enter
check "Enter on a runner: its detail in a window" shows "state    stalled"
check "  … with its keys on screen" shows "r refresh  q or Esc close"
check "  … only that runner's" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'steps    3 of 4 ticked' && ! tmux -L nvim-board capture-pane -p -t 0 | grep -q 'steps    2 of 4'"
keys q
check "  … q closes it: the board again, no empty window left" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Runners (3)' && ! tmux -L nvim-board capture-pane -p -t 0 | grep -q '╭'"
keys ' aS'
sleep 1
check "<leader>aS: every runner's detail, asked for apart from the board" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'steps    2 of 4 ticked' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'state    waiting' && grep -q -- '--json' '$tmp/runner-calls'"
sed -i 's/Edit board.py/Write runner.py/g' "$tmp/runners.json"
keys r
sleep 1
check "  … r asks again" shows "Write runner.py"
keys q
check "  … q closes it too" sh -c "! tmux -L nvim-board capture-pane -p -t 0 | grep -q '╭'"
on 'src.txt'
keys Enter
check "Enter on a flagged file: the file" [ "$(probe "vim.fn.expand('%:t')")" = "src.txt" ]
keys ':bd' Enter
keys b
keys zR
on 'track scorer'
keys Enter
check "Enter on a track: its TRACK.md" shows "The scorer findings"
keys ':bd' Enter
keys b
keys zR
keys q
check "q: back to the first page" shows "Find file"

# ---- session tabs -----------------------------------------------------------------
keys b
keys zR
on 'Fix parser'
keys Enter
sleep 1
check "Enter on a session: a tab running claude attach" shows "ATTACHED abc12345"
check "  … with the personal account's folder" grep -q "^$HOME/.claude-personal .* attach abc12345" "$tmp/claude-calls"
check "  … a winbar: project, name, state" shows "proj · Fix parser · needs you"
keys hello
check "  … what you type reaches the session" shows "hello"
normal
check "  … Normal mode keeps the screen" shows "ATTACHED abc12345"
keys ' ab'
check "<leader>ab from a session tab: back to the board, no error" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Plan ──' && ! tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Invalid window'"
on 'Fix parser'
keys Enter
sleep 1
check "Enter on the same session again: its tab, not a second attach" [ "$(grep -c ' attach abc12345' "$tmp/claude-calls")" = 1 ]
check "  … the footer lists its keys" shows "Alt+A menu · Alt+A Esc scroll · Ctrl+6 board · Ctrl+Z detach"
keys M-a b
check "Alt+A B from the prompt: back to the board" shows "Plan ──"
on 'Fix parser'
keys Enter
sleep 1
keys M-a w
sleep 2
check "Alt+A W from the prompt: the picker" shows "Claude: needs you, sessions, projects"
keys C-c
check "  … closing it: the session's tab again" shows "ATTACHED abc12345"
keys i
keys M-ф е
check "Alt+Ф Е in the Russian layout: the board" shows "Plan ──"
on 'Fix parser'
keys Enter
sleep 1
board "Fix parser" working
sleep 7
check "the winbar follows the session (working)" shows "proj · Fix parser · working"
normal
keys q
check "q in a session tab: the tab closes" [ "$(probe "vim.fn.tabpagenr '\$'")" = 2 ]

# ---- keys in a session window -------------------------------------------------------
on 'Fix parser'
keys Enter
sleep 1
keys M-a
sleep 1.5
check "Alt+A waits past timeoutlen (300 ms): the Claude menu is still open" shows "Control board"
check "  … and the terminal did not go back to typing" sh -c "! tmux -L nvim-board capture-pane -p -t 0 | grep -q ' TERMINAL '"
keys Escape
check "  … Esc closes the menu and stays in Normal mode" shows " NORMAL "
check "  … the footer lists the Normal mode keys" shows "i type · Ctrl+U/Ctrl+D page · G end · Ctrl+6 board · Alt+A menu · ? keys"
keys C-u
check "Ctrl+U in Normal mode: Claude gets PageUp" shows "[5~"
keys C-d
check "Ctrl+D: PageDown" shows "[6~"
keys G
check "G: the end" shows "[1;5F"
keys '?'
check "?: the cheat sheet, at the board" shows "Control board (all your Claude sessions, in nvim)"
keys q
keys i
check "i: back to typing" shows " TERMINAL "
keys C-^
check "Ctrl+6 in a session: the board" shows "Needs you ("
keys C-^
check "Ctrl+6 on the board: the last session, ready to type" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q ' TERMINAL ' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'ATTACHED abc12345'"
keys C-z
sleep 1
check "Ctrl+Z (the client exits): the board, and the session's tab is gone" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Needs you (' && [ \"\$(grep -c ' attach abc12345' '$tmp/claude-calls')\" -ge 1 ]"
check "  … no session window left" [ "$(probe "#vim.tbl_filter(function(b) return vim.b[b].control_session ~= nil end, vim.api.nvim_list_bufs())")" = 0 ]
keys C-^
check "Ctrl+6 with no session window: says so" shows "No session window yet"
on 'Fix parser'
keys Enter
sleep 1
keys M-ф
sleep 1
check "Alt+Ф (Russian layout): the menu too" shows "Control board"
keys Escape
normal
keys q
check "q from Normal mode: the board" shows "Needs you ("

# ---- the keys of the board ----------------------------------------------------------
keys ':ControlBoard' Enter
keys zR
on 'Log in to npm'
keys t
sleep 1
check "t on a Waiting on you line: ticked in ROADMAP.md" grep -q '^- \[x\] Log in to npm: `npm login`' "$proj/ROADMAP.md"
check "  … the others stay" grep -q '^- \[ \] Try the demo' "$proj/ROADMAP.md"
on 'M3 Third'
keys t
check "t on a review: nothing more ticked" [ "$(grep -c '^- \[x\]' "$proj/ROADMAP.md")" = 1 ]

on 'M3 Third'
keys c
keys 'Looks good'
keys Escape
keys ':w' Enter
check "c on a review: REVIEW.md opens in Insert mode, in a Your reply section" sh -c "grep -A1 '^## Your reply' '$proj/REVIEW.md' | tail -1 | grep -qx 'Looks good'"
check "  … at the end of that review, not the next" sh -c "awk '/^## Your reply/{f=1} /^# Review: M2/{exit} END{exit !f}' '$proj/REVIEW.md'"
keys ':tabclose' Enter
on 'M3 Third'
keys c
keys 'More'
keys Escape
keys ':w' Enter
check "c again: the same section" [ "$(grep -c '^## Your reply' "$proj/REVIEW.md")" = 1 ]
keys ':tabclose' Enter

on 'M3 Third'
keys i
keys 'try dark mode' Enter
sleep 1
check "i: a line in the project's INBOX.md" [ "$(tail -1 "$proj/INBOX.md")" = '- try dark mode' ]
check "  … the others stay" grep -qx -- '- first' "$proj/INBOX.md"

# Claude rewrote ROADMAP.md while nvim held it: the tick lands on the new text, no prompt
keys ':tabedit ROADMAP.md' Enter
sed -i 's/^M3 is in review\./M3 changed outside./' "$proj/ROADMAP.md"
keys ':ControlBoard' Enter
keys zR
on 'Log in to npm'
keys Tab
on 'Try the demo'
keys t
sleep 1
check "t after ROADMAP.md changed on disk: ticked, and the outside change stays" sh -c "grep -q '^- \[x\] Try the demo' '$proj/ROADMAP.md' && grep -q 'M3 changed outside' '$proj/ROADMAP.md'"
check "  … nvim doesn't stop to ask" sh -c "! tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Do you really want'"
# unsaved edits in nvim stop a change to the same file
keys ':tabedit INBOX.md' Enter
keys 'Gotyped'
keys Escape
keys ':ControlBoard' Enter
keys zR
on 'M3 Third'
keys i
keys 'blocked note' Enter
sleep 1
check "i with unsaved changes to INBOX.md in nvim: the file stays as it is" [ "$(grep -c 'blocked note' "$proj/INBOX.md")" = 0 ]
check "  … and it says why" shows "unsaved changes"
keys ':bwipeout! INBOX.md' Enter
# a file that can't be written
chmod 444 "$proj/INBOX.md"
on 'M3 Third'
keys i
keys 'no room' Enter
sleep 1
check "i when INBOX.md can't be written: it says so" shows "Could not write"
chmod 644 "$proj/INBOX.md"
keys ':bwipeout ROADMAP.md' Enter
# the review moved down in REVIEW.md: c finds its heading
sed -i '1i Preface' "$proj/REVIEW.md"
keys ':ControlBoard' Enter
keys zR
on 'M3 Third'
keys c
keys 'Third time'
keys Escape
keys ':w' Enter
check "c after the review moved down: the same Your reply section" sh -c "[ \"\$(grep -c '^## Your reply' '$proj/REVIEW.md')\" = 1 ] && grep -q 'Third time' '$proj/REVIEW.md' && [ \"\$(head -1 '$proj/REVIEW.md')\" = Preface ]"
keys ':tabclose' Enter

check "n on the board stays search-next" [ "$(probe "vim.fn.maparg('n', 'n')")" = "" ]
on 'M3 Third'
keys a
sleep 2
check "a: claude --bg in the project" grep -q "^unset $proj --bg" "$tmp/claude-calls"
check "  … and its tab" shows "ATTACHED feed1234"
check "  … the winbar before the board knows it" shows "proj · feed1234 · attached"
normal
keys q

# ---- sessions started by hand -------------------------------------------------------
keys ':ControlBoard' Enter
keys zR
on 'loose'
keys Enter
check "Enter on a session outside tmux: it says so" shows "outside tmux"
on 'by-hand'
keys Enter
check "Enter on a session in tmux: jumps to its pane" grep -q 'switch-client -t 0 ; select-window -t @3 ; select-pane -t %7' "$tmp/tmux-calls"

on 'Write docs'
keys Enter
sleep 1
check "Enter on a background session in Sessions: its tab" shows "ATTACHED def67890"
normal
keys ':tabclose' Enter
sleep 1
check "  … closing its tab ends the claude attach" sh -c "[ -s '$tmp/attach.pid.def67890' ] && ! kill -0 \$(cat '$tmp/attach.pid.def67890') 2>/dev/null"

# ---- the picker -------------------------------------------------------------------
keys ':tabonly' Enter
keys ' aw'
sleep 2
check "<leader>aw: a picker over the board's rows" shows "Claude: needs you, sessions, projects"
check "  … sessions, a review, a project" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Write docs' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'M3 Third'"
check "  … the review has the same ▶ for its recording" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '▶ *proj *M3 Third'"
check "  … and a session has none" sh -c "! tmux -L nvim-board capture-pane -p -t 0 | grep 'Write docs' | grep -q '▶'"
keys 'docs'
sleep 1
check "  … a preview of the session" shows "TAIL OF def67890"
keys Enter
sleep 1
check "  … Enter opens the session" shows "ATTACHED def67890"
normal
keys q

# ---- every past session ------------------------------------------------------------------
# real transcripts in the scratch home, read by the toolkit's sessions.py
tools=${MILESTONE_FLOW_SESSIONS:-$(getent passwd "$(id -un)" | cut -d: -f6)/src/personal/claude/toolkit/plugins/milestone-flow/scripts/sessions.py}
mkdir -p "$HOME/.claude/projects/p"
past() { # past ID TITLE CWD PROMPT REPLY DAY
    printf '%s\n%s\n%s\n' \
        "{\"type\":\"ai-title\",\"aiTitle\":\"$2\",\"sessionId\":\"$1\"}" \
        "{\"type\":\"user\",\"cwd\":\"$3\",\"timestamp\":\"$6T10:00:00Z\",\"message\":{\"role\":\"user\",\"content\":\"$4\"}}" \
        "{\"type\":\"assistant\",\"timestamp\":\"$6T10:00:05Z\",\"message\":{\"role\":\"assistant\",\"content\":[{\"type\":\"text\",\"text\":\"$5\"}]}}" \
        >"$HOME/.claude/projects/p/$1.jsonl"
}
past aaaa1111 "Cleared parser work" "$proj" "tune the parser" "the zebra heuristic is slow" 2026-10-01
past def67890-0000 "Open one" "$proj" "docs please" "writing docs now" 2026-10-02
past cccc3333 "Gone folder" "$tmp/removed" "old idea" "nothing left" 2026-09-30
: >"$tmp/claude-calls"
keys ":let \$MILESTONE_FLOW_SESSIONS='$tools'" Enter
keys ':tabonly' Enter
keys ' ar'
sleep 3
check "<leader>ar: a picker over every past session" shows "Cleared parser work"
check "  … with project, date and first prompt" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '2026-10-01 *proj *Cleared parser work *tune'"
check "  … newest nearest the prompt" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -E 'Open one|Cleared parser|Gone folder' | grep -o -E 'Open one|Cleared parser|Gone folder' | tr '\n' ',' | grep -q '^Gone folder,Cleared parser,Open one,'"
keys 'parser'
sleep 1
check "  … a preview of the conversation" shows "the zebra heuristic is slow"
check "  … rendered: a heading for each prompt and reply, no # marks" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '● Claude' && ! tmux -L nvim-board capture-pane -p -t 0 | grep -q '# ● Claude'"
keys Enter
sleep 2
check "  … Enter resumes it from its folder, under its account" grep -qx "$HOME/.claude-personal $proj --bg --resume aaaa1111" "$tmp/claude-calls"
check "  … and opens it in a tab" shows "ATTACHED feed1234"
normal
keys q
keys ' ar'
sleep 2
keys 'Open one'
sleep 1
keys Enter
sleep 2
check "A session that is open already: its tab, no second session" shows "ATTACHED def67890"
check "  … started nothing" [ "$(grep -c -- '--resume' "$tmp/claude-calls")" = 1 ]
normal
keys q
keys ' ar'
sleep 2
keys 'Gone folder'
sleep 1
keys Enter
sleep 1
check "A session whose folder is gone: says so" shows "which is gone"
check "  … and starts nothing" [ "$(grep -c -- '--resume' "$tmp/claude-calls")" = 1 ]
keys ' aR'
sleep 2
keys 'zebra'
sleep 2
check "<leader>aR: searches what was said, with the matching line" shows "the zebra heuristic is slow"
check "  … and shows the conversation at that line" shows "tune the parser"
keys C-g
sleep 1
check "  … Ctrl-G goes back to the titles" shows "Sessions (Ctrl-G"
keys C-c
sleep 0.5
keys ':tabonly' Enter

# ---- a review's recording ---------------------------------------------------------------
keys ':tabonly' Enter
keys ':ControlBoard' Enter
keys zR
on 'M3 Third'
keys p
sleep 1
check "p on a review: asciinema play of its recording, in a tab" grep -qx "play $proj/.agent/review/M3/demo.cast" "$tmp/asciinema-calls"
check "  … which shows what it plays" shows "PLAYING $proj/.agent/review/M3/demo.cast"
check "  … a winbar says how to stop it" shows "▶ demo.cast"
sleep 2
check "  … when it ends its last frame stays" shows "THE LAST FRAME"
check "  … in Normal mode, where q closes it" [ "$(probe 'vim.fn.mode()')" = n ]
check "  … in a tab of its own" [ "$(probe "vim.fn.tabpagenr '\$'")" = 2 ]
keys q
check "  … q closes the tab" [ "$(probe "vim.fn.tabpagenr '\$'")" = 1 ]
check "  … and the board is there" shows "Plan ──"

on 'Fix parser'
keys p
check "p on a session: it says there is nothing to play" shows "Nothing to play on this row"
sleep 4 # the notice goes away
check "  … and the notice is gone" sh -c "! tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Nothing to play'"
mv "$proj/.agent/review/M3" "$proj/.agent/review/held"
keys r
sleep 1.5
check "a review whose recording is gone loses its ▶" sh -c "! tmux -L nvim-board capture-pane -p -t 0 | grep -q '▶ proj'"
on 'M3 Third'
keys p
check "p on it: the same notice" shows "Nothing to play on this row"
mv "$proj/.agent/review/held" "$proj/.agent/review/M3"
keys r
sleep 1.5
check "the ▶ is back with the recording" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '▶ proj *M3 Third'"
printf '{"version": 2, "width": 100, "height": 28}\n' >"$proj/.agent/review/M3/second.cast"
on 'M3 Third'
keys p
sleep 1
check "p on a review with two recordings: it asks which" shows "second.cast"
keys second
keys Enter
sleep 1
check "  … and plays that one" shows "PLAYING $proj/.agent/review/M3/second.cast"
normal
keys q
rm "$proj/.agent/review/M3/second.cast"

keys ':tabonly' Enter
keys ' aw'
sleep 2
keys 'review waiting'
sleep 1.5
tm send-keys -t 0 M-p
sleep 1.5
check "Alt+p in the picker: plays the review's recording" shows "PLAYING $proj/.agent/review/M3/demo.cast"
normal
keys q
keys ' aw'
sleep 2
keys 'review waiting'
sleep 1.5
keys Escape
keys p
sleep 1.5
check "p in the picker's Normal mode: the same" [ "$(grep -c "play $proj/.agent/review/M3/demo.cast" "$tmp/asciinema-calls")" -ge 3 ]
normal
keys q
keys ':ControlBoard' Enter
keys zR
keys q

# ---- the refresh and the keys outside the board ---------------------------------------
start
keys ' ab'
check "<leader>ab: the board" shows "Needs you ("
keys ':ControlBoard' Enter
keys zR
check "  … once: :ControlBoard goes to it" [ "$(probe "vim.fn.tabpagenr '\$'")" = 2 ]
board "Fixed parser" answer
sleep 7
check "The board refreshes by itself" shows "Fixed parser"
keys ':tabnew' Enter
board "Redrawn away" answer
sleep 7
keys ':tabprevious' Enter
check "A board in another tab is redrawn while you are away" shows "Redrawn away"
keys q

board "Fixed parser" answer dup
start
keys b
keys zR
check "Two projects of one name: each has its own waiting line" shows "Other thing"
check "  … and its own count of the others" shows "+ 1 more"
on 'Third · review'
before=$(probe 'vim.api.nvim_win_get_cursor(0)[1]')
sleep 7
check "A refresh keeps the cursor on its project when two have one name" [ "$(probe 'vim.api.nvim_win_get_cursor(0)[1]')" = "$before" ]
keys q
board "Fixed parser" answer

# a collector that fails: the first page asks once, not again and again
touch "$tmp/board-fails"
: >"$tmp/board-calls"
start
sleep 3
check "board.py fails: the first page runs it once" [ "$(wc -c <"$tmp/board-calls")" -eq 1 ]
check "  … and still shows the line, without counts" shows "Control board"
rm -f "$tmp/board-fails"

start src.txt
keys ' ac'
sleep 2
check "<leader>ac: a background session in this project" [ "$(grep -c "^unset $proj --bg" "$tmp/claude-calls")" = 2 ]
check "  … attached" shows "ATTACHED feed1234"

# ---- a board taller than its window -----------------------------------------------------
# The config's scrolloff is 10, so the board used to shift under the cursor on every j, and
# redrew all of itself each time. Now the cursor moves down the window and the board turns
# a page when it leaves it.
board "Fix parser" answer
tm kill-server 2>/dev/null
tm new-session -d -x 100 -y 14 -c "$proj" "$nvim -c ControlBoard"
sleep 4
keys zR
start_line=$(probe "vim.fn.line '.'")
check "a small window: the board is taller than it" [ "$(probe "vim.api.nvim_buf_line_count(0) - vim.api.nvim_win_get_height(0)")" -ge 5 ]
# only the board's window counts (a notification float or which-key scrolls too)
probe "(function() local win = vim.api.nvim_get_current_win(); _G.scrolled = 0; vim.api.nvim_create_autocmd('WinScrolled', { callback = function() if vim.v.event[tostring(win)] then _G.scrolled = _G.scrolled + 1 end end }) end)()" >/dev/null
for _ in $(seq 17); do tm send-keys -t 0 j; sleep 0.15; done
sleep 0.5
check "j down the board: the cursor reaches the last rows" [ "$(probe "vim.fn.line '.'")" -ge 17 ]
check "  … and the board scrolled" [ "$(probe _G.scrolled)" -ge 1 ]
check "  … three times at most, not on every j" [ "$(probe _G.scrolled)" -le 3 ]
for _ in $(seq 17); do tm send-keys -t 0 k; sleep 0.15; done
sleep 0.5
check "k back up: to where the board opened (on what needs you)" [ "$(probe "vim.fn.line '.'")" = "$start_line" ]
check "  … the board scrolled six times at most in all" [ "$(probe _G.scrolled)" -le 6 ]
check "  … a page is half the window, while the board is the buffer" [ "$(probe 'vim.go.scrolljump')" = -50 ]
keys ':tabnew' Enter
check "  … scrolljump and the config's scrolloff are back in another tab" [ "$(probe 'vim.go.scrolljump') $(probe 'vim.go.scrolloff')" = '1 10' ]
keys ':tabclose' Enter
check "  … and the board has it again when you return" [ "$(probe 'vim.go.scrolljump')" = -50 ]
keys ':edit src.txt' Enter
check "A file in the board's window (the board is wiped): scrolljump and scrolloff are normal" [ "$(probe 'vim.go.scrolljump') $(probe 'vim.go.scrolloff')" = '1 10' ]
keys ':ControlBoard' Enter
keys zR
keys ':tabnew' Enter
keys ':tabprevious' Enter
keys q
check "q on the board with other tabs open: scrolljump and scrolloff are normal again" [ "$(probe 'vim.go.scrolljump') $(probe 'vim.go.scrolloff')" = '1 10' ]

# ---- prose: no typewriter mode ------------------------------------------------------------
start
keys ':edit ROADMAP.md' Enter
sleep 1
check "a Markdown file: no typewriter mode (no <leader>mt, no b:typewriter)" [ "$(probe "vim.fn.maparg(' mt', 'n') .. tostring(vim.b.typewriter)")" = nil ]
check "  … the config's scrolloff stays (a wrapped paragraph keeps its margin)" [ "$(probe 'vim.wo.scrolloff')" = 10 ]
check "  … the prose settings stay: soft wrap, spelling" [ "$(probe "tostring(vim.wo.wrap) .. tostring(vim.wo.spell)")" = truetrue ]

# ---- cb: the board alone -------------------------------------------------------------
start -c ControlBoard
check "nvim -c ControlBoard: the board, no first page" shows "Needs you (5)"
check "  … in the only tab" [ "$(probe "vim.fn.tabpagenr '\$'")" = 1 ]
keys q
sleep 1
check "  … q leaves nvim" sh -c "! tmux -L nvim-board has-session -t 0 2>/dev/null"

# ---- the fish functions ------------------------------------------------------------------
: >"$tmp/claude-calls"
(cd "$proj" && fish -c "source '$here/../home/dot_config/private_fish/functions/cl.fish'; cl" </dev/null >/dev/null)
check "cl: starts a session here, then attaches it" sh -c "[ \"\$(sed 's/^[^ ]* [^ ]* //' '$tmp/claude-calls')\" = '--bg
attach feed1234' ]"
check "cb: nvim with the board" grep -q 'nvim -c ControlBoard' "$here/../home/dot_config/private_fish/functions/cb.fish"

echo
[ "$fails" = 0 ] && echo "all passed" || echo "$fails failed"
exit "$fails"
