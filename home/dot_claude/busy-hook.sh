#!/bin/sh
# Claude Code hook: `busy-hook.sh on|off` marks this session busy or idle for polybar's
# claude module, which spins Claude's glyph while any session is busy. settings.json
# (modify_settings.json, desktops only) runs `on` when a prompt is sent and after each
# tool (so again after a permission prompt), and `off` when Claude stops or fails,
# waits for the user, or the session ends. Esc runs no hook: the idle notification
# (after about a minute) turns the glyph off then. The marker holds the claude
# process's PID, so the bar ignores a session that died without `off`.
dir=${XDG_RUNTIME_DIR:-/tmp}/claude-busy

# Silent, and always exit 0: a command hook costs no tokens, but UserPromptSubmit adds
# its stdout to the prompt, and an exit 2 after a tool shows Claude its stderr
exec >/dev/null 2>&1

# Subagents run inside their parent's turn, which counts already; skipping theirs
# keeps a background agent from marking a finished turn busy again
id=$(jq -r 'select(.agent_id == null) | .session_id // empty')
[ -n "$id" ] || exit 0
marker=$dir/$id

if [ "$1" != on ]; then
    rm -f "$marker"
    exit 0
fi

# The claude process: this hook's parent, or the parent of the `sh -c` that ran it
pid=$PPID
for _ in 1 2; do
    read -r comm <"/proc/$pid/comm" || exit 0
    [ "$comm" = claude ] && break
    read -r stat <"/proc/$pid/stat"
    stat=${stat##*) } # after "PID (COMM) "
    stat=${stat#* }   # after the state letter
    pid=${stat%% *}
done
[ "$comm" = claude ] || exit 0
mkdir -p "$dir" && echo "$pid" >"$marker"
exit 0
