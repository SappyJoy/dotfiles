return {
  {
    'romgrk/todoist.nvim',
    build = ':TodoistInstall',
    enabled = false,
    init = function()
      vim.g.todoist_default_provider = 'clap'
    end,
    config = function()
      local wk = require 'which-key'
      wk.add {
        {
          { '<leader>tt', '<cmd>Todoist<cr>', desc = 'Todoist Inbox' },
        },
      }
    end,
  },
}
