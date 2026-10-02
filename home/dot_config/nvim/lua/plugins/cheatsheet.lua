-- The cheatsheet (cheatsheet.md next to init.lua): <leader>? opens it in a float
-- (editable: add your own lines), <leader>s? searches it.
local path = vim.fn.stdpath 'config' .. '/cheatsheet.md'

return {
  'folke/snacks.nvim',
  keys = {
    {
      '<leader>?',
      function()
        Snacks.win { file = path, width = 0.6, height = 0.85, border = 'rounded', title = ' cheatsheet ', wo = { spell = false } }
      end,
      desc = 'Cheatsheet',
    },
    {
      '<leader>s?',
      function()
        require('telescope.builtin').live_grep { search_dirs = { path }, prompt_title = 'Cheatsheet' }
      end,
      desc = 'Search the cheatsheet',
    },
  },
}
