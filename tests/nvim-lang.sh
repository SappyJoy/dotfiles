#!/bin/sh
# Every language of nvim's lang/ on a sample file: its language servers attach and
# it's highlighted (treesitter, or vim's syntax where a plugin owns it). Each file
# opens in its own headless nvim (jdtls and kotlin-lsp take a while to start). Needs
# the mason tools and parsers installed.
# Run: sh tests/nvim-lang.sh [NAME…]   (NAME: a sample below, e.g. main.py; default all)
#   NVIM=path/to/nvim (default: nvim on PATH); NVIM_APPNAME picks the config as usual

set -u
nvim=${NVIM:-nvim}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0

# file, then the servers that must attach ("-" for none)
expect='main.py basedpyright,ruff
init.lua lua_ls
main.c clangd
main.cpp clangd
src/main.rs rust_analyzer
main.go gopls
index.ts vtsls
app.js vtsls
page.ets vtsls
Main.java jdtls
Main.kt kotlin_lsp
query.sql -
doc.tex texlab
doc.typ tinymist
run.sh bashls
conf.fish -
data.json jsonls
compose.yaml yamlls
pyproject.toml taplo
Dockerfile -
note.md -'

proj=$tmp/proj
mkdir -p "$proj/src" && cd "$proj" && git init -q
printf '[project]\nname = "sample"\nversion = "0.1.0"\n\n[tool.ruff]\nline-length = 100\n' >pyproject.toml
printf 'import os\n\nprint(os.getcwd())\n' >main.py
printf 'local M = {}\nreturn M\n' >init.lua
printf 'int main(void) { return 0; }\n' >main.c
printf '#include <vector>\nint main() { std::vector<int> v; return v.size(); }\n' >main.cpp
printf '[package]\nname = "sample"\nversion = "0.1.0"\nedition = "2021"\n' >Cargo.toml
printf 'fn main() {\n    println!("hi");\n}\n' >src/main.rs
printf 'module sample\n\ngo 1.22\n' >go.mod
printf 'package main\n\nfunc main() {}\n' >main.go
printf 'const x: number = 1;\nexport default x;\n' >index.ts
printf 'const y = 2;\nconsole.log(y);\n' >app.js
printf 'let z: number = 3;\n' >page.ets
printf 'public class Main {\n  public static void main(String[] a) {}\n}\n' >Main.java
printf 'fun main() {\n    println("hi")\n}\n' >Main.kt
printf 'SELECT 1;\n' >query.sql
printf '\\documentclass{article}\n\\begin{document}\nHi\n\\end{document}\n' >doc.tex
printf '= Title\n\nSome text.\n' >doc.typ
printf '#!/bin/sh\necho hi\n' >run.sh
printf 'function f\n    echo hi\nend\n' >conf.fish
printf '{ "a": 1 }\n' >data.json
printf 'services:\n  app:\n    image: alpine\n' >compose.yaml
printf 'FROM alpine\nRUN echo hi\n' >Dockerfile
printf '# A note\n\nText.\n' >note.md

cat >"$tmp/check.lua" <<'EOF'
-- after VimEnter, as in a real start: lazy fires VeryLazy (which loads the LSP) once
-- a UI has entered, and headless has none; vim.lsp.enable attaches to the buffers
-- already open only after VimEnter
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = vim.schedule_wrap(function()
    if not vim.g.did_very_lazy then
      vim.api.nvim_exec_autocmds('User', { pattern = 'VeryLazy', modeline = false })
    end
    local want = vim.env.WANT == '-' and {} or vim.split(vim.env.WANT, ',')
    local function names()
      local out = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients { bufnr = 0 })
      table.sort(out)
      return out
    end
    vim.wait(60000, function()
      local have = names()
      return vim.iter(want):all(function(n) return vim.tbl_contains(have, n) end)
    end, 200)
    -- treesitter, or vim's syntax where a plugin owns it (vimtex for LaTeX)
    local hl = vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] and 'treesitter'
      or vim.b.current_syntax and 'syntax'
      or 'none'
    vim.fn.writefile({ table.concat(names(), ','), hl }, vim.env.OUT)
    vim.cmd 'qa!'
  end),
})
EOF

printf '%s\n' "$expect" | while read -r file want; do
    if [ $# -gt 0 ]; then
        case " $* " in *" $file "*) ;; *) continue ;; esac
    fi
    WANT=$want OUT=$tmp/out timeout 90 "$nvim" --headless "$file" -c "luafile $tmp/check.lua" >/dev/null 2>&1
    got=$(sed -n 1p "$tmp/out" 2>/dev/null)
    hl=$(sed -n 2p "$tmp/out" 2>/dev/null)
    missing=
    [ "$want" = - ] || for s in $(printf '%s' "$want" | tr , ' '); do
        case ",$got," in *",$s,"*) ;; *) missing="$missing $s" ;; esac
    done
    if [ -z "$missing" ] && [ "$hl" != none ] && [ -n "$hl" ]; then
        echo "ok   $file: ${got:-no server}, highlighted ($hl)"
    else
        echo "FAIL $file: servers ${got:-none} (missing:${missing:- none}), highlighted: ${hl:-?}"
        echo x >>"$tmp/fails"
    fi
    rm -f "$tmp/out"
done

if [ -s "$tmp/fails" ]; then
    echo "$(wc -l <"$tmp/fails") failed"
    exit 1
fi
echo "all passed"
