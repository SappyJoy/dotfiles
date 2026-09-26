return {
  {
    'luukvbaal/statuscol.nvim',
    event = { 'BufReadPost', 'BufNewFile' }, -- Can be lazy-loaded
    config = function()
      local builtin = require 'statuscol.builtin'
      require('statuscol').setup {
        relculright = true,
        segments = {
          -- GitSigns
          {
            sign = { namespace = { 'gitsigns' }, name = { '.*' }, maxwidth = 1, colwidth = 1, auto = true }, -- Adjusted maxwidth
            click = 'v:lua.ScSa', -- Or use gitsigns actions directly?
          },
          -- Diagnostics (use icons?)
          {
            sign = { name = { 'Diagnostic' }, maxwidth = 1, colwidth = 1, auto = true }, -- Adjusted maxwidth
            click = 'v:lua.ScSa', -- Or use diagnostic actions?
          },
          -- Line Number
          { text = { builtin.lnumfunc }, click = 'v:lua.ScLa' }, -- Added click action
          -- Fold Column
          { text = { builtin.foldfunc }, click = 'v:lua.ScFa' },
        },
      }
    end,
  },
}
