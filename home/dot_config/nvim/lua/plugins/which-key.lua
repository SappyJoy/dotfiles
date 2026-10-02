-- which-key: names the leader groups and runs the sticky modes ("hydras"): a loop
-- keeps its popup open, so a group's keys repeat until Esc. Modules add their own
-- groups through opts.spec (extended, not replaced: core/lazy.lua).
return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    -- the Russian twins (core/russian.lua) stay out of the popup: there a Russian
    -- key reads as the Latin one (config below)
    filter = function(mapping)
      return not require('core.russian').is_twin(mapping.lhs or '')
    end,
    spec = {
      -- Windows: <leader>w loops over vim's own <C-w> keys, with arrows (built in)
      -- instead of hjkl, and Shift+arrows to move a window.
      {
        '<leader>w',
        function()
          require('which-key').show { keys = '<c-w>', loop = true }
        end,
        desc = 'Windows (sticky)',
      },
      { '<c-w><Left>', '<c-w>h', desc = 'Focus left' },
      { '<c-w><Down>', '<c-w>j', desc = 'Focus down' },
      { '<c-w><Up>', '<c-w>k', desc = 'Focus up' },
      { '<c-w><Right>', '<c-w>l', desc = 'Focus right' },
      { '<c-w><S-Left>', '<c-w>H', desc = 'Move window left' },
      { '<c-w><S-Down>', '<c-w>J', desc = 'Move window down' },
      { '<c-w><S-Up>', '<c-w>K', desc = 'Move window up' },
      { '<c-w><S-Right>', '<c-w>L', desc = 'Move window right' },
      { '<c-w>h', hidden = true },
      { '<c-w>j', hidden = true },
      { '<c-w>k', hidden = true },
      { '<c-w>l', hidden = true },
      { '<c-w>H', hidden = true },
      { '<c-w>J', hidden = true },
      { '<c-w>K', hidden = true },
      { '<c-w>L', hidden = true },
      { '<leader>c', group = 'code' },
    },
  },
  config = function(_, opts)
    require('which-key').setup(opts)
    -- Keys typed while the popup waits: <leader>ву = <leader>sf. which-key reads them
    -- with its (internal) state.getchar; tests/nvim-keys.sh checks it still does.
    local state = require 'which-key.state'
    local getchar = state.getchar
    state.getchar = function()
      local ok, char = getchar()
      if ok and not vim.api.nvim_get_mode().mode:find '^[ic]' then
        char = require('core.russian').to_latin(char)
      end
      return ok, char
    end
  end,
}
