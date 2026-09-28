#!/bin/bash
# Claude Code status line
# Shows: current directory | git branch (if inside a repo) | active model · effort
#        | context window % · 5-hour and 7-day rate limit %
# Colors are dimmed to match the status line's rendering style.

input=$(cat)

dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir')
model=$(printf '%s' "$input" | jq -r '.model.display_name')
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
rl_5h=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_7d=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

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

printf '%s' "$out"
