-- Keys that need no plugin. Leader groups, filled by the plugin modules:
--   <leader>s  search (telescope)      <leader>h  hunks (gitsigns)
--   <leader>d  diff (diffview)         <leader>x  lists (trouble)
--   <leader>c  code                    <leader>n  notes (obsidian)
--   <leader>o  org                     <leader>j  notebook
--   <leader>w  windows                 <leader>a  AI (Claude Code)
--   <leader>t  tests                   <leader>e  explorer, - oil
-- Moving around is mostly jumps (flash, search, the picker), arrows for small moves:
-- extra keys go on arrows, not on QWERTY's hjkl.
local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<cr>')
map('n', '<C-s>', '<cmd>write<cr>', { desc = 'Save' })
map('i', '<C-s>', '<Esc><cmd>write<cr>', { desc = 'Save' })
map('n', '<C-q>', '<cmd>confirm quit<cr>', { desc = 'Quit' })

-- Tabs. A new one holds a scratch buffer: paste, look, Ctrl+Q, no question asked.
map('n', '<C-t>', function()
  vim.cmd.tabnew()
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
end, { desc = 'Scratch tab' })
map('n', '<M-Left>', 'gT', { desc = 'Previous tab' })
map('n', '<M-Right>', 'gt', { desc = 'Next tab' })
map('n', '<M-S-Left>', '<cmd>-tabmove<cr>', { desc = 'Move tab left' })
map('n', '<M-S-Right>', '<cmd>+tabmove<cr>', { desc = 'Move tab right' })

-- Visual: move the selected lines, keep the selection after an indent
map('v', 'J', ":m '>+1<cr>gv=gv", { desc = 'Move lines down' })
map('v', 'K', ":m '<-2<cr>gv=gv", { desc = 'Move lines up' })
map('v', '<S-Down>', ":m '>+1<cr>gv=gv", { desc = 'Move lines down' })
map('v', '<S-Up>', ":m '<-2<cr>gv=gv", { desc = 'Move lines up' })
map('v', '>', '>gv')
map('v', '<', '<gv')

map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')

map('n', '<leader>co', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Change all occurrences' })
map('v', '<leader>co', [["hy:%s/<C-r>h/<C-r>h/gI<Left><Left><Left>]], { desc = 'Change all occurrences' })
map('n', '<leader>cf', function()
  vim.fn.setreg('+', vim.fn.expand '%')
  vim.notify('Copied ' .. vim.fn.expand '%')
end, { desc = 'Copy the file path' })
