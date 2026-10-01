-- Lists: trouble (diagnostics, references, quickfix), todo-comments, outline.
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
