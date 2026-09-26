return {
  {
    'L3MON4D3/LuaSnip',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    build = (function()
      if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
        return
      end
      return 'make install_jsregexp'
    end)(),
    config = function(_, opts)
      local ls = require 'luasnip'
      ls.setup {
        link_children = true,
        link_roots = false,
        keep_roots = false,
        update_events = { 'TextChanged', 'TextChangedI' },
      }

      -- Standalone snippet navigation keys
      vim.keymap.set({ 'i', 's' }, '<Tab>', function()
        if ls.expand_or_jumpable() then
          ls.expand_or_jump()
        end
      end, { silent = true, desc = 'Snippet Expand/Next' })

      vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
        if ls.jumpable(-1) then
          ls.jump(-1)
        end
      end, { silent = true, desc = 'Snippet Previous' })

      vim.keymap.set({ 'i', 's' }, '<C-l>', function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true, desc = 'Snippet Next Choice' })

      vim.keymap.set({ 'i', 's' }, '<C-h>', function()
        if ls.choice_active() then
          ls.change_choice(-1)
        end
      end, { silent = true, desc = 'Snippet Previous Choice' })

      -- Load friendly snippets
      require('luasnip.loaders.from_vscode').lazy_load()
      
      -- Load custom snippets
      require("snippets.init")
    end,
  },
}
