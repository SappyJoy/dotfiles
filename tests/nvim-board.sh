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
cat >"$tmp/bin/claude" <<EOS
#!/bin/sh
echo "\${CLAUDE_CONFIG_DIR:-unset} \$PWD \$*" >>"$tmp/claude-calls"
case \$1 in
    --bg) echo "backgrounded · feed1234" ;;
    attach) echo \$\$ >"$tmp/attach.pid.\$2"; echo "ATTACHED \$2"; exec cat ;;
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
    "needs": needs, "sessions": sessions,
    "projects": projects,
    "counts": {"answer": 1 if state == "answer" else 0, "review": 1, "track": 1, "waiting": 2,
        "working": 1, "sessions": 4}}, sys.stdout)
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
    keys ":call cursor(1, 1) | call search('\\V$1')" Enter
}
normal() { tm send-keys -t 0 'C-\' C-n; sleep 0.4; } # out of a session tab's Terminal mode

# ---- the first page -------------------------------------------------------------
start
check "first page: the line with the counts" shows "Control board   ❓1  🚦1  ☐2  ⏳1 working"
check "  … and its key b" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep 'Control board' | grep -q ' b\$'"
check "  … the art, the name and the quote stay" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '████████╗██╗   ██╗██████╗' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Чехов' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Find file'"

# ---- the board ------------------------------------------------------------------
keys b
check "b: the board" shows "Plan ──"
check "  … a bar with the percent and its reset" shows "34%  resets in 3h"
check "  … a window with no data" shows "no data yet"
check "  … Needs you, Sessions, Projects" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Needs you (5)' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Sessions (4)' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Projects ──'"
check "  … a session that asks, a review, a waiting line" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Which parser' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'M3 Third' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Log in to npm'"
check "  … a project with its milestone and progress" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'M3 🚦 Third · review.*2 of 4 done'"
check "  … the board's keys, and what p plays" shows "⏎ open  t tick  c comment  p play ▶"
check "  … the review has a recording: a ▶ after its icon" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '▶ proj *M3 Third'"
check "  … and no other row has one (the key hint does)" sh -c "[ \$(tmux -L nvim-board capture-pane -p -t 0 | grep -c '▶') = 2 ]"
check "  … a finished track under Needs you" shows "track scorer"
check "  … the Week: tokens per project with their share" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Week ──' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'proj *2.4M.* 80%'"
check "  … a spark for each day, and the costliest prompt" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '▁▁▁▃▁▆█' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Costliest prompt: 900k in proj, \"fix the parser\"'"
check "  … the 5-hour windows as bars, milestones finished, code growth" sh -c "tmux -L nvim-board capture-pane -p -t 0 | grep -q '5h personal' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'Milestones finished: proj 3' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'proj *13k *+3.4k −200' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'lib/parser +900 · new: lib/report' && tmux -L nvim-board capture-pane -p -t 0 | grep -q 'src.txt *412 lines'"
on 'src.txt'
keys Enter
check "Enter on a flagged file: the file" [ "$(probe "vim.fn.expand('%:t')")" = "src.txt" ]
keys ':bd' Enter
keys b
on 'track scorer'
keys Enter
check "Enter on a track: its TRACK.md" shows "The scorer findings"
keys ':bd' Enter
keys b
keys q
check "q: back to the first page" shows "Find file"

# ---- session tabs -----------------------------------------------------------------
keys b
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
check "  … its winbar names Alt+A" shows "Alt+A as Space a"
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

# ---- the keys of the board ----------------------------------------------------------
keys ':ControlBoard' Enter
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
on 'M3 Third'
keys c
keys 'Third time'
keys Escape
keys ':w' Enter
check "c after the review moved down: the same Your reply section" sh -c "[ \"\$(grep -c '^## Your reply' '$proj/REVIEW.md')\" = 1 ] && grep -q 'Third time' '$proj/REVIEW.md' && [ \"\$(head -1 '$proj/REVIEW.md')\" = Preface ]"
keys ':tabclose' Enter

on 'M3 Third'
keys s
sleep 2
check "s: claude --bg in the project" grep -q "^$HOME/.claude-personal $proj --bg" "$tmp/claude-calls"
check "  … and its tab" shows "ATTACHED feed1234"
check "  … the winbar before the board knows it" shows "proj · feed1234 · attached"
normal
keys q

# ---- sessions started by hand -------------------------------------------------------
keys ':ControlBoard' Enter
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

# ---- a review's recording ---------------------------------------------------------------
keys ':tabonly' Enter
keys ':ControlBoard' Enter
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
keys q

# ---- the refresh and the keys outside the board ---------------------------------------
start
keys ' ab'
check "<leader>ab: the board" shows "Plan ──"
keys ':ControlBoard' Enter
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
check "<leader>ac: a background session in this project" [ "$(grep -c "^$HOME/.claude-personal $proj --bg" "$tmp/claude-calls")" = 2 ]
check "  … attached" shows "ATTACHED feed1234"

# ---- a board taller than its window -----------------------------------------------------
# The config's scrolloff is 10, so the board used to shift under the cursor on every j, and
# redrew all of itself each time. Now the cursor moves down the window and the board turns
# a page when it leaves it.
board "Fix parser" answer
tm kill-server 2>/dev/null
tm new-session -d -x 100 -y 14 -c "$proj" "$nvim -c ControlBoard"
sleep 4
check "a small window: the board is taller than it" [ "$(probe "vim.api.nvim_buf_line_count(0) - vim.api.nvim_win_get_height(0)")" -ge 5 ]
# only the board's window counts (a notification float or which-key scrolls too)
probe "(function() local win = vim.api.nvim_get_current_win(); _G.scrolled = 0; vim.api.nvim_create_autocmd('WinScrolled', { callback = function() if vim.v.event[tostring(win)] then _G.scrolled = _G.scrolled + 1 end end }) end)()" >/dev/null
for _ in $(seq 17); do tm send-keys -t 0 j; sleep 0.15; done
sleep 0.5
check "j down the board: the cursor reaches the last rows" [ "$(probe "vim.fn.line '.'")" -ge 17 ]
check "  … and the board scrolled" [ "$(probe _G.scrolled)" -ge 1 ]
check "  … twice at most, not on every j" [ "$(probe _G.scrolled)" -le 2 ]
for _ in $(seq 17); do tm send-keys -t 0 k; sleep 0.15; done
sleep 0.5
check "k back up: to the first line" [ "$(probe "vim.fn.line '.'")" = 1 ]
check "  … the board scrolled four times at most in all" [ "$(probe _G.scrolled)" -le 4 ]
check "  … a page is half the window, while the board is the buffer" [ "$(probe 'vim.go.scrolljump')" = -50 ]
keys ':tabnew' Enter
check "  … scrolljump and the config's scrolloff are back in another tab" [ "$(probe 'vim.go.scrolljump') $(probe 'vim.go.scrolloff')" = '1 10' ]
keys ':tabclose' Enter
check "  … and the board has it again when you return" [ "$(probe 'vim.go.scrolljump')" = -50 ]
keys ':edit src.txt' Enter
check "A file in the board's window (the board is wiped): scrolljump and scrolloff are normal" [ "$(probe 'vim.go.scrolljump') $(probe 'vim.go.scrolloff')" = '1 10' ]
keys ':ControlBoard' Enter
keys ':tabnew' Enter
keys ':tabprevious' Enter
keys q
check "q on the board with other tabs open: scrolljump and scrolloff are normal again" [ "$(probe 'vim.go.scrolljump') $(probe 'vim.go.scrolloff')" = '1 10' ]

# ---- cb: the board alone -------------------------------------------------------------
start -c ControlBoard
check "nvim -c ControlBoard: the board, no first page" shows "Plan ──"
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
