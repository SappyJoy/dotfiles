#!/bin/bash
# Qwen Code status line: the built-in simple look in ayu-light colors, plus cache-hit %.
# dir (branch) [model · effort] ▓▓░░░░░░░░ % · cache %
# Effort and cache come from the transcript (runtime-config and the last usage record).

input=$(cat)

dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir')
model=$(printf '%s' "$input" | jq -r '.model.display_name')
ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

rgb() { printf '\033[38;2;%d;%d;%dm%s\033[0m' "$1" "$2" "$3" "$4"; }
blue()   { rgb 57 158 230 "$1"; }   # ayu #399EE6
green()  { rgb 134 179 0 "$1"; }    # ayu #86B300
purple() { rgb 163 122 204 "$1"; }  # ayu #A37ACC
yellow() { rgb 242 174 73 "$1"; }   # ayu #F2AE49
red()    { rgb 240 113 113 "$1"; }  # ayu #F07171
gray()   { rgb 138 145 153 "$1"; }  # ayu #8A9199
dim()    { rgb 171 176 182 "$1"; }  # ayu #ABB0B6

branch=""
if git -C "$dir" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
fi

display_dir=$dir
case "$display_dir" in
  "$HOME"*) display_dir="~${display_dir#"$HOME"}" ;;
esac

effort="" cache=""
if [ -n "$transcript" ] && [ -r "$transcript" ]; then
  effort=$(tac "$transcript" | grep -m1 '"runtime-config"' | jq -r '.reasoningEffort // empty' 2>/dev/null)
  cache=$(tac "$transcript" | grep -m1 '"cache_read_input_tokens"' |
    jq -r '[.. | objects | select(has("cache_read_input_tokens"))][0]
      | select(.input_tokens > 0)
      | (.cache_read_input_tokens / .input_tokens * 100 | round)' 2>/dev/null)
fi

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
