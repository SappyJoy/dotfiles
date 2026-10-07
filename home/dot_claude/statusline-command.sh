#!/bin/bash
# Claude Code status line
# Shows: current directory | git branch (if inside a repo) | active model · effort
#        | context window % · 5-hour and 7-day rate limit %
# Colors are dimmed to match the status line's rendering style.
# Also saves the 5-hour window for polybar's claude module (see the end).

input=$(cat)

dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir')
model=$(printf '%s' "$input" | jq -r '.model.display_name')
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
rl_5h=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_7d=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
# "PERCENT RESETS_AT" (rounded, epoch seconds), for the desktop bar
rl_5h_window=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour
  | select(.used_percentage != null and .resets_at != null)
  | "\(.used_percentage | round) \(.resets_at | floor)"')

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

# Share the 5-hour window with polybar's claude module: one file per account (config
# dir), e.g. ~/.cache/claude-usage/claude-personal. An idle session runs this again
# with its last numbers (e.g. when its prompt cache expires), so a newer window
# replaces the file, and within a window (a minute of slack in resets_at) only a
# higher percentage does.
if [ -n "$rl_5h_window" ]; then
  account=$(basename "${CLAUDE_CONFIG_DIR:-$HOME/.claude}")
  usage_file=${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage/${account#.}
  read -r pct reset <<<"$rl_5h_window"
  old_pct=-1 old_reset=0
  [ -r "$usage_file" ] && read -r old_pct old_reset <"$usage_file"
  if [ "$reset" -gt $((old_reset + 60)) ] ||
    { [ "$reset" -ge $((old_reset - 60)) ] && [ "$pct" -gt "$old_pct" ]; }; then
    mkdir -p "${usage_file%/*}"
    printf '%s %s\n' "$pct" "$reset" >"$usage_file.$$" && mv "$usage_file.$$" "$usage_file"
  fi
fi

printf '%s' "$out"
