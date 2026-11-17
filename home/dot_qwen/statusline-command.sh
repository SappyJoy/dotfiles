#!/bin/bash
# Qwen Code 0.x status line: the built-in simple look in ayu-light colors, plus cache-hit %.
# dir (branch) [model · effort] ▓▓░░░░░░░░ % · cache %
# Branch comes from the payload; effort from settings.json (/effort writes it there);
# cache from the payload's per-model token metrics (cached / prompt).

input=$(cat)

dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(printf '%s' "$input" | jq -r '.model.display_name // ""')
ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
branch=$(printf '%s' "$input" | jq -r '.git.branch // empty')

rgb() { printf '\033[38;2;%d;%d;%dm%s\033[0m' "$1" "$2" "$3" "$4"; }
blue()   { rgb 57 158 230 "$1"; }   # ayu #399EE6
green()  { rgb 134 179 0 "$1"; }    # ayu #86B300
purple() { rgb 163 122 204 "$1"; }  # ayu #A37ACC
yellow() { rgb 242 174 73 "$1"; }   # ayu #F2AE49
red()    { rgb 240 113 113 "$1"; }  # ayu #F07171
gray()   { rgb 138 145 153 "$1"; }  # ayu #8A9199
dim()    { rgb 171 176 182 "$1"; }  # ayu #ABB0B6

display_dir=$dir
case "$display_dir" in
  "$HOME"*) display_dir="~${display_dir#"$HOME"}" ;;
esac

effort=$(jq -r '.model.reasoningEffort // empty' "$HOME/.qwen/settings.json" 2>/dev/null)
cache=$(printf '%s' "$input" | jq -r '
  [.metrics.models // {} | .[] | .tokens // {}]
  | (map(.prompt // 0) | add // 0) as $p
  | (map(.cached // 0) | add // 0) as $c
  | if $p > 0 then ($c / $p * 100 | round) else empty end' 2>/dev/null)

out=$(blue "$display_dir")
[ -n "$branch" ] && out="$out $(green "($branch)")"
[ -n "$effort" ] && model="$model · $effort"
out="$out $(purple "[$model]")"

if [ -n "$ctx" ]; then
  pct=${ctx%.*}
  filled=$(( (pct + 5) / 10 ))
  [ "$filled" -gt 10 ] && filled=10
  bar="" empty="" i=0
  while [ "$i" -lt 10 ]; do
    if [ "$i" -lt "$filled" ]; then bar="$bar▓"; else empty="$empty░"; fi
    i=$((i + 1))
  done
  color=green
  [ "$pct" -ge 75 ] && color=yellow
  [ "$pct" -ge 90 ] && color=red
  out="$out $($color "$bar")$(dim "$empty") $($color "${pct}%")"
fi
[ -n "$cache" ] && out="$out $(gray "· cache ${cache}%")"

printf '%s' "$out"