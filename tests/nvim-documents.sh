#!/bin/sh
# nvim's documents module (lua/documents.lua): a sample of each format opens as
# readable text, read-only; a .pth that is a Python path file and a .db that isn't
# SQLite open as they are; a pickle's code never runs; CSV gets csvview; zip and tar
# open in nvim's own archive browsers.
# Needs pandoc, xelatex, duckdb, uv (numpy, h5py, openpyxl), ffmpeg, mediainfo, 7z.
# Run: sh tests/nvim-documents.sh
#   NVIM=path/to/nvim (default: nvim on PATH); NVIM_APPNAME picks the config as usual

set -u
nvim=${NVIM:-nvim}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0
check() { # check NAME CONDITION...
    name=$1; shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fails=$((fails + 1)); fi
}

d=$tmp/docs
mkdir -p "$d" && cd "$d" || exit 1
printf '# Report\n\nПривет, document text here.\n\n| a | b |\n|---|---|\n| 1 | 2 |\n' >src.md
pandoc src.md -o doc.pdf --pdf-engine=xelatex -V 'mainfont=Noto Serif' 2>/dev/null
for f in docx odt epub pptx; do pandoc src.md -o "doc.$f" 2>/dev/null; done
duckdb -c "COPY (SELECT range AS id, 'item ' || range AS name FROM range(30)) TO 'data.parquet'"
python3 -c "
import sqlite3
db = sqlite3.connect('lib.sqlite')
db.execute('CREATE TABLE books (id INTEGER, title TEXT)')
db.executemany('INSERT INTO books VALUES (?, ?)', [(1, 'Dune'), (2, 'Solaris')])
db.commit()
"
printf 'not a database\n' >notes.db
printf '/some/site/packages/path\n' >paths.pth
uv run -q --with numpy --with h5py --with openpyxl python - <<'EOF'
import io, json, pickle, struct, sys, types, zipfile
import h5py, numpy as np, openpyxl
np.save('feat.npy', np.arange(12, dtype=np.float32).reshape(3, 4))
np.savez('pack.npz', w=np.ones((2, 5)), b=np.zeros(3))
with h5py.File('model.h5', 'w') as f:
    f['layer/kernel'] = np.ones((4, 8), dtype=np.float32)
header = {'embed.weight': {'dtype': 'F32', 'shape': [10, 4], 'data_offsets': [0, 160]}}
raw = json.dumps(header).encode()
open('w.safetensors', 'wb').write(struct.pack('<Q', len(raw)) + raw + bytes(160))
class Evil:
    def __reduce__(self):
        import os
        return (os.system, ('touch PWNED',))
pickle.dump({'emb': np.zeros((7, 3), dtype=np.float32), 'evil': Evil()}, open('obj.pkl', 'wb'))
# a PyTorch checkpoint as torch writes it (zip with data.pkl), made without torch
torch = types.ModuleType('torch'); utils = types.ModuleType('torch._utils')
def _rebuild_tensor_v2(*a): pass
_rebuild_tensor_v2.__module__ = 'torch._utils'; utils._rebuild_tensor_v2 = _rebuild_tensor_v2
class FloatStorage: pass
FloatStorage.__module__ = 'torch'; torch.FloatStorage = FloatStorage
sys.modules.update({'torch': torch, 'torch._utils': utils})
class T:
    def __reduce__(self):
        return (_rebuild_tensor_v2, (Store(), 0, (16, 8), (8, 1), False, {}))
class Store: pass
class P(pickle.Pickler):
    def persistent_id(self, obj):
        return ('storage', FloatStorage, '0', 'cpu', 128) if isinstance(obj, Store) else None
buf = io.BytesIO(); P(buf, protocol=2).dump({'fc.weight': T()})
with zipfile.ZipFile('ckpt.pt', 'w') as z:
    z.writestr('archive/data.pkl', buf.getvalue()); z.writestr('archive/version', '3\n')
wb = openpyxl.Workbook(); ws = wb.active; ws.title = 'Sales'
ws.append(['region', 'total']); ws.append(['north', 42]); wb.save('sheet.xlsx')
EOF
ffmpeg -loglevel error -f lavfi -i 'sine=frequency=440:duration=1' tone.wav
printf 'x\n' >inner.txt && 7z a -bso0 arc.7z inner.txt && zip -q arc.zip inner.txt && tar czf arc.tar.gz inner.txt
printf 'name,score\nann,1\nbob,22\n' >t.csv

# open FILE, wait for the conversion, print the buffer and its state
cat >"$tmp/open.lua" <<'EOF'
vim.wait(30000, function()
  local first = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ''
  return not first:find '^Reading ' and (vim.bo.filetype ~= 'csv' or package.loaded.csvview)
end, 100)
vim.wait(300)
local ok, csv = pcall(require, 'csvview')
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
table.insert(lines, ('STATE readonly=%s buftype=%s csvview=%s ft=%s'):format(vim.bo.readonly, vim.bo.buftype,
  tostring(ok and csv.is_enabled(0)), vim.bo.filetype))
vim.fn.writefile(lines, vim.env.OUT)
vim.cmd 'qa!'
EOF
show() { OUT=$tmp/out timeout 60 "$nvim" --headless "$1" -c "luafile $tmp/open.lua" >/dev/null 2>&1; cat "$tmp/out" 2>/dev/null; }
has() { show "$1" | grep -qF -- "$2"; }

check "pdf: its text" has doc.pdf 'Привет, document text here.'
check "pdf: read-only" has doc.pdf 'STATE readonly=true buftype=nowrite'
for f in docx odt epub pptx; do check "$f: as Markdown" has "doc.$f" 'Привет, document text here.'; done
check "xlsx: the sheet's cells" has sheet.xlsx 'north'
check "xlsx: a table, not the zip browser" has sheet.xlsx 'ft=document'
check "docx: Markdown, not the zip browser" has doc.docx 'ft=markdown'
check "parquet: schema and rows" has data.parquet 'item 29'
check "sqlite: tables and rows" has lib.sqlite 'Solaris'
check "npy: shape and stats" has feat.npy 'min 0  max 11  mean 5.5  NaN 0'
check "npz: its arrays" has pack.npz '[2, 5]'
check "h5: datasets" has model.h5 'layer/kernel'
check "safetensors: tensors" has w.safetensors 'embed.weight'
check "pt: a tensor's shape, without torch" has ckpt.pt '[16, 8]'
check "pkl: arrays; code shown, not run" has obj.pkl 'posix.system'
check "pkl: nothing ran" [ ! -e PWNED ]
check "media: mediainfo" has tone.wav 'Sampling rate'
check "7z: listing" has arc.7z 'inner.txt'
check "zip: nvim's browser" has arc.zip 'inner.txt'
check "tar.gz: nvim's browser" has arc.tar.gz 'inner.txt'
check "pth that is text: as it is, editable" has paths.pth 'STATE readonly=false buftype='
check "db that isn't SQLite: as it is" has notes.db 'not a database'
check "csv: csvview on, editable" has t.csv 'STATE readonly=false buftype= csvview=true'

if [ $fails -gt 0 ]; then
    echo "$fails failed"
    exit 1
fi
echo "all passed"
