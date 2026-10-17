#!/bin/sh
# Tells the user that a Claude session waits for them: a desktop notification (dunst)
# and a tmux message on every attached client, which is what an ssh login sees.
# busy-hook.sh runs this for every `off` event with the hook's JSON on stdin; only a
# Notification (the session asks for a permission or an answer, or has been idle for
# a minute) carries a notification_type, and the rest exit at once. nvim's control
# board tells in its own way (lua/control_board/notify.lua), the phone gets Claude
# Code's own push.
#
# The text is the project's name and the notification's message. An idle session in a
# project with a review waiting for the user says so instead, and the desktop shows
# it as critical; so does an idle side track that has written its TRACK.md. The urgency of the others follows notification_type: idle is low,
# a permission or a question is normal.
#
# Runs in every live session, both accounts: silent on stdout and stderr, always exit 0.
# Every command that talks to a daemon is on a timer, so a missing display or a stuck
# tmux server can't hold a session up.
exec >/dev/null 2>&1

# The JSON's fields, quoted for the shell by jq itself
eval "$(jq -r '@sh "type=\(.notification_type // "") cwd=\(.cwd // "") sid=\(.session_id // "") message=\(.message // "")"')" || exit 0
[ -n "$type" ] || exit 0
[ -n "$cwd" ] || cwd=$PWD

# The project: the milestone-flow project the folder is in, else its git root, else
# the folder (the same rule as the control board's collector, board.py)
root=
d=$cwd
while [ -n "$d" ]; do
    if [ -f "$d/ROADMAP.md" ] && [ -d "$d/.agent/milestones" ]; then
        root=$d
        break
    fi
    d=${d%/*}
done
[ -n "$root" ] || root=$(git -C "$cwd" rev-parse --show-toplevel) || root=$cwd
project=${root##*/}

# A side track (`.claude/worktrees/track-<slug>` of the project, M25) is a checkout of
# its own: the project is the one above it, and the track is named by its slug
track=
case $cwd in
    */.claude/worktrees/track-*)
        project=${cwd%%/.claude/worktrees/track-*}
        track=${cwd#*/.claude/worktrees/track-}
        track=${track%%/*}
        tdir=$project/.claude/worktrees/track-$track
        project=${project##*/}
        ;;
esac

# The first review in REVIEW.md that the user hasn't put off: "M3 Title". A review is
# put off by a line starting with "Put off" within three lines of its heading.
review=$(awk '
    function flush() { if (title != "" && !off && found == "") found = title }
    /^# Review: / { flush(); title = $0; sub(/^# Review: /, "", title); gsub(/ 🚦/, "", title); off = 0; near = 3; next }
    near > 0 { near--; if ($0 ~ /^Put off/) off = 1 }
    END { flush(); print found }
' "$root/REVIEW.md")
[ -z "$track" ] || review=

urgency=normal
body=${message:-needs you}
case $type in
    idle_prompt)
        urgency=low
        body=${message:-is idle}
        if [ -n "$review" ]; then
            urgency=critical
            body="review waiting: $review"
        fi
        if [ -n "$track" ]; then
            urgency=low
            body="track $track is still working"
            if [ -f "$tdir/TRACK.md" ]; then
                urgency=critical
                body="track $track is done: read TRACK.md"
            fi
        fi
        ;;
esac

if command -v notify-send >/dev/null && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    # dunst reads markup; one stack tag per session lets a new notice replace the old
    markup() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
    timeout 3 notify-send -a 'Claude Code' -u "$urgency" -h "string:x-dunst-stack-tag:claude-$sid" \
        -- "$(markup "$project")" "$(markup "$body")"
fi

if command -v tmux >/dev/null; then
    # tmux expands #(command) and #{format} in a message: double every # to show it as it is
    text=$(printf '%s: %s' "$project" "$body" | tr '\n' ' ' | sed 's/#/##/g')
    for client in $(timeout 3 tmux list-clients -F '#{client_name}'); do
        timeout 3 tmux display-message -c "$client" -d 6000 -- "$text"
    done
fi
exit 0
