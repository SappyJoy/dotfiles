-- nvim-next: one module per capability. core/ needs no plugins and loads first;
-- lazy.nvim then loads lua/plugins/.
vim.loader.enable()

require 'core.options'
require 'core.keymaps'
require 'core.autocmds'
require 'core.lazy'
