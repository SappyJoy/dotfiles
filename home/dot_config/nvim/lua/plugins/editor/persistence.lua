-- lua/plugins/persistence.lua
return {
  {
    'folke/persistence.nvim',
    event = 'BufReadPre', -- Load nicely on start
    opts = {
      -- Directory where session files will be stored
      dir = vim.fn.stdpath 'data' .. '/sessions/',
      -- Options to save with the session
      options = { 'buffers', 'curdir', 'tabpages', 'winsize', 'help', 'globals', 'skiprtp' },
      -- Pre-save hook (optional)
      -- pre_save = function() vim.cmd('tabcloseall') end,
      -- Automatically save the session when quitting Neovim
      autosave = { last = true },
      -- Automatically load the session for the current directory if it exists
      autoload = true,
    },
    keys = {
      { '<leader>qs', function() require('persistence').save() end,                     desc = '[Q]uit [S]ave Session' },
      { '<leader>qS', function() require('persistence').select() end,                     desc = '[Q]uit [S]elect Session' },
      { '<leader>ql', function() require('persistence').load() end,                     desc = '[Q]uit [L]oad Session' },
      { '<leader>qd', function() require('persistence').stop() require('persistence').load { last = true } end, desc = '[Q]uit [D]elete Current Session and Load Last' },
      -- Note: 'stop()' is needed if you want to load another session *after* the current one was loaded.
    },
  },
}
