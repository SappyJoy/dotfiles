-- nvim-next: one module per capability. core/ and ui/ need no plugins and load
-- first; lazy.nvim then loads lua/plugins/.
vim.loader.enable()

require 'core.options'
require 'core.keymaps'
require 'core.autocmds'
require 'core.diagnostics'
require 'core.russian'
require 'ui.prose'
require 'ui.statusline'
require 'core.lazy'
