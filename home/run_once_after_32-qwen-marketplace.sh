#!/bin/sh
# Register the qwen toolkit clone as the `personal` marketplace source and install
# milestone-flow, once per machine (after the external above has cloned it). Where
# you work on the toolkit, `make install` registers your working repo instead; an
# existing registration is left alone.
command -v qwen >/dev/null 2>&1 || exit 0
if qwen extensions sources list 2>/dev/null | grep -q '^personal'; then
  exit 0
fi
clone="$HOME/.local/share/qwen-extensions/personal"
[ -f "$clone/.claude-plugin/marketplace.json" ] || exit 0
qwen extensions sources add "$clone" || exit 0
qwen extensions install "$clone:milestone-flow" --consent