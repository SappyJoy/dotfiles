#!/bin/sh
# Tests for nvim's parser list (home/dot_config/nvim/lua/parsers.lua): with nothing
# installed, each parser is asked for once. nvim-treesitter builds a parser asked
# for twice in parallel in one cache folder, and the builds break each other.
# nvim-treesitter is a stub; the config is the source's, in a scratch XDG_CONFIG_HOME.
# Run: sh tests/nvim-parsers.sh (offline; needs nvim)

set -u
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/config"
ln -s "$here/../home/dot_config/nvim" "$tmp/config/nvim"

out=$(XDG_CONFIG_HOME=$tmp/config nvim --headless -u NONE -i NONE -c 'lua
package.path = vim.fn.stdpath("config") .. "/lua/?.lua;" .. vim.fn.stdpath("config") .. "/lua/?/init.lua;" .. package.path
package.loaded["nvim-treesitter"] = { get_installed = function() return {} end }
local seen, dups, list = {}, {}, require("parsers").missing()
for _, p in ipairs(list) do
  if seen[p] then table.insert(dups, p) end
  seen[p] = true
end
io.stdout:write(#list, ":", table.concat(dups, " "), "\n")' +qa 2>&1)

case $out in
    [1-9]*:) echo "ok   each parser asked for once (${out%:} parsers)"; echo "all passed" ;;
    *) echo "FAIL each parser asked for once: $out"; exit 1 ;;
esac
