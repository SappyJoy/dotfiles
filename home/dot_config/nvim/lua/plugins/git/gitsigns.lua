return {
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' }, -- Load when opening a buffer
    dependencies = { 'tpope/vim-repeat' },
    opts = {
      -- Signs configuration (using block characters)
      signs = {
        add = { text = '█' },
        change = { text = '█' },
        delete = { text = '█' },
        topdelete = { text = '▀' },
        changedelete = { text = '▒' },
        untracked = { text = '┆' },
      },
      signcolumn = true, -- Always show the signcolumn
      numhl = false, -- Do not highlight the number column based on sign
      linehl = false, -- Do not highlight the whole line based on sign
      word_diff = false, -- Disable word diff highlighting within changed lines
      watch_gitdir = { -- Improve performance by watching the .git directory
        interval = 1000,
        follow_files = true,
      },
      attach_to_untracked = true, -- Show signs for untracked files
      -- Current line blame configuration
      current_line_blame = true, -- Enable virtual text blame for the current line
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', -- Show blame at the end of the line
        delay = 100, -- Delay before showing blame (ms) - increased slightly
        ignore_whitespace = false,
        virt_text_priority = 100, -- Rendering priority
      },
      current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>', -- Blame format string
      sign_priority = 6,
      update_debounce = 100, -- Debounce time for updates (ms)
      status_formatter = nil, -- Use default status formatter for git status component integration (e.g., with statuslines)
      max_file_length = 40000, -- Disable for very large files (lines)
      preview_config = { -- Configuration for hunk preview window
        border = 'rounded',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1,
      },
    },
    -- Define keymaps using the standard `keys` table for lazy-loading
    keys = {
      -- Hunk Navigation (Repeatable with vim-repeat)
      {
        ']c', -- Or use ']h' if you prefer
        function()
          if vim.wo.diff then
            -- In diff mode, execute Vim's native ]c for diff navigation
            return ']c'
          end
          -- Otherwise, use gitsigns. Schedule it to mimic gitsigns' own behavior.
          vim.schedule(function()
            require('gitsigns').next_hunk()
          end)
          -- Tell Neovim the mapping was handled and it shouldn't process ']c' further.
          return '<Ignore>'
        end,
        mode = 'n',
        expr = true, -- Crucial for the conditional return logic
        desc = 'Next Hunk (GitSigns)',
      },
      {
        '[c', -- Or use '[h' if you prefer
        function()
          if vim.wo.diff then
            return '[c'
          end
          vim.schedule(function()
            require('gitsigns').prev_hunk()
          end)
          return '<Ignore>'
        end,
        mode = 'n',
        expr = true, -- Crucial!
        desc = 'Previous Hunk (GitSigns)',
      },

      -- Hunk Actions
      {
        '<leader>hs',
        function()
          require('gitsigns').stage_hunk()
        end,
        mode = { 'n', 'v' },
        desc = 'Stage Hunk',
      },
      {
        '<leader>hr',
        function()
          require('gitsigns').reset_hunk()
        end,
        mode = { 'n', 'v' },
        desc = 'Reset Hunk',
      },
      {
        '<leader>hp',
        function()
          require('gitsigns').preview_hunk()
        end,
        mode = 'n',
        desc = 'Preview Hunk',
      },
      {
        '<leader>hb',
        function()
          require('gitsigns').blame_line { full = true }
        end,
        mode = 'n',
        desc = 'Blame Line',
      },
      {
        '<leader>hS',
        function()
          require('gitsigns').stage_buffer()
        end,
        mode = 'n',
        desc = 'Stage Buffer',
      },
      {
        '<leader>hR',
        function()
          require('gitsigns').reset_buffer()
        end,
        mode = 'n',
        desc = 'Reset Buffer',
      },
      -- Diffing
      {
        '<leader>hd',
        function()
          require('gitsigns').diffthis()
        end,
        mode = 'n',
        desc = 'Diff This',
      },
      {
        '<leader>hD',
        function()
          require('gitsigns').diffthis '~'
        end,
        mode = 'n',
        desc = 'Diff This ~',
      },
      -- Toggles
      {
        '<leader>gtd',
        function()
          require('gitsigns').toggle_deleted()
        end,
        mode = 'n',
        desc = '[T]oggle [D]eleted Signs',
      },
      {
        '<leader>gb',
        function()
          require('gitsigns').blame()
        end,
        mode = 'n',
        desc = '[G]it [B]lame',
      },
      {
        '<leader>tB',
        function()
          require('gitsigns').toggle_current_line_blame()
        end,
        mode = 'n',
        desc = '[T]oggle Line [B]lame',
      },
    },
  },
}
