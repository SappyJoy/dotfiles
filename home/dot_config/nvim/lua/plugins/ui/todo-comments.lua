return {
  {
    'folke/todo-comments.nvim',
    event = { 'BufReadPost', 'BufNewFile' }, -- Load when a buffer is ready
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      signs = false, -- Keep your preference
      -- keywords = { ... } -- Customize keywords if needed
    },
  },
}
