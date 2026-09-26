return {
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
    },
    keys = {
      { '<C-Left>',  '<cmd>TmuxNavigateLeft<cr>',  desc = 'Tmux Nav Left' },
      { '<C-Down>',  '<cmd>TmuxNavigateDown<cr>',  desc = 'Tmux Nav Down' },
      { '<C-Up>',    '<cmd>TmuxNavigateUp<cr>',    desc = 'Tmux Nav Up' },
      { '<C-Right>', '<cmd>TmuxNavigateRight<cr>', desc = 'Tmux Nav Right' },
      { '<C-\\>',    '<cmd>TmuxNavigatePrevious<cr>', desc = 'Tmux Nav Previous' },
    },
    init = function()
        -- Disable default mappings (C-h, C-j, etc) so only your C-Arrow keys work
        vim.g.tmux_navigator_no_mappings = 1
    end,
    config = function()
      -- Terminal mode (inside :term buffers)
      vim.keymap.set('t', '<C-Left>',  [[<C-\><C-n><cmd>TmuxNavigateLeft<cr>]])
      vim.keymap.set('t', '<C-Down>',  [[<C-\><C-n><cmd>TmuxNavigateDown<cr>]])
      vim.keymap.set('t', '<C-Up>',    [[<C-\><C-n><cmd>TmuxNavigateUp<cr>]])
      vim.keymap.set('t', '<C-Right>', [[<C-\><C-n><cmd>TmuxNavigateRight<cr>]])
      vim.keymap.set('t', '<C-\\>',    [[<C-\><C-n><cmd>TmuxNavigatePrevious<cr>]])
    end,
  },
}
