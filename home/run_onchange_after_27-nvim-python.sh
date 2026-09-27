#!/bin/sh
# nvim's Python host (python3_host_prog in lua/sap/globals.lua): a venv built with
# uv, the same on every machine. pynvim, plus what molten.nvim uses for Jupyter
# output and images. chezmoi runs this again whenever the list below changes.
# Rebuilt when its Python is gone (e.g. after `uv python uninstall`); to force it:
#   sh ~/.local/share/chezmoi/home/run_onchange_after_27-nvim-python.sh
set -eu
PATH=$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH
if ! command -v uv >/dev/null 2>&1; then
    echo "nvim python: no uv yet, skipped" >&2
    exit 0
fi
venv=${XDG_DATA_HOME:-$HOME/.local/share}/nvim/venv
"$venv/bin/python" -c '' 2>/dev/null || uv venv --quiet --clear --python 3.12 "$venv"
uv pip install --quiet --python "$venv/bin/python" \
    pynvim jupyter_client nbformat \
    cairosvg pnglatex pillow pyperclip \
    'plotly<6' 'kaleido==0.2.1'
