#!/bin/sh
# Refresh the qwen-preview plugin cache from the personal marketplace (the toolkit
# repo). Idempotent; runs after every apply so a merged milestone reaches sessions.
command -v qwen-preview >/dev/null 2>&1 || exit 0
qwen-preview plugins marketplace update personal || :
qwen-preview plugins update milestone-flow || :
