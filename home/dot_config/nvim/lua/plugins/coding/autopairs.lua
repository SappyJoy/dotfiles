return {
  {
    'windwp/nvim-autopairs',
    event = { 'InsertEnter' }, -- Load when entering insert mode
    dependencies = { 'hrsh7th/nvim-cmp' }, -- Ensure cmp is loaded
    opts = {
      check_ts = true, -- Use treesitter to check context for pairing
      ts_config = {
        lua = { 'string', 'source' }, -- Example: disable pairing in lua strings
        javascript = { 'template_string' },
        java = false, -- Disable autopairs in java - example
      },
      fast_wrap = {
        map = '<M-e>',
        chars = { '{', '[', '(', '"', "'", '`' },
        pattern = [=[[%'%"%>%]%)%}%,]]=],
        end_key = '$',
        cursor_pos_before = true,
        keys = 'qwertyuiopzxcvbnmasdfghjkl',
        manual_position = false,
        highlight = 'Search',
        highlight_grey = 'Comment',
      },
    },
    config = function(_, opts)
      require('nvim-autopairs').setup(opts)
      -- Integrate with nvim-cmp
      local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
      require('cmp').event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end,
  },
}
