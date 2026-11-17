#!/bin/sh
# Refresh the installed milestone-flow extension from the registered `personal`
# marketplace source (the qwen toolkit clone, or your working repo where you develop
# it). Idempotent; runs after every apply so a merged milestone reaches sessions.
# 0.x's `extensions update` does not refresh a Claude-origin local extension, so the
# refresh is an uninstall/install cycle.
command -v qwen >/dev/null 2>&1 || exit 0
qwen extensions sources update personal >/dev/null 2>&1 || :
src=$(jq -r '.[] | select(.name=="personal") | .source' "$HOME/.qwen/extensions/marketplaces.json" 2>/dev/null)
[ -n "$src" ] && [ -f "$src/.claude-plugin/marketplace.json" ] || exit 0
if qwen extensions list 2>/dev/null | grep -q milestone-flow; then
  qwen extensions uninstall milestone-flow >/dev/null 2>&1 || :
  qwen extensions install "$src:milestone-flow" --consent >/dev/null 2>&1 || :
fi