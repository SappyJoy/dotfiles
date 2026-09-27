#!/bin/sh
# tide's prompt style lives in fish universal variables, which aren't tracked, so
# set it here: Lean, two lines, true color, 24-hour time, transient.
# chezmoi runs this again whenever the flags below change.
set -eu
PATH=$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH
if ! command -v fish >/dev/null 2>&1; then
    echo "tide: no fish yet, skipped" >&2
    exit 0
fi
fish -c 'functions -q tide; or exit 0
tide configure --auto --style=Lean --prompt_colors="True color" \
    --show_time="24-hour format" --lean_prompt_height="Two lines" \
    --prompt_connection=Disconnected --prompt_spacing=Compact \
    --icons="Few icons" --transient=Yes' >/dev/null
