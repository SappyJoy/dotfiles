--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear Search Highlight' }) -- Added desc

vim.keymap.set('n', '<C-s>', '<cmd>w<CR>', { desc = 'Save' })
vim.keymap.set('i', '<C-s>', '<Esc><cmd>w<CR>', { desc = 'Save' })
vim.keymap.set('n', '<C-q>', '<cmd>q<CR>', { desc = 'Quit' })

vim.keymap.set('n', '<C-t>', '<cmd>tabnew<CR>', { desc = 'New Tab' })

-- Terminal doesn't send this sequence to nvim
-- vim.keymap.set('n', '<C-Tab>', '<cmd>tabnext<CR>', { desc = 'Next Tab' })
-- vim.keymap.set('n', '<C-S-Tab>', '<cmd>tabprevious<CR>', { desc = 'Previous Tab' })

-- Diagnostic keymaps
vim.keymap.set('n', ']d', function()
  vim.diagnostic.goto_next { float = { border = 'single' } }
end, { desc = 'Jump to next [D]iagnostic' })

vim.keymap.set('n', '[d', function()
  vim.diagnostic.goto_prev { float = { border = 'single' } }
end, { desc = 'Jump to prev [D]iagnostic' })

vim.keymap.set('n', '<leader>dd', function()
  vim.diagnostic.open_float { border = 'single' }
end, { desc = 'Show diagnostic [E]rror messages' })

-- Toggle Virtual Text Diagnostics
vim.keymap.set('n', '<leader>E', function()
  local current_vt = vim.diagnostic.config().virtual_text
  vim.diagnostic.config { virtual_text = not current_vt }
end, { desc = 'Toggle Virtual Text Diagnostics' })

vim.keymap.set('n', '<leader>dq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode (keep commented if default <C-\><C-n> works)
-- vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Scroll centering
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down half page', noremap = true })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up half page', noremap = true })

-- Replace word under cursor
vim.keymap.set('n', '<leader>co', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Change all occurrences (current word)' })
-- WARNING: This visual mode mapping uses register "h". Might conflict with other plugins or workflows.
vim.keymap.set('v', '<leader>co', [["hy:%s/<C-r>h/<C-r>h/gI<Left><Left><left>]], { desc = 'Change all occurrences (visual selection)' })

-- Visual mode improvements
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line down' }) -- Fixed desc
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move line up' }) -- Fixed desc
vim.keymap.set('v', '<S-Down>', ":m '>+1<CR>gv=gv", { desc = 'Move line down' })
vim.keymap.set('v', '<S-Up>', ":m '<-2<CR>gv=gv", { desc = 'Move line up' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent line' }) -- Fixed desc
vim.keymap.set('v', '<', '<gv', { desc = 'Unindent line' }) -- Fixed desc

-- Copy file path
vim.keymap.set('n', '<leader>cf', function()
  local file_path = vim.fn.expand('%')
  vim.fn.setreg('+', file_path)
  vim.notify("Copied file path to clipboard: " .. file_path)
end, { desc = 'Copy file path to clipboard' })

-- -- =============================================================================
-- -- COLEMAK-DH MOVEMENT REMAPS (MNEI -> HJKL)
-- -- =============================================================================
--
-- -- 1. Map physical keys (MNEI) to movement (HJKL)
-- -- We map these in Normal, Visual, and Operator-pending modes
-- local modes = {'n', 'v', 'o'}
--
-- vim.keymap.set(modes, 'm', 'h', { desc = 'Move Left' })
-- vim.keymap.set(modes, 'n', 'j', { desc = 'Move Down' })
-- vim.keymap.set(modes, 'e', 'k', { desc = 'Move Up' })
-- vim.keymap.set(modes, 'i', 'l', { desc = 'Move Right' })
--
-- -- 2. Restore lost functionality
-- -- Since 'm', 'n', 'e', 'i' are now movement, we map their original functions
-- -- to the keys that used to be movement (h, j, k, l).
--
-- -- 'h' key (now empty) becomes 'm' (Mark)
-- vim.keymap.set(modes, 'h', 'm', { desc = 'Set Mark' })
--
-- -- 'j' key (now empty) becomes 'n' (Next search result)
-- vim.keymap.set(modes, 'j', 'n', { desc = 'Next search result' })
-- -- Make 'J' (Shift+j) act as 'N' (Prev search result) for consistency
-- vim.keymap.set(modes, 'J', 'N', { desc = 'Prev search result' })
--
-- -- 'k' key (now empty) becomes 'e' (End of word)
-- vim.keymap.set(modes, 'k', 'e', { desc = 'End of word' })
-- -- Make 'K' act as 'E' (End of WORD)
-- vim.keymap.set(modes, 'K', 'E', { desc = 'End of WORD' })
-- -- NOTE: You previously mapped 'K' to move line up in visual mode.
-- -- You might want to update that visual map to use 'E' or keep this overwrite.
--
-- -- 'l' key (now empty) becomes 'i' (Insert)
-- vim.keymap.set(modes, 'l', 'i', { desc = 'Insert mode' })
-- vim.keymap.set(modes, 'L', 'I', { desc = 'Insert at start of line' })
--
-- -- Update Window Navigation (Ctrl+w) to use MNEI
-- vim.keymap.set('n', '<C-w>m', '<C-w>h', { desc = 'Window Left' })
-- vim.keymap.set('n', '<C-w>n', '<C-w>j', { desc = 'Window Down' })
-- vim.keymap.set('n', '<C-w>e', '<C-w>k', { desc = 'Window Up' })
-- vim.keymap.set('n', '<C-w>i', '<C-w>l', { desc = 'Window Right' })
