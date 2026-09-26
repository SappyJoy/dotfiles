return {
  { -- which-key setup
    'folke/which-key.nvim',
    event = 'VimEnter',
    dependencies = {
      'Wansmer/langmapper.nvim', -- Ensure langmapper is loaded first
    },
    config = function()
      -- Wait for langmapper to potentially finish its setup if needed
      vim.schedule(function()
        pcall(function() -- Wrap in pcall in case langmapper isn't fully ready
          local lmu = require 'langmapper.utils'
          local view = require 'which-key.view'
          local execute = view.execute

          -- Wrap `execute()` to translate sequence back for non-EN layouts
          view.execute = function(prefix_i, mode, buf)
            -- Translate back to English characters if needed
            prefix_i = lmu.translate_keycode(prefix_i, 'default', 'ru') -- Adapt 'ru' if needed
            execute(prefix_i, mode, buf)
          end
        end)

        require('which-key').setup {
          -- Add any which-key specific options here
          -- e.g., window options, triggers, etc.
        }

        -- Document existing key chains (add more as you define them)
        require('which-key').add {
          { '<leader>c', group = '[C]ode' },
          { '<leader>d', group = '[D]ocument' },
          { '<leader>g', group = '[G]it' },
          { '<leader>h', group = '[H]unk (GitSigns)' }, -- Map group for gitsigns actions
          { '<leader>o', group = '[O]ptions / Open' }, -- Unified group name
          { '<leader>r', group = '[R]efactor / [R]ename' },
          { '<leader>f', group = '[S]earch' },
          -- Hide placeholders for missing keys within groups
          { '<leader>c_', hidden = true },
          { '<leader>d_', hidden = true },
          { '<leader>f_', hidden = true },
          { '<leader>g_', hidden = true },
          -- ... and so on
        }
      end)
    end,
  },
}
