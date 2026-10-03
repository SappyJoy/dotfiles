-- Options that differ from nvim's defaults.

vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'
vim.g.have_nerd_font = true

-- The terminal shows images (kitty's graphics protocol): kitty sets KITTY_WINDOW_ID,
-- and tmux passes it on when its server started in kitty. Not over ssh, not in
-- Windows Terminal.
vim.g.kitty_graphics = vim.env.KITTY_WINDOW_ID ~= nil

-- Python host: the uv venv chezmoi builds (run_onchange_after_27-nvim-python.sh). A
-- fixed path, not stdpath: it stays where it is whatever NVIM_APPNAME says.
vim.g.python3_host_prog = vim.fn.expand '~/.local/share/nvim/venv/bin/python'
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

local o = vim.opt

o.guicursor = '' -- a block cursor in every mode
o.termguicolors = true
o.number = true
o.relativenumber = true
o.numberwidth = 3
o.signcolumn = 'yes'
o.cursorline = true
o.colorcolumn = '120'
o.wrap = false -- text soft-wraps (autocmds.lua)
o.foldlevelstart = 99 -- files open unfolded (treesitter folds, zc/zo)
o.breakindent = true
o.scrolloff = 10
o.list = true
o.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
o.laststatus = 3
o.showmode = false
o.title = true
o.winborder = 'rounded'
o.splitright = true
o.splitbelow = true

o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true

o.ignorecase = true
o.smartcase = true
o.inccommand = 'split'
o.mouse = 'a'
o.confirm = true -- :q on a changed buffer asks instead of failing
o.exrc = true -- a project's .nvim.lua, once trusted (nvim asks; :trust after edits)
o.updatetime = 250
o.timeoutlen = 300

o.swapfile = false
o.undofile = true
o.undodir = vim.fn.expand '~/.vim/undodir' -- shared with the old config

-- Spelling (on in text, ui/prose.lua, which adds Russian where its spell file is:
-- the installer downloads it, install.lua). Words added with zg go to the config,
-- so they're tracked.
o.spelllang = 'en'
o.spellcapcheck = '' -- no "capital letter" marks, only misspellings
o.spellfile = vim.fn.stdpath 'config' .. '/spell/en.utf-8.add'

o.langmap = require 'core.langmap'

-- vim's regex syntax only where treesitter doesn't highlight (treesitter.lua sets it):
-- markdown's alone pulled in HTML, CSS, YAML and VB syntax for nothing
vim.cmd 'syntax manual'

-- The clipboard provider's check costs startup time: set it once the UI is up.
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)
