return {
  {
    'kdheepak/lazygit.nvim',
    enabled = false,
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    dependencies = {
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
    },
    keys = {
      { '<leader>gl', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
    },
  },

  -- Diffview: Enhanced Git Diff Viewer
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    dependencies = { 'nvim-lua/plenary.nvim', 'lewis6991/gitsigns.nvim' },
    keys = {
      { '<leader>do', '<cmd>DiffviewOpen<cr>', desc = '[D]iff [O]pen (Changes)' },
      { '<leader>dc', '<cmd>DiffviewClose<cr>', desc = '[D]iff [C]lose' },
      { '<leader>dh', '<cmd>DiffviewFileHistory %<cr>', desc = '[D]iff File [H]istory' },
      { '<leader>dH', '<cmd>DiffviewFileHistory<cr>', desc = '[D]iff Repo [H]istory' },
      { '<leader>dm', '<cmd>DiffviewOpen master...<cr>', desc = '[D]iff Against [M]aster' },
      -- Diff line history
      {
        '<leader>dl',
        function()
          local current_line = vim.fn.line '.'
          local file = vim.fn.expand '%'
          local cmd = string.format('DiffviewFileHistory --follow -L%s,%s:%s', current_line, current_line, file)
          vim.cmd(cmd)
        end,
        desc = '[D]iff [L]ine History',
      },
      -- Open the commit that touched the current line in Diffview
      {
        '<leader>dC',
        function()
          local line = vim.fn.line '.'
          local file = vim.fn.expand '%'
          -- Get the commit hash for the current line
          local cmd = 'git blame -L ' .. line .. ',' .. line .. ' -l -s ' .. file
          local output = vim.fn.system(cmd)
          local commit_hash = vim.split(output, ' ')[1]

          if commit_hash and #commit_hash > 0 and commit_hash ~= '0000000000000000000000000000000000000000' then
            -- Open Diffview for this commit (hash^! syntax means "this commit vs parent")
            vim.cmd('DiffviewOpen ' .. commit_hash .. '^!')
            vim.notify('Viewing Commit: ' .. commit_hash)
          else
            vim.notify('No commit found for this line (uncommitted?)', vim.log.levels.WARN)
          end
        end,
        desc = '[D]iff [C]ommit at Line',
      },
    },
    config = function()
      local wk = require 'which-key'
      wk.add {
        {
          mode = { 'v' },
          { '<leader>dl', "<Esc><Cmd>'<,'>DiffviewFileHistory --follow<CR>", desc = 'File History for visual selection' },
        },
      }
      require('diffview').setup {
        use_icons = vim.g.have_nerd_font,
        signs = {
          fold_closed = '',
          fold_open = '',
          line_prefix = '│',
        },
      }
    end,
  },

  -- Neogit: Magit-like Git interface for Neovim
  {
    'NeogitOrg/neogit',
    enabled = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim', -- Recommended for diff viewing integration
      'nvim-telescope/telescope.nvim', -- Optional for commit searching etc.
    },
    cmd = 'Neogit', -- Lazy load on command
    keys = {
      { '<leader>gn', '<cmd>Neogit<cr>', desc = 'Neogit' },
      -- Git log for current file
      {
        '<leader>gfl',
        function()
          require('neogit').open { 'log', '--', vim.fn.expand '%' }
        end,
        desc = 'Neogit [F]ile [L]og',
      },
      -- Git log for selected lines in visual mode
      {
        '<leader>gl',
        function()
          local file = vim.fn.expand '%'
          -- Ensure we are out of visual mode before getting positions
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
          local line_start = vim.fn.getpos("'<")[2]
          local line_end = vim.fn.getpos("'>")[2]
          -- Use Neogit's action directly if available, otherwise construct command
          require('neogit').open { 'log', ('-L%d,%d:%s'):format(line_start, line_end, file) }
        end,
        desc = 'Neogit [L]ine Log (Visual)',
        mode = 'v',
      },
      -- Add other neogit actions/keymaps if needed
      {
        '<leader>gc',
        function()
          require('neogit').open { 'commit' }
        end,
        desc = 'Neogit [C]ommit',
      },
      {
        '<leader>gs',
        function()
          require('neogit').open()
        end,
        desc = 'Neogit [S]tatus',
      }, -- Same as gg
    },
    config = function()
      require('neogit').setup {
        -- Configure Neogit options here
        integrations = {
          -- Diffview integration is enabled by default if diffview is detected
          diffview = true,
        },
        -- kind = "tab", -- Open in a new tab instead of split
        -- signs = { ... } -- Customize signs
      }
    end,
  },
}
