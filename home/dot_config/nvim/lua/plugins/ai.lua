-- AI: Claude Code, connected to nvim through claudecode.nvim (the protocol of
-- Claude's VS Code extension). Claude runs in tmux (lua/ai.lua opens the panes); it
-- sees the file and the selection, takes sends as @file#L10-20, shows its edits as
-- diffs here and reads the diagnostics. The server starts after the first screen,
-- so a claude started by hand in this folder finds nvim too (it connects by itself
-- with CLAUDE_CODE_AUTO_CONNECT_IDE, set in Claude's settings.json).
local function claude(account)
  return function()
    require('ai').account = account
    require('claudecode.terminal').open() -- the provider gets the env with the port
  end
end

return {
  {
    'folke/which-key.nvim',
    opts = { spec = { { '<leader>a', group = 'AI (Claude Code)' } } },
  },
  {
    'coder/claudecode.nvim',
    enabled = vim.fn.executable 'claude' == 1,
    event = 'VeryLazy',
    keys = {
      { '<leader>ac', claude 'claude', desc = 'Claude (personal)' },
      { '<leader>aC', claude 'claude-team', desc = 'Claude (team)' },
      { '<leader>as', '<cmd>ClaudeCodeSend<cr>', mode = 'x', desc = 'Send the selection to Claude' },
      { '<leader>as', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Send this file to Claude' },
      {
        '<leader>as',
        '<cmd>ClaudeCodeTreeAdd<cr>',
        ft = { 'oil', 'snacks_picker_list' },
        desc = 'Send the file to Claude',
      },
      { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', desc = "Accept Claude's edit" },
      { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', desc = "Reject Claude's edit" },
    },
    opts = function()
      return { terminal = { provider = require('ai').provider } }
    end,
    config = function(_, opts)
      require('claudecode').setup(opts)
      vim.api.nvim_create_autocmd('User', {
        pattern = 'ClaudeCodeSendComplete',
        group = vim.api.nvim_create_augroup('ai', { clear = true }),
        callback = function()
          require('ai').focus()
        end,
      })
    end,
  },
}
