#!/bin/bash
# Claude Code status line
# Shows: current directory | git branch (if inside a repo) | active model · effort
#        | context window % · 5-hour and 7-day rate limit %
# Colors are dimmed to match the status line's rendering style.
# Also saves the 5-hour and 7-day windows for polybar's claude module and nvim's
# control board (see the end).

input=$(cat)

dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir')
model=$(printf '%s' "$input" | jq -r '.model.display_name')
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
rl_5h=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_7d=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
# "PERCENT RESETS_AT" (rounded, epoch seconds), for the desktop bar and the board
window() { # window five_hour|seven_day
  printf '%s' "$input" | jq -r --arg w "$1" '.rate_limits[$w]
    | select(. != null and .used_percentage != null and .resets_at != null)
    | "\(.used_percentage | round) \(.resets_at | floor)"'
}
rl_5h_window=$(window five_hour)
rl_7d_window=$(window seven_day)

# Git branch, if cwd is inside a work tree (skip optional locks for safety/perf)
branch=""
if git -C "$dir" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
fi

# Shorten $HOME to ~ for display only (git needs the real path)
display_dir=$dir
case "$display_dir" in
  "$HOME"*) display_dir="~${display_dir#"$HOME"}" ;;
esac

out=$(printf '\033[2;34m%s\033[0m' "$display_dir")
if [ -n "$branch" ]; then
  out="$out $(printf '\033[2;32m(%s)\033[0m' "$branch")"
fi
if [ -n "$effort" ]; then
  model="$model · $effort"
fi
out="$out $(printf '\033[2;90m[%s]\033[0m' "$model")"

# Usage: context window fill and plan rate limits, each only if reported
usage=""
[ -n "$ctx" ] && usage="ctx ${ctx}%"
[ -n "$rl_5h" ] && usage="${usage:+$usage · }5h ${rl_5h}%"
[ -n "$rl_7d" ] && usage="${usage:+$usage · }7d ${rl_7d}%"
if [ -n "$usage" ]; then
  out="$out $(printf '\033[2;33m%s\033[0m' "$usage")"
fi

# Share the 5-hour and 7-day windows with polybar's claude module and nvim's control
# board: one file per account (config dir), e.g. ~/.cache/claude-usage/claude-personal,
# with the 5-hour window on line 1 and the 7-day one on line 2 (polybar reads line 1).
# An idle session runs this again with its last numbers (e.g. when its prompt cache
# expires), so a newer window replaces the one in the file, and within a window (a
# minute of slack in resets_at) only a higher percentage does.
keep_newer() { # keep_newer NEW OLD: the "PERCENT RESETS_AT" to keep
  local pct reset old_pct=-1 old_reset=0
  [ -n "$1" ] || { printf '%s' "$2"; return; }
  read -r pct reset <<<"$1"
  [ -n "$2" ] && read -r old_pct old_reset <<<"$2"
  if [ "$reset" -gt $((old_reset + 60)) ] ||
    { [ "$reset" -ge $((old_reset - 60)) ] && [ "$pct" -gt "$old_pct" ]; }; then
    printf '%s' "$1"
  else
    printf '%s' "$2"
  fi
}
if [ -n "$rl_5h_window" ] || [ -n "$rl_7d_window" ]; then
  account=$(basename "${CLAUDE_CONFIG_DIR:-$HOME/.claude}")
  usage_file=${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage/${account#.}
  old=()
  [ -r "$usage_file" ] && mapfile -t old <"$usage_file"
  new_5h=$(keep_newer "$rl_5h_window" "${old[0]:-}")
  new_7d=$(keep_newer "$rl_7d_window" "${old[1]:-}")
  # polybar needs line 1, so a 7-day window alone waits for a 5-hour one
  if [ -n "$new_5h" ] && { [ "$new_5h" != "${old[0]:-}" ] || [ "$new_7d" != "${old[1]:-}" ]; }; then
    mkdir -p "${usage_file%/*}"
    { printf '%s\n' "$new_5h"; [ -z "$new_7d" ] || printf '%s\n' "$new_7d"; } >"$usage_file.$$" &&
      mv "$usage_file.$$" "$usage_file"
  fi
fi

printf '%s' "$out"
