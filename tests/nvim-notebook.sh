#!/bin/sh
# nvim's notebooks (lua/notebook.lua, plugins/notebook.lua) in a real UI (a scratch
# tmux with extended keys): a uv project whose .venv has ipykernel, and a notebook
# with saved outputs. Opening it shows Python cells, starts the project's kernel and
# brings the outputs back; Shift+Enter / Ctrl+Enter run cells; ]j and ij move and
# select; saving writes the new output into the .ipynb.
# Jupyter's data dir is a scratch one: the test registers its kernel there.
# Needs uv (numpy, ipykernel, nbclient; downloads them once) and jupytext.
# Run: sh tests/nvim-notebook.sh
#   NVIM=path/to/nvim (default: nvim on PATH); NVIM_APPNAME picks the config as usual

set -u
nvim=${NVIM:-nvim}
tmp=$(mktemp -d)
tm() { tmux -L nvim-notebook -f /dev/null "$@"; }
trap 'tm kill-server 2>/dev/null; rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name ($*)"; fails=$((fails + 1)); fi
}
export JUPYTER_DATA_DIR=$tmp/jupyter

cd "$tmp" && uv init -q --app proj && cd proj || exit 1
uv add -q numpy && uv add -q --dev ipykernel nbclient nbformat || exit 1
cat >make.py <<'EOF'
import nbclient, nbformat
nb = nbformat.v4.new_notebook()
nb.metadata.kernelspec = {"name": "python3", "display_name": "Python 3", "language": "python"}
nb.cells = [
    nbformat.v4.new_markdown_cell("# A run"),
    nbformat.v4.new_code_cell("import numpy as np\nx = np.arange(4)\nx.sum()"),
    nbformat.v4.new_code_cell("print('old output')"),
]
nbclient.NotebookClient(nb, kernel_name="python3").execute()
nbformat.write(nb, "run.ipynb")
EOF
uv run -q python make.py 2>/dev/null
git init -q

tm new-session -d -x 120 -y 34 -c "$PWD" "sleep 0.5; $nvim run.ipynb"
tm set -s extended-keys on
tm set -s extended-keys-format csi-u
sleep 14 # nvim, jupytext, the kernel's start and the output import
keys() { tm send-keys -t 0 "$@"; sleep 0.4; }
screen() { tm capture-pane -p -t 0; }
probe() {
    rm -f "$tmp/probe"
    tm send-keys -t 0 Escape
    sleep 0.2
    tm send-keys -t 0 ":lua vim.fn.writefile({ tostring($1) }, '$tmp/probe')" Enter
    sleep 0.4
    cat "$tmp/probe" 2>/dev/null
}
cell_output() { # the outputs of the notebook's cell N, as saved
    python3 -c "
import json, sys
c = json.load(open('run.ipynb'))['cells'][int(sys.argv[1])]
print(''.join(''.join(o.get('text', '')) or ''.join(o.get('data', {}).get('text/plain', '')) for o in c['outputs']))" "$1"
}

check "opens as Python cells" [ "$(probe 'vim.bo.filetype')" = python ]
check "the project's kernel started" [ "$(probe "table.concat(vim.fn.MoltenRunningKernels(true), ',')")" = venv-proj ]
check "it's registered as a Jupyter kernel" [ -f "$JUPYTER_DATA_DIR/kernels/venv-proj/kernel.json" ]
check "the saved outputs are back" sh -c "tmux -L nvim-notebook capture-pane -p -t 0 | grep -q 'old output'"
check "the header is folded, the cursor on the first cell" [ "$(probe "vim.fn.foldclosed(1) .. ':' .. vim.fn.getline('.')")" = '1:# %% [markdown]' ]

keys ']j'
check "]j: the next cell" [ "$(probe "vim.fn.getline('.')")" = 'import numpy as np' ]
keys S-Enter
sleep 2
check "Shift+Enter: runs it, goes to the next cell" [ "$(probe "vim.fn.getline('.')")" = "print('old output')" ]
check "  its output shows" sh -c "tmux -L nvim-notebook capture-pane -p -t 0 | grep -q 'Out\[[0-9]*\]: ✓ Done [0-9.]*s'"
keys cc "print('new output'"
keys Escape
keys C-Enter
sleep 2
check "Ctrl+Enter: runs it, stays" [ "$(probe "vim.fn.getline('.')")" = "print('new output')" ]
keys v i j
keys Escape
check "vij: the cell's code" [ "$(probe "vim.fn.line(\"'<\") == vim.fn.line(\"'>\") and vim.fn.getline(\"'<\")")" = "print('new output')" ]
keys ':w' Enter
sleep 4
check "saving: the new code in the .ipynb" sh -c "grep -q \"new output'\" run.ipynb"
check "saving: the new output in the .ipynb" [ "$(cell_output 2)" = 'new output' ]

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
