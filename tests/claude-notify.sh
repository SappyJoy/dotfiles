#!/bin/sh
# Tests for the notices a waiting Claude session sends (home/dot_claude/notify-hook.sh,
# run by busy-hook.sh on every `off` event): a desktop notification and a tmux message.
# `notify-send` is a stand-in that records its arguments, so nothing reaches the desktop;
# the tmux server is a private one (its own TMUX_TMPDIR) with one attached client, which
# runs inside a second private server so its screen can be read.
# Run: sh tests/claude-notify.sh (offline; needs jq, awk and tmux, takes ~15 s)

set -u
here=$(cd "$(dirname "$0")" && pwd)
notify=$here/../home/dot_claude/notify-hook.sh
busy=$here/../home/dot_claude/busy-hook.sh
tmp=$(mktemp -d)
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}

# a session of Claude would leak its own tmux, display and bus into the hook
unset TMUX TMUX_PANE
export TMUX_TMPDIR=$tmp/tmux XDG_RUNTIME_DIR=$tmp/run DISPLAY=:99
export DBUS_SESSION_BUS_ADDRESS=unix:path=$tmp/no-bus
unset WAYLAND_DISPLAY
mkdir -p "$TMUX_TMPDIR" "$XDG_RUNTIME_DIR" "$tmp/bin"
# after the private TMUX_TMPDIR is set: this must never reach the user's own tmux
trap 'tmux kill-server 2>/dev/null; tmux -L outer kill-server 2>/dev/null; rm -rf "$tmp"' EXIT

# notify-send: one line per call, the arguments between brackets
cat >"$tmp/bin/notify-send" <<EOF
#!/bin/sh
printf '[%s]' "\$@" >>"$tmp/sent"
echo >>"$tmp/sent"
[ -z "\${FAKE_NOTIFY_SLOW:-}" ] || sleep 30
[ -z "\${FAKE_NOTIFY_FAILS:-}" ] || exit 1
EOF
chmod +x "$tmp/bin/notify-send"
export PATH="$tmp/bin:$PATH"

# a milestone-flow project, a git repo without milestones, and a bare folder
proj=$tmp/proj
mkdir -p "$proj/.agent/milestones" "$proj/src"
echo '# proj' >"$proj/ROADMAP.md"
repo=$tmp/plain-repo
mkdir -p "$repo/lib" && git -C "$repo" init -q
mkdir -p "$tmp/bare folder"

# the private tmux: a server with a session, and a client of it shown in another server
tmux -f /dev/null new-session -d -s in -x 110 -y 12
tmux -L outer -f /dev/null new-session -d -x 110 -y 12 "env -u TMUX tmux -f /dev/null attach -t in"
sleep 0.5
screen() { tmux -L outer capture-pane -p; }
screen_has() { # screen_has TEXT: within 3 s
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
        screen | grep -qF -- "$1" && return 0
        sleep 0.25
    done
    return 1
}

# note TYPE CWD [MESSAGE]: the hook gets a Notification
note() {
    jq -nc --arg t "$1" --arg c "$2" --arg m "${3:-}" \
        '{session_id: "s1", cwd: $c, hook_event_name: "Notification", notification_type: $t, message: $m}' |
        sh "$notify"
}
sent() { cat "$tmp/sent" 2>/dev/null; }
reset() { rm -f "$tmp/sent"; tmux clear-history 2>/dev/null; }

note permission_prompt "$proj" "Claude needs your permission to use Bash"
check "a permission prompt: normal urgency, the project's name, Claude's message" \
    [ "$(sent)" = "[-a][Claude Code][-u][normal][-h][string:x-dunst-stack-tag:claude-s1][--][proj][Claude needs your permission to use Bash]" ]
check "a permission prompt: a tmux message on the client" screen_has "proj: Claude needs your permission to use Bash"

reset
note idle_prompt "$proj/src" "Claude is waiting for your input"
check "an idle session: low urgency; a subfolder counts as its project" \
    [ "$(sent)" = "[-a][Claude Code][-u][low][-h][string:x-dunst-stack-tag:claude-s1][--][proj][Claude is waiting for your input]" ]

reset
printf '# Review: M3 🚦 First look\n\n## Try it\n' >"$proj/REVIEW.md"
note idle_prompt "$proj" "Claude is waiting for your input"
check "an idle session with a review waiting: critical, says so" \
    [ "$(sent)" = "[-a][Claude Code][-u][critical][-h][string:x-dunst-stack-tag:claude-s1][--][proj][review waiting: M3 First look]" ]
check "a review waiting: the tmux message says so" screen_has "proj: review waiting: M3 First look"

reset
note permission_prompt "$proj" "Claude needs your permission to use Bash"
check "a permission prompt with a review waiting: still a permission prompt" \
    [ "$(sent)" = "[-a][Claude Code][-u][normal][-h][string:x-dunst-stack-tag:claude-s1][--][proj][Claude needs your permission to use Bash]" ]

reset
printf '# Review: M5 Later one\n\nPut off 2026-10-15: Claude went on.\n\n# Review: M3 🚦 First look\n\n## Try it\n' >"$proj/REVIEW.md"
note idle_prompt "$proj" "Claude is waiting for your input"
check "a put-off review is skipped, the next open one counts" \
    [ "$(sent)" = "[-a][Claude Code][-u][critical][-h][string:x-dunst-stack-tag:claude-s1][--][proj][review waiting: M3 First look]" ]

reset
printf '# Review: M5 Later one\n\nPut off 2026-10-15: Claude went on.\n' >"$proj/REVIEW.md"
note idle_prompt "$proj" "Claude is waiting for your input"
check "only put-off reviews: not urgent" \
    [ "$(sent)" = "[-a][Claude Code][-u][low][-h][string:x-dunst-stack-tag:claude-s1][--][proj][Claude is waiting for your input]" ]
rm -f "$proj/REVIEW.md"

reset
note elicitation_dialog "$repo/lib" "Claude Code needs your input"
check "a folder in a git repo: the repo's name, normal urgency" \
    [ "$(sent)" = "[-a][Claude Code][-u][normal][-h][string:x-dunst-stack-tag:claude-s1][--][plain-repo][Claude Code needs your input]" ]
reset
note agent_needs_input "$tmp/bare folder" ""
check "no project, no message: the folder's name and a plain text" \
    [ "$(sent)" = "[-a][Claude Code][-u][normal][-h][string:x-dunst-stack-tag:claude-s1][--][bare folder][needs you]" ]

reset
note permission_prompt "$proj" 'Run <b>rm</b> & #(touch '"$tmp"'/ran) #{session_name}'
check "markup in the text is escaped for dunst" \
    [ "$(sent)" = "[-a][Claude Code][-u][normal][-h][string:x-dunst-stack-tag:claude-s1][--][proj][Run &lt;b&gt;rm&lt;/b&gt; &amp; #(touch $tmp/ran) #{session_name}]" ]
check "a #(format) in the text is shown as it is, not expanded by tmux" screen_has "#{session_name}"

reset
(unset DISPLAY DBUS_SESSION_BUS_ADDRESS; note permission_prompt "$proj" "A question over ssh")
check "no display and no bus (ssh): no desktop notification" [ -z "$(sent)" ]
check "no display and no bus (ssh): the tmux message still comes" screen_has "proj: A question over ssh"

reset
jq -nc --arg c "$proj" '{session_id: "s1", cwd: $c, hook_event_name: "Stop"}' | sh "$notify"
check "an event that is no notification: nothing sent" [ -z "$(sent)" ]

# silent, and exit 0 whatever fails
out=$(FAKE_NOTIFY_FAILS=1 note permission_prompt "$proj" "x" 2>&1; echo "exit $?")
check "silent and exit 0 when notify-send fails" [ "$out" = "exit 0" ]
out=$(printf 'not json' | sh "$notify" 2>&1; echo "exit $?")
check "silent and exit 0 on bad input" [ "$out" = "exit 0" ]
out=$(TMUX_TMPDIR=$tmp/none note permission_prompt "$proj" "x" 2>&1; echo "exit $?")
check "silent and exit 0 with no tmux server" [ "$out" = "exit 0" ]
start=$(date +%s)
FAKE_NOTIFY_SLOW=1 note permission_prompt "$proj" "x"
check "a notify-send that hangs is cut off after 3 s" [ $(($(date +%s) - start)) -lt 6 ]

# through busy-hook.sh, as settings.json runs it
reset
mkdir -p "$XDG_RUNTIME_DIR/claude-busy" && echo 1 >"$XDG_RUNTIME_DIR/claude-busy/s1"
jq -nc --arg c "$proj" '{session_id: "s1", cwd: $c, hook_event_name: "Notification", notification_type: "permission_prompt", message: "via busy"}' |
    sh "$busy" off
check "busy-hook.sh off on a notification: the marker goes" [ ! -e "$XDG_RUNTIME_DIR/claude-busy/s1" ]
check "busy-hook.sh off on a notification: and the notice is sent" \
    [ "$(sent)" = "[-a][Claude Code][-u][normal][-h][string:x-dunst-stack-tag:claude-s1][--][proj][via busy]" ]
reset
echo 1 >"$XDG_RUNTIME_DIR/claude-busy/s1"
jq -nc --arg c "$proj" '{session_id: "s1", cwd: $c, hook_event_name: "Stop"}' | sh "$busy" off
check "busy-hook.sh off on a stop: the marker goes, no notice" \
    sh -c '[ ! -e "$1/claude-busy/s1" ] && [ -z "$(cat "$2" 2>/dev/null)" ]' - "$XDG_RUNTIME_DIR" "$tmp/sent"
out=$(jq -nc --arg c "$proj" '{session_id: "s1", cwd: $c, hook_event_name: "Notification", notification_type: "idle_prompt"}' |
    sh "$busy" off 2>&1; echo "exit $?")
check "busy-hook.sh stays silent and exits 0 on a notification" [ "$out" = "exit 0" ]

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
