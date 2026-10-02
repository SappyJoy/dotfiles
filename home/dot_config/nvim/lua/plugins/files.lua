-- Files: oil edits a directory like a buffer (`-` opens the file's dir) and owns
-- directory buffers (`nvim .`); snacks' explorer is the tree on <leader>e.
return {
  {
    'stevearc/oil.nvim',
    cmd = 'Oil',
    keys = { { '-', '<cmd>Oil<cr>', desc = 'Parent directory (oil)' } },
    init = function()
      -- oil loads on demand, so a directory given at start opens it by hand
      local arg = vim.fn.argv(0)
      if vim.fn.argc() == 1 and vim.fn.isdirectory(arg) == 1 then
        require 'oil'
      end
    end,
    opts = {
      columns = {
        {
          'type',
          icons = { directory = 'd', fifo = 'p', file = '-', link = 'l', socket = 's' },
          highlight = 'Comment',
        },
        { 'permissions', highlight = 'Comment' },
        { 'size', highlight = 'Number' },
        { 'mtime', highlight = 'Comment' },
        'icon',
      },
      constrain_cursor = 'name',
      view_options = { show_hidden = true },
      win_options = { signcolumn = 'yes', foldcolumn = '1', spell = false },
      keymaps = {
        ['<C-s>'] = false, -- Ctrl+S saves (applies the edits), as everywhere
        ['<C-q>'] = 'actions.close', -- back to the file, not out of nvim
        ['<C-h>'] = false,
        ['<C-l>'] = false,
        ['<C-c>'] = false,
        ['<C-p>'] = 'actions.preview',
        ['<C-r>'] = 'actions.refresh',
        ['<C-t>'] = 'actions.select_tab',
      },
    },
  },
  {
    'folke/snacks.nvim',
    opts = { explorer = { replace_netrw = false } },
    keys = {
      {
        '<leader>e',
        function()
          Snacks.explorer()
        end,
        desc = 'Explorer (tree)',
      },
    },
  },
}
