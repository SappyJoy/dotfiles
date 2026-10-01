-- Moving and editing: flash jumps, mini.ai text objects, surround, autopairs.
return {
  {
    'folke/flash.nvim',
    opts = {},
    keys = {
      {
        's',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Flash',
      },
      -- not in Visual mode: there S surrounds the selection
      {
        'S',
        mode = { 'n', 'o' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash treesitter',
      },
      {
        'r',
        mode = 'o',
        function()
          require('flash').remote()
        end,
        desc = 'Remote flash',
      },
      {
        'R',
        mode = { 'o', 'x' },
        function()
          require('flash').treesitter_search()
        end,
        desc = 'Treesitter search',
      },
      {
        '<c-s>',
        mode = 'c',
        function()
          require('flash').toggle()
        end,
        desc = 'Toggle flash search',
      },
    },
  },
  {
    -- a/i objects that also find the next one on the line (ci( before the brackets),
    -- plus f (function) and c (class) from treesitter's textobjects queries
    'nvim-mini/mini.ai',
    event = 'VeryLazy',
    dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
    opts = function()
      local ts = require('mini.ai').gen_spec.treesitter
      return {
        n_lines = 500,
        custom_textobjects = {
          f = ts { a = '@function.outer', i = '@function.inner' },
          c = ts { a = '@class.outer', i = '@class.inner' },
        },
      }
    end,
  },
  {
    -- vim-surround's keys: select, then S + char; ds" deletes, cs"' changes,
    -- ysiw" wraps a word
    'kylechui/nvim-surround',
    event = 'VeryLazy',
    opts = {},
  },
  { 'windwp/nvim-autopairs', event = 'InsertEnter', opts = {} },
}
