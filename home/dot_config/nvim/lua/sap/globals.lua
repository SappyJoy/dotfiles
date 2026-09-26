-- -- 1. Construct the path to the UV-managed Python 3.12
-- -- Based on your `uv python list` output:
-- local uv_python_bin_path = vim.fn.expand("$HOME/.local/share/uv/python/cpython-3.12.9-linux-x86_64-gnu/bin")
--
-- -- 2. Prepend this path to the Neovim $PATH environment variable
-- -- This forces Mason to use UV's Python 3.12 instead of system Python 3.8
-- vim.env.PATH = uv_python_bin_path .. ":" .. vim.env.PATH

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Set to true if you have a Nerd Font installed
vim.g.have_nerd_font = true

-- Python Provider configuration (using dedicated conda env)
vim.g.python_host_prog = vim.fn.expand '$HOME' .. '/.conda/envs/nvim/bin/python'
vim.g.python3_host_prog = vim.fn.expand '$HOME' .. '/.conda/envs/nvim/bin/python3'

package.path = package.path .. ';' .. vim.fn.expand '$HOME' .. '/.luarocks/share/lua/5.1/?/init.lua;'
package.path = package.path .. ';' .. vim.fn.expand '$HOME' .. '/.luarocks/share/lua/5.1/?.lua;'

-- Standard Global Border Definition
vim.g.Border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }

vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
-- vim.g.loaded_node_provider = 0
