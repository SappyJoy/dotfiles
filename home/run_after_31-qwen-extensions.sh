#!/bin/sh
# Refresh the installed milestone-flow extension from the personal marketplace source
# (the qwen toolkit repo). Idempotent; runs after every apply so a merged milestone
# reaches sessions. The source and the install are set up once by the toolkit's
# `make install`. 0.x's `extensions update` does not refresh a Claude-origin local
# extension, so the refresh is an uninstall/install cycle.
command -v qwen >/dev/null 2>&1 || exit 0
qwen extensions sources update personal >/dev/null 2>&1 || :
if qwen extensions list 2>/dev/null | grep -q milestone-flow; then
  qwen extensions uninstall milestone-flow >/dev/null 2>&1 || :
  qwen extensions install "$HOME/src/personal/harness/qwen/toolkit:milestone-flow" --consent >/dev/null 2>&1 || :
fi