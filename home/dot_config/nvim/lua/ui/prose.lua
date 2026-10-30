-- Prose: text filetypes soft-wrap at word boundaries, get spelling (no linters), a
-- clean look (no line numbers or ruler; git signs stay). <leader>mn numbers.
local M = {}

M.filetypes = { markdown = true, text = true, gitcommit = true, tex = true, typst = true, org = true }

-- moving through wrapped text: j/k and the arrows go by screen line (as vim-pencil
-- did), a count by real lines (5j); in Insert mode the arrows too, unless blink's
-- menu is open (they move through it)
local function display_moves(buf)
  for key, screen in pairs { j = 'j', k = 'k', ['<Down>'] = 'j', ['<Up>'] = 'k' } do
    vim.keymap.set({ 'n', 'x' }, key, function()
      return vim.v.count == 0 and 'g' .. screen or key
    end, { buffer = buf, expr = true })
  end
  for key, dir in pairs { ['<Down>'] = 'next', ['<Up>'] = 'prev' } do
    vim.keymap.set('i', key, function()
      local ok, blink = pcall(require, 'blink.cmp')
      if ok and blink.is_menu_visible() then
        return blink['select_' .. dir]()
      end
      vim.cmd('normal! g' .. (dir == 'next' and 'j' or 'k'))
    end, { buffer = buf })
  end
end

-- English, and Russian where its spell file is (a machine that couldn't download
-- it would warn "Cannot find word list" in every text file)
local has_ru
local function spell(win, buf)
  if has_ru == nil then
    has_ru = #vim.api.nvim_get_runtime_file('spell/ru.utf-8.spl', false) > 0
  end
  vim.bo[buf].spelllang = has_ru and 'en,ru' or 'en'
  vim.wo[win][0].spell = true
end

local function prose(args)
  display_moves(args.buf)
  local wo = vim.wo[0][0]
  wo.wrap, wo.linebreak, wo.smoothscroll = true, true, true
  -- spelling loads its dictionaries on the first draw (~10 ms for en + ru): while
  -- nvim starts, it waits until the first screen is up
  local win = vim.api.nvim_get_current_win()
  if vim.v.vim_did_enter == 1 then
    spell(win, args.buf)
  else
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      once = true,
      callback = function()
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == args.buf then
          spell(win, args.buf)
        end
      end,
    })
  end
  wo.number, wo.relativenumber, wo.colorcolumn = false, false, ''
end

local group = vim.api.nvim_create_augroup('ui.prose', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = vim.tbl_keys(M.filetypes),
  callback = prose,
})

vim.keymap.set('n', '<leader>mn', function()
  vim.wo.number = not vim.wo.number
  vim.wo.relativenumber = vim.wo.number
end, { desc = 'Line numbers on/off' })

return M
