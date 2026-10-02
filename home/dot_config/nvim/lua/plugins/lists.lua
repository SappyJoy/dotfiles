-- Lists: trouble (diagnostics, references, quickfix), todo-comments, outline.

-- Replace text in every line of the quickfix list (e.g. a grep's matches): plain
-- text, case-sensitive, each line once, changed files saved. The old text defaults
-- to the search telescope put in the list's title, "Live Grep (old)".
local function replace_in_list()
  local list = vim.fn.getqflist { items = 0, title = 0 }
  if #list.items == 0 then
    return vim.notify('The list is empty: grep first (<leader>sg, then Ctrl+Q)', vim.log.levels.WARN)
  end
  local old = vim.fn.input('Replace: ', list.title:match '%((.*)%)$' or '')
  if old == '' then
    return
  end
  local new = vim.fn.input('Replace "' .. old .. '" with: ')
  local seen, count, files = {}, 0, {}
  for _, item in ipairs(list.items) do
    local key = item.bufnr .. ':' .. item.lnum
    if item.bufnr > 0 and not seen[key] then
      seen[key] = true
      vim.fn.bufload(item.bufnr)
      local line = vim.api.nvim_buf_get_lines(item.bufnr, item.lnum - 1, item.lnum, false)[1] or ''
      local escaped = new:gsub('%%', '%%%%')
      local changed, n = line:gsub(vim.pesc(old), escaped)
      if n > 0 then
        vim.api.nvim_buf_set_lines(item.bufnr, item.lnum - 1, item.lnum, false, { changed })
        count, files[item.bufnr] = count + n, true
      end
    end
  end
  for buf in pairs(files) do
    vim.api.nvim_buf_call(buf, function()
      vim.cmd 'silent update'
    end)
  end
  vim.notify(('Replaced %d in %d files (u in a file undoes it there)'):format(count, vim.tbl_count(files)))
end

return {
  {
    'folke/which-key.nvim',
    opts = { spec = { { '<leader>x', group = 'lists' } } },
  },
  {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    opts = {},
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Diagnostics (file)' },
      { '<leader>xs', '<cmd>Trouble symbols toggle focus=false<cr>', desc = 'Symbols' },
      {
        '<leader>xl',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        desc = 'LSP definitions, references',
      },
      { '<leader>xq', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix' },
      { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = 'Location list' },
      { '<leader>xt', '<cmd>Trouble todo toggle<cr>', desc = 'TODOs' },
      { '<leader>xr', replace_in_list, desc = 'Replace in the list (asks old, new)' },
    },
  },
  {
    'folke/todo-comments.nvim',
    event = 'VeryLazy',
    opts = {},
    keys = {
      {
        ']t',
        function()
          require('todo-comments').jump_next()
        end,
        desc = 'Next TODO',
      },
      {
        '[t',
        function()
          require('todo-comments').jump_prev()
        end,
        desc = 'Previous TODO',
      },
      { '<leader>st', '<cmd>TodoTelescope<cr>', desc = 'TODOs' },
    },
  },
  {
    'hedyhli/outline.nvim',
    cmd = 'Outline',
    opts = {},
    keys = { { '<leader>cs', '<cmd>Outline<cr>', desc = 'Symbols outline' } },
  },
}
