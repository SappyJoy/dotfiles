#!/bin/sh
# Refresh the installed milestone-flow extension from the personal marketplace source
# (the qwen toolkit repo). Idempotent; runs after every apply so a merged milestone
# reaches sessions. The source and the install are set up once by the toolkit's
# `make install`.
command -v qwen >/dev/null 2>&1 || exit 0
qwen extensions sources update personal >/dev/null 2>&1 || :
qwen extensions update milestone-flow >/dev/null 2>&1 || :